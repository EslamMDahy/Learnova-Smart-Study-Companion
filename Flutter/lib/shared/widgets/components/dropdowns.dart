import 'package:flutter/material.dart';
import '../design_tokens.dart';

/// Dropdowns / selects (canonical + legacy wrappers + profile menu).

class AppDropdown extends StatelessWidget {
  final double? width;
  final double height;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const AppDropdown({
    super.key,
    this.width,
    this.height = 40,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: enabled ? AppColors.cSurface : AppColors.headerBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cBorder),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: height >= 48 ? 12 : 10),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 22, color: AppColors.cGray500),
              onChanged: enabled ? (v) => onChanged(v!) : null,
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
            ),
          ),
        ),
      ),
    );

    return child;
  }
}

class AppDropdown48 extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const AppDropdown48({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppDropdown(
      height: 48,
      value: value,
      items: items,
      onChanged: onChanged,
      enabled: enabled,
    );
  }
}

class AppLabeledSelect extends StatelessWidget {
  final String label;
  final String value;

  const AppLabeledSelect({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        AppSpacing.gap6,
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSoft),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: Text(value, style: AppText.input.copyWith(height: 20 / 14))),
              const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ],
    );
  }
}

// -------- Notifications atom --------

class FigmaUmDropdown40 extends StatelessWidget {
  final double width;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const FigmaUmDropdown40({
    super.key,
    required this.width,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppDropdown(
      width: width,
      height: 40,
      value: value,
      items: items,
      onChanged: onChanged,
    );
  }
}

class JrDropdownFigma extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const JrDropdownFigma({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppDropdown(
      height: 40,
      value: value,
      items: items,
      onChanged: onChanged,
    );
  }
}

enum AppProfileAction { profile, settings, logout }

class AppProfileDropdown extends StatelessWidget {
  final String name;
  final String subtitle;

  final VoidCallback? onLogout;
  final VoidCallback? onProfile;
  final VoidCallback? onSettings;

  const AppProfileDropdown({
    super.key,
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

            // Arrow
            const SizedBox(
              width: 14.02,
              height: 20,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Icon(
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

    final targetTopLeft = targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final targetRect = Rect.fromLTWH(
      targetTopLeft.dx,
      targetTopLeft.dy,
      targetBox.size.width,
      targetBox.size.height,
    );

    final action = await showMenu<AppProfileAction>(
      context: context,
      elevation: 0,
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      position: RelativeRect.fromLTRB(
        targetRect.left,
        targetRect.bottom + 8,
        overlayBox.size.width - targetRect.right,
        overlayBox.size.height - (targetRect.bottom + 8),
      ),
      items: [
        PopupMenuItem<AppProfileAction>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _AppModernMenuCard(
            name: name,
            subtitle: subtitle,
            onSelect: (a) => Navigator.of(context).pop(a),
          ),
        ),
      ],
    );

    if (action == null) return;

    switch (action) {
      case AppProfileAction.profile:
        (onProfile ??
            () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profile coming soon")),
                ))();
        break;
      case AppProfileAction.settings:
        (onSettings ??
            () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Settings coming soon")),
                ))();
        break;
      case AppProfileAction.logout:
        (onLogout ??
            () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Logout handler not provided")),
                ))();
        break;
    }
  }
}

class _AppModernMenuCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final ValueChanged<AppProfileAction> onSelect;

  const _AppModernMenuCard({
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

            _AppModernMenuItem(
              icon: Icons.person_outline,
              title: "Profile",
              onTap: () => onSelect(AppProfileAction.profile),
            ),
            _AppModernMenuItem(
              icon: Icons.settings_outlined,
              title: "Settings",
              onTap: () => onSelect(AppProfileAction.settings),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(height: 1, color: _divider),
            ),

            _AppModernMenuItem(
              icon: Icons.logout,
              title: "Logout",
              color: _danger,
              hoverBg: const Color(0x1AEF4444),
              onTap: () => onSelect(AppProfileAction.logout),
            ),

            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _AppModernMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  final Color? color;
  final Color? hoverBg;

  const _AppModernMenuItem({
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

// ===================== Sidebar components =====================

/* -------------------- Models -------------------- */
