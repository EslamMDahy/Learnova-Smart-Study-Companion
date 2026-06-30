import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/courses_models.dart';
import '../../data/exam_correction_models.dart';
import '../../data/exam_models.dart';
import '../controllers/exam_correction_controller.dart';

class ExamCorrectionPage extends ConsumerWidget {
  const ExamCorrectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1120;
        final padding = EdgeInsets.symmetric(
          horizontal: constraints.maxWidth < 680 ? 16 : 32,
          vertical: constraints.maxWidth < 680 ? 18 : 28,
        );

        return SingleChildScrollView(
          padding: padding,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CorrectionHero(),
                  const SizedBox(height: 20),
                  if (compact) ...[
                    const _UploadPdfPanel(),
                    const SizedBox(height: 18),
                    const _CorrectionWorkspace(),
                  ] else
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 385, child: _UploadPdfPanel()),
                        SizedBox(width: 22),
                        Expanded(child: _CorrectionWorkspace()),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CorrectionHero extends StatelessWidget {
  const _CorrectionHero();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(28),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroIcon(),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exam Correction', style: AppText.h1.copyWith(fontSize: 30, height: 1.15)),
                    const SizedBox(height: 8),
                    Text(
                      'Upload one solved exam PDF. The system reads the QR metadata, detects printed choice bubbles, grades objective questions immediately, and keeps written answers for instructor review.',
                      style: AppText.subtitle.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          );

          final badge = const _SoftBadge(icon: Icons.picture_as_pdf_rounded, label: 'PDF only');
          if (compact) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [content, const SizedBox(height: 18), badge]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: content), const SizedBox(width: 24), Flexible(child: Align(alignment: Alignment.topRight, child: badge))],
          );
        },
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 30),
    );
  }
}

class _UploadPdfPanel extends ConsumerStatefulWidget {
  const _UploadPdfPanel();

  @override
  ConsumerState<_UploadPdfPanel> createState() => _UploadPdfPanelState();
}

class _UploadPdfPanelState extends ConsumerState<_UploadPdfPanel> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(examCorrectionControllerProvider.notifier).loadExamContext());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(examCorrectionControllerProvider);
    final controller = ref.read(examCorrectionControllerProvider.notifier);

    return _GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            icon: Icons.upload_file_rounded,
            title: 'Upload exam PDF',
            subtitle: 'Select the exact course and exam, then upload the solved PDF.',
          ),
          const SizedBox(height: 18),
          _ExamTargetPicker(
            courses: state.courses,
            exams: state.exams,
            selectedCourseId: state.selectedCourseId,
            selectedExamId: state.selectedExamId,
            loadingCourses: state.loadingCourses,
            loadingExams: state.loadingExams,
            disabled: state.loading,
            onRefresh: () => controller.loadExamContext(force: true),
            onCourseChanged: controller.selectCourse,
            onExamChanged: controller.selectExam,
          ),
          if (state.contextError != null && state.contextError!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _Notice(message: state.contextError!, tone: _NoticeTone.warning),
          ],
          const SizedBox(height: 18),
          _UploadDropZone(
            hasFile: state.files.isNotEmpty,
            loading: state.loading,
            onTap: state.loading ? null : controller.pickFiles,
          ),
          if (state.files.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SelectedFileTile(file: state.files.first, onRemove: () => controller.removeFile(0)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: state.loading ? null : controller.clearFiles,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Remove PDF'),
              ),
            ),
          ],
          if (state.files.isNotEmpty && !state.hasExamTarget) ...[
            const SizedBox(height: 12),
            const _Notice(
              message: 'Choose the matching course and exam so the backend can bind every MCQ, true/false, multi-select, and written question even when the QR scan is weak.',
              tone: _NoticeTone.warning,
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: state.canAnalyze ? controller.analyzeScan : null,
              icon: state.loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.document_scanner_outlined),
              label: Text(state.loading ? 'Analyzing PDF...' : 'Analyze selected exam'),
            ),
          ),
          if (state.error != null && state.error!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _Notice(message: state.error!, tone: _NoticeTone.error),
          ],
        ],
      ),
    );
  }
}

