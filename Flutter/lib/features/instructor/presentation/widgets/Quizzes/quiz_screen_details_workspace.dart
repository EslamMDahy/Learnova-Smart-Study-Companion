part of 'quiz_screen.dart';

class _ExamDetailsWorkspace extends StatelessWidget {
  final ExamModel? exam;
  final MyCourseItem? course;
  final ExamDetailsModel? details;
  final bool loading;
  final String? error;
  final bool publishing;
  final bool exportingPdf;
  final VoidCallback onBack;
  final VoidCallback onRetry;
  final VoidCallback? onPublish;
  final VoidCallback? onExportPdf;
  final VoidCallback? onOpenQuestionBank;
  final VoidCallback? onAddSection;
  final ValueChanged<ExamSectionDetailsModel>? onAddQuestionsToSection;

  const _ExamDetailsWorkspace({
    required this.exam,
    required this.course,
    required this.details,
    required this.loading,
    required this.error,
    required this.publishing,
    required this.exportingPdf,
    required this.onBack,
    required this.onRetry,
    required this.onPublish,
    required this.onExportPdf,
    required this.onOpenQuestionBank,
    required this.onAddSection,
    required this.onAddQuestionsToSection,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedExam = details?.exam ?? exam;
    final questions = details?.questions ?? const <ExamQuestionDetail>[];
    final sections = details?.sections ?? const <ExamSectionDetailsModel>[];
    final questionsCount = questions.isNotEmpty ? questions.length : resolvedExam?.totalQuestions ?? 0;

    return Container(
      color: AppColors.pageBg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ExamDetailsHero(
                    exam: resolvedExam,
                    course: course,
                    questionsCount: questionsCount,
                    publishing: publishing,
                    exportingPdf: exportingPdf,
                    onBack: onBack,
                    onPublish: resolvedExam == null || resolvedExam.isPublished || publishing ? null : onPublish,
                    onExportPdf: resolvedExam == null || exportingPdf ? null : onExportPdf,
                    onOpenQuestionBank: onOpenQuestionBank,
                  ),
                  const SizedBox(height: 18),
                  if (loading)
                    const _StudioShell(child: SizedBox(height: 520, child: Center(child: CircularProgressIndicator())))
                  else if (error != null)
                    _StudioShell(child: _StateMessage(icon: Icons.error_outline_rounded, title: 'Could not load exam details', message: error!, actionLabel: 'Retry', onAction: onRetry))
                  else if (resolvedExam == null)
                    const _StudioShell(child: _StateMessage(icon: Icons.assignment_outlined, title: 'No exam selected', message: 'Go back and choose an exam from the studio.'))
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 980;
                        if (compact) {
                          return Column(
                            children: [
                              _ExamSnapshotGrid(exam: resolvedExam, questionsCount: questionsCount),
                              const SizedBox(height: 18),
                              _QuestionPaperCard(
                                sections: sections,
                                questions: questions,
                                onAddSection: onAddSection,
                                onAddQuestionsToSection: onAddQuestionsToSection,
                              ),
                              const SizedBox(height: 18),
                              _ExamBackendSettingsCard(exam: resolvedExam, course: course),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: Column(
                                children: [
                                  _ExamSnapshotGrid(exam: resolvedExam, questionsCount: questionsCount),
                                  const SizedBox(height: 18),
                                  _QuestionPaperCard(
                                sections: sections,
                                questions: questions,
                                onAddSection: onAddSection,
                                onAddQuestionsToSection: onAddQuestionsToSection,
                              ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),
                            SizedBox(
                              width: 380,
                              child: _ExamBackendSettingsCard(exam: resolvedExam, course: course),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamDetailsHero extends StatelessWidget {
  final ExamModel? exam;
  final MyCourseItem? course;
  final int questionsCount;
  final bool publishing;
  final bool exportingPdf;
  final VoidCallback onBack;
  final VoidCallback? onPublish;
  final VoidCallback? onExportPdf;
  final VoidCallback? onOpenQuestionBank;

  const _ExamDetailsHero({
    required this.exam,
    required this.course,
    required this.questionsCount,
    required this.publishing,
    required this.exportingPdf,
    required this.onBack,
    required this.onPublish,
    required this.onExportPdf,
    required this.onOpenQuestionBank,
  });

  @override
  Widget build(BuildContext context) {
    final title = exam?.title.trim().isNotEmpty ?? false ? exam!.title : 'Exam details';
    final statusColor = exam?.isPublished ?? false ? AppColors.successText : AppColors.warningText;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.shadowThin, blurRadius: 24, offset: const Offset(0, 14))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back to Exams'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.primarySoft,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.22)),
                ),
              ),
              const Spacer(),
              if (onOpenQuestionBank != null)
                OutlinedButton.icon(
                  onPressed: onOpenQuestionBank,
                  icon: const Icon(Icons.quiz_outlined, size: 18),
                  label: const Text('Question Bank'),
                ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onExportPdf,
                icon: exportingPdf
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: Text(exportingPdf ? 'Exporting...' : 'Export PDF'),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: onPublish,
                icon: publishing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon((exam?.isPublished ?? false) ? Icons.verified_rounded : Icons.publish_rounded, size: 18),
                label: Text((exam?.isPublished ?? false) ? 'Published' : publishing ? 'Publishing...' : 'Publish'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _IconBox(icon: Icons.assignment_turned_in_outlined, color: AppColors.primary, size: 58),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MiniBadge(label: exam?.isPublished ?? false ? 'Published' : 'Draft', color: statusColor),
                        _MiniBadge(label: _titleCase(exam?.examType ?? 'exam'), color: AppColors.primary),
                        if (course != null) _MiniBadge(label: course!.safeCourseCode, color: AppColors.textMuted),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: _textStyle(color: AppColors.textTitle, size: 30, weight: FontWeight.w900, letterSpacing: -0.7, height: 1.12)),
                    const SizedBox(height: 8),
                    Text(
                      '${course?.safeTitle ?? 'Course'} • $questionsCount questions • Updated ${exam == null ? '-' : _formatDate(exam!.updatedAt)}',
                      style: _textStyle(color: AppColors.textMuted, size: 13, weight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExamSnapshotGrid extends StatelessWidget {
  final ExamModel exam;
  final int questionsCount;

  const _ExamSnapshotGrid({required this.exam, required this.questionsCount});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 720 ? 2 : 4;
        final width = (constraints.maxWidth - ((columns - 1) * 14)) / columns;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(width: width, child: _MetricCard(title: 'Questions', value: '$questionsCount', subtitle: 'attached to exam', icon: Icons.quiz_outlined, color: AppColors.primary)),
            SizedBox(width: width, child: _MetricCard(title: 'Total Score', value: _points(exam.totalScore), subtitle: 'backend calculated', icon: Icons.stacked_line_chart_rounded, color: AppColors.successText)),
            SizedBox(width: width, child: _MetricCard(title: 'Duration', value: _duration(exam.durationMinutes), subtitle: 'student time limit', icon: Icons.timer_outlined, color: AppColors.warningText)),
            SizedBox(width: width, child: _MetricCard(title: 'Attempts', value: '${exam.maxAttempts}', subtitle: 'allowed attempts', icon: Icons.restart_alt_rounded, color: AppColors.purpleText)),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({required this.title, required this.value, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.shadowThin, blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _textStyle(color: AppColors.textMuted, size: 12, weight: FontWeight.w900)),
                const Spacer(),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: _textStyle(color: AppColors.textTitle, size: 24, weight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 3),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: _textStyle(color: color, size: 11, weight: FontWeight.w800)),
              ],
            ),
          ),
          _IconBox(icon: icon, color: color, size: 42),
        ],
      ),
    );
  }
}

class _QuestionPaperCard extends StatelessWidget {
  final List<ExamSectionDetailsModel> sections;
  final List<ExamQuestionDetail> questions;
  final VoidCallback? onAddSection;
  final ValueChanged<ExamSectionDetailsModel>? onAddQuestionsToSection;

  const _QuestionPaperCard({
    required this.sections,
    required this.questions,
    this.onAddSection,
    this.onAddQuestionsToSection,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty && questions.isEmpty) {
      return _StudioShell(
        child: _StateMessage(
          icon: Icons.view_agenda_outlined,
          title: 'Start manual structure',
          message: 'This draft exam has no sections yet. Add a section, then open it and attach saved questions manually.',
          actionLabel: onAddSection == null ? null : 'Add first section',
          onAction: onAddSection,
        ),
      );
    }

    return _StudioShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            icon: Icons.fact_check_outlined,
            title: 'Question paper',
            subtitle: sections.isEmpty ? '${questions.length} questions' : '${sections.length} sections • ${questions.length} questions',
            trailing: onAddSection == null
                ? null
                : FilledButton.icon(
                    onPressed: onAddSection,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add section'),
                  ),
          ),
          Divider(height: 1, color: AppColors.border),
          if (sections.isNotEmpty)
            ...sections.map((section) => _SectionBlock(section: section, onAddQuestions: onAddQuestionsToSection == null ? null : () => onAddQuestionsToSection!(section)))
          else
            ...questions.asMap().entries.map((entry) => _QuestionRow(index: entry.key + 1, question: entry.value, showSection: true)),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final ExamSectionDetailsModel section;
  final VoidCallback? onAddQuestions;

  const _SectionBlock({required this.section, this.onAddQuestions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          color: AppColors.surfaceBg,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.title, style: _textStyle(color: AppColors.textTitle, size: 14, weight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('${_titleCase(section.questionType)} • ${section.questionCount} questions • ${_points(section.sectionScore)} points', style: _textStyle(color: AppColors.textMuted, size: 11, weight: FontWeight.w800)),
                  ],
                ),
              ),
              _MiniBadge(label: section.mustComplete ? 'Required' : 'Optional', color: section.mustComplete ? AppColors.primary : AppColors.textMuted),
              if (onAddQuestions != null) ...[
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onAddQuestions,
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: const Text('Add questions'),
                ),
              ],
            ],
          ),
        ),
        ...section.questions.asMap().entries.map((entry) => _QuestionRow(index: entry.key + 1, question: entry.value, showSection: false)),
      ],
    );
  }
}

