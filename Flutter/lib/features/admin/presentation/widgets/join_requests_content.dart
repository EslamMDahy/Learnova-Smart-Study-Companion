import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/user_storage.dart';
import '../controllers/join_requests_controller.dart';
import '../../data/dto/join_request_user.dart';

/* ============================================================
   FIGMA PIXEL-PERFECT CONSTANTS
============================================================ */

// Outer container (like Figma: padding 32px 116px)
const double _kOuterWideHPad = 116;
const double _kOuterNarrowHPad = 16;

// Title area (Figma: padding 24px 116px 8px 8px) -> we mimic by:
// outer padding already gives 116, then internal left pad 8.
const double _kTitleTopPad = 24;
const double _kTitleBottomPad = 8;
const double _kTitleInnerLeftPad = 8;

// Body container (Figma: padding 8px 14px 32px 8px)
const double _kBodyTopPad = 8;
const double _kBodyRightPad = 14;
const double _kBodyBottomPad = 32;
const double _kBodyLeftPad = 8;

// Cards/table widths like Figma
const double _kCardWidth = 1389; // filters card / table shell (approx)
const double _kTableWidth = 1398;

// Table header height (Figma 49), row height (Figma ~91/92)
const double _kHeaderH = 49;
const double _kRowH = 91;

// Figma row padding-left: 16
const double _kRowLeftPad = 16;

// Figma gaps
const double _kHeaderGap = 16;
const double _kRowGap = 40;

// Column widths from Figma
const double _kColCheck = 16;
const double _kColUserInfo = 369.33;
const double _kColRole = 194.69;
const double _kColDept = 228.48;
const double _kColJoinDate = 159.64;
const double _kColStatus = 189.23;
const double _kColActions = 128.64;

class JoinRequestsContent extends ConsumerStatefulWidget {
  final String? organizationId;

  const JoinRequestsContent({
    super.key,
    required this.organizationId,
  });

  @override
  ConsumerState<JoinRequestsContent> createState() => _JoinRequestsContentState();
}

class _JoinRequestsContentState extends ConsumerState<JoinRequestsContent> {
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
      if (_orgId.isEmpty) {
        ref.read(joinRequestsControllerProvider.notifier).clearError();
        return;
      }