class _ExamTargetPicker extends StatelessWidget {
  final List<MyCourseItem> courses;
  final List<ExamModel> exams;
  final int? selectedCourseId;
  final int? selectedExamId;
  final bool loadingCourses;
  final bool loadingExams;
  final bool disabled;
  final VoidCallback onRefresh;
  final ValueChanged<int?> onCourseChanged;
  final ValueChanged<int?> onExamChanged;

  const _ExamTargetPicker({
    required this.courses,
    required this.exams,
    required this.selectedCourseId,
    required this.selectedExamId,
    required this.loadingCourses,
    required this.loadingExams,
    required this.disabled,
    required this.onRefresh,
    required this.onCourseChanged,
    required this.onExamChanged,
  });

  @override
  Widget build(BuildContext context) {
    final courseValue = courses.any((course) => course.id == selectedCourseId) ? selectedCourseId : null;
    final examValue = exams.any((exam) => exam.id == selectedExamId) ? selectedExamId : null;
    final canChangeCourse = !disabled && !loadingCourses;
    final canChangeExam = !disabled && !loadingExams && courseValue != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Correction target', style: AppText.label)),
              TextButton.icon(
                onPressed: disabled || loadingCourses ? null : onRefresh,
                icon: loadingCourses
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PickerField<int>(
            value: courseValue,
            hint: loadingCourses ? 'Loading courses...' : 'Select course',
            enabled: canChangeCourse,
            items: courses
                .map((course) => DropdownMenuItem<int>(
                      value: course.id,
                      child: Text('${course.safeTitle} • ${course.safeCourseCode}', overflow: TextOverflow.ellipsis),
                    ))
                .toList(growable: false),
            onChanged: canChangeCourse ? onCourseChanged : null,
          ),
          const SizedBox(height: 10),
          _PickerField<int>(
            value: examValue,
            hint: courseValue == null
                ? 'Select a course first'
                : loadingExams
                    ? 'Loading exams...'
                    : exams.isEmpty
                        ? 'No exams found in this course'
                        : 'Select exam',
            enabled: canChangeExam && exams.isNotEmpty,
            items: exams
                .map((exam) => DropdownMenuItem<int>(
                      value: exam.id,
                      child: Text(
                        '${exam.title.trim().isEmpty ? 'Untitled exam' : exam.title} • ${exam.totalQuestions} questions • ${exam.isPublished ? 'Published' : 'Draft'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(growable: false),
            onChanged: canChangeExam ? onExamChanged : null,
          ),
        ],
      ),
    );
  }
}

class _PickerField<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final bool enabled;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const _PickerField({
    required this.value,
    required this.hint,
    required this.enabled,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      items: items,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: enabled ? AppColors.cardBg : AppColors.fieldDisabledBg,
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.borderSoft)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.borderSoft)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.45))),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.borderSoft)),
      ),
      style: AppText.input.copyWith(color: AppColors.textTitle, fontWeight: FontWeight.w700),
    );
  }
}

class _UploadDropZone extends StatelessWidget {
  final bool hasFile;
  final bool loading;
  final VoidCallback? onTap;

  const _UploadDropZone({required this.hasFile, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surfaceBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: hasFile ? AppColors.primary.withValues(alpha: 0.30) : AppColors.borderSoft),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.borderSoft)),
              child: Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: 12),
            Text(hasFile ? 'PDF ready' : 'Choose PDF', style: AppText.sectionTitle.copyWith(fontSize: 16)),
            const SizedBox(height: 5),
            Text('One PDF file only', textAlign: TextAlign.center, style: AppText.mutedSmall),
          ],
        ),
      ),
    );
  }
}

class _SelectedFileTile extends StatelessWidget {
  final ExamCorrectionUploadFile file;
  final VoidCallback onRemove;

