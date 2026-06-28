part of 'question_bank_tab.dart';

class _QuestionReviewDialog extends ConsumerStatefulWidget {
  final int courseId;
  final QuestionModel question;
  final List<_TopicTarget> topicTargets;

  const _QuestionReviewDialog({
    required this.courseId,
    required this.question,
    required this.topicTargets,
  });

  @override
  ConsumerState<_QuestionReviewDialog> createState() => _QuestionReviewDialogState();
}

class _QuestionReviewDialogState extends ConsumerState<_QuestionReviewDialog> {
  late QuestionModel _question;
  bool _loadingDetails = false;
  String? _detailsError;

  @override
  void initState() {
    super.initState();
    _question = widget.question;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFullQuestion());
  }

  Future<void> _loadFullQuestion() async {
    final questionId = widget.question.remoteId ?? int.tryParse(widget.question.id);
    if (questionId == null || questionId <= 0) return;
    if (!mounted) return;
    setState(() {
      _loadingDetails = true;
      _detailsError = null;
    });
    try {
      final hydrated = await ref.read(questionsApiProvider).getQuestion(
            courseId: widget.courseId,
            questionId: questionId,
          );
      if (!mounted) return;
      setState(() {
        _question = hydrated;
        _loadingDetails = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailsError = mapApiFailure(e).message;
        _loadingDetails = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final compact = size.width < 760;
    return Dialog(
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 42,
        vertical: compact ? 18 : 34,
      ),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 940,
          maxHeight: size.height * 0.88,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: AppColors.cardBg,
            child: _QuestionInspector(
              question: _question,
              topicTargets: widget.topicTargets,
              loadingDetails: _loadingDetails,
              detailsError: _detailsError,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionInspector extends StatelessWidget {
  final QuestionModel? question;
  final List<_TopicTarget> topicTargets;
  final bool loadingDetails;
  final String? detailsError;
  final VoidCallback? onClose;

  const _QuestionInspector({
    required this.question,
    required this.topicTargets,
    this.loadingDetails = false,
    this.detailsError,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final q = question;
    if (q == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        color: AppColors.cardBg,
        child: Center(
          child: Text(
            'Select a question to review the answer and details.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, height: 1.5, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    final target = _targetForQuestion(topicTargets, q);
    final topicPath = _topicPathFromTarget(target, q);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 16, 18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF145CCB), Color(0xFF137FEC), Color(0xFF22C1F1)],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                ),
                child: const Icon(Icons.fact_check_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Question review',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$topicPath • ${q.typeLabel} • ${q.difficultyLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (loadingDetails) ...[
                  const _InspectorNotice(
                    icon: Icons.sync_rounded,
                    message: 'Loading the full question record from the backend...',
                    tone: _InspectorNoticeTone.info,
                  ),
                  const SizedBox(height: 14),
                ],
                if (detailsError != null) ...[
                  _InspectorNotice(
                    icon: Icons.warning_amber_rounded,
                    message: 'Full question details could not be loaded. Showing the cached row data. ${detailsError!}',
                    tone: _InspectorNoticeTone.warning,
                  ),
                  const SizedBox(height: 14),
                ],
                _InspectorSection(
                  title: 'Question',
                  child: Text(
                    q.text,
                    style: TextStyle(
                      color: AppColors.textTitle,
                      fontSize: 17,
                      height: 1.45,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.15,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _InspectorSection(
                  title: 'Answer',
                  child: _AnswerPreview(question: q),
                ),
                if (q.explanation != null && q.explanation!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _InspectorSection(
                    title: 'Explanation',
                    child: _MutedBox(q.explanation!),
                  ),
                ],
                if (q.gradingRubric != null) ...[
                  const SizedBox(height: 14),
                  _InspectorSection(
                    title: 'Grading rubric',
                    child: _MutedBox(_jsonish(q.gradingRubric)),
                  ),
                ],
                const SizedBox(height: 14),
                _InspectorSection(
                  title: 'Learning outcomes',
                  child: q.learningOutcomes.isEmpty
                      ? const _MutedBox('No learning outcome is linked to this question.')
                      : Column(
                          children: q.learningOutcomes
                              .map((outcome) => _OutcomeLine(title: outcome.title))
                              .toList(),
                        ),
                ),
                if (q.tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _InspectorSection(
                    title: 'Tags',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: q.tags.map(_TagChip.new).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}



enum _InspectorNoticeTone { info, warning }

class _InspectorNotice extends StatelessWidget {
  final IconData icon;
  final String message;
  final _InspectorNoticeTone tone;

  const _InspectorNotice({
    required this.icon,
    required this.message,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final warning = tone == _InspectorNoticeTone.warning;
    final fg = warning ? AppColors.warningText : AppColors.primary;
    final bg = warning ? AppColors.warningSoftBg : AppColors.primarySoft;
    final border = warning ? AppColors.warningBorder : AppColors.primary.withValues(alpha: 0.22);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _InspectorSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.65,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _AnswerPreview extends StatelessWidget {
  final QuestionModel question;

  const _AnswerPreview({required this.question});

  @override
  Widget build(BuildContext context) {
    if (question.options.isNotEmpty) {
      final hasCorrect = question.options.asMap().entries.any((entry) => _isCorrectOption(question, entry.value, index: entry.key));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List<Widget>.generate(question.options.length, (index) {
            final option = question.options[index];
            final correct = _isCorrectOption(question, option, index: index);
            return _AnswerOptionCard(
              index: index,
              option: option,
              correct: correct,
              multiSelect: question.type == QuestionType.multiSelect,
            );
          }),
          if (!hasCorrect && _answerText(question).isNotEmpty) ...[
            const SizedBox(height: 4),
            _InspectorNotice(
              icon: Icons.info_outline_rounded,
              message: 'Stored expected answer: ${_answerText(question)}. It does not match any visible option id.',
              tone: _InspectorNoticeTone.warning,
            ),
          ],
        ],
      );
    }

    if (question.type == QuestionType.trueFalse) {
      final answer = question.correctBool ?? (question.expectedAnswer?.toLowerCase() == 'true' ? true : question.expectedAnswer?.toLowerCase() == 'false' ? false : null);
      if (answer != null) {
        return Row(
          children: [
            Expanded(child: _BooleanAnswerPreview(label: 'True', selected: answer == true)),
            const SizedBox(width: 10),
            Expanded(child: _BooleanAnswerPreview(label: 'False', selected: answer == false)),
          ],
        );
      }
    }

    final answer = _answerText(question);
    return _MutedBox(answer.isEmpty ? 'No answer stored for this question.' : answer);
  }
}

class _AnswerOptionCard extends StatelessWidget {
  final int index;
  final QuestionOption option;
  final bool correct;
  final bool multiSelect;

  const _AnswerOptionCard({
    required this.index,
    required this.option,
    required this.correct,
    required this.multiSelect,
  });

  @override
  Widget build(BuildContext context) {
    final label = String.fromCharCode(65 + index);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: correct ? AppColors.successBg : AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: correct ? AppColors.greenBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: correct ? AppColors.successText : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: correct ? AppColors.successText : AppColors.border),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: correct ? Colors.white : AppColors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  correct
                      ? Icons.check_circle_rounded
                      : multiSelect
                          ? Icons.check_box_outline_blank_rounded
                          : Icons.radio_button_unchecked_rounded,
                  size: 17,
                  color: correct ? AppColors.successText : AppColors.textHint,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  option.text,
                  style: TextStyle(
                    color: correct ? AppColors.successText : AppColors.textTitle,
                    fontSize: 12.8,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (correct)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.greenBorder),
                  ),
                  child: Text(
                    'Correct',
                    style: TextStyle(
                      color: AppColors.successText,
                      fontSize: 10.6,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          if ((option.explanation ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 45),
              child: Text(
                option.explanation!.trim(),
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BooleanAnswerPreview extends StatelessWidget {
  final String label;
  final bool selected;

  const _BooleanAnswerPreview({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.successBg : AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? AppColors.greenBorder : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: selected ? AppColors.successText : AppColors.textHint,
          ),
          const SizedBox(width: 9),
          Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.successText : AppColors.textTitle,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutcomeLine extends StatelessWidget {
  final String title;

  const _OutcomeLine({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.track_changes_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: AppColors.textTitle, fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _MutedBox extends StatelessWidget {
  final String text;

  const _MutedBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12.5,
          height: 1.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

