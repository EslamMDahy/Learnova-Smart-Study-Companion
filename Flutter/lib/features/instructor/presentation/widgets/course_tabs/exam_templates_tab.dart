import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/widgets/app_ui_components.dart';
import '../../../data/courses_models.dart';
import '../../../data/exam_templates_storage.dart';

class CourseExamTemplatesTab extends ConsumerStatefulWidget {
  final MyCourseItem course;

  const CourseExamTemplatesTab({super.key, required this.course});

  @override
  ConsumerState<CourseExamTemplatesTab> createState() => _CourseExamTemplatesTabState();
}

class _CourseExamTemplatesTabState extends ConsumerState<CourseExamTemplatesTab> {
  bool _loading = true;
  String? _error;
  List<ExamTemplateModel> _templates = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final templates = await ref.read(examTemplatesStorageProvider).load(widget.course.id);
      if (!mounted) return;
      setState(() {
        _templates = templates;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load exam templates.';
      });
    }
  }

  Future<void> _openEditor([ExamTemplateModel? template]) async {
    final saved = await showDialog<ExamTemplateModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ExamTemplateEditorDialog(
        courseId: widget.course.id,
        template: template,
      ),
    );
    if (saved == null) return;
    setState(() => _error = null);
    try {
      final templates = await ref.read(examTemplatesStorageProvider).upsert(widget.course.id, saved);
      if (!mounted) return;
      setState(() => _templates = templates);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not save exam template: $e');
    }
  }

  Future<void> _delete(ExamTemplateModel template) async {
    if (template.isCustom || template.isDefault) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete template'),
        content: Text('Delete "${template.name}" from this course?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _error = null);
    try {
      final templates = await ref.read(examTemplatesStorageProvider).delete(widget.course.id, template.id);
      if (!mounted) return;
      setState(() => _templates = templates);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not delete exam template: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalQuestions = _templates.fold<int>(
      0,
      (sum, template) => sum + template.questionCount,
    );
    final customTemplates = _templates.where((template) => !template.isDefault).length;

    return Container(
      color: AppColors.pageBg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TemplatesHeader(
                  loading: _loading,
                  totalTemplates: _templates.length,
                  customTemplates: customTemplates,
                  totalQuestions: totalQuestions,
                  onRefresh: _load,
                  onCreate: () => _openEditor(),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowThin,
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _error != null
                              ? _TemplatesError(message: _error!, onRetry: _load)
                              : _templates.isEmpty
                                  ? _TemplatesEmpty(onCreate: () => _openEditor())
                                  : _TemplatesList(
                                      templates: _templates,
                                      onEdit: _openEditor,
                                      onDelete: _delete,
                                    ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplatesHeader extends StatelessWidget {
  final bool loading;
  final int totalTemplates;
  final int customTemplates;
  final int totalQuestions;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

  const _TemplatesHeader({
    required this.loading,
    required this.totalTemplates,
    required this.customTemplates,
    required this.totalQuestions,
    required this.onRefresh,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF145CCB), Color(0xFF137FEC), Color(0xFF22C1F1)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;

          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: loading ? null : onRefresh,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white.withOpacity(0.5),
                  side: BorderSide(color: Colors.white.withOpacity(0.35)),
                  backgroundColor: Colors.white.withOpacity(0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh'),
              ),
              FilledButton.icon(
                onPressed: onCreate,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New Template'),
              ),
            ],
          );

          final stats = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _TemplateHeaderCounter(label: 'Templates', value: totalTemplates),
              _TemplateHeaderCounter(label: 'Custom', value: customTemplates),
              _TemplateHeaderCounter(label: 'Questions', value: totalQuestions),
            ],
          );

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Text(
                  'Templates',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Assessment Templates',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Define reusable exam structures before selecting topics, outcomes, and questions.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.84),
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: 18),
                stats,
                const SizedBox(height: 10),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: copy),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  stats,
                  const SizedBox(height: 10),
                  actions,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TemplateHeaderCounter extends StatelessWidget {
  final String label;
  final int value;

  const _TemplateHeaderCounter({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 11.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplatesList extends StatelessWidget {
  final List<ExamTemplateModel> templates;
  final ValueChanged<ExamTemplateModel> onEdit;
  final ValueChanged<ExamTemplateModel> onDelete;

  const _TemplatesList({required this.templates, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          color: AppColors.surfaceBg,
          child: const Row(
            children: [
              Expanded(flex: 36, child: _HeaderCell('Template')),
              Expanded(flex: 18, child: _HeaderCell('Shape')),
              Expanded(flex: 24, child: _HeaderCell('Settings')),
              SizedBox(width: 96, child: _HeaderCell('Actions')),
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.border),
        Expanded(
          child: ListView.separated(
            itemCount: templates.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, index) {
              final template = templates[index];
              return _TemplateRow(
                template: template,
                onEdit: () => onEdit(template),
                onDelete: () => onDelete(template),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 0.6),
    );
  }
}

class _TemplateRow extends StatefulWidget {
  final ExamTemplateModel template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateRow({required this.template, required this.onEdit, required this.onDelete});

  @override
  State<_TemplateRow> createState() => _TemplateRowState();
}

class _TemplateRowState extends State<_TemplateRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.template;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        color: _hovered ? AppColors.hoverBg : AppColors.cardBg,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 36,
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(11)),
                    child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textTitle, fontSize: 14, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 3),
                        Text(_templateRowSubtitle(t), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 18,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ..._distributionBadges(t),
                ],
              ),
            ),
            Expanded(
              flex: 24,
              child: Text(
                '${t.durationMinutes} min • ${t.maxAttempts} attempt${t.maxAttempts == 1 ? '' : 's'} • ${t.passingScore.toStringAsFixed(0)}% pass • ${t.shuffleQuestions ? 'shuffle Q' : 'fixed Q'} • ${t.shuffleAnswers ? 'shuffle answers' : 'fixed answers'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(
              width: 96,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: t.isCustom ? 'Duplicate defaults by creating a new template' : 'Edit template',
                    onPressed: t.isCustom ? null : widget.onEdit,
                    icon: Icon(Icons.edit_outlined, size: 18, color: t.isCustom ? AppColors.textHint : AppColors.primary),
                  ),
                  IconButton(
                    tooltip: t.isCustom ? 'Custom cannot be deleted' : 'Delete template',
                    onPressed: t.isCustom || t.isDefault ? null : widget.onDelete,
                    icon: Icon(Icons.delete_outline_rounded, size: 18, color: t.isCustom || t.isDefault ? AppColors.textHint : AppColors.dangerText),
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

class _MiniBadge extends StatelessWidget {
  final String label;
  const _MiniBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: TextStyle(color: AppColors.textTitle, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}


class _ExamTemplateEditorDialog extends StatefulWidget {
  final int courseId;
  final ExamTemplateModel? template;

  const _ExamTemplateEditorDialog({required this.courseId, this.template});

  @override
  State<_ExamTemplateEditorDialog> createState() => _ExamTemplateEditorDialogState();
}

class _ExamTemplateEditorDialogState extends State<_ExamTemplateEditorDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _attemptsCtrl;
  late final TextEditingController _passingCtrl;
  late String _examType;
  late bool _shuffleQuestions;
  late bool _shuffleAnswers;
  late final List<_TemplateSectionDraft> _sectionDrafts;
  String? _error;

  int get _totalQuestions => _sectionDrafts.fold<int>(0, (sum, draft) => sum + draft.questionCount);
  double get _totalScore => _sectionDrafts.fold<double>(0, (sum, draft) => sum + draft.sectionScore);
  int get _activeSectionCount => _sectionDrafts.where((draft) => draft.questionCount > 0).length;

  @override
  void initState() {
    super.initState();
    final template = widget.template ?? ExamTemplateModel.custom(widget.courseId).copyWith(
      id: 'new-${DateTime.now().microsecondsSinceEpoch}',
      name: '',
      description: '',
    );
    _nameCtrl = TextEditingController(text: template.name == 'Custom exam' ? '' : template.name);
    _durationCtrl = TextEditingController(text: template.durationMinutes.toString());
    _attemptsCtrl = TextEditingController(text: template.maxAttempts.toString());
    _passingCtrl = TextEditingController(text: template.passingScore.toStringAsFixed(0));
    _examType = template.examType;
    _shuffleQuestions = template.shuffleQuestions;
    _shuffleAnswers = template.shuffleAnswers;
    _sectionDrafts = _TemplateSectionDraft.fromTemplate(template);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _durationCtrl.dispose();
    _attemptsCtrl.dispose();
    _passingCtrl.dispose();
    for (final draft in _sectionDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _clearDistribution() {
    for (final draft in _sectionDrafts) {
      draft.setQuestionCount(0);
    }
    setState(() => _error = null);
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final duration = int.tryParse(_durationCtrl.text.trim()) ?? 0;
    final attempts = int.tryParse(_attemptsCtrl.text.trim()) ?? -1;
    final passing = double.tryParse(_passingCtrl.text.trim()) ?? -1;
    final activeSections = <ExamTemplateSectionModel>[];
    final now = DateTime.now();

    for (final draft in _sectionDrafts) {
      if (draft.hasNegativeQuestionCount) {
        setState(() => _error = '${draft.label} question count cannot be negative.');
        return;
      }
      final count = draft.questionCount;
      final points = draft.pointsPerQuestion;
      if (count > 0 && points <= 0) {
        setState(() => _error = '${draft.label} points must be greater than zero.');
        return;
      }
      if (count > 0) {
        activeSections.add(draft.toModel(orderIndex: activeSections.length + 1, now: now));
      }
    }

    final qCount = activeSections.fold<int>(0, (sum, section) => sum + section.questionCount);
    if (name.isEmpty) {
      setState(() => _error = 'Template name is required.');
      return;
    }
    if (qCount <= 0) {
      setState(() => _error = 'Add at least one question in the template blueprint.');
      return;
    }
    if (duration <= 0) {
      setState(() => _error = 'Duration must be greater than zero.');
      return;
    }
    if (attempts < 0) {
      setState(() => _error = 'Attempts cannot be negative.');
      return;
    }
    if (passing < 0 || passing > 100) {
      setState(() => _error = 'Passing score must be between 0 and 100.');
      return;
    }

    final original = widget.template;
    Navigator.of(context).pop(ExamTemplateModel(
      id: original?.id ?? 'new-${now.microsecondsSinceEpoch}',
      courseId: widget.courseId,
      name: name,
      description: '',
      examType: _examType,
      questionCount: qCount,
      durationMinutes: duration,
      maxAttempts: attempts,
      passingScore: passing,
      shuffleQuestions: _shuffleQuestions,
      shuffleAnswers: _shuffleAnswers,
      showResultImmediately: true,
      allowReview: true,
      publishAfterSave: false,
      preferredDifficulty: null,
      instructions: '',
      createdAt: original?.createdAt ?? now,
      updatedAt: now,
      sections: activeSections,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.template != null;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080, maxHeight: 820),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Material(
            color: AppColors.cardBg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TemplateEditorHeader(
                  isEditing: isEditing,
                  totalQuestions: _totalQuestions,
                  onClose: () => Navigator.of(context).pop(),
                ),
                Divider(height: 1, color: AppColors.borderGray),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_error != null) ...[
                          _EditorAlert(message: _error!),
                          const SizedBox(height: 14),
                        ],
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 900;
                            final essentials = _TemplateEssentialsPanel(
                              nameCtrl: _nameCtrl,
                              examType: _examType,
                              durationCtrl: _durationCtrl,
                              attemptsCtrl: _attemptsCtrl,
                              passingCtrl: _passingCtrl,
                              shuffleQuestions: _shuffleQuestions,
                              shuffleAnswers: _shuffleAnswers,
                              onExamTypeChanged: (value) => setState(() => _examType = value),
                              onShuffleQuestionsChanged: (value) => setState(() => _shuffleQuestions = value),
                              onShuffleAnswersChanged: (value) => setState(() => _shuffleAnswers = value),
                            );
                            final blueprint = _TemplateDistributionEditor(
                              drafts: _sectionDrafts,
                              totalQuestions: _totalQuestions,
                              totalScore: _totalScore,
                              onChanged: () => setState(() => _error = null),
                              onClear: _clearDistribution,
                            );
                            if (!wide) {
                              return Column(
                                children: [
                                  essentials,
                                  const SizedBox(height: 16),
                                  blueprint,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: 330, child: essentials),
                                const SizedBox(width: 16),
                                Expanded(child: blueprint),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: AppColors.borderGray),
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
                  color: AppColors.cardBg,
                  child: Row(
                    children: [
                      _FooterStat(label: 'Sections', value: '$_activeSectionCount'),
                      const SizedBox(width: 10),
                      _FooterStat(label: 'Questions', value: '$_totalQuestions'),
                      const SizedBox(width: 10),
                      _FooterStat(label: 'Score', value: _formatPoints(_totalScore)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_outlined, size: 17),
                        label: Text(isEditing ? 'Update Template' : 'Save Template'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
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
}

class _TemplateEditorHeader extends StatelessWidget {
  final bool isEditing;
  final int totalQuestions;
  final VoidCallback onClose;

  const _TemplateEditorHeader({required this.isEditing, required this.totalQuestions, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 18, 20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [BoxShadow(color: AppColors.shadowThin, blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF137FEC), Color(0xFF22C1F1)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.20), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.account_tree_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isEditing ? 'Edit Exam Template' : 'Create Exam Template',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textTitle, fontSize: 22, height: 1.05, fontWeight: FontWeight.w900, letterSpacing: -0.4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _MiniBadge('$totalQuestions questions'),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Define reusable settings, supported question types, question counts, and points. Difficulty is chosen only when generating an exam.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, color: AppColors.textMuted, size: 22),
          ),
        ],
      ),
    );
  }
}

class _TemplateEssentialsPanel extends StatelessWidget {
  final TextEditingController nameCtrl;
  final String examType;
  final TextEditingController durationCtrl;
  final TextEditingController attemptsCtrl;
  final TextEditingController passingCtrl;
  final bool shuffleQuestions;
  final bool shuffleAnswers;
  final ValueChanged<String> onExamTypeChanged;
  final ValueChanged<bool> onShuffleQuestionsChanged;
  final ValueChanged<bool> onShuffleAnswersChanged;

  const _TemplateEssentialsPanel({
    required this.nameCtrl,
    required this.examType,
    required this.durationCtrl,
    required this.attemptsCtrl,
    required this.passingCtrl,
    required this.shuffleQuestions,
    required this.shuffleAnswers,
    required this.onExamTypeChanged,
    required this.onShuffleQuestionsChanged,
    required this.onShuffleAnswersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _EditorCard(
      icon: Icons.tune_rounded,
      title: 'Template settings',
      subtitle: 'Saved directly in the FastAPI template endpoint: name, exam type, duration, attempts, passing, and shuffle settings.',
      child: Column(
        children: [
          _EditorTextField(label: 'Template name', controller: nameCtrl, hint: 'Example: Java chapter quiz'),
          const SizedBox(height: 12),
          _EditorChoice<String>(
            label: 'Exam type',
            width: double.infinity,
            value: examType,
            options: const [
              _ChoiceItem(value: 'quiz', label: 'Quiz'),
              _ChoiceItem(value: 'midterm', label: 'Midterm'),
              _ChoiceItem(value: 'final', label: 'Final'),
              _ChoiceItem(value: 'practice', label: 'Practice'),
            ],
            onChanged: onExamTypeChanged,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _EditorTextField(label: 'Duration', controller: durationCtrl, hint: '60', number: true, suffix: 'min')),
              const SizedBox(width: 10),
              Expanded(child: _EditorTextField(label: 'Attempts', controller: attemptsCtrl, hint: '1', number: true)),
            ],
          ),
          const SizedBox(height: 12),
          _EditorTextField(label: 'Passing score', controller: passingCtrl, hint: '60', number: true, suffix: '%'),
          const SizedBox(height: 14),
          _EditorSwitch(title: 'Shuffle questions', value: shuffleQuestions, onChanged: onShuffleQuestionsChanged),
          const SizedBox(height: 10),
          _EditorSwitch(title: 'Shuffle answer options', value: shuffleAnswers, onChanged: onShuffleAnswersChanged),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderGray),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Templates stay reusable: they store the exam metadata and each section shape only. Easy / Medium / Hard is selected later in Generate Exam.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.35, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorAlert extends StatelessWidget {
  final String message;

  const _EditorAlert({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.dangerText, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: AppColors.dangerText, fontWeight: FontWeight.w800, fontSize: 12.5))),
        ],
      ),
    );
  }
}


class _TemplateDistributionEditor extends StatelessWidget {
  final List<_TemplateSectionDraft> drafts;
  final int totalQuestions;
  final double totalScore;
  final VoidCallback onChanged;
  final VoidCallback onClear;

  const _TemplateDistributionEditor({
    required this.drafts,
    required this.totalQuestions,
    required this.totalScore,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return _EditorCard(
      icon: Icons.grid_view_rounded,
      title: 'Template section blueprint',
      subtitle: 'Static section shape only: choose question type counts and score rules. Difficulty is not part of the template.',
      trailing: _PresetChip(label: 'Clear all', danger: true, onPressed: onClear),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricTile(label: 'Questions', value: '$totalQuestions'),
              _MetricTile(label: 'Total score', value: _formatPoints(totalScore)),
              _MetricTile(label: 'Active types', value: '${drafts.where((draft) => draft.questionCount > 0).length}'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGray),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Expanded(flex: 34, child: _DistributionHeader('Question type')),
                    SizedBox(width: 8),
                    SizedBox(width: 96, child: _DistributionHeader('Questions')),
                    SizedBox(width: 8),
                    SizedBox(width: 96, child: _DistributionHeader('Point / Q')),
                    SizedBox(width: 8),
                    SizedBox(width: 82, child: _DistributionHeader('Score')),
                  ],
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < drafts.length; i++) ...[
                  _TemplateDistributionRow(draft: drafts[i], onChanged: onChanged),
                  if (i != drafts.length - 1) Divider(height: 14, color: AppColors.borderGray),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'How grading works: total score = questions in each active row × point per question. Difficulty mix is configured at generation time, so the same template can produce easy or hard exams.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.4, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DistributionHeader extends StatelessWidget {
  final String label;

  const _DistributionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
    );
  }
}

class _TemplateDistributionRow extends StatelessWidget {
  final _TemplateSectionDraft draft;
  final VoidCallback onChanged;

  const _TemplateDistributionRow({required this.draft, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final active = draft.questionCount > 0;
    return Row(
      children: [
        Expanded(
          flex: 34,
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: active ? AppColors.primarySoft : AppColors.surfaceBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: Icon(draft.icon, size: 16, color: active ? AppColors.primary : AppColors.textHint),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textTitle, fontSize: 12.5, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      active ? '${draft.questionCount} questions • ${_formatPoints(draft.sectionScore)} pts' : 'Disabled',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 96, child: _SmallDistributionField(controller: draft.questionCountCtrl, hint: '0', onChanged: onChanged)),
        const SizedBox(width: 8),
        SizedBox(width: 96, child: _SmallDistributionField(controller: draft.pointsCtrl, hint: '1', onChanged: onChanged, decimal: true)),
        const SizedBox(width: 8),
        SizedBox(width: 82, child: _ReadonlyDistributionValue(value: _formatPoints(draft.sectionScore), active: active)),
      ],
    );
  }
}

class _ReadonlyDistributionValue extends StatelessWidget {
  final String value;
  final bool active;

  const _ReadonlyDistributionValue({required this.value, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.primarySoft : AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: active ? AppColors.primary : AppColors.textMuted, fontSize: 12.5, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _SmallDistributionField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;
  final bool decimal;

  const _SmallDistributionField({required this.controller, required this.hint, required this.onChanged, this.decimal = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      onChanged: (_) => onChanged(),
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.textTitle, fontSize: 12.5, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        filled: true,
        fillColor: AppColors.fieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 12, fontWeight: FontWeight.w600),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.borderGray)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.borderGray)),
      ),
    );
  }
}

class _TemplateSectionDraft {
  final int? id;
  final int? templateId;
  final String questionType;
  final String label;
  final IconData icon;
  final TextEditingController questionCountCtrl;
  final TextEditingController pointsCtrl;

  _TemplateSectionDraft({
    this.id,
    this.templateId,
    required this.questionType,
    required this.label,
    required this.icon,
    required int questionCount,
    required double pointsPerQuestion,
  })  : questionCountCtrl = TextEditingController(text: questionCount.toString()),
        pointsCtrl = TextEditingController(text: _formatPoints(pointsPerQuestion));

  int get questionCount => int.tryParse(questionCountCtrl.text.trim()) ?? 0;
  double get pointsPerQuestion => double.tryParse(pointsCtrl.text.trim()) ?? 0;
  double get sectionScore => questionCount * (pointsPerQuestion > 0 ? pointsPerQuestion : 0);

  bool get hasNegativeQuestionCount => _isNegative(questionCountCtrl.text);

  ExamTemplateSectionModel toModel({required int orderIndex, required DateTime now}) {
    final points = pointsPerQuestion > 0 ? pointsPerQuestion : 1.0;
    final count = questionCount;
    return ExamTemplateSectionModel(
      id: id,
      templateId: templateId,
      title: _sectionTitle(questionType),
      questionType: questionType,
      questionCount: count,
      pointsPerQuestion: points,
      sectionScore: count * points,
      orderIndex: orderIndex,
      difficultyDistribution: const <String, int>{},
      createdAt: now,
      updatedAt: now,
    );
  }

  void setQuestionCount(int value) {
    questionCountCtrl.text = value.toString();
  }

  void dispose() {
    questionCountCtrl.dispose();
    pointsCtrl.dispose();
  }

  static List<_TemplateSectionDraft> fromTemplate(ExamTemplateModel template) {
    final byType = <String, ExamTemplateSectionModel>{
      for (final section in template.sections) section.questionType: section,
    };
    if (byType.isEmpty) {
      for (final section in template.distributionSections) {
        byType[section.questionType] = section;
      }
    }

    return _supportedTemplateSectionTypes.map((spec) {
      final section = byType[spec.questionType];
      final fallbackCount = section == null && spec.questionType == 'multiple_choice' ? template.questionCount : 0;
      return _TemplateSectionDraft(
        id: section?.id,
        templateId: section?.templateId,
        questionType: spec.questionType,
        label: spec.label,
        icon: spec.icon,
        questionCount: section?.questionCount ?? fallbackCount,
        pointsPerQuestion: section?.pointsPerQuestion ?? 1,
      );
    }).toList();
  }
}
class _TemplateSectionSpec {
  final String questionType;
  final String label;
  final IconData icon;

  const _TemplateSectionSpec({required this.questionType, required this.label, required this.icon});
}

const _supportedTemplateSectionTypes = <_TemplateSectionSpec>[
  _TemplateSectionSpec(questionType: 'multiple_choice', label: 'Multiple Choice', icon: Icons.radio_button_checked_rounded),
  _TemplateSectionSpec(questionType: 'true_false', label: 'True / False', icon: Icons.rule_rounded),
  _TemplateSectionSpec(questionType: 'short_answer', label: 'Short Answer', icon: Icons.short_text_rounded),
  _TemplateSectionSpec(questionType: 'essay', label: 'Essay', icon: Icons.subject_rounded),
  _TemplateSectionSpec(questionType: 'multi_select', label: 'Multi-Select', icon: Icons.checklist_rounded),
];

String _templateRowSubtitle(ExamTemplateModel template) {
  final sections = template.distributionSections;
  if (sections.isEmpty) return '${template.examType.toUpperCase()} • ${template.questionCount} questions • ${_formatPoints(template.questionCount.toDouble())} pts';
  final types = sections.map((section) {
    return '${section.questionCount} ${_shortTypeLabel(section.questionType)}';
  }).join(' / ');
  return types;
}

List<Widget> _distributionBadges(ExamTemplateModel template) {
  final sections = template.distributionSections;
  final result = <Widget>[_MiniBadge('${template.questionCount} Q')];
  for (final section in sections.take(2)) {
    result.add(_MiniBadge('${section.questionCount} ${_shortTypeLabel(section.questionType)}'));
  }
  if (sections.length > 2) result.add(_MiniBadge('+${sections.length - 2} types'));
  return result;
}

String _shortTypeLabel(String questionType) {
  switch (questionType) {
    case 'true_false':
      return 'TF';
    case 'short_answer':
      return 'SA';
    case 'essay':
      return 'Essay';
    case 'multi_select':
      return 'MS';
    default:
      return 'MCQ';
  }
}

String _sectionTitle(String questionType) {
  switch (questionType) {
    case 'true_false':
      return 'True / False Questions';
    case 'short_answer':
      return 'Short Answer Questions';
    case 'essay':
      return 'Essay Questions';
    case 'multi_select':
      return 'Multi-Select Questions';
    default:
      return 'Multiple Choice Questions';
  }
}

String _formatPoints(double value) {
  if (value % 1 == 0) return value.toInt().toString();
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

bool _isNegative(String raw) {
  final parsed = int.tryParse(raw.trim());
  return parsed != null && parsed < 0;
}

class _ChoiceItem<T> {
  final T value;
  final String label;

  const _ChoiceItem({required this.value, required this.label});
}

class _EditorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  const _EditorCard({required this.icon, required this.title, required this.subtitle, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: TextStyle(color: AppColors.textTitle, fontSize: 15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.35, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool danger;

  const _PresetChip({required this.label, required this.onPressed, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: danger ? AppColors.dangerBg : AppColors.cardBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: danger ? AppColors.dangerBorder : AppColors.borderGray),
        ),
        child: Text(
          label,
          style: TextStyle(color: danger ? AppColors.dangerText : AppColors.textTitle, fontSize: 11.5, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderGray)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: AppColors.textTitle, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _FooterStat extends StatelessWidget {
  final String label;
  final String value;

  const _FooterStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderGray)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w900)),
          const SizedBox(width: 7),
          Text(value, style: TextStyle(color: AppColors.textTitle, fontSize: 12.5, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _EditorChoice<T> extends StatelessWidget {
  final String label;
  final double width;
  final T value;
  final List<_ChoiceItem<T>> options;
  final ValueChanged<T> onChanged;

  const _EditorChoice({
    required this.label,
    required this.width,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = options.cast<_ChoiceItem<T>?>().firstWhere(
          (item) => item != null && item.value == value,
          orElse: () => null,
        );
    final selectedLabel = selected?.label ?? (options.isEmpty ? '' : options.first.label);
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth = width.isFinite ? width : constraints.maxWidth;
        return SizedBox(
          width: effectiveWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              FigmaUmDropdown40(
                width: effectiveWidth,
                value: selectedLabel,
                items: options.map((item) => item.label).toList(growable: false),
                onChanged: (selectedText) {
                  final match = options.cast<_ChoiceItem<T>?>().firstWhere(
                        (item) => item != null && item.label == selectedText,
                        orElse: () => null,
                      );
                  if (match != null) onChanged(match.value);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EditorTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool number;
  final String? suffix;

  const _EditorTextField({required this.label, required this.controller, required this.hint, this.maxLines = 1, this.number = false, this.suffix});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          style: TextStyle(color: AppColors.textTitle, fontSize: 13, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            suffixText: suffix,
            filled: true,
            fillColor: AppColors.fieldBg,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines > 1 ? 12 : 12),
            hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13, fontWeight: FontWeight.w600),
            suffixStyle: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w800),
            enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AppColors.borderGray)),
            focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AppColors.borderGray)),
          ),
        ),
      ],
    );
  }
}

class _EditorSwitch extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _EditorSwitch({required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 12, right: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textTitle, fontSize: 12, height: 1.15, fontWeight: FontWeight.w800),
            ),
          ),
          Transform.scale(scale: 0.78, child: Switch(value: value, onChanged: onChanged)),
        ],
      ),
    );
  }
}

class _TemplatesError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _TemplatesError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.dangerText, size: 38),
          const SizedBox(height: 10),
          Text(message, style: TextStyle(color: AppColors.textTitle, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _TemplatesEmpty extends StatelessWidget {
  final VoidCallback onCreate;
  const _TemplatesEmpty({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, color: AppColors.textHint, size: 42),
          const SizedBox(height: 12),
          Text('No templates yet', style: TextStyle(color: AppColors.textTitle, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Create one template and reuse it when building exams.', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add_rounded), label: const Text('New Template')),
        ],
      ),
    );
  }
}
