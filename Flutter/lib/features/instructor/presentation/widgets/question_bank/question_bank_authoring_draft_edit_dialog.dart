part of 'question_bank_authoring_flow.dart';

class _DraftQuestionEditDialog extends StatefulWidget {
  final QuestionModel question;
  final List<add_question_sheet.QuestionAuthoringTarget> targets;

  const _DraftQuestionEditDialog({
    required this.question,
    required this.targets,
  });

  @override
  State<_DraftQuestionEditDialog> createState() => _DraftQuestionEditDialogState();
}

class _DraftQuestionEditDialogState extends State<_DraftQuestionEditDialog> {
  late final TextEditingController _questionCtrl;
  late final TextEditingController _explanationCtrl;
  late QuestionDifficulty _difficulty;
  late int? _topicId;

  @override
  void initState() {
    super.initState();
    _questionCtrl = TextEditingController(text: widget.question.text);
    _explanationCtrl = TextEditingController(text: widget.question.explanation ?? '');
    _difficulty = widget.question.difficulty;
    _topicId = widget.question.topicId;
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _explanationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 14, 16),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Edit question',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textTitle,
                        ),
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
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                child: Column(
                  children: <Widget>[
                    _dialogField(
                      controller: _questionCtrl,
                      label: 'Question text',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _dialogField(
                      controller: _explanationCtrl,
                      label: 'Explanation / note',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    _answerPreview(),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _simpleDropdown<QuestionDifficulty>(
                            label: 'Difficulty',
                            value: _difficulty,
                            items: QuestionDifficulty.values,
                            itemLabel: (QuestionDifficulty value) => value.label,
                            onChanged: (QuestionDifficulty? value) {
                              if (value != null) setState(() => _difficulty = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _simpleDropdown<int>(
                            label: 'Topic / Subtopic',
                            value: _topicId,
                            items: widget.targets.map((t) => t.topicId).toList(),
                            itemLabel: (int value) => _compactTargetLabel(_findTarget(widget.targets, value)!),
                            onChanged: (int? value) => setState(() => _topicId = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Apply changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: AppColors.textGray, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
        filled: true,
        fillColor: AppColors.surfaceBg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _answerPreview() {
    final QuestionModel question = widget.question;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.check_circle_outline_rounded, size: 17, color: AppColors.successText),
              const SizedBox(width: 8),
              Text(
                'Answer',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _dialogAnswerSummary(question),
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w800,
              color: AppColors.textTitle,
            ),
          ),
          if (question.options.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: question.options.map((QuestionOption option) {
                final bool correct = _dialogIsCorrectOption(question, option);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: correct ? AppColors.greenBg : AppColors.cardBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: correct
                          ? AppColors.successText.withValues(alpha: 0.32)
                          : AppColors.borderSoft,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (correct) ...<Widget>[
                        Icon(Icons.check_rounded, size: 14, color: AppColors.successText),
                        const SizedBox(width: 5),
                      ],
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: Text(
                          option.text,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: correct ? AppColors.successText : AppColors.textGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  bool _dialogIsCorrectOption(QuestionModel question, QuestionOption option) {
    if (option.isCorrect) return true;
    if (question.correctOptionId != null && option.id == question.correctOptionId) return true;
    final String expected = (question.expectedAnswer ?? '').trim();
    if (expected.isEmpty) return false;
    final List<String> parts = expected.split(',').map((String value) => value.trim()).toList();
    return parts.contains(option.id) || parts.contains(option.text);
  }

  String _dialogAnswerSummary(QuestionModel question) {
    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.multiSelect:
        final List<QuestionOption> correctOptions = question.options
            .where((QuestionOption option) => _dialogIsCorrectOption(question, option))
            .toList();
        if (correctOptions.isNotEmpty) {
          return correctOptions.map((QuestionOption option) => option.text).join(', ');
        }
        final String answerFallback = (question.expectedAnswer ?? question.correctOptionId ?? '').trim();
        return answerFallback.isEmpty ? 'No answer set' : answerFallback;
      case QuestionType.trueFalse:
        if (question.correctBool != null) return question.correctBool! ? 'True' : 'False';
        final String tfFallback = (question.expectedAnswer ?? '').trim();
        return tfFallback.isEmpty ? 'No answer set' : tfFallback;
      case QuestionType.shortAnswer:
      case QuestionType.essay:
      case QuestionType.fillInTheBlank:
      case QuestionType.numeric:
      case QuestionType.code:
        final String textFallback = (question.expectedAnswer ?? question.sampleAnswer ?? '').trim();
        return textFallback.isEmpty ? 'No answer set' : textFallback;
    }
  }

  Widget _simpleDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T value) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
        filled: true,
        fillColor: AppColors.surfaceBg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      dropdownColor: AppColors.cardBg,
      items: items
          .map((T value) => DropdownMenuItem<T>(
                value: value,
                child: Text(
                  itemLabel(value),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textGray, fontWeight: FontWeight.w700),
                ),
              ),)
          .toList(),
      onChanged: onChanged,
    );
  }

  void _submit() {
    final String text = _questionCtrl.text.trim();
    if (text.isEmpty || _topicId == null) return;
    final add_question_sheet.QuestionAuthoringTarget? target = _findTarget(widget.targets, _topicId!);

    Navigator.of(context).pop(
      QuestionModel(
        id: widget.question.id,
        remoteId: widget.question.remoteId,
        text: text,
        type: widget.question.type,
        difficulty: _difficulty,
        source: widget.question.source,
        approvalStatus: widget.question.approvalStatus,
        options: widget.question.options,
        correctOptionId: widget.question.correctOptionId,
        correctBool: widget.question.correctBool,
        sampleAnswer: widget.question.sampleAnswer,
        explanation: _explanationCtrl.text.trim().isEmpty ? null : _explanationCtrl.text.trim(),
        expectedAnswer: widget.question.expectedAnswer,
        tags: widget.question.tags,
        usageCount: widget.question.usageCount,
        successRate: widget.question.successRate,
        maxScore: widget.question.maxScore,
        autoGradable: widget.question.autoGradable,
        courseId: widget.question.courseId,
        moduleId: target?.moduleId ?? widget.question.moduleId,
        moduleName: target?.moduleName ?? widget.question.moduleName,
        materialId: target?.materialId ?? widget.question.materialId,
        materialName: target?.materialName ?? widget.question.materialName,
        topicId: target?.topicId ?? widget.question.topicId,
        topicName: target?.topicName ?? widget.question.topicName,
        learningOutcomes: widget.question.learningOutcomes,
        createdAt: widget.question.createdAt,
      ),
    );
  }
}

