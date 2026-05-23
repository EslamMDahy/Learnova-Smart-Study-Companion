import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/network/endpoints.dart';
import '../../../../../core/network/error_mapper.dart';
import '../../../data/courses_models.dart';
import '../../../../../features/auth/data/auth_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CourseStudentsTab
// ─────────────────────────────────────────────────────────────────────────────

class CourseStudentsTab extends ConsumerStatefulWidget {
  final MyCourseItem course;
  const CourseStudentsTab({super.key, required this.course});

  @override
  ConsumerState<CourseStudentsTab> createState() => _CourseStudentsTabState();
}

class _CourseStudentsTabState extends ConsumerState<CourseStudentsTab> {
  List<_InviteRow> _invites = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  // Filter: all | accepted | pending
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.get<Map<String, dynamic>>(
        Endpoints.courseInvitationsList(widget.course.id.toString()),
      );
      final data = res.data;
      final items = (data?['items'] as List?) ?? [];
      setState(() {
        _invites = items
            .whereType<Map>()
            .map((e) => _InviteRow.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _loading = false;
      });
    } catch (e) {
      // 404 / 403 / 409 on courses with no invitation collection — treat as empty.
      // Some backends return 409 for public courses where invitations are not applicable.
      final failure = mapApiFailure(e);
      final msg = failure.message;
      final isEmptyOk = failure.statusCode == 404 ||
          failure.statusCode == 403 ||
          failure.statusCode == 409 ||
          msg.toLowerCase().contains('not found');
      setState(() {
        _loading = false;
        _invites = [];
        _error = isEmptyOk ? null : msg;
      });
    }
  }

  List<_InviteRow> get _filtered {
    var list = _invites;
    if (_filter != 'all') {
      list = list.where((i) => i.status == _filter).toList();
    }
    if (_search.trim().isNotEmpty) {
      list = list
          .where((i) =>
              i.email.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final accepted = _invites.where((i) => i.status == 'accepted').length;
    final pending  = _invites.where((i) => i.status == 'pending').length;
    final shown    = _filtered;

    return Container(
      color: AppColors.pageBg,
      child: Column(children: [
        // ── Toolbar ───────────────────────────────────────────────────────
        Container(
          color: AppColors.cardBg,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children: [
            // Stat pills
            _StatPill('${_invites.length}', 'Total', AppColors.primary),
            SizedBox(width: 8),
            _StatPill('$accepted', 'Accepted Invites', AppColors.successText),
            SizedBox(width: 8),
            _StatPill('$pending', 'Pending', AppColors.warningText),
            Spacer(),
            // Search
            SizedBox(
              width: 210,
              height: 34,
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by email...',
                  hintStyle: TextStyle(fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 15, color: AppColors.textHint),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  filled: true,
                  fillColor: AppColors.pageBg,
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: AppColors.primary, width: 1.5)),
                ),
              ),
            ),
            SizedBox(width: 8),
            // Filter chips
            _FilterBtn('All',      'all',      _filter, (v) => setState(() => _filter = v)),
            SizedBox(width: 6),
            _FilterBtn('Accepted', 'accepted', _filter, (v) => setState(() => _filter = v)),
            SizedBox(width: 6),
            _FilterBtn('Pending',  'pending',  _filter, (v) => setState(() => _filter = v)),
            SizedBox(width: 8),
            // Refresh
            Tooltip(
              message: 'Refresh',
              child: InkWell(hoverColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent, overlayColor: WidgetStatePropertyAll(Colors.transparent), 
                onTap: _load,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(Icons.refresh_rounded,
                      size: 17, color: AppColors.textMuted),
                ),
              ),
            ),
          ]),
        ),

        // ── Content ───────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorView(error: _error!, onRetry: _load)
                  : shown.isEmpty
                      ? _buildEmpty()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: shown.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(height: 8),
                          itemBuilder: (_, i) =>
                              _InviteCard(invite: shown[i]),
                        ),
        ),
      ]),
    );
  }

  Widget _buildEmpty() {
    final isFiltered = _filter != 'all' || _search.isNotEmpty;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.people_outline_rounded,
            size: 42, color: AppColors.primary),
        SizedBox(height: 12),
        Text(
          isFiltered ? 'No matching students' : 'No invitations yet',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textTitle),
        ),
        SizedBox(height: 6),
        Text(
          isFiltered
              ? 'Try adjusting your filters.'
              : widget.course.isPrivate
                  ? 'Invite students via the course settings to get started.'
                  : 'This is a public course. Students can join without invitations.',
          style: TextStyle(
              fontSize: 13, color: AppColors.textMuted, height: 1.5),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}

// ── Models ─────────────────────────────────────────────────────────────────────

class _InviteRow {
  final int id;
  final String email;
  final String status;
  final DateTime? acceptedAt;
  final DateTime createdAt;

  const _InviteRow({
    required this.id,
    required this.email,
    required this.status,
    this.acceptedAt,
    required this.createdAt,
  });

  factory _InviteRow.fromJson(Map<String, dynamic> json) {
    return _InviteRow(
      id: (json['id'] as num).toInt(),
      email: (json['invited_email'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      acceptedAt: json['accepted_at'] == null
          ? null
          : DateTime.tryParse(json['accepted_at'].toString()),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _InviteCard extends StatelessWidget {
  final _InviteRow invite;
  const _InviteCard({required this.invite});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final isAccepted = invite.status == 'accepted';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: isAccepted
              ? AppColors.badgeBlueBg
              : AppColors.headerBg,
          child: Text(
            invite.email.isNotEmpty
                ? invite.email[0].toUpperCase()
                : '?',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isAccepted
                    ? AppColors.primary
                    : AppColors.textMuted),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(invite.email,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTitle)),
            SizedBox(height: 3),
            Text(
              isAccepted && invite.acceptedAt != null
                  ? 'Accepted ${_fmt(invite.acceptedAt!)}'
                  : 'Invited ${_fmt(invite.createdAt)}',
              style: TextStyle(
                  fontSize: 11.5, color: AppColors.textMuted),
            ),
          ]),
        ),
        _StatusBadge(status: invite.status),
      ]),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    Color bg, fg;
    String label;
    switch (status.toLowerCase()) {
      case 'accepted':
        bg = AppColors.successBg; fg = AppColors.successText;
        label = 'Accepted'; break;
      case 'pending':
        bg = AppColors.warningSoftBg; fg = AppColors.warningText;
        label = 'Pending'; break;
      case 'revoked':
        bg = AppColors.dangerBg; fg = AppColors.dangerText;
        label = 'Revoked'; break;
      case 'expired':
        bg = AppColors.headerBg; fg = AppColors.textMuted;
        label = 'Expired'; break;
      default:
        bg = AppColors.headerBg; fg = AppColors.textMuted;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String count;
  final String label;
  final Color color;
  const _StatPill(this.count, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(count,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color)),
        SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.8))),
      ]),
    );
  }
}

class _FilterBtn extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onTap;
  const _FilterBtn(this.label, this.value, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final active = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : AppColors.cardBg,
          border: Border.all(
              color: active ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active
                    ? AppColors.primary
                    : AppColors.textMuted)),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, size: 36, color: AppColors.dangerText),
        SizedBox(height: 12),
        Text('Failed to load students',
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15)),
        SizedBox(height: 6),
        Text(error,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: AppColors.textMuted)),
        SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: Icon(Icons.refresh),
          label: Text('Retry'),
        ),
      ]),
    );
  }
}
