part of 'student_course_details_page.dart';

class _ExamOverviewBody extends ConsumerStatefulWidget {
  final StudentCourse? course;
  final StudentCourseExam exam;
  final VoidCallback? onStart;

  const _ExamOverviewBody({
    required this.course,
    required this.exam,
    required this.onStart,
  });

  @override
  ConsumerState<_ExamOverviewBody> createState() => _ExamOverviewBodyState();
}

class _ExamOverviewBodyState extends ConsumerState<_ExamOverviewBody> {
  Timer? _gradingRefreshTimer;

  @override
  void didUpdateWidget(covariant _ExamOverviewBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exam.id != widget.exam.id || oldWidget.exam.courseId != widget.exam.courseId) {
      _gradingRefreshTimer?.cancel();
      _gradingRefreshTimer = null;
    }
  }

  @override
  void dispose() {
    _gradingRefreshTimer?.cancel();
    super.dispose();
  }

  void _scheduleGradingRefresh(StudentExamResultArgs args) {
    if (_gradingRefreshTimer?.isActive == true) return;
    _gradingRefreshTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      ref.invalidate(studentExamLatestResultProvider(args));
      _gradingRefreshTimer = null;
    });
  }

  void _stopGradingRefresh() {
    _gradingRefreshTimer?.cancel();
    _gradingRefreshTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final args = StudentExamResultArgs(courseId: widget.exam.courseId, examId: widget.exam.id);
    final resultAsync = ref.watch(studentExamLatestResultProvider(args));
    final cachedResult = StudentExamResultsCache.loadLatest(
      courseId: widget.exam.courseId,
      examId: widget.exam.id,
    );

    return resultAsync.when(
      loading: () => _QuizResultOverviewShell(
        course: widget.course,
        exam: widget.exam,
        result: cachedResult,
        loading: cachedResult == null,
        errorMessage: null,
        onStart: widget.onStart,
      ),
      error: (error, _) => _QuizResultOverviewShell(
        course: widget.course,
        exam: widget.exam,
        result: cachedResult,
        loading: false,
        errorMessage: cachedResult == null
            ? 'Could not load the latest result. Please refresh the course.'
            : null,
        onStart: widget.onStart,
      ),
      data: (result) {
        if (result.gradingPending) {
          _scheduleGradingRefresh(args);
        } else {
          _stopGradingRefresh();
        }
        return _QuizResultOverviewShell(
          course: widget.course,
          exam: widget.exam,
          result: result,
          loading: false,
          errorMessage: null,
          onStart: widget.onStart,
        );
      },
    );
  }
}

class _QuizResultOverviewShell extends StatelessWidget {
  final StudentCourse? course;
  final StudentCourseExam exam;
  final StudentExamLatestResult? result;
  final bool loading;
  final String? errorMessage;
  final VoidCallback? onStart;

