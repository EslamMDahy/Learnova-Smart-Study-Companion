import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:learnova/core/storage/key_value_store_factory.dart';
import 'package:learnova/core/ui/responsive_layout.dart';

import 'design_tokens.dart';

typedef SidebarBuilder = Widget Function(
  bool isCollapsed,
  VoidCallback toggleSidebar,
);

class BaseDashboardShell extends StatefulWidget {
  final SidebarBuilder sidebarBuilder;
  final Widget header;
  final Widget child;

  /// Default expanded desktop sidebar width.
  final double asideWidth;

  /// Minimum width the user can drag the expanded sidebar to.
  final double minAsideWidth;

  /// Maximum width the user can drag the expanded sidebar to.
  final double maxAsideWidth;

  /// Icons-only desktop sidebar width.
  final double collapsedAsideWidth;

  final double contentMaxWidth;
  final EdgeInsets contentPadding;

  final Color? backgroundColor;
  final Color? dividerColor;

  final bool enableResponsive;
  final double drawerBreakpoint;
  final double compactPaddingBreakpoint;
  final EdgeInsets compactPadding;

  final bool wrapChild;

  /// Persist collapsed/expanded preference in browser localStorage on web.
  final bool persistSidebarState;
  final String sidebarStorageKey;
  final bool initialSidebarCollapsed;

  /// Let desktop users resize the expanded sidebar by dragging its right edge.
  final bool enableSidebarResize;
  final bool persistSidebarWidth;
  final String sidebarWidthStorageKey;

  const BaseDashboardShell({
    super.key,
    required this.sidebarBuilder,
    required this.header,
    required this.child,
    this.asideWidth = 288,
    this.minAsideWidth = 224,
    this.maxAsideWidth = 420,
    this.collapsedAsideWidth = 72,
    this.contentMaxWidth = 1400,
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 116, vertical: 32),
    this.backgroundColor,
    this.dividerColor,
    this.enableResponsive = true,
    this.drawerBreakpoint = 1100,
    this.compactPaddingBreakpoint = 900,
    this.compactPadding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    this.wrapChild = true,
    this.persistSidebarState = true,
    this.sidebarStorageKey = 'learnova.sidebar.collapsed',
    this.initialSidebarCollapsed = false,
    this.enableSidebarResize = true,
    this.persistSidebarWidth = true,
    this.sidebarWidthStorageKey = 'learnova.sidebar.width',
  });

  @override
  State<BaseDashboardShell> createState() => _BaseDashboardShellState();
}

class _BaseDashboardShellState extends State<BaseDashboardShell> {
  late bool _isCollapsed;
  late double _asideWidth;
  bool _isResizing = false;
  bool _resizeHandleHovered = false;

  @override
  void initState() {
    super.initState();
    _isCollapsed = _readInitialSidebarState();
    _asideWidth = _readInitialSidebarWidth();
  }

  @override
  void didUpdateWidget(covariant BaseDashboardShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sidebarStorageKey != widget.sidebarStorageKey) {
      _isCollapsed = _readInitialSidebarState();
    }

