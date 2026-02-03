import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../controllers/signup_controller.dart';

enum AccountType { user, owner }
enum UserKind { student, instructor, assistant }

class SignUpForm extends ConsumerStatefulWidget {
  final bool isMobile;
  const SignUpForm({super.key, this.isMobile = false});

  @override
  ConsumerState<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<SignUpForm> {
  final blue = const Color(0xFF137FEC);

  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  AccountType accountType = AccountType.user;
  UserKind userKind = UserKind.student;
  

  bool isChecked = false;
  bool _obscurePassword = true;

  String? _authError; // ✅ UI/local error فقط

  String? validatePassword(String? v) {
  final s = (v ?? '').trim();
    if (s.isEmpty) return 'Password is required';
    if (s.length < 8) return 'Min 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(s)) return 'Add at least 1 uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(s)) return 'Add at least 1 lowercase letter';
    if (!RegExp(r'\d').hasMatch(s)) return 'Add at least 1 number';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\]=+~`]').hasMatch(s)) {
      return 'Add at least 1 special character';
    }
    if (s.contains(' ')) return 'No spaces allowed';
    return null;
  }

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final orgCodeController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    void clearErr() {
      if (_authError != null) setState(() => _authError = null);
    }

    firstNameController.addListener(clearErr);
    lastNameController.addListener(clearErr);
    emailController.addListener(clearErr);
    orgCodeController.addListener(clearErr);
    passwordController.addListener(clearErr);
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    orgCodeController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _onCreateAccount() async {
    if (_autoValidate != AutovalidateMode.onUserInteraction) {
      setState(() => _autoValidate = AutovalidateMode.onUserInteraction);
    }

    setState(() => _authError = null);

    final okForm = _formKey.currentState?.validate() ?? false;
    if (!okForm) return;

    if (!isChecked) {
      setState(() => _authError = 'Please accept Terms and Privacy Policy.');
      return;
    }

    final fullName =
        '${firstNameController.text.trim()} ${lastNameController.text.trim()}'
            .trim();
    final role = accountType == AccountType.user ? userKind.name : 'owner';
    final ok = await ref.read(signupControllerProvider.notifier).signup(
        fullName: fullName,
        email: emailController.text.trim(),
        password: passwordController.text,
        accountType: accountType.name,
        inviteCode: accountType == AccountType.user ? orgCodeController.text.trim() : null,
        systemRole: role, // ✅
      );

    if (!mounted) return;

    if (ok) {
      context.go(Routes.login);
    } else {
      // ✅ سيب عرض error للـ provider (مش لازم نعمل setState)
      // بس لو حابب رسالة fallback محلية:
      final apiErr = ref.read(signupControllerProvider).error;
      if (apiErr == null) {
        setState(() => _authError = 'Signup failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signupControllerProvider);

    // ✅ اللي هيتعرض في الـ box: local UI error أولاً، وإلا API error
    final shownError = _authError ?? state.error;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 24 : 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 420,
              child: Form(
                key: _formKey,
                autovalidateMode: _autoValidate,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Create account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start your journey with AI-driven personalized assessments today.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),

                    // ✅ Error Box (no snackbar)
                    if (shownError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3F3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFC7C7)),
                        ),
                        child: Text(
                          shownError,
                          style: const TextStyle(
                            color: Color(0xFFB00020),
                            fontSize: 13,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    _segmented(
                      leftText: 'User',
                      rightText: 'Owner',
                      leftSelected: accountType == AccountType.user,
                      onLeft: state.loading
                          ? null
                          : () => setState(() => accountType = AccountType.user),
                      onRight: state.loading
                          ? null
                          : () => setState(() => accountType = AccountType.owner),
                    ),

                    const SizedBox(height: 12),

                    if (accountType == AccountType.user) ...[
                      _tripleToggle(state),
                      const SizedBox(height: 12),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: _labeledField(
                            label: 'First Name',
                            child: TextFormField(
                              controller: firstNameController,
                              style: const TextStyle(color: Colors.black),
                              validator: (v) =>
                                  (v ?? '').trim().isEmpty ? 'Required' : null,
                              decoration: _inputDecoration(
                                hint: 'Enter first name',
                                prefixIcon: Icons.person_outline,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _labeledField(
                            label: 'Last Name',
                            child: TextFormField(
                              controller: lastNameController,
                              style: const TextStyle(color: Colors.black),
                              validator: (v) =>
                                  (v ?? '').trim().isEmpty ? 'Required' : null,
                              decoration: _inputDecoration(
                                hint: 'Enter last name',
                                prefixIcon: Icons.person_outline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    _labeledField(
                      label: 'Email',
                      child: TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.black),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return 'Email is required';
                          if (!s.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                        decoration: _inputDecoration(
                          hint: 'Enter your email address',
                          prefixIcon: Icons.mail_outline,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    if (accountType == AccountType.user) ...[
                      _labeledField(
                        label: 'Organization Code',
                        child: TextFormField(
                          controller: orgCodeController,
                          style: const TextStyle(color: Colors.black),
                          validator: (v) =>
                              (v ?? '').trim().isEmpty ? 'Required' : null,
                          decoration: _inputDecoration(
                            hint: 'Enter organization code',
                            prefixIcon: Icons.vpn_key_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    _labeledField(
                      label: 'Password',
                      child: TextFormField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.black),
                        validator: validatePassword,
                        decoration: _inputDecoration(
                          hint: 'Create a password',
                          prefixIcon: Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.black54,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          activeColor: blue,
                          checkColor: Colors.white,
                          onChanged: state.loading
                              ? null
                              : (v) => setState(() => isChecked = v ?? false),
                        ),
                        Expanded(
                          child: Wrap(
                            children: [
                              const Text(
                                'I agree to the ',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 14),
                              ),
                              InkWell(
                                onTap: state.loading ? null : () {},
                                child: Text(
                                  'Terms',
                                  style: TextStyle(
                                    color: blue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Text(
                                ' and ',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 14),
                              ),
                              InkWell(
                                onTap: state.loading ? null : () {},
                                child: Text(
                                  'Privacy Policy',
                                  style: TextStyle(
                                    color: blue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: state.loading ? null : _onCreateAccount,
                        child: state.loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? ",
                            style: TextStyle(color: Colors.black)),
                        InkWell(
                          onTap:
                              state.loading ? null : () => context.go(Routes.login),
                          child: Text(
                            "Log in",
                            style: TextStyle(
                              color: blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- User Kind Toggle (3 options) ----------
  Widget _tripleToggle(dynamic state) {
    Widget chip(String text, UserKind kind) {
      final selected = userKind == kind;
      return Expanded(
        child: GestureDetector(
          onTap: state.loading ? null : () => setState(() => userKind = kind),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? Colors.black : const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFE5E7EB),
      ),
      child: Row(
        children: [
          chip('Student', UserKind.student),
          const SizedBox(width: 6),
          chip('Instructor', UserKind.instructor),
          const SizedBox(width: 6),
          chip('Assistant', UserKind.assistant),
        ],
      ),
    );
  }

  // ---------- Segmented (User/Owner) ----------
  Widget _segmented({
    required String leftText,
    required String rightText,
    required bool leftSelected,
    required VoidCallback? onLeft,
    required VoidCallback? onRight,
  }) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFE5E7EB),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: leftSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: leftSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    leftText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          leftSelected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          leftSelected ? Colors.black : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: onRight,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !leftSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !leftSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    rightText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          !leftSelected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          !leftSelected ? Colors.black : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- UI Helpers ----------
  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black, fontSize: 15)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38),
      prefixIcon: Icon(prefixIcon, color: Colors.black54),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black26),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade700),
        borderRadius: BorderRadius.circular(8),
      ),
      errorStyle: const TextStyle(height: 1.1),
    );
  }
}
