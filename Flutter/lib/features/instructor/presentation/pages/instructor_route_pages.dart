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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Home  >  Instructor Dashboard",
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Welcome back, Professor Anderson",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const Text(
            "Here's what's happening with your AI study assistant today.",
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          const Row(
            children: [
              Expanded(
                child: DashboardStatCard(
                  icon: Icons.folder_open_rounded,
                  iconColor: Color(0xFF3B82F6),
                  title: "Uploaded Materials",
                  value: "12 Files",
                  trend: "+2",
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: DashboardStatCard(
                  icon: Icons.lightbulb_outline_rounded,
                  iconColor: Color(0xFFA855F7),
                  title: "Extracted Topics",
                  value: "45 Concepts",
                  trend: "+5",
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: DashboardStatCard(
                  icon: Icons.assignment_outlined,
                  iconColor: Color(0xFFF59E0B),
                  title: "Generated Questions",
                  value: "120 Items",
                  trend: "+20",
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: DashboardStatCard(
                  icon: Icons.people_outline_rounded,
                  iconColor: Color(0xFF10B981),
                  title: "Active Students",
                  value: "85 Enrolled",
                  trend: "+3",
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: RecentActivityWidget()),
              SizedBox(width: 32),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    QuickActionsWidget(),
                    SizedBox(height: 32),
                    SystemUsageWidget(),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Home  >  Courses Management",
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "My Courses",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    "Manage your curriculum and student cohorts.",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                // عند الضغط هنا، يتم تفعيل واجهة الـ Steps
                onPressed: () {
                  setState(() {
                    isCreatingExam = true;
                    currentStep = 1;
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  "Create New Course",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // كروت الإحصائيات
          const Row(
            children: [
              Expanded(
                child: CourseStatCard(
                  title: "TOTAL COURSES",
                  value: "12",
                  icon: Icons.book_outlined,
                  iconColor: Colors.blue,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: CourseStatCard(
                  title: "ACTIVE STUDENTS",
                  value: "345",
                  icon: Icons.people_outline,
                  iconColor: Colors.green,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: CourseStatCard(
                  title: "PENDING GRADING",
                  value: "28",
                  icon: Icons.assignment_outlined,
                  iconColor: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const CourseFilterBar(),
          const SizedBox(height: 24),
          // شبكة الكورسات
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1.1,
            children: [
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MaterialsExplorerPage(),
                  ),
                ),
                borderRadius: BorderRadius.circular(16),
                child: const CourseItemCard(
                  title: "Advanced Machine Learning",
                  code: "CS-405",
                  semester: "Fall 2023",
                  status: "Active",
                  statusColor: Color(0xFF22C55E),
                  studentsCount: 45,
                  modulesCount: 8,
                ),
              ),
              const CourseItemCard(
                title: "Introduction to Robotics",
                code: "ENG-201",
                semester: "Spring 2024",
                status: "Draft",
                statusColor: Color(0xFFF59E0B),
                studentsCount: 0,
                modulesCount: 2,
              ),
              const CourseItemCard(
                title: "Algorithms",
                code: "CS-101",
                semester: "Fall 2023",
                status: "Active",
                statusColor: Color(0xFF22C55E),
                studentsCount: 120,
                modulesCount: 14,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------
// SECTION: Quizzes Route Page 
// ----------------------------------------------------------------

class InstructorQuizzesRoutePage extends StatelessWidget {
  const InstructorQuizzesRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPanel(
      icon: Icons.quiz_outlined,
      title: "Quizzes",
      subtitle: "View and manage your student assessments.",
      hint: "Quizzes List View.",
    );
  }
}
// ----------------------------------------------------------------
// OTHER PAGES (Question Bank, Help, Settings, etc.)
// ----------------------------------------------------------------
class InstructorQuestionBankRoutePage extends StatelessWidget {
  const InstructorQuestionBankRoutePage({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderPanel(
    icon: Icons.inventory_2_outlined,
    title: "Question Bank",
    subtitle: "Create and organize questions.",
    hint: "API Connect.",
  );
}

class InstructorHelpRoutePage extends StatelessWidget {
  const InstructorHelpRoutePage({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderPanel(
    icon: Icons.help_outline_rounded,
    title: "Help & Support",
    subtitle: "FAQs and tickets.",
    hint: "Support module.",
  );
}

class InstructorSettingsRoutePage extends StatelessWidget {
  const InstructorSettingsRoutePage({super.key});
  @override
  Widget build(BuildContext context) => const SettingsPage();
}

class InstructorNotificationsRoutePage extends StatelessWidget {
  const InstructorNotificationsRoutePage({super.key});
  @override
  Widget build(BuildContext context) => const NotificationsPage();
}

class _PlaceholderPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String hint;
  const _PlaceholderPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEEF2F6)),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(subtitle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
