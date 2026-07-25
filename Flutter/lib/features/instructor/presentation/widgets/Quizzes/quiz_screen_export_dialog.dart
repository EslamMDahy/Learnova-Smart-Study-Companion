part of 'quiz_screen.dart';

class _ExamPdfExportOptions {
  final bool includeLearnovaLogo;
  final bool includeCourseTitle;
  final bool includeCourseCode;
  final bool includeExamMetadata;
  final bool includeInstructions;
  final bool includeSectionDescriptions;
  final bool includePoints;
  final bool includeStudentInfoFields;
  final bool includeAnswerSpace;
  final bool includeOcrSupport;
  final bool shuffleQuestions;
  final bool shuffleOptions;

  const _ExamPdfExportOptions({
    this.includeLearnovaLogo = true,
    this.includeCourseTitle = true,
    this.includeCourseCode = false,
    this.includeExamMetadata = true,
    this.includeInstructions = true,
    this.includeSectionDescriptions = true,
    this.includePoints = true,
    this.includeStudentInfoFields = true,
    this.includeAnswerSpace = true,
    this.includeOcrSupport = false,
    this.shuffleQuestions = false,
    this.shuffleOptions = false,
  });
}

class _ExamPdfExportOptionsDialog extends StatefulWidget {
  const _ExamPdfExportOptionsDialog();

  @override
  State<_ExamPdfExportOptionsDialog> createState() => _ExamPdfExportOptionsDialogState();
}

class _ExamPdfExportOptionsDialogState extends State<_ExamPdfExportOptionsDialog> {
  bool _includeLearnovaLogo = true;
  bool _includeCourseTitle = true;
  bool _includeCourseCode = false;
  bool _includeExamMetadata = true;
  bool _includeInstructions = true;
  bool _includeSectionDescriptions = true;
  bool _includePoints = true;
  bool _includeStudentInfoFields = true;
  bool _includeAnswerSpace = true;
  bool _includeOcrSupport = false;
  bool _shuffleQuestions = false;
  bool _shuffleOptions = false;

