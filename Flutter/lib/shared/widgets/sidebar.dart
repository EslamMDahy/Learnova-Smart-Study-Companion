import 'package:flutter/material.dart';

class SidebarWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const SidebarWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFEDF2F7))),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 26),
            _LogoBlock(onTap: () => onItemSelected(0)),
            const SizedBox(height: 26),

            _NavItem(
              icon: Icons.grid_view_rounded,
              title: "User Management",
              index: 0,
              selectedIndex: selectedIndex,
              onTap: onItemSelected,
            ),
            _NavItem(
              icon: Icons.bar_chart_rounded,
              title: "Join Requests",
              index: 1,
              selectedIndex: selectedIndex,
              onTap: onItemSelected,
            ),
            _NavItem(
              icon: Icons.workspace_premium_outlined,
              title: "Upgrade plans",
              index: 2,
              selectedIndex: selectedIndex,
              onTap: onItemSelected,
            ),

            const Spacer(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Divider(color: Color(0xFFF1F5F9), height: 22),
            ),

            _NavItem(
              icon: Icons.settings_outlined,
              title: "Settings",
              index: 3,
              selectedIndex: selectedIndex,
              onTap: onItemSelected,
              isBottom: true,
            ),
            _NavItem(
              icon: Icons.help_outline_rounded,
              title: "Help & Support",
              index: 4,
              selectedIndex: selectedIndex,
              onTap: onItemSelected,
              isBottom: true,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/* ---------------- Logo block ---------------- */

class _LogoBlock extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoBlock({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            SizedBox(
              height: 30,
              child: Image.asset(
                "assets/logo.png",
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.auto_awesome,
                  size: 26,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Learnova",
                  style: TextStyle(
                    fontFamily: "Lexend",
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 25 / 20,
                    color: Color(0xFF111418),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "ADMIN PORTAL",
                  style: TextStyle(
                    fontFamily: "Lexend",
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.2,
                    height: 15 / 10,
                    color: Color(0xFF617589),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- Nav item ---------------- */

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool isBottom;

  const _NavItem({
    required this.icon,
    required this.title,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    this.isBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isBottom ? 2 : 3,
      ),
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? const Color(0xFF2563EB) : Colors.black54,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontFamily: "Lexend",
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF111418),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                  height: 21 / 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
