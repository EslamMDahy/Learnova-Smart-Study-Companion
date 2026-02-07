import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/user_storage.dart';
import '../controllers/user_management_controller.dart';
import '../../data/dto/join_request_user.dart';

/* ============================================================
   Figma-like constants
============================================================ */
const _cText = Color(0xFF111418);
const _cMuted = Color(0xFF617589);
const _cGray700 = Color(0xFF374151);
const _cGray500 = Color(0xFF6B7280);
const _cBorder = Color(0xFFE5E7EB);
const _cBorderSoft = Color(0xFFF3F4F6);
const _cBg = Color(0xFFFFFFFF);
const _cSurface = Color(0xFFF9FAFB);

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

  String get _orgId =>
      (widget.organizationId != null && widget.organizationId!.trim().isNotEmpty)
          ? widget.organizationId!.trim()
          : (UserStorage.organizationId ?? '').trim();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_orgId.isEmpty) return;

      await ref.read(userManagementControllerProvider.notifier).loadUsers(
            organizationId: _orgId,
          );
    });
  }

  @override
  void dispose() {
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
                  const _PageHeader(),
                  const SizedBox(height: 24),

                  if (_orgId.isEmpty) ...[
                    const _ErrorBanner(
                      message:
                          "Missing organization id. Please create/select an organization first.",
                      onRetry: null,
                    ),
                    const SizedBox(height: 16),
                  ] else if (state.error != null) ...[
                    _ErrorBanner(
                      message: state.error!,
                      onRetry: () => ref
                          .read(userManagementControllerProvider.notifier)
                          .loadUsers(organizationId: _orgId),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Stats cards (Figma)
                  _StatsRow(isNarrow: isNarrow, users: state.users),
                  const SizedBox(height: 16),

                  // Filters bar (Figma)
                  _FiltersBarFigma(
                    controller: _search,
                    selectedRole: selectedRole,
                    selectedStatus: selectedStatus,
                    isNarrow: isNarrow,
                    onSearchChanged: (_) => setState(() {}),
                    onRoleChanged: (v) => setState(() => selectedRole = v),
                    onStatusChanged: (v) => setState(() => selectedStatus = v),
                    onMoreFilters: () {},
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
          u.status.toLowerCase() == selectedStatus.toLowerCase();

      final searchOk = q.isEmpty ||
          u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);

      return roleOk && statusOk && searchOk;
    }).toList();
  }
}

/* ============================================================
   Header (Figma)
============================================================ */
class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "User Management",
          style: TextStyle(
            fontFamily: "Manrope",
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 36 / 30,
            letterSpacing: -0.75,
            color: _cText,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "Manage student and instructor accounts, roles, and permissions.",
          style: TextStyle(
            fontFamily: "Manrope",
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 24 / 16,
            color: _cMuted,
          ),
        ),
      ],
    );
  }
}

/* ============================================================
   Stats row (Figma)
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
      _StatCard(
        title: "Total Users",
        value: "$total",
        subtitle: "+12% from last month",
        subtitleColor: const Color(0xFF16A34A),
        iconBg: const Color(0x1A137FEC),
        icon: Icons.people_alt_outlined,
        iconColor: const Color(0xFF137FEC),
      ),
      _StatCard(
        title: "Active Instructors",
        value: "$instructors",
        subtitle: "Across 12 Departments",
        subtitleColor: _cGray500,
        iconBg: const Color(0xFFFAF5FF),
        icon: Icons.school_outlined,
        iconColor: const Color(0xFF9333EA),
      ),
      _StatCard(
        title: "Active Students",
        value: "$students",
        subtitle: "+5% new enrollments",
        subtitleColor: const Color(0xFF16A34A),
        iconBg: const Color(0xFFFFF7ED),
        icon: Icons.groups_outlined,
        iconColor: const Color(0xFFEA580C),
      ),
      _StatCard(
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
      return Wrap(spacing: 16, runSpacing: 16, children: cards);
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 16),
        Expanded(child: cards[1]),
        const SizedBox(width: 16),
        Expanded(child: cards[2]),
        const SizedBox(width: 16),
        SizedBox(width: 319, child: cards[3]),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color subtitleColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final double? fixedWidth;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.subtitleColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.fixedWidth,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: 134,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: "Manrope",
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                  color: _cMuted,
                ),
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: "Manrope",
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 32 / 24,
              color: _cText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: "Manrope",
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 16 / 12,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );

    if (fixedWidth == null) return card;
    return SizedBox(width: fixedWidth, child: card);
  }
}

/* ============================================================
   Filters bar (Figma) - RESPONSIVE
============================================================ */
class _FiltersBarFigma extends StatelessWidget {
  final TextEditingController controller;
  final String selectedRole;
  final String selectedStatus;
  final bool isNarrow;

  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onStatusChanged;

