import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/routes.dart';
import '../controllers/login_controller.dart';

class LoginForm extends ConsumerStatefulWidget {
  final bool isMobile;
  const LoginForm({super.key, this.isMobile = false});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final blue = const Color(0xFF137FEC);

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool rememberMe = false;
  bool _obscurePassword = true;

  // ✅ success banners state
  bool _showResetSuccess = false;
  bool _showVerifiedSuccess = false;
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final uri = GoRouterState.of(context).uri;
      final resetDone = uri.queryParameters['reset'] == '1';
      final verifiedDone = uri.queryParameters['verified'] == '1';

      // ✅ IMPORTANT: clear any old banner state (because page can be reused)
      setState(() {
        _showResetSuccess = false;
        _showVerifiedSuccess = false;
      });

      // ✅ show correct banner based on query params
      if (verifiedDone) {
        setState(() => _showVerifiedSuccess = true);
      }
      if (resetDone) {
        setState(() => _showResetSuccess = true);
      }

      // ✅ remove query params cleanly (so banner doesn't re-appear)
      if (verifiedDone || resetDone) {
        final clean = uri.replace(queryParameters: {});
        context.replace(clean.toString());

        // ✅ auto-hide after 3s
        _successTimer?.cancel();
        _successTimer = Timer(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() {
            _showResetSuccess = false;
            _showVerifiedSuccess = false;
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final okForm = _formKey.currentState?.validate() ?? false;
    if (!okForm) return;

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    final ok = await ref
        .read(loginControllerProvider.notifier)
        .login(email, password, persist: rememberMe);

    if (!mounted) return;

    if (ok) context.go(Routes.admin);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final err = state.error;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 24 : 56),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please sign in to access your dashboard.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  // ✅ Email verified banner
                  if (_showVerifiedSuccess && err == null) ...[
                    _SuccessBanner(
                      title: "Email verified!",
                      message:
                          "Your email has been verified successfully. You can log in now.",
                      onClose: () => setState(() => _showVerifiedSuccess = false),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ✅ Reset password banner
                  if (_showResetSuccess && err == null) ...[
                    _SuccessBanner(
                      title: "All set!",
                      message:
                          "Your password has been updated. Log in with the new one.",
                      onClose: () => setState(() => _showResetSuccess = false),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ERROR (from Riverpod state)
                  if (err != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3F3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFC7C7)),
                      ),
                      child: Text(
                        err,
                        style: const TextStyle(
                          color: Color(0xFFB00020),
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  const Text('Email',
                      style: TextStyle(color: Colors.black, fontSize: 15)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) =>
                        ref.read(loginControllerProvider.notifier).clearError(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      height: 1.4,
                    ),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'Email is required';
                      if (!value.contains('@')) return 'Enter a valid email';
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

                  const SizedBox(height: 20),

                  const Text('Password',
                      style: TextStyle(color: Colors.black, fontSize: 15)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    onChanged: (_) =>
                        ref.read(loginControllerProvider.notifier).clearError(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      height: 1.4,
                    ),
                    validator: (v) {
                      if ((v ?? '').isEmpty) return 'Password is required';
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
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

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        activeColor: Colors.blue,
                        checkColor: Colors.white,
                        onChanged: state.loading
                            ? null
                            : (v) => setState(() => rememberMe = v ?? false),
                      ),
                      const Text(
                        'Remember me',
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: state.loading
                            ? null
                            : () => context.go(Routes.forgotPassword),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(color: blue, fontSize: 14),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

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
                      onPressed: state.loading ? null : _onLogin,
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
                              'Log In',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),

                  const SizedBox(height: 28),
                  _divider(),
                  const SizedBox(height: 24),

                  _socialButton(
                    label: 'Google',
                    onTap: () {},
                    imagePath: 'assets/google.png',
                  ),
                  const SizedBox(height: 12),

                  _socialButton(
                    label: 'Microsoft',
                    onTap: () {},
                    imagePath: 'assets/microsoft.png',
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.black),
                      ),
                      InkWell(
                        onTap: state.loading ? null : () => context.go(Routes.signup),
                        child: Text(
                          "Sign up",
                          style: TextStyle(
                            color: blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Row(
      children: const [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR CONTINUE WITH',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(child: Divider()),
      ],
    );
  }

  Widget _socialButton({
    required String label,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.black26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 40, height: 35, fit: BoxFit.contain),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onClose;

  const _SuccessBanner({
    required this.title,
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7EE),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBEE6C7)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.check_circle,
                  color: Color(0xFF1E7A36), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF145A29),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF1E7A36),
                      fontSize: 13,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onClose,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close,
                    size: 16, color: Color(0xFF1E7A36)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
