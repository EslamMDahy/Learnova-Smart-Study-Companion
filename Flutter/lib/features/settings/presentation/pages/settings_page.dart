import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/before_unload_stub.dart'
    if (dart.library.html) '../../../../core/utils/before_unload_web.dart'
    as before_unload;

import '../../../../core/ui/toast.dart';
import '../../../../core/routing/routes.dart';
import '../../../auth/data/auth_providers.dart';
import '../../presentation/controllers/settings_controller.dart';
import '../../presentation/controllers/settings_state.dart';
import '../../../../shared/widgets/app_ui_components.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  int _sectionIndex = 0;

  VoidCallback? _beforeUnloadDispose;

  // ✅ Single-page scroll (left nav scrolls to section)
  final ScrollController _scrollController = ScrollController();
  
  final GlobalKey _kPersonal = GlobalKey();
  final GlobalKey _kSecurity = GlobalKey();
  final GlobalKey _kPreferences = GlobalKey();
  final GlobalKey _kNotifications = GlobalKey();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // ✅ Form keys
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // ===== Controllers (hydrate from API) =====
  final firstName = TextEditingController(text: "");
  final lastName = TextEditingController(text: "");
  final universityEmailCtrl = TextEditingController(text: "");
  final studentIdCtrl = TextEditingController(text: "");

  String _language = "English (US)";

  final bio = TextEditingController(text: "");
  final phoneNumber = TextEditingController(text: "");

  final currentPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();

  // ===== Preferences (matches user_preferences) =====
  bool emailNotifications = true;
  bool assignmentAlerts = true;
  bool courseUpdates = true;
  bool announcementNotifications = true;
  bool gradingNotifications = true;
  bool deadlineReminders = true;

  String themeMode = 'light'; // light, dark, system
  String profileVisibility = 'private'; // public, private, connections
  bool showOnlineStatus = true;

  // ===== Snapshot for Cancel + Dirty check =====
  String _initialFirstName = "";
  String _initialLastName = "";
  String _initialPhone = "";
  String _initialBio = "";
  String _initialLanguage = "English (US)";

  bool _initialEmailNotifications = true;
  bool _initialAssignmentAlerts = true;
  bool _initialCourseUpdates = true;
  bool _initialAnnouncementNotifications = true;
  bool _initialGradingNotifications = true;
  bool _initialDeadlineReminders = true;

  String _initialThemeMode = 'light';
  String _initialProfileVisibility = 'private';
  bool _initialShowOnlineStatus = true;

  // ✅ Cache للتواريخ عشان مايرجعوش "—" بعد save لو الباك رجّع null مؤقتًا
  DateTime? _cachedCreatedAt;
  DateTime? _cachedLastLoginAt;

  bool _hydrated = false;

  @override
  void initState() {
    super.initState();

    final st = ref.read(settingsControllerProvider);
    if (!_hydrated && st.profile != null && st.preferences != null) {
      _hydrated = true;

      final full = st.profile!.fullName.trim();
      final parts = full.split(RegExp(r'\s+'));
      firstName.text = parts.isNotEmpty ? parts.first : "";
      lastName.text = parts.length > 1 ? parts.sublist(1).join(' ') : "";

      universityEmailCtrl.text = st.profile!.universityEmail ?? st.profile!.email;
      studentIdCtrl.text = st.profile!.studentId ?? "";
      phoneNumber.text = st.profile!.phoneNumber ?? "";
      bio.text = st.profile!.bio ?? "";

      _language = _mapLangCodeToUi(st.profile!.languagePreference);

      emailNotifications = st.preferences!.emailNotifications;
      assignmentAlerts = st.preferences!.assignmentAlerts;
      courseUpdates = st.preferences!.courseUpdates;
      announcementNotifications = st.preferences!.announcementNotifications;
      gradingNotifications = st.preferences!.gradingNotifications;
      deadlineReminders = st.preferences!.deadlineReminders;

      themeMode = st.preferences!.themeMode;
      profileVisibility = st.preferences!.profileVisibility;
      showOnlineStatus = st.preferences!.showOnlineStatus;

      _takeSnapshot();
    }


    Future.microtask(() => ref.read(settingsControllerProvider.notifier).load());

    _beforeUnloadDispose = before_unload.registerBeforeUnload(() => _hasChanges);

    _takeSnapshot();
  }

  @override
  void dispose() {
    _beforeUnloadDispose?.call();
    firstName.dispose();
    lastName.dispose();
    bio.dispose();
    phoneNumber.dispose();
    currentPassword.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
    universityEmailCtrl.dispose();
    studentIdCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }



