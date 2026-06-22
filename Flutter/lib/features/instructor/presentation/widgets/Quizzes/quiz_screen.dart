import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:learnova/core/network/error_mapper.dart';
import 'package:learnova/core/routing/routes.dart';
import 'package:learnova/core/storage/published_exams_cache.dart';
import 'package:learnova/core/theme/app_theme.dart';
import 'package:learnova/core/ui/toast.dart';
import 'package:learnova/core/utils/file_download_stub.dart'
    if (dart.library.html) 'package:learnova/core/utils/file_download_web.dart';
import 'package:learnova/features/instructor/data/courses_models.dart';
import 'package:learnova/features/instructor/data/courses_providers.dart';
import 'package:learnova/features/instructor/data/exam_models.dart';
import 'package:learnova/features/instructor/data/question_models.dart';
import 'package:learnova/features/instructor/data/questions_api.dart';
import 'package:learnova/features/instructor/data/modules_materials_providers.dart';
import 'package:learnova/features/instructor/presentation/controllers/selected_course_provider.dart';
import 'package:learnova/features/instructor/presentation/course_route_identity.dart';
import 'package:learnova/features/instructor/presentation/widgets/course_tabs/question_bank_tab.dart';

class InstructorQuizzesScreen extends ConsumerStatefulWidget {
  final int? courseId;
  final String? courseTitle;

  const InstructorQuizzesScreen({super.key, this.courseId, this.courseTitle});

  @override
  ConsumerState<InstructorQuizzesScreen> createState() =>
      _InstructorQuizzesScreenState();
}