    if (oldWidget.sidebarWidthStorageKey != widget.sidebarWidthStorageKey) {
      _asideWidth = _readInitialSidebarWidth();
    } else if (oldWidget.minAsideWidth != widget.minAsideWidth ||
        oldWidget.maxAsideWidth != widget.maxAsideWidth ||
        oldWidget.asideWidth != widget.asideWidth) {
      _asideWidth = _clampSidebarWidth(_asideWidth);
    }
  }

  double get _normalizedMinAsideWidth => math.max(
        widget.collapsedAsideWidth,
        widget.minAsideWidth,
      );

  double get _normalizedMaxAsideWidth => math.max(
        _normalizedMinAsideWidth,
        widget.maxAsideWidth,
      );

  double _clampSidebarWidth(double value) {
    return value.clamp(_normalizedMinAsideWidth, _normalizedMaxAsideWidth)
        .toDouble();
  }

  bool _readInitialSidebarState() {
    if (!widget.persistSidebarState) return widget.initialSidebarCollapsed;

    try {
      final stored = createLocalStore().getString(widget.sidebarStorageKey);
      if (stored == null) return widget.initialSidebarCollapsed;

      return stored == 'true';
    } catch (_) {
      return widget.initialSidebarCollapsed;
    }
  }

  double _readInitialSidebarWidth() {
    if (!widget.persistSidebarWidth) {
      return _clampSidebarWidth(widget.asideWidth);
    }

    try {
      final stored = createLocalStore().getString(widget.sidebarWidthStorageKey);
      final parsed = double.tryParse(stored ?? '');
      return _clampSidebarWidth(parsed ?? widget.asideWidth);
    } catch (_) {
      return _clampSidebarWidth(widget.asideWidth);
    }
  }

  void _persistSidebarState() {
    if (!widget.persistSidebarState) return;

    try {
      createLocalStore().setString(
        widget.sidebarStorageKey,
        _isCollapsed ? 'true' : 'false',
      );
    } catch (_) {
      // Keep the UI responsive even if browser storage is unavailable.
    }
  }

  void _persistSidebarWidth() {
    if (!widget.persistSidebarWidth) return;

    try {
      createLocalStore().setString(
        widget.sidebarWidthStorageKey,
        _asideWidth.toStringAsFixed(0),
      );
    } catch (_) {
      // Keep resizing responsive even if browser storage is unavailable.
    }
  }

  void _toggleSidebar() {
    setState(() => _isCollapsed = !_isCollapsed);
    _persistSidebarState();
  }

  void _resizeSidebar(double delta) {
    if (_isCollapsed || !widget.enableSidebarResize) return;

    setState(() {
      _asideWidth = _clampSidebarWidth(_asideWidth + delta);
    });
    _persistSidebarWidth();
  }

  void _resetSidebarWidth() {
    if (_isCollapsed || !widget.enableSidebarResize) return;

    setState(() => _asideWidth = _clampSidebarWidth(widget.asideWidth));
    _persistSidebarWidth();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useDrawer = widget.enableResponsive && width < widget.drawerBreakpoint;

    final dynamicHorizontal = math.max(16.0, math.min(116.0, width * 0.08));
    final dynamicVertical =
        width < widget.compactPaddingBreakpoint ? 16.0 : 32.0;

    final effectivePadding = !widget.enableResponsive
        ? widget.contentPadding
        : width < widget.compactPaddingBreakpoint
            ? learnovaPagePaddingForWidth(width)
            : EdgeInsets.symmetric(
                horizontal: dynamicHorizontal,
                vertical: dynamicVertical,
              );

    final effectiveBody = widget.wrapChild
        ? Padding(
            padding: effectivePadding,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.contentMaxWidth),
                child: widget.child,
              ),
            ),
          )
        : MediaQuery.removePadding(
            context: context,
            removeTop: true,
            removeBottom: false,
            child: widget.child,
          );

    final effectiveBackground = widget.backgroundColor ?? AppColors.pageBg;
    final effectiveDivider = widget.dividerColor ?? AppColors.border;

    final content = Container(
      color: effectiveBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border(bottom: BorderSide(color: effectiveDivider)),
            ),
            child: widget.header,
          ),
          Expanded(child: effectiveBody),
        ],
      ),
    );

    final sidebarWidth = _isCollapsed ? widget.collapsedAsideWidth : _asideWidth;
    final sidebar = AnimatedContainer(
      duration: _isResizing ? Duration.zero : const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      width: sidebarWidth,
      child: Stack(
        children: [
          Positioned.fill(
            child: widget.sidebarBuilder(_isCollapsed, _toggleSidebar),
          ),
          if (widget.enableSidebarResize && !_isCollapsed)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: _SidebarResizeHandle(
                hovered: _resizeHandleHovered,
                active: _isResizing,
                onHoverChanged: (value) {
                  setState(() => _resizeHandleHovered = value);
                },
                onDragStart: () => setState(() => _isResizing = true),
                onDragEnd: () {
                  setState(() => _isResizing = false);
                  _persistSidebarWidth();
                },
                onDragUpdate: _resizeSidebar,
                onDoubleTap: _resetSidebarWidth,
              ),
            ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: effectiveBackground,
      drawer: useDrawer
          ? Drawer(
              width: math.min(320.0, width * 0.88),
              child: SafeArea(
                child: widget.sidebarBuilder(false, () {
                  Navigator.of(context).maybePop();
                }),
              ),
            )
          : null,
      body: useDrawer
          ? content
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sidebar,
                Expanded(child: content),
              ],
            ),
    );
  }
}

class _SidebarResizeHandle extends StatelessWidget {
  final bool hovered;
  final bool active;
  final ValueChanged<bool> onHoverChanged;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDoubleTap;

  const _SidebarResizeHandle({
    required this.hovered,
    required this.active,
    required this.onHoverChanged,
    required this.onDragStart,
    required this.onDragEnd,
    required this.onDragUpdate,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHighlighted = hovered || active;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: Tooltip(
        message: 'Drag to resize sidebar • Double click to reset',
        waitDuration: const Duration(milliseconds: 450),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onDoubleTap: onDoubleTap,
          onHorizontalDragStart: (_) => onDragStart(),
          onHorizontalDragEnd: (_) => onDragEnd(),
          onHorizontalDragCancel: onDragEnd,
          onHorizontalDragUpdate: (details) => onDragUpdate(details.delta.dx),
          child: SizedBox(
            width: 10,
            child: Align(
              alignment: Alignment.centerRight,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                width: isHighlighted ? 3 : 1,
                color: isHighlighted
                    ? AppColors.primary.withValues(alpha: 0.65)
                    : AppColors.sidebarBorder,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
