part of 'quiz_screen.dart';

class _ExamCreationLauncherDialog extends StatelessWidget {
  final MyCourseItem course;

  const _ExamCreationLauncherDialog({required this.course});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _IconBox(icon: Icons.add_task_rounded, color: AppColors.primary, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create exam', style: _textStyle(color: AppColors.textTitle, size: 22, weight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(course.safeTitle, style: _textStyle(color: AppColors.textMuted, size: 12.5, weight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 620;
                  final cards = [
                    _CreateModeCard(
                      icon: Icons.edit_note_rounded,
                      title: 'Manual draft',
                      subtitle: 'Create an empty exam, then add sections and attach questions section-by-section.',
                      buttonLabel: 'Start manually',
                      onTap: () => Navigator.of(context).pop(_ExamCreationMode.manual),
                    ),
                    _CreateModeCard(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Generate from template',
                      subtitle: 'Pick a template, topics/subtopics, and type the Easy / Medium / Hard mix at generation time.',
                      buttonLabel: 'Generate',
                      onTap: () => Navigator.of(context).pop(_ExamCreationMode.automatic),
                    ),
                  ];
                  if (stacked) {
                    return Column(children: [cards[0], const SizedBox(height: 12), cards[1]]);
                  }
                  return Row(children: [Expanded(child: cards[0]), const SizedBox(width: 14), Expanded(child: cards[1])]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const _CreateModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconBox(icon: icon, color: AppColors.primary, size: 46),
            const SizedBox(height: 14),
            Text(title, style: _textStyle(color: AppColors.textTitle, size: 16, weight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(subtitle, style: _textStyle(color: AppColors.textMuted, size: 12.2, weight: FontWeight.w700, height: 1.45)),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: onTap, child: Text(buttonLabel))),
          ],
        ),
      ),
    );
  }
}

class _ManualExamDraft {
  final String title;
  final String? description;
  final String? instructions;
  final String examType;
  final int? durationMinutes;
  final int maxAttempts;
  final double? passingScore;
  final bool shuffleQuestions;
  final bool shuffleOptions;
  final DateTime? availableFrom;
  final DateTime? availableTo;

  const _ManualExamDraft({
    required this.title,
    this.description,
    this.instructions,
    required this.examType,
    this.durationMinutes,
    required this.maxAttempts,
    this.passingScore,
    required this.shuffleQuestions,
    required this.shuffleOptions,
    this.availableFrom,
    this.availableTo,
  });
}

class _ManualExamDraftDialog extends StatefulWidget {
  final MyCourseItem course;

  const _ManualExamDraftDialog({required this.course});

  @override
  State<_ManualExamDraftDialog> createState() => _ManualExamDraftDialogState();
}

