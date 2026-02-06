import 'package:flutter/material.dart';

class JoinRequestsContent extends StatefulWidget {
  const JoinRequestsContent({super.key});

  @override
  State<JoinRequestsContent> createState() => _JoinRequestsContentState();
}

class _JoinRequestsContentState extends State<JoinRequestsContent> {
  String selectedRole = "All Roles";
  String selectedStatus = "All Status";

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Join Requests",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const Text(
            "Manage student and instructor accounts, roles, and permissions.",
            style: TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Search by name, ID, or email...",
                      prefixIcon: Icon(Icons.search, size: 20, color: Colors.black),
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.black26),
                    ),
                  ),
                ),
                _buildDropdown(selectedRole, ["All Roles", "Instructor", "Student"], (v) => setState(() => selectedRole = v!)),
                const SizedBox(width: 12),
                _buildDropdown(selectedStatus, ["All Status", "Active", "Pending"], (v) => setState(() => selectedStatus = v!)),
                const SizedBox(width: 12),
                const Icon(Icons.filter_list, color: Colors.black),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Data Table Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildTableHeader(),
                // البيانات هنا مطابقة للصورة الأخيرة (الأسماء والحالات)
                _buildUserRow("Dr. Sarah Miller", "sarah.miller@univ.edu", "FAC-2023-01", "Instructor", "Computer Science", "Aug 15, 2023", "Active"),
                _buildUserRow("John Doe", "john.doe@student.univ.edu", "STU-2023-889", "Student", "Engineering", "Sep 01, 2023", "Active"),
                _buildUserRow("Michael Chen", "m.chen@univ.edu", "FAC-2022-45", "Instructor", "Mathematics", "Jan 12, 2022", "Pending"),
                _buildUserRow("Emma Stone", "emma.s@student.univ.edu", "STU-2023-112", "Student", "Psychology", "Sep 05, 2023", "Pending"), // كانت Pending في الصورة
                _buildUserRow("David Kim", "d.kim@univ.edu", "FAC-2021-99", "Instructor", "Physics", "Mar 20, 2021", "Active"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- الهيلبرز (نفس اللي استخدمناهم لضمان توحيد التصميم) ---

  Widget _buildDropdown(String currentVal, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentVal,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black),
          style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val, style: const TextStyle(color: Colors.black)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: const [
          SizedBox(width: 40),
          Expanded(flex: 3, child: Text("USER INFO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black))),
          Expanded(flex: 2, child: Text("ROLE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black))),
          Expanded(flex: 2, child: Text("DEPARTMENT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black))),
          Expanded(flex: 2, child: Text("JOINED DATE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black))),
          Expanded(flex: 2, child: Text("STATUS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black))),
          Expanded(flex: 1, child: Text("ACTIONS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black))),
        ],
      ),
    );
  }

  Widget _buildUserRow(String name, String email, String id, String role, String dept, String date, String status) {
    Color statusColor;
    if (status == "Active") {
      statusColor = Colors.green;
    } else if (status == "Pending") {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    Color roleBg = role == "Instructor" ? const Color(0xFFF3E8FF) : const Color(0xFFDBEAFE);
    Color roleText = role == "Instructor" ? const Color(0xFF7C3AED) : const Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          Checkbox(value: false, onChanged: (v) {}, visualDensity: VisualDensity.compact),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const CircleAvatar(radius: 16, backgroundColor: Color(0xFFE2E8F0), child: Icon(Icons.person, size: 20, color: Colors.white)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
                    Text(email, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    Text("ID: $id", style: const TextStyle(fontSize: 10, color: Colors.black26)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: UnconstrainedBox(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: roleBg, borderRadius: BorderRadius.circular(20)),
                child: Text(role, style: TextStyle(color: roleText, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Expanded(flex: 2, child: Text(dept, style: const TextStyle(fontSize: 13, color: Colors.black))),
          Expanded(flex: 2, child: Text(date, style: const TextStyle(fontSize: 13, color: Colors.black))),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(status, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            ),
          ),
          const Expanded(
            flex: 1,
            child: Icon(Icons.more_vert, size: 18, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}