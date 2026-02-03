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

  @override
  void dispose() {
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

    if (ok) {
      context.go(Routes.home);
    }
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
                  ] else
                    const SizedBox(height: 8),

                  // EMAIL
                  const Text('Email',
                      style: TextStyle(color: Colors.black, fontSize: 15)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.black),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'Email is required';
                      if (!value.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter your email address',
                      hintStyle: const TextStyle(color: Colors.black38),
                      prefixIcon:
                          const Icon(Icons.mail_outline, color: Colors.black54),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.black26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      errorStyle: const TextStyle(height: 1.1),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // PASSWORD
                  const Text('Password',
                      style: TextStyle(color: Colors.black, fontSize: 15)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.black),
                    validator: (v) {
                      if ((v ?? '').isEmpty) return 'Password is required';
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: const TextStyle(color: Colors.black38),
                      prefixIcon:
                          const Icon(Icons.lock_outline, color: Colors.black54),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.black54,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.black26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      errorStyle: const TextStyle(height: 1.1),
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

                  // LOGIN BUTTON
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

                  // SOCIAL - GOOGLE
                  _socialButton(
                    label: 'Google',
                    onTap: () {},
                    imagePath: 'assets/google.png',
                  ),
                  const SizedBox(height: 12),

                  // SOCIAL - MICROSOFT
                  _socialButton(
                    label: 'Microsoft',
                    onTap: () {},
                    imagePath: 'assets/microsoft.png',
                  ),

                  const SizedBox(height: 20),

                  // SIGN UP TEXT
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

  // ---------------- DIVIDER ----------------
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

  // ---------------- SOCIAL BUTTON ----------------
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
