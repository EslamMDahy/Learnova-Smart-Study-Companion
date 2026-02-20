import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_ui_components.dart';

class TopHeaderWidget extends StatelessWidget {
  final String searchHint;
  final String userName;
  final String userSubtitle;
  final int notificationsCount;

  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onNotificationsTap;

  final VoidCallback? onLogout;
  final VoidCallback? onProfile;
  final VoidCallback? onSettings;

  final VoidCallback? onMenuTap;
  final TextEditingController searchController;

  const TopHeaderWidget({
    super.key,
    required this.searchController,
    this.searchHint = "Search topics, questions, or students...",
    this.userName = "Alex Morgan",
    this.userSubtitle = "Computer Science Dept.",
    this.notificationsCount = 0,
    this.onSearchChanged,
    this.onNotificationsTap,
    this.onLogout,
    this.onProfile,
    this.onSettings,
    this.onMenuTap,
  });

  static const Color _bg = Colors.white;
  static const Color _bottomBorder = Color(0xFFEDF2F7);
  static const Color _divider = Color(0xFFE5E7EB);

  static const double _drawerBp = 1100;
  static const double _searchCollapseBp = 700;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    final isDrawerMode = w < _drawerBp;
    final collapseSearch = w < _searchCollapseBp;

    return Container(
      height: 73,
      padding: EdgeInsets.symmetric(
        horizontal: w < 900 ? 16 : 32,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _bottomBorder)),
      ),
      child: Row(
        children: [
          if (isDrawerMode) ...[
            _HeaderIconButton(
              icon: Icons.menu,
              tooltip: 'Open menu',
              onTap: onMenuTap ??
                  () {
                    Scaffold.of(context).openDrawer();
                  },
            ),
            const SizedBox(width: 12),
          ],
          if (!collapseSearch)
            SizedBox(
              width: w < 900 ? 240 : 320,
              height: 40,
              child: FigmaUmSearch40(
                controller: searchController,
                onChanged: onSearchChanged ?? (_) {},
              ),
            )
          else
            _HeaderIconButton(
              icon: Icons.search,
              tooltip: 'Search',
              onTap: () => _openSearchDialog(context),
            ),
          const Spacer(),
          SizedBox(
            height: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppNotifIconButton(
                  hasBadge: notificationsCount > 0,
                  onTap: onNotificationsTap,
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 24, color: _divider),
                const SizedBox(width: 16),
                AppProfileDropdown(
                  name: userName,
                  subtitle: userSubtitle,
                  onLogout: onLogout,
                  onProfile: onProfile,
                  onSettings: onSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openSearchDialog(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final maxDialogWidth = math.min(520.0, math.max(280.0, w - 48.0));

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: const Text('Search'),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxDialogWidth),
            child: TextField(
              controller: searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: onSearchChanged ?? (_) {},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, size: 22, color: const Color(0xFF617589)),
        splashRadius: 22,
      ),
    );
  }
}
