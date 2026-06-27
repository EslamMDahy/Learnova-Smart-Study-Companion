import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_sidebar.dart';
import '../admin_tabs.dart';

class AdminSidebarWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool isCollapsed;
  final VoidCallback? onToggle;

  const AdminSidebarWidget({
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
      portalSubtitle: 'ADMIN Portal',
      mainItems: const [
        AppSidebarItem(
          icon: Icons.grid_view_rounded,
          title: 'User Management',
          index: AdminTabs.users,
        ),
        AppSidebarItem(
          icon: Icons.group_add_rounded, 
          title: 'Join Requests',
          index: AdminTabs.joinRequests,
        ),
        AppSidebarItem(
          icon: Icons.workspace_premium_outlined,
          title: 'Upgrade Plans', 
          index: AdminTabs.upgradePlans,
        ),
      ],
      bottomItems: const [
        AppSidebarItem(
          icon: Icons.settings_outlined,
          title: 'Settings',
          index: AdminTabs.settings,
        ),
        AppSidebarItem(
          icon: Icons.help_outline_rounded,
          title: 'Help & Support',
          index: AdminTabs.help,
        ),
      ],
    );
  }
}
