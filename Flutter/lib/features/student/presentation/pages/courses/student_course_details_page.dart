import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

part 'student_course_details_workspace.dart';
part 'student_course_details_result_review.dart';
part 'student_course_details_assistant.dart';
part 'student_course_details_sidebar.dart';
part 'student_course_details_shared_widgets.dart';


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