  void _setOcrSupport(bool value) {
    setState(() {
      _includeOcrSupport = value;
      if (value) {
        _includeStudentInfoFields = true;
        _includeAnswerSpace = true;
        _shuffleQuestions = false;
        _shuffleOptions = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 18, 16),
              child: Row(
                children: [
                  _IconBox(icon: Icons.picture_as_pdf_outlined, color: AppColors.primary, size: 46),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Export exam paper', style: _textStyle(color: AppColors.textTitle, size: 21, weight: FontWeight.w900)),
                        const SizedBox(height: 5),
                        Text('Choose the print layout and the fields rendered by the backend PDF endpoint.', style: _textStyle(color: AppColors.textMuted, size: 12.5, weight: FontWeight.w700)),
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
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ExportSectionLabel('Print mode'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ExportModeCard(
                            selected: !_includeOcrSupport,
                            icon: Icons.description_outlined,
                            title: 'Standard PDF',
                            subtitle: 'Clean paper copy for manual marking or normal distribution.',
                            onTap: () => _setOcrSupport(false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ExportModeCard(
                            selected: _includeOcrSupport,
                            icon: Icons.document_scanner_outlined,
                            title: 'OCR-ready print',
                            subtitle: 'Adds QR, student ID bubbles, answer bubbles and OCR boxes.',
                            onTap: () => _setOcrSupport(true),
                          ),
                        ),
                      ],
                    ),
                    if (_includeOcrSupport) ...[
                      const SizedBox(height: 12),
                      const _ExportNotice(
                        icon: Icons.verified_outlined,
                        title: 'OCR scan compatible',
                        message: 'This layout is prepared for the /ocr/exam-scan/analyze pipeline after students submit scanned papers. Question and option shuffling are locked off so detected answers stay aligned with the backend exam order.',
                      ),
                    ],
                    const SizedBox(height: 18),
                    _ExportSectionLabel('Header and exam details'),
                    const SizedBox(height: 10),
                    _ExportToggle(
                      title: 'Learnova logo',
                      subtitle: 'Show platform branding at the top of the paper.',
                      value: _includeLearnovaLogo,
                      onChanged: (value) => setState(() => _includeLearnovaLogo = value),
                    ),
                    _ExportToggle(
                      title: 'Course title',
                      subtitle: 'Print the course name in the exam header.',
                      value: _includeCourseTitle,
                      onChanged: (value) => setState(() => _includeCourseTitle = value),
                    ),
                    _ExportToggle(
                      title: 'Course code',
                      subtitle: 'Useful when the same exam title exists across courses.',
                      value: _includeCourseCode,
                      onChanged: (value) => setState(() => _includeCourseCode = value),
                    ),
                    _ExportToggle(
                      title: 'Exam metadata',
                      subtitle: 'Includes type, duration, total questions and total score.',
                      value: _includeExamMetadata,
                      onChanged: (value) => setState(() => _includeExamMetadata = value),
                    ),
                    _ExportToggle(
                      title: 'Instructions',
                      subtitle: 'Render the saved student-facing instructions.',
                      value: _includeInstructions,
                      onChanged: (value) => setState(() => _includeInstructions = value),
                    ),
                    const SizedBox(height: 10),
                    _ExportSectionLabel('Question paper content'),
                    const SizedBox(height: 10),
                    _ExportToggle(
                      title: 'Section descriptions',
                      subtitle: 'Show each section description above its questions.',
                      value: _includeSectionDescriptions,
                      onChanged: (value) => setState(() => _includeSectionDescriptions = value),
                    ),
                    _ExportToggle(
                      title: 'Question points',
                      subtitle: 'Print the score value next to each question.',
                      value: _includePoints,
                      onChanged: (value) => setState(() => _includePoints = value),
                    ),
                    _ExportToggle(
                      title: 'Student info fields',
                      subtitle: _includeOcrSupport ? 'OCR mode uses the dedicated name/date area and student ID bubble grid.' : 'Adds name/date fields for manual paper submissions.',
                      value: _includeStudentInfoFields,
                      enabled: !_includeOcrSupport,
                      onChanged: (value) => setState(() => _includeStudentInfoFields = value),
                    ),
                    _ExportToggle(
                      title: 'Answer space',
                      subtitle: _includeOcrSupport ? 'Required for OCR answer boxes and written-answer detection.' : 'Adds blank space for written answers.',
                      value: _includeAnswerSpace,
                      enabled: !_includeOcrSupport,
                      onChanged: (value) => setState(() => _includeAnswerSpace = value),
                    ),
                    const SizedBox(height: 10),
                    _ExportSectionLabel('Randomization'),
                    const SizedBox(height: 10),
                    _ExportToggle(
                      title: 'Shuffle questions in PDF',
                      subtitle: _includeOcrSupport ? 'Disabled for OCR so scanned answers match the backend question order.' : 'Override the saved exam setting for this export only.',
                      value: _shuffleQuestions,
                      enabled: !_includeOcrSupport,
                      onChanged: (value) => setState(() => _shuffleQuestions = value),
                    ),
                    _ExportToggle(
                      title: 'Shuffle answer options in PDF',
                      subtitle: _includeOcrSupport ? 'Disabled for OCR so selected bubbles map to the saved options.' : 'Override the saved exam setting for this export only.',
                      value: _shuffleOptions,
                      enabled: !_includeOcrSupport,
                      onChanged: (value) => setState(() => _shuffleOptions = value),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(
                        _ExamPdfExportOptions(
                          includeLearnovaLogo: _includeLearnovaLogo,
                          includeCourseTitle: _includeCourseTitle,
                          includeCourseCode: _includeCourseCode,
                          includeExamMetadata: _includeExamMetadata,
                          includeInstructions: _includeInstructions,
                          includeSectionDescriptions: _includeSectionDescriptions,
                          includePoints: _includePoints,
                          includeStudentInfoFields: _includeStudentInfoFields,
                          includeAnswerSpace: _includeAnswerSpace,
                          includeOcrSupport: _includeOcrSupport,
                          shuffleQuestions: _includeOcrSupport ? false : _shuffleQuestions,
                          shuffleOptions: _includeOcrSupport ? false : _shuffleOptions,
                        ),
                      );
                    },
                    icon: Icon(_includeOcrSupport ? Icons.document_scanner_outlined : Icons.download_rounded, size: 18),
                    label: Text(_includeOcrSupport ? 'Export OCR PDF' : 'Export PDF'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportSectionLabel extends StatelessWidget {
  final String label;

  const _ExportSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: _textStyle(
        color: AppColors.textMuted,
        size: 11,
        weight: FontWeight.w900,
      ).copyWith(letterSpacing: .8),
    );
  }
}

class _ExportModeCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.primary : AppColors.border;
    final bg = selected ? AppColors.primarySoft : AppColors.surfaceBg;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? AppColors.primary : AppColors.border),
              ),
              child: Icon(icon, color: selected ? Colors.white : AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _textStyle(color: AppColors.textTitle, size: 13.5, weight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: _textStyle(color: AppColors.textMuted, size: 11.5, weight: FontWeight.w700, height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _ExportNotice({required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.infoText, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _textStyle(color: AppColors.infoText, size: 12.5, weight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(message, style: _textStyle(color: AppColors.infoText, size: 11.5, weight: FontWeight.w700, height: 1.42)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportToggle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ExportToggle({
    required this.title,
    this.subtitle,
    required this.value,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitleColor = enabled ? AppColors.textTitle : AppColors.textHint;
    final effectiveSubtitleColor = enabled ? AppColors.textMuted : AppColors.textHint;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : .78,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: enabled ? AppColors.surfaceBg : AppColors.fieldDisabledBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _textStyle(color: effectiveTitleColor, size: 13, weight: FontWeight.w900)),
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!, style: _textStyle(color: effectiveSubtitleColor, size: 11.3, weight: FontWeight.w700, height: 1.35)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 14),
            Switch(value: value, onChanged: enabled ? onChanged : null),
          ],
        ),
      ),
    );
  }
}

enum _ExamStatusFilter { all, published, draft }

extension _ExamStatusFilterX on _ExamStatusFilter {
  String get label {
    switch (this) {
      case _ExamStatusFilter.all:
        return 'All';
      case _ExamStatusFilter.published:
        return 'Published';
      case _ExamStatusFilter.draft:
        return 'Draft';
    }
  }
}

class _CourseExamGroup {
  final MyCourseItem course;
  final List<ExamModel> exams;
  final String? error;

  const _CourseExamGroup({required this.course, required this.exams, this.error});

  int get published => exams.where((exam) => exam.isPublished).length;
  int get draft => exams.length - published;
  int get totalQuestions => exams.fold<int>(0, (sum, exam) => sum + exam.totalQuestions);
  double get totalScore => exams.fold<double>(0, (sum, exam) => sum + exam.totalScore);
  DateTime get lastUpdated {
    if (exams.isEmpty) return course.updatedAt;
    return exams.map((e) => e.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  _CourseExamGroup copyWith({List<ExamModel>? exams, String? error}) {
    return _CourseExamGroup(
      course: course,
      exams: exams ?? this.exams,
      error: error ?? this.error,
    );
  }
}


enum _ExamCreationMode { manual, automatic }

