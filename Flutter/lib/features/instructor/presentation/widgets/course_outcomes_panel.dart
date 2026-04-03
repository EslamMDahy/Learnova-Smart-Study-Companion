// ─────────────────────────────────────────────────────────────────────────────
//  Course Learning Outcomes Panel
//  Reused both as an embedded tab and as a dialog from quick actions.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/ui/toast.dart';
import '../../data/learning_outcomes_models.dart';
import '../../data/modules_materials_providers.dart';

final courseLOProvider =
    StateProvider.family<List<LearningOutcome>, int>((_, __) => []);
final courseLOLoadingProvider =
    StateProvider.family<bool, int>((_, __) => false);

Future<void> ensureCourseLearningOutcomesLoaded(WidgetRef ref, int courseId) async {
  final isLoading = ref.read(courseLOLoadingProvider(courseId));
  final current = ref.read(courseLOProvider(courseId));
  if (isLoading || current.isNotEmpty) return;

  ref.read(courseLOLoadingProvider(courseId).notifier).state = true;
  try {
    final res = await ref
        .read(learningOutcomesApiProvider)
        .listOutcomes(courseId: courseId);
    ref.read(courseLOProvider(courseId).notifier).state = res.outcomes;
  } catch (_) {
    // Non-fatal: leave list empty on error
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
    final content = _CourseOutcomesContent(
      courseId: courseId,
      embedded: embedded,
    );

    if (embedded) return content;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        child: content,
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
    builder: (_) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: CourseOutcomesManager(courseId: courseId),
    ),
  );
}

class _CourseOutcomesContent extends ConsumerStatefulWidget {
  final int courseId;
  final bool embedded;

  const _CourseOutcomesContent({
    required this.courseId,
    this.embedded = false,
  });

  @override
  ConsumerState<_CourseOutcomesContent> createState() =>
      _CourseOutcomesContentState();
}

