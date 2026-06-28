import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:learnova/core/theme/app_theme.dart';
import 'package:learnova/core/ui/toast.dart';
import '../../data/learning_outcomes_models.dart';
import '../../data/modules_materials_providers.dart';

final courseLOProvider = StateProvider.family<List<LearningOutcome>, int>((_, __) => []);
final courseLOLoadingProvider = StateProvider.family<bool, int>((_, __) => false);
final courseLOErrorProvider = StateProvider.family<String?, int>((_, __) => null);

Future<void> ensureCourseLearningOutcomesLoaded(
  WidgetRef ref,
  int courseId, {
  bool force = false,
}) async {
  final isLoading = ref.read(courseLOLoadingProvider(courseId));
  final current = ref.read(courseLOProvider(courseId));
  if (isLoading || (!force && current.isNotEmpty)) return;

  ref.read(courseLOLoadingProvider(courseId).notifier).state = true;
  ref.read(courseLOErrorProvider(courseId).notifier).state = null;
  try {
    final res = await ref.read(learningOutcomesApiProvider).listOutcomes(courseId: courseId);
    ref.read(courseLOProvider(courseId).notifier).state = assignLearningOutcomeCodes(res.outcomes);
  } catch (_) {
    ref.read(courseLOErrorProvider(courseId).notifier).state =
        'Could not load learning outcomes.';
  } finally {
    ref.read(courseLOLoadingProvider(courseId).notifier).state = false;
  }
}

class CourseOutcomesManager extends ConsumerWidget {
  final int courseId;
  final bool embedded;

  const CourseOutcomesManager({
    super.key,
    required this.courseId,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = _HierarchicalOutcomesContent(courseId: courseId, embedded: embedded);
    if (embedded) return content;

    final size = MediaQuery.of(context).size;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: size.width < 1168 ? size.width - 48 : 1120,
        height: size.height * 0.86,
        child: ClipRRect(borderRadius: BorderRadius.circular(20), child: content),
      ),
    );
  }
}

Future<void> showCourseOutcomesDialog(
  BuildContext context,
  WidgetRef ref,
  int courseId,
) {
  return showDialog(
    context: context,
    builder: (_) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: CourseOutcomesManager(courseId: courseId),
    ),
  );
}

class _HierarchicalOutcomesContent extends ConsumerStatefulWidget {
  final int courseId;
  final bool embedded;

  const _HierarchicalOutcomesContent({required this.courseId, required this.embedded});

  @override
  ConsumerState<_HierarchicalOutcomesContent> createState() =>
      _HierarchicalOutcomesContentState();
}