class _ManualExamDraftDialogState extends State<_ManualExamDraftDialog> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '60');
  final _attemptsCtrl = TextEditingController(text: '1');
  final _passingCtrl = TextEditingController(text: '60');
  String _examType = 'quiz';
  bool _shuffleQuestions = true;
  bool _shuffleOptions = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = '${widget.course.safeTitle} manual exam';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _instructionsCtrl.dispose();
    _durationCtrl.dispose();
    _attemptsCtrl.dispose();
    _passingCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Exam title is required.');
      return;
    }
    final duration = int.tryParse(_durationCtrl.text.trim());
    final attempts = int.tryParse(_attemptsCtrl.text.trim());
    final passing = double.tryParse(_passingCtrl.text.trim());
    Navigator.of(context).pop(_ManualExamDraft(
      title: title,
      description: _emptyToNull(_descriptionCtrl.text),
      instructions: _emptyToNull(_instructionsCtrl.text),
      examType: _examType,
      durationMinutes: duration != null && duration > 0 ? duration : null,
      maxAttempts: attempts != null && attempts > 0 ? attempts : 1,
      passingScore: passing != null && passing >= 0 ? passing : null,
      shuffleQuestions: _shuffleQuestions,
      shuffleOptions: _shuffleOptions,
    ));
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 18, 16),
              child: Row(
                children: [
                  _IconBox(icon: Icons.edit_note_rounded, color: AppColors.primary, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Manual exam draft', style: _textStyle(color: AppColors.textTitle, size: 21, weight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('Create the exam shell first. Sections and questions are added after creation.', style: _textStyle(color: AppColors.textMuted, size: 12.3, weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[_InlineError(message: _error!), const SizedBox(height: 12)],
                    _DialogTextField(label: 'Exam title', controller: _titleCtrl),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _DialogTextField(label: 'Duration minutes', controller: _durationCtrl, numeric: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _DialogTextField(label: 'Max attempts', controller: _attemptsCtrl, numeric: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _DialogTextField(label: 'Passing score', controller: _passingCtrl, numeric: true)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _examType,
                      decoration: _dialogInputDecoration('Exam type'),
                      items: const [
                        DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                        DropdownMenuItem(value: 'midterm', child: Text('Midterm')),
                        DropdownMenuItem(value: 'final', child: Text('Final')),
                        DropdownMenuItem(value: 'assignment', child: Text('Assignment')),
                      ],
                      onChanged: (value) => setState(() => _examType = value ?? 'quiz'),
                    ),
                    const SizedBox(height: 12),
                    _DialogTextField(label: 'Description', controller: _descriptionCtrl, maxLines: 2),
                    const SizedBox(height: 12),
                    _DialogTextField(label: 'Instructions', controller: _instructionsCtrl, maxLines: 3),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      value: _shuffleQuestions,
                      onChanged: (value) => setState(() => _shuffleQuestions = value ?? true),
                      title: const Text('Shuffle questions'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: _shuffleOptions,
                      onChanged: (value) => setState(() => _shuffleOptions = value ?? false),
                      title: const Text('Shuffle answer options'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
              child: Row(
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const Spacer(),
                  FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.arrow_forward_rounded, size: 18), label: const Text('Create draft')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualSectionDraft {
  final String title;
  final String? description;
  final String questionType;
  final int? timeLimitMinutes;
  final bool mustComplete;

  const _ManualSectionDraft({
    required this.title,
    this.description,
    required this.questionType,
    this.timeLimitMinutes,
    required this.mustComplete,
  });
}

class _ManualSectionDialog extends StatefulWidget {
  const _ManualSectionDialog();

  @override
  State<_ManualSectionDialog> createState() => _ManualSectionDialogState();
}

class _ManualSectionDialogState extends State<_ManualSectionDialog> {
  final _titleCtrl = TextEditingController(text: 'Multiple Choice Section');
  final _descriptionCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  String _questionType = 'multiple_choice';
  bool _mustComplete = true;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Section title is required.');
      return;
    }
    final time = int.tryParse(_timeCtrl.text.trim());
    Navigator.of(context).pop(_ManualSectionDraft(
      title: title,
      description: _emptyToNull(_descriptionCtrl.text),
      questionType: _questionType,
      timeLimitMinutes: time != null && time > 0 ? time : null,
      mustComplete: _mustComplete,
    ));
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _IconBox(icon: Icons.view_agenda_outlined, color: AppColors.primary, size: 44),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Add exam section', style: _textStyle(color: AppColors.textTitle, size: 19, weight: FontWeight.w900))),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[_InlineError(message: _error!), const SizedBox(height: 12)],
              _DialogTextField(label: 'Section title', controller: _titleCtrl),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _questionType,
                decoration: _dialogInputDecoration('Question type'),
                items: const [
                  DropdownMenuItem(value: 'multiple_choice', child: Text('Multiple Choice')),
                  DropdownMenuItem(value: 'true_false', child: Text('True / False')),
                  DropdownMenuItem(value: 'short_answer', child: Text('Short Answer')),
                  DropdownMenuItem(value: 'essay', child: Text('Essay')),
                  DropdownMenuItem(value: 'multi_select', child: Text('Multi Select')),
                ],
                onChanged: (value) {
                  setState(() {
                    _questionType = value ?? 'multiple_choice';
                    _titleCtrl.text = '${_backendQuestionTypeLabel(_questionType)} Section';
                  });
                },
              ),
              const SizedBox(height: 12),
              _DialogTextField(label: 'Description', controller: _descriptionCtrl, maxLines: 2),
              const SizedBox(height: 12),
              _DialogTextField(label: 'Time limit minutes (optional)', controller: _timeCtrl, numeric: true),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _mustComplete,
                onChanged: (value) => setState(() => _mustComplete = value ?? true),
                title: const Text('Students must complete this section'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const Spacer(),
                  FilledButton(onPressed: _submit, child: const Text('Add section')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddQuestionsToSectionDialog extends StatefulWidget {
  final ExamSectionDetailsModel section;
  final List<QuestionModel> questions;

  const _AddQuestionsToSectionDialog({required this.section, required this.questions});

  @override
  State<_AddQuestionsToSectionDialog> createState() => _AddQuestionsToSectionDialogState();
}

class _AddQuestionsToSectionDialogState extends State<_AddQuestionsToSectionDialog> {
  final _searchCtrl = TextEditingController();
  final Set<int> _selectedIds = <int>{};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<QuestionModel> get _filtered {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return widget.questions;
    return widget.questions.where((question) {
      return question.text.toLowerCase().contains(query) ||
          (question.topicName ?? '').toLowerCase().contains(query) ||
          question.difficultyLabel.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
              child: Row(
                children: [
                  _IconBox(icon: Icons.playlist_add_rounded, color: AppColors.primary, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add questions', style: _textStyle(color: AppColors.textTitle, size: 19, weight: FontWeight.w900)),
                        const SizedBox(height: 3),
                        Text('${widget.section.title} • ${_backendQuestionTypeLabel(widget.section.questionType)}', style: _textStyle(color: AppColors.textMuted, size: 12, weight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: _dialogInputDecoration('Search saved questions'),
              ),
            ),
            Divider(height: 1, color: AppColors.border),
            Expanded(
              child: filtered.isEmpty
                  ? _StateMessage(
                      icon: Icons.search_off_rounded,
                      title: 'No matching questions',
                      message: widget.questions.isEmpty
                          ? 'There are no unused saved questions matching this section type.'
                          : 'No question matches the current search.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final question = filtered[index];
                        final id = question.remoteId;
                        final selected = id != null && _selectedIds.contains(id);
                        return CheckboxListTile(
                          value: selected,
                          onChanged: id == null
                              ? null
                              : (value) => setState(() {
                                    if (value ?? false) {
                                      _selectedIds.add(id);
                                    } else {
                                      _selectedIds.remove(id);
                                    }
                                  }),
                          title: Text(question.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: _textStyle(color: AppColors.textTitle, size: 13, weight: FontWeight.w800)),
                          subtitle: Text('${question.difficultyLabel} • ${question.topicName ?? question.contextLabel}', style: _textStyle(color: AppColors.textMuted, size: 11.5, weight: FontWeight.w700)),
                          controlAffinity: ListTileControlAffinity.leading,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: selected ? AppColors.primary : AppColors.border)),
                          tileColor: selected ? AppColors.primarySoft : AppColors.cardBg,
                        );
                      },
                    ),
            ),
            Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
              child: Row(
                children: [
                  Text('${_selectedIds.length} selected', style: _textStyle(color: AppColors.textMuted, size: 12, weight: FontWeight.w800)),
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 10),
                  FilledButton(onPressed: _selectedIds.isEmpty ? null : () => Navigator.of(context).pop(Set<int>.from(_selectedIds)), child: const Text('Add selected')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool numeric;
  final int maxLines;

  const _DialogTextField({required this.label, required this.controller, this.numeric = false, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: _dialogInputDecoration(label),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Row(
        children: [
           Icon(Icons.error_outline_rounded, color: AppColors.dangerText, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: _textStyle(color: AppColors.dangerText, size: 12, weight: FontWeight.w800))),
        ],
      ),
    );
  }
}

InputDecoration _dialogInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.surfaceBg,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
  );
}

QuestionType? _questionTypeFromBackend(String raw) {
  switch (raw.trim()) {
    case 'multiple_choice':
      return QuestionType.multipleChoice;
    case 'true_false':
      return QuestionType.trueFalse;
    case 'short_answer':
      return QuestionType.shortAnswer;
    case 'essay':
      return QuestionType.essay;
    case 'multi_select':
      return QuestionType.multiSelect;
    case 'fill_in_the_blank':
    case 'fill_in_blank':
      return QuestionType.fillInTheBlank;
    case 'numeric':
      return QuestionType.numeric;
    case 'code':
      return QuestionType.code;
    default:
      return null;
  }
}

String _backendQuestionTypeLabel(String raw) {
  switch (raw.trim()) {
    case 'multiple_choice':
      return 'Multiple Choice';
    case 'true_false':
      return 'True / False';
    case 'short_answer':
      return 'Short Answer';
    case 'essay':
      return 'Essay';
    case 'multi_select':
      return 'Multi Select';
    default:
      return _titleCase(raw.replaceAll('_', ' '));
  }
}

