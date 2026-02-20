import 'package:flutter/material.dart';
import 'package:learnova/features/instructor/presentation/widgets/create_course_dialog.dart';
import 'package:learnova/features/instructor/presentation/widgets/create_exam_content.dart';
import 'package:learnova/features/instructor/presentation/widgets/create_exam_content2.dart';
import 'package:learnova/features/instructor/presentation/widgets/instructor_course_widgets.dart';
import 'package:learnova/features/instructor/presentation/widgets/instructor_dashboard_content.dart';
import 'package:learnova/features/instructor/presentation/widgets/materials_explorer_page.dart';
// استيراد الكود الجديد
import '../../../../shared/pages/notifications_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';

// ----------------------------------------------------------------
// SECTION: Dashboard Route Page
// ----------------------------------------------------------------
class InstructorDashboardRoutePage extends StatelessWidget {
  const InstructorDashboardRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const InstructorDashboardContent();
  }
}

// ----------------------------------------------------------------
// SECTION: Course Management Page
// ----------------------------------------------------------------
class InstructorCourseRoutePage extends StatefulWidget {
  const InstructorCourseRoutePage({super.key});

  @override
  State<InstructorCourseRoutePage> createState() =>
      _InstructorCourseRoutePageState();
}

class _InstructorCourseRoutePageState extends State<InstructorCourseRoutePage> {
  // متغير للتحكم هل نعرض القائمة الرئيسية أم واجهة الإنشاء
  bool isCreatingExam = false;
  int currentStep = 1;

  @override
  Widget build(BuildContext context) {
    // إذا كان المدرس ضغط على إنشاء، نعرض واجهة الخطوات
    if (isCreatingExam) {
      return CreateExamContent(
        key: ValueKey('course_step_$currentStep'),
        currentStep: currentStep,
        onNext: () {
          if (currentStep < 3) {
            setState(() => currentStep++);
          } else {
            // هنا يمكنك إنهاء العملية والعودة للقائمة
            setState(() {
              isCreatingExam = false;
              currentStep = 1;
            });
          }
        },
        onBack: () {
          if (currentStep > 1) {
            setState(() => currentStep--);
          } else {
            // إذا رجع من الخطوة الأولى، نعود للقائمة الرئيسية
            setState(() => isCreatingExam = false);
          }
        },
      );
    }

    // الواجهة الافتراضية (قائمة الكورسات)
    return InstructorCourseContent(
      onCreateNewCourse: () {
        showDialog(
          context: context,
          builder: (_) => const CreateCourseDialog(),
        );
      },
    );
  }
}
