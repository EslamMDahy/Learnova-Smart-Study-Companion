import 'package:flutter/material.dart';
import 'package:learnova/features/auth/login/login_page.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  bool isStudent = true;
  bool isChecked = false;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final idController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            // 🔥 يخلي الفورم في النص
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520, // عرض ثابت احترافي
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------------- HEADER ------------------
                    const Text(
                      "Create your account",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Start your journey with AI-driven personalized assessments today.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(144, 0, 0, 0),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ---------------- SWITCH BUTTON ------------------
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0xFFE5E7EB),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => isStudent = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 230),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isStudent
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: isStudent
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.06,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    "Student",
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: isStudent
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isStudent
                                          ? Colors.black
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => isStudent = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 230),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: !isStudent
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: !isStudent
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.06,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    "Instructor",
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: !isStudent
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: !isStudent
                                          ? Colors.black
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ---------------- FIRST / LAST NAME ------------------
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: firstNameController,
                            label: "First Name",
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: lastNameController,
                            label: "Last Name",
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: emailController,
                      label: "University Email",
                      prefixIcon: Icons.email_outlined,
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: idController,
                      label: "Student ID",
                      prefixIcon: Icons.badge_outlined,
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: passwordController,
                      label: "Password",
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                    ),

                    const SizedBox(height: 12),

                    // ---------------- CHECKBOX ------------------
                    Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          activeColor: Colors.blue,
                          checkColor: Colors.white,
                          onChanged: (v) =>
                              setState(() => isChecked = v ?? false),
                        ),
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              text: "I agree to the ",
                              style: const TextStyle(color: Colors.black),
                              children: const [
                                TextSpan(
                                  text: "Terms",
                                  style: TextStyle(color: Colors.blue),
                                ),
                                TextSpan(
                                  text: " and ",
                                  style: TextStyle(color: Colors.black),
                                ),
                                TextSpan(
                                  text: "Privacy Policy",
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ---------------- CREATE ACCOUNT ------------------
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Create Account",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ------------ OR REGISTER WITH ----------------
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            "Or register with",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ------------ GOOGLE + MICROSOFT ----------------
                    Row(
                      children: [
                        Expanded(
                          child: _socialButton("Google", "assets/google.png"),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _socialButton(
                            "Microsoft",
                            "assets/microsoft.png",
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ------------ LOGIN LINK ----------------
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Already have an account? ",
                            style: TextStyle(color: Colors.black),
                          ),

                          MouseRegion(
                            cursor: SystemMouseCursors.click, // 🖱️ شكل الماوس
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Log in",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===============================================================
  // ---------------- REUSABLE TEXTFIELD ---------------------------
  // ===============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelStyle: const TextStyle(color: Colors.black),
        labelStyle: const TextStyle(color: Colors.black54),

        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.black54)
            : null,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),

        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xffD1D5DB)),
          borderRadius: BorderRadius.circular(8),
        ),

        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Color.fromARGB(126, 0, 0, 0),
            width: 1.3,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      style: const TextStyle(color: Colors.black),
    );
  }

  // ---------------- SOCIAL BUTTON ------------------
  static Widget _socialButton(String text, String iconPath) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffD1D5DB)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(iconPath, height: 22),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.black, fontSize: 15)),
        ],
      ),
    );
  }
}
