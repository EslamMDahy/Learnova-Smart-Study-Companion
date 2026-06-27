import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:learnova/core/ui/toast.dart';
import '../design_tokens.dart';
import 'buttons.dart';
import 'inputs.dart';
import 'dropdowns.dart';

part 'misc_table_components.dart';

/// Misc widgets (layout, table bits, sidebar, uploaders, empty states, etc.).

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AppSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.sectionTitle),
                AppSpacing.gap4,
                Text(subtitle, style: AppText.sectionSubtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

@Deprecated('Use AppButton(variant: AppButtonVariant.soft)')

class AppToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const AppToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.input.copyWith(fontWeight: FontWeight.w500, height: 20 / 14),
              ),
              AppSpacing.gap4,
              Text(subtitle, style: AppText.mutedSmall),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: AppColors.primary,
          inactiveThumbColor: AppColors.cardBg,
          inactiveTrackColor: AppColors.borderSoft,
        ),
      ],
    );
  }
}

class AppNotifIconButton extends StatelessWidget {
  final bool hasBadge;
  final VoidCallback? onTap;

  const AppNotifIconButton({
    super.key,
    required this.hasBadge,
    this.onTap,
  });

  static Color get _muted => AppColors.textMuted;
  static Color get _danger => AppColors.errorDot;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return SizedBox(
      width: 24.01,
      height: 27.99,
      child: InkWell(hoverColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent, overlayColor: const WidgetStatePropertyAll(Colors.transparent), 
        onTap: onTap ??
            () {
              AppToast.info(
                context,
                title: 'Coming soon',
                message: 'Notifications coming soon',
              );
            },
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Align(
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
                    border: Border.all(color: AppColors.cardBg, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AppSidebarItem {
  final IconData icon;
  final String title;
  final int index;

  const AppSidebarItem({
    required this.icon,
    required this.title,
    required this.index,
  });
}

/* -------------------- App Sidebar -------------------- */

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  final String brandTitle;
  final String portalSubtitle;
  final String? logoAssetPath;
  final VoidCallback? onBrandTap;

  final List<AppSidebarItem> mainItems;
  final List<AppSidebarItem> bottomItems;

  final bool isCollapsed;
  final VoidCallback? onToggle;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.portalSubtitle,
    required this.mainItems,
    required this.bottomItems,
    this.brandTitle = 'Learnova',
    this.logoAssetPath = 'assets/logo.webp',
    this.onBrandTap,
    this.isCollapsed = false,
    this.onToggle,
  });

  static const double expandedWidth = 288;
  static const double collapsedWidth = 72;

  static Color get _rightBorder => AppColors.sidebarBorder;
  static Color get _sectionLabel => AppColors.sidebarLabel;
  static Color get _divider => AppColors.divider;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final horizontalPadding = isCollapsed ? 8.0 : 10.0;

    return ClipRect(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border(
            right: BorderSide(color: _rightBorder),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isCollapsed ? 8 : 16,
                  18,
                  isCollapsed ? 8 : 12,
                  0,
                ),
                child: _AppSidebarBrandHeader(
                  title: brandTitle,
                  subtitle: portalSubtitle,
                  logoAssetPath: logoAssetPath,
                  isCollapsed: isCollapsed,
                  onToggle: onToggle,
                  onTap: onBrandTap ??
                      () => onItemSelected(
                            mainItems.isNotEmpty ? mainItems.first.index : 0,
                          ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: isCollapsed
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      if (isCollapsed)
                        const SizedBox(height: 12)
                      else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(6, 20, 6, 4),
                          child: Text(
                            'NAVIGATION',
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: _sectionLabel,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: !kIsWeb && !isCollapsed,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            physics: const ClampingScrollPhysics(),
                            itemCount: mainItems.length,
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: _AppSidebarNavLink(
                                icon: mainItems[i].icon,
                                title: mainItems[i].title,
                                index: mainItems[i].index,
                                selectedIndex: selectedIndex,
                                onTap: onItemSelected,
                                isCollapsed: isCollapsed,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  10,
                  horizontalPadding,
                  14,
                ),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: _divider)),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < bottomItems.length; i++) ...[
                      _AppSidebarNavLink(
                        icon: bottomItems[i].icon,
                        title: bottomItems[i].title,
                        index: bottomItems[i].index,
                        selectedIndex: selectedIndex,
                        onTap: onItemSelected,
                        isCollapsed: isCollapsed,
                      ),
                      if (i != bottomItems.length - 1)
                        const SizedBox(height: 2),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------- Brand Header -------------------- */

class _AppSidebarBrandHeader extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback? onToggle;
  final String title;
  final String subtitle;
  final String? logoAssetPath;
  final bool isCollapsed;

  const _AppSidebarBrandHeader({
    required this.onTap,
    required this.title,
    required this.subtitle,
    required this.logoAssetPath,
    required this.isCollapsed,
    this.onToggle,
  });

  static Color get _text => AppColors.textTitle;
  static Color get _muted => AppColors.textGray500;
  static Color get _logoBg => AppColors.cardBg;
  static Color get _logoBorder => AppColors.border;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    if (isCollapsed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: title,
            waitDuration: const Duration(milliseconds: 350),
            child: _SidebarLogoButton(
              logoAssetPath: logoAssetPath,
              onTap: onTap,
            ),
          ),
          const SizedBox(height: 8),
          _SidebarToggleButton(
            isCollapsed: isCollapsed,
            onToggle: onToggle,
          ),
        ],
      );
    }

    return Row(
      children: [
        _SidebarLogoButton(
          logoAssetPath: logoAssetPath,
          onTap: onTap,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _text,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _SidebarToggleButton(
          isCollapsed: isCollapsed,
          onToggle: onToggle,
        ),
      ],
    );
  }
}

class _SidebarLogoButton extends StatelessWidget {
  final String? logoAssetPath;
  final VoidCallback onTap;

