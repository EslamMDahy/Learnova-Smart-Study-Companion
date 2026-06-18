import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/exam_correction_models.dart';
import '../controllers/exam_correction_controller.dart';

class ExamCorrectionPage extends ConsumerStatefulWidget {
  const ExamCorrectionPage({super.key});

  @override
  ConsumerState<ExamCorrectionPage> createState() => _ExamCorrectionPageState();
}

class _ExamCorrectionPageState extends ConsumerState<ExamCorrectionPage> {
  late final TextEditingController _examIdController;
  late final TextEditingController _courseIdController;
  late final TextEditingController _submitExamIdController;
  late final TextEditingController _submitStudentIdController;
  late final TextEditingController _teacherFeedbackController;

  @override
  void initState() {
    super.initState();
    _examIdController = TextEditingController();
    _courseIdController = TextEditingController();
    _submitExamIdController = TextEditingController();
    _submitStudentIdController = TextEditingController();
    _teacherFeedbackController = TextEditingController();
    Future.microtask(() => ref.read(examCorrectionControllerProvider.notifier).refreshHealth());
  }

  @override
  void dispose() {
    _examIdController.dispose();
    _courseIdController.dispose();
    _submitExamIdController.dispose();
    _submitStudentIdController.dispose();
    _teacherFeedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(examCorrectionControllerProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1180;
        final padding = EdgeInsets.symmetric(
          horizontal: constraints.maxWidth < 680 ? 16 : 32,
          vertical: constraints.maxWidth < 680 ? 18 : 28,
        );

        return SingleChildScrollView(
          padding: padding,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CorrectionHero(),
                  const SizedBox(height: 20),
                  if (compact) ...[
                    _StartScanPanel(
                      examIdController: _examIdController,
                      courseIdController: _courseIdController,
                      onExamIdChanged: controller.setExamIdText,
                      onCourseIdChanged: controller.setCourseIdText,
                    ),
                    const SizedBox(height: 18),
                    const _BackendContractPanel(),
                    const SizedBox(height: 18),
                    _CorrectionWorkspace(
                      submitExamIdController: _submitExamIdController,
                      submitStudentIdController: _submitStudentIdController,
                      teacherFeedbackController: _teacherFeedbackController,
                    ),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 405,
                          child: Column(
                            children: [
                              _StartScanPanel(
                                examIdController: _examIdController,
                                courseIdController: _courseIdController,
                                onExamIdChanged: controller.setExamIdText,
                                onCourseIdChanged: controller.setCourseIdText,
                              ),
                              const SizedBox(height: 18),
                              const _BackendContractPanel(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: _CorrectionWorkspace(
                            submitExamIdController: _submitExamIdController,
                            submitStudentIdController: _submitStudentIdController,
                            teacherFeedbackController: _teacherFeedbackController,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CorrectionHero extends ConsumerWidget {
  const _CorrectionHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(examCorrectionControllerProvider);
    final controller = ref.read(examCorrectionControllerProvider.notifier);

    return _GlassCard(
      padding: const EdgeInsets.all(28),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final title = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroIcon(),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exam Correction Studio', style: AppText.h1.copyWith(fontSize: 30, height: 1.15)),
                    const SizedBox(height: 8),
                    Text(
                      'Upload solved Learnova exam sheets, let the backend read QR metadata, Student ID bubbles, objective answers, and written-answer regions, then review and save the graded attempt.',
                      style: AppText.subtitle.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              _HealthPill(
                loading: state.healthLoading,
                health: state.health,
                error: state.healthError,
                onRefresh: controller.refreshHealth,
              ),
              const _EndpointPill(icon: Icons.qr_code_2_rounded, label: 'QR'),
              const _EndpointPill(icon: Icons.radio_button_checked_rounded, label: 'OMR'),
              const _EndpointPill(icon: Icons.edit_note_rounded, label: 'Written OCR'),
              const _EndpointPill(icon: Icons.auto_awesome_rounded, label: 'AI grading'),
              const _EndpointPill(icon: Icons.task_alt_rounded, label: 'Submit'),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 20), actions],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: title), const SizedBox(width: 24), Flexible(child: Align(alignment: Alignment.topRight, child: actions))],
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
        gradient: LinearGradient(colors: [AppColors.primary, const Color(0xFF22C1FF)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.20), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 30),
    );
  }
}

class _HealthPill extends StatelessWidget {
  final bool loading;
  final OcrHealthResponse? health;
  final String? error;
  final VoidCallback onRefresh;

  const _HealthPill({
    required this.loading,
    required this.health,
    required this.error,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final available = health?.available == true;
    final color = loading
        ? AppColors.primary
        : available
            ? AppColors.successText
            : AppColors.warningText;
    final label = loading
        ? 'Checking OCR'
        : available
            ? '${health!.engine} ready'
            : error != null
                ? 'OCR endpoint offline'
                : 'Check OCR';

    return InkWell(
      onTap: loading ? null : onRefresh,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: color))
            else
              Icon(available ? Icons.cloud_done_rounded : Icons.cloud_off_rounded, color: color, size: 16),
            const SizedBox(width: 7),
            Text(label, style: AppText.mutedSmall.copyWith(color: color, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _EndpointPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EndpointPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 15),
          const SizedBox(width: 6),
          Text(label, style: AppText.mutedSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _StartScanPanel extends ConsumerWidget {
  final TextEditingController examIdController;
  final TextEditingController courseIdController;
  final ValueChanged<String> onExamIdChanged;
  final ValueChanged<String> onCourseIdChanged;

  const _StartScanPanel({
    required this.examIdController,
    required this.courseIdController,
    required this.onExamIdChanged,
    required this.onCourseIdChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(examCorrectionControllerProvider);
    final controller = ref.read(examCorrectionControllerProvider.notifier);

    return _GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            icon: Icons.playlist_add_check_circle_outlined,
            title: 'Start correction run',
            subtitle: 'Files and fallback metadata sent to /ocr/exam-scan/analyze.',
          ),
          const SizedBox(height: 18),
          _StepProgress(currentStep: state.response == null ? (state.files.isEmpty ? 0 : 1) : 2),
          const SizedBox(height: 18),
          _UploadDropZone(
            filesCount: state.files.length,
            loading: state.loading,
            onTap: state.loading ? null : controller.pickFiles,
          ),
          if (state.files.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SelectedFilesList(files: state.files, onRemove: controller.removeFile),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: state.loading ? null : controller.clearFiles,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Clear queue'),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text('Analyzer settings', style: AppText.label),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: state.language,
            decoration: _fieldDecoration('OCR language'),
            items: const [
              DropdownMenuItem(value: 'eng', child: Text('English')),
              DropdownMenuItem(value: 'ara', child: Text('Arabic')),
              DropdownMenuItem(value: 'ara+eng', child: Text('Arabic + English')),
            ],
            onChanged: state.loading ? null : (value) => controller.setLanguage(value ?? 'eng'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: examIdController,
                  onChanged: onExamIdChanged,
                  enabled: !state.loading,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration('Fallback exam ID').copyWith(helperText: 'Used only when QR fails.'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: courseIdController,
                  onChanged: onCourseIdChanged,
                  enabled: !state.loading,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration('Fallback course ID').copyWith(helperText: 'Optional if exam is known.'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DigitSelector(
            value: state.studentIdDigits,
            onChanged: state.loading ? null : controller.setStudentIdDigits,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: state.canAnalyze ? controller.analyzeScan : null,
              icon: state.loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome_motion_rounded),
              label: Text(state.loading ? 'Analyzing with backend...' : 'Analyze solved sheets'),
            ),
          ),
          if (state.error != null && state.error!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _Notice(message: state.error!, tone: _NoticeTone.error),
          ],
          if (state.submitMessage != null && state.submitMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _Notice(message: state.submitMessage!, tone: _NoticeTone.success),
          ],
        ],
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  final int currentStep;

  const _StepProgress({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const labels = ['Upload', 'Analyze', 'Review', 'Save'];
    const icons = [
      Icons.upload_file_rounded,
      Icons.auto_awesome_motion_rounded,
      Icons.fact_check_rounded,
      Icons.verified_rounded,
    ];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(child: _StepNode(label: labels[i], icon: icons[i], active: i <= currentStep)),
          if (i != labels.length - 1)
            Container(width: 16, height: 2, color: i < currentStep ? AppColors.primary : AppColors.borderSoft),
        ],
      ],
    );
  }
}

class _StepNode extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;

  const _StepNode({required this.label, required this.icon, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textMuted;
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: active ? AppColors.primarySoft : AppColors.surfaceBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? AppColors.primary.withOpacity(0.28) : AppColors.borderSoft),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(height: 6),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.mutedSmall.copyWith(color: color, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _UploadDropZone extends StatelessWidget {
  final int filesCount;
  final bool loading;
  final VoidCallback? onTap;

  const _UploadDropZone({required this.filesCount, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withOpacity(0.28)),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.borderSoft)),
              child: Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: 12),
            Text(filesCount == 0 ? 'Choose solved exam scans' : '$filesCount file${filesCount == 1 ? '' : 's'} ready', style: AppText.sectionTitle.copyWith(fontSize: 16)),
            const SizedBox(height: 5),
            Text('PDF, PNG, JPG, WEBP, TIFF, BMP • up to 12 files • 15 MB each', textAlign: TextAlign.center, style: AppText.mutedSmall),
          ],
        ),
      ),
    );
  }
}

class _SelectedFilesList extends StatelessWidget {
  final List<ExamCorrectionUploadFile> files;
  final ValueChanged<int> onRemove;

  const _SelectedFilesList({required this.files, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < files.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == files.length - 1 ? 0 : 8),
            child: _SelectedFileTile(file: files[i], onRemove: () => onRemove(i)),
          ),
      ],
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
            child: Text(file.extension, style: AppText.mutedSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900)),
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

class _DigitSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;

  const _DigitSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderSoft)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Student ID bubble digits', style: AppText.label),
                const SizedBox(height: 3),
                Text('Must match the printed answer sheet.', style: AppText.mutedSmall),
              ],
            ),
          ),
          _RoundIconButton(icon: Icons.remove_rounded, onTap: onChanged == null ? null : () => onChanged!(value - 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('$value', style: AppText.sectionTitle),
          ),
          _RoundIconButton(icon: Icons.add_rounded, onTap: onChanged == null ? null : () => onChanged!(value + 1)),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: AppColors.cardBg, shape: BoxShape.circle, border: Border.all(color: AppColors.borderSoft)),
        child: Icon(icon, color: onTap == null ? AppColors.textMuted : AppColors.primary, size: 18),
      ),
    );
  }
}