class _CourseOutcomesContentState
    extends ConsumerState<_CourseOutcomesContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await ensureCourseLearningOutcomesLoaded(ref, widget.courseId);
  }

  Future<void> _openAddDialog() async {
    final result = await showDialog<LearningOutcome>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => const _AddOutcomeDialog(),
    );
    if (result == null || !mounted) return;
    await _addOutcome(result);
  }

  Future<void> _addOutcome(LearningOutcome lo) async {
    try {
      final saved = await ref
          .read(learningOutcomesApiProvider)
          .createOutcome(courseId: widget.courseId, outcome: lo);
      final current = ref.read(courseLOProvider(widget.courseId));
      final withCode = saved.copyWith(
          code: LearningOutcome.codeForIndex(current.length));
      ref.read(courseLOProvider(widget.courseId).notifier).state = [
        ...current,
        withCode,
      ];
      if (mounted) {
        AppToast.success(context, title: 'Outcome added', message: '${withCode.code} added successfully.');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, message: 'Failed to add outcome.');
      }
    }
  }

  Future<void> _updateOutcome(LearningOutcome lo) async {
    try {
      final updated = await ref
          .read(learningOutcomesApiProvider)
          .updateOutcome(courseId: widget.courseId, outcomeId: lo.id, outcome: lo);
      final current = ref.read(courseLOProvider(widget.courseId));
      ref.read(courseLOProvider(widget.courseId).notifier).state =
          current.map((o) => o.id == lo.id ? updated.copyWith(code: o.code) : o).toList();
      if (mounted) {
        AppToast.success(context, title: 'Saved', message: '${lo.code} updated.');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, message: 'Failed to update outcome.');
      }
    }
  }

  Future<void> _deleteOutcome(int id) async {
    try {
      await ref
          .read(learningOutcomesApiProvider)
          .deleteOutcome(courseId: widget.courseId, outcomeId: id);
      final current = ref.read(courseLOProvider(widget.courseId));
      final updated = current.where((o) => o.id != id).toList();
      for (var i = 0; i < updated.length; i++) {
        updated[i] = updated[i].copyWith(code: LearningOutcome.codeForIndex(i));
      }
      ref.read(courseLOProvider(widget.courseId).notifier).state = updated;
      if (mounted) {
        AppToast.success(context, title: 'Removed', message: 'Learning outcome removed.');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, message: 'Failed to remove outcome.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final outcomes = ref.watch(courseLOProvider(widget.courseId));
    final loading = ref.watch(courseLOLoadingProvider(widget.courseId));

    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.badgeBlueBg,
                  border: Border.all(color: AppColors.badgeBlueBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flag_outlined,
                  size: 17,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Learning Outcomes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textTitle,
                      ),
                    ),
                    Text(
                      '${outcomes.length} outcome${outcomes.length == 1 ? "" : "s"}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Add button
              FilledButton.icon(
                onPressed: _openAddDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Outcome'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              if (!widget.embedded) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: AppColors.textMuted,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ],
          ),
        ),
        // ── Body ────────────────────────────────────────────────────────────
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : _LOBody(
                  outcomes: outcomes,
                  onEdit: (lo) async {
                    final result = await showDialog<LearningOutcome>(
                      context: context,
                      barrierColor: Colors.black.withOpacity(0.4),
                      builder: (_) => _EditLODialog(outcome: lo),
                    );
                    if (result != null) await _updateOutcome(result);
                  },
                  onDelete: _deleteOutcome,
                  onAddFirst: _openAddDialog,
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Add Outcome Dialog  (professional modal, replaces the inline form)
// ─────────────────────────────────────────────────────────────────────────────
class _AddOutcomeDialog extends StatefulWidget {
  const _AddOutcomeDialog();

  @override
  State<_AddOutcomeDialog> createState() => _AddOutcomeDialogState();
}

class _AddOutcomeDialogState extends State<_AddOutcomeDialog> {
  final _titleCtrl = TextEditingController();
  OutcomeDifficulty _diff = OutcomeDifficulty.beginner;
  String? _titleError;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _titleCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _titleError = 'Outcome description is required.');
      return;
    }
    Navigator.pop(
      context,
      LearningOutcome(
        id: 0,
        title: text,
        difficulty: _diff,
      ),
    );
  }

  static Color _diffColor(OutcomeDifficulty d) {
    switch (d) {
      case OutcomeDifficulty.beginner:     return const Color(0xFF16A34A);
      case OutcomeDifficulty.intermediate: return const Color(0xFFD97706);
      case OutcomeDifficulty.advanced:     return const Color(0xFFDC2626);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.badgeBlueBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.badgeBlueBorder),
                  ),
                  child: const Icon(Icons.flag_outlined, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Add Learning Outcome',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textTitle)),
                    Text('Define what students will achieve',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ]),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: AppColors.textMuted,
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ]),
              const SizedBox(height: 22),

              // Outcome description
              const Text('Description',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textTitle)),
              const SizedBox(height: 6),
              TextField(
                controller: _titleCtrl,
                autofocus: true,
                maxLines: 3,
                minLines: 2,
                onChanged: (_) {
                  if (_titleError != null) setState(() => _titleError = null);
                },
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'e.g. Students will be able to explain the key concepts of...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint, height: 1.5),
                  errorText: _titleError,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFEF4444))),
                ),
              ),
              const SizedBox(height: 18),

              // Difficulty
              const Text('Difficulty Level',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textTitle)),
              const SizedBox(height: 8),
              Row(children: OutcomeDifficulty.values.map((d) {
                final sel = _diff == d;
                final color = _diffColor(d);
                return Expanded(child: Padding(
                  padding: EdgeInsets.only(right: d != OutcomeDifficulty.advanced ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _diff = d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? color.withOpacity(0.09) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: sel ? color : AppColors.border, width: sel ? 1.5 : 1),
                      ),
                      alignment: Alignment.center,
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(d.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel ? color : AppColors.textMuted,
                            )),
                      ]),
                    ),
                  ),
                ));
              }).toList()),
              const SizedBox(height: 24),

              // Actions
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textTitle,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Outcome'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LO Body (list only — add is now handled by modal)
// ─────────────────────────────────────────────────────────────────────────────
class _LOBody extends StatelessWidget {
  final List<LearningOutcome> outcomes;
  final ValueChanged<LearningOutcome> onEdit;
  final ValueChanged<int> onDelete;
  final VoidCallback onAddFirst;

  const _LOBody({
    required this.outcomes,
    required this.onEdit,
    required this.onDelete,
    required this.onAddFirst,
  });