  const _QuizResultOverviewShell({
    required this.course,
    required this.exam,
    required this.result,
    required this.loading,
    required this.errorMessage,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final hasAttempt = result?.hasAttempt == true;
    final gradingPending = hasAttempt && result?.gradingPending == true;
    final totalScore = hasAttempt ? (result?.totalScore ?? exam.totalScore) : exam.totalScore;
    final scoreEarned = hasAttempt && !gradingPending ? (result?.scoreEarned ?? 0) : 0.0;
    final totalQuestions = hasAttempt ? (result?.totalQuestions ?? exam.totalQuestions) : exam.totalQuestions;
    final correct = hasAttempt && !gradingPending ? (result?.correctCount ?? 0) : 0;
    final incorrect = hasAttempt && !gradingPending ? (result?.incorrectCount ?? 0) : 0;
    final unanswered = hasAttempt ? (result?.unansweredCount ?? 0) : totalQuestions;
    final accuracy = hasAttempt && !gradingPending ? (result?.accuracyPercent ?? 0) : 0.0;
    final canStart = !loading && (result?.canStart ?? exam.isAvailable) && onStart != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QuizResultHeader(
          course: course,
          exam: exam,
          result: result,
          loading: loading,
          hasAttempt: hasAttempt,
          gradingPending: gradingPending,
          onStart: canStart ? onStart : null,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 18),
          _ResultNotice(
            icon: Icons.warning_amber_rounded,
            text: errorMessage!,
            danger: true,
          ),
        ],
        if (gradingPending) ...[
          const SizedBox(height: 18),
          _GradingProgressNotice(
            answeredCount: result?.answeredCount ?? 0,
            totalQuestions: totalQuestions,
          ),
        ],
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 760;
            final cards = [
              _ResultScoreCard(
                label: 'OVERALL SCORE',
                value: gradingPending ? '—' : _formatScore(scoreEarned),
                suffix: gradingPending ? null : '/${_formatScore(totalScore)}',
                helper: gradingPending
                    ? 'Submitted — waiting for grading'
                    : hasAttempt
                        ? (result?.isPassed == true ? 'Passed assessment' : 'Latest submitted attempt')
                        : 'No submitted attempt yet',
                icon: Icons.emoji_events_outlined,
              ),
              _ResultScoreCard(
                label: 'TIME TAKEN',
                value: hasAttempt ? _formatElapsedTime(result?.timeSpentSeconds ?? 0) : '0m 0s',
                helper: gradingPending
                    ? 'Submitted answers are being checked'
                    : hasAttempt && totalQuestions > 0
                        ? 'Avg. ${_formatElapsedTime(((result?.timeSpentSeconds ?? 0) / totalQuestions).round())} per question'
                        : 'Timer starts when you take the exam',
                icon: Icons.schedule_rounded,
              ),
              _AccuracyScoreCard(
                percent: accuracy,
                correct: correct,
                incorrect: incorrect,
                unanswered: unanswered,
              ),
              _ResultScoreCard(
                label: 'PERCENTILE',
                value: 'Top 0%',
                helper: gradingPending
                    ? 'Ranking appears after grading'
                    : hasAttempt
                        ? 'Class ranking is not calculated yet'
                        : 'Complete the exam first',
                icon: Icons.leaderboard_outlined,
              ),
            ];

            if (narrow) {
              return Column(
                children: [
                  for (final card in cards) ...[
                    card,
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  Expanded(child: cards[i]),
                  if (i != cards.length - 1) const SizedBox(width: 12),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        _AiLearningAnalysisPanel(
          course: course,
          hasAttempt: hasAttempt,
          gradingPending: gradingPending,
          questions: result?.questions ?? const <StudentExamResultQuestion>[],
        ),
        const SizedBox(height: 28),
        _ResultQuestionReview(
          hasAttempt: hasAttempt,
          loading: loading,
          questions: result?.questions ?? const <StudentExamResultQuestion>[],
          totalQuestions: totalQuestions,
          incorrectCount: incorrect,
          gradingPending: gradingPending,
          onStart: canStart ? onStart : null,
        ),
      ],
    );
  }
}

class _QuizResultHeader extends StatelessWidget {
  final StudentCourse? course;
  final StudentCourseExam exam;
  final StudentExamLatestResult? result;
  final bool loading;
  final bool hasAttempt;
  final bool gradingPending;
  final VoidCallback? onStart;

  const _QuizResultHeader({
    required this.course,
    required this.exam,
    required this.result,
    required this.loading,
    required this.hasAttempt,
    required this.gradingPending,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = loading ? 'Loading' : (result?.statusLabel ?? (hasAttempt ? 'Completed' : 'Not taken'));
    final completedLine = hasAttempt
        ? (gradingPending
            ? 'Assessment submitted on ${_formatResultDate(result?.submittedAt)} • Grading in progress • ID: #EXAM-${exam.id}'
            : 'Assessment completed on ${_formatResultDate(result?.submittedAt)} • Attempt #${result?.attemptNumber ?? 1} • ID: #EXAM-${exam.id}')
        : 'Assessment not taken yet • ${course?.safeCode ?? 'COURSE-${exam.courseId}'} • ID: #EXAM-${exam.id}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      exam.safeTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 20,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusBadge(label: statusLabel, active: hasAttempt),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                completedLine,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: hasAttempt ? () {} : null,
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Export PDF'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textGray,
                disabledForegroundColor: AppColors.textHint,
                side: BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            if (!hasAttempt)
              ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Take Exam'),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.border,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: AppColors.textMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            else
              FilledButton.tonal(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.headerBg,
                  foregroundColor: AppColors.textTitle,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Back to Dashboard'),
              ),
          ],
        ),
      ],
    );
  }
}