// =========================
// Scroll helpers (left nav)
// =========================

Future<void> _scrollTo(GlobalKey key) async {
  final ctx = key.currentContext;
  if (ctx == null) return;
  await Scrollable.ensureVisible(
    ctx,
    duration: const Duration(milliseconds: 450),
    curve: Curves.easeInOut,
    alignment: 0.02, // small top padding
  );
}

void _onNavSelect(int i) {
  setState(() => _sectionIndex = i);
  switch (i) {
    case 0:
      _scrollTo(_kPersonal);
      break;
    case 1:
      _scrollTo(_kSecurity);
      break;
    case 2:
      _scrollTo(_kPreferences);
      break;
    case 3:
      _scrollTo(_kNotifications);
      break;
    default:
      _scrollTo(_kPersonal);
  }
}

  // =========================
  // Validation helpers
  // =========================

  String? _required(String? v, String msg) {
    if ((v ?? '').trim().isEmpty) return msg;
    return null;
  }

  // ✅ Figma-like: "Sep, 2021"
  String _fmtMemberSince(DateTime? dt) {
    if (dt == null) return "—";
    final d = dt.toLocal();
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return "${months[d.month - 1]}, ${d.year}";
  }

  // ✅ Figma-like: "2 hours ago" + fallback date (بدون وقت)
  String _fmtLastLoginRelative(DateTime? dt) {
    if (dt == null) return "—";
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hours ago";
    if (diff.inDays < 7) return "${diff.inDays} days ago";

    // fallback date only
    String two(int n) => n.toString().padLeft(2, '0');
    return "${local.year}-${two(local.month)}-${two(local.day)}";
  }

  String? _validatePhone(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return "Phone number is required";

    // يسمح بأرقام + ومسافات و - و ()
    final ok = RegExp(r'^[0-9+\-\s()]{7,20}$').hasMatch(s);
    if (!ok) return "Enter a valid phone number";
    return null;
  }

  String? _validateNewPassword(String? v) {
    final s = (v ?? '');
    if (s.isEmpty) return "New password is required";
    if (s.length < 8) return "Password must be at least 8 characters";
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    final s = (v ?? '');
    if (s.isEmpty) return "Confirmation is required";
    if (s != newPassword.text) return "Passwords don't match";
    return null;
  }

  bool _validateProfileForm() {
    final ok = _profileFormKey.currentState?.validate() ?? false;
    if (!ok) {
      _toast(
        context,
        title: "Validation",
        message: "Please fix the highlighted fields.",
        icon: Icons.warning_amber_rounded,
      );
    }
    return ok;
  }

  bool _validatePasswordForm() {
    final ok = _passwordFormKey.currentState?.validate() ?? false;
    if (!ok) {
      _toast(
        context,
        title: "Validation",
        message: "Please fix the highlighted fields.",
        icon: Icons.warning_amber_rounded,
      );
    }
    return ok;
  }

  // ✅ Dirty check: مفيش save غير لو فيه تعديل فعلاً
  bool get _hasChanges {
    final fn = firstName.text.trim();
    final ln = lastName.text.trim();
    final ph = phoneNumber.text.trim();
    final b = bio.text.trim();

    if (fn != _initialFirstName.trim()) return true;
    if (ln != _initialLastName.trim()) return true;
    if (ph != _initialPhone.trim()) return true;
    if (b != _initialBio.trim()) return true;
    if (_language != _initialLanguage) return true;

    if (emailNotifications != _initialEmailNotifications) return true;
    if (assignmentAlerts != _initialAssignmentAlerts) return true;
    if (courseUpdates != _initialCourseUpdates) return true;
    if (announcementNotifications != _initialAnnouncementNotifications) return true;
    if (gradingNotifications != _initialGradingNotifications) return true;
    if (deadlineReminders != _initialDeadlineReminders) return true;

    if (themeMode != _initialThemeMode) return true;
    if (profileVisibility != _initialProfileVisibility) return true;
    if (showOnlineStatus != _initialShowOnlineStatus) return true;

    return false;
  }

  bool _shouldValidateProfileOnSave() {
  // ✅ single-page: validate profile fields only if they changed
  final fn = firstName.text.trim();
  final ln = lastName.text.trim();
  final ph = phoneNumber.text.trim();

  if (fn != _initialFirstName.trim()) return true;
  if (ln != _initialLastName.trim()) return true;
  if (ph != _initialPhone.trim()) return true;

  return false;
}



