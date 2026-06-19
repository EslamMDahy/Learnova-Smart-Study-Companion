import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/routes.dart';
import '../../../../../core/storage/student_exam_results_cache.dart';
import '../../../../../core/storage/user_storage.dart';
import '../../../../../core/ui/pdf_preview_view.dart';
import '../../../../../core/ui/toast.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../data/student_course_assistant_models.dart';
import '../../../data/student_course_assistant_providers.dart';
import '../../../data/student_courses_models.dart';
import '../../../../auth/data/auth_providers.dart';
import '../../../../../core/ui/chat/rich_message_renderer.dart';
import '../../../../../shared/widgets/top_header.dart';
import '../../../data/student_courses_providers.dart';

class StudentCourseDetailsPage extends ConsumerStatefulWidget {
  const StudentCourseDetailsPage({super.key});

  @override
  ConsumerState<StudentCourseDetailsPage> createState() =>
      _StudentCourseDetailsPageState();
}

class _StudentCourseDetailsPageState
    extends ConsumerState<StudentCourseDetailsPage> {
  late final TextEditingController _searchController;
  late final TextEditingController _assistantController;

  int? _selectedModuleId;
  int? _selectedMaterialId;
  int? _selectedExamId;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _assistantController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _assistantController.dispose();
    super.dispose();
  }

  int? _courseIdFromRoute(BuildContext context) {
    final raw = GoRouterState.of(context).uri.queryParameters['courseId'];
    return int.tryParse(raw ?? '');
  }

  int? _examIdFromRoute(BuildContext context) {
    final raw = GoRouterState.of(context).uri.queryParameters['examId'];
    return int.tryParse(raw ?? '');
  }

  Future<void> _logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
      if (!mounted) return;
      context.go(Routes.login);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        title: 'Logout failed',
        message: e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseId = _courseIdFromRoute(context);
    final routeExamId = _examIdFromRoute(context);
    final effectiveSelectedExamId = _selectedExamId ?? routeExamId;

    if (courseId == null || courseId <= 0) {
      return _CourseRouteError(
        title: 'Course not found',
        message: 'Open the course again from My Courses.',
        onBack: () => context.go(Routes.studentCourses),
      );
    }

    final contentAsync = ref.watch(studentCourseContentProvider(courseId));

    return contentAsync.when(
      loading: () => const _CourseWorkspaceLoading(),
      error: (error, _) => _CourseRouteError(
        title: 'Could not load course content',
        message:
            'This course content is not available yet, or your enrollment is still waiting for approval.',
        onBack: () => context.go(Routes.studentCourses),
        onRetry: () => ref.invalidate(studentCourseContentProvider(courseId)),
      ),
      data: (content) {
        final assistantState =
            ref.watch(studentCourseAssistantControllerProvider(courseId));

        return _CourseLearningWorkspace(
          courseId: courseId,
          content: content,
          searchController: _searchController,
          assistantController: _assistantController,
          selectedModuleId: _selectedModuleId,
          selectedMaterialId: _selectedMaterialId,
          selectedExamId: effectiveSelectedExamId,
          assistantState: assistantState,
          onBackToDashboard: () => context.go(Routes.studentDashboard),
          onBackToCourses: () => context.go(Routes.studentCourses),
          onNotificationsTap: () => context.go(Routes.studentNotifications),
          onSettings: () => context.go(Routes.studentSettings),
          onLogout: _logout,
          onRefresh: () => ref.invalidate(studentCourseContentProvider(courseId)),
          onSelectModule: (module) {
            setState(() {
              _selectedExamId = null;
              _selectedModuleId = module.id;
              _selectedMaterialId =
                  module.materials.isEmpty ? null : module.materials.first.id;
            });
          },
          onSelectMaterial: (module, material) {
            setState(() {
              _selectedExamId = null;
              _selectedModuleId = module.id;
              _selectedMaterialId = material.id;
            });
          },
          onSelectExam: (exam) {
            setState(() {
              _selectedExamId = exam.id;
              _selectedModuleId = exam.moduleId ?? _selectedModuleId;
              _selectedMaterialId = null;
            });
          },
          onStartExam: (exam) {
            context.go(Routes.studentExamAttemptFor(
              courseId: courseId,
              examId: exam.id,
            ));
          },
          onAssistantSend: (message, module, material) {
            ref.read(studentCourseAssistantControllerProvider(courseId).notifier).send(
                  message: message,
                  moduleId: module?.id,
                  materialId: material?.id,
                );
          },
          onAssistantClear: () {
            ref.read(studentCourseAssistantControllerProvider(courseId).notifier).clear();
          },
        );
      },
    );
  }
}

class _CourseLearningWorkspace extends StatelessWidget {
  final int courseId;
  final StudentCourseContent content;
  final TextEditingController searchController;
  final TextEditingController assistantController;
  final int? selectedModuleId;
  final int? selectedMaterialId;
  final int? selectedExamId;
  final StudentCourseAssistantState assistantState;
  final VoidCallback onBackToDashboard;
  final VoidCallback onBackToCourses;
  final VoidCallback onNotificationsTap;
  final VoidCallback onSettings;
  final Future<void> Function() onLogout;
  final VoidCallback onRefresh;
  final ValueChanged<StudentCourseModule> onSelectModule;
  final void Function(StudentCourseModule module, StudentCourseMaterial material)
      onSelectMaterial;
  final ValueChanged<StudentCourseExam> onSelectExam;
  final ValueChanged<StudentCourseExam> onStartExam;
  final void Function(
    String message,
    StudentCourseModule? module,
    StudentCourseMaterial? material,
  ) onAssistantSend;
  final VoidCallback onAssistantClear;

  const _CourseLearningWorkspace({
    required this.courseId,
    required this.content,
    required this.searchController,
    required this.assistantController,
    required this.selectedModuleId,
    required this.selectedMaterialId,
    required this.selectedExamId,
    required this.assistantState,
    required this.onBackToDashboard,
    required this.onBackToCourses,
    required this.onNotificationsTap,
    required this.onSettings,
    required this.onLogout,
    required this.onRefresh,
    required this.onSelectModule,
    required this.onSelectMaterial,
    required this.onSelectExam,
    required this.onStartExam,
    required this.onAssistantSend,
    required this.onAssistantClear,
  });

  @override
  Widget build(BuildContext context) {
    final selectedExam = _resolveSelectedExam(content.exams);
    final selectedModule = _resolveSelectedModule(content.modules);
    final selectedMaterial = selectedExam == null
        ? _resolveSelectedMaterial(selectedModule)
        : null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 980) {
            return _CompactCourseLearningWorkspace(
              courseId: courseId,
              course: content.course,
              modules: content.modules,
              exams: content.exams,
              examsLoadError: content.examsLoadError,
              selectedModule: selectedModule,
              selectedMaterial: selectedMaterial,
              selectedExam: selectedExam,
              onBackToCourses: onBackToCourses,
              onRefresh: onRefresh,
              onSelectModule: onSelectModule,
              onSelectMaterial: onSelectMaterial,
              onSelectExam: onSelectExam,
              onStartExam: onStartExam,
            );
          }