class _InstructorQuizzesScreenState extends ConsumerState<InstructorQuizzesScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<_CourseExamGroup> _groups = const [];
  int? _activeCourseId;
  _ExamStatusFilter _statusFilter = _ExamStatusFilter.all;

  ExamModel? _selectedExam;
  MyCourseItem? _selectedExamCourse;
  ExamDetailsModel? _selectedDetails;
  bool _detailsLoading = false;
  bool _publishing = false;
  bool _exportingExamPdf = false;
  String? _detailsError;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllCourseExams());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllCourseExams() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final coursesResponse = await ref.read(coursesApiProvider).myCourses();
      final courses = [...coursesResponse.items]
        ..sort((a, b) => a.safeTitle.toLowerCase().compareTo(b.safeTitle.toLowerCase()));

      final groups = await Future.wait<_CourseExamGroup>(
        courses.map((course) async {
          try {
            final response = await ref.read(examsApiProvider).listExams(courseId: course.id);
            final exams = [...response.exams]
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            _cachePublishedExamsForStudents(course, exams);
            return _CourseExamGroup(course: course, exams: exams);
          } catch (e) {
            return _CourseExamGroup(
              course: course,
              exams: const [],
              error: mapApiFailure(e).message,
            );
          }
        }),
      );

      if (!mounted) return;
      final preferredCourseId = widget.courseId;
      final activeCourseId = preferredCourseId != null && groups.any((g) => g.course.id == preferredCourseId)
          ? preferredCourseId
          : groups.isNotEmpty
              ? groups.first.course.id
              : null;

      setState(() {
        _groups = groups;
        _activeCourseId = activeCourseId;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = mapApiFailure(e).message;
        _groups = const [];
        _activeCourseId = null;
        _loading = false;
      });
    }
  }

  void _cachePublishedExamsForStudents(
    MyCourseItem course,
    List<ExamModel> exams,
  ) {
    PublishedExamsCache.saveInstructorExams(
      courseId: course.id,
      courseTitle: course.safeTitle,
      courseCode: course.safeCourseCode,
      exams: exams.map(_examToPublishedCacheJson).toList(growable: false),
    );
  }

  Map<String, dynamic> _examToPublishedCacheJson(ExamModel exam) {
    return <String, dynamic>{
      'id': exam.id,
      'course_id': exam.courseId,
      'title': exam.title,
      'description': exam.description,
      'exam_type': exam.examType,
      'duration_minutes': exam.durationMinutes,
      'max_attempts': exam.maxAttempts,
      'passing_score': exam.passingScore,
      'total_questions': exam.totalQuestions,
      'total_score': exam.totalScore,
      'is_published': exam.isPublished,
      'available_from': exam.availableFrom?.toUtc().toIso8601String(),
      'available_to': exam.availableTo?.toUtc().toIso8601String(),
      'is_available': true,
    }..removeWhere((_, value) => value == null);
  }

  List<_CourseExamGroup> get _filteredGroups {
    final query = _searchController.text.trim().toLowerCase();
    final hasQuery = query.isNotEmpty;

    final filtered = <_CourseExamGroup>[];
    for (final group in _groups) {
      final course = group.course;
      final courseMatches = hasQuery &&
          (course.safeTitle.toLowerCase().contains(query) ||
              course.safeCourseCode.toLowerCase().contains(query) ||
              (course.category ?? '').toLowerCase().contains(query));

      final exams = group.exams.where((exam) {
        final statusMatches = _statusFilter == _ExamStatusFilter.all ||
            (_statusFilter == _ExamStatusFilter.published && exam.isPublished) ||
            (_statusFilter == _ExamStatusFilter.draft && !exam.isPublished);
        final examMatches = !hasQuery ||
            exam.title.toLowerCase().contains(query) ||
            (exam.description ?? '').toLowerCase().contains(query) ||
            exam.examType.toLowerCase().contains(query);
        return statusMatches && (!hasQuery || courseMatches || examMatches);
      }).toList();

      final includeCourse = !hasQuery && _statusFilter == _ExamStatusFilter.all
          ? true
          : courseMatches || exams.isNotEmpty;
      if (includeCourse) filtered.add(group.copyWith(exams: exams));
    }
    return filtered;
  }

  _CourseExamGroup? get _activeGroup {
    final visible = _filteredGroups;
    if (visible.isEmpty) return null;
    final activeId = _activeCourseId;
    if (activeId != null) {
      for (final group in visible) {
        if (group.course.id == activeId) return group;
      }
    }
    return visible.first;
  }

  _ExamStudioStats get _stats => _ExamStudioStats.fromGroups(_groups);

  @override
  Widget build(BuildContext context) {
    if (_selectedExam != null || _detailsLoading) {
      return _ExamDetailsWorkspace(
        exam: _selectedDetails?.exam ?? _selectedExam,
        course: _selectedExamCourse,
        details: _selectedDetails,
        loading: _detailsLoading,
        error: _detailsError,
        publishing: _publishing,
        exportingPdf: _exportingExamPdf,
        onBack: _backToExamStudio,
        onRetry: () {
          final exam = _selectedExam;
          final course = _selectedExamCourse;
          if (exam != null && course != null) {
            unawaited(_openExamDetails(course: course, exam: exam));
          }
        },
        onPublish: _selectedExamCourse == null || _selectedExam == null
            ? null
            : () => _publishExam(course: _selectedExamCourse!, exam: _selectedDetails?.exam ?? _selectedExam!),
        onExportPdf: _selectedExamCourse == null || _selectedExam == null
            ? null
            : () => _exportExamPdf(course: _selectedExamCourse!, exam: _selectedDetails?.exam ?? _selectedExam!),
        onOpenQuestionBank: _selectedExamCourse == null
            ? null
            : () => _goToQuestionBank(_selectedExamCourse!),
        onAddSection: _selectedExamCourse == null || _selectedExam == null
            ? null
            : () => _showCreateSectionDialog(course: _selectedExamCourse!, exam: _selectedDetails?.exam ?? _selectedExam!),
        onAddQuestionsToSection: _selectedExamCourse == null || _selectedExam == null
            ? null
            : (section) => _showAddQuestionsToSectionDialog(
                  course: _selectedExamCourse!,
                  exam: _selectedDetails?.exam ?? _selectedExam!,
                  section: section,
                ),
      );
    }

    final visibleGroups = _filteredGroups;
    final activeGroup = _activeGroup;
    final createExamCourse = activeGroup?.course ?? (_groups.isNotEmpty ? _groups.first.course : null);

    return Container(
      color: AppColors.pageBg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ExamStudioHero(
                    stats: _stats,
                    onRefresh: _loadAllCourseExams,
                    refreshing: _loading,
                    onCreateExam: createExamCourse == null
                        ? null
                        : () => _openCreateExamLauncher(createExamCourse),
                  ),
                  const SizedBox(height: 18),
                  _ExamStudioBody(
                    loading: _loading,
                    error: _error,
                    groups: visibleGroups,
                    allGroups: _groups,
                    activeGroup: activeGroup,
                    statusFilter: _statusFilter,
                    searchController: _searchController,
                    hasActiveFilters: _searchController.text.trim().isNotEmpty || _statusFilter != _ExamStatusFilter.all,
                    onStatusChanged: (value) => setState(() => _statusFilter = value),
                    onClearFilters: _clearFilters,
                    onRetry: _loadAllCourseExams,
                    onSelectCourse: (courseId) => setState(() => _activeCourseId = courseId),
                    onOpenExam: (course, exam) => _openExamDetails(course: course, exam: exam),
                    onPublishExam: (course, exam) => _publishExam(course: course, exam: exam),
                    onExportExam: (course, exam) => _exportExamPdf(course: course, exam: exam),
                    onOpenQuestionBank: _openCreateExamLauncher,
                    onOpenTemplates: _goToTemplates,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openExamDetails({required MyCourseItem course, required ExamModel exam}) async {
    setState(() {
      _selectedExam = exam;
      _selectedExamCourse = course;
      _selectedDetails = null;
      _detailsLoading = true;
      _detailsError = null;
    });

    try {
      final details = await ref.read(examsApiProvider).getExam(
            courseId: course.id,
            examId: exam.id,
          );
      if (!mounted) return;
      setState(() {
        _selectedDetails = details;
        _selectedExam = details.exam;
        _detailsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailsError = mapApiFailure(e).message;
        _detailsLoading = false;
      });
    }
  }

  Future<void> _publishExam({required MyCourseItem course, required ExamModel exam}) async {
    if (_publishing || exam.isPublished) return;
    setState(() => _publishing = true);
    try {
      final api = ref.read(examsApiProvider);
      final publishableExam = await _ensureExamHasBackendAvailability(
        course: course,
        exam: exam,
      );
      final response = await api.publishExam(
            courseId: course.id,
            examId: publishableExam.id,
          );
      if (!mounted) return;

      final updated = _copyExamAfterPublish(publishableExam, response);
      setState(() {
        _groups = _replaceExamInGroups(_groups, course.id, updated);
        if (_selectedExam?.id == exam.id) _selectedExam = updated;
        if (_selectedDetails?.exam.id == exam.id) {
          _selectedDetails = ExamDetailsModel(
            exam: updated,
            sections: _selectedDetails!.sections,
            questions: _selectedDetails!.questions,
          );
        }
      });
      unawaited(api.listExams(courseId: course.id).catchError(
            (_) => ExamListResponse(courseId: course.id, total: 0, exams: const []),
          ));

      AppToast.success(
        context,
        title: 'Exam published',
        message: response.message.trim().isEmpty
            ? 'Students can now see this exam when backend availability rules allow it.'
            : response.message,
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        title: 'Publish failed',
        message: mapApiFailure(e).message,
      );
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<ExamModel> _ensureExamHasBackendAvailability({
    required MyCourseItem course,
    required ExamModel exam,
  }) async {
    if (exam.availableFrom != null && exam.availableTo != null) {
      return exam;
    }

    final now = DateTime.now().toUtc();
    final start = (exam.availableFrom ?? now.subtract(const Duration(minutes: 5))).toUtc();
    var end = (exam.availableTo ?? now.add(const Duration(days: 3650))).toUtc();
    if (!end.isAfter(start)) {
      end = start.add(const Duration(days: 3650));
    }

    return ref.read(examsApiProvider).updateExam(
          courseId: course.id,
          examId: exam.id,
          payload: {
            'available_from': start.toIso8601String(),
            'available_to': end.toIso8601String(),
          },
        );
  }

  Future<void> _exportExamPdf({required MyCourseItem course, required ExamModel exam}) async {
    if (_exportingExamPdf) return;

    final options = await _showExamPdfExportOptionsDialog();
    if (options == null || !mounted) return;

    setState(() => _exportingExamPdf = true);
    try {
      final export = await ref.read(examsApiProvider).exportExamPdf(
            courseId: course.id,
            examId: exam.id,
            includeLearnovaLogo: options.includeLearnovaLogo,
            includeCourseTitle: options.includeCourseTitle,
            includeCourseCode: options.includeCourseCode,
            includeExamMetadata: options.includeExamMetadata,
            includeInstructions: options.includeInstructions,
            includeSectionDescriptions: options.includeSectionDescriptions,
            includePoints: options.includePoints,
            includeStudentInfoFields: options.includeStudentInfoFields,
            includeAnswerSpace: options.includeAnswerSpace,
            includeOcrSupport: options.includeOcrSupport,
            shuffleQuestions: options.shuffleQuestions,
            shuffleOptions: options.shuffleOptions,
          );
      if (!mounted) return;
      downloadBytesFile(
        filename: export.filename,
        bytes: export.bytes,
        mimeType: 'application/pdf',
      );
      AppToast.success(
        context,
        title: 'PDF exported',
        message: 'Downloaded the backend-generated exam paper.',
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        title: 'Export failed',
        message: mapApiFailure(e).message,
      );
    } finally {
      if (mounted) setState(() => _exportingExamPdf = false);
    }
  }

  Future<_ExamPdfExportOptions?> _showExamPdfExportOptionsDialog() {
    return showDialog<_ExamPdfExportOptions>(
      context: context,
      builder: (_) => const _ExamPdfExportOptionsDialog(),
    );
  }

  Future<void> _openCreateExamLauncher(MyCourseItem course) async {
    final mode = await showDialog<_ExamCreationMode>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _ExamCreationLauncherDialog(course: course),
    );
    if (mode == null || !mounted) return;

    if (mode == _ExamCreationMode.manual) {
      await _createManualDraftExam(course);
      return;
    }

    await showCourseCreateExamDialog(
      context: context,
      ref: ref,
      course: course,
      onChanged: () {
        unawaited(_loadAllCourseExams());
      },
    );
    if (mounted) unawaited(_loadAllCourseExams());
  }

  Future<void> _createManualDraftExam(MyCourseItem course) async {
    final draft = await showDialog<_ManualExamDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ManualExamDraftDialog(course: course),
    );
    if (draft == null || !mounted) return;

    try {
      final exam = await ref.read(examsApiProvider).createExam(
            courseId: course.id,
            payload: ExamCreatePayload(
              title: draft.title,
              description: draft.description,
              instructions: draft.instructions,
              examType: draft.examType,
              durationMinutes: draft.durationMinutes,
              maxAttempts: draft.maxAttempts,
              passingScore: draft.passingScore,
              shuffleQuestions: draft.shuffleQuestions,
              shuffleOptions: draft.shuffleOptions,
              availableFrom: draft.availableFrom,
              availableTo: draft.availableTo,
            ),
          );
      if (!mounted) return;
      await _loadAllCourseExams();
      if (!mounted) return;
      AppToast.success(
        context,
        title: 'Manual exam draft created',
        message: 'Open the draft, add sections, then attach questions manually.',
      );
      await _openExamDetails(course: course, exam: exam);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        title: 'Could not create exam',
        message: mapApiFailure(e).message,
      );
    }
  }

  Future<void> _reloadSelectedExamDetails() async {
    final course = _selectedExamCourse;
    final exam = _selectedDetails?.exam ?? _selectedExam;
    if (course == null || exam == null) return;
    await _openExamDetails(course: course, exam: exam);
    unawaited(_loadAllCourseExams());
  }

  Future<void> _showCreateSectionDialog({required MyCourseItem course, required ExamModel exam}) async {
    if (exam.isPublished) {
      AppToast.error(context, title: 'Exam is published', message: 'Unpublished draft exams can be edited manually.');
      return;
    }
    final draft = await showDialog<_ManualSectionDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ManualSectionDialog(),
    );
    if (draft == null || !mounted) return;

    try {
      await ref.read(examsApiProvider).createSection(
            courseId: course.id,
            examId: exam.id,
            payload: ExamSectionCreatePayload(
              title: draft.title,
              description: draft.description,
              questionType: draft.questionType,
              timeLimitMinutes: draft.timeLimitMinutes,
              mustComplete: draft.mustComplete,
            ),
          );
      if (!mounted) return;
      AppToast.success(context, title: 'Section added', message: 'Now add questions to this section.');
      await _reloadSelectedExamDetails();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, title: 'Could not add section', message: mapApiFailure(e).message);
    }
  }

  Future<void> _showAddQuestionsToSectionDialog({
    required MyCourseItem course,
    required ExamModel exam,
    required ExamSectionDetailsModel section,
  }) async {
    if (exam.isPublished) {
      AppToast.error(context, title: 'Exam is published', message: 'Unpublished draft exams can be edited manually.');
      return;
    }

    try {
      final response = await ref.read(questionsApiProvider).getCourseQuestions(courseId: course.id);
      if (!mounted) return;
      final existingQuestionIds = (_selectedDetails?.questions ?? const <ExamQuestionDetail>[])
          .map((item) => item.question.remoteId)
          .whereType<int>()
          .toSet();
      final neededType = _questionTypeFromBackend(section.questionType);
      final candidates = response.questions.where((question) {
        final id = question.remoteId;
        if (id == null || existingQuestionIds.contains(id)) return false;
        if (neededType != null && question.type != neededType) return false;
        return true;
      }).toList()
        ..sort((a, b) {
          final typeCmp = a.typeLabel.compareTo(b.typeLabel);
          if (typeCmp != 0) return typeCmp;
          return a.text.compareTo(b.text);
        });

      final selectedIds = await showDialog<Set<int>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _AddQuestionsToSectionDialog(section: section, questions: candidates),
      );
      if (selectedIds == null || selectedIds.isEmpty || !mounted) return;

      await ref.read(examsApiProvider).addQuestions(
            courseId: course.id,
            examId: exam.id,
            sectionId: section.id,
            questionIds: selectedIds.toList()..sort(),
          );
      if (!mounted) return;
      AppToast.success(context, title: 'Questions attached', message: '${selectedIds.length} question(s) added to ${section.title}.');
      await _reloadSelectedExamDetails();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, title: 'Could not add questions', message: mapApiFailure(e).message);
    }
  }

  void _goToQuestionBank(MyCourseItem course) {
    SelectedCourseCache.set(course);
    context.go(Routes.courseQuestionBank(buildCourseRouteSlug(course)));
  }

  void _goToTemplates(MyCourseItem course) {
    SelectedCourseCache.set(course);
    context.go(Routes.courseTemplates(buildCourseRouteSlug(course)));
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() => _statusFilter = _ExamStatusFilter.all);
  }

  void _backToExamStudio() {
    setState(() {
      _selectedExam = null;
      _selectedExamCourse = null;
      _selectedDetails = null;
      _detailsLoading = false;
      _publishing = false;
      _exportingExamPdf = false;
      _detailsError = null;
    });
  }
}