class _BackendContractPanel extends ConsumerWidget {
  const _BackendContractPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(examCorrectionControllerProvider);
    final health = state.health;
    final languages = health?.languages.take(4).join(', ');

    return _GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            icon: Icons.api_rounded,
            title: 'Backend contract',
            subtitle: 'This page is wired to the OCR router payloads only.',
          ),
          const SizedBox(height: 16),
          _ContractRow(method: 'GET', path: '/ocr/health', note: health == null ? 'Engine status' : '${health.engine}${health.version == null ? '' : ' ${health.version}'}'),
          const SizedBox(height: 8),
          const _ContractRow(method: 'POST', path: '/ocr/exam-scan/analyze', note: 'multipart: files, lang, exam_id, course_id, student_id_digits'),
          const SizedBox(height: 8),
          const _ContractRow(method: 'AI', path: '/api/v1/courses/grading/evaluate', note: 'essay / short-answer grading when written answers exist'),
          const SizedBox(height: 8),
          const _ContractRow(method: 'POST', path: '/ocr/exam-scan/submit', note: 'scan_id, exam_id, student_id, answers, scores'),
          if (languages != null && languages.isNotEmpty) ...[
            const SizedBox(height: 14),
            _Notice(message: 'Installed OCR languages: $languages${health!.languages.length > 4 ? '...' : ''}', tone: _NoticeTone.info),
          ],
          if (state.healthError != null) ...[
            const SizedBox(height: 14),
            _Notice(message: 'Could not reach OCR health. If this returns 404, the backend OCR router is probably not mounted in main.py.', tone: _NoticeTone.warning),
          ],
        ],
      ),
    );
  }
}