          return Row(
            children: [
              _CourseContentRail(
                courseId: courseId,
                course: content.course,
                modules: content.modules,
                exams: content.exams,
                examsLoadError: content.examsLoadError,
                selectedModuleId: selectedModule?.id,
                selectedMaterialId: selectedMaterial?.id,
                selectedExamId: selectedExam?.id,
                onBackToDashboard: onBackToDashboard,
                onRefresh: onRefresh,
                onSelectModule: onSelectModule,
                onSelectMaterial: onSelectMaterial,
                onSelectExam: onSelectExam,
              ),
              Expanded(
                child: Column(
                  children: [
                    _CourseWorkspaceHeader(
                      searchController: searchController,
                      onNotificationsTap: onNotificationsTap,
                      onSettings: onSettings,
                      onLogout: onLogout,
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _LessonContentArea(
                              courseId: courseId,
                              course: content.course,
                              selectedModule: selectedModule,
                              selectedMaterial: selectedMaterial,
                              selectedExam: selectedExam,
                              onRefresh: onRefresh,
                              onStartExam: onStartExam,
                            ),
                          ),
                          _StudyAssistantPanel(
                            courseTitle: content.course?.safeTitle ?? 'Course',
                            controller: assistantController,
                            assistantState: assistantState,
                            selectedModule: selectedModule,
                            selectedMaterial: selectedMaterial,
                            onSend: (message) => onAssistantSend(
                              message,
                              selectedModule,
                              selectedMaterial,
                            ),
                            onClear: onAssistantClear,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  StudentCourseModule? _resolveSelectedModule(List<StudentCourseModule> modules) {
    if (modules.isEmpty) return null;

    for (final module in modules) {
      if (module.id == selectedModuleId) return module;
    }

    if (selectedMaterialId != null) {
      for (final module in modules) {
        final hasSelectedMaterial = module.materials.any(
          (material) => material.id == selectedMaterialId,
        );
        if (hasSelectedMaterial) return module;
      }
    }

    final firstWithMaterial = modules.where((module) => module.materials.isNotEmpty);
    if (firstWithMaterial.isNotEmpty) return firstWithMaterial.first;

    return modules.first;
  }

  StudentCourseExam? _resolveSelectedExam(List<StudentCourseExam> exams) {
    if (selectedExamId == null || exams.isEmpty) return null;
    for (final exam in exams) {
      if (exam.id == selectedExamId) return exam;
    }
    return null;
  }

  StudentCourseMaterial? _resolveSelectedMaterial(StudentCourseModule? module) {
    if (module == null || module.materials.isEmpty) return null;

    for (final material in module.materials) {
      if (material.id == selectedMaterialId) return material;
    }

    return module.materials.first;
  }
}

class _CompactCourseLearningWorkspace extends StatelessWidget {
  final int courseId;
  final StudentCourse? course;
  final List<StudentCourseModule> modules;
  final List<StudentCourseExam> exams;
  final String? examsLoadError;
  final StudentCourseModule? selectedModule;
  final StudentCourseMaterial? selectedMaterial;
  final StudentCourseExam? selectedExam;
  final VoidCallback onBackToCourses;
  final VoidCallback onRefresh;
  final ValueChanged<StudentCourseModule> onSelectModule;
  final void Function(StudentCourseModule module, StudentCourseMaterial material)
      onSelectMaterial;
  final ValueChanged<StudentCourseExam> onSelectExam;
  final ValueChanged<StudentCourseExam> onStartExam;

  const _CompactCourseLearningWorkspace({
    required this.courseId,
    required this.course,
    required this.modules,
    required this.exams,
    required this.examsLoadError,
    required this.selectedModule,
    required this.selectedMaterial,
    required this.selectedExam,
    required this.onBackToCourses,
    required this.onRefresh,
    required this.onSelectModule,
    required this.onSelectMaterial,
    required this.onSelectExam,
    required this.onStartExam,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onBackToCourses,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to My Courses'),
                ),
                const Spacer(),
                _SoftBadge(label: course?.safeCode ?? 'COURSE-$courseId'),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _MobileModuleSelector(
              modules: modules,
              exams: exams,
              examsLoadError: examsLoadError,
              selectedModuleId: selectedModule?.id,
              selectedMaterialId: selectedMaterial?.id,
              selectedExamId: selectedExam?.id,
              onSelectModule: onSelectModule,
              onSelectMaterial: onSelectMaterial,
              onSelectExam: onSelectExam,
              onRetryExams: onRefresh,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
            child: _LessonBody(
              courseId: courseId,
              course: course,
              selectedModule: selectedModule,
              selectedMaterial: selectedMaterial,
              selectedExam: selectedExam,
              onRefresh: onRefresh,
              onStartExam: onStartExam,
            ),
          ),
        ),
      ],
    );
  }
}


class _CourseContentRail extends StatefulWidget {
  final int courseId;
  final StudentCourse? course;
  final List<StudentCourseModule> modules;
  final List<StudentCourseExam> exams;
  final String? examsLoadError;
  final int? selectedModuleId;
  final int? selectedMaterialId;
  final int? selectedExamId;
  final VoidCallback onBackToDashboard;
  final VoidCallback onRefresh;
  final ValueChanged<StudentCourseModule> onSelectModule;
  final void Function(StudentCourseModule module, StudentCourseMaterial material)
      onSelectMaterial;
  final ValueChanged<StudentCourseExam> onSelectExam;

  const _CourseContentRail({
    required this.courseId,
    required this.course,
    required this.modules,
    required this.exams,
    required this.examsLoadError,
    required this.selectedModuleId,
    required this.selectedMaterialId,
    required this.selectedExamId,
    required this.onBackToDashboard,
    required this.onRefresh,
    required this.onSelectModule,
    required this.onSelectMaterial,
    required this.onSelectExam,
  });

  @override
  State<_CourseContentRail> createState() => _CourseContentRailState();
}

class _CourseContentRailState extends State<_CourseContentRail> {
  static const double _minWidth = 252;
  static const double _defaultWidth = 292;
  static const double _maxWidth = 440;

  double _width = _defaultWidth;
  bool _resizing = false;
  final Set<int> _collapsedModuleIds = <int>{};
  bool _examsExpanded = true;

  @override
  void didUpdateWidget(covariant _CourseContentRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentModuleIds = widget.modules.map((module) => module.id).toSet();
    _collapsedModuleIds.removeWhere((id) => !currentModuleIds.contains(id));
    if (widget.selectedExamId != null &&
        widget.selectedExamId != oldWidget.selectedExamId) {
      _examsExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.course?.safeCode ?? 'COURSE-${widget.courseId}';
    final courseTitle = widget.course?.safeTitle ?? code;

    return _StudentResizableSidebarHost(
      width: _width,
      minWidth: _minWidth,
      maxWidth: _maxWidth,
      isResizing: _resizing,
      onResizeStart: () => setState(() => _resizing = true),
      onResize: _resize,
      onResizeEnd: () => setState(() => _resizing = false),
      child: Container(
        width: _width,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border(right: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowThin,
              blurRadius: 18,
              offset: const Offset(8, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _WorkspaceBrandHeader(),
            _CourseSidebarHeader(title: courseTitle),
            Expanded(
              child: widget.modules.isEmpty &&
                      widget.exams.isEmpty &&
                      widget.examsLoadError == null
                  ? const _EmptySidebarState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      children: [
                        for (var index = 0; index < widget.modules.length; index++) ...[
                          Builder(
                            builder: (_) {
                              final module = widget.modules[index];
                              final expanded = !_collapsedModuleIds.contains(module.id);
                              return _CourseModuleCard(
                                module: module,
                                moduleNumber: index + 1,
                                expanded: expanded,
                                selected: module.id == widget.selectedModuleId &&
                                    widget.selectedExamId == null,
                                selectedMaterialId: widget.selectedExamId == null
                                    ? widget.selectedMaterialId
                                    : null,
                                onSelectModule: () => _toggleModule(module),
                                onSelectMaterial: (material) => _selectMaterial(module, material),
                              );
                            },
                          ),
                          if (index != widget.modules.length - 1) const SizedBox(height: 12),
                        ],
                        if (widget.modules.isNotEmpty ||
                            widget.exams.isNotEmpty ||
                            widget.examsLoadError != null) ...[
                          if (widget.modules.isNotEmpty) const SizedBox(height: 16),
                          _CourseExamsTreeCard(
                            exams: widget.exams,
                            loadError: widget.examsLoadError,
                            expanded: _examsExpanded,
                            selectedExamId: widget.selectedExamId,
                            onToggle: () => setState(() => _examsExpanded = !_examsExpanded),
                            onSelectExam: _selectExam,
                            onRetry: widget.onRefresh,
                          ),
                        ],
                      ],
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: widget.onBackToDashboard,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to Dashboard'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resize(double delta) {
    setState(() {
      _width = (_width + delta).clamp(_minWidth, _maxWidth).toDouble();
    });
  }

  void _toggleModule(StudentCourseModule module) {
    setState(() {
      if (_collapsedModuleIds.contains(module.id)) {
        _collapsedModuleIds.remove(module.id);
      } else {
        _collapsedModuleIds.add(module.id);
      }
    });
    widget.onSelectModule(module);
  }

  void _selectMaterial(
    StudentCourseModule module,
    StudentCourseMaterial material,
  ) {
    setState(() => _collapsedModuleIds.remove(module.id));
    widget.onSelectMaterial(module, material);
  }

  void _selectExam(StudentCourseExam exam) {
    setState(() => _examsExpanded = true);
    widget.onSelectExam(exam);
  }
}

class _StudentResizableSidebarHost extends StatelessWidget {
  static const double _handleWidth = 10.0;

  final double width;
  final double minWidth;
  final double maxWidth;
  final bool isResizing;
  final Widget child;
  final VoidCallback onResizeStart;
  final void Function(double delta) onResize;
  final VoidCallback onResizeEnd;

  const _StudentResizableSidebarHost({
    required this.width,
    required this.minWidth,
    required this.maxWidth,
    required this.isResizing,
    required this.child,
    required this.onResizeStart,
    required this.onResize,
    required this.onResizeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width + _handleWidth,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: width, child: child),
          MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (_) => onResizeStart(),
              onHorizontalDragUpdate: (details) => onResize(details.delta.dx),
              onHorizontalDragEnd: (_) => onResizeEnd(),
              onHorizontalDragCancel: onResizeEnd,
              child: Container(
                width: _handleWidth,
                color: isResizing
                    ? AppColors.primary.withOpacity(0.08)
                    : AppColors.bg,
                child: Center(
                  child: Container(
                    width: 3,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isResizing
                          ? AppColors.primary.withOpacity(0.65)
                          : AppColors.textHint.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceBrandHeader extends StatelessWidget {
  const _WorkspaceBrandHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/logo.webp',
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learnova',
                  style: TextStyle(
                    color: AppColors.textTitle,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'STUDENT PORTAL',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    height: 1,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseWorkspaceHeader extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onNotificationsTap;
  final VoidCallback onSettings;
  final Future<void> Function() onLogout;

  const _CourseWorkspaceHeader({
    required this.searchController,
    required this.onNotificationsTap,
    required this.onSettings,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: UserStorage.listenable as ValueNotifier<int>,
      builder: (context, _, __) {
        return TopHeaderWidget(
          searchController: searchController,
          searchHint: 'Search topics, questions, or student',
          userName: _displayName(),
          userSubtitle: _displaySubtitle(),
          avatarUrl: UserStorage.avatarUrl,
          onNotificationsTap: onNotificationsTap,
          onSettings: onSettings,
          onLogout: () async => onLogout(),
        );
      },
    );
  }
}

class _LessonContentArea extends StatelessWidget {
  final int courseId;
  final StudentCourse? course;
  final StudentCourseModule? selectedModule;
  final StudentCourseMaterial? selectedMaterial;
  final StudentCourseExam? selectedExam;
  final VoidCallback onRefresh;
  final ValueChanged<StudentCourseExam> onStartExam;

  const _LessonContentArea({
    required this.courseId,
    required this.course,
    required this.selectedModule,
    required this.selectedMaterial,
    required this.selectedExam,
    required this.onRefresh,
    required this.onStartExam,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      height: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(34, 30, 34, 42),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: selectedExam != null ? 980 : 860),
            child: _LessonBody(
              courseId: courseId,
              course: course,
              selectedModule: selectedModule,
              selectedMaterial: selectedMaterial,
              selectedExam: selectedExam,
              onRefresh: onRefresh,
              onStartExam: onStartExam,
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonBody extends StatelessWidget {
  final int courseId;
  final StudentCourse? course;
  final StudentCourseModule? selectedModule;
  final StudentCourseMaterial? selectedMaterial;
  final StudentCourseExam? selectedExam;
  final VoidCallback onRefresh;
  final ValueChanged<StudentCourseExam> onStartExam;

  const _LessonBody({
    required this.courseId,
    required this.course,
    required this.selectedModule,
    required this.selectedMaterial,
    required this.selectedExam,
    required this.onRefresh,
    required this.onStartExam,
  });

  @override
  Widget build(BuildContext context) {
    final exam = selectedExam;
    if (exam != null) {
      return _ExamOverviewBody(
        course: course,
        exam: exam,
        onStart: exam.isAvailable ? () => onStartExam(exam) : null,
      );
    }

    if (selectedModule == null) {
      return _EmptyLessonState(courseId: courseId, onRefresh: onRefresh);
    }

    final material = selectedMaterial;
    final title = material?.safeTitle ?? selectedModule!.safeTitle;
    final subtitle = material?.safeDescription ?? selectedModule!.safeDescription;
    final lessonTitle = _lessonTitle(selectedModule!, material);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lessonTitle,
          style: TextStyle(
            color: AppColors.textTitle,
            fontSize: 26,
            height: 1.16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.55,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        _MaterialPreviewStage(
          courseId: courseId,
          module: selectedModule!,
          material: material,
          title: title,
          onRefresh: onRefresh,
        ),
        const SizedBox(height: 18),
        _MaterialTopicsCard(
          courseId: courseId,
          course: course,
          module: selectedModule!,
          material: material,
        ),
      ],
    );
  }
}

class _MaterialPreviewStage extends ConsumerStatefulWidget {
  final int courseId;
  final StudentCourseModule module;
  final StudentCourseMaterial? material;
  final String title;
  final VoidCallback onRefresh;

  const _MaterialPreviewStage({
    required this.courseId,
    required this.module,
    required this.material,
    required this.title,
    required this.onRefresh,
  });

  @override
  ConsumerState<_MaterialPreviewStage> createState() => _MaterialPreviewStageState();
}

class _MaterialPreviewStageState extends ConsumerState<_MaterialPreviewStage> {
  Future<String?>? _urlFuture;
  int? _loadedMaterialId;

  Future<String?> _loadUrl(StudentCourseMaterial material) async {
    final inlineUrl = (material.downloadUrl ?? '').trim();
    if (inlineUrl.isNotEmpty) return inlineUrl;

    return ref.read(studentCoursesApiProvider).materialDownloadUrl(
          courseId: widget.courseId,
          moduleId: widget.module.id,
          materialId: material.id,
        );
  }

  Future<String?>? _ensureUrlFuture() {
    final material = widget.material;
    if (material == null) {
      _loadedMaterialId = null;
      _urlFuture = null;
      return null;
    }

    if (_loadedMaterialId != material.id || _urlFuture == null) {
      _loadedMaterialId = material.id;
      _urlFuture = _loadUrl(material);
    }

    return _urlFuture;
  }

  @override
  Widget build(BuildContext context) {
    final material = widget.material;
    if (material == null) {
      return _PdfPlaceholderCard(
        height: 430,
        icon: Icons.picture_as_pdf_outlined,
        title: 'Choose a PDF material',
        message: 'Select one of the published PDF files from the course content list.',
        actionLabel: 'Refresh',
        onAction: widget.onRefresh,
      );
    }

    if (!_isPdfMaterial(material)) {
      return _PdfPlaceholderCard(
        height: 430,
        icon: _materialIcon(material),
        title: widget.title,
        message: 'This student workspace previews PDF files only.',
      );
    }

    final future = _ensureUrlFuture();
    return FutureBuilder<String?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _PdfPlaceholderCard(
            height: 720,
            icon: Icons.picture_as_pdf_outlined,
            title: 'Loading PDF preview...',
            message: 'Preparing the secured viewer for this material.',
            loading: true,
          );
        }

        final url = (snapshot.data ?? '').trim();
        if (snapshot.hasError || url.isEmpty) {
          return _PdfPlaceholderCard(
            height: 430,
            icon: Icons.link_off_rounded,
            title: 'PDF preview unavailable',
            message: 'Could not load the secured PDF URL. Please try again.',
            actionLabel: 'Retry',
            onAction: () {
              setState(() {
                _loadedMaterialId = null;
                _urlFuture = null;
              });
            },
          );
        }

        return _StudentPdfViewer(
          materialId: material.id,
          url: url,
        );
      },
    );
  }
}

class _StudentPdfViewer extends StatefulWidget {
  final int materialId;
  final String url;

  const _StudentPdfViewer({
    required this.materialId,
    required this.url,
  });

  @override
  State<_StudentPdfViewer> createState() => _StudentPdfViewerState();
}

class _StudentPdfViewerState extends State<_StudentPdfViewer> {
  late String _viewType;

  @override
  void initState() {
    super.initState();
    _register();
  }

  @override
  void didUpdateWidget(covariant _StudentPdfViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.materialId != widget.materialId) {
      _register();
    }
  }

  void _register() {
    _viewType = 'student-pdf-${widget.materialId}-${widget.url.hashCode}';
    registerPdfPreviewView(
      viewType: _viewType,
      url: widget.url,
      interactive: true,
    );
    updatePdfPreviewInteractivity(viewType: _viewType, interactive: true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 720,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: HtmlElementView(viewType: _viewType),
    );
  }
}

class _PdfPlaceholderCard extends StatelessWidget {
  final double height;
  final IconData icon;
  final String title;
  final String message;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _PdfPlaceholderCard({
    required this.height,
    required this.icon,
    required this.title,
    required this.message,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  shape: BoxShape.circle,
                ),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(18),
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Icon(icon, color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


class _MaterialTopicsCard extends ConsumerWidget {
  final int courseId;
  final StudentCourse? course;
  final StudentCourseModule module;
  final StudentCourseMaterial? material;

  const _MaterialTopicsCard({
    required this.courseId,
    required this.course,
    required this.module,
    required this.material,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inlineTopics = material?.topics ?? const <StudentCourseTopic>[];
    final materialTopicsAsync = material == null || inlineTopics.isNotEmpty
        ? null
        : ref.watch(studentMaterialTopicsProvider(StudentMaterialTopicsArgs(
            courseId: courseId,
            moduleId: module.id,
            materialId: material!.id,
          )));

    final topics = inlineTopics.isNotEmpty
        ? inlineTopics
        : materialTopicsAsync?.maybeWhen(
              data: (value) => value,
              orElse: () => const <StudentCourseTopic>[],
            ) ??
            const <StudentCourseTopic>[];
    final roots = _rootCourseTopics(topics);
    final title = material == null ? 'Module Topics' : 'File Topics';
    final isLoadingTopics = materialTopicsAsync?.isLoading ?? false;
    final topicsLoadError = materialTopicsAsync?.hasError ?? false;
    final subtitle = material == null
        ? 'Select a PDF file from the course tree to see its extracted topics.'
        : isLoadingTopics
            ? '${material!.safeTitle} • loading topics...'
            : topicsLoadError
                ? '${material!.safeTitle} • topics could not be loaded'
                : '${material!.safeTitle} • ${topics.length} topic${topics.length == 1 ? '' : 's'}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowThin,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.infoBorder),
                  ),
                  child: const Icon(
                    Icons.account_tree_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.textTitle,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: _SoftBadge(label: module.safeTitle),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: isLoadingTopics
                ? const _TopicsLoadingBox()
                : topicsLoadError
                    ? _TopicsLoadErrorBox(
                        onRetry: material == null
                            ? null
                            : () => ref.invalidate(
                                  studentMaterialTopicsProvider(
                                    StudentMaterialTopicsArgs(
                                      courseId: courseId,
                                      moduleId: module.id,
                                      materialId: material!.id,
                                    ),
                                  ),
                                ),
                      )
                    : topics.isEmpty
                        ? _NoTopicsBox(material: material)
                        : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < roots.length; i++) ...[
                        _TopicOutlineCard(
                          topic: roots[i],
                          allTopics: topics,
                          indexLabel: '${i + 1}'.padLeft(2, '0'),
                        ),
                        if (i != roots.length - 1) const SizedBox(height: 12),
                      ],
                      if (course != null) ...[
                        const SizedBox(height: 22),
                        Divider(color: AppColors.border),
                        const SizedBox(height: 14),
                        Text(
                          '${course!.safeCode} • ${course!.safeTitle}',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TopicsLoadingBox extends StatelessWidget {
  const _TopicsLoadingBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading topics for this material...',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicsLoadErrorBox extends StatelessWidget {
  final VoidCallback? onRetry;

  const _TopicsLoadErrorBox({this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.dangerText,
            size: 26,
          ),
          const SizedBox(height: 10),
          Text(
            'Could not load topics for this material.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textTitle,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoTopicsBox extends StatelessWidget {
  final StudentCourseMaterial? material;

  const _NoTopicsBox({required this.material});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.topic_outlined,
            color: AppColors.textHint,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material == null ? 'No file selected' : 'No topics available yet',
                  style: TextStyle(
                    color: AppColors.textTitle,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  material == null
                      ? 'Choose a PDF from the course structure to preview its topics.'
                      : 'When the instructor-generated topics are ready, they will appear here for reading only.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicOutlineCard extends StatelessWidget {
  final StudentCourseTopic topic;
  final List<StudentCourseTopic> allTopics;
  final String indexLabel;

  const _TopicOutlineCard({
    required this.topic,
    required this.allTopics,
    required this.indexLabel,
  });

  @override
  Widget build(BuildContext context) {
    final children = _childCourseTopics(allTopics, topic.id);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.infoBorder),
                ),
                child: Text(
                  indexLabel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.safeTitle,
                      style: TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if ((topic.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        topic.safeDescription,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12.5,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (children.isNotEmpty)
                _SoftBadge(label: '${children.length} subtopic${children.length == 1 ? '' : 's'}'),
            ],
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Column(
                children: [
                  for (final child in children)
                    _SubTopicOutlineRow(
                      topic: child,
                      allTopics: allTopics,
                      depth: 0,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubTopicOutlineRow extends StatelessWidget {
  final StudentCourseTopic topic;
  final List<StudentCourseTopic> allTopics;
  final int depth;

  const _SubTopicOutlineRow({
    required this.topic,
    required this.allTopics,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    final children = _childCourseTopics(allTopics, topic.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: depth * 20.0),
          child: Stack(
            children: [
              Positioned(
                left: 6,
                top: 0,
                bottom: children.isEmpty ? 13 : -2,
                child: Container(width: 1, color: AppColors.border),
              ),
              Positioned(
                left: 6,
                top: 13,
                child: Container(width: 12, height: 1, color: AppColors.border),
              ),
              Container(
                margin: const EdgeInsets.only(left: 20),
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.subdirectory_arrow_right_rounded,
                      size: 14,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.safeTitle,
                            style: TextStyle(
                              color: AppColors.textGray,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if ((topic.description ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              topic.safeDescription,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11.5,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (final child in children)
          _SubTopicOutlineRow(
            topic: child,
            allTopics: allTopics,
            depth: depth + 1,
          ),
      ],
    );
  }
}

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

class _StudyAssistantPanel extends StatefulWidget {
  final String courseTitle;
  final TextEditingController controller;
  final StudentCourseAssistantState assistantState;
  final StudentCourseModule? selectedModule;
  final StudentCourseMaterial? selectedMaterial;
  final ValueChanged<String> onSend;
  final VoidCallback onClear;

  const _StudyAssistantPanel({
    required this.courseTitle,
    required this.controller,
    required this.assistantState,
    required this.selectedModule,
    required this.selectedMaterial,
    required this.onSend,
    required this.onClear,
  });

  @override
  State<_StudyAssistantPanel> createState() => _StudyAssistantPanelState();
}

class _StudyAssistantPanelState extends State<_StudyAssistantPanel> {
  static const double _minPanelWidth = 320;
  static const double _defaultPanelWidth = 430;
  static const double _maxPanelWidth = 760;

  double _panelWidth = _defaultPanelWidth;

  @override
  Widget build(BuildContext context) {
    final moduleTitle = widget.selectedModule?.safeTitle;
    final materialTitle = widget.selectedMaterial?.safeTitle;
    final hasContext = materialTitle != null && materialTitle.trim().isNotEmpty;
    final isAssistantBusy = widget.assistantState.isBusy;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxAllowedWidth = math.max(
      _minPanelWidth,
      math.min(_maxPanelWidth, screenWidth * 0.58),
    );
    final width = _panelWidth.clamp(_minPanelWidth, maxAllowedWidth).toDouble();

    return SizedBox(
      width: width,
      height: double.infinity,
      child: Stack(
        children: [
          Container(
            width: width,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border(left: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      _AssistantBotIcon(size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Course assistant',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textTitle,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.courseTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tooltip(
                        message: 'Drag the left edge to resize chat',
                        child: Icon(
                          Icons.open_in_full_rounded,
                          color: AppColors.textHint,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'New chat',
                        onPressed: isAssistantBusy ? null : widget.onClear,
                        icon: Icon(
                          Icons.add_comment_outlined,
                          color: isAssistantBusy ? AppColors.textHint : AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.headerBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Today',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _AssistantContextCard(
                        moduleTitle: moduleTitle,
                        materialTitle: materialTitle,
                      ),
                      const SizedBox(height: 14),
                      if (widget.assistantState.loadingHistory) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AssistantBotIcon(size: 26),
                            const SizedBox(width: 8),
                            const _AssistantHistoryLoadingBubble(),
                          ],
                        ),
                      ] else if (widget.assistantState.messages.isEmpty) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AssistantBotIcon(size: 26),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _AssistantMessage(
                                isUser: false,
                                child: Text(
                                  hasContext
                                      ? 'Ask anything about this material. I will create a chat session from your first message, then keep the same session for follow-up questions.'
                                      : 'Ask anything about this course. Select a material first if you want the question to stay focused on one lecture.',
                                  style: TextStyle(
                                    color: AppColors.textGray,
                                    fontSize: 12.5,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _AssistantChip(
                              label: 'Summarize material',
                              onTap: hasContext
                                  ? () => widget.onSend(
                                        'Summarize "${materialTitle!}" in clear bullet points.',
                                      )
                                  : null,
                            ),
                            _AssistantChip(
                              label: 'Explain simply',
                              onTap: hasContext
                                  ? () => widget.onSend(
                                        'Explain "${materialTitle!}" in simple terms with examples.',
                                      )
                                  : null,
                            ),
                            _AssistantChip(
                              label: 'Quiz me',
                              onTap: hasContext
                                  ? () => widget.onSend(
                                        'Quiz me on "${materialTitle!}", then wait for my answers.',
                                      )
                                  : null,
                            ),
                          ],
                        ),
                      ] else ...[
                        for (final message in widget.assistantState.messages) ...[
                          if (!message.isUser)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _AssistantBotIcon(size: 26),
                                const SizedBox(width: 8),
                                Expanded(child: _AssistantBubble(message: message)),
                              ],
                            )
                          else
                            _AssistantBubble(message: message),
                          const SizedBox(height: 12),
                        ],
                        if (widget.assistantState.sending)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _AssistantBotIcon(size: 26),
                              const SizedBox(width: 8),
                              const _AssistantTypingBubble(),
                            ],
                          ),
                      ],
                    ],
                  ),
                ),
                _AssistantInputBar(
                  controller: widget.controller,
                  sending: widget.assistantState.sending,
                  enabled: !widget.assistantState.loadingHistory,
                  onSend: widget.onSend,
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _panelWidth = (_panelWidth - details.delta.dx)
                        .clamp(_minPanelWidth, maxAllowedWidth)
                        .toDouble();
                  });
                },
                child: SizedBox(
                  width: 10,
                  child: Center(
                    child: Container(
                      width: 3,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantContextCard extends StatelessWidget {
  final String? moduleTitle;
  final String? materialTitle;

  const _AssistantContextCard({
    required this.moduleTitle,
    required this.materialTitle,
  });

  @override
  Widget build(BuildContext context) {
    final hasMaterial = materialTitle != null && materialTitle!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasMaterial ? AppColors.selectedBg : AppColors.headerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasMaterial ? AppColors.primary.withOpacity(0.25) : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasMaterial ? Icons.menu_book_rounded : Icons.info_outline_rounded,
            color: hasMaterial ? AppColors.primary : AppColors.textMuted,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasMaterial ? materialTitle! : 'No material selected',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textTitle,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (moduleTitle != null && moduleTitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    moduleTitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final bool enabled;
  final ValueChanged<String> onSend;

  const _AssistantInputBar({
    required this.controller,
    required this.sending,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 22),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          color: AppColors.headerBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowThin,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 5, 7, 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled && !sending,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                style: TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: enabled
                      ? 'Ask a question about this lecture...'
                      : 'Ask a question about this course...',
                  hintStyle: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final canSend = enabled && !sending && value.text.trim().isNotEmpty;
                return Material(
                  color: canSend ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(9),
                  child: InkWell(
                    onTap: canSend ? _submit : null,
                    borderRadius: BorderRadius.circular(9),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: sending
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.3,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: canSend ? Colors.white : AppColors.textHint,
                              size: 18,
                            ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final text = controller.text.trim();
    if (text.isEmpty || sending || !enabled) return;
    controller.clear();
    onSend(text);
  }
}

class _AssistantBubble extends StatelessWidget {
  final StudentAssistantMessage message;

  const _AssistantBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return _AssistantMessage(
      isUser: message.isUser,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isUser || message.isError)
            Text(
              message.content,
              style: TextStyle(
                color: message.isUser ? Colors.white : AppColors.warningText,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: message.isUser ? FontWeight.w700 : FontWeight.w500,
              ),
            )
          else
            RichMessageRenderer(
              text: message.content,
            ),
          if (!message.isUser && message.sources.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final source in message.sources)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.headerBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      source.label,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}


class _AssistantMarkdownText extends StatelessWidget {
  final String text;
  const _AssistantMarkdownText({required this.text});
  @override
  Widget build(BuildContext context) {
    return RichMessageRenderer(text: text);
  }
}

class _AssistantMarkdownBullet extends StatelessWidget {
  final String marker;
  final String text;
  final TextStyle baseStyle;

  const _AssistantMarkdownBullet({
    required this.marker,
    required this.text,
    required this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: marker == '•' ? 14 : 24,
          child: Text(
            marker,
            style: baseStyle.copyWith(
              color: AppColors.textGray,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: _AssistantMarkdownLine(text: text, style: baseStyle),
        ),
      ],
    );
  }
}

class _AssistantMarkdownLine extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _AssistantMarkdownLine({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: _inlineSpans(text, style)),
      textAlign: TextAlign.start,
      softWrap: true,
    );
  }
}

List<TextSpan> _inlineSpans(String text, TextStyle baseStyle) {
  final spans = <TextSpan>[];
  var cursor = 0;

  while (cursor < text.length) {
    final token = _nextMarkdownToken(text, cursor);
    if (token == null) {
      spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
      break;
    }

    if (token.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, token.start), style: baseStyle));
    }

    final content = text.substring(token.contentStart, token.contentEnd);
    var tokenStyle = baseStyle;
    switch (token.type) {
      case _MarkdownInlineTokenType.bold:
        tokenStyle = baseStyle.copyWith(
          color: AppColors.textTitle,
          fontWeight: FontWeight.w900,
        );
        break;
      case _MarkdownInlineTokenType.italic:
        tokenStyle = baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
        );
        break;
      case _MarkdownInlineTokenType.code:
        tokenStyle = baseStyle.copyWith(
          color: AppColors.textTitle,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w700,
          backgroundColor: AppColors.headerBg,
        );
        break;
      case _MarkdownInlineTokenType.link:
        tokenStyle = baseStyle.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          decoration: TextDecoration.underline,
        );
        break;
    }

    spans.add(TextSpan(text: content, style: tokenStyle));
    cursor = token.end;
  }

  return spans;
}

_MarkdownInlineToken? _nextMarkdownToken(String text, int start) {
  _MarkdownInlineToken? best;

  void consider(_MarkdownInlineToken? token) {
    if (token == null) return;
    if (best == null || token.start < best!.start) best = token;
  }

  consider(_findDelimitedToken(
    text: text,
    start: start,
    delimiter: '**',
    type: _MarkdownInlineTokenType.bold,
  ));
  consider(_findDelimitedToken(
    text: text,
    start: start,
    delimiter: '__',
    type: _MarkdownInlineTokenType.bold,
  ));
  consider(_findDelimitedToken(
    text: text,
    start: start,
    delimiter: '`',
    type: _MarkdownInlineTokenType.code,
  ));
  consider(_findDelimitedToken(
    text: text,
    start: start,
    delimiter: '*',
    type: _MarkdownInlineTokenType.italic,
    ignoredPrefixes: const ['**'],
  ));
  consider(_findDelimitedToken(
    text: text,
    start: start,
    delimiter: '_',
    type: _MarkdownInlineTokenType.italic,
    ignoredPrefixes: const ['__'],
  ));
  consider(_findMarkdownLink(text, start));

  return best;
}

_MarkdownInlineToken? _findDelimitedToken({
  required String text,
  required int start,
  required String delimiter,
  required _MarkdownInlineTokenType type,
  List<String> ignoredPrefixes = const [],
}) {
  var open = text.indexOf(delimiter, start);

  while (open != -1) {
    final shouldIgnore = ignoredPrefixes.any(
      (prefix) => text.startsWith(prefix, open),
    );
    if (!shouldIgnore) {
      final contentStart = open + delimiter.length;
      final close = text.indexOf(delimiter, contentStart);
      if (close != -1 && close > contentStart) {
        return _MarkdownInlineToken(
          type: type,
          start: open,
          contentStart: contentStart,
          contentEnd: close,
          end: close + delimiter.length,
        );
      }
    }

    open = text.indexOf(delimiter, open + delimiter.length);
  }

  return null;
}

_MarkdownInlineToken? _findMarkdownLink(String text, int start) {
  final openBracket = text.indexOf('[', start);
  if (openBracket == -1) return null;

  final closeBracket = text.indexOf(']', openBracket + 1);
  if (closeBracket == -1 || closeBracket + 1 >= text.length) return null;
  if (text[closeBracket + 1] != '(') return null;

  final closeParen = text.indexOf(')', closeBracket + 2);
  if (closeParen == -1 || closeBracket == openBracket + 1) return null;

  return _MarkdownInlineToken(
    type: _MarkdownInlineTokenType.link,
    start: openBracket,
    contentStart: openBracket + 1,
    contentEnd: closeBracket,
    end: closeParen + 1,
  );
}

enum _MarkdownInlineTokenType { bold, italic, code, link }

class _MarkdownInlineToken {
  final _MarkdownInlineTokenType type;
  final int start;
  final int contentStart;
  final int contentEnd;
  final int end;

  const _MarkdownInlineToken({
    required this.type,
    required this.start,
    required this.contentStart,
    required this.contentEnd,
    required this.end,
  });
}


class _AssistantHistoryLoadingBubble extends StatelessWidget {
  const _AssistantHistoryLoadingBubble();

  @override
  Widget build(BuildContext context) {
    return _AssistantMessage(
      isUser: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            'Loading previous chat...',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantTypingBubble extends StatelessWidget {
  const _AssistantTypingBubble();

  @override
  Widget build(BuildContext context) {
    return _AssistantMessage(
      isUser: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            'Thinking...',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}



class _CourseSidebarHeader extends StatelessWidget {
  final String title;

  const _CourseSidebarHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.menu_book_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textTitle,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarMetricPill extends StatelessWidget {
  final String value;
  final String label;

  const _SidebarMetricPill({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppColors.textTitle,
              fontSize: 13,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 9.5,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SidebarSectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textHint, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseExamsTreeCard extends StatelessWidget {
  final List<StudentCourseExam> exams;
  final String? loadError;
  final bool expanded;
  final int? selectedExamId;
  final VoidCallback onToggle;
  final ValueChanged<StudentCourseExam> onSelectExam;
  final VoidCallback? onRetry;

  const _CourseExamsTreeCard({
    required this.exams,
    required this.expanded,
    required this.selectedExamId,
    required this.onToggle,
    required this.onSelectExam,
    this.loadError,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final active = selectedExamId != null && exams.any((exam) => exam.id == selectedExamId);
    final hasLoadError = loadError != null && loadError!.trim().isNotEmpty;
    final examLabel = hasLoadError && exams.isEmpty
        ? 'Could not load exams'
        : exams.isEmpty
            ? 'No published exams'
            : exams.length == 1
                ? '1 published exam'
                : '${exams.length} published exams';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.infoBorder : AppColors.border,
          width: active ? 1.3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: active ? AppColors.shadowBlue.withOpacity(0.18) : AppColors.shadowThin,
            blurRadius: active ? 18 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: active ? AppColors.selectedBg : AppColors.cardBg,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 11, 11),
                child: Row(
                  children: [
                    _ExamsIndexBox(active: active),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exams',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: active ? AppColors.primary : AppColors.textTitle,
                              fontSize: 13,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            examLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10.5,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.chevron_right_rounded,
                      color: active || expanded ? AppColors.primary : AppColors.textHint,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            sizeCurve: Curves.easeOutCubic,
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Container(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: hasLoadError && exams.isEmpty
                      ? _ExamsLoadErrorNode(
                          message: loadError!.trim(),
                          onRetry: onRetry,
                        )
                      : exams.isEmpty
                          ? const _NoPublishedExamsNode()
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 2,
                                  height: 22.0 * exams.length.clamp(1, 8).toDouble(),
                                  margin: const EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.infoBorder,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    children: [
                                      for (var index = 0; index < exams.length; index++) ...[
                                        _CourseExamTile(
                                          exam: exams[index],
                                          selected: exams[index].id == selectedExamId,
                                          onTap: () => onSelectExam(exams[index]),
                                        ),
                                        if (index != exams.length - 1) const SizedBox(height: 8),
                                      ],
                                    ],
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
    );
  }
}

class _ExamsIndexBox extends StatelessWidget {
  final bool active;

  const _ExamsIndexBox({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.headerBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Icon(
        Icons.assignment_turned_in_outlined,
        color: active ? Colors.white : AppColors.primary,
        size: 17,
      ),
    );
  }
}

class _NoPublishedExamsNode extends StatelessWidget {
  const _NoPublishedExamsNode();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No published exams are available for this course yet.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamsLoadErrorNode extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ExamsLoadErrorNode({
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 17,
                color: AppColors.warningText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Published exams could not be loaded.',
                  style: TextStyle(
                    color: AppColors.warningText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CourseExamTile extends StatelessWidget {
  final StudentCourseExam exam;
  final bool selected;
  final VoidCallback onTap;

  const _CourseExamTile({
    required this.exam,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SidebarLeafTile(
      icon: Icons.assignment_turned_in_outlined,
      iconBg: selected ? AppColors.primary : AppColors.infoBg,
      iconColor: selected ? Colors.white : AppColors.primary,
      title: exam.safeTitle,
      subtitle: '${exam.totalQuestions} questions • ${_formatScore(exam.totalScore)} pts',
      selected: selected,
      onTap: onTap,
      badge: _titleCase(exam.safeType),
      trailing: Icon(
        Icons.play_arrow_rounded,
        color: exam.isAvailable ? AppColors.primary : AppColors.textHint,
        size: 18,
      ),
    );
  }
}

List<StudentCourseTopic> _rootCourseTopics(List<StudentCourseTopic> topics) {
  final roots = topics.where((topic) => topic.parentTopicId == null).toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  return roots;
}

List<StudentCourseTopic> _childCourseTopics(
  List<StudentCourseTopic> topics,
  int parentTopicId,
) {
  final children = topics.where((topic) => topic.parentTopicId == parentTopicId).toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  return children;
}

class _CourseModuleCard extends StatelessWidget {
  final StudentCourseModule module;
  final int moduleNumber;
  final bool selected;
  final bool expanded;
  final int? selectedMaterialId;
  final VoidCallback onSelectModule;
  final ValueChanged<StudentCourseMaterial> onSelectMaterial;

  const _CourseModuleCard({
    required this.module,
    required this.moduleNumber,
    required this.selected,
    required this.expanded,
    required this.selectedMaterialId,
    required this.onSelectModule,
    required this.onSelectMaterial,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected;
    final hasContent = module.materials.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.infoBorder : AppColors.border,
          width: active ? 1.3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: active ? AppColors.shadowBlue.withOpacity(0.18) : AppColors.shadowThin,
            blurRadius: active ? 18 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: active ? AppColors.selectedBg : AppColors.cardBg,
            child: InkWell(
              onTap: onSelectModule,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 11, 11),
                child: Row(
                  children: [
                    _ModuleIndexBox(number: moduleNumber, active: active),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            module.safeTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: active ? AppColors.primary : AppColors.textTitle,
                              fontSize: 13,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _moduleSummary(module),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10.5,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _PublishedDot(active: module.isPublished),
                    const SizedBox(width: 8),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.chevron_right_rounded,
                      color: active || expanded ? AppColors.primary : AppColors.textHint,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            sizeCurve: Curves.easeOutCubic,
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Container(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: hasContent
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 2,
                              height: 22.0 * module.materials.length.clamp(1, 8).toDouble(),
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: AppColors.infoBorder,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                children: [
                                  for (var i = 0; i < module.materials.length; i++) ...[
                                    _ContentMaterialNode(
                                      material: module.materials[i],
                                      indexLabel: '${moduleNumber}.${i + 1}',
                                      selected: module.materials[i].id == selectedMaterialId,
                                      onTap: () => onSelectMaterial(module.materials[i]),
                                    ),
                                    if (i != module.materials.length - 1)
                                      const SizedBox(height: 8),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        )
                      : const _ModuleEmptyContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _moduleSummary(StudentCourseModule module) {
    return module.materials.length == 1
        ? '1 material'
        : '${module.materials.length} materials';
  }
}

class _ModuleIndexBox extends StatelessWidget {
  final int number;
  final bool active;

  const _ModuleIndexBox({required this.number, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.headerBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? AppColors.primary : AppColors.border,
        ),
      ),
      child: active
          ? const Icon(Icons.folder_open_rounded, color: Colors.white, size: 17)
          : Text(
              number.toString().padLeft(2, '0'),
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class _PublishedDot extends StatelessWidget {
  final bool active;

  const _PublishedDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: active ? 'Published' : 'Not published',
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: active ? AppColors.successDot : AppColors.textHint,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ModuleEmptyContent extends StatelessWidget {
  const _ModuleEmptyContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textHint),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'No published materials yet.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentMaterialNode extends StatelessWidget {
  final StudentCourseMaterial material;
  final String indexLabel;
  final bool selected;
  final VoidCallback onTap;

  const _ContentMaterialNode({
    required this.material,
    required this.indexLabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _materialIcon(material);
    final isPdf = _isPdfMaterial(material);
    final meta = <String>[
      _titleCase(material.safeType),
      if (material.fileSize != null) _formatBytes(material.fileSize!),
    ];

    return _SidebarLeafTile(
      icon: icon,
      iconBg: isPdf ? AppColors.dangerBg : AppColors.infoBg,
      iconColor: isPdf ? AppColors.dangerText : AppColors.primary,
      title: material.safeTitle,
      subtitle: meta.join(' • '),
      selected: selected,
      onTap: onTap,
      prefix: indexLabel,
      badge: isPdf ? 'PDF' : _titleCase(material.safeType),
      trailing: _NodeStatusDot(status: material.status),
    );
  }
}

class _ModuleExamTile extends StatelessWidget {
  final StudentCourseExam exam;
  final bool selected;
  final VoidCallback onTap;

  const _ModuleExamTile({
    required this.exam,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SidebarLeafTile(
      icon: Icons.assignment_turned_in_outlined,
      iconBg: AppColors.infoBg,
      iconColor: AppColors.primary,
      title: exam.safeTitle,
      subtitle: '${exam.totalQuestions} questions • ${_formatScore(exam.totalScore)} pts',
      selected: selected,
      onTap: onTap,
      badge: _titleCase(exam.safeType),
      trailing: Icon(
        Icons.play_arrow_rounded,
        color: exam.isAvailable ? AppColors.primary : AppColors.textHint,
        size: 18,
      ),
    );
  }
}

class _SidebarLeafTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final String? prefix;
  final String? badge;
  final Widget? trailing;

  const _SidebarLeafTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.prefix,
    this.badge,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.selectedBg : AppColors.surfaceBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(10, 9, 9, 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.25 : 1,
            ),
          ),
          child: Row(
            children: [
              if ((prefix ?? '').isNotEmpty) ...[
                SizedBox(
                  width: 28,
                  child: Text(
                    prefix!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? AppColors.primary : AppColors.textHint,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : iconBg,
                  borderRadius: BorderRadius.circular(9),
                  border: selected ? null : Border.all(color: AppColors.border),
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: selected ? Colors.white : iconColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if ((badge ?? '').isNotEmpty) ...[
                          _SmallBlueBadge(label: badge!),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected ? AppColors.primary : AppColors.textTitle,
                              fontSize: 12.2,
                              height: 1.12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10.5,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallBlueBadge extends StatelessWidget {
  final String label;

  const _SmallBlueBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 9,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NodeStatusDot extends StatelessWidget {
  final String status;

  const _NodeStatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final available = normalized.contains('published') ||
        normalized.contains('uploaded') ||
        normalized.contains('ready') ||
        normalized.contains('available');

    return Tooltip(
      message: status.trim().isEmpty ? 'Available' : _titleCase(status),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: available ? AppColors.successDot : AppColors.warningDot,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _MobileModuleSelector extends StatelessWidget {
  final List<StudentCourseModule> modules;
  final List<StudentCourseExam> exams;
  final String? examsLoadError;
  final int? selectedModuleId;
  final int? selectedMaterialId;
  final int? selectedExamId;
  final ValueChanged<StudentCourseModule> onSelectModule;
  final void Function(StudentCourseModule module, StudentCourseMaterial material)
      onSelectMaterial;
  final ValueChanged<StudentCourseExam> onSelectExam;
  final VoidCallback onRetryExams;

  const _MobileModuleSelector({
    required this.modules,
    required this.exams,
    required this.examsLoadError,
    required this.selectedModuleId,
    required this.selectedMaterialId,
    required this.selectedExamId,
    required this.onSelectModule,
    required this.onSelectMaterial,
    required this.onSelectExam,
    required this.onRetryExams,
  });

  @override
  Widget build(BuildContext context) {
    if (modules.isEmpty && exams.isEmpty && examsLoadError == null) {
      return const _EmptySidebarState();
    }

    return Column(
      children: [
        for (var index = 0; index < modules.length; index++) ...[
          Builder(
            builder: (_) {
              final module = modules[index];
              return _CourseModuleCard(
                module: module,
                moduleNumber: index + 1,
                expanded: true,
                selected: module.id == selectedModuleId && selectedExamId == null,
                selectedMaterialId: selectedExamId == null ? selectedMaterialId : null,
                onSelectModule: () => onSelectModule(module),
                onSelectMaterial: (material) => onSelectMaterial(module, material),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
        if (modules.isNotEmpty || exams.isNotEmpty || examsLoadError != null) ...[
          const SizedBox(height: 8),
          _CourseExamsTreeCard(
            exams: exams,
            loadError: examsLoadError,
            expanded: true,
            selectedExamId: selectedExamId,
            onToggle: () {},
            onSelectExam: onSelectExam,
            onRetry: onRetryExams,
          ),
        ],
      ],
    );
  }
}

class _ModuleNumberBadge extends StatelessWidget {
  final int number;
  final bool active;
  final bool done;

  const _ModuleNumberBadge({
    required this.number,
    required this.active,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    if (done && !active) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.successBg,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: AppColors.successDot,
          size: 15,
        ),
      );
    }

    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.infoBg : AppColors.headerBg,
        shape: BoxShape.circle,
      ),
      child: active
          ? const Icon(Icons.water_drop_rounded, color: AppColors.primary, size: 14)
          : Text(
              number.toString(),
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String label;
  final bool active;
  final bool alignRight;

  const _TabLabel({
    required this.label,
    required this.active,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      margin: EdgeInsets.only(left: alignRight ? 0 : 20, right: alignRight ? 26 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: active ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.primary : AppColors.textMuted,
          fontSize: 12.5,
          fontWeight: active ? FontWeight.w900 : FontWeight.w600,
        ),
      ),
    );
  }
}


class _TranscriptLineData {
  final String marker;
  final String text;
  final bool selected;

  const _TranscriptLineData({
    required this.marker,
    required this.text,
    this.selected = false,
  });
}

class _TranscriptLine extends StatelessWidget {
  final String marker;
  final String text;
  final bool selected;

  const _TranscriptLine({
    required this.marker,
    required this.text,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.infoBg.withOpacity(0.74) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: selected
            ? Border(left: BorderSide(color: AppColors.primary, width: 2))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              marker,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textGray,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantMessage extends StatelessWidget {
  final bool isUser;
  final Widget child;

  const _AssistantMessage({required this.isUser, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth ? constraints.maxWidth : 420.0;
        final bubbleMaxWidth = isUser ? math.min(360.0, availableWidth * 0.84) : availableWidth;

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
            child: Container(
              width: isUser ? null : double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.cardBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(12),
                ),
                border: isUser ? null : Border.all(color: AppColors.border),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _AssistantChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _AssistantChip({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;

    return Material(
      color: active ? AppColors.selectedBg : AppColors.headerBg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Text(
            label,
            style: TextStyle(
              color: active ? AppColors.primary : AppColors.textHint,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantBotIcon extends StatelessWidget {
  final double size;

  const _AssistantBotIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.smart_toy_outlined,
        color: AppColors.primary,
        size: size * 0.55,
      ),
    );
  }
}

class _GlassLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GlassLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  final String label;

  const _SoftBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LearningVisualPainter extends CustomPainter {
  const _LearningVisualPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.58);
    final linePaint = Paint()
      ..color = const Color(0xFF2DD4BF).withOpacity(0.32)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()
      ..color = const Color(0xFF67E8F9).withOpacity(0.65)
      ..style = PaintingStyle.fill;
    final formulaPaint = Paint()
      ..color = const Color(0xFF2DD4BF).withOpacity(0.16)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 22; i++) {
      final angle = -math.pi + i * math.pi / 11;
      final radius = i.isEven ? 168.0 : 132.0;
      final end = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius * 0.58,
      );
      canvas.drawLine(center, end, linePaint);
      canvas.drawCircle(end, 4.2, dotPaint);
    }

    canvas.drawCircle(center, 9, Paint()..color = Colors.white.withOpacity(0.55));

    final path = Path()
      ..moveTo(size.width * 0.16, size.height * 0.30)
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.18,
        size.width * 0.34,
        size.height * 0.28,
      )
      ..moveTo(size.width * 0.65, size.height * 0.24)
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.12,
        size.width * 0.86,
        size.height * 0.26,
      )
      ..moveTo(size.width * 0.10, size.height * 0.75)
      ..lineTo(size.width * 0.28, size.height * 0.75)
      ..moveTo(size.width * 0.72, size.height * 0.78)
      ..lineTo(size.width * 0.90, size.height * 0.78);

    canvas.drawPath(path, formulaPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CourseWorkspaceLoading extends StatelessWidget {
  const _CourseWorkspaceLoading();

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
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 14),
              Text(
                'Loading course content...',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseRouteError extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onBack;
  final VoidCallback? onRetry;

  const _CourseRouteError({
    required this.title,
    required this.message,
    required this.onBack,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowThin,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.dangerText,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('My Courses'),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLessonState extends StatelessWidget {
  final int courseId;
  final VoidCallback onRefresh;

  const _EmptyLessonState({required this.courseId, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, color: AppColors.textMuted, size: 42),
          const SizedBox(height: 14),
          Text(
            'No course content yet',
            style: TextStyle(
              color: AppColors.textTitle,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Only published modules and uploaded materials are visible to students. Ask the instructor to publish the module and make sure materials are uploaded, not still processing.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _EmptySidebarState extends StatelessWidget {
  const _EmptySidebarState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_off_outlined, color: AppColors.textMuted, size: 30),
          const SizedBox(height: 10),
          Text(
            'No published content',
            style: TextStyle(
              color: AppColors.textTitle,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Published modules with uploaded materials will appear here. Draft modules and processing files are hidden from students by the backend.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


List<_TranscriptLineData> _lessonTranscriptLines(
  StudentCourseModule module,
  StudentCourseMaterial? material,
) {
  if (material != null && material.transcriptSegments.isNotEmpty) {
    return material.transcriptSegments
        .map(
          (segment) => _TranscriptLineData(
            marker: segment.marker,
            text: segment.text,
            selected: segment == material.transcriptSegments.first,
          ),
        )
        .toList(growable: false);
  }

  if (material == null) {
    return [
      _TranscriptLineData(
        marker: 'Module',
        text: module.safeDescription,
        selected: true,
      ),
      _TranscriptLineData(
        marker: 'Status',
        text: module.isPublished ? 'Published' : 'Draft',
      ),
    ];
  }

  final lines = <_TranscriptLineData>[
    _TranscriptLineData(
      marker: _titleCase(material.safeType),
      text: (material.summary ?? '').trim().isNotEmpty
          ? material.summary!.trim()
          : material.safeDescription,
      selected: true,
    ),
    _TranscriptLineData(
      marker: 'Status',
      text: _titleCase(material.safeStatus),
    ),
  ];

  if (material.fileName != null) {
    lines.add(
      _TranscriptLineData(marker: 'File', text: material.fileName!),
    );
  }
  if (material.fileSize != null) {
    lines.add(
      _TranscriptLineData(marker: 'Size', text: _formatBytes(material.fileSize!)),
    );
  }
  if (material.durationSeconds != null) {
    lines.add(
      _TranscriptLineData(
        marker: 'Duration',
        text: _formatDuration(material.durationSeconds!),
      ),
    );
  }
  if (material.pageCount != null) {
    lines.add(
      _TranscriptLineData(marker: 'Pages', text: material.pageCount.toString()),
    );
  }

  return lines;
}

IconData _materialIcon(StudentCourseMaterial? material) {
  if (material == null) return Icons.play_circle_outline_rounded;

  final type = material.type.trim().toLowerCase();
  final mime = (material.mimeType ?? '').trim().toLowerCase();

  if (type.contains('video') || mime.startsWith('video/')) {
    return Icons.play_circle_outline_rounded;
  }
  if (type.contains('quiz') || type.contains('exam')) {
    return Icons.assignment_outlined;
  }
  if (type.contains('presentation') || type.contains('slide')) {
    return Icons.slideshow_outlined;
  }
  if (type.contains('link')) {
    return Icons.link_rounded;
  }
  if (type.contains('pdf') || mime.contains('pdf')) {
    return Icons.picture_as_pdf_outlined;
  }
  return Icons.insert_drive_file_outlined;
}

bool _isPdfMaterial(StudentCourseMaterial material) {
  final type = material.type.trim().toLowerCase();
  final mime = (material.mimeType ?? '').trim().toLowerCase();
  final fileName = (material.fileName ?? '').trim().toLowerCase();
  return type.contains('pdf') || mime.contains('pdf') || fileName.endsWith('.pdf');
}

String _formatScore(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}


String _formatElapsedTime(int seconds) {
  if (seconds <= 0) return '0m 0s';
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remainingSeconds = seconds % 60;

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }
  if (minutes > 0) {
    return '${minutes}m ${remainingSeconds}s';
  }
  return '${remainingSeconds}s';
}

String _formatResultDate(DateTime? value) {
  if (value == null) return 'not submitted yet';
  final local = value.toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final month = months[(local.month - 1).clamp(0, 11)];
  final minute = local.minute.toString().padLeft(2, '0');
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$month ${local.day}, ${local.year} • $hour12:$minute $period';
}

String _shortText(String value, int maxLength) {
  final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.length <= maxLength) return normalized;
  if (maxLength <= 1) return normalized.substring(0, maxLength);
  return '${normalized.substring(0, maxLength - 1).trimRight()}…';
}

String _formatDateTime(DateTime? value) {
  if (value == null) return 'Not set';
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

String _examAvailabilityLabel(StudentCourseExam exam) {
  if (!exam.hasAvailabilityWindow) {
    return exam.isAvailable
        ? 'This exam is published and available now.'
        : 'This exam is currently unavailable.';
  }

  final from = _formatDateTime(exam.availableFrom);
  final to = _formatDateTime(exam.availableTo);
  if (exam.availableFrom != null && exam.availableTo != null) {
    return exam.isAvailable
        ? 'Available now until $to.'
        : 'Availability window: $from → $to.';
  }
  if (exam.availableFrom != null) {
    return exam.isAvailable
        ? 'Available since $from.'
        : 'Available from $from.';
  }
  return exam.isAvailable
      ? 'Available until $to.'
      : 'Availability ended at $to.';
}

String _lessonTitle(
  StudentCourseModule module,
  StudentCourseMaterial? material,
) {
  if (material == null) return module.safeTitle;

  final index = module.materials.indexWhere((item) => item.id == material.id);
  final lessonNumber = index < 0 ? '' : '${module.orderIndex + 1}.${index + 1} ';
  return '$lessonNumber${material.safeTitle}';
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;

  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  final fixed = value >= 10 || unitIndex == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$fixed ${units[unitIndex]}';
}

String _formatDuration(int seconds) {
  if (seconds <= 0) return '0m';
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;

  if (minutes >= 60) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  if (remainingSeconds == 0) return '${minutes}m';
  return '${minutes}m ${remainingSeconds}s';
}

String _titleCase(String value) {
  final normalized = value.replaceAll('_', ' ').trim();
  if (normalized.isEmpty) return 'Not provided';

  return normalized
      .split(RegExp(r'\s+'))
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      })
      .join(' ');
}

String _displayName() {
  final name = (UserStorage.userMap?['full_name'] ?? '').toString().trim();
  if (name.isNotEmpty) return name;
  return 'Student';
}

String _displaySubtitle() {
  final orgs = UserStorage.organizations;
  if (orgs.isNotEmpty) {
    final orgName = (orgs.first['name'] ?? '').toString().trim();
    if (orgName.isNotEmpty) return orgName;
  }
  return 'Student Portal';
}

