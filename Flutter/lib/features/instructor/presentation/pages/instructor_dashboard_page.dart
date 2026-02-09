import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/user_storage.dart';
import '../../../../core/ui/toast.dart';

import '../../../../shared/pages/notifications_page.dart';
import '../../../../shared/pages/settings_page.dart';
import '../../../../shared/widgets/base_dashboard_shell.dart';
import '../../../../shared/widgets/top_header.dart';

import '../instructor_tabs.dart';
import '../widgets/sidebar.dart';

class InstructorDashboardPage extends ConsumerStatefulWidget {
  const InstructorDashboardPage({super.key});

  @override
  ConsumerState<InstructorDashboardPage> createState() =>
      _InstructorDashboardPageState();
}

class _InstructorDashboardPageState
    extends ConsumerState<InstructorDashboardPage> {
  int _selectedIndex = InstructorTabs.dashboard;
  int _viewIndex = InstructorViews.tabs;

  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    FocusScope.of(context).unfocus();

    if (index == InstructorTabs.settings) {
      _openSettings();
      setState(() {
        _selectedIndex = InstructorTabs.settings;
      });
      return;
    }

    setState(() {
      _selectedIndex = index;
      _viewIndex = InstructorViews.tabs;
    });
  }

  void _openNotifications() {
    FocusScope.of(context).unfocus();
    setState(() => _viewIndex = InstructorViews.notifications);
  }

  void _openSettings() {
    FocusScope.of(context).unfocus();
    setState(() => _viewIndex = InstructorViews.settings);
  }

  String _displayName() {
    final name = (UserStorage.userMap?['full_name'] ?? '').toString().trim();
    return name.isEmpty ? "Instructor" : name;
  }

  Future<void> _logout() async {
    try {
      TokenStorage.clear();
      UserStorage.clear();
      if (!mounted) return;
      context.go(Routes.login);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        title: "Logout failed",
        message: e.toString(),
        icon: Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName();

    return BaseDashboardShell(
      asideWidth: 288,
      contentMaxWidth: 1400,
      contentPadding: const EdgeInsets.symmetric(horizontal: 116, vertical: 32),
      backgroundColor: const Color(0xFFF6F7F8),
      dividerColor: const Color(0xFFEDF2F7),

      sidebar: InstructorSidebarWidget(
        selectedIndex: _selectedIndex,
        onItemSelected: _goToTab,
      ),

      header: TopHeaderWidget(
        searchController: _search,
        onSearchChanged: (_) => setState(() {}),
        searchHint: "Search your courses, lessons, or students...",
        userName: displayName,
        userSubtitle: "Instructor",
        notificationsCount: 0,
        onNotificationsTap: _openNotifications,
        onSettings: _openSettings,
        onLogout: _logout,
      ),

      child: IndexedStack(
        index: _viewIndex,
        children: [
          _buildTabsContent(),
          const NotificationsPage(),
          const SettingsPage(),
        ],
      ),
    );
  }

  Widget _buildTabsContent() {
    return IndexedStack(
      index: _effectiveTabIndex(),
      children: const [
        _PlaceholderPanel(
          icon: Icons.grid_view_rounded,
          title: "Dashboard",
          subtitle: "Quick overview for your teaching workspace.",
          hint: "Connect this view to instructor dashboard APIs.",
        ),
        _PlaceholderPanel(
          icon: Icons.menu_book_rounded,
          title: "Course",
          subtitle: "Manage your courses, lessons, and content.",
          hint: "Connect this view to courses APIs.",
        ),
        _PlaceholderPanel(
          icon: Icons.inventory_2_outlined,
          title: "Question Bank",
          subtitle: "Create and organize questions by topics and difficulty.",
          hint: "Connect this view to question-bank APIs.",
        ),
        _PlaceholderPanel(
          icon: Icons.quiz_outlined,
          title: "Quizzes",
          subtitle: "Build quizzes and assign them to your students.",
          hint: "Connect this view to quizzes APIs.",
        ),
        _PlaceholderPanel(
          icon: Icons.help_outline_rounded,
          title: "Help & Support",
          subtitle: "FAQs, documentation, and support tickets.",
          hint: "Connect this view to support/ticketing module.",
        ),
      ],
    );
  }

  /// Sidebar indices:
  /// 0 dashboard, 1 course, 2 questionBank, 3 quizzes, 4 settings(view), 5 help
  /// Tabs stack indices:
  /// 0 dashboard, 1 course, 2 questionBank, 3 quizzes, 4 help
  int _effectiveTabIndex() {
    if (_selectedIndex == InstructorTabs.help) return 4;

    if (_selectedIndex >= InstructorTabs.dashboard &&
        _selectedIndex <= InstructorTabs.quizzes) {
      return _selectedIndex; // 0..3 maps directly
    }

    // Settings selected: keep dashboard visible underneath (optional)
    return 0;
  }
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