class _ContractRow extends StatelessWidget {
  final String method;
  final String path;
  final String note;

  const _ContractRow({required this.method, required this.path, required this.note});

  @override
  Widget build(BuildContext context) {
    final color = method == 'GET' ? AppColors.successText : method == 'AI' ? AppColors.purpleText : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderSoft)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MiniBadge(label: method, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(path, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label.copyWith(fontSize: 13))),
            ],
          ),
          const SizedBox(height: 6),
          Text(note, style: AppText.mutedSmall),
        ],
      ),
    );
  }
}

class _CorrectionWorkspace extends ConsumerWidget {
  final TextEditingController submitExamIdController;
  final TextEditingController submitStudentIdController;
  final TextEditingController teacherFeedbackController;

  const _CorrectionWorkspace({
    required this.submitExamIdController,
    required this.submitStudentIdController,
    required this.teacherFeedbackController,
  });

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
        _ResultOverview(response: response),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;
            final left = Column(
              children: [
                _IdentityPanel(response: response),
                const SizedBox(height: 18),
                _PagesPanel(pages: response.pages),
                if (response.warnings.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _WarningsPanel(warnings: response.warnings),
                ],
              ],
            );
            final right = Column(
              children: [
                _AnswerReviewPanel(answers: response.answers),
                const SizedBox(height: 18),
                _SubmitPanel(
                  submitExamIdController: submitExamIdController,
                  submitStudentIdController: submitStudentIdController,
                  teacherFeedbackController: teacherFeedbackController,
                ),
              ],
            );

