// ─────────────────────────────────────────────────────────────────────────────
//  Course Learning Outcomes Panel
//  Reused both as an embedded tab and as a dialog from quick actions.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/ui/toast.dart';
import '../../data/learning_outcomes_models.dart';
import '../../data/mock_services.dart';

final courseLOProvider =
    StateProvider.family<List<LearningOutcome>, int>((_, __) => []);
final courseLOLoadingProvider =
    StateProvider.family<bool, int>((_, __) => false);

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
    ref.read(courseLOLoadingProvider(widget.courseId).notifier).state = true;
    final svc = ref.read(learningOutcomeMockServiceProvider);
    final list = await svc.listOutcomes(widget.courseId);
    if (!mounted) return;
    ref.read(courseLOProvider(widget.courseId).notifier).state = list;
    ref.read(courseLOLoadingProvider(widget.courseId).notifier).state = false;
  }

  Future<void> _addOutcome(LearningOutcome lo) async {
    final svc = ref.read(learningOutcomeMockServiceProvider);
    final saved = await svc.addOutcome(widget.courseId, lo);
    final current = ref.read(courseLOProvider(widget.courseId));
    ref.read(courseLOProvider(widget.courseId).notifier).state = [
      ...current,
      saved,
    ];
    if (mounted) {
      AppToast.success(context, title: 'Added', message: '${saved.code} added.');
    }
  }

  Future<void> _updateOutcome(LearningOutcome lo) async {
    final svc = ref.read(learningOutcomeMockServiceProvider);
    await svc.updateOutcome(widget.courseId, lo);
    final current = ref.read(courseLOProvider(widget.courseId));
    ref.read(courseLOProvider(widget.courseId).notifier).state =
        current.map((o) => o.id == lo.id ? lo : o).toList();
    if (mounted) {
      AppToast.success(context, title: 'Saved', message: '${lo.code} updated.');
    }
  }

  Future<void> _deleteOutcome(String id) async {
    final svc = ref.read(learningOutcomeMockServiceProvider);
    await svc.deleteOutcome(widget.courseId, id);
    final list = await svc.listOutcomes(widget.courseId);
    ref.read(courseLOProvider(widget.courseId).notifier).state = list;
    if (mounted) {
      AppToast.success(
        context,
        title: 'Removed',
        message: 'Learning outcome removed.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final outcomes = ref.watch(courseLOProvider(widget.courseId));
    final loading = ref.watch(courseLOLoadingProvider(widget.courseId));

    return Column(
      children: [
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
              if (!widget.embedded)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: AppColors.textMuted,
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : _LOBody(
                  outcomes: outcomes,
                  onAdd: _addOutcome,
                  onEdit: _updateOutcome,
                  onDelete: _deleteOutcome,
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LO Body (list + add form)
// ─────────────────────────────────────────────────────────────────────────────
class _LOBody extends StatefulWidget {
  final List<LearningOutcome> outcomes;
  final ValueChanged<LearningOutcome> onAdd;
  final ValueChanged<LearningOutcome> onEdit;
  final ValueChanged<String> onDelete;

  const _LOBody({
    required this.outcomes,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_LOBody> createState() => _LOBodyState();
}

class _LOBodyState extends State<_LOBody> {
  final _descCtrl = TextEditingController();
  OutcomeDifficulty _diff = OutcomeDifficulty.beginner;
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _counter = widget.outcomes.length;
  }

  @override
  void didUpdateWidget(covariant _LOBody old) {
    super.didUpdateWidget(old);
    _counter = widget.outcomes.length;
  }

  @override
  void dispose() { _descCtrl.dispose(); super.dispose(); }

  void _add() {
    final text = _descCtrl.text.trim();
    if (text.isEmpty) return;
    final lo = LearningOutcome(
      id: 'lo_${DateTime.now().millisecondsSinceEpoch}',
      code: LearningOutcome.codeForIndex(_counter),
      description: text,
      difficulty: _diff,
    );
    setState(() {
      _counter++;
      _descCtrl.clear();
      _diff = OutcomeDifficulty.beginner;
    });
    widget.onAdd(lo);
  }

  void _openEdit(LearningOutcome lo) async {
    final result = await showDialog<LearningOutcome>(
      context: context,
      builder: (_) => _EditLODialog(outcome: lo),
    );
    if (result != null) widget.onEdit(result);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // List
        if (widget.outcomes.isEmpty)
          _EmptyLO()
        else
          ...widget.outcomes.map((lo) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LOTile(
              outcome: lo,
              onEdit:   () => _openEdit(lo),
              onDelete: () => widget.onDelete(lo.id),
            ),
          )),

        const SizedBox(height: 16),
        const Divider(color: AppColors.border),
        const SizedBox(height: 14),

        // Add new
        const Text('Add Outcome',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textTitle)),
        const SizedBox(height: 12),

        // Difficulty
        const Text('Difficulty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Row(children: OutcomeDifficulty.values.map((d) {
          final sel = _diff == d;
          final color = _diffColor(d);
          return Expanded(child: Padding(
            padding: EdgeInsets.only(right: d != OutcomeDifficulty.advanced ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _diff = d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? color.withOpacity(0.09) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sel ? color : AppColors.border, width: sel ? 1.5 : 1),
                ),
                alignment: Alignment.center,
                child: Text(d.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? color : AppColors.textMuted)),
              ),
            ),
          ));
        }).toList()),
        const SizedBox(height: 10),

        // Input + button
        Row(children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSoft),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: _descCtrl,
                onSubmitted: (_) => _add(),
                style: AppText.input,
                decoration: const InputDecoration(
                  hintText: 'e.g. Understand database normalization',
                  hintStyle: TextStyle(fontSize: 13.5, color: AppColors.textHint),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _add,
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(42, 42),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Icon(Icons.add, size: 18),
          ),
        ]),
      ]),
    );
  }

  static Color _diffColor(OutcomeDifficulty d) {
    switch (d) {
      case OutcomeDifficulty.beginner:     return const Color(0xFF16A34A);
      case OutcomeDifficulty.intermediate: return const Color(0xFFD97706);
      case OutcomeDifficulty.advanced:     return const Color(0xFFDC2626);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Edit LO Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _EditLODialog extends StatefulWidget {
  final LearningOutcome outcome;
  const _EditLODialog({required this.outcome});
  @override State<_EditLODialog> createState() => _EditLODialogState();
}
class _EditLODialogState extends State<_EditLODialog> {
  late TextEditingController _ctrl;
  late OutcomeDifficulty _diff;
  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.outcome.description);
    _diff = widget.outcome.difficulty;
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Edit ${widget.outcome.code}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textTitle)),
          const SizedBox(height: 16),
          const Text('Description', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textTitle)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.borderSoft)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _ctrl,
              maxLines: 3,
              style: AppText.input,
              decoration: const InputDecoration(hintText: 'Describe learning outcome...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 10)),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Difficulty', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textTitle)),
          const SizedBox(height: 8),
          Row(children: OutcomeDifficulty.values.map((d) {
            final sel = _diff == d;
            Color c() {
              switch (d) {
                case OutcomeDifficulty.beginner:     return const Color(0xFF16A34A);
                case OutcomeDifficulty.intermediate: return const Color(0xFFD97706);
                case OutcomeDifficulty.advanced:     return const Color(0xFFDC2626);
              }
            }
            return Expanded(child: Padding(
              padding: EdgeInsets.only(right: d != OutcomeDifficulty.advanced ? 8 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _diff = d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? c().withOpacity(0.08) : AppColors.pageBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sel ? c() : AppColors.border, width: sel ? 1.5 : 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(d.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? c() : AppColors.textMuted)),
                ),
              ),
            ));
          }).toList()),
          const SizedBox(height: 22),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.textTitle, side: const BorderSide(color: AppColors.borderSoft), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                final t = _ctrl.text.trim();
                if (t.isEmpty) return;
                Navigator.pop(context, widget.outcome.copyWith(description: t, difficulty: _diff));
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Save Changes'),
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
      borderRadius: BorderRadius.circular(9),
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
        child: Text(outcome.code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.badgeBlueFg)),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(color: _diffColor.withOpacity(0.09), borderRadius: BorderRadius.circular(6)),
        child: Text(outcome.difficulty.label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _diffColor)),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(outcome.description, style: const TextStyle(fontSize: 12.5, color: AppColors.textTitle, height: 1.4))),
      IconButton(icon: const Icon(Icons.edit_outlined, size: 15), color: AppColors.textMuted, visualDensity: VisualDensity.compact, onPressed: onEdit),
      IconButton(icon: const Icon(Icons.close, size: 15), color: AppColors.dangerText, visualDensity: VisualDensity.compact, onPressed: onDelete),
    ]),
  );
}

class _EmptyLO extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.border)),
    child: const Row(children: [
      Icon(Icons.info_outline, size: 14, color: AppColors.textHint),
      SizedBox(width: 8),
      Expanded(child: Text('No learning outcomes yet. Add your first outcome below.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.5))),
    ]),
  );
}
