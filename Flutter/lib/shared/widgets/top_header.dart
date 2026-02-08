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
            child: _SearchField(
              hint: searchHint,
              onChanged: onSearchChanged,
            ),
          ),

          const Spacer(),

          // Right actions
          SizedBox(
            height: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NotifButton(
                  hasBadge: notificationsCount > 0,
                  onTap: onNotificationsTap,
                ),
                const SizedBox(width: 24),
                Container(width: 1, height: 24, color: _divider),
                const SizedBox(width: 24),
                _ProfileDropdown(
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

/* ------------------ Search ------------------ */

class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;

  const _SearchField({required this.hint, this.onChanged});

  static const Color _muted = Color(0xFF617589);
  static const Color _searchBg = Color(0xFFF0F2F4);

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);

    return Theme(
      data: baseTheme.copyWith(
        focusColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
      child: SizedBox(
        width: 300,
        height: 40,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _searchBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.search, size: 20, color: _muted),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    onChanged: onChanged,
                    maxLines: 1,
                    textAlignVertical: TextAlignVertical.center,
                    cursorHeight: 18,
                    style: const TextStyle(
                      fontFamily: "Manrope",
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 19 / 14,
                      color: Color(0xFF111418),
                    ),
                    decoration: InputDecoration(
                      hint: Text(
                        hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: "Manrope",
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 19 / 14,
                          color: _muted,
                        ),
                      ),
                      isDense: true,
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.only(right: 16),
                    ),
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

/* ------------------ Notifications ------------------ */

class _NotifButton extends StatelessWidget {
  final bool hasBadge;
  final VoidCallback? onTap;

  const _NotifButton({required this.hasBadge, this.onTap});

  static const Color _muted = Color(0xFF617589);
  static const Color _danger = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24.01,
      height: 27.99,
      child: InkWell(
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Notifications coming soon")),
              );
            },
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Align(
              alignment: Alignment.center,
              child: Icon(
                Icons.notifications_none_outlined,
                color: _muted,
                size: 24,
              ),
            ),
            if (hasBadge)
              Positioned(
                right: 0.01,
                top: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _danger,
                    borderRadius: BorderRadius.circular(9999),
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

  static const Color _muted = Color(0xFF617589);
  static const Color _divider = Color(0xFFE5E7EB);
  static const Color _text = Color(0xFF111418);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 212.02,
      height: 36,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openMenu(context),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: _divider, width: 1),
                color: const Color(0xFF137FEC),
              ),
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),

            // Name + subtitle
            SizedBox(
              width: 138,
              height: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 14,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: "Lexend",
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                          color: _text,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 16,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: "Manrope",
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 16 / 12,
                          color: _muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Arrow (Figma)
            SizedBox(
              width: 14.02,
              height: 20,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: const Icon(
                  Icons.expand_more_rounded,
                  size: 16,
                  color: _muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMenu(BuildContext context) async {
    final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox;
    final targetBox = context.findRenderObject() as RenderBox;

    // مكان الـ Profile block على الشاشة
    final targetTopLeft = targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final targetRect = Rect.fromLTWH(
      targetTopLeft.dx,
      targetTopLeft.dy,
      targetBox.size.width,
      targetBox.size.height,
    );

    final action = await showMenu<_ProfileAction>(
      context: context,
      elevation: 0,
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,

      // ✅ نزّل المنيو تحت بـ 8px
      position: RelativeRect.fromLTRB(
        targetRect.left,
        targetRect.bottom + 8,
        overlayBox.size.width - targetRect.right,
        overlayBox.size.height - (targetRect.bottom + 8),
      ),

      items: [
        PopupMenuItem<_ProfileAction>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _ModernMenuCard(
            name: name,
            subtitle: subtitle,
            onSelect: (a) => Navigator.of(context).pop(a),
          ),
        ),
      ],
    );

    if (action == null) return;

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
  }
}

/* ------------------ Modern Menu UI ------------------ */

class _ModernMenuCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final ValueChanged<_ProfileAction> onSelect;

  const _ModernMenuCard({
    required this.name,
    required this.subtitle,
    required this.onSelect,
  });

  static const Color _muted = Color(0xFF617589);
  static const Color _divider = Color(0xFFE5E7EB);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _text = Color(0xFF111418);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F2F4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 22,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(color: _divider, width: 1),
                      color: const Color(0xFF137FEC),
                    ),
                    child: const Icon(Icons.person, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: "Lexend",
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _text,
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
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Container(height: 1, color: _divider),

            _ModernMenuItem(
              icon: Icons.person_outline,
              title: "Profile",
              onTap: () => onSelect(_ProfileAction.profile),
            ),
            _ModernMenuItem(
              icon: Icons.settings_outlined,
              title: "Settings",
              onTap: () => onSelect(_ProfileAction.settings),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(height: 1, color: _divider),
            ),

            _ModernMenuItem(
              icon: Icons.logout,
              title: "Logout",
              color: _danger,
              hoverBg: const Color(0x1AEF4444),
              onTap: () => onSelect(_ProfileAction.logout),
            ),

            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _ModernMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  final Color? color;
  final Color? hoverBg;

  const _ModernMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
    this.hoverBg,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF111418);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
        if (states.contains(MaterialState.pressed)) {
          return (hoverBg ?? const Color(0xFFF0F2F4)).withOpacity(0.75);
        }
        if (states.contains(MaterialState.hovered)) {
          return hoverBg ?? const Color(0xFFF6F7F8);
        }
        return Colors.transparent;
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: c,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_right,
              size: 18,
              color: Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}
