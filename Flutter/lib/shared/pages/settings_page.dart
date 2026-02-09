import 'package:flutter/material.dart';
import '../widgets/app_ui_components.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _sectionIndex = 0;

  final firstName = TextEditingController(text: "Alex");
  final lastName = TextEditingController(text: "Johnson");
  final bio = TextEditingController(
    text: "Interested in Artificial Intelligence, Machine Learning, and Human-Computer Interaction.",
  );

  final phoneNumber = TextEditingController(text: "+1 (555) 123-4567");

  final email = "alex.johnson@uni.edu";
  final studentId = "2021004592";

  bool assignmentAlerts = true;

  final currentPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    bio.dispose();
    phoneNumber.dispose();
    currentPassword.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pageBg,
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: AppSpacing.page,
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
                          Text("Account Settings", style: AppText.h1),
                          SizedBox(height: 6),
                          Text(
                            "Manage your personal information, security credentials, and system preferences.",
                            style: AppText.subtitle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        AppSoftButton(
                          label: "Cancel",
                          onTap: () => _toast(context, "Canceled (UI only)."),
                        ),
                        const SizedBox(width: 12),
                        AppPrimaryButton(
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
                        const _ProfileCard(
                          name: "Alex Johnson",
                          subtitle: "Student | Computer Science",
                          memberSince: "Sep, 2021",
                          lastLogin: "2 hours ago",
                        ),
                        const SizedBox(height: 16),
                        _NavCard(
                          selectedIndex: _sectionIndex,
                          onSelect: (i) => setState(() => _sectionIndex = i),
                        ),
                      ],
                    );

                    final right = Column(
                      children: [
                        if (_sectionIndex == 0) _buildPersonalInfoCard(),
                        if (_sectionIndex == 1) _buildSecurityCard(),
                        if (_sectionIndex == 2) _buildPreferencesCard(),
                        if (_sectionIndex == 3) _buildNotificationsCard(),
                        const SizedBox(height: 16),
                        _buildDangerZone(),
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

  Widget _buildPersonalInfoCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: "Personal Information",
            subtitle: "Update your personal details here.",
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, c) {
              final isWide = c.maxWidth >= 780;

              final first = AppLabeledInput(
                label: "First Name",
                controller: firstName,
                hint: "First name",
              );

              final last = AppLabeledInput(
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
                  AppReadOnlyInput(
                    label: "University Email",
                    value: email,
                    rightTag: "Read Only",
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, c2) {
                      final wide2 = c2.maxWidth >= 780;

                      final id = AppReadOnlyInput(
                        label: "Student ID",
                        value: studentId,
                        icon: Icons.badge_outlined,
                      );

                      final phone = AppLabeledInput(
                        label: "Phone Number",
                        controller: phoneNumber,
                        hint: "+1 ...",
                      );

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
                  AppLabeledTextarea(
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

  Widget _buildSecurityCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: "Security",
            subtitle: "Manage your password and authentication settings.",
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, c) {
              final isWide = c.maxWidth >= 780;

              final left = Column(
                children: [
                  AppLabeledPassword(
                    label: "Current Password",
                    controller: currentPassword,
                  ),
                  const SizedBox(height: 20),
                  AppLabeledPassword(
                    label: "New Password",
                    controller: newPassword,
                    helper: "Minimum 8 characters, at least one uppercase and one number.",
                  ),
                  const SizedBox(height: 20),
                  AppLabeledPassword(
                    label: "Confirm New Password",
                    controller: confirmPassword,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppSoftButton(
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
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.title,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Use a strong password and avoid reusing it across services.",
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: AppColors.muted,
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

  Widget _buildPreferencesCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: "Preferences",
            subtitle: "Customize your system experience.",
          ),
          const SizedBox(height: 24),
          const AppLabeledSelect(
            label: "Interface Language",
            value: "English (US)",
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF0F2F4)),
          const SizedBox(height: 24),
          const Text(
            "NOTIFICATIONS",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.35,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: 16),
          AppToggleRow(
            title: "Assignment Alerts",
            subtitle: "Get notified when new assessments are posted.",
            value: assignmentAlerts,
            onChanged: (v) => setState(() => assignmentAlerts = v),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: "Notifications",
            subtitle: "Control how and when you receive updates.",
          ),
          const SizedBox(height: 24),
          AppToggleRow(
            title: "Assignment Alerts",
            subtitle: "Get notified when new assessments are posted.",
            value: assignmentAlerts,
            onChanged: (v) => setState(() => assignmentAlerts = v),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 560;

        final textBlock = Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Danger Zone",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.dangerTitle,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "Once you delete your account, there is no going back. Please be certain.",
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xCCDC2626),
                  height: 20 / 14,
                ),
              ),
            ],
          ),
        );

        final button = AppDangerButton(
          label: "Delete Account",
          onTap: () => _toast(context, "Delete (UI only)."),
        );

        return Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.dangerBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.dangerBorder),
          ),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textBlock,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: button),
                  ],
                )
              : Row(
                  children: [
                    textBlock,
                    const SizedBox(width: 16),
                    button,
                  ],
                ),
        );
      },
    );
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// ---------------------------------------------------------------------------
/// Page-specific widgets (مش متكررة غالبًا) نخليها هنا
/// ---------------------------------------------------------------------------

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
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            blurRadius: 2,
            offset: Offset(0, 1),
            color: AppColors.shadowSoft,
          ),
        ],
      ),
      child: Stack(
        children: [
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
                    color: AppColors.borderSoft,
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
                  child: const Icon(Icons.person, size: 54, color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    height: 28 / 20,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 20 / 14,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      _Dot(color: AppColors.successDot),
                      SizedBox(width: 6),
                      Text(
                        "Active Status",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          height: 16 / 12,
                          color: AppColors.successText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
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
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: AppColors.muted,
              height: 20 / 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            right,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: AppColors.title,
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
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            blurRadius: 2,
            offset: Offset(0, 1),
            color: AppColors.shadowSoft,
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
    final bg = selected ? AppColors.primarySoft : Colors.transparent;
    final color = selected ? AppColors.primary : AppColors.muted;
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
