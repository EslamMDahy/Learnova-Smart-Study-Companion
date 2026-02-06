import 'package:flutter/material.dart';

class TopHeaderWidget extends StatelessWidget {
  const TopHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEDF2F7))),
      ),
      child: Row(
        children: [
          _buildSearchField(),
          const Spacer(),
          const Icon(Icons.notifications_none_outlined, color: Colors.black),
          const SizedBox(width: 24),
          _buildUserProfile(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: 320,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const TextField(
        style: const TextStyle(color: Colors.black, fontSize: 14),
        decoration: InputDecoration(
          hintText: "Search topics, questions, or student",
          hintStyle: TextStyle(fontSize: 13, color: Colors.black45),
          prefixIcon: Icon(Icons.search, size: 20, color: Colors.black),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return Row(
      children: [
        const CircleAvatar(radius: 18, backgroundColor: Colors.blueAccent),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Khaled Khodary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
            Text("Computer Science Dept.", style: TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
        const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black),
      ],
    );
  }
}