            if (compact) {
              return Column(children: [left, const SizedBox(height: 18), right]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: left),
                const SizedBox(width: 18),
                Expanded(flex: 5, child: right),
              ],
            );
          },
        ),
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
        height: 560,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 4),
              ),
              const SizedBox(height: 22),
              Text('Backend is analyzing the scan', style: AppText.h3),
              const SizedBox(height: 8),
              Text('Reading QR metadata, aligning pages, detecting Student ID bubbles, extracting OMR answers, and preparing written answers.', textAlign: TextAlign.center, style: AppText.sectionSubtitle),
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
        height: 560,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(28)),
                child: Icon(Icons.rule_folder_outlined, color: AppColors.primary, size: 42),
              ),
              const SizedBox(height: 20),
              Text('No correction run yet', style: AppText.h3),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text('Add one or more solved answer sheets, optionally provide fallback IDs, then run the analyzer. The review dashboard will appear here.', textAlign: TextAlign.center, style: AppText.sectionSubtitle),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: const [
                  _EmptyHint(icon: Icons.qr_code_scanner_rounded, label: 'QR metadata'),
                  _EmptyHint(icon: Icons.person_search_rounded, label: 'Student match'),
                  _EmptyHint(icon: Icons.grading_rounded, label: 'Score preview'),
                  _EmptyHint(icon: Icons.verified_rounded, label: 'Save attempt'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EmptyHint({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.borderSoft)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, color: AppColors.primary, size: 16), const SizedBox(width: 7), Text(label, style: AppText.mutedSmall.copyWith(fontWeight: FontWeight.w800))],
      ),
    );
  }
}

class _ResultOverview extends ConsumerWidget {
  final ExamScanAnalyzeResponse response;

