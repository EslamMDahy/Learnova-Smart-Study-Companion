import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/user_storage.dart';
import '../controllers/join_requests_controller.dart';
import '../../data/dto/join_request_user.dart';

import '../../../../shared/widgets/app_ui_components.dart';

/* ============================================================
   SAME TABLE CONSTANTS (from UserManagement)
============================================================ */
const double _kActionsColW = 72;
const double _kCellLeftPad = 8;
const double _kRowHPad = 16;

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
  final TextEditingController _search = TextEditingController();

  String get _orgId {
    final fromWidget = (widget.organizationId ?? '').trim();
    if (fromWidget.isNotEmpty) return fromWidget;
    return (UserStorage.organizationId ?? '').trim();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_orgId.isEmpty) return;
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

  Future<void> _refresh() async {
    if (_orgId.isEmpty) return;
    FocusScope.of(context).unfocus();
    await ref.read(joinRequestsControllerProvider.notifier).load(
          organizationId: _orgId,
          view: 'pending',
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(joinRequestsControllerProvider);
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
                    title: "Join Requests",
                    subtitle:
                        "Manage student and instructor accounts, roles, and permissions.",
                  ),
                  const SizedBox(height: 24),

                  _StatsRow(isNarrow: isNarrow, users: state.users),
                  const SizedBox(height: 16),

                  // ✅ نفس FiltersBar بتاع UserManagement (UI)
                  // ✅ الوظيفة: search/role/status + refresh الحقيقي
                  FigmaUmFiltersBar(
                    controller: _search,
                    selectedRole: selectedRole,
                    selectedStatus: selectedStatus,
                    isNarrow: isNarrow,
                    onSearchChanged: (_) => setState(() {}),
                    onRoleChanged: (v) => setState(() => selectedRole = v),
                    onStatusChanged: (v) => setState(() => selectedStatus = v),
                    onMoreFilters: () {}, // keep UI behavior (optional)
                    onRefresh: (_orgId.isEmpty || state.loading) ? () {} : _refresh,
                  ),

                  const SizedBox(height: 16),

                  _JoinRequestsTableFigma(
                    isNarrow: isNarrow,
                    loading: state.loading,
                    orgId: _orgId,
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
          jrNormalizeStatus(u.status) == jrNormalizeStatus(selectedStatus);

      final searchOk = q.isEmpty ||
          u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);

      return roleOk && statusOk && searchOk;
    }).toList();
  }
}

/* ============================================================
   STATS ROW (نفس شكل UserManagement)
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

    final students = users.where((e) => e.systemRole.toLowerCase() == "student").length;

    final pending = users.where((e) => jrNormalizeStatus(e.status) == "pending").length;

    final cards = [
      FigmaUmStatCard(
        title: "Total Requests",
        value: "$total",
        subtitle: "All join requests",
        subtitleColor: AppColors.cGray500,
        iconBg: const Color(0x1A137FEC),
        icon: Icons.people_alt_outlined,
        iconColor: const Color(0xFF137FEC),
      ),
      FigmaUmStatCard(
        title: "Instructors",
        value: "$instructors",
        subtitle: "Teacher / Instructor",
        subtitleColor: AppColors.cGray500,
        iconBg: const Color(0xFFFAF5FF),
        icon: Icons.school_outlined,
        iconColor: const Color(0xFF9333EA),
      ),
      FigmaUmStatCard(
        title: "Students",
        value: "$students",
        subtitle: "Student requests",
        subtitleColor: AppColors.cGray500,
        iconBg: const Color(0xFFFFF7ED),
        icon: Icons.groups_outlined,
        iconColor: const Color(0xFFEA580C),
      ),
      FigmaUmStatCard(
        title: "Pending",
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

/* ============================================================
   TABLE (نفس شكل UserManagement) + Actions (Accept/Decline)
============================================================ */
class _JoinRequestsTableFigma extends StatelessWidget {
  final bool isNarrow;
  final bool loading;
  final String orgId;
  final List<JoinRequestUser> users;

  const _JoinRequestsTableFigma({
    required this.isNarrow,
    required this.loading,
    required this.orgId,
    required this.users,
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

          if (orgId.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: FigmaUmEmptyTableState(),
            )
          else if (loading)
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
              itemBuilder: (_, i) => _JoinRequestRowFigma(
                user: users[i],
                isNarrow: isNarrow,
                orgId: orgId,
              ),
            ),

          FigmaUmTableFooter(
            showingText: "Showing 1-$showingTo of ${users.length} requests",
            onPrev: null,
            onNext: users.length > 5 ? () {} : null,
          ),
        ],
      ),
    );
  }
}

class _JoinRequestRowFigma extends ConsumerWidget {
  final JoinRequestUser user;
  final bool isNarrow;
  final String orgId;

  const _JoinRequestRowFigma({
    required this.user,
    required this.isNarrow,
    required this.orgId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = jrNormalizeStatus(user.status);
    final isPending = status == 'pending';

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

            // User info (same as UM)
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

            // Role
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

            // Dept / Join date placeholders (same behavior as UM)
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

            // Status
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: _kCellLeftPad),
                child: FigmaUmStatus(status: user.status),
              ),
            ),

            // Actions (✅ same function: accept/decline, UI changed فقط)
            SizedBox(
              width: _kActionsColW,
              child: Align(
                alignment: Alignment.centerRight,
                child: isPending
                    ? _JoinRequestActionsMenu(orgId: orgId, user: user)
                    : const Text(
                        "—",
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

/* ============================================================
   ACTIONS MENU (Accept/Decline) - نفس الوظيفة
============================================================ */
class _JoinRequestActionsMenu extends ConsumerStatefulWidget {
  final String orgId;
  final JoinRequestUser user;

  const _JoinRequestActionsMenu({
    required this.orgId,
    required this.user,
  });

  @override
  ConsumerState<_JoinRequestActionsMenu> createState() => _JoinRequestActionsMenuState();
}

class _JoinRequestActionsMenuState extends ConsumerState<_JoinRequestActionsMenu> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.read(joinRequestsControllerProvider.notifier);

    return PopupMenuButton<int>(
      tooltip: "Actions",
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      enabled: !_busy,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 0, child: Text("Accept")),
        PopupMenuItem(value: 1, child: Text("Decline")),
      ],
      onSelected: (v) async {
        if (v == 0) {
          await _run(() async {
            await ctrl.accept(
              organizationId: widget.orgId,
              orgMemberId: widget.user.orgMemberId,
            );
            await ctrl.load(
              organizationId: widget.orgId,
              view: 'pending',
            );
          });
        } else {
          await _run(() async {
            await ctrl.decline(
              organizationId: widget.orgId,
              orgMemberId: widget.user.orgMemberId,
            );
            await ctrl.load(
              organizationId: widget.orgId,
              view: 'pending',
            );
          });
        }
      },

      // ✅ نفس شكل زر الأكشن بتاع UM (3 نقط)
      child: SizedBox(
        width: 28,
        height: 28,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Center(
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.more_vert,
                    size: 20,
                    color: Color(0xFF9CA3AF),
                  ),
          ),
        ),
      ),
    );
  }
}
