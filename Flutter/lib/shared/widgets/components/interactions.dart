import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Web-friendly interaction wrappers (hover / cursor / focus ring).
///
/// Use this on any clickable surface (buttons, cards, table rows, sidebar items)
/// to get consistent pointer cursor + hover feedback + keyboard focus outline.

class AppInteractiveRegion extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final bool enabled;

  /// Optional builder to tweak visuals based on hover/focus.
  final Widget Function(
    BuildContext context,
    bool hovered,
    bool focused,
    Widget child,
  )? builder;

  const AppInteractiveRegion({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.enabled = true,
    this.builder,
  });

  @override
  State<AppInteractiveRegion> createState() => _AppInteractiveRegionState();
}

class _AppInteractiveRegionState extends State<AppInteractiveRegion> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onTap != null;

    Widget c = widget.child;
    if (widget.builder != null) {
      c = widget.builder!(context, _hovered, _focused, c);
    }

    // Focus outline for keyboard navigation (important on web).
    c = AnimatedContainer(
      duration: kIsWeb ? Duration.zero : const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: _focused
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.45),
                width: 2,
              )
            : null,
      ),
      child: c,
    );

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: enabled
            ? (_) {
                if (!kIsWeb) return;
                setState(() => _hovered = true);
              }
            : null,
        onExit: enabled
            ? (_) {
                if (!kIsWeb) return;
                setState(() => _hovered = false);
              }
            : null,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled ? widget.onTap : null,
            borderRadius: widget.borderRadius,
            child: c,
          ),
        ),
      ),
    );
  }
}