  const _ResultOverview({required this.response});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(examCorrectionControllerProvider);
    final percentage = state.effectivePercentage;
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
                        _MiniBadge(label: response.status.replaceAll('_', ' '), color: _statusColor(response.status)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(response.exam.title ?? 'Exam ${response.exam.examId ?? 'not detected'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.sectionSubtitle),
                  ],
                ),
              ),
              Text('Scan ${response.scanId}', style: AppText.mutedSmall),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _OverviewMetric(label: 'Score', value: '${state.effectiveTotalScore.toStringAsFixed(2)} / ${response.gradePreview.totalScore.toStringAsFixed(2)}', icon: Icons.scoreboard_rounded, color: AppColors.primary),
              _OverviewMetric(label: 'Percentage', value: percentage == null ? '—' : '${percentage.toStringAsFixed(1)}%', icon: Icons.percent_rounded, color: AppColors.successText),
              _OverviewMetric(label: 'Detected', value: '${response.gradePreview.detectedQuestions}', icon: Icons.task_alt_rounded, color: AppColors.successText),
              _OverviewMetric(label: 'Needs review', value: '${response.gradePreview.needsReview}', icon: Icons.warning_amber_rounded, color: AppColors.warningText),
              _OverviewMetric(label: 'AI graded', value: '${response.gradePreview.aiGraded}', icon: Icons.auto_awesome_rounded, color: AppColors.purpleText),
              if (response.gradePreview.aiPending > 0)
                _OverviewMetric(label: 'AI pending', value: '${response.gradePreview.aiPending}', icon: Icons.hourglass_top_rounded, color: AppColors.warningText),
              _OverviewMetric(label: 'Pages', value: '${response.pages.length}', icon: Icons.description_outlined, color: AppColors.purpleText),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _OverviewMetric({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.18))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.sectionTitle.copyWith(fontSize: 17)),
          const SizedBox(height: 2),
          Text(label, style: AppText.mutedSmall.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _IdentityPanel extends StatelessWidget {
  final ExamScanAnalyzeResponse response;

  const _IdentityPanel({required this.response});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(icon: Icons.badge_outlined, title: 'Identity & exam match', subtitle: 'Detected from QR, database lookup, and Student ID bubbles.'),
          const SizedBox(height: 16),
          _InfoTile(icon: Icons.person_outline_rounded, label: 'Student', value: response.student.name ?? response.student.studentId ?? 'Unmatched', status: response.student.userId == null ? 'needs review' : 'matched', color: response.student.userId == null ? AppColors.warningText : AppColors.successText),
          const SizedBox(height: 10),
          _InfoTile(icon: Icons.pin_outlined, label: 'Student user ID', value: response.student.userId?.toString() ?? 'Not found', status: '${response.student.confidence.toStringAsFixed(1)}% ID confidence', color: response.student.confidence >= 70 ? AppColors.successText : AppColors.warningText),
          const SizedBox(height: 10),
          _InfoTile(icon: Icons.assignment_outlined, label: 'Exam', value: response.exam.title ?? 'Exam ${response.exam.examId ?? 'not detected'}', status: 'course ${response.exam.courseId ?? '—'}', color: response.exam.examId == null ? AppColors.warningText : AppColors.primary),
          const SizedBox(height: 10),
          _InfoTile(icon: Icons.layers_outlined, label: 'Template version', value: response.exam.templateVersion, status: response.exam.examType ?? 'exam', color: AppColors.purpleText),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String status;
  final Color color;

  const _InfoTile({required this.icon, required this.label, required this.value, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSoft)),
      child: Row(
        children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 21)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.mutedSmall.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _MiniBadge(label: status, color: color),
        ],
      ),
    );
  }
}

class _PagesPanel extends StatelessWidget {
  final List<ExamScanPage> pages;

  const _PagesPanel({required this.pages});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(icon: Icons.document_scanner_outlined, title: 'Page intelligence', subtitle: 'Alignment, QR status, and detected bubble count per page.'),
          const SizedBox(height: 16),
          if (pages.isEmpty)
            _Notice(message: 'No pages were returned from the analyzer.', tone: _NoticeTone.warning)
          else
            Column(
              children: [
                for (var i = 0; i < pages.length; i++) ...[
                  _PageRow(page: pages[i]),
                  if (i != pages.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _PageRow extends StatelessWidget {
  final ExamScanPage page;

  const _PageRow({required this.page});

  @override
  Widget build(BuildContext context) {
    final alignmentOk = page.alignmentStatus == 'aligned' || page.alignmentConfidence >= 70;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSoft)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 38, height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderSoft)), child: Text('${page.pageNumber}', style: AppText.label)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(page.filename, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label),
                    const SizedBox(height: 3),
                    Text('${page.bubbleCount} bubbles • ${page.alignmentConfidence.toStringAsFixed(1)}% alignment', style: AppText.mutedSmall),
                  ],
                ),
              ),
              _MiniBadge(label: page.qrDetected ? 'QR found' : 'No QR', color: page.qrDetected ? AppColors.successText : AppColors.warningText),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: ((page.alignmentConfidence / 100).clamp(0.0, 1.0) as num).toDouble(),
              backgroundColor: AppColors.borderSoft,
              color: alignmentOk ? AppColors.successText : AppColors.warningText,
            ),
          ),
          if (page.warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...page.warnings.map((warning) => Padding(padding: const EdgeInsets.only(top: 4), child: Text('• $warning', style: AppText.mutedSmall.copyWith(color: AppColors.warningText)))),
          ],
        ],
      ),
    );
  }
}

class _WarningsPanel extends StatelessWidget {
  final List<String> warnings;

  const _WarningsPanel({required this.warnings});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(icon: Icons.warning_amber_rounded, title: 'Analyzer warnings', subtitle: 'Review these before saving the attempt.'),
          const SizedBox(height: 14),
          for (final warning in warnings) Padding(padding: const EdgeInsets.only(bottom: 8), child: _Notice(message: warning, tone: _NoticeTone.warning)),
        ],
      ),
    );
  }
}

