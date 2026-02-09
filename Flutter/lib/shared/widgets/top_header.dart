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
  });


  static const Color _bg = Colors.white;
  static const Color _bottomBorder = Color(0xFFEDF2F7);
  static const Color _divider = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 73,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _bottomBorder)),
      ),
      child: Row(
        children: [
          // Search left
          SizedBox(
            width: 300,
            height: 40,
            child: FigmaUmSearch40(
              controller: searchController,
              onChanged: onSearchChanged ?? (_) {},
            ),
          ),


          const Spacer(),

          // Right actions
          SizedBox(
            height: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppNotifIconButton(
                  hasBadge: notificationsCount > 0,
                  onTap: onNotificationsTap,
                ),
                const SizedBox(width: 24),
                Container(width: 1, height: 24, color: _divider),
                const SizedBox(width: 24),
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
}