Future<bool> _confirmDiscardDialog(BuildContext context) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Discard changes?'),
      content: const Text(
        'You have unsaved changes. If you leave now, your changes will be lost.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Stay'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Discard'),
        ),
      ],
    ),
  );
  return res ?? false;
}

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(settingsControllerProvider);

    ref.listen(settingsControllerProvider, (prev, next) {
      final err = next.error;
      final ok = next.success;

      if (err != null && err.trim().isNotEmpty) {
        _toast(context,
            title: "Error", message: err, icon: Icons.error_outline_rounded);
      } else if (ok != null && ok.trim().isNotEmpty) {
        _toast(context,
            title: "Done",
            message: ok,
            icon: Icons.check_circle_outline_rounded);

        // ✅ بعد نجاح save: اعتبر القيم الحالية snapshot (عشان Save يتقفل)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _takeSnapshot();
          setState(() {});
        });
      }
    });

    // ✅ Hydrate once (post-frame) when data arrives
    if (!_hydrated && st.profile != null && st.preferences != null) {
      _hydrated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final full = st.profile!.fullName.trim();
        final parts = full.split(RegExp(r'\s+'));
        firstName.text = parts.isNotEmpty ? parts.first : "";
        lastName.text = parts.length > 1 ? parts.sublist(1).join(' ') : "";

        universityEmailCtrl.text = st.profile!.universityEmail ?? st.profile!.email;
        studentIdCtrl.text = st.profile!.studentId ?? "";
        phoneNumber.text = st.profile!.phoneNumber ?? "";
        bio.text = st.profile!.bio ?? "";

        _language = _mapLangCodeToUi(st.profile!.languagePreference);

        emailNotifications = st.preferences!.emailNotifications;
        assignmentAlerts = st.preferences!.assignmentAlerts;
        courseUpdates = st.preferences!.courseUpdates;
        announcementNotifications = st.preferences!.announcementNotifications;
        gradingNotifications = st.preferences!.gradingNotifications;
        deadlineReminders = st.preferences!.deadlineReminders;

        themeMode = st.preferences!.themeMode;
        profileVisibility = st.preferences!.profileVisibility;
        showOnlineStatus = st.preferences!.showOnlineStatus;

        // ✅ cache dates
        _cachedCreatedAt = st.profile!.createdAt ?? _cachedCreatedAt;
        _cachedLastLoginAt = st.profile!.lastLoginAt ?? _cachedLastLoginAt;

        _takeSnapshot();
        setState(() {});
      });
    }

    // ✅ لو الباك رجّع null بعد save: حافظ على آخر قيمة
    _cachedCreatedAt = st.profile?.createdAt ?? _cachedCreatedAt;
    _cachedLastLoginAt = st.profile?.lastLoginAt ?? _cachedLastLoginAt;

    final isBusy =
        st.savingProfile || st.updatingPassword || st.deleting || st.savingPreferences;

    // ✅ زرار Save يتقفل لو مفيش تغييرات
    final canSave = _hasChanges && !isBusy;

    // ✅ Figma-like smaller buttons (height 40)
    const double btnH = 40;