class _AnswerReviewPanel extends ConsumerWidget {
  final List<ExamScanAnswer> answers;

  const _AnswerReviewPanel({required this.answers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(examCorrectionControllerProvider);
    final controller = ref.read(examCorrectionControllerProvider.notifier);
    final objective = answers.where((answer) => !answer.isWritten).length;
    final written = answers.where((answer) => answer.isWritten).length;

    return _GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: _CardTitle(icon: Icons.fact_check_outlined, title: 'Review answers', subtitle: 'Objective answers are auto-graded. Written/low-confidence answers can be adjusted before submit.')),
              if (state.pointsOverrides.isNotEmpty || state.correctnessOverrides.isNotEmpty)
                TextButton.icon(onPressed: controller.clearReviewOverrides, icon: const Icon(Icons.restart_alt_rounded, size: 18), label: const Text('Reset')),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniBadge(label: '$objective objective', color: AppColors.primary),
              _MiniBadge(label: '$written written', color: AppColors.purpleText),
              _MiniBadge(label: '${answers.where((answer) => answer.needsReview).length} review', color: AppColors.warningText),
            ],
          ),
          const SizedBox(height: 16),
          if (answers.isEmpty)
            _Notice(message: 'No answers were extracted. Check scan quality, QR, and printed answer-sheet template.', tone: _NoticeTone.warning)
          else
            Column(
              children: [
                for (var i = 0; i < answers.length; i++) ...[
                  _AnswerReviewTile(answer: answers[i]),
                  if (i != answers.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _AnswerReviewTile extends ConsumerWidget {
  final ExamScanAnswer answer;

  const _AnswerReviewTile({required this.answer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(examCorrectionControllerProvider);
    final controller = ref.read(examCorrectionControllerProvider.notifier);
    final points = state.effectivePointsFor(answer);
    final correctness = state.effectiveCorrectnessFor(answer);
    final maxScore = answer.maxScore ?? points;
    final color = answer.needsReview ? AppColors.warningText : AppColors.successText;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: answer.needsReview ? AppColors.warningSoftBg.withOpacity(0.55) : AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: answer.needsReview ? AppColors.warningBorder : AppColors.borderSoft),
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
                decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
                child: Icon(answer.isWritten ? Icons.edit_note_rounded : Icons.radio_button_checked_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Q${answer.questionNumber} • ${answer.typeLabel}', style: AppText.label)),
                        _MiniBadge(label: '${answer.confidence.toStringAsFixed(0)}%', color: color),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(answer.displayAnswer, maxLines: answer.isWritten ? 4 : 2, overflow: TextOverflow.ellipsis, style: AppText.input),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniBadge(label: answer.status.replaceAll('_', ' '), color: _statusColor(answer.status)),
                        if (correctness != null) _MiniBadge(label: correctness ? 'correct' : 'incorrect', color: correctness ? AppColors.successText : AppColors.dangerText),
                        if (answer.hasAiGrade) _MiniBadge(label: 'AI graded', color: AppColors.purpleText),
                        if (answer.isAiPending) _MiniBadge(label: 'AI pending', color: AppColors.warningText),
                        if (!answer.hasAiGrade && answer.aiGradingPayload != null) _MiniBadge(label: 'AI ready', color: AppColors.purpleText),
                        if (answer.examQuestionId == null) _MiniBadge(label: 'not bound', color: AppColors.warningText),
                      ],
                    ),
                    if (answer.aiFeedback != null && answer.aiFeedback!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('AI feedback: ${answer.aiFeedback}', maxLines: 3, overflow: TextOverflow.ellipsis, style: AppText.mutedSmall.copyWith(color: AppColors.purpleText, fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderSoft)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Points earned', style: AppText.mutedSmall.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('${points.toStringAsFixed(2)} / ${maxScore.toStringAsFixed(2)}', style: AppText.label),
                    ],
                  ),
                ),
                _RoundIconButton(icon: Icons.remove_rounded, onTap: () => controller.adjustAnswerPoints(answer, -0.5)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(points.toStringAsFixed(points % 1 == 0 ? 0 : 1), style: AppText.sectionTitle.copyWith(fontSize: 16)),
                ),
                _RoundIconButton(icon: Icons.add_rounded, onTap: () => controller.adjustAnswerPoints(answer, 0.5)),
                const SizedBox(width: 10),
                _ToggleChip(label: 'Correct', selected: correctness == true, color: AppColors.successText, onTap: () => controller.setAnswerCorrectness(answer, true)),
                const SizedBox(width: 8),
                _ToggleChip(label: 'Wrong', selected: correctness == false, color: AppColors.dangerText, onTap: () => controller.setAnswerCorrectness(answer, false)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleChip({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : AppColors.surfaceBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? color.withOpacity(0.35) : AppColors.borderSoft),
        ),
        child: Text(label, style: AppText.mutedSmall.copyWith(color: selected ? color : AppColors.textMuted, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _SubmitPanel extends ConsumerWidget {
  final TextEditingController submitExamIdController;
  final TextEditingController submitStudentIdController;
  final TextEditingController teacherFeedbackController;

  const _SubmitPanel({
    required this.submitExamIdController,
    required this.submitStudentIdController,
    required this.teacherFeedbackController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(examCorrectionControllerProvider);
    final controller = ref.read(examCorrectionControllerProvider.notifier);
    final response = state.response;
    final percentage = state.effectivePercentage;

    return _GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(icon: Icons.verified_user_outlined, title: 'Save graded attempt', subtitle: 'POST /ocr/exam-scan/submit after review.'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.primary.withOpacity(0.18))),
            child: Row(
              children: [
                Icon(Icons.scoreboard_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Final score', style: AppText.mutedSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text('${state.effectiveTotalScore.toStringAsFixed(2)} / ${(response?.gradePreview.totalScore ?? 0).toStringAsFixed(2)}${percentage == null ? '' : ' • ${percentage.toStringAsFixed(1)}%'}', style: AppText.h3.copyWith(fontSize: 19)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: submitExamIdController,
                  keyboardType: TextInputType.number,
                  onChanged: controller.setSubmitExamIdText,
                  decoration: _fieldDecoration('Override exam ID').copyWith(
                    helperText: response?.exam.examId == null ? 'Required when QR did not resolve exam.' : 'Detected: ${response!.exam.examId}',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: submitStudentIdController,
                  keyboardType: TextInputType.number,
                  onChanged: controller.setSubmitStudentIdText,
                  decoration: _fieldDecoration('Override student user ID').copyWith(
                    helperText: response?.student.userId == null ? 'Required when Student ID did not match a user.' : 'Detected: ${response!.student.userId}',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: teacherFeedbackController,
            minLines: 3,
            maxLines: 5,
            onChanged: controller.setTeacherFeedback,
            decoration: _fieldDecoration('Teacher feedback for the attempt').copyWith(hintText: 'Optional feedback saved on the student exam attempt'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: state.canSubmit ? controller.submitCorrection : null,
              icon: state.submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.verified_rounded),
              label: Text(state.submitting ? 'Saving graded attempt...' : 'Save graded attempt'),
            ),
          ),
          if (!state.canSubmit) ...[
            const SizedBox(height: 12),
            _Notice(
              message: 'Save requires a resolved exam ID, a matched or overridden student user ID, and at least one answer bound to an exam question.',
              tone: _NoticeTone.info,
            ),
          ],
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

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withOpacity(0.24))),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.mutedSmall.copyWith(color: color, fontWeight: FontWeight.w900)),
    );
  }
}

enum _NoticeTone { error, warning, success, info }

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
    _NoticeTone.success => _NoticeColors(AppColors.successBg, AppColors.greenBorder, AppColors.successText, Icons.check_circle_outline_rounded),
    _NoticeTone.info => _NoticeColors(AppColors.infoBg, AppColors.infoBorder, AppColors.infoText, Icons.info_outline_rounded),
  };
}

Color _statusColor(String status) {
  final value = status.toLowerCase();
  if (value == 'ready' || value == 'detected' || value == 'ai_ready' || value == 'ai_graded') return AppColors.successText;
  if (value == 'needs_review' || value == 'pending' || value == 'sent') return AppColors.warningText;
  if (value == 'failed' || value == 'error') return AppColors.dangerText;
  return AppColors.primary;
}

InputDecoration _fieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.fieldBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.borderSoft)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.borderSoft)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary, width: 1.4)),
  );
}