  final VoidCallback onMoreFilters;
  final VoidCallback onRefresh;

  const _FiltersBarFigma({
    required this.controller,
    required this.selectedRole,
    required this.selectedStatus,
    required this.isNarrow,
    required this.onSearchChanged,
    required this.onRoleChanged,
    required this.onStatusChanged,
    required this.onMoreFilters,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final roleDrop = _FigmaDropdown(
      width: isNarrow ? 150 : 140,
      value: selectedRole,
      items: const ["All Roles", "owner", "teacher", "student", "assistant"],
      onChanged: onRoleChanged,
    );

    final statusDrop = _FigmaDropdown(
      width: isNarrow ? 150 : 140,
      value: selectedStatus,
      items: const ["All Status", "pending", "accepted", "suspended", "declinate"],
      onChanged: onStatusChanged,
    );

    final search = _FigmaSearch(
      controller: controller,
      onChanged: onSearchChanged,
      isNarrow: isNarrow,
    );

    final moreFilters = _SquareIconBtn(
      icon: Icons.tune_rounded,
      onTap: onMoreFilters,
      tooltip: "More filters",
    );

    final refresh = _SquareIconBtn(
      icon: Icons.refresh,
      onTap: onRefresh,
      tooltip: "Refresh",
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                search,
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    roleDrop,
                    statusDrop,
                    moreFilters,
                    refresh,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 16),
                roleDrop,
                const SizedBox(width: 12),
                statusDrop,
                const Spacer(),
                moreFilters,
                const SizedBox(width: 8),
                refresh,
              ],
            ),
    );
  }
}

class _FigmaSearch extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isNarrow;

  const _FigmaSearch({
    required this.controller,
    required this.onChanged,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: "Manrope",
          fontSize: 14,
          height: 19 / 14,
          color: _cGray700,
        ),
        decoration: InputDecoration(
          hintText: "Search by name, ID, or email...",
          hintStyle: const TextStyle(
            fontFamily: "Manrope",
            fontSize: 14,
            height: 19 / 14,
            color: _cGray500,
          ),
          filled: true,
          fillColor: _cSurface,
          prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF9CA3AF)),
          contentPadding: const EdgeInsets.only(top: 10, bottom: 11),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFBFDBFE), width: 1.2),
          ),
        ),
      ),
    );
  }
}

class _FigmaDropdown extends StatelessWidget {
  final double width;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _FigmaDropdown({
    required this.width,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _cSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: _cGray500),
              style: const TextStyle(
                fontFamily: "Manrope",
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
                color: _cGray700,
              ),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SquareIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _SquareIconBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _cSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: _cGray500),
        ),
      ),
    );
  }
}

/* ============================================================
   Table (Figma) - RESPONSIVE + ALIGNED (KEEP ONLY THIS VERSION)
============================================================ */

const double _kActionsColW = 72; // ثابت للهيدر والرو
const double _kCellLeftPad = 8;  // padding موحد
const double _kRowHPad = 16;     // horizontal padding للصف والهيدر

class _UsersTableFigma extends StatelessWidget {
  final bool isNarrow;
  final bool loading;
  final List<JoinRequestUser> users;

  const _UsersTableFigma({
    required this.isNarrow,
    required this.loading,
    required this.users,
  });

  @override
  Widget build(BuildContext context) {
    final showingTo = users.isEmpty ? 0 : (users.length < 5 ? users.length : 5);

    return Container(
      decoration: BoxDecoration(
        color: _cBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _TableHeaderFigma(isNarrow: isNarrow),

          if (loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (users.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: _EmptyTableState(),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: _cBorderSoft),
              itemBuilder: (_, i) => _UserRowFigma(
                user: users[i],
                isNarrow: isNarrow,
              ),
            ),

          _TableFooterFigma(
            showingText: "Showing 1-$showingTo of ${users.length} users",
            onPrev: null,
            onNext: users.length > 5 ? () {} : null,
          ),
        ],
      ),
    );
  }
}

