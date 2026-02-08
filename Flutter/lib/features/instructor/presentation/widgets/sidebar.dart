import 'package:flutter/material.dart';

class InstructorSidebarWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const InstructorSidebarWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const double _asideWidth = 288;
  static const double _innerWidth = 255;

  static const Color _border = Color(0xFFF0F2F4);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _asideWidth,
      child: Container(
        color: Colors.white,
        child: SafeArea(
          top: true,
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: _innerWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _BrandHeader(
                      onTap: () => onItemSelected(0),
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      physics: const ClampingScrollPhysics(),
                      children: [
                        _NavLink(
                          icon: Icons.grid_view_rounded,
                          title: "Dashboard",
                          index: 0,
                          selectedIndex: selectedIndex,
                          onTap: onItemSelected,
                        ),
                        const SizedBox(height: 8),
                        _NavLink(
                          icon: Icons.menu_book_rounded,
                          title: "Course",
                          index: 1,
                          selectedIndex: selectedIndex,
                          onTap: onItemSelected,
                        ),
                        const SizedBox(height: 8),
                        _NavLink(
                          icon: Icons.inventory_2_outlined,
                          title: "Question Bank",
                          index: 2,
                          selectedIndex: selectedIndex,
                          onTap: onItemSelected,
                        ),
                        const SizedBox(height: 8),
                        _NavLink(
                          icon: Icons.quiz_outlined,
                          title: "Quizzes",
                          index: 3,
                          selectedIndex: selectedIndex,
                          onTap: onItemSelected,
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: _innerWidth,
                    padding: const EdgeInsets.only(top: 16),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: _border)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _NavLink(
                          icon: Icons.settings_outlined,
                          title: "Settings",
                          index: 4,
                          selectedIndex: selectedIndex,
                          onTap: onItemSelected,
                        ),
                        const SizedBox(height: 8),
                        _NavLink(
                          icon: Icons.help_outline_rounded,
                          title: "Help & Support",
                          index: 5,
                          selectedIndex: selectedIndex,
                          onTap: onItemSelected,
                        ),
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
  }
}

/* -------------------- Brand Header -------------------- */

class _BrandHeader extends StatelessWidget {
  final VoidCallback onTap;
  const _BrandHeader({required this.onTap});

  static const Color _text = Color(0xFF111418);
  static const Color _muted = Color(0xFF617589);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 255,
      height: 75,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    "assets/logo.png",
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.auto_awesome,
                      size: 22,
                      color: Color(0xFF137FEC),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const SizedBox(
                width: 132,
                height: 43,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 27,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Learnova",
                          style: TextStyle(
                            fontFamily: "Manrope",
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 27 / 18,
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
                          "INSTRUCTOR Portal",
                          style: TextStyle(
                            fontFamily: "Manrope",
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 16 / 12,
                            letterSpacing: 0.6,
                            color: _muted,
                          ),
                        ),
                      ),
                    ),
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

/* -------------------- Nav Link (Figma hover + selected, no setState) -------------------- */

class _NavLink extends StatelessWidget {
  final IconData icon;
  final String title;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _NavLink({
    required this.icon,
    required this.title,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  static const Color _muted = Color(0xFF617589);
  static const Color _primary = Color(0xFF137FEC);

  static const Color _pill = Color(0x1A137FEC); // hover + selected
  static const Color _pressed = Color(0x33137FEC); // pressed darker

  static const double _radius = 12;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;

    final bg = MaterialStateProperty.resolveWith<Color?>((states) {
      if (isSelected) return _pill;
      if (states.contains(MaterialState.pressed)) return _pressed;
      if (states.contains(MaterialState.hovered)) return _pill;
      return Colors.transparent;
    });

    final fg = MaterialStateProperty.resolveWith<Color>((states) {
      if (isSelected) return _primary;
      if (states.contains(MaterialState.hovered)) return _primary;
      return _muted;
    });

    return RepaintBoundary(
      child: SizedBox(
        width: 255,
        height: 44,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(_radius),
            overlayColor: bg,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 24.02,
                    height: 28,
                    child: Center(
                      child: IconTheme(
                        data: IconThemeData(color: fg.resolve({})),
                        child: Builder(
                          builder: (context) {
                            return Icon(
                              icon,
                              size: 22,
                              color: MaterialStateColor.resolveWith(
                                (states) => fg.resolve(states),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        return Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: "Manrope",
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: MaterialStateColor.resolveWith(
                              (states) => fg.resolve(states),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
