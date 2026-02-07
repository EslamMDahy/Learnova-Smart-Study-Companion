import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/user_storage.dart';
import '../../../../core/ui/toast.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../controllers/admin_dashboard_state.dart';
import '../widgets/create_org_dialog.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_header.dart';
import '../widgets/empty_org_state.dart';
import '../widgets/user_management_content.dart';
import '../widgets/join_requests_content.dart';
import '../widgets/upgrade_plans_content.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  int selectedIndex = 0;
  String? _lastToastMsg;

  static const double _asideWidth = 288; // ✅ Figma: 288
  static const double _contentMaxWidth = 1400; // ✅ Figma: 1400
  static const Color _mainBg = Color(0xFFF6F7F8); // ✅ Figma: #F6F7F8
  static const Color _divider = Color(0xFFEDF2F7);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminDashboardControllerProvider);
    final ctrl = ref.read(adminDashboardControllerProvider.notifier);

    _handleErrorOnce(context, state, ctrl);

    final orgId = _resolveOrgId(state);
    final hasOrg = orgId.isNotEmpty;

    final displayName = _readDisplayName() ?? "Admin";

    return Scaffold(
      backgroundColor: _mainBg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Aside (Scrollable)
          SizedBox(
            width: _asideWidth,
            child: SidebarWidget(
              selectedIndex: selectedIndex,
              onItemSelected: (index) {
                if (!_canAccessTab(index, hasOrg)) {
                  AppToast.show(
                    context,
                    title: "Action needed",
                    message: "Create an organization first to unlock this section.",
                    icon: Icons.lock_outline_rounded,
                  );
                  return;
                }
                setState(() => selectedIndex = index);
              },
            ),
          ),

          // ✅ Main
          Expanded(
            child: Container(
              color: _mainBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header ثابت
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: _divider)),
                    ),
                    child: TopHeaderWidget(
                      userName: displayName,
                      userSubtitle: hasOrg ? "Organization Admin Portal" : "Setup your organization",
                      notificationsCount: 0,
                      onLogout: () async => await _logout(context),
                    ),
                  ),

                  // ✅ Scroll area الرئيسي
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 116, vertical: 32),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            layoutBuilder: (currentChild, previousChildren) {
                              return Stack(
                                alignment: Alignment.topLeft,
                                children: <Widget>[
                                  ...previousChildren,
                                  if (currentChild != null) currentChild,
                                ],
                              );
                            },
                            child: KeyedSubtree(
                              key: ValueKey("${hasOrg}_${orgId}_$selectedIndex"),
                              child: _buildMainBody(state, ctrl, orgId),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      TokenStorage.clear();
      UserStorage.clear();

      if (!mounted) return;

      // ✅ لو عندك GoRouter الأفضل: context.go('/login');
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
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

  /* -------------------- Body -------------------- */

  Widget _buildMainBody(
    AdminDashboardState state,
    AdminDashboardController ctrl,
    String orgId,
  ) {
    final hasOrg = orgId.isNotEmpty;

    if (!hasOrg) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: EmptyOrgState(
          onCreateOrganizationPressed: () async {
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

            setState(() => selectedIndex = 0);
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

    switch (selectedIndex) {
      case 0:
        return UserManagementContent(organizationId: orgId);

      case 1:
        return JoinRequestsContent(organizationId: orgId);

      case 2:
        return const UpgradePlansContent();

      case 3:
        return _buildPlaceholder(
          icon: Icons.settings_suggest_outlined,
          title: "Settings & Configuration",
          subtitle: "Manage your institutional preferences here.",
          hint: "Coming soon: permissions, security, integrations.",
        );

      case 4:
        return _buildPlaceholder(
          icon: Icons.help_outline_rounded,
          title: "Help & Support Center",
          subtitle: "Check documentation or contact our support team.",
          hint: "Coming soon: docs, ticketing, and live chat.",
        );

      default:
        return UserManagementContent(organizationId: orgId);
    }
  }

  /* -------------------- Org resolution -------------------- */

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
    return index == 2 || index == 3 || index == 4;
  }

  void _handleErrorOnce(
    BuildContext context,
    AdminDashboardState state,
    AdminDashboardController ctrl,
  ) {
    if (state.error != null && state.error != _lastToastMsg) {
      _lastToastMsg = state.error;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppToast.show(
          context,
          title: "Something went wrong",
          message: state.error!,
          icon: Icons.warning_amber_rounded,
        );
        ctrl.clearError();
      });
    }
  }

  /* -------------------- Placeholder -------------------- */

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
