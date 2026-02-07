import 'package:flutter/material.dart';

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

  const TopHeaderWidget({
    super.key,
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

  static const _bg = Colors.white;
  static const _divider = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 73,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: Color(0xFFEDF2F7))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Search (300x40)
          SizedBox(
            width: 300,
            height: 40,
            child: _SearchField(
              hint: searchHint,
              onChanged: onSearchChanged,
            ),
          ),

          // Right actions group
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Notifications (icon + optional red dot)
              _NotifButton(
                hasBadge: notificationsCount > 0,
                onTap: onNotificationsTap,
              ),

              const SizedBox(width: 24),

              // Divider (1x24)
              Container(width: 1, height: 24, color: _divider),

              const SizedBox(width: 24),

              // Profile dropdown block (avatar + name/subtitle + arrow)
              _ProfileDropdown(
                name: userName,
                subtitle: userSubtitle,
                onLogout: onLogout,
                onProfile: onProfile,
                onSettings: onSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ------------------ Search ------------------ */

class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;

  const _SearchField({required this.hint, this.onChanged});

  static const _muted = Color(0xFF617589);
  static const _searchBg = Color(0xFFF0F2F4);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _searchBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // left icon container (padding-left 16)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(Icons.search, size: 20, color: _muted),
          ),
          // input
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: const TextStyle(
                fontFamily: "Manrope",
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111418),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontFamily: "Manrope",
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _muted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------ Notifications ------------------ */

class _NotifButton extends StatelessWidget {
  final bool hasBadge;
  final VoidCallback? onTap;

  const _NotifButton({required this.hasBadge, this.onTap});

  static const _muted = Color(0xFF617589);
  static const _danger = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Notifications coming soon")),
            );
          },
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 28,
        height: 28,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Align(
              alignment: Alignment.center,
              child: Icon(Icons.notifications_none_outlined, color: _muted, size: 24),
            ),
            if (hasBadge)
              Positioned(
                right: -1,
                top: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _danger,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/* ------------------ Profile Dropdown ------------------ */

enum _ProfileAction { profile, settings, logout }

class _ProfileDropdown extends StatelessWidget {
  final String name;
  final String subtitle;

  final VoidCallback? onLogout;
  final VoidCallback? onProfile;
  final VoidCallback? onSettings;

  const _ProfileDropdown({
    required this.name,
    required this.subtitle,
    this.onLogout,
    this.onProfile,
    this.onSettings,
  });

  static const _muted = Color(0xFF617589);
  static const _divider = Color(0xFFE5E7EB);
  static const _danger = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ProfileAction>(
      tooltip: "",
      position: PopupMenuPosition.under,
      offset: const Offset(0, 10),
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (action) {
        switch (action) {
          case _ProfileAction.profile:
            (onProfile ??
                    () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Profile coming soon")),
                        ))();
            break;
          case _ProfileAction.settings:
            (onSettings ??
                    () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Settings coming soon")),
                        ))();
            break;
          case _ProfileAction.logout:
            (onLogout ??
                    () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Logout handler not provided")),
                        ))();
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _ProfileAction.profile,
          child: _MenuItemRow(icon: Icons.person_outline, text: "Profile"),
        ),
        PopupMenuItem(
          value: _ProfileAction.settings,
          child: _MenuItemRow(icon: Icons.settings_outlined, text: "Settings"),
        ),
        const PopupMenuDivider(height: 10),
        PopupMenuItem(
          value: _ProfileAction.logout,
          child: _MenuItemRow(
            icon: Icons.logout,
            text: "Logout",
            color: _danger,
          ),
        ),
      ],
      child: Row(
        children: [
          // Avatar 36x36 with border
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _divider, width: 1),
              color: const Color(0xFF137FEC),
            ),
            child: const Icon(Icons.person, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),

          // Name + subtitle
          SizedBox(
            width: 138,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: "Lexend",
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                    color: Color(0xFF111418),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: "Manrope",
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Arrow
          const Icon(Icons.keyboard_arrow_down, size: 18, color: _muted),
        ],
      ),
    );
  }
}

class _MenuItemRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _MenuItemRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF111418);
    return Row(
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c,
          ),
        ),
      ],
    );
  }
}
