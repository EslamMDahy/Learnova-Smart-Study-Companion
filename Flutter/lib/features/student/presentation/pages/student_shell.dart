import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learnova/core/routing/routes.dart';

import '../../../../core/storage/user_storage.dart';
import '../../../../core/ui/toast.dart';
import '../../../../features/auth/data/auth_providers.dart';

import '../../../../shared/widgets/base_dashboard_shell.dart';
import '../../../../shared/widgets/top_header.dart';

import '../widgets/student_sidebar.dart';

class StudentShell extends ConsumerStatefulWidget {
  final Widget child;

  const StudentShell({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
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

  String _displayName() {
    final name = (UserStorage.userMap?['full_name'] ?? '').toString().trim();

    if (name.isNotEmpty) return name;

    return 'Student';
  }

  String _displaySubtitle() {
    final orgs = UserStorage.organizations;

    if (orgs.isNotEmpty) {
      final orgName = (orgs.first['name'] ?? '').toString().trim();

      if (orgName.isNotEmpty) return orgName;
    }

    return 'Student Portal';
  }

  int _selectedIndexFromPath(String path) {
    if (path.startsWith(Routes.studentDashboard)) {
      return 0;
    }

    if (path.startsWith(Routes.studentCourses)) {
      return 1;
    }

    if (path.startsWith(Routes.studentDiscoverCourses)) {
      return 2;
    }

    if (path.startsWith(Routes.studentSettings)) {
      return 3;
    }

    if (path.startsWith(Routes.studentHelp)) {
      return 4;
    }

    return 0;
  }


  Future<void> _logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
      if (!mounted) return;
      context.go(Routes.login);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        title: 'Logout failed',
        message: e.toString(),
      );
    }
  }

  void _goByIndex(int index) {
    switch (index) {
      case 0:
        context.go(Routes.studentDashboard);
        return;

      case 1:
        context.go(Routes.studentCourses);
        return;

      case 2:
        context.go(Routes.studentDiscoverCourses);
        return;

      case 3:
        context.go(Routes.studentSettings);
        return;

      case 4:
        context.go(Routes.studentHelp);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;

    // The course workspace has its own Figma layout: course-content sidebar,
    // learning area, and study assistant panel. Keep it outside the default
    // student navigation shell so the page matches the dedicated design.
    if (path == Routes.studentCourseDetails ||
        path == Routes.studentExamAttempt ||
        path == Routes.studentExamResult) {
      return widget.child;
    }

    return ValueListenableBuilder<int>(
      valueListenable: UserStorage.listenable as ValueNotifier<int>,
      builder: (context, _, __) {
        return BaseDashboardShell(
          wrapChild: false,

          /// SIDEBAR
          sidebarBuilder: (isCollapsed, toggleSidebar) => StudentSidebarWidget(
            selectedIndex: _selectedIndexFromPath(path),
            onItemSelected: _goByIndex,
            isCollapsed: isCollapsed,
            onToggle: toggleSidebar,
          ),

          /// HEADER
          header: TopHeaderWidget(
            searchController: _search,
            onSearchChanged: (_) => setState(() {}),
            searchHint: 'Search topics, questions, or student',
            userName: _displayName(),
            userSubtitle: _displaySubtitle(),
            avatarUrl: UserStorage.avatarUrl,
            onNotificationsTap: () {
              context.go(Routes.studentNotifications);
            },
            onSettings: () {
              context.go(Routes.studentSettings);
            },
            onLogout: () async => _logout(),
          ),

          /// CONTENT
          child: widget.child,
        );
      },
    );
  }
}
