import 'package:flutter/material.dart';

class SettingsContent extends StatefulWidget {
  final VoidCallback onShowNotifications;
  const SettingsContent({super.key, required this.onShowNotifications});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header Row (Title + Buttons) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Account Settings",
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  Text(
                      "Manage your personal information, security credentials, and system preferences.",
                      style: TextStyle(color: Colors.black54)),
                ],
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 18),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Cancel",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Save Changes",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Left Column: Profile Card & Mini Nav ---
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildProfileInfoCard(),
                    const SizedBox(height: 20),
                    _buildSettingsNav(),
                  ],
                ),
              ),
              const SizedBox(width: 32),

              // --- Right Column: Forms Sections ---
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildPersonalInformation(),
                    const SizedBox(height: 24),
                    _buildSecuritySection(),
                    const SizedBox(height: 24),
                    _buildPreferencesSection(),
                    const SizedBox(height: 24),
                    _buildDangerZone(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 1. Profile Summary Card
  Widget _buildProfileInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage('https://via.placeholder.com/150'),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                    color: Color(0xFF2563EB), shape: BoxShape.circle),
                child:
                    const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              )
            ],
          ),
          const SizedBox(height: 16),
          const Text("Khaled Khodary",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          const Text("Student | Computer Science",
              style: TextStyle(color: Colors.black45, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20)),
            child: const Text("● Active Status",
                style: TextStyle(
                    color: Color(0xFF166534),
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 32),
          _buildProfileDetailRow("Member since", "Sep, 2021"),
          const SizedBox(height: 8),
          _buildProfileDetailRow("Last login", "2 hours ago"),
        ],
      ),
    );
  }

  // 2. Settings Mini Navigation
  Widget _buildSettingsNav() {
    return Container(
      clipBehavior: Clip.antiAlias, // لضمان عدم خروج الخط عن حدود الزوايا الدائرية
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _navTile(Icons.person_outline, "Personal Info", true),
          _navTile(Icons.lock_outline, "Security", false),
          _navTile(Icons.tune, "Preferences", false),
          _navTile(Icons.notifications_none, "Notifications", false),
        ],
      ),
    );
  }

  // 3. Personal Information Form
  Widget _buildPersonalInformation() {
    return _sectionWrapper(
      title: "Personal Information",
      subtitle: "Update your personal details here.",
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildInput("First Name", "Khaled")),
              const SizedBox(width: 16),
              Expanded(child: _buildInput("Last Name", "Khodary")),
            ],
          ),
          const SizedBox(height: 16),
          _buildInput("University Email", "khaled.khodary@uni.edu",
              readOnly: true, suffixText: "READ ONLY"),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInput("Student ID", "2021004592")),
              const SizedBox(width: 16),
              Expanded(child: _buildInput("Phone Number", "+1 (555) 123-4567")),
            ],
          ),
          const SizedBox(height: 16),
          _buildInput("Bio / Academic Interests",
              "Interested in Artificial Intelligence, Machine Learning...",
              maxLines: 3),
        ],
      ),
    );
  }

  // 4. Security Section
  Widget _buildSecuritySection() {
    return _sectionWrapper(
      title: "Security",
      subtitle: "Manage your password and authentication settings.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInput("Current Password", "••••••••••••", isPassword: true),
          const SizedBox(height: 16),
          _buildInput("New Password", "", isPassword: true),
          const Text(
              "Minimum 8 characters, at least one uppercase and one number.",
              style: TextStyle(fontSize: 11, color: Colors.black45)),
          const SizedBox(height: 16),
          _buildInput("Confirm New Password", "", isPassword: true),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              elevation: 0,
            ),
            child: const Text("Update Password",
                style: TextStyle(color: Colors.black)),
          )
        ],
      ),
    );
  }

  // 5. Preferences Section
  Widget _buildPreferencesSection() {
    return _sectionWrapper(
      title: "Preferences",
      subtitle: "Customize your system experience.",
      child: Column(
        children: [
          _buildDropdown("Interface Language", "English (US)"),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Assignment Alerts",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  Text("Get notified when new assessments are posted.",
                      style: TextStyle(fontSize: 12, color: Colors.black45)),
                ],
              ),
              Switch(
                  value: true,
                  onChanged: (v) {},
                  activeColor: const Color(0xFF2563EB)),
            ],
          )
        ],
      ),
    );
  }

  // 6. Danger Zone
  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Danger Zone",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                Text(
                    "Once you delete your account, there is no going back. Please be certain.",
                    style: TextStyle(fontSize: 13, color: Color(0xFF991B1B))),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
                side: const BorderSide(color: Color(0xFFFCA5A5))),
            child: const Text("Delete Account",
                style: TextStyle(color: Color(0xFFB91C1C))),
          )
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _sectionWrapper(
      {required String title, required String subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          Text(subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.black45)),
          const Divider(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildInput(String label, String hint,
      {bool readOnly = false,
      String? suffixText,
      int maxLines = 1,
      bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
        const SizedBox(height: 8),
        TextField(
          readOnly: readOnly,
          maxLines: maxLines,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.black, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: readOnly ? const Color(0xFFF8FAFC) : Colors.white,
            suffixIcon: suffixText != null
                ? Container(
                    padding: const EdgeInsets.all(12),
                    child: Text(suffixText,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black26)))
                : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF93C5FD))),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              items: [
                DropdownMenuItem(
                    value: value,
                    child: Text(value,
                        style:
                            const TextStyle(color: Colors.black, fontSize: 14)))
              ],
              onChanged: (v) {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _navTile(IconData icon, String title, bool isSelected) {
    return Stack(
      children: [
        Container(
          color: isSelected ? const Color(0xFFF1F5F9) : Colors.transparent,
          child: ListTile(
            leading: Icon(icon,
                color: isSelected ? const Color(0xFF2563EB) : Colors.black45,
                size: 20),
            title: Text(title,
                style: TextStyle(
                    color:
                        isSelected ? const Color(0xFF2563EB) : Colors.black87,
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal)),
            onTap: () {
              if (title == "Notifications") {
                widget.onShowNotifications(); // استدعاء الانتقال
              }
            },
          ),
        ),
        if (isSelected)
          Positioned(
            left: 0, // ملتصق بالحافة تماماً
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.black45, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ],
    );
  }
}