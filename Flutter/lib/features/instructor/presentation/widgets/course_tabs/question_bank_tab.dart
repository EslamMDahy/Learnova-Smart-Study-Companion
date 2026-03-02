import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/ui/toast.dart';
import '../../../data/courses_models.dart';
import '../../../data/question_models.dart';
import '../../controllers/course_details_controller.dart';
import '../../controllers/course_details_state.dart';
import '../add_question_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CourseQuestionBankTab — matches Figma (images 3 & 4)
// ─────────────────────────────────────────────────────────────────────────────

class CourseQuestionBankTab extends ConsumerStatefulWidget {
  final MyCourseItem course;
  const CourseQuestionBankTab({super.key, required this.course});

  @override
  ConsumerState<CourseQuestionBankTab> createState() =>
      _CourseQuestionBankTabState();
}

class _CourseQuestionBankTabState
    extends ConsumerState<CourseQuestionBankTab> {
  String _search = '';
  QuestionType? _filterType;
  QuestionDifficulty? _filterDiff;
  int? _filterModuleId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(courseDetailsControllerProvider(widget.course.id));
    final filtered = _applyFilters(state.questions);

    return Container(
      color: AppColors.pageBg,
      child: Column(children: [
        // ── AI Generator banner ───────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Question Bank (Local Draft)',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textTitle)),
                Text(
                    'Questions added here are stored locally in this build and won\'t sync to the server yet.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ]),
            ),
            const SizedBox(width: 16),
            _BlueTextBtn(
              label: 'AI Review (Coming soon)',
              onTap: () => _generateWithAI(state),
            ),
          ]),
        ),

        // ── Toolbar ───────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children: [
            // Search
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search questions by keyword or topic...',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 15, color: AppColors.textHint),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    filled: true,
                    fillColor: AppColors.pageBg,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Filter dropdowns (matching prototype)
            _DropFilter<int?>(
              label: 'All Topics',
              value: _filterModuleId,
              options: {
                null: 'All Topics',
                for (final m in state.modules) m.id: m.title,
              },
              onChanged: (v) => setState(() => _filterModuleId = v),
            ),
            const SizedBox(width: 8),
            _DropFilter<QuestionDifficulty?>(
              label: 'Any Difficulty',
              value: _filterDiff,
              options: {
                null: 'Any Difficulty',
                QuestionDifficulty.easy: 'Easy',
                QuestionDifficulty.medium: 'Medium',
                QuestionDifficulty.hard: 'Hard',
              },
              onChanged: (v) => setState(() => _filterDiff = v),
            ),
            const SizedBox(width: 8),
            _DropFilter<QuestionType?>(
              label: 'All Types',
              value: _filterType,
              options: {
                null: 'All Types',
                QuestionType.multipleChoice: 'Multiple Choice',
                QuestionType.trueFalse: 'True / False',
                QuestionType.shortAnswer: 'Short Answer',
                QuestionType.essay: 'Essay',
              },
              onChanged: (v) => setState(() => _filterType = v),
            ),
          ]),
        ),

        // ── Stats bar ─────────────────────────────────────────────────────
        Container(
          color: const Color(0xFFFAFBFC),
          padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children: [
            const Text('AVAILABLE QUESTIONS',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHint,
                    letterSpacing: 0.5)),
            const Spacer(),
            Text('${filtered.length} questions',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted)),
          ]),
        ),

        // ── Question list ─────────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? _buildEmpty(state.questions.isEmpty)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    // Last item = Add New Question button
                    if (i == filtered.length) {
                      return _AddNewBtn(
                        onTap: () => _showAddQuestion(state),
                      );
                    }
                    return _QuestionCard(
                      question: filtered[i],
                      onDelete: () {
                        ref
                            .read(courseDetailsControllerProvider(
                                    widget.course.id)
                                .notifier)
                            .deleteQuestion(filtered[i].id);
                        AppToast.success(ctx,
                            title: 'Question removed',
                            message: 'Removed from Question Bank.');
                      },
                    );
                  },
                ),
        ),

        // ── Bottom action ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: Colors.white,
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showAddQuestion(state),
                icon: const Icon(Icons.add, size: 15),
                label: const Text('Add New Question'),
              ),
              ElevatedButton.icon(
                onPressed: state.questions.isEmpty
                    ? null
                    : () => _showSummary(state),
                icon: const Icon(Icons.summarize_outlined, size: 15),
                label: Text(
                    '${state.questions.length} question${state.questions.length == 1 ? '' : 's'} in bank'),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  List<QuestionModel> _applyFilters(List<QuestionModel> all) {
    return all.where((q) {
      if (_search.isNotEmpty &&
          !q.text.toLowerCase().contains(_search.toLowerCase())) {
        return false;
      }
      if (_filterType != null && q.type != _filterType) return false;
      if (_filterDiff != null && q.difficulty != _filterDiff) return false;
      if (_filterModuleId != null && q.moduleId != _filterModuleId) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildEmpty(bool noQuestions) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.quiz_outlined, size: 42, color: AppColors.primary),
        const SizedBox(height: 12),
        Text(
          noQuestions ? 'No questions yet' : 'No matching questions',
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textTitle),
        ),
        const SizedBox(height: 6),
        Text(
          noQuestions
              ? 'Add questions manually or use AI to generate them from your materials.'
              : 'Try adjusting your filters or search term.',
          style: const TextStyle(
              fontSize: 13, color: AppColors.textMuted, height: 1.5),
          textAlign: TextAlign.center,
        ),
        if (noQuestions) ...[
          const SizedBox(height: 16),
          Row(mainAxisSize: MainAxisSize.min, children: [
            ElevatedButton.icon(
              onPressed: () => _showAddQuestion(
                  ref.read(courseDetailsControllerProvider(widget.course.id))),
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => _generateWithAI(
                  ref.read(courseDetailsControllerProvider(widget.course.id))),
              icon: const Icon(Icons.auto_awesome_rounded, size: 15),
              label: const Text('Generate with AI'),
            ),
          ]),
        ],
      ]),
    );
  }

  void _showAddQuestion(CourseDetailsState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddQuestionSheet(
        modules: state.modules,
        onAdd: (q) {
          ref
              .read(courseDetailsControllerProvider(widget.course.id).notifier)
              .addQuestion(q);
          if (mounted) {
            AppToast.success(context,
                title: 'Question added',
                message: 'Added to Question Bank.');
          }
        },
      ),
    );
  }

  void _generateWithAI(CourseDetailsState state) {
    // Backend endpoints for AI generation/review aren't exposed in this project build.
    // Avoid implying server-side workflows are available.
    AppToast.info(
      context,
      title: 'Coming soon',
      message: 'AI generation / review will appear here when it is enabled on the server.',
    );
  }

  void _showSummary(CourseDetailsState state) {
    final easy   = state.questions.where((q) => q.difficulty == QuestionDifficulty.easy).length;
    final medium = state.questions.where((q) => q.difficulty == QuestionDifficulty.medium).length;
    final hard   = state.questions.where((q) => q.difficulty == QuestionDifficulty.hard).length;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Question Bank Summary',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _SummaryRow('Total questions', '${state.questions.length}'),
          _SummaryRow('Easy', '$easy'),
          _SummaryRow('Medium', '$medium'),
          _SummaryRow('Hard', '$hard'),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }
}

