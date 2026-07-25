import 'package:flutter/material.dart';
import 'package:learnova/core/storage/user_storage.dart';
import 'package:learnova/core/ui/toast.dart';
import 'package:learnova/core/network/error_mapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:learnova/features/instructor/presentation/widgets/create_course_dialog.dart';
import 'package:learnova/features/instructor/presentation/widgets/invite_students_dialog.dart';
import 'package:learnova/features/instructor/data/learning_outcomes_cache.dart';
import 'package:learnova/features/instructor/data/learning_outcomes_models.dart';
import 'package:learnova/features/instructor/data/modules_materials_providers.dart';
import 'package:learnova/features/instructor/presentation/widgets/instructor_course_widgets.dart';
import 'package:learnova/features/instructor/presentation/widgets/instructor_dashboard_content.dart';

import '../controllers/instructor_courses_controller.dart';

// ----------------------------------------------------------------
// SECTION: Dashboard Route Page
// ----------------------------------------------------------------
class InstructorDashboardRoutePage extends StatelessWidget {
  const InstructorDashboardRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    final name = (UserStorage.userMap?['full_name'] ?? '').toString().trim();
    final displayName = name.isNotEmpty ? name : 'Professor';
    return InstructorDashboardContent(userName: displayName);
  }
}

// ----------------------------------------------------------------
// SECTION: Courses Route Page (Backend-ready)
// ----------------------------------------------------------------
class InstructorCourseRoutePage extends ConsumerStatefulWidget {
  const InstructorCourseRoutePage({super.key});

  @override
  ConsumerState<InstructorCourseRoutePage> createState() =>
      _InstructorCourseRoutePageState();
}

class _InstructorCourseRoutePageState extends ConsumerState<InstructorCourseRoutePage> {
  @override
  void initState() {
    super.initState();
    // Load my courses once when entering the page
    Future.microtask(() => ref
        .read(instructorCoursesControllerProvider.notifier)
        .load(force: true),);
  }

  Future<void> _openCreateCourse() async {
    final result = await showDialog<CreateCourseDialogResult>(
      context: context,
      builder: (_) => const CreateCourseDialog(),
    );

    if (result == null) return;

    // 1) Create course first (backend returns course with id).
    // Controller stores any backend validation/network error in page state.
    final created = await (() async {
      try {
        return await ref
            .read(instructorCoursesControllerProvider.notifier)
            .createCourse(result.request);
      } catch (_) {
        return null;
      }
    })();

    if (created == null) return;

    final courseId = created.id;

    if (courseId <= 0) {
      await ref.read(instructorCoursesControllerProvider.notifier).load(force: true);
      return;
    }

    // 2) Upload selected cover image after the course exists and has an id.
    if ((result.coverBytes?.isNotEmpty ?? false)) {
      try {
        await ref
            .read(instructorCoursesControllerProvider.notifier)
            .uploadCourseCoverById(
              courseId: courseId,
              bytes: result.coverBytes!,
              contentType: result.coverContentType,
              filename: result.coverFilename ?? 'course-cover.jpg',
              recoverExistingObjectOnDuplicate: true,
            );
      } catch (error) {
        if (mounted) {
          AppToast.error(
            context,
            title: 'Cover upload failed',
            message: 'Course created, but the cover image could not be uploaded. ${mapApiFailure(error).message}',
          );
        }
      }
    }

    // 3) Persist initial learning outcomes through the backend so the
    // dedicated Outcomes tab stays consistent after refresh/navigation.
    if (result.learningOutcomes.isNotEmpty) {
      var failedOutcomes = 0;
      final savedOutcomes = <LearningOutcome>[];
      final api = ref.read(learningOutcomesApiProvider);

      for (final outcome in result.learningOutcomes) {
        try {
          final saved = await api.createOutcome(
            courseId: courseId,
            outcome: outcome.copyWith(courseId: courseId),
          );
          savedOutcomes.add(saved);
        } catch (_) {
          failedOutcomes += 1;
        }
      }

      if (savedOutcomes.isNotEmpty) {
        LearningOutcomesCache.save(courseId: courseId, outcomes: savedOutcomes);
      }

      if (failedOutcomes > 0 && mounted) {
        AppToast.warning(
          context,
          title: 'Learning outcomes not fully saved',
          message:
              '$failedOutcomes learning outcome${failedOutcomes == 1 ? '' : 's'} could not be saved. You can add them from the Outcomes tab.',
        );
      }
    }

    // 4) If course is PRIVATE (needs invites), open upload dialog with courseId
    if (!mounted) return;
    if (result.needsInvites) {
      await showDialog<bool>(
        context: context,
        builder: (_) => InviteStudentsDialog(courseId: courseId),
      );
    }

    // 5) Refresh courses list after creation, cover upload, and possible invites
    await ref.read(instructorCoursesControllerProvider.notifier).load(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(instructorCoursesControllerProvider);

    final controller = ref.read(instructorCoursesControllerProvider.notifier);

    return InstructorCourseContent(
      loading: state.loading,
      errorText: state.error,
      courses: state.items,
      onRefresh: () => controller.load(force: true),
      onCreateNewCourse: _openCreateCourse,
      onUpdateCourse: (course, payload) => controller.updateCourse(
        course: course,
        payload: payload,
      ),
      onPublishCourse: controller.publishCourse,
      onUploadCover: controller.uploadCourseCover,
    );
  }
}
