import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../data/courses_models.dart';
import '../course_outcomes_panel.dart';

class CourseOutcomesTab extends StatelessWidget {
  final MyCourseItem course;

  const CourseOutcomesTab({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.pageBg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1480),
            child: CourseOutcomesManager(courseId: course.id, embedded: true),
          ),
        ),
      ),
    );
  }
}
