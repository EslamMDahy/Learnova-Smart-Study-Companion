import 'package:flutter/material.dart';

class NotificationsContent extends StatefulWidget {
  const NotificationsContent({super.key});

  @override
  State<NotificationsContent> createState() => _NotificationsContentState();
}

class _NotificationsContentState extends State<NotificationsContent> {
  String selectedFilter = "All";

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildInternalSearch(),
            const SizedBox(height: 20),
            _buildFilters(),
            const SizedBox(height: 32),
            _buildNotificationItem(),
            const SizedBox(height: 40),
            const Center(
              child: Text("End of notifications", 
                style: TextStyle(color: Colors.black26, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Notifications", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            SizedBox(height: 8),
            Text("Stay updated with your courses and system alerts", style: TextStyle(color: Colors.black54, fontSize: 15)),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.check, size: 16),
          label: const Text("Mark all as read"),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildInternalSearch() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: "Search notifications by keyword, professor, or date...",
          hintStyle: TextStyle(color: Colors.black26),
          prefixIcon: Icon(Icons.search, color: Colors.black26),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ["All", "High Priority", "Assignments", "Grades", "Mentions"];
    return Row(
      children: filters.map((filter) {
        bool isSelected = selectedFilter == filter;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (val) => setState(() => selectedFilter = filter),
            // ✅ اللون الأسود عند الاختيار
            selectedColor: const Color(0xFF1E293B), 
            backgroundColor: Colors.white,
            showCheckmark: false,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: isSelected ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotificationItem() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.assignment_outlined, color: Color(0xFF64748B), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Assignment Due Soon: Neural Networks", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                    Text("Yesterday", style: TextStyle(color: Colors.black26, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text("Reminder: The project \"Backpropagation Implementation\" is due tomorrow at 11:59 PM.", 
                  style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}