return WillPopScope(
  onWillPop: () async {
    if (!_hasChanges) return true;
    return _confirmDiscardDialog(context);
  },
  child: AbsorbPointer(
    absorbing: isBusy,
    child: Container(
      color: AppColors.pageBg,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row + actions (stays visible)
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 120,
                          child: AppPrimaryLoadingButton(
                            label: "Cancel",
                            loading: false,
                            height: btnH,
                            onPressed: () {
                              setState(() {
                                _restoreSnapshot();
                                currentPassword.clear();
                                newPassword.clear();
                                confirmPassword.clear();
                              });
                              _toast(
                                context,
                                title: "Cancelled",
                                message: "Changes discarded.",
                                icon: Icons.info_outline_rounded,
                              );
                            },
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.title,
                            borderColor: AppColors.borderSoft,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 160,
                          child: AppPrimaryLoadingButton(
                            label: "Save Changes",
                            height: btnH,
                            loading: st.savingProfile || st.savingPreferences,
                            onPressed: canSave
                                ? () {
                                    // ✅ validate profile ONLY if you are in Personal Info section
                                    if (_shouldValidateProfileOnSave()) {
                                      if (!_validateProfileForm()) return;
                                    }

                                    ref
                                        .read(settingsControllerProvider.notifier)
                                        .saveProfile(
                                          firstName: firstName.text.trim(),
                                          lastName: lastName.text.trim(),
                                          phoneNumber: phoneNumber.text.trim(),
                                          bio: bio.text.trim(),
                                          language: _language,
                                          assignmentAlerts: assignmentAlerts,

                                          // prefs (user_preferences)
                                          emailNotifications: emailNotifications,
                                          courseUpdates: courseUpdates,
                                          announcementNotifications:
                                              announcementNotifications,
                                          gradingNotifications: gradingNotifications,
                                          deadlineReminders: deadlineReminders,
                                          themeMode: themeMode,
                                          profileVisibility: profileVisibility,
                                          showOnlineStatus: showOnlineStatus,
                                        );
                                  }
                                : null, // ✅ disabled if no changes
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Main (scrollable content). Sidebar stays sticky on wide screens.
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final isWide = c.maxWidth >= 980;

                      final left = Column(
                        children: [
                          _ProfileCard(
                            name: (st.profile?.fullName.isNotEmpty ?? false)
                                ? st.profile!.fullName
                                : "${firstName.text} ${lastName.text}".trim(),
                            subtitle: st.profile?.email ?? universityEmailCtrl.text,
                            memberSince: _fmtMemberSince(_cachedCreatedAt),
                            lastLogin: _fmtLastLoginRelative(_cachedLastLoginAt),
                          ),
                          const SizedBox(height: 16),
                          _NavCard(
                            selectedIndex: _sectionIndex,
                            onSelect: (i) => _onNavSelect(i),
                          ),
                        ],
                      );

                      final right = Column(
                        children: [
                          _buildPersonalInfoCard(),
                          const SizedBox(height: 16),
                          _buildSecurityCard(st),
                          const SizedBox(height: 16),
                          _buildPreferencesCard(),
                          const SizedBox(height: 16),
                          _buildNotificationsCard(),
                          const SizedBox(height: 16),
                          _buildDangerZone(st),
                          const SizedBox(height: 24),
                        ],
                      );

                      if (!isWide) {
                        return SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            children: [
                              left,
                              const SizedBox(height: 16),
                              right,
                            ],
                          ),
                        );
                      }

                      // ✅ Sticky sidebar (left fixed, right scrolls)
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 264 + 32),
                                child: right,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            child: SizedBox(width: 264, child: left),
                          ),
                        ],
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
  ),
);
  }

  // =========================
  // Sections
  // =========================

  Widget _buildPersonalInfoCard() {
    return AppCard(
      child: Form(
        key: _profileFormKey,
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

                final first = AppLabeledIconField(
                  label: "First Name",
                  controller: firstName,
                  hint: "First name",
                  icon: Icons.person_outline,
                  onChanged: (_) => setState(() {}),
                  validator: (v) => _required(v, "First name is required"),
                );

                final last = AppLabeledIconField(
                  label: "Last Name",
                  controller: lastName,
                  hint: "Last name",
                  icon: Icons.person_outline,
                  onChanged: (_) => setState(() {}),
                  validator: (v) => _required(v, "Last name is required"),
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
                    AbsorbPointer(
                      child: AppLabeledIconField(
                        label: "University Email",
                        controller: universityEmailCtrl,
                        hint: "University email",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) {},
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, c2) {
                        final wide2 = c2.maxWidth >= 780;

                        final id = AbsorbPointer(
                          child: AppLabeledIconField(
                            label: "Student ID",
                            controller: studentIdCtrl,
                            hint: "Student ID",
                            icon: Icons.badge_outlined,
                            onChanged: (_) {},
                          ),
                        );

                        final phone = AppLabeledIconField(
                          label: "Phone Number",
                          controller: phoneNumber,
                          hint: "+1 ...",
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          onChanged: (_) => setState(() {}),
                          validator: _validatePhone,
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
                    AppLabeledIconField(
                      label: "Bio / Academic Interests",
                      controller: bio,
                      hint: "Write something...",
                      icon: Icons.edit_outlined,
                      onChanged: (_) => setState(() {}),
                      validator: (_) => null,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard(SettingsState st) {
    return AppCard(
      child: Form(
        key: _passwordFormKey,
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
                    AppLabeledIconField(
                      label: "Current Password",
                      controller: currentPassword,
                      hint: "Enter current password",
                      icon: Icons.lock_outline,
                      obscureText: _obscureCurrent,
                      onChanged: (_) => setState(() {}),
                      validator: (v) => _required(v, "Current password is required"),
                      suffix: IconButton(
                        splashRadius: 18,
                        icon: Icon(
                          _obscureCurrent
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.muted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppLabeledIconField(
                      label: "New Password",
                      controller: newPassword,
                      hint: "Enter new password",
                      icon: Icons.lock_outline,
                      obscureText: _obscureNew,
                      onChanged: (_) => setState(() {}),
                      validator: _validateNewPassword,
                      suffix: IconButton(
                        splashRadius: 18,
                        icon: Icon(
                          _obscureNew
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.muted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppLabeledIconField(
                      label: "Confirm New Password",
                      controller: confirmPassword,
                      hint: "Confirm new password",
                      icon: Icons.lock_outline,
                      obscureText: _obscureConfirm,
                      onChanged: (_) => setState(() {}),
                      validator: _validateConfirmPassword,
                      suffix: IconButton(
                        splashRadius: 18,
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.muted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppPrimaryLoadingButton(
                        label: "Update Password",
                        loading: st.updatingPassword,
                        height: 40, // ✅ figma-like
                        onPressed: () {
                          if (!_validatePasswordForm()) return;

                          if (currentPassword.text == newPassword.text) {
                            _toast(
                              context,
                              title: "Validation",
                              message: "New password must be different",
                              icon: Icons.warning_amber_rounded,
                            );
                            return;
                          }

                          ref.read(settingsControllerProvider.notifier).changePassword(
                                currentPassword: currentPassword.text,
                                newPassword: newPassword.text,
                              );
                        },
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.title,
                        borderColor: AppColors.borderSoft,
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
                    ),
                  ],
                );
              },
            ),
          ],
        ),
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
          AppModernDropdown<String>(
            label: "Interface Language",
            value: _language,
            items: const [
              DropdownMenuItem(value: "English (US)", child: Text("English (US)")),
              DropdownMenuItem(value: "English (UK)", child: Text("English (UK)")),
              DropdownMenuItem(value: "Arabic", child: Text("Arabic")),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _language = v);
            },
          ),
          const SizedBox(height: 16),
          AppModernDropdown<String>(
            label: "Theme Mode",
            value: themeMode,
            items: const [
              DropdownMenuItem(value: "light", child: Text("Light")),
              DropdownMenuItem(value: "dark", child: Text("Dark")),
              DropdownMenuItem(value: "system", child: Text("System")),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => themeMode = v);
            },
          ),
          const SizedBox(height: 16),
          AppModernDropdown<String>(
            label: "Profile Visibility",
            value: profileVisibility,
            items: const [
              DropdownMenuItem(value: "public", child: Text("Public")),
              DropdownMenuItem(value: "private", child: Text("Private")),
              DropdownMenuItem(value: "connections", child: Text("Connections")),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => profileVisibility = v);
            },
          ),
          const SizedBox(height: 16),
          AppToggleRow(
            title: "Show Online Status",
            subtitle: "Allow others to see when you're online.",
            value: showOnlineStatus,
            onChanged: (v) => setState(() => showOnlineStatus = v),
          ),
          const SizedBox(height: 24),
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
            title: "Email Notifications",
            subtitle: "Receive notifications by email.",
            value: emailNotifications,
            onChanged: (v) => setState(() => emailNotifications = v),
          ),
          const SizedBox(height: 12),
          AppToggleRow(
            title: "Assignment Alerts",
            subtitle: "Get notified when new assessments are posted.",
            value: assignmentAlerts,
            onChanged: (v) => setState(() => assignmentAlerts = v),
          ),
          const SizedBox(height: 12),
          AppToggleRow(
            title: "Course Updates",
            subtitle: "Updates about your courses.",
            value: courseUpdates,
            onChanged: (v) => setState(() => courseUpdates = v),
          ),
          const SizedBox(height: 12),
          AppToggleRow(
            title: "Announcements",
            subtitle: "Important announcements.",
            value: announcementNotifications,
            onChanged: (v) => setState(() => announcementNotifications = v),
          ),
          const SizedBox(height: 12),
          AppToggleRow(
            title: "Grading Notifications",
            subtitle: "Grades & evaluation updates.",
            value: gradingNotifications,
            onChanged: (v) => setState(() => gradingNotifications = v),
          ),
          const SizedBox(height: 12),
          AppToggleRow(
            title: "Deadline Reminders",
            subtitle: "Reminders before deadlines.",
            value: deadlineReminders,
            onChanged: (v) => setState(() => deadlineReminders = v),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(SettingsState st) {
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 560;

        final textContent = Column(
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
        );

        final button = AppPrimaryLoadingButton(
          label: "Delete Account",
          loading: st.deleting,
          onPressed: () => _openDeleteDialog(context),
          height: 40,
          backgroundColor: const Color(0xFFDC2626),
          foregroundColor: Colors.white,
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
                    textContent,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: button),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: textContent),
                    const SizedBox(width: 16),
                    SizedBox(width: 170, child: button),
                  ],
                ),
        );
      },
    );
  }

  // =========================
  // Delete Flow (Popup)
  // =========================

  void _openDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeleteAccountDialog(),
    );
  }

  // =========================
  // Snapshot helpers
  // =========================

  void _takeSnapshot() {
    _initialFirstName = firstName.text.trim();
    _initialLastName = lastName.text.trim();
    _initialPhone = phoneNumber.text.trim();
    _initialBio = bio.text.trim();
    _initialLanguage = _language;

    _initialEmailNotifications = emailNotifications;
    _initialAssignmentAlerts = assignmentAlerts;
    _initialCourseUpdates = courseUpdates;
    _initialAnnouncementNotifications = announcementNotifications;
    _initialGradingNotifications = gradingNotifications;
    _initialDeadlineReminders = deadlineReminders;

    _initialThemeMode = themeMode;
    _initialProfileVisibility = profileVisibility;
    _initialShowOnlineStatus = showOnlineStatus;
  }

  void _restoreSnapshot() {
    firstName.text = _initialFirstName;
    lastName.text = _initialLastName;
    phoneNumber.text = _initialPhone;
    bio.text = _initialBio;
    _language = _initialLanguage;

    emailNotifications = _initialEmailNotifications;
    assignmentAlerts = _initialAssignmentAlerts;
    courseUpdates = _initialCourseUpdates;
    announcementNotifications = _initialAnnouncementNotifications;
    gradingNotifications = _initialGradingNotifications;
    deadlineReminders = _initialDeadlineReminders;

    themeMode = _initialThemeMode;
    profileVisibility = _initialProfileVisibility;
    showOnlineStatus = _initialShowOnlineStatus;
  }

  String _mapLangCodeToUi(String code) {
    switch (code) {
      case 'en_US':
      case 'en':
        return "English (US)";
      case 'en_GB':
        return "English (UK)";
      case 'ar_EG':
      case 'ar':
        return "Arabic";
      default:
        return "English (US)";
    }
  }


  static void _toast(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
  }) {
    AppToast.show(
      context,
      title: title,
      message: message,
      icon: icon,
    );
  }
}

