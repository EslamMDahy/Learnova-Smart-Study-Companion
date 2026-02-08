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

  // UI/local error (terms etc.)
  String? _localError;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _clearLocalError() {
    if (_localError != null) setState(() => _localError = null);
  }

  void _onSwitchAccountType(AccountType type) {
    if (accountType == type) return;

    setState(() {
      accountType = type;
      _localError = null;

      // لو رايح Owner: role default مش مهم للـ owner لكن نخليه منظم
      if (type == AccountType.owner) {
        userKind = UserKind.student; // irrelevant for owner
      }
    });

    // امسح API error كمان
    ref.read(signupControllerProvider.notifier).clearError();
  }

  String? _validatePassword(String? v) {
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

  Future<void> _onCreateAccount() async {
    if (_autoValidate != AutovalidateMode.onUserInteraction) {
      setState(() => _autoValidate = AutovalidateMode.onUserInteraction);
    }

    _clearLocalError();
    ref.read(signupControllerProvider.notifier).clearError();

    final okForm = _formKey.currentState?.validate() ?? false;
    if (!okForm) return;

    if (!isChecked) {
      setState(() => _localError = 'Please accept Terms and Privacy Policy.');
      return;
    }

    final fullName =
        '${firstNameController.text.trim()} ${lastNameController.text.trim()}'
            .trim();

    // ✅ system_role matches backend allowed set
    final systemRole =
        accountType == AccountType.owner ? 'owner' : userKind.name;

    final ok = await ref.read(signupControllerProvider.notifier).signup(
          fullName: fullName,
          email: emailController.text.trim(),
          password: passwordController.text,
          systemRole: systemRole,
        );

    if (!mounted) return;

    if (ok) {
      // ✅ حركة كريتيف: نروح login ومعانا باراميتر "signed=1"
      context.go('${Routes.login}?signed=1');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signupControllerProvider);

    // shown error: local first then api
    final shownError = _localError ?? state.error;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 24 : 56),
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              autovalidateMode: _autoValidate,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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

                  if (shownError != null) ...[
                    _ErrorBox(message: shownError),
                    const SizedBox(height: 14),
                  ],

                  _segmented(
                    leftText: 'User',
                    rightText: 'Owner',
                    leftSelected: accountType == AccountType.user,
                    onLeft: state.loading
                        ? null
                        : () => _onSwitchAccountType(AccountType.user),
                    onRight: state.loading
                        ? null
                        : () => _onSwitchAccountType(AccountType.owner),
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
                            onChanged: (_) {
                              _clearLocalError();
                              ref
                                  .read(signupControllerProvider.notifier)
                                  .clearError();
                            },
                            controller: firstNameController,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              height: 1.4,
                            ),
                            validator: (v) =>
                                (v ?? '').trim().isEmpty ? 'Required' : null,
                            decoration: InputDecoration(
                              hintText: 'Enter first name',
                              hintStyle: const TextStyle(
                                color: Colors.black38,
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: Colors.black45,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF137FEC),
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE53935),
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE53935),
                                  width: 1.5,
                                ),
                              ),
                              errorStyle: const TextStyle(
                                fontSize: 12,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _labeledField(
                          label: 'Last Name',
                          child: TextFormField(
                            onChanged: (_) {
                              _clearLocalError();
                              ref
                                  .read(signupControllerProvider.notifier)
                                  .clearError();
                            },
                            controller: lastNameController,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              height: 1.4,
                            ),
                            validator: (v) =>
                                (v ?? '').trim().isEmpty ? 'Required' : null,
                            decoration: InputDecoration(
                              hintText: 'Enter last name',
                              hintStyle: const TextStyle(
                                color: Colors.black38,
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: Colors.black45,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF137FEC),
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE53935),
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE53935),
                                  width: 1.5,
                                ),
                              ),
                              errorStyle: const TextStyle(
                                fontSize: 12,
                                height: 1.2,
                              ),
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
                      onChanged: (_) {
                        _clearLocalError();
                        ref.read(signupControllerProvider.notifier).clearError();
                      },
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        height: 1.4,
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Email is required';
                        if (!s.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter your email address',
                        hintStyle: const TextStyle(
                          color: Colors.black38,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.mail_outline,
                          color: Colors.black45,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF137FEC),
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE53935),
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE53935),
                            width: 1.5,
                          ),
                        ),
                        errorStyle: const TextStyle(
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  _labeledField(
                    label: 'Password',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          onChanged: (_) {
                            _clearLocalError();
                            ref.read(signupControllerProvider.notifier).clearError();
                            setState(() {}); // لتحديث مؤشر القوة
                          },
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            height: 1.4,
                          ),
                          validator: _validatePassword,
                          decoration: InputDecoration(
                            hintText: 'Create a password',
                            hintStyle: const TextStyle(
                              color: Colors.black38,
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Colors.black45,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              splashRadius: 18,
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.black45,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF137FEC),
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE53935),
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE53935),
                                width: 1.5,
                              ),
                            ),
                            errorStyle: const TextStyle(
                              fontSize: 12,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _PasswordStrengthHints(passwordController.text),
                      ],
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
                            : (v) => setState(() {
                                  isChecked = v ?? false;
                                  _clearLocalError();
                                }),
                      ),
                      Expanded(
                        child: Wrap(
                          children: [
                            const Text(
                              'I agree to the ',
                              style: TextStyle(color: Colors.black, fontSize: 14),
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
                              style: TextStyle(color: Colors.black, fontSize: 14),
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
                              style: TextStyle(color: Colors.white, fontSize: 16),
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
                        onTap: state.loading ? null : () => context.go(Routes.login),
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
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFC7C7)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFB00020),
          fontSize: 13,
          height: 1.2,
        ),
      ),
    );
  }
}

/// ✅ كريتيف خفيف: Chips توضح شروط الباسورد بدل ما المستخدم يتبهدل
class _PasswordStrengthHints extends StatelessWidget {
  final String password;
  const _PasswordStrengthHints(this.password);

  bool _has(String pattern) => RegExp(pattern).hasMatch(password);
  bool get _len => password.trim().length >= 8;

  @override
  Widget build(BuildContext context) {
    Widget chip(String text, bool ok) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: ok ? const Color(0xFFEAF7EE) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: ok ? const Color(0xFFBEE6C7) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: ok ? const Color(0xFF1E7A36) : const Color(0xFF6B7280),
            fontWeight: ok ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip("8+ chars", _len),
        chip("A-Z", _has(r'[A-Z]')),
        chip("a-z", _has(r'[a-z]')),
        chip("0-9", _has(r'\d')),
        chip("Symbol", _has(r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\]=+~`]')),
      ],
    );
  }
}