class _ExamPdfExportOptions {
  final bool includeLearnovaLogo;
  final bool includeCourseTitle;
  final bool includeCourseCode;
  final bool includeExamMetadata;
  final bool includeInstructions;
  final bool includeSectionDescriptions;
  final bool includePoints;
  final bool includeStudentInfoFields;
  final bool includeAnswerSpace;
  final bool includeOcrSupport;
  final bool shuffleQuestions;
  final bool shuffleOptions;

  const _ExamPdfExportOptions({
    this.includeLearnovaLogo = true,
    this.includeCourseTitle = true,
    this.includeCourseCode = false,
    this.includeExamMetadata = true,
    this.includeInstructions = true,
    this.includeSectionDescriptions = true,
    this.includePoints = true,
    this.includeStudentInfoFields = true,
    this.includeAnswerSpace = true,
    this.includeOcrSupport = false,
    this.shuffleQuestions = false,
    this.shuffleOptions = false,
  });
}

class _ExamPdfExportOptionsDialog extends StatefulWidget {
  const _ExamPdfExportOptionsDialog();

  @override
  State<_ExamPdfExportOptionsDialog> createState() => _ExamPdfExportOptionsDialogState();
}

class _ExamPdfExportOptionsDialogState extends State<_ExamPdfExportOptionsDialog> {
  bool _includeLearnovaLogo = true;
  bool _includeCourseTitle = true;
  bool _includeCourseCode = false;
  bool _includeExamMetadata = true;
  bool _includeInstructions = true;
  bool _includeSectionDescriptions = true;
  bool _includePoints = true;
  bool _includeStudentInfoFields = true;
  bool _includeAnswerSpace = true;
  bool _includeOcrSupport = false;
  bool _shuffleQuestions = false;
  bool _shuffleOptions = false;

