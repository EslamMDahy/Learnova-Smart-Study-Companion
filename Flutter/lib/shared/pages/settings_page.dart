import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // right panel sections
  int _sectionIndex = 0; // 0 personal, 1 security, 2 preferences, 3 notifications

  // sample controllers (UI only)
  final firstName = TextEditingController(text: "Alex");
  final lastName = TextEditingController(text: "Johnson");
  final bio = TextEditingController(
    text:
        "Interested in Artificial Intelligence, Machine Learning, and Human-Computer Interaction.",
  );

  // read-only fields
  final email = "alex.johnson@uni.edu";
  final studentId = "2021004592";

  // toggles
  bool assignmentAlerts = true;

  // security controllers (UI only)
  final currentPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    bio.dispose();
    currentPassword.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF6F7F8);
    const textDark = Color(0xFF111418);
    const textMuted = Color(0xFF617589);
    const border = Color(0xFFE5E7EB);

    return Container(
      color: bg,
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row + actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Account Settings",
                            style: TextStyle(
                              fontFamily: "Manrope",
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              height: 40 / 36,
                              letterSpacing: -0.9,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Manage your personal information, security credentials, and system preferences.",
                            style: TextStyle(
                              fontFamily: "Manrope",
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 24 / 16,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        _SoftButton(
                          label: "Cancel",
                          onTap: () => _toast(context, "Canceled (UI only)."),
                        ),
                        const SizedBox(width: 12),
                        _PrimaryButton(
                          label: "Save Changes",
                          onTap: () => _toast(context, "Saved (UI only)."),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Main layout
                LayoutBuilder(
                  builder: (context, c) {
                    final isWide = c.maxWidth >= 980;

                    final left = Column(
                      children: [
                        // profile card
                        const _ProfileCard(
                          name: "Alex Johnson",
                          subtitle: "Student | Computer Science",
                          memberSince: "Sep, 2021",
                          lastLogin: "2 hours ago",
                        ),
                        const SizedBox(height: 16),

                        // nav card
                        _NavCard(
                          selectedIndex: _sectionIndex,
                          onSelect: (i) => setState(() => _sectionIndex = i),
                        ),
                      ],
                    );

                    final right = Column(
                      children: [
                        if (_sectionIndex == 0) _buildPersonalInfoCard(border),
                        if (_sectionIndex == 1) _buildSecurityCard(border),
                        if (_sectionIndex == 2) _buildPreferencesCard(border),
                        if (_sectionIndex == 3) _buildNotificationsCard(border),
                        const SizedBox(height: 16),
                        _buildDangerZone(border),
                      ],
                    );

                    if (!isWide) {
                      return Column(
                        children: [
                          left,
                          const SizedBox(height: 16),
                          right,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 264, child: left),
                        const SizedBox(width: 32),
                        Expanded(child: right),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(Color border) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: "Personal Information",
            subtitle: "Update your personal details here.",
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, c) {
              final isWide = c.maxWidth >= 780;

              final first = _LabeledInput(
                label: "First Name",
                controller: firstName,
                hint: "First name",
              );
              final last = _LabeledInput(
                label: "Last Name",
                controller: lastName,
                hint: "Last name",
              );

              final row = isWide
                  ? Row(
                      children: [
                        Expanded(child: first),
                        const SizedBox(width: 24),
                        Expanded(child: last),
                      ],
                    )
                  : Column(
                      children: [
                        first,
                        const SizedBox(height: 16),
                        last,
                      ],
                    );

              return Column(
                children: [
                  row,
                  const SizedBox(height: 16),

                  _ReadOnlyInput(
                    label: "University Email",
                    value: email,
                    rightTag: "Read Only",
                    icon: Icons.email_outlined,
                  ),

                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, c2) {
                      final wide2 = c2.maxWidth >= 780;

                      final id = _ReadOnlyInput(
                        label: "Student ID",
                        value: studentId,
                        icon: Icons.badge_outlined,
                      );

                      final phone = _LabeledInput(
                        label: "Phone Number",
                        controller: TextEditingController(text: "+1 (555) 123-4567"),
                        hint: "+1 ...",
                      );

                      // avoid creating controller each build in real code; here UI only
                      // ignore: unnecessary_null_comparison

                      return wide2
                          ? Row(
                              children: [
                                Expanded(child: id),
                                const SizedBox(width: 24),
                                Expanded(child: phone),
                              ],
                            )
                          : Column(
                              children: [
                                id,
                                const SizedBox(height: 16),
                                phone,
                              ],
                            );
                    },
                  ),

                  const SizedBox(height: 16),

                  _LabeledTextarea(
                    label: "Bio / Academic Interests",
                    controller: bio,
                    hint: "Write something...",
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(Color border) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: "Security",
            subtitle: "Manage your password and authentication settings.",
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, c) {
              final isWide = c.maxWidth >= 780;

              final left = Column(
                children: [
                  _LabeledPassword(
                    label: "Current Password",
                    controller: currentPassword,
                  ),
                  const SizedBox(height: 20),
                  _LabeledPassword(
                    label: "New Password",
                    controller: newPassword,
                    helper:
                        "Minimum 8 characters, at least one uppercase and one number.",
                  ),
                  const SizedBox(height: 20),
                  _LabeledPassword(
                    label: "Confirm New Password",
                    controller: confirmPassword,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _SoftButton(
                      label: "Update Password",
                      onTap: () => _toast(context, "Password updated (UI only)."),
                      compact: true,
                    ),
                  ),
                ],
              );

              if (!isWide) return left;

              return Row(
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Tips",
                          style: TextStyle(
                            fontFamily: "Manrope",
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF111418),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Use a strong password and avoid reusing it across services.",
                          style: TextStyle(
                            fontFamily: "Manrope",
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: Color(0xFF617589),
                            height: 20 / 14,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(Color border) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: "Preferences",
            subtitle: "Customize your system experience.",
          ),
          const SizedBox(height: 24),

          const _LabeledSelect(
            label: "Interface Language",
            value: "English (US)",
          ),

          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF0F2F4)),
          const SizedBox(height: 24),

          const Text(
            "NOTIFICATIONS",
            style: TextStyle(
              fontFamily: "Manrope",
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.35,
              color: Color(0xFF111418),
            ),
          ),
          const SizedBox(height: 16),

          _ToggleRow(
            title: "Assignment Alerts",
            subtitle: "Get notified when new assessments are posted.",
            value: assignmentAlerts,
            onChanged: (v) => setState(() => assignmentAlerts = v),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard(Color border) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: "Notifications",
            subtitle: "Control how and when you receive updates.",
          ),
          const SizedBox(height: 24),
          _ToggleRow(
            title: "Assignment Alerts",
            subtitle: "Get notified when new assessments are posted.",
            value: assignmentAlerts,
            onChanged: (v) => setState(() => assignmentAlerts = v),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(Color border) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Danger Zone",
                  style: TextStyle(
                    fontFamily: "Manrope",
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFFB91C1C),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Once you delete your account, there is no going back. Please be certain.",
                  style: TextStyle(
                    fontFamily: "Manrope",
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Color(0xCCDC2626),
                    height: 20 / 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _DangerButton(
            label: "Delete Account",
            onTap: () => _toast(context, "Delete (UI only)."),
          ),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

/* -------------------- Small UI pieces -------------------- */

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 2,
            offset: Offset(0, 1),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: "Manrope",
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 28 / 18,
                    color: Color(0xFF111418),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: "Manrope",
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 20 / 14,
                    color: Color(0xFF617589),
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

class _SoftButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool compact;
  const _SoftButton({
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: compact ? 38 : 40,
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 16.75),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDBE0E6)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 2,
              offset: Offset(0, 1),
              color: Color(0x14000000),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: "Manrope",
            fontWeight: FontWeight.w700,
            fontSize: 14,
            height: 21 / 14,
            color: Color(0xFF111418),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF137FEC),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              blurRadius: 2,
              offset: Offset(0, 1),
              color: Color(0xFFBFDBFE),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: "Manrope",
            fontWeight: FontWeight.w700,
            fontSize: 14,
            height: 21 / 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DangerButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: "Manrope",
            fontWeight: FontWeight.w700,
            fontSize: 14,
            height: 20 / 14,
            color: Color(0xFFDC2626),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String memberSince;
  final String lastLogin;

  const _ProfileCard({
    required this.name,
    required this.subtitle,
    required this.memberSince,
    required this.lastLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 375,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 2,
            offset: Offset(0, 1),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Avatar
          Positioned(
            top: 25,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 6,
                        offset: Offset(0, 4),
                        color: Color(0x1A000000),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person, size: 54, color: Color(0xFF617589)),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: "Manrope",
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    height: 28 / 20,
                    color: Color(0xFF111418),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: "Manrope",
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 20 / 14,
                    color: Color(0xFF617589),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      _Dot(color: Color(0xFF22C55E)),
                      SizedBox(width: 6),
                      Text(
                        "Active Status",
                        style: TextStyle(
                          fontFamily: "Manrope",
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          height: 16 / 12,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // bottom stats
          Positioned(
            left: 25,
            right: 25,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.only(top: 24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF0F2F4))),
              ),
              child: Column(
                children: [
                  _TwoColRow(left: "Member since", right: memberSince),
                  const SizedBox(height: 8),
                  _TwoColRow(left: "Last login", right: lastLogin),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

class _TwoColRow extends StatelessWidget {
  final String left;
  final String right;
  const _TwoColRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            left,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: "Manrope",
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Color(0xFF617589),
              height: 20 / 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            right,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: "Manrope",
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF111418),
              height: 20 / 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _NavCard extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _NavCard({
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 226,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 2,
            offset: Offset(0, 1),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        children: [
          _NavItem(
            selected: selectedIndex == 0,
            label: "Personal Info",
            icon: Icons.person_outline,
            onTap: () => onSelect(0),
          ),
          _NavItem(
            selected: selectedIndex == 1,
            label: "Security",
            icon: Icons.lock_outline,
            onTap: () => onSelect(1),
          ),
          _NavItem(
            selected: selectedIndex == 2,
            label: "Preferences",
            icon: Icons.tune_rounded,
            onTap: () => onSelect(2),
          ),
          _NavItem(
            selected: selectedIndex == 3,
            label: "Notifications",
            icon: Icons.notifications_none_rounded,
            onTap: () => onSelect(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _NavItem({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0x0D137FEC) : Colors.transparent;
    final color = selected ? const Color(0xFF137FEC) : const Color(0xFF617589);
    final weight = selected ? FontWeight.w700 : FontWeight.w500;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: bg,
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontFamily: "Manrope",
                fontWeight: weight,
                fontSize: 14,
                height: 20 / 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _LabeledInput({
    required this.label,
    required this.controller,
    required this.hint,
  });

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        isCollapsed: true, // ✅ يمنع أي padding داخلي افتراضي
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,

        // ✅ الأهم: اقفل أي fill جاي من Theme
        filled: false,
        fillColor: Colors.transparent,

        hintStyle: const TextStyle(
          fontFamily: "Manrope",
          fontWeight: FontWeight.w400,
          fontSize: 14,
          height: 19 / 14,
          color: Color(0xFF9CA3AF),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: "Manrope",
            fontWeight: FontWeight.w700,
            fontSize: 14,
            height: 20 / 14,
            color: Color(0xFF111418),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDBE0E6)),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: 1,
            textAlignVertical: TextAlignVertical.center,
            decoration: _decoration(hint),
            style: const TextStyle(
              fontFamily: "Manrope",
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 19 / 14,
              color: Color(0xFF111418),
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledPassword extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? helper;

  const _LabeledPassword({
    required this.label,
    required this.controller,
    this.helper,
  });

  InputDecoration _decoration() => const InputDecoration(
        isCollapsed: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        filled: false,
        fillColor: Colors.transparent,
        hintText: "••••••••••••",
        hintStyle: TextStyle(
          fontFamily: "Manrope",
          fontWeight: FontWeight.w400,
          fontSize: 14,
          height: 19 / 14,
          color: Color(0xFF9CA3AF),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: "Manrope",
            fontWeight: FontWeight.w700,
            fontSize: 14,
            height: 20 / 14,
            color: Color(0xFF111418),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDBE0E6)),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: true,
            maxLines: 1,
            textAlignVertical: TextAlignVertical.center,
            decoration: _decoration(),
            style: const TextStyle(
              fontFamily: "Manrope",
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 19 / 14,
              color: Color(0xFF111418),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: const TextStyle(
              fontFamily: "Manrope",
              fontWeight: FontWeight.w400,
              fontSize: 12,
              height: 16 / 12,
              color: Color(0xFF617589),
            ),
          ),
        ],
      ],
    );
  }
}

class _LabeledTextarea extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _LabeledTextarea({
    required this.label,
    required this.controller,
    required this.hint,
  });

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        isCollapsed: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        filled: false,
        fillColor: Colors.transparent,
        hintStyle: const TextStyle(
          fontFamily: "Manrope",
          fontWeight: FontWeight.w400,
          fontSize: 14,
          height: 20 / 14,
          color: Color(0xFF9CA3AF),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: "Manrope",
            fontWeight: FontWeight.w700,
            fontSize: 14,
            height: 20 / 14,
            color: Color(0xFF111418),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 100, // زي فيجما
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDBE0E6)),
          ),
          child: TextFormField(
            controller: controller,
            expands: true, // ✅ يخلي الكلام من فوق وميلقّمش شكل غريب
            maxLines: null,
            minLines: null,
            textAlignVertical: TextAlignVertical.top,
            decoration: _decoration(hint),
            style: const TextStyle(
              fontFamily: "Manrope",
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 20 / 14,
              color: Color(0xFF111418),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyInput extends StatelessWidget {
  final String label;
  final String value;
  final String? rightTag;
  final IconData icon;

  const _ReadOnlyInput({
    required this.label,
    required this.value,
    required this.icon,
    this.rightTag,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: "Manrope",
            fontWeight: FontWeight.w700,
            fontSize: 14,
            height: 20 / 14,
            color: Color(0xFF111418),
          ),
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.only(left: 44, right: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7F8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontFamily: "Manrope",
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 19 / 14,
                        color: Color(0xFF617589),
                      ),
                    ),
                  ),
                  if (rightTag != null)
                    Text(
                      rightTag!.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: "Manrope",
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.3,
                        color: Color(0xFF617589),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(icon, color: const Color(0xFF617589)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: "Manrope",
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  height: 20 / 14,
                  color: Color(0xFF111418),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: "Manrope",
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  height: 16 / 12,
                  color: Color(0xFF617589),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFF137FEC),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFE5E7EB),
        ),
      ],
    );
  }
}

class _LabeledSelect extends StatelessWidget {
  final String label;
  final String value;
  const _LabeledSelect({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: "Manrope",
            fontWeight: FontWeight.w700,
            fontSize: 14,
            height: 20 / 14,
            color: Color(0xFF111418),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDBE0E6)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: const [
              Expanded(
                child: Text(
                  "English (US)",
                  style: TextStyle(
                    fontFamily: "Manrope",
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Color(0xFF111418),
                    height: 20 / 14,
                  ),
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF617589)),
            ],
          ),
        ),
      ],
    );
  }
}
