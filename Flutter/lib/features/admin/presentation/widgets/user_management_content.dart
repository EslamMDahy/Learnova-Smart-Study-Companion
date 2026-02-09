import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/user_storage.dart';
import '../../../../core/ui/toast.dart';
import '../controllers/user_management_controller.dart';
import '../controllers/user_management_state.dart';
import '../../data/dto/join_request_user.dart';

import '../../../../shared/widgets/app_ui_components.dart';

/* ============================================================
   Keep SAME constants for layout widths
============================================================ */
const double _kActionsColW = 72;
const double _kCellLeftPad = 8;
const double _kRowHPad = 16;

class UserManagementContent extends ConsumerStatefulWidget {
  final String? organizationId;

  const UserManagementContent({
    super.key,
    this.organizationId,
  });

  @override
  ConsumerState<UserManagementContent> createState() =>
      _UserManagementContentState();
}

class _UserManagementContentState extends ConsumerState<UserManagementContent> {
  String selectedRole = "All Roles";
  String selectedStatus = "All Status";
  final _search = TextEditingController();

  String? _lastToastMsg;
  ProviderSubscription<UserManagementState>? _errSub;

  String get _orgId =>
      (widget.organizationId != null && widget.organizationId!.trim().isNotEmpty)
          ? widget.organizationId!.trim()
          : (UserStorage.organizationId ?? '').trim();

  @override
  void initState() {
    super.initState();

    _errSub = ref.listenManual<UserManagementState>(
      userManagementControllerProvider,
      (prev, next) {
        final err = next.error;
        if (err == null) return;

        if (_lastToastMsg == err) return;
        _lastToastMsg = err;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          AppToast.show(
            context,
            title: "Something went wrong",
            message: err,
            icon: Icons.warning_amber_rounded,
          );

          ref.read(userManagementControllerProvider.notifier).clearError();
        });
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_orgId.isEmpty) {
        if (!mounted) return;
        AppToast.show(
          context,
          title: "Action needed",
          message: "Create/select an organization first.",
          icon: Icons.lock_outline_rounded,
        );
        return;
      }