  void _setOcrSupport(bool value) {
    setState(() {
      _includeOcrSupport = value;
      if (value) {
        _includeStudentInfoFields = true;
        _includeAnswerSpace = true;
        _shuffleQuestions = false;
        _shuffleOptions = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 18, 16),
              child: Row(
                children: [
                  _IconBox(icon: Icons.picture_as_pdf_outlined, color: AppColors.primary, size: 46),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Export exam paper', style: _textStyle(color: AppColors.textTitle, size: 21, weight: FontWeight.w900)),
                        const SizedBox(height: 5),
                        Text('Choose the print layout and the fields rendered by the backend PDF endpoint.', style: _textStyle(color: AppColors.textMuted, size: 12.5, weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ExportSectionLabel('Print mode'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ExportModeCard(
                            selected: !_includeOcrSupport,
                            icon: Icons.description_outlined,
                            title: 'Standard PDF',
                            subtitle: 'Clean paper copy for manual marking or normal distribution.',
                            onTap: () => _setOcrSupport(false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ExportModeCard(
                            selected: _includeOcrSupport,
                            icon: Icons.document_scanner_outlined,
                            title: 'OCR-ready print',
                            subtitle: 'Adds QR, student ID bubbles, answer bubbles and OCR boxes.',
                            onTap: () => _setOcrSupport(true),
                          ),
                        ),
                      ],
                    ),
                    if (_includeOcrSupport) ...[
                      const SizedBox(height: 12),
                      const _ExportNotice(
                        icon: Icons.verified_outlined,
                        title: 'OCR scan compatible',
                        message: 'This layout is prepared for the /ocr/exam-scan/analyze pipeline after students submit scanned papers. Question and option shuffling are locked off so detected answers stay aligned with the backend exam order.',
                      ),
                    ],
                    const SizedBox(height: 18),
                    _ExportSectionLabel('Header and exam details'),
                    const SizedBox(height: 10),
                    _ExportToggle(
                      title: 'Learnova logo',
                      subtitle: 'Show platform branding at the top of the paper.',
                      value: _includeLearnovaLogo,
                      onChanged: (value) => setState(() => _includeLearnovaLogo = value),
                    ),
                    _ExportToggle(
                      title: 'Course title',
                      subtitle: 'Print the course name in the exam header.',
                      value: _includeCourseTitle,
                      onChanged: (value) => setState(() => _includeCourseTitle = value),
                    ),
                    _ExportToggle(
                      title: 'Course code',
                      subtitle: 'Useful when the same exam title exists across courses.',
                      value: _includeCourseCode,
                      onChanged: (value) => setState(() => _includeCourseCode = value),
                    ),
                    _ExportToggle(
                      title: 'Exam metadata',
                      subtitle: 'Includes type, duration, total questions and total score.',
                      value: _includeExamMetadata,
                      onChanged: (value) => setState(() => _includeExamMetadata = value),
                    ),
                    _ExportToggle(
                      title: 'Instructions',
                      subtitle: 'Render the saved student-facing instructions.',
                      value: _includeInstructions,
                      onChanged: (value) => setState(() => _includeInstructions = value),
                    ),
                    const SizedBox(height: 10),
                    _ExportSectionLabel('Question paper content'),
                    const SizedBox(height: 10),
                    _ExportToggle(
                      title: 'Section descriptions',
                      subtitle: 'Show each section description above its questions.',
                      value: _includeSectionDescriptions,
                      onChanged: (value) => setState(() => _includeSectionDescriptions = value),
                    ),
                    _ExportToggle(
                      title: 'Question points',
                      subtitle: 'Print the score value next to each question.',
                      value: _includePoints,
                      onChanged: (value) => setState(() => _includePoints = value),
                    ),
                    _ExportToggle(
                      title: 'Student info fields',
                      subtitle: _includeOcrSupport ? 'OCR mode uses the dedicated name/date area and student ID bubble grid.' : 'Adds name/date fields for manual paper submissions.',
                      value: _includeStudentInfoFields,
                      enabled: !_includeOcrSupport,
                      onChanged: (value) => setState(() => _includeStudentInfoFields = value),
                    ),
                    _ExportToggle(
                      title: 'Answer space',
                      subtitle: _includeOcrSupport ? 'Required for OCR answer boxes and written-answer detection.' : 'Adds blank space for written answers.',
                      value: _includeAnswerSpace,
                      enabled: !_includeOcrSupport,
                      onChanged: (value) => setState(() => _includeAnswerSpace = value),
                    ),
                    const SizedBox(height: 10),
                    _ExportSectionLabel('Randomization'),
                    const SizedBox(height: 10),
                    _ExportToggle(
                      title: 'Shuffle questions in PDF',
                      subtitle: _includeOcrSupport ? 'Disabled for OCR so scanned answers match the backend question order.' : 'Override the saved exam setting for this export only.',
                      value: _shuffleQuestions,
                      enabled: !_includeOcrSupport,
                      onChanged: (value) => setState(() => _shuffleQuestions = value),
                    ),
                    _ExportToggle(
                      title: 'Shuffle answer options in PDF',
                      subtitle: _includeOcrSupport ? 'Disabled for OCR so selected bubbles map to the saved options.' : 'Override the saved exam setting for this export only.',
                      value: _shuffleOptions,
                      enabled: !_includeOcrSupport,
                      onChanged: (value) => setState(() => _shuffleOptions = value),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(
                        _ExamPdfExportOptions(
                          includeLearnovaLogo: _includeLearnovaLogo,
                          includeCourseTitle: _includeCourseTitle,
                          includeCourseCode: _includeCourseCode,
                          includeExamMetadata: _includeExamMetadata,
                          includeInstructions: _includeInstructions,
                          includeSectionDescriptions: _includeSectionDescriptions,
                          includePoints: _includePoints,
                          includeStudentInfoFields: _includeStudentInfoFields,
                          includeAnswerSpace: _includeAnswerSpace,
                          includeOcrSupport: _includeOcrSupport,
                          shuffleQuestions: _includeOcrSupport ? false : _shuffleQuestions,
                          shuffleOptions: _includeOcrSupport ? false : _shuffleOptions,
                        ),
                      );
                    },
                    icon: Icon(_includeOcrSupport ? Icons.document_scanner_outlined : Icons.download_rounded, size: 18),
                    label: Text(_includeOcrSupport ? 'Export OCR PDF' : 'Export PDF'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportSectionLabel extends StatelessWidget {
  final String label;

  const _ExportSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: _textStyle(
        color: AppColors.textMuted,
        size: 11,
        weight: FontWeight.w900,
      ).copyWith(letterSpacing: .8),
    );
  }
}

class _ExportModeCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.primary : AppColors.border;
    final bg = selected ? AppColors.primarySoft : AppColors.surfaceBg;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? AppColors.primary : AppColors.border),
              ),
              child: Icon(icon, color: selected ? Colors.white : AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _textStyle(color: AppColors.textTitle, size: 13.5, weight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: _textStyle(color: AppColors.textMuted, size: 11.5, weight: FontWeight.w700, height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _ExportNotice({required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.infoText, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _textStyle(color: AppColors.infoText, size: 12.5, weight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(message, style: _textStyle(color: AppColors.infoText, size: 11.5, weight: FontWeight.w700, height: 1.42)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportToggle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ExportToggle({
    required this.title,
    this.subtitle,
    required this.value,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitleColor = enabled ? AppColors.textTitle : AppColors.textHint;
    final effectiveSubtitleColor = enabled ? AppColors.textMuted : AppColors.textHint;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : .78,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: enabled ? AppColors.surfaceBg : AppColors.fieldDisabledBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _textStyle(color: effectiveTitleColor, size: 13, weight: FontWeight.w900)),
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!, style: _textStyle(color: effectiveSubtitleColor, size: 11.3, weight: FontWeight.w700, height: 1.35)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 14),
            Switch(value: value, onChanged: enabled ? onChanged : null),
          ],
        ),
      ),
    );
  }
}

enum _ExamStatusFilter { all, published, draft }

extension _ExamStatusFilterX on _ExamStatusFilter {
  String get label {
    switch (this) {
      case _ExamStatusFilter.all:
        return 'All';
      case _ExamStatusFilter.published:
        return 'Published';
      case _ExamStatusFilter.draft:
        return 'Draft';
    }
  }
}

class _CourseExamGroup {
  final MyCourseItem course;
  final List<ExamModel> exams;
  final String? error;

  const _CourseExamGroup({required this.course, required this.exams, this.error});

  int get published => exams.where((exam) => exam.isPublished).length;
  int get draft => exams.length - published;
  int get totalQuestions => exams.fold<int>(0, (sum, exam) => sum + exam.totalQuestions);
  double get totalScore => exams.fold<double>(0, (sum, exam) => sum + exam.totalScore);
  DateTime get lastUpdated {
    if (exams.isEmpty) return course.updatedAt;
    return exams.map((e) => e.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  _CourseExamGroup copyWith({List<ExamModel>? exams, String? error}) {
    return _CourseExamGroup(
      course: course,
      exams: exams ?? this.exams,
      error: error ?? this.error,
    );
  }
}


enum _ExamCreationMode { manual, automatic }

class _ExamCreationLauncherDialog extends StatelessWidget {
  final MyCourseItem course;

  const _ExamCreationLauncherDialog({required this.course});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _IconBox(icon: Icons.add_task_rounded, color: AppColors.primary, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create exam', style: _textStyle(color: AppColors.textTitle, size: 22, weight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(course.safeTitle, style: _textStyle(color: AppColors.textMuted, size: 12.5, weight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 620;
                  final cards = [
                    _CreateModeCard(
                      icon: Icons.edit_note_rounded,
                      title: 'Manual draft',
                      subtitle: 'Create an empty exam, then add sections and attach questions section-by-section.',
                      buttonLabel: 'Start manually',
                      onTap: () => Navigator.of(context).pop(_ExamCreationMode.manual),
                    ),
                    _CreateModeCard(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Generate from template',
                      subtitle: 'Pick a template, topics/subtopics, and type the Easy / Medium / Hard mix at generation time.',
                      buttonLabel: 'Generate',
                      onTap: () => Navigator.of(context).pop(_ExamCreationMode.automatic),
                    ),
                  ];
                  if (stacked) {
                    return Column(children: [cards[0], const SizedBox(height: 12), cards[1]]);
                  }
                  return Row(children: [Expanded(child: cards[0]), const SizedBox(width: 14), Expanded(child: cards[1])]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const _CreateModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconBox(icon: icon, color: AppColors.primary, size: 46),
            const SizedBox(height: 14),
            Text(title, style: _textStyle(color: AppColors.textTitle, size: 16, weight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(subtitle, style: _textStyle(color: AppColors.textMuted, size: 12.2, weight: FontWeight.w700, height: 1.45)),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: onTap, child: Text(buttonLabel))),
          ],
        ),
      ),
    );
  }
}

class _ManualExamDraft {
  final String title;
  final String? description;
  final String? instructions;
  final String examType;
  final int? durationMinutes;
  final int maxAttempts;
  final double? passingScore;
  final bool shuffleQuestions;
  final bool shuffleOptions;
  final DateTime? availableFrom;
  final DateTime? availableTo;

  const _ManualExamDraft({
    required this.title,
    this.description,
    this.instructions,
    required this.examType,
    this.durationMinutes,
    required this.maxAttempts,
    this.passingScore,
    required this.shuffleQuestions,
    required this.shuffleOptions,
    this.availableFrom,
    this.availableTo,
  });
}

class _ManualExamDraftDialog extends StatefulWidget {
  final MyCourseItem course;

  const _ManualExamDraftDialog({required this.course});

  @override
  State<_ManualExamDraftDialog> createState() => _ManualExamDraftDialogState();
}

class _ManualExamDraftDialogState extends State<_ManualExamDraftDialog> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '60');
  final _attemptsCtrl = TextEditingController(text: '1');
  final _passingCtrl = TextEditingController(text: '60');
  String _examType = 'quiz';
  bool _shuffleQuestions = true;
  bool _shuffleOptions = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = '${widget.course.safeTitle} manual exam';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _instructionsCtrl.dispose();
    _durationCtrl.dispose();
    _attemptsCtrl.dispose();
    _passingCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Exam title is required.');
      return;
    }
    final duration = int.tryParse(_durationCtrl.text.trim());
    final attempts = int.tryParse(_attemptsCtrl.text.trim());
    final passing = double.tryParse(_passingCtrl.text.trim());
    Navigator.of(context).pop(_ManualExamDraft(
      title: title,
      description: _emptyToNull(_descriptionCtrl.text),
      instructions: _emptyToNull(_instructionsCtrl.text),
      examType: _examType,
      durationMinutes: duration != null && duration > 0 ? duration : null,
      maxAttempts: attempts != null && attempts > 0 ? attempts : 1,
      passingScore: passing != null && passing >= 0 ? passing : null,
      shuffleQuestions: _shuffleQuestions,
      shuffleOptions: _shuffleOptions,
    ));
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 18, 16),
              child: Row(
                children: [
                  _IconBox(icon: Icons.edit_note_rounded, color: AppColors.primary, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Manual exam draft', style: _textStyle(color: AppColors.textTitle, size: 21, weight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('Create the exam shell first. Sections and questions are added after creation.', style: _textStyle(color: AppColors.textMuted, size: 12.3, weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[_InlineError(message: _error!), const SizedBox(height: 12)],
                    _DialogTextField(label: 'Exam title', controller: _titleCtrl),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _DialogTextField(label: 'Duration minutes', controller: _durationCtrl, numeric: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _DialogTextField(label: 'Max attempts', controller: _attemptsCtrl, numeric: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _DialogTextField(label: 'Passing score', controller: _passingCtrl, numeric: true)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _examType,
                      decoration: _dialogInputDecoration('Exam type'),
                      items: const [
                        DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                        DropdownMenuItem(value: 'midterm', child: Text('Midterm')),
                        DropdownMenuItem(value: 'final', child: Text('Final')),
                        DropdownMenuItem(value: 'assignment', child: Text('Assignment')),
                      ],
                      onChanged: (value) => setState(() => _examType = value ?? 'quiz'),
                    ),
                    const SizedBox(height: 12),
                    _DialogTextField(label: 'Description', controller: _descriptionCtrl, maxLines: 2),
                    const SizedBox(height: 12),
                    _DialogTextField(label: 'Instructions', controller: _instructionsCtrl, maxLines: 3),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      value: _shuffleQuestions,
                      onChanged: (value) => setState(() => _shuffleQuestions = value ?? true),
                      title: const Text('Shuffle questions'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: _shuffleOptions,
                      onChanged: (value) => setState(() => _shuffleOptions = value ?? false),
                      title: const Text('Shuffle answer options'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
              child: Row(
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const Spacer(),
                  FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.arrow_forward_rounded, size: 18), label: const Text('Create draft')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualSectionDraft {
  final String title;
  final String? description;
  final String questionType;
  final int? timeLimitMinutes;
  final bool mustComplete;

  const _ManualSectionDraft({
    required this.title,
    this.description,
    required this.questionType,
    this.timeLimitMinutes,
    required this.mustComplete,
  });
}

class _ManualSectionDialog extends StatefulWidget {
  const _ManualSectionDialog();

  @override
  State<_ManualSectionDialog> createState() => _ManualSectionDialogState();
}

class _ManualSectionDialogState extends State<_ManualSectionDialog> {
  final _titleCtrl = TextEditingController(text: 'Multiple Choice Section');
  final _descriptionCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  String _questionType = 'multiple_choice';
  bool _mustComplete = true;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Section title is required.');
      return;
    }
    final time = int.tryParse(_timeCtrl.text.trim());
    Navigator.of(context).pop(_ManualSectionDraft(
      title: title,
      description: _emptyToNull(_descriptionCtrl.text),
      questionType: _questionType,
      timeLimitMinutes: time != null && time > 0 ? time : null,
      mustComplete: _mustComplete,
    ));
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _IconBox(icon: Icons.view_agenda_outlined, color: AppColors.primary, size: 44),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Add exam section', style: _textStyle(color: AppColors.textTitle, size: 19, weight: FontWeight.w900))),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[_InlineError(message: _error!), const SizedBox(height: 12)],
              _DialogTextField(label: 'Section title', controller: _titleCtrl),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _questionType,
                decoration: _dialogInputDecoration('Question type'),
                items: const [
                  DropdownMenuItem(value: 'multiple_choice', child: Text('Multiple Choice')),
                  DropdownMenuItem(value: 'true_false', child: Text('True / False')),
                  DropdownMenuItem(value: 'short_answer', child: Text('Short Answer')),
                  DropdownMenuItem(value: 'essay', child: Text('Essay')),
                  DropdownMenuItem(value: 'multi_select', child: Text('Multi Select')),
                ],
                onChanged: (value) {
                  setState(() {
                    _questionType = value ?? 'multiple_choice';
                    _titleCtrl.text = '${_backendQuestionTypeLabel(_questionType)} Section';
                  });
                },
              ),
              const SizedBox(height: 12),
              _DialogTextField(label: 'Description', controller: _descriptionCtrl, maxLines: 2),
              const SizedBox(height: 12),
              _DialogTextField(label: 'Time limit minutes (optional)', controller: _timeCtrl, numeric: true),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _mustComplete,
                onChanged: (value) => setState(() => _mustComplete = value ?? true),
                title: const Text('Students must complete this section'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const Spacer(),
                  FilledButton(onPressed: _submit, child: const Text('Add section')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddQuestionsToSectionDialog extends StatefulWidget {
  final ExamSectionDetailsModel section;
  final List<QuestionModel> questions;

  const _AddQuestionsToSectionDialog({required this.section, required this.questions});

  @override
  State<_AddQuestionsToSectionDialog> createState() => _AddQuestionsToSectionDialogState();
}

class _AddQuestionsToSectionDialogState extends State<_AddQuestionsToSectionDialog> {
  final _searchCtrl = TextEditingController();
  final Set<int> _selectedIds = <int>{};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<QuestionModel> get _filtered {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return widget.questions;
    return widget.questions.where((question) {
      return question.text.toLowerCase().contains(query) ||
          (question.topicName ?? '').toLowerCase().contains(query) ||
          question.difficultyLabel.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 16, 14),
              child: Row(
                children: [
                  _IconBox(icon: Icons.playlist_add_rounded, color: AppColors.primary, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add questions', style: _textStyle(color: AppColors.textTitle, size: 19, weight: FontWeight.w900)),
                        const SizedBox(height: 3),
                        Text('${widget.section.title} • ${_backendQuestionTypeLabel(widget.section.questionType)}', style: _textStyle(color: AppColors.textMuted, size: 12, weight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: _dialogInputDecoration('Search saved questions'),
              ),
            ),
            Divider(height: 1, color: AppColors.border),
            Expanded(
              child: filtered.isEmpty
                  ? _StateMessage(
                      icon: Icons.search_off_rounded,
                      title: 'No matching questions',
                      message: widget.questions.isEmpty
                          ? 'There are no unused saved questions matching this section type.'
                          : 'No question matches the current search.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final question = filtered[index];
                        final id = question.remoteId;
                        final selected = id != null && _selectedIds.contains(id);
                        return CheckboxListTile(
                          value: selected,
                          onChanged: id == null
                              ? null
                              : (value) => setState(() {
                                    if (value ?? false) {
                                      _selectedIds.add(id);
                                    } else {
                                      _selectedIds.remove(id);
                                    }
                                  }),
                          title: Text(question.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: _textStyle(color: AppColors.textTitle, size: 13, weight: FontWeight.w800)),
                          subtitle: Text('${question.difficultyLabel} • ${question.topicName ?? question.contextLabel}', style: _textStyle(color: AppColors.textMuted, size: 11.5, weight: FontWeight.w700)),
                          controlAffinity: ListTileControlAffinity.leading,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: selected ? AppColors.primary : AppColors.border)),
                          tileColor: selected ? AppColors.primarySoft : AppColors.cardBg,
                        );
                      },
                    ),
            ),
            Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
              child: Row(
                children: [
                  Text('${_selectedIds.length} selected', style: _textStyle(color: AppColors.textMuted, size: 12, weight: FontWeight.w800)),
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 10),
                  FilledButton(onPressed: _selectedIds.isEmpty ? null : () => Navigator.of(context).pop(Set<int>.from(_selectedIds)), child: const Text('Add selected')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool numeric;
  final int maxLines;

  const _DialogTextField({required this.label, required this.controller, this.numeric = false, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: _dialogInputDecoration(label),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Row(
        children: [
           Icon(Icons.error_outline_rounded, color: AppColors.dangerText, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: _textStyle(color: AppColors.dangerText, size: 12, weight: FontWeight.w800))),
        ],
      ),
    );
  }
}

InputDecoration _dialogInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.surfaceBg,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
  );
}

QuestionType? _questionTypeFromBackend(String raw) {
  switch (raw.trim()) {
    case 'multiple_choice':
      return QuestionType.multipleChoice;
    case 'true_false':
      return QuestionType.trueFalse;
    case 'short_answer':
      return QuestionType.shortAnswer;
    case 'essay':
      return QuestionType.essay;
    case 'multi_select':
      return QuestionType.multiSelect;
    case 'fill_in_the_blank':
    case 'fill_in_blank':
      return QuestionType.fillInTheBlank;
    case 'numeric':
      return QuestionType.numeric;
    case 'code':
      return QuestionType.code;
    default:
      return null;
  }
}

String _backendQuestionTypeLabel(String raw) {
  switch (raw.trim()) {
    case 'multiple_choice':
      return 'Multiple Choice';
    case 'true_false':
      return 'True / False';
    case 'short_answer':
      return 'Short Answer';
    case 'essay':
      return 'Essay';
    case 'multi_select':
      return 'Multi Select';
    default:
      return _titleCase(raw.replaceAll('_', ' '));
  }
}

class _ExamStudioStats {
  final int courses;
  final int exams;
  final int published;
  final int draft;
  final int questions;

  const _ExamStudioStats({
    required this.courses,
    required this.exams,
    required this.published,
    required this.draft,
    required this.questions,
  });

  factory _ExamStudioStats.fromGroups(List<_CourseExamGroup> groups) {
    final exams = groups.fold<int>(0, (sum, group) => sum + group.exams.length);
    final published = groups.fold<int>(0, (sum, group) => sum + group.published);
    final questions = groups.fold<int>(0, (sum, group) => sum + group.totalQuestions);
    return _ExamStudioStats(
      courses: groups.length,
      exams: exams,
      published: published,
      draft: exams - published,
      questions: questions,
    );
  }
}

class _ExamStudioHero extends StatelessWidget {
  final _ExamStudioStats stats;
  final bool refreshing;
  final VoidCallback onRefresh;
  final VoidCallback? onCreateExam;

  const _ExamStudioHero({
    required this.stats,
    required this.refreshing,
    required this.onRefresh,
    required this.onCreateExam,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3EA8), Color(0xFF137FEC), Color(0xFF20C6D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.34), blurRadius: 22, offset: const Offset(0, 12))],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            child: const Icon(Icons.assignment_turned_in_outlined, color: Colors.white, size: 29),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Exams', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.7)),
                const SizedBox(height: 6),
                Text(
                  'Manage generated exams, publish them to students, and export backend-ready paper PDFs.',
                  style: TextStyle(color: Colors.white.withOpacity(0.86), fontSize: 13, fontWeight: FontWeight.w700, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroMetric(value: '${stats.courses}', label: 'Courses'),
              _HeroMetric(value: '${stats.exams}', label: 'Exams'),
              _HeroMetric(value: '${stats.published}', label: 'Published'),
              _HeroMetric(value: '${stats.questions}', label: 'Questions'),
            ],
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: refreshing ? null : onRefresh,
                icon: refreshing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: Text(refreshing ? 'Loading...' : 'Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white.withOpacity(0.55),
                  side: BorderSide(color: Colors.white.withOpacity(0.35)),
                  backgroundColor: Colors.white.withOpacity(0.08),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: onCreateExam,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create exam'),
                style: FilledButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white.withOpacity(0.25),
                  disabledForegroundColor: Colors.white.withOpacity(0.65),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String value;
  final String label;

  const _HeroMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.76), fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ExamStudioBody extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<_CourseExamGroup> groups;
  final List<_CourseExamGroup> allGroups;
  final _CourseExamGroup? activeGroup;
  final _ExamStatusFilter statusFilter;
  final TextEditingController searchController;
  final bool hasActiveFilters;
  final ValueChanged<_ExamStatusFilter> onStatusChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectCourse;
  final void Function(MyCourseItem course, ExamModel exam) onOpenExam;
  final void Function(MyCourseItem course, ExamModel exam) onPublishExam;
  final void Function(MyCourseItem course, ExamModel exam) onExportExam;
  final ValueChanged<MyCourseItem> onOpenQuestionBank;
  final ValueChanged<MyCourseItem> onOpenTemplates;

  const _ExamStudioBody({
    required this.loading,
    required this.error,
    required this.groups,
    required this.allGroups,
    required this.activeGroup,
    required this.statusFilter,
    required this.searchController,
    required this.hasActiveFilters,
    required this.onStatusChanged,
    required this.onClearFilters,
    required this.onRetry,
    required this.onSelectCourse,
    required this.onOpenExam,
    required this.onPublishExam,
    required this.onExportExam,
    required this.onOpenQuestionBank,
    required this.onOpenTemplates,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _StudioShell(
        child: SizedBox(height: 560, child: Center(child: CircularProgressIndicator())),
      );
    }
    if (error != null) {
      return _StudioShell(
        child: _StateMessage(
          icon: Icons.error_outline_rounded,
          title: 'Could not load exams',
          message: error!,
          actionLabel: 'Retry',
          onAction: onRetry,
        ),
      );
    }
    final noMatches = groups.isEmpty && hasActiveFilters && allGroups.isNotEmpty;
    if (groups.isEmpty && !noMatches) {
      return _StudioShell(
        child: _StateMessage(
          icon: Icons.school_outlined,
          title: 'No courses found',
          message: 'Create a course first. Exams are scoped per course in the backend.',
          actionLabel: 'Refresh',
          onAction: onRetry,
        ),
      );
    }

    final group = noMatches ? allGroups.first : activeGroup ?? groups.first;
    final navigatorGroups = noMatches ? const <_CourseExamGroup>[] : groups;
    final board = noMatches
        ? _NoMatchingExamsPanel(onClearFilters: onClearFilters)
        : _CourseExamBoard(
            group: group,
            onOpenExam: onOpenExam,
            onPublishExam: onPublishExam,
            onExportExam: onExportExam,
            onOpenQuestionBank: onOpenQuestionBank,
            onOpenTemplates: onOpenTemplates,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;
        if (compact) {
          return Column(
            children: [
              _CourseNavigatorCard(
                groups: navigatorGroups,
                totalCount: noMatches ? allGroups.length : groups.length,
                activeCourseId: group.course.id,
                statusFilter: statusFilter,
                searchController: searchController,
                emptyMessage: noMatches ? 'No courses or exams match the current filters.' : null,
                onStatusChanged: onStatusChanged,
                onSelectCourse: onSelectCourse,
              ),
              const SizedBox(height: 16),
              board,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 420,
              child: _CourseNavigatorCard(
                groups: navigatorGroups,
                totalCount: noMatches ? allGroups.length : groups.length,
                activeCourseId: group.course.id,
                statusFilter: statusFilter,
                searchController: searchController,
                emptyMessage: noMatches ? 'No courses or exams match the current filters.' : null,
                onStatusChanged: onStatusChanged,
                onSelectCourse: onSelectCourse,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(child: board),
          ],
        );
      },
    );
  }
}

class _NoMatchingExamsPanel extends StatelessWidget {
  final VoidCallback onClearFilters;

  const _NoMatchingExamsPanel({required this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return _StudioShell(
      child: SizedBox(
        height: 360,
        child: _StateMessage(
          icon: Icons.search_rounded,
          title: 'No matching exams',
          message: 'No course or exam matches the current search/status filters. Clear filters or edit the search box on the left.',
          actionLabel: 'Clear filters',
          onAction: onClearFilters,
        ),
      ),
    );
  }
}

class _InlineEmptyMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InlineEmptyMessage({required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBox(icon: icon, color: AppColors.textMuted, size: 36),
          const SizedBox(height: 12),
          Text(title, style: _textStyle(color: AppColors.textTitle, size: 13, weight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(message, style: _textStyle(color: AppColors.textMuted, size: 12, weight: FontWeight.w700, height: 1.4)),
        ],
      ),
    );
  }
}

class _StudioShell extends StatelessWidget {
  final Widget child;

  const _StudioShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.shadowThin, blurRadius: 24, offset: const Offset(0, 14))],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _CourseNavigatorCard extends StatelessWidget {
  final List<_CourseExamGroup> groups;
  final int totalCount;
  final int activeCourseId;
  final _ExamStatusFilter statusFilter;
  final TextEditingController searchController;
  final String? emptyMessage;
  final ValueChanged<_ExamStatusFilter> onStatusChanged;
  final ValueChanged<int> onSelectCourse;

  const _CourseNavigatorCard({
    required this.groups,
    required this.totalCount,
    required this.activeCourseId,
    required this.statusFilter,
    required this.searchController,
    this.emptyMessage,
    required this.onStatusChanged,
    required this.onSelectCourse,
  });

  @override
  Widget build(BuildContext context) {
    return _StudioShell(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconBox(icon: Icons.folder_open_outlined, color: AppColors.primary, size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Course library', style: _textStyle(color: AppColors.textTitle, size: 16, weight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text('Backend exams grouped by course', style: _textStyle(color: AppColors.textMuted, size: 11, weight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    _MiniBadge(label: '$totalCount', color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 16),
                _SearchField(controller: searchController),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _ExamStatusFilter.values.map((filter) {
                    return _FilterChipButton(
                      label: filter.label,
                      selected: filter == statusFilter,
                      onTap: () => onStatusChanged(filter),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          if (groups.isEmpty && emptyMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
              child: _InlineEmptyMessage(
                icon: Icons.manage_search_rounded,
                title: 'No matches',
                message: emptyMessage!,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final group = groups[index];
                return _CourseTile(
                  group: group,
                  active: group.course.id == activeCourseId,
                  onTap: () => onSelectCourse(group.course.id),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search course or exam...',
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: controller.clear,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
        filled: true,
        fillColor: AppColors.surfaceBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      style: _textStyle(color: AppColors.textTitle, size: 13, weight: FontWeight.w700),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: _textStyle(
            color: selected ? Colors.white : AppColors.textMuted,
            size: 12,
            weight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  final _CourseExamGroup group;
  final bool active;
  final VoidCallback onTap;

  const _CourseTile({required this.group, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final course = group.course;
    final statusColor = course.isPrivate ? AppColors.warningText : AppColors.successText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? AppColors.selectedBg : AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.primary.withOpacity(0.42) : AppColors.border),
          boxShadow: active ? [BoxShadow(color: AppColors.shadowThin, blurRadius: 14, offset: const Offset(0, 8))] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _IconBox(icon: Icons.school_outlined, color: active ? AppColors.primary : AppColors.textMuted, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.safeTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: _textStyle(color: AppColors.textTitle, size: 13, weight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text(course.safeCourseCode, maxLines: 1, overflow: TextOverflow.ellipsis, style: _textStyle(color: AppColors.textMuted, size: 11, weight: FontWeight.w800)),
                    ],
                  ),
                ),
                _StatusDot(color: group.error == null ? statusColor : AppColors.errorDot),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _CompactStat(value: '${group.exams.length}', label: 'Exams'),
                const SizedBox(width: 8),
                _CompactStat(value: '${group.published}', label: 'Live'),
                const SizedBox(width: 8),
                _CompactStat(value: '${group.draft}', label: 'Draft'),
              ],
            ),
            if (group.error != null) ...[
              const SizedBox(height: 10),
              Text(group.error!, maxLines: 2, overflow: TextOverflow.ellipsis, style: _textStyle(color: AppColors.dangerText, size: 11, weight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String value;
  final String label;

  const _CompactStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: _textStyle(color: AppColors.textTitle, size: 13, weight: FontWeight.w900)),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _textStyle(color: AppColors.textHint, size: 10, weight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _CourseExamBoard extends StatelessWidget {
  final _CourseExamGroup group;
  final void Function(MyCourseItem course, ExamModel exam) onOpenExam;
  final void Function(MyCourseItem course, ExamModel exam) onPublishExam;
  final void Function(MyCourseItem course, ExamModel exam) onExportExam;
  final ValueChanged<MyCourseItem> onOpenQuestionBank;
  final ValueChanged<MyCourseItem> onOpenTemplates;

  const _CourseExamBoard({
    required this.group,
    required this.onOpenExam,
    required this.onPublishExam,
    required this.onExportExam,
    required this.onOpenQuestionBank,
    required this.onOpenTemplates,
  });

  @override
  Widget build(BuildContext context) {
    final course = group.course;
    return _StudioShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CourseBoardHeader(
            group: group,
            onOpenTemplates: () => onOpenTemplates(course),
          ),
          if (group.error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: _StateMessage(icon: Icons.error_outline_rounded, title: 'Could not load course exams', message: group.error!),
            )
          else if (group.exams.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 88, horizontal: 24),
              child: _EmptyCourseExams(course: course, onOpenQuestionBank: () => onOpenQuestionBank(course), onOpenTemplates: () => onOpenTemplates(course)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              itemCount: group.exams.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final exam = group.exams[index];
                return _ExamListCard(
                  index: index + 1,
                  course: course,
                  exam: exam,
                  onOpen: () => onOpenExam(course, exam),
                  onPublish: exam.isPublished ? null : () => onPublishExam(course, exam),
                  onExport: () => onExportExam(course, exam),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CourseBoardHeader extends StatelessWidget {
  final _CourseExamGroup group;
  final VoidCallback onOpenTemplates;

  const _CourseBoardHeader({required this.group, required this.onOpenTemplates});

  @override
  Widget build(BuildContext context) {
    final course = group.course;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
        gradient: LinearGradient(colors: [AppColors.surfaceAlt, AppColors.surfaceBg], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Row(
        children: [
          _IconBox(icon: Icons.menu_book_outlined, color: AppColors.primary, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(course.safeTitle, style: _textStyle(color: AppColors.textTitle, size: 21, weight: FontWeight.w900, letterSpacing: -0.3)),
                    _MiniBadge(label: course.isPrivate ? 'Private' : 'Public', color: course.isPrivate ? AppColors.warningText : AppColors.successText),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${course.safeCourseCode} • ${group.exams.length} exams • ${group.published} published • ${group.draft} draft',
                  style: _textStyle(color: AppColors.textMuted, size: 12, weight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onOpenTemplates,
            icon: const Icon(Icons.view_module_outlined, size: 18),
            label: const Text('Templates'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCourseExams extends StatelessWidget {
  final MyCourseItem course;
  final VoidCallback onOpenQuestionBank;
  final VoidCallback onOpenTemplates;

  const _EmptyCourseExams({required this.course, required this.onOpenQuestionBank, required this.onOpenTemplates});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBox(icon: Icons.add_task_rounded, color: AppColors.primary, size: 62),
              const SizedBox(height: 18),
              Text('No exams for ${course.safeTitle} yet', textAlign: TextAlign.center, style: _textStyle(color: AppColors.textTitle, size: 20, weight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                'Create a manual draft, or generate one automatically from a saved template. The backend stores exams per course.',
                textAlign: TextAlign.center,
                style: _textStyle(color: AppColors.textMuted, size: 13, weight: FontWeight.w700, height: 1.45),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(onPressed: onOpenQuestionBank, icon: const Icon(Icons.add_rounded), label: const Text('Create exam')),
                  OutlinedButton.icon(onPressed: onOpenTemplates, icon: const Icon(Icons.view_module_outlined), label: const Text('Open templates')),
                ],
              ),
            ],
          ),
        ),
    );
  }
}

class _ExamListCard extends StatelessWidget {
  final int index;
  final MyCourseItem course;
  final ExamModel exam;
  final VoidCallback onOpen;
  final VoidCallback? onPublish;
  final VoidCallback onExport;

  const _ExamListCard({
    required this.index,
    required this.course,
    required this.exam,
    required this.onOpen,
    required this.onPublish,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = exam.isPublished ? AppColors.successText : AppColors.warningText;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: AppColors.shadowThin, blurRadius: 16, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.badgeBlueBorder)),
              child: Text(index.toString().padLeft(2, '0'), style: _textStyle(color: AppColors.primary, size: 13, weight: FontWeight.w900)),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(exam.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _textStyle(color: AppColors.textTitle, size: 15, weight: FontWeight.w900))),
                      const SizedBox(width: 8),
                      _MiniBadge(label: exam.isPublished ? 'Published' : 'Draft', color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MetaPill(icon: Icons.category_outlined, label: _titleCase(exam.examType)),
                      _MetaPill(icon: Icons.quiz_outlined, label: '${exam.totalQuestions} questions'),
                      _MetaPill(icon: Icons.stacked_line_chart_rounded, label: '${_points(exam.totalScore)} points'),
                      _MetaPill(icon: Icons.timer_outlined, label: _duration(exam.durationMinutes)),
                      _MetaPill(icon: Icons.repeat_rounded, label: '${exam.maxAttempts} attempt${exam.maxAttempts == 1 ? '' : 's'}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 96,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Updated', style: _textStyle(color: AppColors.textHint, size: 10, weight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(_formatDate(exam.updatedAt), style: _textStyle(color: AppColors.textMuted, size: 12, weight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            PopupMenuButton<String>(
              tooltip: 'Exam actions',
              onSelected: (value) {
                switch (value) {
                  case 'open':
                    onOpen();
                    return;
                  case 'publish':
                    onPublish?.call();
                    return;
                  case 'export':
                    onExport();
                    return;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'open', child: _MenuItem(icon: Icons.open_in_new_rounded, label: 'Open details')),
                if (!exam.isPublished)
                  const PopupMenuItem(value: 'publish', child: _MenuItem(icon: Icons.publish_rounded, label: 'Publish to students')),
                const PopupMenuItem(value: 'export', child: _MenuItem(icon: Icons.picture_as_pdf_outlined, label: 'Export PDF')),
              ],
            ),
            const SizedBox(width: 6),
            FilledButton(
              onPressed: onOpen,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              child: const Text('Open'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}

class _ExamDetailsWorkspace extends StatelessWidget {
  final ExamModel? exam;
  final MyCourseItem? course;
  final ExamDetailsModel? details;
  final bool loading;
  final String? error;
  final bool publishing;
  final bool exportingPdf;
  final VoidCallback onBack;
  final VoidCallback onRetry;
  final VoidCallback? onPublish;
  final VoidCallback? onExportPdf;
  final VoidCallback? onOpenQuestionBank;
  final VoidCallback? onAddSection;
  final ValueChanged<ExamSectionDetailsModel>? onAddQuestionsToSection;

  const _ExamDetailsWorkspace({
    required this.exam,
    required this.course,
    required this.details,
    required this.loading,
    required this.error,
    required this.publishing,
    required this.exportingPdf,
    required this.onBack,
    required this.onRetry,
    required this.onPublish,
    required this.onExportPdf,
    required this.onOpenQuestionBank,
    required this.onAddSection,
    required this.onAddQuestionsToSection,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedExam = details?.exam ?? exam;
    final questions = details?.questions ?? const <ExamQuestionDetail>[];
    final sections = details?.sections ?? const <ExamSectionDetailsModel>[];
    final questionsCount = questions.isNotEmpty ? questions.length : resolvedExam?.totalQuestions ?? 0;

    return Container(
      color: AppColors.pageBg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ExamDetailsHero(
                    exam: resolvedExam,
                    course: course,
                    questionsCount: questionsCount,
                    publishing: publishing,
                    exportingPdf: exportingPdf,
                    onBack: onBack,
                    onPublish: resolvedExam == null || resolvedExam.isPublished || publishing ? null : onPublish,
                    onExportPdf: resolvedExam == null || exportingPdf ? null : onExportPdf,
                    onOpenQuestionBank: onOpenQuestionBank,
                  ),
                  const SizedBox(height: 18),
                  if (loading)
                    const _StudioShell(child: SizedBox(height: 520, child: Center(child: CircularProgressIndicator())))
                  else if (error != null)
                    _StudioShell(child: _StateMessage(icon: Icons.error_outline_rounded, title: 'Could not load exam details', message: error!, actionLabel: 'Retry', onAction: onRetry))
                  else if (resolvedExam == null)
                    const _StudioShell(child: _StateMessage(icon: Icons.assignment_outlined, title: 'No exam selected', message: 'Go back and choose an exam from the studio.'))
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 980;
                        if (compact) {
                          return Column(
                            children: [
                              _ExamSnapshotGrid(exam: resolvedExam, questionsCount: questionsCount),
                              const SizedBox(height: 18),
                              _QuestionPaperCard(
                                sections: sections,
                                questions: questions,
                                onAddSection: onAddSection,
                                onAddQuestionsToSection: onAddQuestionsToSection,
                              ),
                              const SizedBox(height: 18),
                              _ExamBackendSettingsCard(exam: resolvedExam, course: course),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: Column(
                                children: [
                                  _ExamSnapshotGrid(exam: resolvedExam, questionsCount: questionsCount),
                                  const SizedBox(height: 18),
                                  _QuestionPaperCard(
                                sections: sections,
                                questions: questions,
                                onAddSection: onAddSection,
                                onAddQuestionsToSection: onAddQuestionsToSection,
                              ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),
                            SizedBox(
                              width: 380,
                              child: _ExamBackendSettingsCard(exam: resolvedExam, course: course),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamDetailsHero extends StatelessWidget {
  final ExamModel? exam;
  final MyCourseItem? course;
  final int questionsCount;
  final bool publishing;
  final bool exportingPdf;
  final VoidCallback onBack;
  final VoidCallback? onPublish;
  final VoidCallback? onExportPdf;
  final VoidCallback? onOpenQuestionBank;

  const _ExamDetailsHero({
    required this.exam,
    required this.course,
    required this.questionsCount,
    required this.publishing,
    required this.exportingPdf,
    required this.onBack,
    required this.onPublish,
    required this.onExportPdf,
    required this.onOpenQuestionBank,
  });

  @override
  Widget build(BuildContext context) {
    final title = exam?.title.trim().isNotEmpty ?? false ? exam!.title : 'Exam details';
    final statusColor = exam?.isPublished ?? false ? AppColors.successText : AppColors.warningText;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.shadowThin, blurRadius: 24, offset: const Offset(0, 14))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back to Exams'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.primarySoft,
                  side: BorderSide(color: AppColors.primary.withOpacity(0.22)),
                ),
              ),
              const Spacer(),
              if (onOpenQuestionBank != null)
                OutlinedButton.icon(
                  onPressed: onOpenQuestionBank,
                  icon: const Icon(Icons.quiz_outlined, size: 18),
                  label: const Text('Question Bank'),
                ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onExportPdf,
                icon: exportingPdf
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: Text(exportingPdf ? 'Exporting...' : 'Export PDF'),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: onPublish,
                icon: publishing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon((exam?.isPublished ?? false) ? Icons.verified_rounded : Icons.publish_rounded, size: 18),
                label: Text((exam?.isPublished ?? false) ? 'Published' : publishing ? 'Publishing...' : 'Publish'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _IconBox(icon: Icons.assignment_turned_in_outlined, color: AppColors.primary, size: 58),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MiniBadge(label: exam?.isPublished ?? false ? 'Published' : 'Draft', color: statusColor),
                        _MiniBadge(label: _titleCase(exam?.examType ?? 'exam'), color: AppColors.primary),
                        if (course != null) _MiniBadge(label: course!.safeCourseCode, color: AppColors.textMuted),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: _textStyle(color: AppColors.textTitle, size: 30, weight: FontWeight.w900, letterSpacing: -0.7, height: 1.12)),
                    const SizedBox(height: 8),
                    Text(
                      '${course?.safeTitle ?? 'Course'} • $questionsCount questions • Updated ${exam == null ? '-' : _formatDate(exam!.updatedAt)}',
                      style: _textStyle(color: AppColors.textMuted, size: 13, weight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExamSnapshotGrid extends StatelessWidget {
  final ExamModel exam;
  final int questionsCount;

  const _ExamSnapshotGrid({required this.exam, required this.questionsCount});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 720 ? 2 : 4;
        final width = (constraints.maxWidth - ((columns - 1) * 14)) / columns;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(width: width, child: _MetricCard(title: 'Questions', value: '$questionsCount', subtitle: 'attached to exam', icon: Icons.quiz_outlined, color: AppColors.primary)),
            SizedBox(width: width, child: _MetricCard(title: 'Total Score', value: _points(exam.totalScore), subtitle: 'backend calculated', icon: Icons.stacked_line_chart_rounded, color: AppColors.successText)),
            SizedBox(width: width, child: _MetricCard(title: 'Duration', value: _duration(exam.durationMinutes), subtitle: 'student time limit', icon: Icons.timer_outlined, color: AppColors.warningText)),
            SizedBox(width: width, child: _MetricCard(title: 'Attempts', value: '${exam.maxAttempts}', subtitle: 'allowed attempts', icon: Icons.restart_alt_rounded, color: AppColors.purpleText)),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({required this.title, required this.value, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.shadowThin, blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _textStyle(color: AppColors.textMuted, size: 12, weight: FontWeight.w900)),
                const Spacer(),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: _textStyle(color: AppColors.textTitle, size: 24, weight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 3),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: _textStyle(color: color, size: 11, weight: FontWeight.w800)),
              ],
            ),
          ),
          _IconBox(icon: icon, color: color, size: 42),
        ],
      ),
    );
  }
}

class _QuestionPaperCard extends StatelessWidget {
  final List<ExamSectionDetailsModel> sections;
  final List<ExamQuestionDetail> questions;
  final VoidCallback? onAddSection;
  final ValueChanged<ExamSectionDetailsModel>? onAddQuestionsToSection;

  const _QuestionPaperCard({
    required this.sections,
    required this.questions,
    this.onAddSection,
    this.onAddQuestionsToSection,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty && questions.isEmpty) {
      return _StudioShell(
        child: _StateMessage(
          icon: Icons.view_agenda_outlined,
          title: 'Start manual structure',
          message: 'This draft exam has no sections yet. Add a section, then open it and attach saved questions manually.',
          actionLabel: onAddSection == null ? null : 'Add first section',
          onAction: onAddSection,
        ),
      );
    }

    return _StudioShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            icon: Icons.fact_check_outlined,
            title: 'Question paper',
            subtitle: sections.isEmpty ? '${questions.length} questions' : '${sections.length} sections • ${questions.length} questions',
            trailing: onAddSection == null
                ? null
                : FilledButton.icon(
                    onPressed: onAddSection,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add section'),
                  ),
          ),
          Divider(height: 1, color: AppColors.border),
          if (sections.isNotEmpty)
            ...sections.map((section) => _SectionBlock(section: section, onAddQuestions: onAddQuestionsToSection == null ? null : () => onAddQuestionsToSection!(section)))
          else
            ...questions.asMap().entries.map((entry) => _QuestionRow(index: entry.key + 1, question: entry.value, showSection: true)),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final ExamSectionDetailsModel section;
  final VoidCallback? onAddQuestions;

  const _SectionBlock({required this.section, this.onAddQuestions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          color: AppColors.surfaceBg,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.title, style: _textStyle(color: AppColors.textTitle, size: 14, weight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('${_titleCase(section.questionType)} • ${section.questionCount} questions • ${_points(section.sectionScore)} points', style: _textStyle(color: AppColors.textMuted, size: 11, weight: FontWeight.w800)),
                  ],
                ),
              ),
              _MiniBadge(label: section.mustComplete ? 'Required' : 'Optional', color: section.mustComplete ? AppColors.primary : AppColors.textMuted),
              if (onAddQuestions != null) ...[
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onAddQuestions,
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: const Text('Add questions'),
                ),
              ],
            ],
          ),
        ),
        ...section.questions.asMap().entries.map((entry) => _QuestionRow(index: entry.key + 1, question: entry.value, showSection: false)),
      ],
    );
  }
}

class _QuestionRow extends StatelessWidget {
  final int index;
  final ExamQuestionDetail question;
  final bool showSection;

  const _QuestionRow({required this.index, required this.question, required this.showSection});

  @override
  Widget build(BuildContext context) {
    final q = question.question;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Text(index.toString().padLeft(2, '0'), style: _textStyle(color: AppColors.textHint, size: 12, weight: FontWeight.w900)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.text, maxLines: 3, overflow: TextOverflow.ellipsis, style: _textStyle(color: AppColors.textTitle, size: 13, weight: FontWeight.w800, height: 1.38)),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MetaPill(icon: Icons.category_outlined, label: q.typeLabel),
                    _DifficultyPill(label: q.difficultyLabel),
                    _MetaPill(icon: Icons.grade_outlined, label: '${_points(question.points)} pts'),
                    if (showSection && question.sectionId > 0) _MetaPill(icon: Icons.view_agenda_outlined, label: 'Section ${question.sectionId}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamBackendSettingsCard extends StatelessWidget {
  final ExamModel exam;
  final MyCourseItem? course;

  const _ExamBackendSettingsCard({required this.exam, required this.course});

  @override
  Widget build(BuildContext context) {
    return _StudioShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelHeader(
            icon: Icons.tune_rounded,
            title: 'Backend settings',
            subtitle: 'Values returned by the instructor exam endpoint.',
          ),
          Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _SettingRow(label: 'Exam ID', value: '#${exam.id}'),
                _SettingRow(label: 'Course', value: course?.safeTitle ?? 'Course #${exam.courseId}'),
                _SettingRow(label: 'Type', value: _titleCase(exam.examType)),
                _SettingRow(label: 'Status', value: exam.isPublished ? 'Published' : 'Draft', valueColor: exam.isPublished ? AppColors.successText : AppColors.warningText),
                _SettingRow(label: 'Passing score', value: exam.passingScore == null ? 'Not set' : '${_points(exam.passingScore!)}%'),
                _SettingRow(label: 'Shuffle questions', value: exam.shuffleQuestions ? 'Enabled' : 'Disabled'),
                _SettingRow(label: 'Shuffle options', value: exam.shuffleOptions ? 'Enabled' : 'Disabled'),
                _SettingRow(label: 'Created', value: _formatDate(exam.createdAt)),
                _SettingRow(label: 'Updated', value: _formatDate(exam.updatedAt)),
                if ((exam.instructions ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoNote(title: 'Instructions', message: exam.instructions!.trim()),
                ] else ...[
                  const SizedBox(height: 12),
                  const _InfoNote(title: 'Instructions', message: 'No student-facing instructions were saved for this exam.'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _PanelHeader({required this.icon, required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 15),
      child: Row(
        children: [
          _IconBox(icon: icon, color: AppColors.primary, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _textStyle(color: AppColors.textTitle, size: 15, weight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle, style: _textStyle(color: AppColors.textMuted, size: 11, weight: FontWeight.w700)),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SettingRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: _textStyle(color: AppColors.textMuted, size: 12, weight: FontWeight.w800))),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _textStyle(color: valueColor ?? AppColors.textTitle, size: 12, weight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final String title;
  final String message;

  const _InfoNote({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _textStyle(color: AppColors.infoText, size: 12, weight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(message, style: _textStyle(color: AppColors.infoText, size: 12, weight: FontWeight.w700, height: 1.35)),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateMessage({required this.icon, required this.title, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 380),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconBox(icon: icon, color: AppColors.textHint, size: 58),
                const SizedBox(height: 16),
                Text(title, textAlign: TextAlign.center, style: _textStyle(color: AppColors.textTitle, size: 18, weight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: _textStyle(color: AppColors.textMuted, size: 13, weight: FontWeight.w700, height: 1.45)),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 18),
                  FilledButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _IconBox({required this.icon, required this.color, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(size * 0.30),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Icon(icon, color: color, size: size * 0.50),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _textStyle(color: color, size: 11, weight: FontWeight.w900)),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Text(label, style: _textStyle(color: AppColors.textMuted, size: 11, weight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _DifficultyPill extends StatelessWidget {
  final String label;

  const _DifficultyPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    final color = normalized == 'easy'
        ? AppColors.successText
        : normalized == 'hard'
            ? AppColors.dangerText
            : AppColors.warningText;
    return _MiniBadge(label: label, color: color);
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;

  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

TextStyle _textStyle({
  required Color color,
  required double size,
  required FontWeight weight,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    color: color,
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
  );
}

String _duration(int? minutes) => minutes == null || minutes <= 0 ? 'No limit' : '${minutes}m';

String _points(double value) {
  return value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
}

String _formatDate(DateTime date) {
  if (date.millisecondsSinceEpoch == 0) return '-';
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

String _titleCase(String value) {
  final normalized = value.replaceAll('_', ' ').trim();
  if (normalized.isEmpty) return 'Exam';
  return normalized
      .split(RegExp(r'\s+'))
      .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
}

ExamModel _copyExamAfterPublish(ExamModel exam, ExamPublishResponse response) {
  return ExamModel(
    id: exam.id,
    courseId: exam.courseId,
    title: exam.title,
    description: exam.description,
    instructions: exam.instructions,
    examType: exam.examType,
    durationMinutes: exam.durationMinutes,
    maxAttempts: exam.maxAttempts,
    passingScore: exam.passingScore,
    totalQuestions: response.totalQuestions == 0 ? exam.totalQuestions : response.totalQuestions,
    totalScore: response.totalScore == 0 ? exam.totalScore : response.totalScore,
    isPublished: response.isPublished,
    shuffleQuestions: exam.shuffleQuestions,
    shuffleOptions: exam.shuffleOptions,
    availableFrom: exam.availableFrom,
    availableTo: exam.availableTo,
    createdAt: exam.createdAt,
    updatedAt: DateTime.now(),
  );
}

List<_CourseExamGroup> _replaceExamInGroups(List<_CourseExamGroup> groups, int courseId, ExamModel updated) {
  return groups.map((group) {
    if (group.course.id != courseId) return group;
    return group.copyWith(
      exams: group.exams.map((exam) => exam.id == updated.id ? updated : exam).toList(),
    );
  }).toList();
}
