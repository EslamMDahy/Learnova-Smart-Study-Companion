import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_sidebar.dart';

class StudentSidebarWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool isCollapsed;
  final VoidCallback? onToggle;

  const StudentSidebarWidget({
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
      portalSubtitle: 'STUDENT PORTAL',
      mainItems: const [
        AppSidebarItem(
          icon: Icons.grid_view_rounded,
          title: 'Dashboard',
          index: 0,
        ),
        AppSidebarItem(
          icon: Icons.menu_book_rounded,
          title: 'My Courses',
          index: 1,
        ),
        AppSidebarItem(
          icon: Icons.travel_explore_rounded,
          title: 'Discover Courses',
          index: 2,
        ),
      ],
      bottomItems: const [
        AppSidebarItem(
          icon: Icons.settings_outlined,
          title: 'Settings',
          index: 3,
        ),
        AppSidebarItem(
          icon: Icons.help_outline_rounded,
          title: 'Help & Support',
          index: 4,
        ),
      ],
    );
  }
}
