import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/user_storage.dart';
import '../../../../core/ui/toast.dart';
import '../../../../core/ui/layout/base_dashboard_shell.dart';

import '../../../../shared/pages/settings_page.dart';
import '../../../../shared/pages/notifications_page.dart';

import '../controllers/admin_dashboard_controller.dart';
import '../controllers/admin_dashboard_state.dart';

import '../widgets/create_org_dialog.dart';
import '../widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';
import '../widgets/empty_org_state.dart';
import '../widgets/user_management_content.dart';
import '../widgets/join_requests_content.dart';
import '../widgets/upgrade_plans_content.dart';

import 'package:go_router/go_router.dart';
import '../../../../core/routing/routes.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  int selectedIndex = 0;
  String? _lastToastMsg;

  // Admin tabs indexes
  static const int _idxUsers = 0;
  static const int _idxUpgrade = 2;
  static const int _idxSettingsTab = 3;
  static const int _idxHelp = 4;

  // Global views indexes inside ONE IndexedStack
  static const int _viewAdminTabs = 0;
  static const int _viewNotifications = 1;
  static const int _viewSettings = 2;

  int _viewIndex = _viewAdminTabs;

  ProviderSubscription<AdminDashboardState>? _errSub;

  @override
  void initState() {
    super.initState();

    _errSub = ref.listenManual<AdminDashboardState>(
      adminDashboardControllerProvider,
      (prev, next) {
        final err = next.error;
        if (err != null && err != _lastToastMsg) {
          _lastToastMsg = err;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            AppToast.show(
              context,
              title: "Something went wrong",
              message: err,
              icon: Icons.warning_amber_rounded,
            );

            ref.read(adminDashboardControllerProvider.notifier).clearError();
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _errSub?.close();
    super.dispose();
  }

  void _goToAdminTab(int index) {
    // ✅ يقلل التأخير (خصوصًا لو فيه TextField واخد focus)
    FocusScope.of(context).unfocus();

    final state = ref.read(adminDashboardControllerProvider);
    final orgId = _resolveOrgId(state);
    final hasOrg = orgId.isNotEmpty;

    if (!_canAccessTab(index, hasOrg)) {
      AppToast.show(
        context,
        title: "Action needed",
        message: "Create an organization first to unlock this section.",
        icon: Icons.lock_outline_rounded,
      );
      return;
    }

    setState(() {
      // ✅ لو كنت في notifications/settings ودوست نفس التاب، رجّعه للمحتوى
      if (index == selectedIndex) {
        _viewIndex = _viewAdminTabs;
        return;
      }

      selectedIndex = index;
      _viewIndex = _viewAdminTabs;
    });
  }

  void _openNotifications() {
    FocusScope.of(context).unfocus();
    setState(() => _viewIndex = _viewNotifications);
  }

  void _openSettings() {
    FocusScope.of(context).unfocus();
    setState(() {
      // اختياري: تخلي السايدبار يلمّح إنك على Settings tab
      selectedIndex = _idxSettingsTab;
      _viewIndex = _viewSettings;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminDashboardControllerProvider);
    final ctrl = ref.read(adminDashboardControllerProvider.notifier);

    final orgId = _resolveOrgId(state);
    final hasOrg = orgId.isNotEmpty;

    final displayName = _readDisplayName() ?? "Admin";

    return BaseDashboardShell(
      asideWidth: 288,
      contentMaxWidth: 1400,
      contentPadding: const EdgeInsets.symmetric(horizontal: 116, vertical: 32),
      backgroundColor: const Color(0xFFF6F7F8),
      dividerColor: const Color(0xFFEDF2F7),

      sidebar: SidebarWidget(
        selectedIndex: selectedIndex,
        onItemSelected: (index) => _goToAdminTab(index),
      ),

      header: TopHeaderWidget(
        userName: displayName,
        userSubtitle:
            hasOrg ? "Organization Admin Portal" : "Setup your organization",
        notificationsCount: 0,

        onNotificationsTap: _openNotifications,
        onSettings: _openSettings,
        onLogout: () async => await _logout(context),
      ),

      // ✅ كل التنقل بقى مجرد تغيير index في IndexedStack واحد
      child: IndexedStack(
        index: _viewIndex,
        children: [
          _buildAdminTabsBody(state, ctrl, orgId),
          const NotificationsPage(),
          const SettingsPage(),
        ],
      ),
    );
  }

  Widget _buildAdminTabsBody(
    AdminDashboardState state,
    AdminDashboardController ctrl,
    String orgId,
  ) {
    final hasOrg = orgId.isNotEmpty;

    final isAllowedWithoutOrg =
        selectedIndex == _idxSettingsTab || selectedIndex == _idxHelp;

    if (!hasOrg && !isAllowedWithoutOrg) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: EmptyOrgState(
          onCreateOrganizationPressed: () async {
            FocusScope.of(context).unfocus();

            final data = await showDialog<Map<String, dynamic>>(
              context: context,
              builder: (_) => const CreateOrgDialog(),
            );

            if (data == null) return;

            final name = (data['name'] ?? '').toString().trim();
            final desc = (data['description'] ?? '').toString().trim();
            final logo = (data['logo_url'] ?? '').toString().trim();

            if (name.isEmpty || desc.isEmpty) {
              AppToast.show(
                context,
                title: "Missing info",
                message: "Organization name and description are required.",
                icon: Icons.error_outline,
              );
              return;
            }

            await ctrl.createOrganization(
              name: name,
              description: desc,
              logoUrl: logo.isEmpty ? null : logo,
            );

            if (!mounted) return;

            setState(() {
              selectedIndex = _idxUsers;
              _viewIndex = _viewAdminTabs;
            });

            AppToast.show(
              context,
              title: "Done",
              message: "Organization created successfully.",
              icon: Icons.check_circle_outline,
            );
          },
        ),
      );
    }

    return IndexedStack(
      index: selectedIndex,
      children: [
        UserManagementContent(organizationId: orgId),

        hasOrg
            ? JoinRequestsContent(organizationId: orgId)
            : _buildPlaceholder(
                icon: Icons.lock_outline_rounded,
                title: "Organization required",
                subtitle: "Create an organization first to access Join Requests.",
                hint: "Go back and create your organization.",
              ),

        const UpgradePlansContent(),
        const SettingsPage(),

        _buildPlaceholder(
          icon: Icons.help_outline_rounded,
          title: "Help & Support Center",
          subtitle: "Check documentation or contact our support team.",
          hint: "Coming soon: docs, ticketing, and live chat.",
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
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

  String _resolveOrgId(AdminDashboardState state) {
    final s = (state.organizationId ?? '').trim();
    if (s.isNotEmpty) return s;

    final me = UserStorage.meJson ?? const <String, dynamic>{};

    final selected = me['selected_organization_id']?.toString().trim();
    if (selected != null && selected.isNotEmpty) return selected;

    final orgs = UserStorage.organizations;
    if (orgs.isNotEmpty) {
      final id = orgs.first['id']?.toString().trim();
      if (id != null && id.isNotEmpty) return id;
    }

    return '';
  }

  String? _readDisplayName() {
    final me = UserStorage.meJson;
    if (me == null) return null;

    final user = me['user'];
    if (user is Map) {
      final u = user.cast<String, dynamic>();
      final name = u['full_name']?.toString();
      if (name != null && name.trim().isNotEmpty) return name.trim();
    }
    return null;
  }

  bool _canAccessTab(int index, bool hasOrg) {
    if (hasOrg) return true;
    return index == _idxUpgrade || index == _idxSettingsTab || index == _idxHelp;
  }

  Widget _buildPlaceholder({
    required IconData icon,
    required String title,
    required String subtitle,
    required String hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 22,
              offset: Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 34, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline,
                      size: 18, color: Color(0xFF4338CA)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      hint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF3730A3),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
