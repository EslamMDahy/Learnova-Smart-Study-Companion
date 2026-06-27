part of 'question_bank_tab.dart';

class _GeneratedExamSuccessDialog extends StatelessWidget {
  final ExamModel exam;
  final ExamTemplateModel template;

  const _GeneratedExamSuccessDialog({required this.exam, required this.template});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      icon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.check_circle_rounded, color: AppColors.successText, size: 28),
      ),
      title: const Text('Exam generated'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The exam was created successfully. Next, you will be taken to this course’s Exams page.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.45, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          _GeneratedExamLine(label: 'Exam', value: exam.title),
          _GeneratedExamLine(label: 'Template', value: template.name),
          _GeneratedExamLine(label: 'Questions', value: '${exam.totalQuestions}'),
          _GeneratedExamLine(label: 'Score', value: exam.totalScore.toStringAsFixed(exam.totalScore.truncateToDouble() == exam.totalScore ? 0 : 1)),
          _GeneratedExamLine(label: 'Status', value: exam.isPublished ? 'Published' : 'Draft'),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Open course exams'),
        ),
      ],
    );
  }
}

class _GeneratedExamLine extends StatelessWidget {
  final String label;
  final String value;

  const _GeneratedExamLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w900)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: AppColors.textTitle, fontSize: 12.5, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _TemplateRequirementGap {
  final String label;
  final int requiredCount;
  final int availableCount;

  const _TemplateRequirementGap({
    required this.label,
    required this.requiredCount,
    required this.availableCount,
  });
}

class _TemplateDistributionStatus extends StatelessWidget {
  final ExamTemplateModel template;
  final List<_TemplateRequirementGap> gaps;

  const _TemplateDistributionStatus({required this.template, required this.gaps});

  @override
  Widget build(BuildContext context) {
    final distribution = _templateDistributionText(template);
    if (distribution.isEmpty) {
      return Text(
        'Template uses total question count only.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700),
      );
    }
    final ok = gaps.isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: ok ? AppColors.successBg : AppColors.dangerBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ok ? AppColors.successText.withOpacity(0.24) : AppColors.dangerBorder),
      ),
      child: Text(
        ok ? 'Section plan ready: $distribution' : 'Section shortage: ${gaps.map((gap) => '${gap.label} ${gap.availableCount}/${gap.requiredCount}').join(' • ')}',
        style: TextStyle(
          color: ok ? AppColors.successText : AppColors.dangerText,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _difficultyLabelFromKey(String key) {
  switch (key.trim().toLowerCase()) {
    case 'easy':
      return 'Easy';
    case 'hard':
      return 'Hard';
    default:
      return 'Medium';
  }
}

String _templateDistributionText(ExamTemplateModel template) {
  final sections = template.sections.where((section) => section.questionCount > 0).toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  if (sections.isEmpty) return '';
  return sections.map((section) {
    return '${section.questionCount} ${_shortTemplateQuestionTypeLabel(section.questionType)}';
  }).join(' / ');
}

String _templateQuestionTypeLabel(String questionType) {
  switch (questionType) {
    case 'true_false':
      return 'True / False';
    case 'short_answer':
      return 'Short Answer';
    case 'essay':
      return 'Essay';
    case 'multi_select':
      return 'Multi-Select';
    case 'fill_in_the_blank':
    case 'fill_in_blank':
      return 'Fill in the Blank';
    case 'numeric':
      return 'Numeric';
    case 'code':
      return 'Code';
    default:
      return 'Multiple Choice';
  }
}

String _shortTemplateQuestionTypeLabel(String questionType) {
  switch (questionType) {
    case 'true_false':
      return 'TF';
    case 'short_answer':
      return 'SA';
    case 'essay':
      return 'Essay';
    case 'multi_select':
      return 'MS';
    case 'fill_in_the_blank':
    case 'fill_in_blank':
      return 'Blank';
    case 'numeric':
      return 'Num';
    case 'code':
      return 'Code';
    default:
      return 'MCQ';
  }
}