      await ref.read(joinRequestsControllerProvider.notifier).load(
            organizationId: _orgId,
            view: 'pending',
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
    final state = ref.watch(joinRequestsControllerProvider);
    final users = _applyFilters(state.users);

    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 1100;

        return SingleChildScrollView(
          // Outer container (Figma: padding 32px 116px) + vertical space
          padding: EdgeInsets.fromLTRB(
            isNarrow ? _kOuterNarrowHPad : _kOuterWideHPad,
            _kTitleTopPad,
            isNarrow ? _kOuterNarrowHPad : _kOuterWideHPad,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title block (we add left 8 like figma inside)
              Padding(
                padding: const EdgeInsets.only(left: _kTitleInnerLeftPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Join Requests",
                      style: TextStyle(
                        fontFamily: "Manrope",
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 36 / 30,
                        letterSpacing: -0.75,
                        color: Color(0xFF111418),
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
                        color: Color(0xFF617589),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _kTitleBottomPad),

              // Error banners
              if (_orgId.isEmpty) ...[
                const _ErrorBanner(
                  message:
                      "Missing organization id. Please create/select an organization first.",
                  onRetry: null,
                ),
                const SizedBox(height: 14),
              ] else if (state.error != null) ...[
                _ErrorBanner(
                  message: state.error!,
                  onRetry: () => ref
                      .read(joinRequestsControllerProvider.notifier)
                      .load(organizationId: _orgId, view: 'pending'),
                ),
                const SizedBox(height: 14),
              ],

              // Body container padding like Figma: 8px 14px 32px 8px
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  _kBodyLeftPad,
                  _kBodyTopPad,
                  _kBodyRightPad,
                  _kBodyBottomPad,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filters card (Figma: height ~74, radius 12, bg white, border E5E7EB)
                    _CardShell(
                      width: _kCardWidth,
                      child: _FiltersBarFigma(
                        controller: _search,
                        selectedRole: selectedRole,
                        selectedStatus: selectedStatus,
                        isNarrow: isNarrow,
                        onSearchChanged: (_) => setState(() {}),
                        onRoleChanged: (v) => setState(() => selectedRole = v),
                        onStatusChanged: (v) => setState(() => selectedStatus = v),
                        onRefresh: _orgId.isEmpty
                            ? () {}
                            : () => ref
                                .read(joinRequestsControllerProvider.notifier)
                                .load(organizationId: _orgId, view: 'pending'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Table shell (Figma: white + border + shadow + radius 12)
                    _CardShell(
                      width: _kCardWidth,
                      child: Column(
                        children: [
                          // horizontal scroll wrapper to keep widths fixed
                          _HScroll(
                            child: SizedBox(
                              width: _kTableWidth,
                              child: Column(
                                children: [
                                  _FigmaTableHeader(isNarrow: isNarrow),
                                  if (state.loading)
                                    const Padding(
                                      padding: EdgeInsets.all(26),
                                      child: Center(child: CircularProgressIndicator()),
                                    )
                                  else if (users.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(26),
                                      child: _EmptyTableState(),
                                    )
                                  else
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: users.length,
                                      separatorBuilder: (_, __) => const Divider(
                                        height: 1,
                                        color: Color(0xFFF3F4F6),
                                      ),
                                      itemBuilder: (_, i) => SizedBox(
                                        height: _kRowH,
                                        child: _FigmaUserRow(
                                          user: users[i],
                                          organizationId: _orgId,
                                          isNarrow: isNarrow,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
   HELPERS
============================================================ */

class _HScroll extends StatelessWidget {
  final Widget child;
  const _HScroll({required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: child,
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  final double width;
  const _CardShell({required this.child, required this.width});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        // let it shrink on narrow, but cap on desktop
        maxWidth: width,
      ),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/* ============================================================
   FILTERS BAR (Figma-like)
============================================================ */

class _FiltersBarFigma extends StatelessWidget {
  final TextEditingController controller;
  final String selectedRole;
  final String selectedStatus;
  final bool isNarrow;

  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onRefresh;

  const _FiltersBarFigma({
    required this.controller,
    required this.selectedRole,
    required this.selectedStatus,
    required this.isNarrow,
    required this.onSearchChanged,
    required this.onRoleChanged,
    required this.onStatusChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final role = _DropdownFigma(
      value: selectedRole,
      items: const ["All Roles", "owner", "teacher", "student", "assistant"],
      onChanged: onRoleChanged,
    );

    final status = _DropdownFigma(
      value: selectedStatus,
      items: const ["All Status", "pending", "accepted", "suspended", "declined"],
      onChanged: onStatusChanged,
    );

    return Padding(
      padding: const EdgeInsets.all(16), // Figma card padding
      child: isNarrow
          ? Column(
              children: [
                _SearchFieldFigma(
                  controller: controller,
                  onChanged: onSearchChanged,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: role),
                    const SizedBox(width: 12),
                    Expanded(child: status),
                    const SizedBox(width: 12),
                    _IconBtnFigma(onPressed: onRefresh),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                SizedBox(
                  width: 448, // Figma search width
                  child: _SearchFieldFigma(
                    controller: controller,
                    onChanged: onSearchChanged,
                  ),
                ),
                const Spacer(),
                SizedBox(width: 140, child: role),
                const SizedBox(width: 12),
                SizedBox(width: 140, child: status),
                const SizedBox(width: 12),
                _IconBtnFigma(onPressed: onRefresh),
              ],
            ),
    );
  }
}

class _SearchFieldFigma extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchFieldFigma({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40, // Figma
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: "Manrope",
          fontSize: 14,
          color: Color(0xFF111418),
        ),
        decoration: InputDecoration(
          hintText: "Search by name, ID, or email...",
          hintStyle: const TextStyle(
            fontFamily: "Manrope",
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
          prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF9CA3AF)),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _IconBtnFigma extends StatelessWidget {
  final VoidCallback onPressed;
  const _IconBtnFigma({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          backgroundColor: const Color(0xFFF9FAFB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Icon(Icons.refresh, size: 18, color: Color(0xFF6B7280)),
      ),
    );
  }
}

class _DropdownFigma extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _DropdownFigma({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down,
                  size: 20, color: Color(0xFF6B7280)),
              style: const TextStyle(
                fontFamily: "Manrope",
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF374151),
              ),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              items: items
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(e, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   TABLE HEADER (Figma widths)
============================================================ */

class _FigmaTableHeader extends StatelessWidget {
  final bool isNarrow;
  const _FigmaTableHeader({required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kHeaderH,
      color: const Color(0xFFF9FAFB),
      child: Row(
        children: [
          const SizedBox(width: _kRowLeftPad),

          // Checkbox column
          const SizedBox(
            width: _kColCheck,
            child: Center(child: SizedBox.shrink()),
          ),
          const SizedBox(width: _kHeaderGap),

          // USER INFO
          const SizedBox(
            width: _kColUserInfo,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: _HeaderTxt("USER INFO"),
            ),
          ),

          // ROLE
          const SizedBox(
            width: _kColRole,
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, 16, 24, 16),
              child: _HeaderTxt("ROLE"),
            ),
          ),

          if (!isNarrow)
            const SizedBox(
              width: _kColDept,
              child: Padding(
                padding: EdgeInsets.fromLTRB(8, 16, 24, 16),
                child: _HeaderTxt("DEPARTMENT"),
              ),
            ),

          if (!isNarrow)
            const SizedBox(
              width: _kColJoinDate,
              child: Padding(
                padding: EdgeInsets.fromLTRB(8, 16, 24, 16),
                child: _HeaderTxt("JOIN DATE"),
              ),
            ),

          const SizedBox(
            width: _kColStatus,
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, 16, 24, 16),
              child: _HeaderTxt("STATUS"),
            ),
          ),

          const SizedBox(
            width: _kColActions,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: _HeaderTxt("ACTIONS"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTxt extends StatelessWidget {
  final String text;
  const _HeaderTxt(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: "Manrope",
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF6B7280),
      ),
    );
  }
}

/* ============================================================
   TABLE EMPTY STATE
============================================================ */

class _EmptyTableState extends StatelessWidget {
  const _EmptyTableState();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.inbox_outlined, color: Color(0xFF6B7280)),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            "No pending join requests right now.",
            style: TextStyle(
              fontFamily: "Manrope",
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }
}

/* ============================================================
   ROW (Figma widths)
============================================================ */

class _FigmaUserRow extends ConsumerWidget {
  final JoinRequestUser user;
  final String organizationId;
  final bool isNarrow;

  const _FigmaUserRow({
    required this.user,
    required this.organizationId,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = user.status.toLowerCase();
    final role = user.systemRole.toLowerCase();
    final isPending = status == 'pending';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: _kRowLeftPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _kColCheck,
            height: _kColCheck,
            child: Checkbox(
              value: false,
              onChanged: (_) {},
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: _kRowGap),

          // USER INFO cell
          SizedBox(
            width: _kColUserInfo,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _UserInfoCell(user: user),
            ),
          ),

          // ROLE cell
          SizedBox(
            width: _kColRole,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _RolePill(role: role),
              ),
            ),
          ),

          if (!isNarrow)
            const SizedBox(
              width: _kColDept,
              child: Padding(
                padding: EdgeInsets.only(left: 8, right: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "—",
                    style: TextStyle(
                      fontFamily: "Manrope",
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ),
            ),

          if (!isNarrow)
            const SizedBox(
              width: _kColJoinDate,
              child: Padding(
                padding: EdgeInsets.only(left: 8, right: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "—",
                    style: TextStyle(
                      fontFamily: "Manrope",
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),

          // STATUS cell
          SizedBox(
            width: _kColStatus,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusBadge(status: status),
              ),
            ),
          ),

          // ACTIONS cell
          SizedBox(
            width: _kColActions,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: isPending
                    ? _RowActions(organizationId: organizationId, user: user)
                    : const Text(
                        "—",
                        style: TextStyle(
                          fontFamily: "Manrope",
                          fontSize: 12,
                          color: Color(0xFF6B7280),
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

class _UserInfoCell extends StatelessWidget {
  final JoinRequestUser user;
  const _UserInfoCell({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFDBEAFE),
          child: Text(
            "U",
            style: TextStyle(
              fontFamily: "Manrope",
              fontWeight: FontWeight.w700,
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
                  color: Color(0xFF111418),
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
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "ID: —",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF9CA3AF),
                  height: 20 / 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ============================================================
   ROLE PILL + STATUS BADGE (close to Figma)
============================================================ */

class _RolePill extends StatelessWidget {
  final String role;
  const _RolePill({required this.role});

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFDBEAFE);
    Color border = const Color(0xFFBFDBFE);
    Color fg = const Color(0xFF1E40AF);
    String label = role;

    if (role == 'owner') {
      bg = const Color(0xFFE0E7FF);
      border = const Color(0xFFC7D2FE);
      fg = const Color(0xFF4F46E5);
    } else if (role == 'teacher' || role == 'instructor') {
      bg = const Color(0xFFF3E8FF);
      border = const Color(0xFFE9D5FF);
      fg = const Color(0xFF6B21A8);
      label = "Instructor";
    } else if (role == 'student') {
      bg = const Color(0xFFDBEAFE);
      border = const Color(0xFFBFDBFE);
      fg = const Color(0xFF1E40AF);
      label = "Student";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: "Manrope",
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: fg,
          height: 16 / 12,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color dot = const Color(0xFFEAB308); // pending
    String label = status;

    if (status == 'accepted') dot = const Color(0xFF22C55E);
    if (status != 'accepted' && status != 'pending') dot = const Color(0xFFEF4444);

    // fix common typo
    if (label == 'pinding') label = 'pending';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: dot, borderRadius: BorderRadius.circular(9999)),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: "Manrope",
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
            height: 20 / 14,
          ),
        ),
      ],
    );
  }
}

/* ============================================================
   ACTIONS (keep your controller logic)
============================================================ */

class _RowActions extends ConsumerStatefulWidget {
  final String organizationId;
  final JoinRequestUser user;

  const _RowActions({
    required this.organizationId,
    required this.user,
  });

  @override
  ConsumerState<_RowActions> createState() => _RowActionsState();
}

class _RowActionsState extends ConsumerState<_RowActions> {
  bool busy = false;

  Future<void> _run(Future<void> Function() fn) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await fn();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.read(joinRequestsControllerProvider.notifier);

    return PopupMenuButton<int>(
      tooltip: "Actions",
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      enabled: !busy,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 0, child: Text("Accept")),
        PopupMenuItem(value: 1, child: Text("Decline")),
      ],
      onSelected: (v) async {
        if (v == 0) {
          await _run(() async {
            await ctrl.accept(
              organizationId: widget.organizationId, // ✅ fixed
              orgMemberId: widget.user.orgMemberId,
            );
            await ctrl.load(organizationId: widget.organizationId, view: 'pending'); // ✅ fixed
          });
        } else {
          await _run(() async {
            await ctrl.decline(
              organizationId: widget.organizationId, // ✅ fixed
              orgMemberId: widget.user.orgMemberId,
            );
            await ctrl.load(organizationId: widget.organizationId, view: 'pending'); // ✅ fixed
          });
        }
      },

      // ✅ FIX: show actions button with bg + border (Figma-like)
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.more_horiz, size: 20, color: Color(0xFF9CA3AF)),
      ),
    );
  }
}

/* ============================================================
   ERROR BANNER
============================================================ */

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