// ============================================================================
// Delete Account Dialog (improved UI/UX)
// ============================================================================

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _passCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _otpStep = false;
  bool _obscurePass = true;

  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _passCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _startCountdown([int seconds = 60]) {
    _timer?.cancel();
    setState(() => _secondsLeft = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  String _mmss(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString()}:${s.toString().padLeft(2, '0')}";
  }

  Future<void> _requestOtp() async {
    final pass = _passCtrl.text.trim();
    if (pass.isEmpty) {
      AppToast.show(
        context,
        title: "Validation",
        message: "Password is required",
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    final ok = await ref
        .read(settingsControllerProvider.notifier)
        .requestDelete(currentPassword: pass);

    if (!mounted) return;
    if (ok) {
      setState(() {
        _otpStep = true;
        _otpCtrl.clear();
      });
      _startCountdown(60);
    }
  }

  Future<void> _confirmDelete() async {
    final otp = _otpCtrl.text.trim();
    final valid = RegExp(r'^[a-zA-Z0-9]{6}$').hasMatch(otp);

    if (!valid) {
      AppToast.show(
        context,
        title: "Validation",
        message: "Enter a valid 6-digit OTP",
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    final ok = await ref
        .read(settingsControllerProvider.notifier)
        .confirmDelete(otp: otp);

    if (!mounted) return;
    if (ok) {
      // ✅ logout after delete
      ref.read(authRepositoryProvider).logout();

      if (context.mounted) {
        Navigator.of(context).pop();
        // go to login
        context.go(Routes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(settingsControllerProvider);
    final isBusy = st.deleting;

    final title = _otpStep ? "Confirm deletion" : "Delete account";
    final subtitle = _otpStep
        ? "Enter the 6-digit code sent to your email to confirm deletion."
        : "We’ll send a one-time code to confirm. This action can’t be undone.";

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ),
                  IconButton(
                    splashRadius: 18,
                    onPressed: isBusy ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 14),

              // step pills
              Row(
                children: [
                  _StepPill(active: !_otpStep, label: "1  Password"),
                  const SizedBox(width: 8),
                  _StepPill(active: _otpStep, label: "2  OTP"),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.dangerBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Deleting your account is permanent. You’ll lose access to your data.",
                        style: TextStyle(
                          color: Color(0xCCDC2626),
                          height: 20 / 14,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (!_otpStep)
                AppLabeledIconField(
                  label: "Current Password",
                  controller: _passCtrl,
                  hint: "••••••••",
                  icon: Icons.lock_outline,
                  obscureText: _obscurePass,
                  onChanged: (_) => setState(() {}),
                  suffix: IconButton(
                    splashRadius: 18,
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),

              if (_otpStep)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppLabeledIconField(
                      label: "OTP",
                      controller: _otpCtrl,
                      hint: "6-digit code",
                      icon: Icons.verified_outlined,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text(
                          "Didn’t get the code?",
                          style: TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: (isBusy || _secondsLeft > 0)
                              ? null
                              : () async {
                                  await _requestOtp();
                                },
                          child: Text(
                            _secondsLeft > 0
                                ? "Resend in ${_mmss(_secondsLeft)}"
                                : "Resend code",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppPrimaryLoadingButton(
                      label: _otpStep ? "Back" : "Cancel",
                      loading: false,
                      onPressed: isBusy
                          ? null
                          : () {
                              if (_otpStep) {
                                setState(() => _otpStep = false);
                                return;
                              }
                              Navigator.of(context).pop();
                            },
                      height: 40,
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.title,
                      borderColor: AppColors.borderSoft,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppPrimaryLoadingButton(
                      label: _otpStep ? "Confirm delete" : "Request OTP",
                      loading: isBusy,
                      onPressed: isBusy
                          ? null
                          : () async {
                              if (_otpStep) {
                                await _confirmDelete();
                              } else {
                                await _requestOtp();
                              }
                            },
                      height: 40,
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  final bool active;
  final String label;
  const _StepPill({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    final bg = active ? AppColors.primarySoft : const Color(0xFFF3F4F6);
    final border = active ? AppColors.primary : const Color(0xFFE5E7EB);
    final fg = active ? AppColors.primary : AppColors.muted;
    final weight = active ? FontWeight.w700 : FontWeight.w600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: fg, fontWeight: weight),
      ),
    );
  }
}

// ============================================================================
// UI Widgets (unchanged - same as yours)
// ============================================================================

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