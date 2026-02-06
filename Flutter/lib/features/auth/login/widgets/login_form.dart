import 'package:flutter/material.dart';
import 'package:learnova/features/auth/signup/signup_page.dart';
import 'package:learnova/features/auth/forget_password/forget_password_page.dart';

class LoginForm extends StatefulWidget {
  final bool isMobile;
  const LoginForm({super.key, this.isMobile = false});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool rememberMe = false;
  bool _obscurePassword = true; // 👁️ show/hide password

  final blue = const Color(0xFF137FEC);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 24 : 56),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
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
                const SizedBox(height: 32),

                // EMAIL
                const Text(
                  'Email',
                  style: TextStyle(color: Colors.black, fontSize: 15),
                ),
                const SizedBox(height: 6),
                _inputField(
                  hint: 'Enter your email address',
                  icon: Icons.mail_outline,
                ),

                const SizedBox(height: 20),

                // PASSWORD
                const Text(
                  'Password',
                  style: TextStyle(color: Colors.black, fontSize: 15),
                ),
                const SizedBox(height: 6),

                // 🔐 PASSWORD FIELD (WITH EYE ICON)
                TextField(
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: const TextStyle(color: Colors.black38),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.black54,
                    ),

                    // 👁️ eye icon
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
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
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      activeColor: Colors.blue,
                      checkColor: Colors.white,
                      onChanged: (v) {
                        setState(() {
                          rememberMe = v!;
                        });
                      },
                    ),
                    const Text(
                      'Remember me',
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                    const Spacer(),

                    // 🔁 FORGOT PASSWORD (NAVIGATION)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgetPasswordPage(),
                          ),
                        );
                      },
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
                    onPressed: () {},
                    child: const Text(
                      'Log In',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpPage(),
                          ),
                        );
                      },
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
    );
  }

  // ---------------- INPUT FIELD ----------------
  Widget _inputField({required String hint, required IconData icon}) {
    return TextField(
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        prefixIcon: Icon(icon, color: Colors.black54),
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
