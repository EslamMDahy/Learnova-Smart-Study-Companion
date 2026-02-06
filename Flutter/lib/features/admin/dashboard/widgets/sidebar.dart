import 'package:flutter/material.dart';

class SidebarWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _buildLogo(),
          const SizedBox(height: 40),
          _navItem(Icons.grid_view_rounded, "User Management", 0),
          _navItem(Icons.bar_chart_rounded, "Join Requests", 1),
          _navItem(Icons.workspace_premium_outlined, "Upgrade plans", 2),
          
          const Spacer(),
          const Divider(indent: 20, endIndent: 20, color: Color(0xFFF1F5F9)),

          _navItem(Icons.settings_outlined, "Settings", 3),
          _navItem(Icons.help_outline_rounded, "Help & Support", 4),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // تأكد من وجود الصورة في الـ assets أو استبدلها بـ Icon مؤقتاً
          Image.asset("assets/logo.png",height: 30,),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Learnova", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
              Text("ADMIN PORTAL", style: TextStyle(fontSize: 10, color: Colors.black54, letterSpacing: 1.2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String title, int index) {
    bool isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => onItemSelected(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF2563EB) : Colors.black54, size: 22),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? const Color(0xFF2563EB) : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}