class _HierarchicalOutcomesContentState extends ConsumerState<_HierarchicalOutcomesContent> {
  final TextEditingController _searchCtrl = TextEditingController();
  int? _expandedParentId;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool force = false}) async {
    await ensureCourseLearningOutcomesLoaded(ref, widget.courseId, force: force);
  }

  void _setOutcomes(List<LearningOutcome> outcomes) {
    ref.read(courseLOProvider(widget.courseId).notifier).state =
        assignLearningOutcomeCodes(outcomes);
  }

  Future<void> _createParent() async {
    final draft = await _showOutcomeEditor(
      context,
      title: 'Create LO',
      subtitle: 'Create an LO group such as LO1 / LO2. Add Easy, Medium, and Hard criteria under it.',
      parentMode: true,
    );
    if (draft == null || !mounted) return;

    try {
      final saved = await ref.read(learningOutcomesApiProvider).createOutcome(
            courseId: widget.courseId,
            outcome: LearningOutcome(
              id: 0,
              title: draft.title,
              description: draft.description,
              parentLearningOutcomeId: null,
              level: null,
            ),
          );
      final current = ref.read(courseLOProvider(widget.courseId));
      _setOutcomes([...current, saved]);
      setState(() => _expandedParentId = saved.id);
      if (mounted) {
        AppToast.success(context, title: 'LO added', message: saved.title);
      }
    } catch (e) {
      if (mounted) AppToast.error(context, title: 'Could not add LO', message: _friendlyError(e));
    }
  }

  Future<void> _createSub(LearningOutcome parent, OutcomeDifficulty difficulty) async {
    final draft = await _showOutcomeEditor(
      context,
      title: 'Add ${difficulty.label} criterion',
      subtitle: 'This criterion can be mapped to subtopics.',
      parentMode: false,
      difficulty: difficulty,
    );
    if (draft == null || !mounted) return;

    try {
      final saved = await ref.read(learningOutcomesApiProvider).createOutcome(
            courseId: widget.courseId,
            outcome: LearningOutcome(
              id: 0,
              title: draft.title,
              description: draft.description,
              parentLearningOutcomeId: parent.id,
              difficulty: difficulty,
              level: difficulty.backendLevel,
            ),
          );
      final current = ref.read(courseLOProvider(widget.courseId));
      _setOutcomes([...current, saved]);
      setState(() => _expandedParentId = parent.id);
      if (mounted) {
        AppToast.success(context, title: 'Criterion added', message: saved.title);
      }
    } catch (e) {
      if (mounted) AppToast.error(context, title: 'Could not add criterion', message: _friendlyError(e));
    }
  }

  Future<void> _editOutcome(LearningOutcome outcome) async {
    final draft = await _showOutcomeEditor(
      context,
      title: outcome.isParentOutcome ? 'Edit LO' : 'Edit criterion',
      subtitle: outcome.isParentOutcome
          ? 'Update the LO label.'
          : 'Update the selected criterion.',
      parentMode: outcome.isParentOutcome,
      initial: outcome,
      difficulty: outcome.difficulty,
    );
    if (draft == null || !mounted) return;

    try {
      final payload = outcome.copyWith(
        title: draft.title,
        description: draft.description,
        difficulty: draft.difficulty ?? outcome.difficulty,
        level: outcome.isParentOutcome ? null : (draft.difficulty ?? outcome.difficulty).backendLevel,
      );
      final saved = await ref.read(learningOutcomesApiProvider).updateOutcome(
            courseId: widget.courseId,
            outcomeId: outcome.id,
            outcome: payload,
          );
      final current = ref.read(courseLOProvider(widget.courseId));
      _setOutcomes(current.map((item) {
        if (item.id != outcome.id) return item;
        return saved.copyWith(
          parentLearningOutcomeId: outcome.parentLearningOutcomeId,
          level: payload.level,
          difficulty: payload.difficulty,
        );
      }).toList());
      if (mounted) AppToast.success(context, title: 'Saved', message: 'Learning outcome updated.');
    } catch (e) {
      if (mounted) AppToast.error(context, title: 'Save failed', message: _friendlyError(e));
    }
  }

  Future<void> _deleteOutcome(LearningOutcome outcome) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(outcome.isParentOutcome ? 'Delete LO?' : 'Delete criterion?'),
        content: Text(
          outcome.isParentOutcome
              ? 'Deleting an LO will also remove its criteria and mappings if the backend cascades them. Continue?'
              : 'This removes the criterion and any subtopic mapping connected to it.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await ref.read(learningOutcomesApiProvider).deleteOutcome(
            courseId: widget.courseId,
            outcomeId: outcome.id,
          );
      final current = ref.read(courseLOProvider(widget.courseId));
      _setOutcomes(current.where((item) {
        if (item.id == outcome.id) return false;
        if (outcome.isParentOutcome && item.parentLearningOutcomeId == outcome.id) {
          return false;
        }
        return true;
      }).toList());
      if (mounted) AppToast.success(context, title: 'Removed', message: 'Learning outcome deleted.');
    } catch (e) {
      if (mounted) AppToast.error(context, title: 'Delete failed', message: _friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final outcomes = ref.watch(courseLOProvider(widget.courseId));
    final loading = ref.watch(courseLOLoadingProvider(widget.courseId));
    final error = ref.watch(courseLOErrorProvider(widget.courseId));
    final query = _searchCtrl.text.trim().toLowerCase();
    final parents = outcomes.where((o) => o.isParentOutcome).toList();
    final childrenByParent = groupSubOutcomesByParent(outcomes);
    final filteredParents = query.isEmpty
        ? parents
        : parents.where((parent) {
            final children = childrenByParent[parent.id] ?? const <LearningOutcome>[];
            final text = [
              parent.code,
              parent.title,
              parent.description ?? '',
              ...children.map((c) => '${c.code} ${c.title} ${c.description ?? ''}'),
            ].join(' ').toLowerCase();
            return text.contains(query);
          }).toList();

    return ColoredBox(
      color: AppColors.pageBg,
      child: Padding(
        padding: widget.embedded ? EdgeInsets.zero : const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OutcomesHero(
              total: outcomes.length,
              parents: parents.length,
              subOutcomes: outcomes.where((o) => o.isSubOutcome).length,
              loading: loading,
              onRefresh: () => _load(force: true),
              onCreateParent: _createParent,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search LOs and criteria...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      filled: true,
                      fillColor: AppColors.cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: error != null && outcomes.isEmpty
                  ? _LoadError(message: error, onRetry: () => _load(force: true))
                  : loading && outcomes.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : filteredParents.isEmpty
                          ? _EmptyOutcomes(onCreate: _createParent)
                          : ListView.separated(
                              itemCount: filteredParents.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 14),
                              itemBuilder: (_, i) {
                                final parent = filteredParents[i];
                                return _ParentOutcomeCard(
                                  parent: parent,
                                  children: childrenByParent[parent.id] ?? const <LearningOutcome>[],
                                  expanded: _expandedParentId == parent.id || query.isNotEmpty,
                                  onToggle: () => setState(() {
                                    _expandedParentId = _expandedParentId == parent.id ? null : parent.id;
                                  }),
                                  onAddSub: (difficulty) => _createSub(parent, difficulty),
                                  onEdit: _editOutcome,
                                  onDelete: _deleteOutcome,
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutcomeDraft {
  final String title;
  final String? description;
  final OutcomeDifficulty? difficulty;
  const _OutcomeDraft({required this.title, this.description, this.difficulty});
}

Future<_OutcomeDraft?> _showOutcomeEditor(
  BuildContext context, {
  required String title,
  required String subtitle,
  required bool parentMode,
  LearningOutcome? initial,
  OutcomeDifficulty? difficulty,
}) async {
  final titleCtrl = TextEditingController(text: initial?.title ?? '');
  final descCtrl = TextEditingController(text: initial?.description ?? '');
  var selectedDifficulty = difficulty ?? initial?.difficulty ?? OutcomeDifficulty.beginner;

  final result = await showDialog<_OutcomeDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              if (!parentMode && difficulty == null) ...[
                const SizedBox(height: 16),
                Text('Difficulty level', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textTitle)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: OutcomeDifficulty.values.map((level) {
                    final selected = selectedDifficulty == level;
                    return ChoiceChip(
                      avatar: _DifficultyDot(level: level, compact: true),
                      label: Text(level.label),
                      selected: selected,
                      onSelected: (_) => setDialogState(() => selectedDifficulty = level),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final cleanTitle = titleCtrl.text.trim();
              if (cleanTitle.isEmpty) return;
              Navigator.pop(
                dialogContext,
                _OutcomeDraft(
                  title: cleanTitle,
                  description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  difficulty: parentMode ? null : selectedDifficulty,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );

  titleCtrl.dispose();
  descCtrl.dispose();
  return result;
}

class _OutcomesHero extends StatelessWidget {
  final int total;
  final int parents;
  final int subOutcomes;
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback onCreateParent;

  const _OutcomesHero({
    required this.total,
    required this.parents,
    required this.subOutcomes,
    required this.loading,
    required this.onRefresh,
    required this.onCreateParent,
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
            color: AppColors.primary.withValues(alpha: 0.18),
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
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
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
                onPressed: onCreateParent,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New LO'),
              ),
            ],
          );

          final stats = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _HeroMetric(label: 'LO', value: parents),
              _HeroMetric(label: 'Criteria', value: subOutcomes),
              _HeroMetric(label: 'Total items', value: total),
            ],
          );

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: Text(
                  'Outcomes',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Learning Outcomes',
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
                'Create course LOs and add Easy, Medium, and Hard criteria that can be mapped to subtopics.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.84),
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

class _HeroMetric extends StatelessWidget {
  final String label;
  final int value;

  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
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
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 11.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentOutcomeCard extends StatelessWidget {
  final LearningOutcome parent;
  final List<LearningOutcome> children;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<OutcomeDifficulty> onAddSub;
  final ValueChanged<LearningOutcome> onEdit;
  final ValueChanged<LearningOutcome> onDelete;

  const _ParentOutcomeCard({
    required this.parent,
    required this.children,
    required this.expanded,
    required this.onToggle,
    required this.onAddSub,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final byLevel = <OutcomeDifficulty, List<LearningOutcome>>{
      for (final level in OutcomeDifficulty.values)
        level: children.where((child) => child.difficulty == level).toList(),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.shadowThin, blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _LoCodeBadge(label: parent.code.isEmpty ? 'LO' : parent.code, primary: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(parent.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
                        if ((parent.description ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(parent.description!.trim(), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _CountPill(label: 'Criteria', value: '${children.length}'),
                  IconButton(tooltip: 'Edit', onPressed: () => onEdit(parent), icon: const Icon(Icons.edit_rounded, size: 18)),
                  IconButton(tooltip: 'Delete', onPressed: () => onDelete(parent), icon: const Icon(Icons.delete_outline_rounded, size: 18)),
                  Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 850;
                  final lanes = OutcomeDifficulty.values.map((level) {
                    return _DifficultyLane(
                      level: level,
                      outcomes: byLevel[level] ?? const <LearningOutcome>[],
                      onAdd: () => onAddSub(level),
                      onEdit: onEdit,
                      onDelete: onDelete,
                    );
                  }).toList();
                  if (compact) {
                    return Column(children: [
                      for (var i = 0; i < lanes.length; i++)
                        Padding(padding: EdgeInsets.only(bottom: i == lanes.length - 1 ? 0 : 12), child: lanes[i]),
                    ]);
                  }
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (var i = 0; i < lanes.length; i++) ...[
                      Expanded(child: lanes[i]),
                      if (i != lanes.length - 1) const SizedBox(width: 12),
                    ],
                  ]);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DifficultyLane extends StatelessWidget {
  final OutcomeDifficulty level;
  final List<LearningOutcome> outcomes;
  final VoidCallback onAdd;
  final ValueChanged<LearningOutcome> onEdit;
  final ValueChanged<LearningOutcome> onDelete;

  const _DifficultyLane({required this.level, required this.outcomes, required this.onAdd, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DifficultyDot(level: level),
              const SizedBox(width: 8),
              Expanded(child: Text(level.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textTitle))),
              TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Add')),
            ],
          ),
          const SizedBox(height: 8),
          if (outcomes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Text('No ${level.label.toLowerCase()} criteria yet.', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
            )
          else
            Column(
              children: [
                for (var i = 0; i < outcomes.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == outcomes.length - 1 ? 0 : 8),
                    child: _SubOutcomeTile(outcome: outcomes[i], onEdit: onEdit, onDelete: onDelete),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SubOutcomeTile extends StatelessWidget {
  final LearningOutcome outcome;
  final ValueChanged<LearningOutcome> onEdit;
  final ValueChanged<LearningOutcome> onDelete;

  const _SubOutcomeTile({required this.outcome, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DifficultyDot(level: outcome.difficulty),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(outcome.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
                if ((outcome.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(outcome.description!.trim(), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded, size: 18),
            onSelected: (value) {
              if (value == 'edit') onEdit(outcome);
              if (value == 'delete') onDelete(outcome);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}


Color _difficultyColor(OutcomeDifficulty level) {
  switch (level) {
    case OutcomeDifficulty.beginner:
      return const Color(0xFF16A34A);
    case OutcomeDifficulty.intermediate:
      return const Color(0xFFF59E0B);
    case OutcomeDifficulty.advanced:
      return const Color(0xFFDC2626);
  }
}

IconData _difficultyIcon(OutcomeDifficulty level) {
  switch (level) {
    case OutcomeDifficulty.beginner:
      return Icons.eco_rounded;
    case OutcomeDifficulty.intermediate:
      return Icons.bolt_rounded;
    case OutcomeDifficulty.advanced:
      return Icons.local_fire_department_rounded;
  }
}

class _DifficultyDot extends StatelessWidget {
  final OutcomeDifficulty level;
  final bool compact;

  const _DifficultyDot({required this.level, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = _difficultyColor(level);
    final size = compact ? 18.0 : 26.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Icon(_difficultyIcon(level), size: compact ? 12 : 15, color: color),
    );
  }
}

class _LoCodeBadge extends StatelessWidget {
  final String label;
  final bool primary;
  const _LoCodeBadge({required this.label, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: primary ? AppColors.primarySoft : AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary ? AppColors.badgeBlueBorder : AppColors.border),
      ),
      child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: primary ? AppColors.primary : AppColors.textMuted)),
    );
  }
}

class _CountPill extends StatelessWidget {
  final String label;
  final String value;
  const _CountPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)),
      child: Text('$value $label', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textMuted)),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
        ],
      ),
    );
  }
}

class _EmptyOutcomes extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyOutcomes({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined, size: 34, color: AppColors.primary),
            const SizedBox(height: 12),
            Text('No learning outcomes yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
            const SizedBox(height: 6),
            Text('Create an LO first, then add Easy, Medium, and Hard criteria under it.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add_rounded), label: const Text('Create LO')),
          ],
        ),
      ),
    );
  }
}

String _friendlyError(Object error) {
  final text = error.toString();
  if (text.contains('level must not be provided')) {
    return 'The backend rejected a level on an LO. Refresh and try again.';
  }
  if (text.contains('parent')) return 'Could not save LO/criteria relation.';
  return 'Please try again.';
}