  @override
  Widget build(BuildContext context) {
    if (outcomes.isEmpty) return _EmptyLO(onAdd: onAddFirst);

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: outcomes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _LOTile(
        outcome: outcomes[i],
        onEdit:   () => onEdit(outcomes[i]),
        onDelete: () => onDelete(outcomes[i].id),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Edit LO Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _EditLODialog extends StatefulWidget {
  final LearningOutcome outcome;
  const _EditLODialog({required this.outcome});

  @override
  State<_EditLODialog> createState() => _EditLODialogState();
}

class _EditLODialogState extends State<_EditLODialog> {
  late TextEditingController _ctrl;
  late OutcomeDifficulty _diff;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.outcome.title);
    _diff = widget.outcome.difficulty;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static Color _diffColor(OutcomeDifficulty d) {
    switch (d) {
      case OutcomeDifficulty.beginner:     return const Color(0xFF16A34A);
      case OutcomeDifficulty.intermediate: return const Color(0xFFD97706);
      case OutcomeDifficulty.advanced:     return const Color(0xFFDC2626);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF7C3AED)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Edit ${widget.outcome.code}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textTitle)),
              const Text('Update this learning outcome',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ])),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.textMuted,
              onPressed: () => Navigator.pop(context),
              visualDensity: VisualDensity.compact,
            ),
          ]),
          const SizedBox(height: 22),

          // Description
          const Text('Description',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textTitle)),
          const SizedBox(height: 6),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            minLines: 2,
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
            decoration: InputDecoration(
              hintText: 'Describe the learning outcome...',
              errorText: _titleError,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            ),
          ),
          const SizedBox(height: 18),

          // Difficulty
          const Text('Difficulty Level',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textTitle)),
          const SizedBox(height: 8),
          Row(children: OutcomeDifficulty.values.map((d) {
            final sel = _diff == d;
            final color = _diffColor(d);
            return Expanded(child: Padding(
              padding: EdgeInsets.only(right: d != OutcomeDifficulty.advanced ? 8 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _diff = d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? color.withOpacity(0.09) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: sel ? color : AppColors.border, width: sel ? 1.5 : 1),
                  ),
                  alignment: Alignment.center,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(d.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel ? color : AppColors.textMuted,
                        )),
                  ]),
                ),
              ),
            ));
          }).toList()),
          const SizedBox(height: 24),

          // Actions
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textTitle,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () {
                final t = _ctrl.text.trim();
                if (t.isEmpty) {
                  setState(() => _titleError = 'Description is required.');
                  return;
                }
                Navigator.pop(context, widget.outcome.copyWith(title: t, difficulty: _diff));
              },
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Save Changes'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              ),
            ),
          ]),
        ]),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sub widgets
// ─────────────────────────────────────────────────────────────────────────────
class _LOTile extends StatelessWidget {
  final LearningOutcome outcome;
  final VoidCallback onEdit, onDelete;
  const _LOTile({required this.outcome, required this.onEdit, required this.onDelete});

  Color get _diffColor {
    switch (outcome.difficulty) {
      case OutcomeDifficulty.beginner:     return const Color(0xFF16A34A);
      case OutcomeDifficulty.intermediate: return const Color(0xFFD97706);
      case OutcomeDifficulty.advanced:     return const Color(0xFFDC2626);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.badgeBlueBg,
          border: Border.all(color: AppColors.badgeBlueBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(outcome.code,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.badgeBlueFg)),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: _diffColor.withOpacity(0.09),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: _diffColor, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(outcome.difficulty.label,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _diffColor)),
        ]),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(outcome.title,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textTitle, height: 1.4))),
      IconButton(
          icon: const Icon(Icons.edit_outlined, size: 15),
          color: AppColors.textMuted,
          visualDensity: VisualDensity.compact,
          onPressed: onEdit),
      IconButton(
          icon: const Icon(Icons.delete_outline, size: 15),
          color: AppColors.dangerText,
          visualDensity: VisualDensity.compact,
          onPressed: onDelete),
    ]),
  );
}

class _EmptyLO extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyLO({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: AppColors.badgeBlueBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.flag_outlined, size: 26, color: AppColors.primary),
        ),
        const SizedBox(height: 14),
        const Text('No learning outcomes yet',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textTitle)),
        const SizedBox(height: 6),
        const Text(
          'Define what students will achieve\nby completing this course.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add First Outcome'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          ),
        ),
      ]),
    ),
  );
}