  const _SelectedFileTile({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.headerBg, borderRadius: BorderRadius.circular(12)),
            child: Text('PDF', style: AppText.mutedSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label),
                const SizedBox(height: 2),
                Text(file.displaySize, style: AppText.mutedSmall),
              ],
            ),
          ),
          IconButton(onPressed: onRemove, icon: const Icon(Icons.close_rounded, size: 18), tooltip: 'Remove'),
        ],
      ),
    );
  }
}

class _CorrectionWorkspace extends ConsumerWidget {
  const _CorrectionWorkspace();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(examCorrectionControllerProvider);

    if (state.loading && state.response == null) {
      return const _AnalyzingState();
    }

    final response = state.response;
    if (response == null) {
      return const _EmptyWorkspace();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GradingSummaryPanel(response: response),
        const SizedBox(height: 18),
        _QuestionResultsPanel(response: response),
      ],
    );
  }
}

class _AnalyzingState extends StatelessWidget {
  const _AnalyzingState();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(34),
      child: SizedBox(
        height: 520,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 64, height: 64, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3.5)),
              const SizedBox(height: 22),
              Text('Analyzing exam answers', style: AppText.h3),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text('The backend is reading the QR metadata and detecting selected choice bubbles. Written answers will be listed for manual review instead of unreliable handwriting OCR.', textAlign: TextAlign.center, style: AppText.sectionSubtitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyWorkspace extends StatelessWidget {
  const _EmptyWorkspace();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(34),
      child: SizedBox(
        height: 520,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                child: Icon(Icons.fact_check_outlined, color: AppColors.primary, size: 42),
              ),
              const SizedBox(height: 20),
              Text('No correction result yet', style: AppText.h3),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Text('Upload the solved exam PDF. The result will show each question, the detected student answer, the correct answer, feedback, and the exam score.', textAlign: TextAlign.center, style: AppText.sectionSubtitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradingSummaryPanel extends StatelessWidget {
  final ExamScanAnalyzeResponse response;

  const _GradingSummaryPanel({required this.response});

  @override
  Widget build(BuildContext context) {
    final title = response.exam.title?.trim().isNotEmpty == true ? response.exam.title!.trim() : 'Exam correction';
    final score = response.gradePreview.scoreSoFar;
    final total = response.gradePreview.totalScore;
    final percent = response.gradePreview.percentageScore ?? (total > 0 ? (score / total) * 100 : null);
    final duration = response.processingTimeSeconds;

    return _GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Correction result', style: AppText.h3),
                        const SizedBox(width: 10),
                        _StatusBadge(status: response.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(title, style: AppText.sectionSubtitle),
                  ],
                ),
              ),
              if (response.scanId.isNotEmpty) Text('Scan ${response.scanId}', style: AppText.mutedSmall),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryTile(label: 'Score', value: '${_formatNumber(score)} / ${_formatNumber(total)}', icon: Icons.scoreboard_outlined),
              _SummaryTile(label: 'Percentage', value: percent == null ? '—' : '${percent.toStringAsFixed(1)}%', icon: Icons.percent_rounded),
              _SummaryTile(label: 'Questions', value: '${response.answers.length}', icon: Icons.list_alt_rounded),
              _SummaryTile(label: 'Graded', value: '${response.gradePreview.gradedQuestions}', icon: Icons.verified_outlined),
              _SummaryTile(label: 'Correct', value: '${response.gradePreview.correctCount}', icon: Icons.check_circle_outline_rounded),
              _SummaryTile(label: 'Wrong', value: '${response.gradePreview.incorrectCount}', icon: Icons.cancel_outlined),
              if (response.gradePreview.needsReview > 0) _SummaryTile(label: 'Need review', value: '${response.gradePreview.needsReview}', icon: Icons.rate_review_outlined),
              if (duration != null) _SummaryTile(label: 'Processing', value: '${duration.toStringAsFixed(1)}s', icon: Icons.timer_outlined),
            ],
          ),
          const SizedBox(height: 14),
          _Notice(
            message: 'Instructor preview: objective answers are detected from the printed bubbles and graded immediately. Written answers are intentionally marked for manual review to avoid unreliable handwriting OCR.',
            tone: _NoticeTone.info,
          ),
        ],
      ),
    );
  }
}