      await ref.read(userManagementControllerProvider.notifier).loadUsers(
            organizationId: _orgId,
          );
    });
  }

  @override
  void dispose() {
    _errSub?.close();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementControllerProvider);
    final users = _applyFilters(state.users);

    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 1100;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 16 : 116,
            vertical: 32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FigmaUmPageHeader(
                    title: "User Management",
                    subtitle:
                        "Manage student and instructor accounts, roles, and permissions.",
                  ),
                  const SizedBox(height: 24),

                  _StatsRow(isNarrow: isNarrow, users: state.users),
                  const SizedBox(height: 16),

                  FigmaUmFiltersBar(
                    controller: _search,
                    selectedRole: selectedRole,
                    selectedStatus: selectedStatus,
                    isNarrow: isNarrow,
                    onSearchChanged: (_) => setState(() {}),
                    onRoleChanged: (v) => setState(() => selectedRole = v),
                    onStatusChanged: (v) => setState(() => selectedStatus = v),
                    onMoreFilters: () {
                      AppToast.show(
                        context,
                        title: "Coming soon",
                        message: "More filters will be available soon.",
                        icon: Icons.info_outline,
                      );
                    },
                    onRefresh: _orgId.isEmpty
                        ? () {}
                        : () => ref
                            .read(userManagementControllerProvider.notifier)
                            .loadUsers(organizationId: _orgId),
                  ),

                  const SizedBox(height: 16),

                  _UsersTableFigma(
                    isNarrow: isNarrow,
                    loading: state.loading,
                    users: users,
                    onActionTap: () {
                      AppToast.show(
                        context,
                        title: "Coming soon",
                        message: "User actions menu is coming soon.",
                        icon: Icons.info_outline,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<JoinRequestUser> _applyFilters(List<JoinRequestUser> users) {
    final q = _search.text.trim().toLowerCase();

    return users.where((u) {
      final roleOk = selectedRole == "All Roles" ||
          u.systemRole.toLowerCase() == selectedRole.toLowerCase();

      final statusOk = selectedStatus == "All Status" ||
          _normalizeStatus(u.status) == _normalizeStatus(selectedStatus);

      final searchOk = q.isEmpty ||
          u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);

      return roleOk && statusOk && searchOk;
    }).toList();
  }

  String _normalizeStatus(String s) {
    final v = s.toLowerCase().trim();
    if (v == 'declinate') return 'declined';
    if (v == 'rejected') return 'declined';
    return v;
  }
}

/* ============================================================
   Stats row (same UI, but stat cards moved to reusable)
============================================================ */
class _StatsRow extends StatelessWidget {
  final bool isNarrow;
  final List<JoinRequestUser> users;

  const _StatsRow({required this.isNarrow, required this.users});

  @override
  Widget build(BuildContext context) {
    final total = users.length;
    final instructors = users.where((e) {
      final r = e.systemRole.toLowerCase();
      return r == "teacher" || r == "instructor";
    }).length;
    final students =
        users.where((e) => e.systemRole.toLowerCase() == "student").length;
    final pending = users.where((e) => e.status.toLowerCase() == "pending").length;

    final cards = [
      const FigmaUmStatCard(
        title: "Total Users",
        value: "0",
        subtitle: "+12% from last month",
        subtitleColor: Color(0xFF16A34A),
        iconBg: Color(0x1A137FEC),
        icon: Icons.people_alt_outlined,
        iconColor: Color(0xFF137FEC),
      ),
      const FigmaUmStatCard(
        title: "Active Instructors",
        value: "0",
        subtitle: "Across 12 Departments",
        subtitleColor: AppColors.cGray500,
        iconBg: Color(0xFFFAF5FF),
        icon: Icons.school_outlined,
        iconColor: Color(0xFF9333EA),
      ),
      const FigmaUmStatCard(
        title: "Active Students",
        value: "0",
        subtitle: "+5% new enrollments",
        subtitleColor: Color(0xFF16A34A),
        iconBg: Color(0xFFFFF7ED),
        icon: Icons.groups_outlined,
        iconColor: Color(0xFFEA580C),
      ),
      FigmaUmStatCard(
        title: "Pending Approvals",
        value: "$pending",
        subtitle: "Requires attention",
        subtitleColor: const Color(0xFFCA8A04),
        iconBg: const Color(0xFFFEFCE8),
        icon: Icons.hourglass_bottom_rounded,
        iconColor: const Color(0xFFCA8A04),
        fixedWidth: isNarrow ? null : 319,
      ),
    ];

    // ✅ update dynamic values without changing widget look
    final updated = [
      FigmaUmStatCard(
        title: "Total Users",
        value: "$total",
        subtitle: "+12% from last month",
        subtitleColor: const Color(0xFF16A34A),
        iconBg: const Color(0x1A137FEC),
        icon: Icons.people_alt_outlined,
        iconColor: const Color(0xFF137FEC),
      ),
      FigmaUmStatCard(
        title: "Active Instructors",
        value: "$instructors",
        subtitle: "Across 12 Departments",
        subtitleColor: AppColors.cGray500,
        iconBg: const Color(0xFFFAF5FF),
        icon: Icons.school_outlined,
        iconColor: const Color(0xFF9333EA),
      ),
      FigmaUmStatCard(
        title: "Active Students",
        value: "$students",
        subtitle: "+5% new enrollments",
        subtitleColor: const Color(0xFF16A34A),
        iconBg: const Color(0xFFFFF7ED),
        icon: Icons.groups_outlined,
        iconColor: const Color(0xFFEA580C),
      ),
      FigmaUmStatCard(
        title: "Pending Approvals",
        value: "$pending",
        subtitle: "Requires attention",
        subtitleColor: const Color(0xFFCA8A04),
        iconBg: const Color(0xFFFEFCE8),
        icon: Icons.hourglass_bottom_rounded,
        iconColor: const Color(0xFFCA8A04),
        fixedWidth: isNarrow ? null : 319,
      ),
    ];

    if (isNarrow) {
      return Wrap(spacing: 16, runSpacing: 16, children: updated);
    }

    return Row(
      children: [
        Expanded(child: updated[0]),
        const SizedBox(width: 16),
        Expanded(child: updated[1]),
        const SizedBox(width: 16),
        Expanded(child: updated[2]),
        const SizedBox(width: 16),
        SizedBox(width: 319, child: updated[3]),
      ],
    );
  }
}

class _UsersTableFigma extends StatelessWidget {
  final bool isNarrow;
  final bool loading;
  final List<JoinRequestUser> users;
  final VoidCallback onActionTap;

  const _UsersTableFigma({
    required this.isNarrow,
    required this.loading,
    required this.users,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final showingTo = users.isEmpty ? 0 : (users.length < 5 ? users.length : 5);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          FigmaUmTableHeader(
            isNarrow: isNarrow,
            actionsColWidth: _kActionsColW,
            cellLeftPad: _kCellLeftPad,
            rowHPad: _kRowHPad,
          ),

          if (loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (users.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: FigmaUmEmptyTableState(),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.cBorderSoft),
              itemBuilder: (_, i) => _UserRowFigma(
                user: users[i],
                isNarrow: isNarrow,
                onActionTap: onActionTap,
              ),
            ),

          FigmaUmTableFooter(
            showingText: "Showing 1-$showingTo of ${users.length} users",
            onPrev: null,
            onNext: users.length > 5 ? () {} : null,
          ),
        ],
      ),
    );
  }
}

class _UserRowFigma extends StatelessWidget {
  final JoinRequestUser user;
  final bool isNarrow;
  final VoidCallback onActionTap;

  const _UserRowFigma({
    required this.user,
    required this.isNarrow,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 91,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _kRowHPad),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: Checkbox(
                value: false,
                onChanged: (_) {},
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.only(left: _kCellLeftPad),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: AppColors.cBorderSoft),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(user.fullName),
                        style: const TextStyle(
                          fontFamily: "Manrope",
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 20 / 14,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: "Manrope",
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 20 / 14,
                              color: AppColors.cText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: "Manrope",
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 16 / 12,
                              color: AppColors.cGray500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "ID: —",
                            style: TextStyle(
                              fontFamily: "Inter",
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              height: 20 / 10,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: _kCellLeftPad),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FigmaUmRolePill(role: user.systemRole),
                ),
              ),
            ),

            if (!isNarrow)
              const Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.only(left: _kCellLeftPad),
                  child: Text(
                    "—",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: "Manrope",
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 20 / 14,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ),

            if (!isNarrow)
              const Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.only(left: _kCellLeftPad),
                  child: Text(
                    "—",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: "Manrope",
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 16 / 12,
                      color: AppColors.cGray500,
                    ),
                  ),
                ),
              ),

            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: _kCellLeftPad),
                child: FigmaUmStatus(status: user.status),
              ),
            ),

            SizedBox(
              width: _kActionsColW,
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: InkWell(
                    onTap: onActionTap,
                    borderRadius: BorderRadius.circular(9999),
                    child: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return "—";
    final a = parts[0].isNotEmpty ? parts[0][0] : "";
    final b = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : "";
    final res = (a + b).toUpperCase();
    return res.isEmpty ? "—" : res;
  }
}