class _ResultScoreCard extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final String helper;
  final IconData icon;

  const _ResultScoreCard({
    required this.label,
    required this.value,
    this.suffix,
    required this.helper,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 136,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: AppColors.shadowThin, blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Icon(icon, color: AppColors.infoBg, size: 52),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 27,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                  if (suffix != null) ...[
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        suffix!,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                helper,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccuracyScoreCard extends StatelessWidget {
  final double percent;
  final int correct;
  final int incorrect;
  final int unanswered;

  const _AccuracyScoreCard({
    required this.percent,
    required this.correct,
    required this.incorrect,
    required this.unanswered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 136,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: AppColors.shadowThin, blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ACCURACY RATE',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: percent <= 0 ? 0.0 : ((percent / 100).clamp(0.0, 1.0)).toDouble(),
                      strokeWidth: 6,
                      backgroundColor: AppColors.infoBg,
                      color: AppColors.primary,
                    ),
                    Text(
                      '${percent.round()}%',
                      style: TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  '$correct Correct\n$incorrect Incorrect${unanswered > 0 ? '\n$unanswered Unanswered' : ''}',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiLearningAnalysisPanel extends StatelessWidget {
  final StudentCourse? course;
  final bool hasAttempt;
  final bool gradingPending;
  final List<StudentExamResultQuestion> questions;

  const _AiLearningAnalysisPanel({
    required this.course,
    required this.hasAttempt,
    required this.gradingPending,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    final missed = questions.where((q) => q.isIncorrectAnswer || q.isUnanswered).take(2).toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.infoBg.withOpacity(0.55), AppColors.cardBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Learning Analysis',
                style: TextStyle(color: AppColors.textTitle, fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 720;
              final left = _AnalysisColumn(
                title: 'IDENTIFIED WEAKNESSES',
                children: gradingPending
                    ? [
                        _AnalysisItem(
                          icon: Icons.hourglass_top_rounded,
                          iconColor: AppColors.primary,
                          bgColor: AppColors.infoBg,
                          borderColor: AppColors.infoBorder,
                          title: 'Grading in progress',
                          subtitle: 'Your answers were submitted. The result will appear here once grading is ready.',
                        ),
                      ]
                    : hasAttempt
                        ? (questions.isEmpty
                        ? [
                            _AnalysisItem(
                              icon: Icons.insights_rounded,
                              iconColor: AppColors.primary,
                              bgColor: AppColors.infoBg,
                              borderColor: AppColors.infoBorder,
                              title: 'Review loaded',
                              subtitle: 'Your latest answers are available below for revision.',
                            ),
                          ]
                        : missed.isEmpty
                            ? [
                                _AnalysisItem(
                                  icon: Icons.check_circle_outline_rounded,
                                  iconColor: AppColors.successDot,
                                  bgColor: AppColors.successBg,
                                  borderColor: AppColors.greenBorder,
                                  title: 'No weak points detected',
                                  subtitle: 'Great work. Your submitted answers did not reveal major gaps.',
                                ),
                              ]
                            : missed
                            .map(
                              (q) => _AnalysisItem(
                                icon: q.isUnanswered ? Icons.info_outline_rounded : Icons.warning_amber_rounded,
                                iconColor: q.isUnanswered ? AppColors.warningText : AppColors.errorDot,
                                bgColor: q.isUnanswered ? AppColors.warningSoftBg : AppColors.dangerBg,
                                borderColor: q.isUnanswered ? AppColors.warningBorder : AppColors.dangerBorder,
                                title: _shortText(q.safeText, 48),
                                subtitle: q.isUnanswered
                                    ? 'You left this question unanswered. Review the related material.'
                                    : 'Your answer was incorrect. Review this concept before retrying.',
                              ),
                            )
                            .toList(growable: false))
                    : [
                        _AnalysisItem(
                          icon: Icons.info_outline_rounded,
                          iconColor: AppColors.primary,
                          bgColor: AppColors.infoBg,
                          borderColor: AppColors.infoBorder,
                          title: 'No attempt submitted yet',
                          subtitle: 'Complete this assessment to unlock weakness analysis.',
                        ),
                      ],
              );
              final right = _AnalysisColumn(
                title: 'RECOMMENDED STUDY MATERIALS',
                children: [
                  _AnalysisItem(
                    icon: Icons.picture_as_pdf_outlined,
                    iconColor: AppColors.errorDot,
                    bgColor: AppColors.dangerBg,
                    borderColor: AppColors.dangerBorder,
                    title: course?.safeTitle ?? 'Course materials',
                    subtitle: hasAttempt ? 'Review the attached PDF materials for this course.' : 'Recommendations appear after your first attempt.',
                    hasArrow: hasAttempt,
                  ),
                  const SizedBox(height: 12),
                  _AnalysisItem(
                    icon: Icons.quiz_outlined,
                    iconColor: AppColors.primary,
                    bgColor: AppColors.infoBg,
                    borderColor: AppColors.infoBorder,
                    title: 'Practice similar questions',
                    subtitle: hasAttempt ? 'Focus on the questions marked incorrect or unanswered.' : 'Start the exam to build a personalized plan.',
                    hasArrow: hasAttempt,
                  ),
                ],
              );

              if (narrow) {
                return Column(
                  children: [left, const SizedBox(height: 18), right],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 28),
                  Expanded(child: right),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnalysisColumn extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _AnalysisColumn({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.45,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _AnalysisItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final String title;
  final String subtitle;
  final bool hasArrow;

  const _AnalysisItem({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.title,
    required this.subtitle,
    this.hasArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textTitle, fontSize: 13, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.35, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (hasArrow) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
          ],
        ],
      ),
    );
  }
}

class _ResultQuestionReview extends StatelessWidget {
  final bool hasAttempt;
  final bool loading;
  final List<StudentExamResultQuestion> questions;
  final int totalQuestions;
  final int incorrectCount;
  final bool gradingPending;
  final VoidCallback? onStart;

  const _ResultQuestionReview({
    required this.hasAttempt,
    required this.loading,
    required this.questions,
    required this.totalQuestions,
    required this.incorrectCount,
    required this.gradingPending,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Question Review',
              style: TextStyle(color: AppColors.textTitle, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            _ReviewFilterChip(label: 'All ($totalQuestions)', selected: true),
            const SizedBox(width: 8),
            _ReviewFilterChip(label: 'Incorrect ($incorrectCount)', danger: true),
            const SizedBox(width: 8),
            const _ReviewFilterChip(label: 'Flagged (0)'),
          ],
        ),
        const SizedBox(height: 16),
        if (loading)
          const _ResultLoadingCard()
        else if (!hasAttempt)
          _EmptyResultQuestionCard(onStart: onStart)
        else if (gradingPending)
          const _GradingReviewCard()
        else if (questions.isEmpty)
          const _NoReviewQuestionsCard()
        else
          for (var i = 0; i < questions.length; i++) ...[
            _ResultQuestionCard(question: questions[i], displayIndex: i + 1),
            const SizedBox(height: 14),
          ],
      ],
    );
  }
}


class _GradingProgressNotice extends StatelessWidget {
  final int answeredCount;
  final int totalQuestions;

  const _GradingProgressNotice({
    required this.answeredCount,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final answered = answeredCount.clamp(0, totalQuestions).toInt();
    final total = totalQuestions <= 0 ? answered : totalQuestions;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.infoBg.withOpacity(0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.hourglass_top_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your exam was submitted. Grading is in progress.',
                  style: TextStyle(color: AppColors.textTitle, fontSize: 14, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Answered $answered / $total questions. The score cards below will update when grading is available.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.45, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const SizedBox(height: 7, child: LinearProgressIndicator()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradingReviewCard extends StatelessWidget {
  const _GradingReviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Row(
        children: [
          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.8)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Question review will appear after the attempt is graded.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool danger;

  const _ReviewFilterChip({required this.label, this.selected = false, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.cardBg : AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? AppColors.borderSoft : AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: danger ? AppColors.dangerText : AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ResultQuestionCard extends StatelessWidget {
  final StudentExamResultQuestion question;
  final int displayIndex;

  const _ResultQuestionCard({required this.question, required this.displayIndex});

  @override
  Widget build(BuildContext context) {
    final correct = question.isCorrectAnswer;
    final unanswered = question.isUnanswered;
    final pendingAi = question.isAiGradingPending;
    final stripColor = pendingAi
        ? AppColors.primary
        : unanswered
            ? AppColors.warningDot
            : (correct ? AppColors.successDot : AppColors.errorDot);
    final statusLabel = pendingAi ? 'Pending AI Review' : (unanswered ? 'Unanswered' : (correct ? 'Correct' : 'Incorrect'));
    final statusColor = pendingAi ? AppColors.infoText : (unanswered ? AppColors.warningText : (correct ? AppColors.successText : AppColors.dangerText));
    final statusBg = pendingAi ? AppColors.infoBg : (unanswered ? AppColors.warningSoftBg : (correct ? AppColors.successBg : AppColors.dangerBg));

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.shadowThin, blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 4, constraints: const BoxConstraints(minHeight: 110), color: stripColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 68,
                        child: Text(
                          'Q. ${displayIndex.toString().padLeft(2, '0')}',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w900),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          question.safeText,
                          style: TextStyle(color: AppColors.textTitle, fontSize: 14, height: 1.45, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              pendingAi
                                  ? Icons.hourglass_top_rounded
                                  : (correct ? Icons.check_rounded : (unanswered ? Icons.help_outline_rounded : Icons.close_rounded)),
                              color: statusColor,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.headerBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          '${_formatScore(question.pointsEarned)}/${_formatScore(question.points)} pts',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 88),
                    child: pendingAi
                        ? _AnswerBox(
                            label: 'Your Answer',
                            text: question.selectedAnswerText ?? 'No answer text',
                          )
                        : correct
                            ? _AnswerBox(
                                label: 'Your Answer',
                                text: question.selectedAnswerText ?? 'No answer text',
                                success: true,
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final narrow = constraints.maxWidth < 620;
                                  final boxes = [
                                    _AnswerBox(
                                      label: 'Your Answer',
                                      text: unanswered ? 'No answer submitted' : (question.selectedAnswerText ?? 'No answer text'),
                                      danger: true,
                                    ),
                                    _AnswerBox(
                                      label: 'Correct Answer',
                                      text: question.correctAnswerText ?? 'Correct answer is not available',
                                      success: true,
                                    ),
                                  ];
                                  if (narrow) {
                                    return Column(children: [boxes[0], const SizedBox(height: 10), boxes[1]]);
                                  }
                                  return Row(children: [Expanded(child: boxes[0]), const SizedBox(width: 14), Expanded(child: boxes[1])]);
                                },
                              ),
                  ),
                  if (pendingAi) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 88),
                      child: _PendingAiFeedbackBox(),
                    ),
                  ],
                  if ((question.explanation ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 88),
                      child: _ExplanationBox(text: question.explanation!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingAiFeedbackBox extends StatelessWidget {
  const _PendingAiFeedbackBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoBg.withOpacity(0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hourglass_top_rounded, color: AppColors.infoText, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI grading has not returned for this written answer yet. It will update automatically after the backend receives the callback.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.45, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerBox extends StatelessWidget {
  final String label;
  final String text;
  final bool success;
  final bool danger;

  const _AnswerBox({required this.label, required this.text, this.success = false, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final bg = success ? AppColors.successBg : (danger ? AppColors.dangerBg : AppColors.headerBg);
    final border = success ? AppColors.greenBorder : (danger ? AppColors.dangerBorder : AppColors.border);
    final fg = success ? AppColors.successText : (danger ? AppColors.dangerText : AppColors.textTitle);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.4)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(success ? Icons.check_circle_rounded : (danger ? Icons.cancel_rounded : Icons.circle_outlined), color: fg, size: 17),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: TextStyle(color: AppColors.textTitle, fontSize: 13, height: 1.35, fontWeight: FontWeight.w700))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExplanationBox extends StatelessWidget {
  final String text;

  const _ExplanationBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Explanation', style: TextStyle(color: AppColors.textTitle, fontSize: 12, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(text, style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.45, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResultQuestionCard extends StatelessWidget {
  final VoidCallback? onStart;

  const _EmptyResultQuestionCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.assignment_outlined, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 14),
          Text('No answers yet', style: TextStyle(color: AppColors.textTitle, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            'This results page will fill with your score, answers, correct answers, and explanations after you submit the exam.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Take Exam'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.border,
              foregroundColor: Colors.white,
              disabledForegroundColor: AppColors.textMuted,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoReviewQuestionsCard extends StatelessWidget {
  const _NoReviewQuestionsCard();

  @override
  Widget build(BuildContext context) {
    return _ResultNotice(
      icon: Icons.info_outline_rounded,
      text: 'Your result summary is available, but no question review was returned for this attempt yet.',
      danger: false,
    );
  }
}

class _ResultLoadingCard extends StatelessWidget {
  const _ResultLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
          const SizedBox(width: 14),
          Text('Loading latest assessment result...', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ResultNotice extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool danger;

  const _ResultNotice({required this.icon, required this.text, required this.danger});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: danger ? AppColors.dangerBg : AppColors.infoBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: danger ? AppColors.dangerBorder : AppColors.infoBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: danger ? AppColors.dangerText : AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: danger ? AppColors.dangerText : AppColors.infoText, fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}


class _StatusBadge extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusBadge({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppColors.successBg : AppColors.headerBg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: active ? AppColors.successDot : AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.successText : AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