  const _SidebarLogoButton({
    required this.logoAssetPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return InkWell(
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _AppSidebarBrandHeader._logoBg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _AppSidebarBrandHeader._logoBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: logoAssetPath == null
              ? const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: AppColors.primary,
                )
              : Image.asset(
                  logoAssetPath!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SidebarToggleButton extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback? onToggle;

  const _SidebarToggleButton({
    required this.isCollapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Tooltip(
      message: isCollapsed ? 'Open sidebar' : 'Close sidebar',
      waitDuration: const Duration(milliseconds: 350),
      child: Semantics(
        button: true,
        label: isCollapsed ? 'Open sidebar' : 'Close sidebar',
        child: IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          splashRadius: 18,
          onPressed: onToggle,
          icon: _ChatGptSidebarToggleIcon(
            isCollapsed: isCollapsed,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _ChatGptSidebarToggleIcon extends StatelessWidget {
  final bool isCollapsed;
  final Color color;

  const _ChatGptSidebarToggleIcon({
    required this.isCollapsed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(20),
      painter: _ChatGptSidebarToggleIconPainter(
        isCollapsed: isCollapsed,
        color: color,
      ),
    );
  }
}

class _ChatGptSidebarToggleIconPainter extends CustomPainter {
  final bool isCollapsed;
  final Color color;

  const _ChatGptSidebarToggleIconPainter({
    required this.isCollapsed,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.65
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rect = Rect.fromLTWH(
      size.width * 0.14,
      size.height * 0.18,
      size.width * 0.72,
      size.height * 0.64,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3.2)),
      stroke,
    );

    // ChatGPT-style sidebar glyph: a rounded window with a slim side rail.
    final railX = isCollapsed
        ? rect.right - size.width * 0.25
        : rect.left + size.width * 0.25;
    canvas.drawLine(
      Offset(railX, rect.top + size.height * 0.08),
      Offset(railX, rect.bottom - size.height * 0.08),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _ChatGptSidebarToggleIconPainter oldDelegate) {
    return oldDelegate.isCollapsed != isCollapsed ||
        oldDelegate.color != color;
  }
}

/* -------------------- Nav Link -------------------- */

class _AppSidebarNavLink extends StatefulWidget {
  final IconData icon;
  final String title;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool isCollapsed;

  const _AppSidebarNavLink({
    required this.icon,
    required this.title,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    required this.isCollapsed,
  });

  @override
  State<_AppSidebarNavLink> createState() => _AppSidebarNavLinkState();
}

class _AppSidebarNavLinkState extends State<_AppSidebarNavLink> {
  bool _hovered = false;
  bool _focused = false;

  static Color get _primary => AppColors.primary;
  static Color get _selectedBg => AppColors.sidebarSelectedBg;
  static Color get _hoverBg => AppColors.sidebarHoverBg;
  static Color get _idleFg => AppColors.textMuted;
  static Color get _selectedFg => AppColors.primary;
  static Color get _hoverFg => AppColors.textGray;
  static Color get _barColor => AppColors.primary;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final sel = widget.selectedIndex == widget.index;

    final bg = sel ? _selectedBg : _hovered ? _hoverBg : Colors.transparent;
    final fg = sel ? _selectedFg : _hovered ? _hoverFg : _idleFg;

    final link = Semantics(
      button: true,
      selected: sel,
      label: widget.title,
      child: Focus(
        onFocusChange: (v) => setState(() => _focused = v),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => widget.onTap(widget.index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              height: 42,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                border: _focused
                    ? Border.all(
                        color: _primary.withValues(alpha: 0.45),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  if (sel)
                    Positioned(
                      left: 0,
                      top: 10,
                      bottom: 10,
                      child: Container(
                        width: 3,
                        decoration: BoxDecoration(
                          color: _barColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isCollapsed ? 0 : 12,
                    ),
                    child: Row(
                      mainAxisAlignment: widget.isCollapsed
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        Icon(widget.icon, size: 19, color: fg),
                        if (!widget.isCollapsed) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight:
                                    sel ? FontWeight.w700 : FontWeight.w500,
                                color: fg,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!widget.isCollapsed) return link;

    return Tooltip(
      message: widget.title,
      waitDuration: const Duration(milliseconds: 350),
      child: link,
    );
  }
}


class AppFormHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AppFormHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return AppDialogTitleBlock(title: title, subtitle: subtitle);
  }
}


// ===================== Auth / Forms Reusables =====================

class AppErrorBox extends StatelessWidget {
  final String message;
  const AppErrorBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Text(
        message,
        style: AppText.mutedSmall.copyWith(
          color: AppColors.dangerTitle,
          fontSize: 13,
          height: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AppSegmentOption<T> {
  final String label;
  final T value;
  const AppSegmentOption({required this.label, required this.value});
}



class AppSegmentedControl<T> extends StatelessWidget {
  final List<AppSegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool disabled;

  const AppSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.disabled = false,
  });

  static Color get _bg => AppColors.borderGray;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _bg,
      ),
      child: Row(
        children: [
          for (int i = 0; i < options.length; i++) ...[
            Expanded(
              child: _SegmentChip(
                text: options[i].label,
                selected: options[i].value == value,
                onTap: disabled ? null : () => onChanged(options[i].value),
              ),
            ),
            if (i != options.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback? onTap;

  const _SegmentChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: kIsWeb ? Duration.zero : const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.cardBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.shadowThin,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.title : AppColors.textGray500,
              height: 20 / 14,
            ),
          ),
        ),
      ),
    );
  }
}

class AppLabeledIconField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const AppLabeledIconField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final radius = BorderRadius.circular(10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        AppSpacing.gap6,
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          validator: validator,
          style: TextStyle(
            color: AppColors.title,
            fontSize: 15,
            height: 1.4,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.hint,
            prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: AppColors.pageBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: AppColors.borderGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: AppColors.dangerText),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: AppColors.dangerText, width: 1.5),
            ),
            errorStyle: const TextStyle(fontSize: 12, height: 1.2),
          ),
        ),
      ],
    );
  }
}

class AppPasswordStrengthHints extends StatelessWidget {
  final String password;
  const AppPasswordStrengthHints({super.key, required this.password});

  bool _has(String pattern) => RegExp(pattern).hasMatch(password);
  bool get _len => password.trim().length >= 8;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    Widget chip(String text, bool ok) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: ok ? AppColors.successBg : AppColors.divider,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: ok ? AppColors.greenBorder : AppColors.borderGray,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: ok ? AppColors.successText : AppColors.textGray500,
            fontWeight: ok ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('8+ chars', _len),
        chip('A-Z', _has(r'[A-Z]')),
        chip('a-z', _has(r'[a-z]')),
        chip('0-9', _has(r'\d')),
        chip('Symbol', _has(r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\]=+~`]')),
      ],
    );
  }
}

enum AppInfoType { success, error }

class AppInfoCard extends StatelessWidget {
  final AppInfoType type;
  final String title;
  final String message;

  const AppInfoCard({
    super.key,
    required this.type,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final isSuccess = type == AppInfoType.success;

    final bg = isSuccess ? AppColors.successBg : AppColors.dangerBg;
    final border = isSuccess ? AppColors.greenBorder : AppColors.dangerBorder;
    final icon =
        isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;
    final iconColor = isSuccess ? AppColors.successText : AppColors.dangerTitle;
    final textColor = iconColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppAuthHeaderIcon extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AppAuthHeaderIcon({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(icon, color: AppColors.primary, size: 26),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: AppText.h1.copyWith(fontSize: 28, color: AppColors.title),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: AppText.subtitle.copyWith(
            color: AppColors.muted,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
class AppPrimaryLoadingButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final double height;

  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  const AppPrimaryLoadingButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
    this.height = 50,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  TextStyle _autoTextStyle(Color fg) {
    if (height <= 36) {
      return TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600);
    }
    if (height <= 40) {
      return TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600);
    }
    if (height <= 48) {
      return TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w700);
    }
    return TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w700);
  }

  EdgeInsets _autoPadding() {
    
    if (height <= 36) return const EdgeInsets.symmetric(horizontal: 10);
    if (height <= 40) return const EdgeInsets.symmetric(horizontal: 12);
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  double _loaderSize() {
    if (height <= 36) return 14;
    if (height <= 40) return 16;
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final bg = backgroundColor ?? AppColors.primary;
    final fg = foregroundColor ?? Colors.white;

    final borderSide = borderColor == null
        ? BorderSide.none
        : BorderSide(color: borderColor!);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.6),
          disabledForegroundColor: fg.withValues(alpha: 0.85),
          elevation: 0,
          padding: _autoPadding(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: borderSide,
          ),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? SizedBox(
                width: _loaderSize(),
                height: _loaderSize(),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown, 
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _autoTextStyle(fg),
                ),
              ),
      ),
    );
  }
}

class AppBackLink extends StatelessWidget {
  final String? label;
  final VoidCallback? onTap;
  final bool showLabel;

  const AppBackLink({
    super.key,
    this.label,
    required this.onTap,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return InkWell(hoverColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent, overlayColor: const WidgetStatePropertyAll(Colors.transparent), 
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textMuted),
          if (showLabel && (label ?? '').isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              label!,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}



@Deprecated('Use AppBackLink(showLabel: true)')

class AppBackLinkLabeled extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const AppBackLinkLabeled({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return AppBackLink(label: label, onTap: onTap, showLabel: true);
  }
}


// ===================== Auth Layout / Helpers =====================

class AppAuthShell extends StatelessWidget {
  final bool isMobile;
  final Widget child;
  final double maxWidth;

  const AppAuthShell({
    super.key,
    required this.child,
    this.isMobile = false,
    this.maxWidth = 420,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      color: AppColors.pageBg,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 56),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AppAuthOrDivider extends StatelessWidget {
  const AppAuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR CONTINUE WITH',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class AppSocialButton extends StatelessWidget {
  final String label;
  final String imagePath;
  final VoidCallback onTap;
  final bool disabled;

  const AppSocialButton({
    super.key,
    required this.label,
    required this.imagePath,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.borderSoft),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: disabled ? null : onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 40, height: 35, fit: BoxFit.contain),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(color: AppColors.textTitle, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class AppSuccessBanner extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onClose;

  const AppSuccessBanner({
    super.key,
    required this.title,
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: kIsWeb ? Duration.zero : const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greenBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.check_circle,
                  color: AppColors.successText, size: 20,),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.successText,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: TextStyle(
                      color: AppColors.successText,
                      fontSize: 13,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(hoverColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent, overlayColor: const WidgetStatePropertyAll(Colors.transparent), 
              borderRadius: BorderRadius.circular(8),
              onTap: onClose,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child:
                    Icon(Icons.close, size: 16, color: AppColors.successText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppRememberForgotRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onForgot;
  final bool disabled;

  const AppRememberForgotRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onForgot,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Row(
      children: [
        Checkbox(
          value: value,
          activeColor: AppColors.primary,
          checkColor: Colors.white,
          onChanged: disabled ? null : onChanged,
        ),
        Text(
          'Remember me',
          style: TextStyle(color: AppColors.textTitle, fontSize: 14),
        ),
        const Spacer(),
        TextButton(
          onPressed: disabled ? null : onForgot,
          child: const Text(
            'Forgot Password?',
            style: TextStyle(color: AppColors.primary, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class AppOutlinedLoadingButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final double height;

  const AppOutlinedLoadingButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}

class AppTextLoadingButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const AppTextLoadingButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return TextButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

// ===================== Dialog / Admin Form Reusables =====================

class AppDialogShell extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double maxHeight;

  const AppDialogShell({
    super.key,
    required this.child,
    this.maxWidth = 1184,
    this.maxHeight = 820,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Dialog(
      backgroundColor: AppColors.headerBg, // close to figma bg
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }
}

class AppDialogTitleBlock extends StatelessWidget {
  final String title;
  final String subtitle;

  const AppDialogTitleBlock({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.h1),
        AppSpacing.gap8,
        Text(subtitle, style: AppText.subtitle),
      ],
    );
  }
}

class AppCardHeaderRow extends StatelessWidget {
  final IconData icon;
  final String title;

  const AppCardHeaderRow({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 25 / 20,
            color: AppColors.title,
          ),
        ),
      ],
    );
  }
}

class AppSubHeaderText extends StatelessWidget {
  final String title;

  const AppSubHeaderText({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.title,
      ),
    );
  }
}

class AppLabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  final double gap;

  const AppLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.gap = 8,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        SizedBox(height: gap),
        child,
      ],
    );
  }
}

class AppTextField48 extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final int? maxLen;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  const AppTextField48({
    super.key,
    required this.controller,
    required this.hint,
    this.focusNode,
    this.maxLen,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLength: maxLen,
        enabled: enabled,
        onChanged: onChanged,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.title,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.muted,
          ),
          filled: true,
          fillColor: AppColors.cardBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.borderSoft),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// Inline info banner with primary brand tint.
class AppInfoInlineBox extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;

  const AppInfoInlineBox({
    super.key,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return InkWell(hoverColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent, overlayColor: const WidgetStatePropertyAll(Colors.transparent), 
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.infoBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Need help? Chat with our support team or learn more about how organizations work.',
                style: TextStyle(
                  fontSize: 13,
                  height: 20 / 13,
                  color: AppColors.infoText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppLogoUrlUploader extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onUploadPressed;

  const AppLogoUrlUploader({
    super.key,
    required this.controller,
    this.onChanged,
    this.onUploadPressed,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.headerBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Icon(Icons.image_outlined, color: AppColors.muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(fontSize: 14, color: AppColors.title),
              decoration: InputDecoration(
                hintText: 'Paste logo URL (optional)',
                hintStyle: TextStyle(fontSize: 14, color: AppColors.muted),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onUploadPressed ??
                () {
                  AppToast.info(
                  context,
                  title: 'Coming soon',
                  message: 'Upload coming soon — use URL for now.',
                );
                },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Upload Logo',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;

  final double maxWidth;
  final EdgeInsets padding;

  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.maxWidth = 720,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
  });

  void _handleTap(BuildContext context) {
    FocusScope.of(context).unfocus();
    onPrimaryAction();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppText.h1.copyWith(
                  fontSize: 48,
                  height: 60 / 48,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppText.subtitle,
              ),
              const SizedBox(height: 22),
              Semantics(
                button: true,
                label: primaryActionLabel,
                child: AppButton(
                  label: primaryActionLabel,
                  onTap: () => _handleTap(context),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