class _QuestionResultsPanel extends StatelessWidget {
  final ExamScanAnalyzeResponse response;

  const _QuestionResultsPanel({required this.response});

  @override
  Widget build(BuildContext context) {
    final answers = List<ExamScanAnswer>.from(response.answers)..sort((a, b) => a.questionNumber.compareTo(b.questionNumber));
    return _GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Question results',
            subtitle: 'Objective questions show the detected bubble answer and score. Written questions are shown as manual-review items.',
          ),
          const SizedBox(height: 16),
          if (answers.isEmpty)
            const _Notice(message: 'No question-level correction was returned. Make sure the uploaded PDF is the solved exam generated by Learnova and the QR code is visible.', tone: _NoticeTone.warning)
          else
            Column(
              children: [
                for (var i = 0; i < answers.length; i++) ...[
                  _QuestionResultTile(answer: answers[i]),
                  if (i != answers.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _QuestionResultTile extends StatelessWidget {
  final ExamScanAnswer answer;

  const _QuestionResultTile({required this.answer});

  @override
  Widget build(BuildContext context) {
    final status = _answerStatus(answer);
    final points = answer.pointsEarned ?? answer.aiScore;
    final maxScore = answer.maxScore;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderSoft)),
                child: Text('${answer.questionNumber}', style: AppText.label),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(answer.displayQuestion, style: AppText.label.copyWith(height: 1.35)),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SoftBadge(icon: answer.isWritten ? Icons.edit_note_rounded : Icons.radio_button_checked_rounded, label: answer.typeLabel),
                        _StatusBadge(status: status),
                        if (points != null || maxScore != null) _SoftBadge(icon: Icons.score_outlined, label: '${_formatNumber(points ?? 0)} / ${_formatNumber(maxScore ?? 0)}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final answerCards = [
                _AnswerValueCard(label: 'Student answer', value: answer.displayAnswer),
                _AnswerValueCard(label: 'Correct answer', value: answer.displayCorrectAnswer),
              ];
              if (compact) {
                return Column(children: [answerCards[0], const SizedBox(height: 10), answerCards[1]]);
              }
              return Row(children: [Expanded(child: answerCards[0]), const SizedBox(width: 10), Expanded(child: answerCards[1])]);
            },
          ),
          if (answer.options.isNotEmpty) ...[
            const SizedBox(height: 12),
            _OptionsPreview(answer: answer),
          ],
          if (answer.shouldShowAiFeedback) ...[
            const SizedBox(height: 12),
            _Notice(message: '${answer.aiStatus == 'manual_review' ? 'Review note' : 'AI feedback'}: ${answer.aiFeedback!.trim()}', tone: _NoticeTone.info),
          ],
        ],
      ),
    );
  }
}

class _AnswerValueCard extends StatelessWidget {
  final String label;
  final String value;

  const _AnswerValueCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderSoft)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.mutedSmall.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          SelectableText(value.trim().isEmpty ? '—' : value.trim(), style: AppText.input.copyWith(height: 1.35)),
        ],
      ),
    );
  }
}

class _OptionsPreview extends StatelessWidget {
  final ExamScanAnswer answer;

  const _OptionsPreview({required this.answer});

  @override
  Widget build(BuildContext context) {
    final options = answer.options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Options', style: AppText.mutedSmall.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < options.length && i < 8; i++) _OptionChip(answer: answer, index: i, option: options[i]),
          ],
        ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  final ExamScanAnswer answer;
  final int index;
  final Map<String, dynamic> option;

  const _OptionChip({required this.answer, required this.index, required this.option});

