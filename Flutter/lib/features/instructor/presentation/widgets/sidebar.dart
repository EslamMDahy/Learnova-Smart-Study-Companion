import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_sidebar.dart';
import '../instructor_tabs.dart';

class InstructorSidebarWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool isCollapsed;
  final VoidCallback? onToggle;

  const InstructorSidebarWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AppSidebar(
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
      isCollapsed: isCollapsed,
      onToggle: onToggle,
      portalSubtitle: 'INSTRUCTOR Portal',
      mainItems: const [
        AppSidebarItem(icon: Icons.grid_view_rounded, title: 'Dashboard', index: InstructorTabs.dashboard),
        AppSidebarItem(icon: Icons.menu_book_rounded, title: 'My Courses', index: InstructorTabs.course),
        AppSidebarItem(icon: Icons.document_scanner_outlined, title: 'Exam Correction', index: InstructorTabs.examCorrection),
        AppSidebarItem(icon: Icons.assignment_turned_in_outlined, title: 'Exams', index: InstructorTabs.quizzes),
      ],
      bottomItems: const [
        AppSidebarItem(icon: Icons.settings_outlined, title: 'Settings', index: InstructorTabs.settings),
        AppSidebarItem(icon: Icons.help_outline_rounded, title: 'Help & Support', index: InstructorTabs.help),
      ],
    );
  }
}
