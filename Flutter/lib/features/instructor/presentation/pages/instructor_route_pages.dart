import 'package:flutter/material.dart';
import '../../../../shared/pages/notifications_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class InstructorDashboardRoutePage extends StatelessWidget {
  const InstructorDashboardRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPanel(
      icon: Icons.grid_view_rounded,
      title: "Dashboard",
      subtitle: "Quick overview for your teaching workspace.",
      hint: "Connect this view to instructor dashboard APIs.",
    );
  }
}

class InstructorCourseRoutePage extends StatelessWidget {
  const InstructorCourseRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPanel(
      icon: Icons.menu_book_rounded,
      title: "Course",
      subtitle: "Manage your courses, lessons, and content.",
      hint: "Connect this view to courses APIs.",
    );
  }
}

class InstructorQuestionBankRoutePage extends StatelessWidget {
  const InstructorQuestionBankRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPanel(
      icon: Icons.inventory_2_outlined,
      title: "Question Bank",
      subtitle: "Create and organize questions by topics and difficulty.",
      hint: "Connect this view to question-bank APIs.",
    );
  }
}

class InstructorQuizzesRoutePage extends StatelessWidget {
  const InstructorQuizzesRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPanel(
      icon: Icons.quiz_outlined,
      title: "Quizzes",
      subtitle: "Build quizzes and assign them to your students.",
      hint: "Connect this view to quizzes APIs.",
    );
  }
}

class InstructorHelpRoutePage extends StatelessWidget {
  const InstructorHelpRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPanel(
      icon: Icons.help_outline_rounded,
      title: "Help & Support",
      subtitle: "FAQs, documentation, and support tickets.",
      hint: "Connect this view to support/ticketing module.",
    );
  }
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

// ✅ نفس Placeholder اللي عندك (انسخته زي ما هو)
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEEF2F6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hint,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