class _QuestionRow extends StatelessWidget {
  final int index;
  final ExamQuestionDetail question;
  final bool showSection;

  const _QuestionRow({required this.index, required this.question, required this.showSection});

  @override
  Widget build(BuildContext context) {
    final q = question.question;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Text(index.toString().padLeft(2, '0'), style: _textStyle(color: AppColors.textHint, size: 12, weight: FontWeight.w900)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.text, maxLines: 3, overflow: TextOverflow.ellipsis, style: _textStyle(color: AppColors.textTitle, size: 13, weight: FontWeight.w800, height: 1.38)),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MetaPill(icon: Icons.category_outlined, label: q.typeLabel),
                    _DifficultyPill(label: q.difficultyLabel),
                    _MetaPill(icon: Icons.grade_outlined, label: '${_points(question.points)} pts'),
                    if (showSection && question.sectionId > 0) _MetaPill(icon: Icons.view_agenda_outlined, label: 'Section ${question.sectionId}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamBackendSettingsCard extends StatelessWidget {
  final ExamModel exam;
  final MyCourseItem? course;

  const _ExamBackendSettingsCard({required this.exam, required this.course});

  @override
  Widget build(BuildContext context) {
    return _StudioShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelHeader(
            icon: Icons.tune_rounded,
            title: 'Backend settings',
            subtitle: 'Values returned by the instructor exam endpoint.',
          ),
          Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _SettingRow(label: 'Exam ID', value: '#${exam.id}'),
                _SettingRow(label: 'Course', value: course?.safeTitle ?? 'Course #${exam.courseId}'),
                _SettingRow(label: 'Type', value: _titleCase(exam.examType)),
                _SettingRow(label: 'Status', value: exam.isPublished ? 'Published' : 'Draft', valueColor: exam.isPublished ? AppColors.successText : AppColors.warningText),
                _SettingRow(label: 'Passing score', value: exam.passingScore == null ? 'Not set' : '${_points(exam.passingScore!)}%'),
                _SettingRow(label: 'Shuffle questions', value: exam.shuffleQuestions ? 'Enabled' : 'Disabled'),
                _SettingRow(label: 'Shuffle options', value: exam.shuffleOptions ? 'Enabled' : 'Disabled'),
                _SettingRow(label: 'Created', value: _formatDate(exam.createdAt)),
                _SettingRow(label: 'Updated', value: _formatDate(exam.updatedAt)),
                if ((exam.instructions ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoNote(title: 'Instructions', message: exam.instructions!.trim()),
                ] else ...[
                  const SizedBox(height: 12),
                  const _InfoNote(title: 'Instructions', message: 'No student-facing instructions were saved for this exam.'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _PanelHeader({required this.icon, required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 15),
      child: Row(
        children: [
          _IconBox(icon: icon, color: AppColors.primary, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _textStyle(color: AppColors.textTitle, size: 15, weight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle, style: _textStyle(color: AppColors.textMuted, size: 11, weight: FontWeight.w700)),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SettingRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: _textStyle(color: AppColors.textMuted, size: 12, weight: FontWeight.w800))),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _textStyle(color: valueColor ?? AppColors.textTitle, size: 12, weight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final String title;
  final String message;

  const _InfoNote({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _textStyle(color: AppColors.infoText, size: 12, weight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(message, style: _textStyle(color: AppColors.infoText, size: 12, weight: FontWeight.w700, height: 1.35)),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateMessage({required this.icon, required this.title, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 380),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconBox(icon: icon, color: AppColors.textHint, size: 58),
                const SizedBox(height: 16),
                Text(title, textAlign: TextAlign.center, style: _textStyle(color: AppColors.textTitle, size: 18, weight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: _textStyle(color: AppColors.textMuted, size: 13, weight: FontWeight.w700, height: 1.45)),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 18),
                  FilledButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _IconBox({required this.icon, required this.color, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(size * 0.30),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Icon(icon, color: color, size: size * 0.50),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _textStyle(color: color, size: 11, weight: FontWeight.w900)),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Text(label, style: _textStyle(color: AppColors.textMuted, size: 11, weight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _DifficultyPill extends StatelessWidget {
  final String label;

  const _DifficultyPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    final color = normalized == 'easy'
        ? AppColors.successText
        : normalized == 'hard'
            ? AppColors.dangerText
            : AppColors.warningText;
    return _MiniBadge(label: label, color: color);
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;

  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

TextStyle _textStyle({
  required Color color,
  required double size,
  required FontWeight weight,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    color: color,
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
  );
}

String _duration(int? minutes) => minutes == null || minutes <= 0 ? 'No limit' : '${minutes}m';

String _points(double value) {
  return value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
}

String _formatDate(DateTime date) {
  if (date.millisecondsSinceEpoch == 0) return '-';
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

String _titleCase(String value) {
  final normalized = value.replaceAll('_', ' ').trim();
  if (normalized.isEmpty) return 'Exam';
  return normalized
      .split(RegExp(r'\s+'))
      .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
}

ExamModel _copyExamAfterPublish(ExamModel exam, ExamPublishResponse response) {
  return ExamModel(
    id: exam.id,
    courseId: exam.courseId,
    title: exam.title,
    description: exam.description,
    instructions: exam.instructions,
    examType: exam.examType,
    durationMinutes: exam.durationMinutes,
    maxAttempts: exam.maxAttempts,
    passingScore: exam.passingScore,
    totalQuestions: response.totalQuestions == 0 ? exam.totalQuestions : response.totalQuestions,
    totalScore: response.totalScore == 0 ? exam.totalScore : response.totalScore,
    isPublished: response.isPublished,
    shuffleQuestions: exam.shuffleQuestions,
    shuffleOptions: exam.shuffleOptions,
    availableFrom: exam.availableFrom,
    availableTo: exam.availableTo,
    createdAt: exam.createdAt,
    updatedAt: DateTime.now(),
  );
}

List<_CourseExamGroup> _replaceExamInGroups(List<_CourseExamGroup> groups, int courseId, ExamModel updated) {
  return groups.map((group) {
    if (group.course.id != courseId) return group;
    return group.copyWith(
      exams: group.exams.map((exam) => exam.id == updated.id ? updated : exam).toList(),
    );
  }).toList();
}
