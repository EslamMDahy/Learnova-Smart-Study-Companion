part of 'question_bank_tab.dart';

class _EditQuestionDialog extends ConsumerStatefulWidget {
  final int courseId;
  final QuestionModel question;
  final List<_TopicTarget> topicTargets;

  const _EditQuestionDialog({
    required this.courseId,
    required this.question,
    required this.topicTargets,
  });

  @override
  ConsumerState<_EditQuestionDialog> createState() => _EditQuestionDialogState();
}

class _EditQuestionDialogState extends ConsumerState<_EditQuestionDialog> {
  late final TextEditingController _questionController;
  late final TextEditingController _explanationController;
  late final TextEditingController _answerController;
  late final TextEditingController _tagsController;
  late QuestionDifficulty _difficulty;
  late int? _topicId;
  late List<_EditableOption> _options;
  late bool? _boolAnswer;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _questionController = TextEditingController(text: q.text);
    _explanationController = TextEditingController(text: q.explanation ?? '');
    _answerController = TextEditingController(text: _initialAnswerText(q));
    _tagsController = TextEditingController(text: q.tags.join(', '));
    _difficulty = q.difficulty;
    _topicId = q.topicId ?? (widget.topicTargets.isNotEmpty ? widget.topicTargets.first.topic.id : null);
    _boolAnswer = q.correctBool;
    _options = _initialOptions(q);
  }

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
    _answerController.dispose();
    _tagsController.dispose();
    for (final option in _options) {
      option.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final qid = widget.question.remoteId ?? int.tryParse(widget.question.id);
    if (qid == null || qid <= 0) {
      setState(() => _error = 'This question does not have a backend id.');
      return;
    }

    final validation = _validate();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final payload = _buildPayload();
      await ref.read(questionsApiProvider).updateQuestion(
            courseId: widget.courseId,
            questionId: qid,
            payload: payload,
          );
      final hydrated = await ref.read(questionsApiProvider).getQuestion(
            courseId: widget.courseId,
            questionId: qid,
          );
      if (!mounted) return;
      Navigator.of(context).pop(hydrated);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = mapApiFailure(e).message;
      });
    }
  }

  String? _validate() {
    if (_questionController.text.trim().isEmpty) return 'Question text is required.';
    if (_topicId == null || _topicId! <= 0) return 'A topic is required.';
    final type = widget.question.type;
    if (!_backendEditableType(type)) {
      return '${type.label} is not editable with the current backend question contract.';
    }
    if (type == QuestionType.multipleChoice || type == QuestionType.multiSelect) {
      final cleanOptions = _options.where((option) => option.controller.text.trim().isNotEmpty).toList();
      if (cleanOptions.length < 2) return 'At least two non-empty options are required.';
      if (!cleanOptions.any((option) => option.correct)) return 'Select at least one correct option.';
      if (type == QuestionType.multipleChoice && cleanOptions.where((option) => option.correct).length != 1) {
        return 'Multiple choice needs exactly one correct option.';
      }
    }
    if (type == QuestionType.trueFalse && _boolAnswer == null) return 'Select True or False.';
    if (type == QuestionType.shortAnswer && _answerController.text.trim().isEmpty) {
      return 'Expected answer is required for short answer questions.';
    }
    return null;
  }

  UpdateQuestionPayload _buildPayload() {
    final type = widget.question.type;
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    if (type == QuestionType.multipleChoice || type == QuestionType.multiSelect) {
      final cleanOptions = _options.where((option) => option.controller.text.trim().isNotEmpty).toList();
      final optionIds = List.generate(cleanOptions.length, (index) => index.toString());
      final createOptions = List.generate(cleanOptions.length, (index) {
        return CreateQuestionOption(id: optionIds[index], text: cleanOptions[index].controller.text.trim());
      });
      final correctIds = <String>[];
      for (var i = 0; i < cleanOptions.length; i++) {
        if (cleanOptions[i].correct) correctIds.add(optionIds[i]);
      }
      return UpdateQuestionPayload(
        topicId: _topicId,
        questionText: _questionController.text.trim(),
        difficulty: _difficulty.backendValue,
        explanation: _explanationController.text.trim(),
        options: createOptions,
        expectedAnswer: type == QuestionType.multiSelect ? correctIds : correctIds.first,
        tags: tags,
      );
    }

    if (type == QuestionType.trueFalse) {
      return UpdateQuestionPayload(
        topicId: _topicId,
        questionText: _questionController.text.trim(),
        difficulty: _difficulty.backendValue,
        explanation: _explanationController.text.trim(),
        expectedAnswer: (_boolAnswer ?? false).toString(),
        tags: tags,
      );
    }

    return UpdateQuestionPayload(
      topicId: _topicId,
      questionText: _questionController.text.trim(),
      difficulty: _difficulty.backendValue,
      explanation: _explanationController.text.trim(),
      expectedAnswer: _answerController.text.trim(),
      tags: tags,
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final editable = _backendEditableType(q.type);
    final size = MediaQuery.of(context).size;
    final compact = size.width < 900;
    final width = compact ? size.width * 0.94 : 860.0;
    final height = size.height < 760 ? size.height * 0.94 : size.height * 0.86;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 32,
        vertical: compact ? 18 : 36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width,
            maxHeight: height.clamp(640.0, 820.0).toDouble(),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.pageBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Question',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textTitle,
                                height: 1.22,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              editable
                                  ? 'Update this saved assessment item using the same authoring workspace.'
                                  : '${q.typeLabel} cannot be updated by the current backend question contract.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _saving ? null : () => Navigator.of(context).pop(),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderGray),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_error != null) ...[
                                    _EditErrorBanner(message: _error!),
                                    const SizedBox(height: 16),
                                  ],
                                  _buildMetaSection(q, editable),
                                  const SizedBox(height: 18),
                                  _buildQuestionTextSection(q, editable),
                                  const SizedBox(height: 18),
                                  _buildAnswerSection(q, editable),
                                  const SizedBox(height: 18),
                                  _buildExplanationSection(editable),
                                  const SizedBox(height: 18),
                                  _buildTagsSection(editable),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Row(
                    children: [
                      const _TinyMeta(icon: Icons.lock_outline_rounded, label: 'Type locked'),
                      const Spacer(),
                      TextButton(
                        onPressed: _saving ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _saving || !editable ? null : _save,
                        style: _editPrimaryButtonStyle(),
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: Text(_saving ? 'Saving...' : 'Save Changes'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaSection(QuestionModel q, bool editable) {
    Widget topicField() => _TopicSelectorField(
          value: _topicId,
          targets: widget.topicTargets,
          fallbackTopicName: q.topicName,
          enabled: !_saving && editable,
          onChanged: (value) => setState(() => _topicId = value),
        );

    Widget difficultyField() => AppModernDropdown<QuestionDifficulty>(
          label: 'Difficulty',
          value: _difficulty,
          icon: Icons.signal_cellular_alt_rounded,
          items: const <DropdownMenuItem<QuestionDifficulty>>[
            DropdownMenuItem<QuestionDifficulty>(
              value: QuestionDifficulty.easy,
              child: Text('Easy'),
            ),
            DropdownMenuItem<QuestionDifficulty>(
              value: QuestionDifficulty.medium,
              child: Text('Medium'),
            ),
            DropdownMenuItem<QuestionDifficulty>(
              value: QuestionDifficulty.hard,
              child: Text('Hard'),
            ),
          ],
          onChanged: (value) {
            if (_saving || !editable || value == null) return;
            setState(() => _difficulty = value);
          },
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              topicField(),
              const SizedBox(height: 16),
              difficultyField(),
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 2, child: topicField()),
            const SizedBox(width: 16),
            Expanded(child: difficultyField()),
          ],
        );
      },
    );
  }


  Widget _buildQuestionTextSection(QuestionModel q, bool editable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _EditSectionLabel('Question Text')),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                q.typeLabel,
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBg,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    const _EditToolbarButton(label: 'B'),
                    const SizedBox(width: 4),
                    const _EditToolbarButton(label: 'I', italic: true),
                    const SizedBox(width: 4),
                    const _EditToolbarButton(label: 'U', underlined: true),
                    const SizedBox(width: 8),
                    Icon(Icons.format_list_bulleted_rounded, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Icon(Icons.image_outlined, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Icon(Icons.code_rounded, size: 16, color: AppColors.textMuted),
                    const Spacer(),
                    if (_topicId != null)
                      Flexible(
                        child: Text(
                          _topicPickerLabel(widget.topicTargets, _topicId) ?? q.topicName ?? 'Selected topic',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              TextField(
                controller: _questionController,
                enabled: !_saving && editable,
                minLines: 5,
                maxLines: 5,
                decoration: _editInputDecoration(
                  'Enter your question here... e.g. What is the primary function of the mitochondria?',
                ).copyWith(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerSection(QuestionModel q, bool editable) {
    if (q.type == QuestionType.multipleChoice || q.type == QuestionType.multiSelect) {
      return _buildMultipleChoiceSection(q.type, editable);
    }
    if (q.type == QuestionType.trueFalse) {
      return _buildTrueFalseSection(editable);
    }
    return _buildWrittenAnswerSection(q.type, editable);
  }

  Widget _buildMultipleChoiceSection(QuestionType type, bool editable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _EditSectionLabel('Answer Options'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                type == QuestionType.multiSelect ? 'Select all correct answers' : 'Select the correct answer',
                style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w500),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: !_saving && editable && _options.length < 8
                  ? () {
                      setState(() {
                        _options.add(_EditableOption(controller: TextEditingController(), correct: false));
                      });
                    }
                  : null,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: const Text('Add another option'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List<Widget>.generate(_options.length, (index) {
          final option = _options[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 26),
                  child: type == QuestionType.multiSelect
                      ? Checkbox(
                          value: option.correct,
                          onChanged: !_saving && editable
                              ? (value) {
                                  setState(() => option.correct = value ?? false);
                                }
                              : null,
                        )
                      : InkWell(
                          onTap: !_saving && editable
                              ? () {
                                  setState(() {
                                    for (var i = 0; i < _options.length; i++) {
                                      _options[i].correct = i == index;
                                    }
                                  });
                                }
                              : null,
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: option.correct ? AppColors.primary : AppColors.borderSoft,
                                width: option.correct ? 5 : 1.5,
                              ),
                              color: AppColors.cardBg,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Option ${String.fromCharCode(65 + index)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: option.controller,
                        enabled: !_saving && editable,
                        decoration: _editInputDecoration(index == 0 ? 'Powerhouse of the cell' : 'Enter answer option'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: IconButton(
                    onPressed: !_saving && editable && _options.length > 2
                        ? () {
                            final removed = _options.removeAt(index);
                            removed.controller.dispose();
                            setState(() {});
                          }
                        : null,
                    icon: const Icon(Icons.delete_outline_rounded, size: 19),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrueFalseSection(bool editable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EditSectionLabel('Correct Answer'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _EditBooleanAnswerCard(
                label: 'True',
                selected: _boolAnswer ?? false,
                enabled: !_saving && editable,
                onTap: () => setState(() => _boolAnswer = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _EditBooleanAnswerCard(
                label: 'False',
                selected: _boolAnswer == false,
                enabled: !_saving && editable,
                onTap: () => setState(() => _boolAnswer = false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWrittenAnswerSection(QuestionType type, bool editable) {
    final hint = type == QuestionType.essay
        ? 'Enter the expected problem-solving answer or rubric.'
        : 'Enter the expected short answer.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EditSectionLabel('Expected Answer'),
        const SizedBox(height: 10),
        TextField(
          controller: _answerController,
          enabled: !_saving && editable,
          maxLines: 4,
          decoration: _editInputDecoration(hint),
        ),
      ],
    );
  }

  Widget _buildExplanationSection(bool editable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EditSectionLabel('Explanation (Optional)'),
        const SizedBox(height: 10),
        TextField(
          controller: _explanationController,
          enabled: !_saving && editable,
          maxLines: 3,
          decoration: _editInputDecoration('Explain why the correct answer is correct...'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'This will be shown to students after they submit their answer.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagsSection(bool editable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EditSectionLabel('Tags (Optional)'),
        const SizedBox(height: 10),
        TextField(
          controller: _tagsController,
          enabled: !_saving && editable,
          decoration: _editInputDecoration('Tags, comma separated'),
        ),
      ],
    );
  }

  ButtonStyle _editPrimaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    );
  }

  InputDecoration _editInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textHint,
      ),
      filled: true,
      fillColor: AppColors.surfaceBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    );
  }

}

class _EditErrorBanner extends StatelessWidget {
  final String message;

  const _EditErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: AppColors.dangerText,
          fontSize: 12.5,
          height: 1.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EditSectionLabel extends StatelessWidget {
  final String text;

  const _EditSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textTitle,
      ),
    );
  }
}

class _EditToolbarButton extends StatelessWidget {
  final String label;
  final bool italic;
  final bool underlined;

  const _EditToolbarButton({
    required this.label,
    this.italic = false,
    this.underlined = false,
  });

  @override
  Widget build(BuildContext context) {
    var style = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      color: AppColors.textMuted,
    );
    if (italic) style = style.copyWith(fontStyle: FontStyle.italic);
    if (underlined) style = style.copyWith(decoration: TextDecoration.underline);
    return Text(label, style: style);
  }
}

class _EditBooleanAnswerCard extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _EditBooleanAnswerCard({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: selected ? AppColors.infoBg : AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.borderSoft,
                  width: selected ? 5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: AppColors.textTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicSelectorField extends StatelessWidget {
  final int? value;
  final List<_TopicTarget> targets;
  final String? fallbackTopicName;
  final bool enabled;
  final ValueChanged<int?> onChanged;

  const _TopicSelectorField({
    required this.value,
    required this.targets,
    required this.fallbackTopicName,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label = _topicPickerLabel(targets, value) ?? fallbackTopicName ?? 'No topic selected';
    Future<void> openPicker() async {
      if (!enabled || targets.isEmpty) return;
      final selected = await showDialog<int>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.30),
        builder: (_) => _TopicPickerDialog(
          selectedTopicId: value,
          targets: targets,
        ),
      );
      if (selected != null) onChanged(selected);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Topic',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppColors.textGray,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: targets.isEmpty ? null : openPicker,
          child: Container(
            height: 44,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: targets.isEmpty ? AppColors.surfaceBg : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: targets.isEmpty ? AppColors.border : AppColors.primary.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_tree_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: targets.isEmpty ? AppColors.textMuted : AppColors.textGray,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.unfold_more_rounded, color: AppColors.textMuted, size: 19),
              ],
            ),
          ),
        ),
      ],
    );
  }

}

class _TopicPickerDialog extends StatefulWidget {
  final int? selectedTopicId;
  final List<_TopicTarget> targets;

  const _TopicPickerDialog({required this.selectedTopicId, required this.targets});

  @override
  State<_TopicPickerDialog> createState() => _TopicPickerDialogState();
}

class _TopicPickerDialogState extends State<_TopicPickerDialog> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = widget.targets.where((target) {
      if (query.isEmpty) return true;
      return <String>[
        target.topic.title,
        target.parentTopicTitle ?? '',
        target.material.displayTitle,
        target.module.title,
      ].join(' ').toLowerCase().contains(query);
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 680),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 14, 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_tree_outlined, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose target topic',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textTitle,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Pick the exact topic or subtopic where this question belongs.',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGray),
                  ),
                  child: TextField(
                    controller: _search,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
                      hintText: 'Search topic, material, or module...',
                      hintStyle: TextStyle(color: AppColors.textHint),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No matching topics found.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        children: _buildGroupedTargetRows(context, filtered),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedTargetRows(BuildContext context, List<_TopicTarget> targets) {
    final rows = <Widget>[];
    String? currentModule;
    String? currentMaterial;

    for (final target in targets) {
      if (target.module.title != currentModule) {
        currentModule = target.module.title;
        rows.add(_groupHeader(Icons.school_outlined, currentModule));
        currentMaterial = null;
      }
      if (target.material.displayTitle != currentMaterial) {
        currentMaterial = target.material.displayTitle;
        rows.add(_groupHeader(Icons.description_outlined, currentMaterial, indent: 14));
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(left: 28, top: 6),
          child: _treeOption(
            context,
            selected: widget.selectedTopicId == target.topic.id,
            icon: target.parentTopicTitle == null ? Icons.topic_outlined : Icons.subdirectory_arrow_right_rounded,
            title: target.parentTopicTitle == null ? target.topic.title : '${target.parentTopicTitle} / ${target.topic.title}',
            subtitle: '${target.module.title} • ${target.material.displayTitle} • ${target.parentTopicTitle == null ? 'Topic' : 'Subtopic'}',
            onTap: () => Navigator.of(context).pop(target.topic.id),
          ),
        ),
      );
    }
    return rows;
  }

  Widget _groupHeader(IconData icon, String title, {double indent = 0}) {
    return Padding(
      padding: EdgeInsets.only(left: indent, top: 14, bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.45,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _treeOption(
    BuildContext context, {
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.selectedBg : AppColors.surfaceBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? AppColors.primary.withValues(alpha: 0.50) : AppColors.borderGray,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.cardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: selected ? Colors.white : AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.2,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textTitle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }

}

class _EditableOption {
  final TextEditingController controller;
  bool correct;

  _EditableOption({required this.controller, required this.correct});
}

class _TopicTarget {
  final ModuleItem module;
  final MaterialItem material;
  final TopicItem topic;
  final String? parentTopicTitle;

  const _TopicTarget({
    required this.module,
    required this.material,
    required this.topic,
    this.parentTopicTitle,
  });
}


class _TinyMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TinyMeta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textHint),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: AppColors.textMuted, fontSize: 11.2, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _QuestionBankSkeleton extends StatelessWidget {
  const _QuestionBankSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: List.generate(
          7,
          (index) => Container(
            margin: EdgeInsets.only(bottom: index == 6 ? 0 : 10),
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.surfaceBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionBankEmpty extends StatelessWidget {
  final bool hasQuestions;

  const _QuestionBankEmpty({required this.hasQuestions});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.quiz_outlined, size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              hasQuestions ? 'No questions match the current filters' : 'No saved questions yet',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textTitle, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Text(
                hasQuestions
                    ? 'Adjust the search term, learning outcome, or question type to reveal more questions.'
                    : 'Questions will appear here after they are saved from the material generation workspace or manual authoring flow.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionBankError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _QuestionBankError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 42, color: AppColors.dangerText),
            const SizedBox(height: 14),
            Text(
              'Could not load question bank',
              style: TextStyle(color: AppColors.textTitle, fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}


bool _isCorrectOption(QuestionModel question, QuestionOption option, {int? index}) {
  if (option.isCorrect) return true;
  if (question.correctOptionId != null && question.correctOptionId == option.id) return true;

  final normalizedTokens = _expectedAnswerTokens(question)
      .map((token) => token.trim().toLowerCase())
      .where((token) => token.isNotEmpty)
      .toSet();
  if (normalizedTokens.isEmpty) return false;

  final keys = <String>{
    option.id,
    option.orderIndex.toString(),
  };
  if (index != null) {
    keys.add(String.fromCharCode(65 + index));
    keys.add(index.toString());
    keys.add('${index + 1}');
    keys.add('opt_$index');
  }

  return keys.map((key) => key.trim().toLowerCase()).any(normalizedTokens.contains);
}

List<String> _expectedAnswerTokens(QuestionModel question) {
  final expected = question.expectedAnswer;
  if (expected == null || expected.trim().isEmpty) return const <String>[];
  return expected
      .replaceAll('[', '')
      .replaceAll(']', '')
      .replaceAll('"', '')
      .replaceAll("'", '')
      .split(',')
      .map((token) => token.trim())
      .where((token) => token.isNotEmpty)
      .toList();
}

String _jsonish(Object? value) {
  if (value == null) return '—';
  if (value is String) return value.trim().isEmpty ? '—' : value;
  try {
    return const JsonEncoder.withIndent('  ').convert(value);
  } catch (_) {
    return value.toString();
  }
}
class _FilterOption {
  final int id;
  final String label;

  const _FilterOption({required this.id, required this.label});
}

_TopicTarget? _targetForQuestion(List<_TopicTarget> targets, QuestionModel question) {
  final topicId = question.topicId;
  if (topicId == null) return null;
  for (final target in targets) {
    if (target.topic.id == topicId) return target;
  }
  return null;
}

bool _materialBelongsToModule(List<_TopicTarget> targets, int materialId, int moduleId) {
  for (final target in targets) {
    if (target.material.id == materialId && target.module.id == moduleId) return true;
  }
  return false;
}

bool _topicBelongsToMaterial(List<_TopicTarget> targets, int topicId, int materialId) {
  for (final target in targets) {
    if (target.topic.id == topicId && target.material.id == materialId) return true;
  }
  return false;
}

List<_FilterOption> _materialFilterOptions(List<_TopicTarget> targets, int? moduleId) {
  final seen = <int>{};
  final result = <_FilterOption>[];
  for (final target in targets) {
    if (moduleId != null && target.module.id != moduleId) continue;
    if (!seen.add(target.material.id)) continue;
    final label = '${target.module.title} / ${target.material.displayTitle}';
    result.add(_FilterOption(id: target.material.id, label: label));
  }
  result.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  return result;
}

List<_FilterOption> _learningOutcomeSetupOptions(
  List<QuestionModel> questions,
  List<LearningOutcome> courseOutcomes,
) {
  final byId = <int, String>{};
  for (final outcome in courseOutcomes) {
    final title = outcome.title.trim();
    byId[outcome.id] = title.isEmpty ? 'LO ${outcome.id}' : title;
  }
  for (final question in questions) {
    for (final outcome in question.learningOutcomes) {
      final title = outcome.title.trim();
      byId.putIfAbsent(outcome.id, () => title.isEmpty ? 'LO ${outcome.id}' : title);
    }
  }
  final result = byId.entries
      .map((entry) => _FilterOption(id: entry.key, label: entry.value))
      .toList()
    ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  return result;
}

String _selectedMaterialFilterLabel(List<_FilterOption> options, int? id) {
  if (id == null) return 'All materials';
  for (final option in options) {
    if (option.id == id) return option.label;
  }
  return 'All materials';
}

String _selectedOutcomeFilterLabel(List<_FilterOption> options, int? id) {
  if (id == null) return 'All LOs';
  for (final option in options) {
    if (option.id == id) return option.label;
  }
  return 'All LOs';
}

String _sourceLabel(QuestionSource source) {
  switch (source) {
    case QuestionSource.aiGenerated:
      return 'AI';
    case QuestionSource.nativeExtraction:
      return 'Material';
    case QuestionSource.imported:
      return 'Imported';
    case QuestionSource.manual:
      return 'Manual';
  }
}

String _usageLabel(int count) => count == 0 ? 'Unused' : 'Used in $count exam${count == 1 ? '' : 's'}';

String _topicPathFromTarget(_TopicTarget? target, QuestionModel question) {
  if (target == null) return question.topicName ?? 'Not assigned';
  if (target.parentTopicTitle == null) return target.topic.title;
  return '${target.parentTopicTitle} / ${target.topic.title}';
}

String _answerText(QuestionModel question) {
  if (question.correctBool != null) return question.correctBool! ? 'True' : 'False';
  if (question.options.isNotEmpty && (question.expectedAnswer ?? '').trim().isNotEmpty) {
    final labels = _expectedAnswerTokens(question)
        .map((token) => _answerTokenLabel(question, token))
        .where((token) => token.trim().isNotEmpty)
        .toList(growable: false);
    if (labels.isNotEmpty) return labels.join(', ');
  }
  if ((question.expectedAnswer ?? '').trim().isNotEmpty) return question.expectedAnswer!.trim();
  if ((question.sampleAnswer ?? '').trim().isNotEmpty) return question.sampleAnswer!.trim();
  if ((question.correctOptionId ?? '').trim().isNotEmpty) return question.correctOptionId!.trim();
  return '';
}

String _answerTokenLabel(QuestionModel question, String token) {
  final normalized = token.trim().replaceAll('"', '').replaceAll("'", '');
  if (normalized.isEmpty) return '';

  final numericIndex = int.tryParse(normalized);
  if (numericIndex != null && numericIndex >= 0 && numericIndex < question.options.length) {
    return String.fromCharCode(65 + numericIndex);
  }

  final upper = normalized.toUpperCase();
  for (var i = 0; i < question.options.length; i++) {
    final option = question.options[i];
    if (option.id.trim().toUpperCase() == upper) {
      return String.fromCharCode(65 + i);
    }
  }
  return normalized;
}

String _moduleLabel(ModuleItem module) => module.title.trim().isEmpty ? 'Module ${module.id}' : module.title.trim();

String _selectedModuleLabel(List<ModuleItem> modules, int? id) {
  if (id == null) return 'All modules';
  for (final module in modules) {
    if (module.id == id) return _moduleLabel(module);
  }
  return 'All modules';
}

QuestionType? _typeFromLabel(String label) {
  switch (label) {
    case 'Multiple Choice':
      return QuestionType.multipleChoice;
    case 'True / False':
      return QuestionType.trueFalse;
    case 'Short Answer':
      return QuestionType.shortAnswer;
    case 'Essay':
      return QuestionType.essay;
    case 'Multi-Select':
      return QuestionType.multiSelect;
    case 'Fill in the Blank':
      return QuestionType.fillInTheBlank;
    case 'Numeric':
      return QuestionType.numeric;
    case 'Code':
      return QuestionType.code;
    default:
      return null;
  }
}

bool _backendEditableType(QuestionType type) {
  return type == QuestionType.multipleChoice ||
      type == QuestionType.multiSelect ||
      type == QuestionType.trueFalse ||
      type == QuestionType.shortAnswer ||
      type == QuestionType.essay;
}

String _initialAnswerText(QuestionModel q) {
  if (q.type == QuestionType.shortAnswer || q.type == QuestionType.essay) {
    return q.sampleAnswer ?? q.expectedAnswer ?? '';
  }
  return q.expectedAnswer ?? '';
}

List<_EditableOption> _initialOptions(QuestionModel q) {
  if (q.options.isEmpty) {
    return [
      _EditableOption(controller: TextEditingController(), correct: true),
      _EditableOption(controller: TextEditingController(), correct: false),
    ];
  }
  return q.options.map((option) {
    final correct = option.isCorrect || option.id == q.correctOptionId;
    return _EditableOption(
      controller: TextEditingController(text: option.text),
      correct: correct,
    );
  }).toList();
}

bool _isNegativeNumber(String raw) {
  final parsed = int.tryParse(raw.trim());
  return parsed != null && parsed < 0;
}

String? _topicPickerLabel(List<_TopicTarget> targets, int? topicId) {
  if (topicId == null) return null;
  for (final target in targets) {
    if (target.topic.id == topicId) return target.topic.title;
  }
  return null;
}