import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/network/error_mapper.dart';
import '../../../../../core/routing/routes.dart';
import '../../../../../core/storage/student_exam_results_cache.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../data/student_courses_models.dart';
import '../../../data/student_courses_providers.dart';

class StudentQuizActivePage extends ConsumerStatefulWidget {
  const StudentQuizActivePage({super.key});

  @override
  ConsumerState<StudentQuizActivePage> createState() => _StudentQuizActivePageState();
}

class _StudentQuizActivePageState extends ConsumerState<StudentQuizActivePage> {
  final Map<int, int> _singleAnswers = <int, int>{};
  final Map<int, Set<int>> _multiAnswers = <int, Set<int>>{};
  final Map<int, TextEditingController> _textControllers = <int, TextEditingController>{};
  final Set<int> _flaggedQuestionIds = <int>{};
  final Stopwatch _stopwatch = Stopwatch();

  Timer? _timer;
  DateTime _now = DateTime.now();
  int _currentIndex = 0;
  bool _submitting = false;
  bool _autoSubmitted = false;
  _SubmissionSuccessState? _submissionSuccess;
  int? _timerAttemptId;

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int? _queryInt(BuildContext context, String key) {
    final raw = GoRouterState.of(context).uri.queryParameters[key];
    return int.tryParse(raw ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final courseId = _queryInt(context, 'courseId');
    final examId = _queryInt(context, 'examId');

    if (courseId == null || courseId <= 0 || examId == null || examId <= 0) {
      return _ExamErrorPage(
        title: 'Exam not found',
        message: 'Open the exam again from the course content page.',
        onBack: () => context.go(Routes.studentCourses),
      );
    }

    final args = StudentExamAttemptArgs(courseId: courseId, examId: examId);
    final attemptAsync = ref.watch(studentExamAttemptProvider(args));

    return attemptAsync.when(
      loading: () => const _ExamLoadingPage(),
      error: (error, _) => _ExamErrorPage(
        title: 'Could not start exam',
        message: mapApiFailure(error).message,
        onBack: () => context.go('${Routes.studentCourseDetails}?courseId=$courseId'),
        onRetry: () => ref.invalidate(studentExamAttemptProvider(args)),
      ),
      data: (attempt) {
        _startTimer(attempt);
        final questions = attempt.questions;
        final clampedIndex = questions.isEmpty
            ? 0
            : _currentIndex.clamp(0, questions.length - 1).toInt();
        if (clampedIndex != _currentIndex) _currentIndex = clampedIndex;
        final question = questions.isEmpty ? null : questions[clampedIndex];
        final answeredCount = questions.where(_isAnswered).length;

        if (attempt.expiresAt != null &&
            attempt.expiresAt!.isBefore(_now) &&
            !_autoSubmitted &&
            !_submitting) {
          _autoSubmitted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _submit(courseId: courseId, attempt: attempt, forced: true);
          });
        }

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Stack(
            children: [
              Column(
                children: [
                  _ExamHeader(
                    attempt: attempt,
                    submitting: _submitting,
                    canFinish: questions.isNotEmpty,
                    onFinish: () => _confirmSubmit(courseId, attempt),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _QuestionRail(
                          questions: questions,
                          selectedIndex: clampedIndex,
                          submitting: _submitting,
                          answered: _isAnswered,
                          flaggedQuestionIds: _flaggedQuestionIds,
                          onSelect: (index) => setState(() => _currentIndex = index),
                        ),
                        Expanded(
                          child: question == null
                              ? _NoQuestions(
                                  onBack: () => context.go('${Routes.studentCourseDetails}?courseId=$courseId'),
                                )
                              : _QuestionPanel(
                                  attempt: attempt,
                                  question: question,
                                  index: clampedIndex,
                                  total: questions.length,
                                  answeredCount: answeredCount,
                                  remaining: _remainingLabel(attempt),
                                  submitting: _submitting,
                                  flagged: _flaggedQuestionIds.contains(question.examQuestionId),
                                  selectedSingleIndex: _singleAnswers[question.examQuestionId],
                                  selectedMultiIndices: _multiAnswers[question.examQuestionId] ?? const <int>{},
                                  textController: _controllerFor(question),
                                  onFlagToggled: () {
                                    setState(() {
                                      if (!_flaggedQuestionIds.add(question.examQuestionId)) {
                                        _flaggedQuestionIds.remove(question.examQuestionId);
                                      }
                                    });
                                  },
                                  onSingleSelected: (optionIndex) {
                                    setState(() => _singleAnswers[question.examQuestionId] = optionIndex);
                                  },
                                  onMultiChanged: (optionIndex, selected) {
                                    setState(() {
                                      final values = {...?_multiAnswers[question.examQuestionId]};
                                      selected ? values.add(optionIndex) : values.remove(optionIndex);
                                      _multiAnswers[question.examQuestionId] = values;
                                    });
                                  },
                                  onTextChanged: () => setState(() {}),
                                  onPrevious: clampedIndex > 0 ? () => setState(() => _currentIndex--) : null,
                                  onNext: clampedIndex < questions.length - 1 ? () => setState(() => _currentIndex++) : null,
                                  onFinish: _submitting ? null : () => _confirmSubmit(courseId, attempt),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_submissionSuccess != null)
                Positioned.fill(
                  child: _SubmissionSuccessOverlay(state: _submissionSuccess!),
                ),
            ],
          ),
        );
      },
    );
  }

  void _startTimer(StudentExamAttempt attempt) {
    if (_timerAttemptId == attempt.attemptId) return;
    _timerAttemptId = attempt.attemptId;
    _timer?.cancel();
    _stopwatch
      ..reset()
      ..start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  TextEditingController _controllerFor(StudentExamQuestion question) {
    return _textControllers.putIfAbsent(
      question.examQuestionId,
      () => TextEditingController(),
    );
  }

  bool _isAnswered(StudentExamQuestion question) {
    if (question.hasOptions) {
      if (question.allowsMultipleSelection) {
        return (_multiAnswers[question.examQuestionId] ?? const <int>{}).isNotEmpty;
      }
      return _singleAnswers.containsKey(question.examQuestionId);
    }
    return (_textControllers[question.examQuestionId]?.text.trim() ?? '').isNotEmpty;
  }

  List<StudentExamAnswerDraft> _collectAnswers(StudentExamAttempt attempt) {
    final answers = <StudentExamAnswerDraft>[];
    for (final question in attempt.questions) {
      if (question.hasOptions) {
        if (question.allowsMultipleSelection) {
          final selected = (_multiAnswers[question.examQuestionId] ?? const <int>{}).toList()..sort();
          if (selected.isNotEmpty) {
            final selectedKeys = selected
                .map((index) => _backendOptionKey(question, index))
                .where((key) => key.isNotEmpty)
                .toList(growable: false);
            answers.add(StudentExamAnswerDraft(
              examQuestionId: question.examQuestionId,
              selectedOptionIndices: selected,
              // Backend stores option ids as A/B/C/D in snapshot_options. Keep the
              // numeric index for the API schema and send the selected ids in
              // answer_text so the result screen can resolve the exact option.
              answerText: selectedKeys.isEmpty ? null : jsonEncode(selectedKeys),
            ));
          }
        } else {
          final selected = _singleAnswers[question.examQuestionId];
          if (selected != null) {
            final selectedKey = _backendOptionKey(question, selected);
            answers.add(StudentExamAnswerDraft(
              examQuestionId: question.examQuestionId,
              selectedOptionIndex: selected,
              // selected_option_index is the option position required by the
              // endpoint schema. answer_text carries the real snapshot option id
              // (A/B/C/D) for result review/display.
              answerText: selectedKey.isEmpty ? null : selectedKey,
            ));
          }
        }
      } else {
        final text = _textControllers[question.examQuestionId]?.text.trim() ?? '';
        if (text.isNotEmpty) {
          answers.add(StudentExamAnswerDraft(
            examQuestionId: question.examQuestionId,
            answerText: text,
          ));
        }
      }
    }
    return answers;
  }

  String _backendOptionKey(StudentExamQuestion question, int optionIndex) {
    if (optionIndex < 0 || optionIndex >= question.options.length) return '';

    final option = question.options[optionIndex];
    final rawId = option.id.trim();
    final normalizedType = question.safeType.toLowerCase().replaceAll('-', '_');

    // True/False questions are graded against true/false in the backend.
    if (normalizedType.contains('true_false') || normalizedType.contains('boolean')) {
      final text = option.text.trim().toLowerCase();
      final id = rawId.toLowerCase();
      if (id == 'true' || id == 'false') return id;
      if (text == 'true' || text == 'صح') return 'true';
      if (text == 'false' || text == 'خطأ' || text == 'غلط') return 'false';
    }

    // Prefer the option id coming from snapshot_options. In the database this is
    // stored as A/B/C/D, and correct_answer comes back using the same ids.
    if (rawId.isNotEmpty && int.tryParse(rawId) == null) {
      return rawId.toUpperCase();
    }

    return _optionLetter(optionIndex);
  }

  String _optionLetter(int index) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (index >= 0 && index < letters.length) return letters[index];
    return index.toString();
  }

  Future<void> _confirmSubmit(int courseId, StudentExamAttempt attempt) async {
    final unanswered = attempt.questions.where((question) => !_isAnswered(question)).length;
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish attempt?'),
        content: Text(
          unanswered == 0
              ? 'Your answers will be submitted for grading.'
              : '$unanswered question(s) are still unanswered. Finish anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep working'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Finish Attempt'),
          ),
        ],
      ),
    );

