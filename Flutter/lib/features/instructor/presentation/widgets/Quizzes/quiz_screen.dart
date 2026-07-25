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
    if (dart.library.js_interop) 'package:learnova/core/utils/file_download_web.dart'
    if (dart.library.html) 'package:learnova/core/utils/file_download_web.dart';
import 'package:learnova/features/instructor/data/courses_models.dart';
import 'package:learnova/features/instructor/data/courses_providers.dart';
import 'package:learnova/features/instructor/data/exam_models.dart';
import 'package:learnova/features/instructor/data/question_models.dart';
import 'package:learnova/features/instructor/data/modules_materials_providers.dart';
import 'package:learnova/features/instructor/presentation/controllers/selected_course_provider.dart';
import 'package:learnova/features/instructor/presentation/course_route_identity.dart';
import 'package:learnova/features/instructor/presentation/widgets/course_tabs/question_bank_tab.dart';

part 'quiz_screen_export_dialog.dart';
part 'quiz_screen_manual_dialogs.dart';
part 'quiz_screen_studio_shell.dart';
part 'quiz_screen_details_workspace.dart';


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