  @override
  Widget build(BuildContext context) {
    final selected = answer.isOptionSelected(index);
    final correct = answer.isOptionCorrect(index);
    final selectedWrong = selected && !correct && answer.normalizedCorrectOptionIndices.isNotEmpty;
    final label = option['label']?.toString().trim().isNotEmpty == true ? option['label'].toString().trim() : String.fromCharCode(65 + index);
    final text = option['text']?.toString().trim() ?? '';
    final color = correct
        ? AppColors.greenText
        : selectedWrong
            ? AppColors.dangerText
            : selected
                ? AppColors.primary
                : AppColors.textMuted;
    final bg = correct
        ? AppColors.greenBg
        : selectedWrong
            ? AppColors.dangerBg
            : selected
                ? AppColors.primarySoft
                : AppColors.cardBg;
    final border = correct
        ? AppColors.greenBorder
        : selectedWrong
            ? AppColors.dangerBorder
            : selected
                ? AppColors.primary.withValues(alpha: 0.30)
                : AppColors.borderSoft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            correct
                ? Icons.check_circle_rounded
                : selectedWrong
                    ? Icons.cancel_rounded
                    : selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text.isEmpty ? label : '$label. $text',
            style: AppText.mutedSmall.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.replaceAll('_', ' ').trim();
    final lower = status.toLowerCase();
    final icon = (lower == 'correct' || lower == 'ready' || lower == 'detected' || lower == 'ai_graded')
        ? Icons.check_circle_outline_rounded
        : (lower == 'wrong' || lower == 'incorrect')
            ? Icons.cancel_outlined
            : Icons.info_outline_rounded;
    return _SoftBadge(icon: icon, label: normalized.isEmpty ? 'review' : normalized);
  }
}

String _answerStatus(ExamScanAnswer answer) {
  if (answer.isCorrect == true) return 'correct';
  if (answer.isCorrect == false) return 'wrong';
  if (answer.isAiPending) return 'ai pending';
  if (answer.hasAiGrade) return 'ai graded';
  return answer.status.isEmpty ? 'needs review' : answer.status;
}

String _formatNumber(double value) {
  if (value.isNaN || value.isInfinite) return '0';
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSoft)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(height: 10),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.sectionTitle.copyWith(fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: AppText.mutedSmall.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}


class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CardTitle({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(13)),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.sectionTitle),
              const SizedBox(height: 3),
              Text(subtitle, style: AppText.mutedSmall.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _GlassCard({required this.child, this.padding = const EdgeInsets.all(22)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [BoxShadow(color: AppColors.shadowSoft, blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: child,
    );
  }
}

class _SoftBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SoftBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.borderSoft)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 15),
          const SizedBox(width: 6),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.mutedSmall.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

enum _NoticeTone { error, warning, info }

class _Notice extends StatelessWidget {
  final String message;
  final _NoticeTone tone;

  const _Notice({required this.message, required this.tone});

  @override
  Widget build(BuildContext context) {
    final colors = _noticeColors(tone);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(colors.icon, color: colors.fg, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: AppText.mutedSmall.copyWith(color: colors.fg, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _NoticeColors {
  final Color bg;
  final Color border;
  final Color fg;
  final IconData icon;

  const _NoticeColors(this.bg, this.border, this.fg, this.icon);
}

_NoticeColors _noticeColors(_NoticeTone tone) {
  return switch (tone) {
    _NoticeTone.error => _NoticeColors(AppColors.dangerBg, AppColors.dangerBorder, AppColors.dangerText, Icons.error_outline_rounded),
    _NoticeTone.warning => _NoticeColors(AppColors.warningSoftBg, AppColors.warningBorder, AppColors.warningText, Icons.warning_amber_rounded),
    _NoticeTone.info => _NoticeColors(AppColors.infoBg, AppColors.infoBorder, AppColors.infoText, Icons.info_outline_rounded),
  };
}