class _TableHeaderFigma extends StatelessWidget {
  final bool isNarrow;
  const _TableHeaderFigma({required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 49,
      color: _cSurface,
      padding: const EdgeInsets.symmetric(horizontal: _kRowHPad),
      child: Row(
        children: [
          const SizedBox(width: 16, height: 16), // checkbox placeholder
          const SizedBox(width: 16),

          const _HeaderCellFlex(flex: 5, text: "USER INFO", leftPad: _kCellLeftPad),
          const _HeaderCellFlex(flex: 2, text: "ROLE", leftPad: _kCellLeftPad),

          if (!isNarrow)
            const _HeaderCellFlex(flex: 3, text: "DEPARTMENT", leftPad: _kCellLeftPad),
          if (!isNarrow)
            const _HeaderCellFlex(flex: 2, text: "JOINED DATE", leftPad: _kCellLeftPad),

          const _HeaderCellFlex(flex: 2, text: "STATUS", leftPad: _kCellLeftPad),

          const SizedBox(
            width: _kActionsColW,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text(
                  "ACTIONS",
                  style: TextStyle(
                    fontFamily: "Manrope",
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 16 / 12,
                    color: _cGray500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCellFlex extends StatelessWidget {
  final int flex;
  final String text;
  final double leftPad;

  const _HeaderCellFlex({
    required this.flex,
    required this.text,
    this.leftPad = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsets.only(left: leftPad),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: "Manrope",
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 16 / 12,
            color: _cGray500,
          ),
        ),
      ),
    );
  }
}

class _UserRowFigma extends StatelessWidget {
  final JoinRequestUser user;
  final bool isNarrow;

  const _UserRowFigma({
    required this.user,
    required this.isNarrow,
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

            // USER INFO
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
                        border: Border.all(color: _cBorderSoft),
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
                              color: _cText,
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
                              color: _cGray500,
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

            // ROLE
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: _kCellLeftPad),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _RolePillFigma(role: user.systemRole),
                ),
              ),
            ),

            // DEPARTMENT
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

            // JOIN DATE
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
                      color: _cGray500,
                    ),
                  ),
                ),
              ),

            // STATUS
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: _kCellLeftPad),
                child: _StatusFigma(status: user.status),
              ),
            ),

            // ACTIONS
            SizedBox(
              width: _kActionsColW,
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: InkWell(
                    onTap: () {},
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

class _RolePillFigma extends StatelessWidget {
  final String role;
  const _RolePillFigma({required this.role});

  @override
  Widget build(BuildContext context) {
    final r = role.toLowerCase();

    Color bg = const Color(0xFFDBEAFE);
    Color br = const Color(0xFFBFDBFE);
    Color fg = const Color(0xFF1E40AF);

    if (r == "teacher" || r == "instructor") {
      bg = const Color(0xFFF3E8FF);
      br = const Color(0xFFE9D5FF);
      fg = const Color(0xFF6B21A8);
    }

    if (r == "owner") {
      bg = const Color(0xFFE0E7FF);
      br = const Color(0xFFC7D2FE);
      fg = const Color(0xFF4338CA);
    }

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: br),
        borderRadius: BorderRadius.circular(9999),
      ),
      alignment: Alignment.center,
      child: Text(
        _titleCase(r),
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: "Manrope",
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 16 / 12,
          color: fg,
        ),
      ),
    );
  }

  String _titleCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _StatusFigma extends StatelessWidget {
  final String status;
  const _StatusFigma({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();

    Color dot = const Color(0xFFEAB308);
    if (s == "accepted" || s == "active") dot = const Color(0xFF22C55E);
    if (s == "suspended" || s == "rejected" || s == "declinate") {
      dot = const Color(0xFFEF4444);
    }

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: dot,
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _titleCase(s),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: "Manrope",
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
              color: _cGray700,
            ),
          ),
        ),
      ],
    );
  }

  String _titleCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/* ============================================================
   Table footer pagination (Figma)
============================================================ */
class _TableFooterFigma extends StatelessWidget {
  final String showingText;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _TableFooterFigma({
    required this.showingText,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 71,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: _cSurface,
        border: Border(top: BorderSide(color: _cBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              showingText,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: "Manrope",
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
                color: _cGray500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              _PageBtn(
                label: "Previous",
                icon: Icons.chevron_left,
                enabled: onPrev != null,
                onTap: onPrev,
                width: 105,
                trailingIcon: false,
              ),
              const SizedBox(width: 8),
              _PageBtn(
                label: "Next",
                icon: Icons.chevron_right,
                enabled: onNext != null,
                onTap: onNext,
                width: 79,
                trailingIcon: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;
  final double width;
  final bool trailingIcon;

  const _PageBtn({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.width,
    required this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: SizedBox(
        width: width,
        height: 38,
        child: OutlinedButton(
          onPressed: enabled ? onTap : null,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFD1D5DB)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: _cBg,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: trailingIcon
                ? [
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: "Manrope",
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 20 / 14,
                          color: _cGray500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(icon, size: 18, color: _cGray500),
                  ]
                : [
                    Icon(icon, size: 18, color: _cGray500),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: "Manrope",
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 20 / 14,
                          color: _cGray500,
                        ),
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   Empty + Error
============================================================ */
class _EmptyTableState extends StatelessWidget {
  const _EmptyTableState();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.inbox_outlined, color: _cGray500),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            "No users match your filters right now.",
            style: TextStyle(
              fontFamily: "Manrope",
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
              color: _cGray500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB91C1C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: "Manrope",
                fontWeight: FontWeight.w600,
                color: Color(0xFF7F1D1D),
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text(
                "Retry",
                style: TextStyle(
                  fontFamily: "Manrope",
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