// ── Question Card ──────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final QuestionModel question;
  final VoidCallback onDelete;
  const _QuestionCard({required this.question, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Checkbox (visual only — for quiz selection later)
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 2, right: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Text(question.text,
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTitle,
                    height: 1.4)),
          ),
          const SizedBox(width: 8),
          _DiffBadge(question.difficulty),
          const SizedBox(width: 6),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.delete_outline,
                  size: 15, color: AppColors.dangerText),
            ),
          ),
        ]),
        const SizedBox(height: 8),

        // Meta chips
        Row(children: [
          const SizedBox(width: 28), // align with text
          _MetaChip(Icons.category_outlined, question.typeLabel),
          const SizedBox(width: 6),
          _MetaChip(Icons.location_on_outlined, question.contextLabel),
          if (question.explanation != null) ...[
            const SizedBox(width: 6),
            const _MetaChip(Icons.info_outline_rounded, 'Has explanation'),
          ],
        ]),

        // MC options preview
        if (question.type == QuestionType.multipleChoice &&
            question.options.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...question.options.take(4).map((opt) {
            final isCorrect = opt.id == question.correctOptionId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 28),
              child: Row(children: [
                Icon(
                  isCorrect
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 13,
                  color: isCorrect
                      ? const Color(0xFF16A34A)
                      : AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(opt.text,
                      style: TextStyle(
                          fontSize: 12.5,
                          color: isCorrect
                              ? const Color(0xFF16A34A)
                              : AppColors.textMuted,
                          fontWeight: isCorrect
                              ? FontWeight.w600
                              : FontWeight.w400)),
                ),
              ]),
            );
          }),
        ],

        // T/F answer
        if (question.type == QuestionType.trueFalse &&
            question.correctBool != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Row(children: [
              const Icon(Icons.check_circle_outline,
                  size: 12, color: Color(0xFF16A34A)),
              const SizedBox(width: 4),
              Text(
                  'Correct: ${question.correctBool! ? "True" : "False"}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ── Micro widgets ──────────────────────────────────────────────────────────────

class _DiffBadge extends StatelessWidget {
  final QuestionDifficulty diff;
  const _DiffBadge(this.diff);

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;
    switch (diff) {
      case QuestionDifficulty.easy:
        bg = const Color(0xFFDCFCE7); fg = const Color(0xFF16A34A);
        label = 'Easy'; break;
      case QuestionDifficulty.medium:
        bg = const Color(0xFFFEF3C7); fg = const Color(0xFFD97706);
        label = 'Medium'; break;
      case QuestionDifficulty.hard:
        bg = AppColors.dangerBg; fg = AppColors.dangerText;
        label = 'Hard'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: AppColors.pageBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textMuted)),
      ]),
    );
  }
}

class _BlueTextBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BlueTextBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary)),
    );
  }
}

class _AddNewBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddNewBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.primary.withOpacity(0.3)),
        ),
        child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Icon(Icons.add_circle_outline_rounded,
              size: 18, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Add New Question',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
        ]),
      ),
    );
  }
}

class _DropFilter<T> extends StatelessWidget {
  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T?> onChanged;

  const _DropFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value != null;
    return GestureDetector(
      onTap: () => _showMenu(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : Colors.white,
          border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            isActive ? (options[value] ?? label) : label,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color:
                    isActive ? AppColors.primary : AppColors.textMuted),
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: isActive ? AppColors.primary : AppColors.textMuted),
        ]),
      ),
    );
  }

  void _showMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    final result = await showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
          offset.dx,
          offset.dy + size.height,
          offset.dx + size.width,
          0),
      items: options.entries
          .map((e) => PopupMenuItem<T>(
                value: e.key,
                child: Text(e.value,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: e.key == value
                            ? FontWeight.w700
                            : FontWeight.w400)),
              ))
          .toList(),
    );
    if (result != null) onChanged(result);
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(color: AppColors.textMuted))),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textTitle)),
      ]),
    );
  }
}
