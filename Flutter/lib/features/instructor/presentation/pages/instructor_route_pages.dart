import 'package:flutter/material.dart';
import 'package:learnova/core/storage/user_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:learnova/features/instructor/presentation/widgets/create_course_dialog.dart';
import 'package:learnova/features/instructor/presentation/widgets/invite_students_dialog.dart';
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

class _InstructorCourseRoutePageState
    extends ConsumerState<InstructorCourseRoutePage> {
  @override
  void initState() {
    super.initState();
    // Load my courses once when entering the page.
    Future.microtask(() => ref
        .read(instructorCoursesControllerProvider.notifier)
        .load(force: true));
  }

  Future<void> _openCreateCourse() async {
    final result = await showDialog<CreateCourseDialogResult>(
      context: context,
      builder: (_) => const CreateCourseDialog(),
    );

    if (result == null) return;

    final created = await ref
        .read(instructorCoursesControllerProvider.notifier)
        .createCourse(result.request);

    final courseIdNum = created['id'];
    final courseId =
        (courseIdNum is num) ? courseIdNum.toInt() : int.tryParse('$courseIdNum');

    if (courseId == null) {
      await ref.read(instructorCoursesControllerProvider.notifier).load(force: true);
      return;
    }

    if (result.needsInvites) {
      await showDialog<bool>(
        context: context,
        builder: (_) => InviteStudentsDialog(courseId: courseId),
      );
    }

    await ref.read(instructorCoursesControllerProvider.notifier).load(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(instructorCoursesControllerProvider);

    return InstructorCourseContent(
      loading: state.loading,
      errorText: state.error,
      courses: state.items,
      onRefresh: () => ref
          .read(instructorCoursesControllerProvider.notifier)
          .load(force: true),
      onCreateNewCourse: _openCreateCourse,
    );
  }
}