    if (submit == true) {
      await _submit(courseId: courseId, attempt: attempt);
    }
  }

  Future<void> _submit({
    required int courseId,
    required StudentExamAttempt attempt,
    bool forced = false,
  }) async {
    if (_submitting || !mounted) return;
    setState(() => _submitting = true);

    try {
      final elapsedSeconds = _stopwatch.elapsed.inSeconds;
      final answers = _collectAnswers(attempt);
      final answeredCount = answers.length;
      final totalQuestions = attempt.totalQuestions > 0
          ? attempt.totalQuestions
          : attempt.questions.length;
      final result = await ref.read(studentCoursesApiProvider).submitStudentExam(
            courseId: courseId,
            examId: attempt.examId,
            attemptId: attempt.attemptId,
            answers: answers,
            timeSpentSeconds: elapsedSeconds,
            cancelToken: CancelToken(),
          );

      _timer?.cancel();
      _stopwatch.stop();
      StudentExamResultsCache.saveSubmittedResult(
        courseId: courseId,
        attempt: attempt,
        result: result,
        timeSpentSeconds: elapsedSeconds,
        answeredCount: answeredCount,
      );

      if (!mounted) return;
      setState(() {
        _submissionSuccess = _SubmissionSuccessState(
          forced: forced,
          answeredCount: answeredCount,
          totalQuestions: totalQuestions,
        );
      });

      await Future<void>.delayed(const Duration(seconds: 2));

      if (mounted) {
        context.go('${Routes.studentCourseDetails}?courseId=$courseId&examId=${attempt.examId}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapApiFailure(e).message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _remainingLabel(StudentExamAttempt attempt) {
    final expiresAt = attempt.expiresAt;
    if (expiresAt == null) return 'No time limit';
    final remaining = expiresAt.difference(_now);
    if (remaining.isNegative) return '00:00';
    final hours = remaining.inHours;
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    if (hours > 0) return "${hours.toString().padLeft(2, '0')}:$minutes:$seconds";
    return '$minutes:$seconds';
  }

  String _resultMessage(StudentExamSubmitResult result) {
    final parts = <String>[];
    if (result.percentageScore != null) {
      parts.add('Score: ${_formatScore(result.percentageScore!)}%');
    } else if (result.totalScore != null) {
      parts.add('Score: ${_formatScore(result.totalScore!)}');
    }
    if (result.isPassed != null) parts.add(result.isPassed! ? 'Passed' : 'Not passed yet');
    if (result.unansweredCount != null) parts.add('Unanswered: ${result.unansweredCount}');
    return parts.isEmpty ? 'Your exam attempt was submitted successfully.' : parts.join('\n');
  }
}


class _SubmissionSuccessState {
  final bool forced;
  final int answeredCount;
  final int totalQuestions;

  const _SubmissionSuccessState({
    required this.forced,
    required this.answeredCount,
    required this.totalQuestions,
  });
}

class _SubmissionSuccessOverlay extends StatelessWidget {
  final _SubmissionSuccessState state;

  const _SubmissionSuccessOverlay({required this.state});

  @override
  Widget build(BuildContext context) {
    final answered = state.answeredCount.clamp(0, state.totalQuestions).toInt();
    final total = state.totalQuestions <= 0 ? answered : state.totalQuestions;

    return Container(
      color: Colors.black.withOpacity(0.36),
      alignment: Alignment.center,
      child: Container(
        width: 380,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.fromLTRB(30, 32, 30, 28),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.greenBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: AppColors.successBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.greenBorder, width: 2),
              ),
              child: Icon(Icons.check_rounded, color: AppColors.successText, size: 54),
            ),
            const SizedBox(height: 22),
            Text(
              state.forced ? 'Time is up — attempt submitted' : 'Attempt submitted successfully',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textTitle,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.infoBorder),
              ),
              child: Text(
                'Answered $answered / $total questions',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Saving your attempt and opening the result page...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 210,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: const SizedBox(height: 6, child: LinearProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamHeader extends StatelessWidget {
  final StudentExamAttempt attempt;
  final bool submitting;
  final bool canFinish;
  final VoidCallback? onFinish;

  const _ExamHeader({
    required this.attempt,
    required this.submitting,
    required this.canFinish,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attempt.safeTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textTitle,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_titleCase(attempt.safeType)} • Attempt ${attempt.attemptNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: submitting || !canFinish ? null : onFinish,
              icon: submitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.logout_rounded, size: 16),
              label: Text(submitting ? 'Submitting...' : 'Finish Attempt'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.headerBg,
                foregroundColor: AppColors.textTitle,
                disabledBackgroundColor: AppColors.headerBg,
                disabledForegroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionRail extends StatelessWidget {
  final List<StudentExamQuestion> questions;
  final int selectedIndex;
  final bool submitting;
  final bool Function(StudentExamQuestion question) answered;
  final Set<int> flaggedQuestionIds;
  final ValueChanged<int> onSelect;

  const _QuestionRail({
    required this.questions,
    required this.selectedIndex,
    required this.submitting,
    required this.answered,
    required this.flaggedQuestionIds,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 276,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Row(
              children: [
                Icon(Icons.grid_view_rounded, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Question Palette',
                    style: TextStyle(color: AppColors.textTitle, fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.infoBorder),
                  ),
                  child: Text(
                    '${questions.length} Qs',
                    style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              child: GridView.builder(
                itemCount: questions.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return _QuestionNumber(
                    number: index + 1,
                    selected: index == selectedIndex,
                    answered: answered(question),
                    flagged: flaggedQuestionIds.contains(question.examQuestionId),
                    onTap: submitting ? null : () => onSelect(index),
                  );
                },
              ),
            ),
          ),
          const _PaletteLegend(),
        ],
      ),
    );
  }
}

class _QuestionNumber extends StatelessWidget {
  final int number;
  final bool selected;
  final bool answered;
  final bool flagged;
  final VoidCallback? onTap;

  const _QuestionNumber({
    required this.number,
    required this.selected,
    required this.answered,
    required this.flagged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = answered ? AppColors.primary : AppColors.headerBg;
    final borderColor = selected
        ? AppColors.primary
        : flagged
            ? AppColors.warningText
            : AppColors.border;
    final textColor = answered
        ? Colors.white
        : selected
            ? AppColors.primary
            : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected && !answered ? AppColors.cardBg : background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: selected ? 2 : 1),
            ),
            child: Text(
              number.toString(),
              style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
          if (answered)
            const Positioned(
              right: 5,
              bottom: 5,
              child: Icon(Icons.check_rounded, size: 10, color: Colors.white),
            ),
          if (flagged)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.warningText,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBg, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaletteLegend extends StatelessWidget {
  const _PaletteLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.headerBg.withOpacity(0.55),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEGEND',
            style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .5),
          ),
          const SizedBox(height: 12),
          const _LegendItem(color: AppColors.primary, label: 'Answered'),
          const SizedBox(height: 8),
          const _LegendItem(color: Colors.white, label: 'Current', borderColor: AppColors.primary),
          const SizedBox(height: 8),
          const _LegendItem(color: Color(0xFFF97316), label: 'Flagged'),
          const SizedBox(height: 8),
          const _LegendItem(color: Color(0xFFCBD5E1), label: 'Unanswered'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color? borderColor;
  final String label;

  const _LegendItem({required this.color, required this.label, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: borderColor == null ? null : Border.all(color: borderColor!, width: 1.5),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: AppColors.textTitle, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _QuestionPanel extends StatelessWidget {
  final StudentExamAttempt attempt;
  final StudentExamQuestion question;
  final int index;
  final int total;
  final int answeredCount;
  final String remaining;
  final bool submitting;
  final bool flagged;
  final int? selectedSingleIndex;
  final Set<int> selectedMultiIndices;
  final TextEditingController textController;
  final VoidCallback onFlagToggled;
  final ValueChanged<int> onSingleSelected;
  final void Function(int index, bool selected) onMultiChanged;
  final VoidCallback onTextChanged;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onFinish;

  const _QuestionPanel({
    required this.attempt,
    required this.question,
    required this.index,
    required this.total,
    required this.answeredCount,
    required this.remaining,
    required this.submitting,
    required this.flagged,
    required this.selectedSingleIndex,
    required this.selectedMultiIndices,
    required this.textController,
    required this.onFlagToggled,
    required this.onSingleSelected,
    required this.onMultiChanged,
    required this.onTextChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final sectionInfo = _sectionInfoForQuestion(attempt, question);
    final completed = total == 0 ? 0 : ((answeredCount / total) * 100).round();

    return Container(
      color: AppColors.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(46, 26, 46, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sectionInfo.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textTitle, fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Section ${sectionInfo.index} of ${sectionInfo.total}',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _TimerPill(label: remaining),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          height: 9,
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : answeredCount / total,
                            backgroundColor: AppColors.border,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '$completed% Completed',
                      style: TextStyle(color: AppColors.textTitle, fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [BoxShadow(color: AppColors.shadowThin, blurRadius: 16, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.headerBg,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'Question ${index + 1}',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: submitting ? null : onFlagToggled,
                                  icon: Icon(
                                    flagged ? Icons.flag_rounded : Icons.flag_outlined,
                                    size: 16,
                                    color: flagged ? AppColors.warningText : AppColors.textMuted,
                                  ),
                                  label: Text(
                                    'Flag',
                                    style: TextStyle(
                                      color: flagged ? AppColors.warningText : AppColors.textMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              question.safeText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textTitle,
                                fontSize: 22,
                                height: 1.28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 28),
                            const _QuestionMediaPlaceholder(),
                            const SizedBox(height: 20),
                            if (question.hasOptions)
                              for (var i = 0; i < question.options.length; i++) ...[
                                question.allowsMultipleSelection
                                    ? _MultiOption(
                                        index: i,
                                        option: question.options[i],
                                        selected: selectedMultiIndices.contains(i),
                                        enabled: !submitting,
                                        onChanged: (selected) => onMultiChanged(i, selected),
                                      )
                                    : _SingleOption(
                                        index: i,
                                        option: question.options[i],
                                        selectedIndex: selectedSingleIndex,
                                        enabled: !submitting,
                                        onChanged: onSingleSelected,
                                      ),
                                const SizedBox(height: 11),
                              ]
                            else
                              TextField(
                                controller: textController,
                                enabled: !submitting,
                                onChanged: (_) => onTextChanged(),
                                minLines: 7,
                                maxLines: 12,
                                decoration: InputDecoration(
                                  hintText: 'Write your answer here...',
                                  filled: true,
                                  fillColor: AppColors.headerBg,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: AppColors.border),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: AppColors.border),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 40,
                              child: OutlinedButton.icon(
                                onPressed: submitting ? null : onPrevious,
                                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                                label: const Text('Previous'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textTitle,
                                  side: BorderSide(color: AppColors.border),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                ),
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: submitting ? null : (onNext ?? onFinish),
                                icon: Icon(onNext == null ? Icons.logout_rounded : Icons.arrow_forward_rounded, size: 18),
                                label: Text(onNext == null ? 'Finish Attempt' : 'Next Question'),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                ),
                              ),
                            ),
                          ],
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

class _QuestionMediaPlaceholder extends StatelessWidget {
  const _QuestionMediaPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 188,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Icon(Icons.bar_chart_rounded, color: AppColors.borderSoft, size: 36),
      ),
    );
  }
}

class _TimerPill extends StatelessWidget {
  final String label;

  const _TimerPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.primary, size: 17),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(color: AppColors.textTitle, fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SingleOption extends StatelessWidget {
  final int index;
  final StudentExamQuestionOption option;
  final int? selectedIndex;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _SingleOption({
    required this.index,
    required this.option,
    required this.selectedIndex,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedIndex == index;
    return InkWell(
      onTap: enabled ? () => onChanged(index) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.8 : 1),
        ),
        child: Row(
          children: [
            Radio<int>(
              value: index,
              groupValue: selectedIndex,
              activeColor: AppColors.primary,
              onChanged: enabled ? (value) => onChanged(value ?? index) : null,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                option.text,
                style: TextStyle(color: AppColors.textTitle, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiOption extends StatelessWidget {
  final int index;
  final StudentExamQuestionOption option;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _MultiOption({
    required this.index,
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged(!selected) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.8 : 1),
        ),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              activeColor: AppColors.primary,
              onChanged: enabled ? (value) => onChanged(value ?? false) : null,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                option.text,
                style: TextStyle(color: AppColors.textTitle, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoQuestions extends StatelessWidget {
  final VoidCallback onBack;

  const _NoQuestions({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _MessageCard(
        icon: Icons.assignment_late_outlined,
        title: 'No questions available',
        message: 'This exam does not have published questions yet.',
        actionLabel: 'Back',
        onAction: onBack,
      ),
    );
  }
}

class _ExamLoadingPage extends StatelessWidget {
  const _ExamLoadingPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
              const SizedBox(width: 14),
              Text(
                'Preparing exam...',
                style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamErrorPage extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onBack;
  final VoidCallback? onRetry;

  const _ExamErrorPage({required this.title, required this.message, required this.onBack, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: _MessageCard(
          icon: Icons.warning_amber_rounded,
          title: title,
          message: message,
          actionLabel: 'Back',
          onAction: onBack,
          secondaryLabel: onRetry == null ? null : 'Retry',
          onSecondary: onRetry,
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 460,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.shadowThin, blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 44),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textTitle, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
              if (secondaryLabel != null && onSecondary != null) ...[
                const SizedBox(width: 10),
                ElevatedButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionDisplayInfo {
  final String title;
  final int index;
  final int total;

  const _SectionDisplayInfo({required this.title, required this.index, required this.total});
}

_SectionDisplayInfo _sectionInfoForQuestion(StudentExamAttempt attempt, StudentExamQuestion question) {
  final sections = attempt.sections;
  if (sections.isEmpty) {
    return const _SectionDisplayInfo(title: 'Questions', index: 1, total: 1);
  }

  for (var i = 0; i < sections.length; i++) {
    final contains = sections[i].questions.any((item) => item.examQuestionId == question.examQuestionId);
    if (contains) {
      return _SectionDisplayInfo(title: sections[i].safeTitle, index: i + 1, total: sections.length);
    }
  }

  return _SectionDisplayInfo(title: sections.first.safeTitle, index: 1, total: sections.length);
}

String _titleCase(String value) {
  final normalized = value.replaceAll('_', ' ').replaceAll('-', ' ').trim();
  if (normalized.isEmpty) return 'Not provided';
  return normalized
      .split(RegExp(r'\s+'))
      .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}

String _formatScore(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}
