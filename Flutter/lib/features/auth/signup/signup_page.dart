import 'package:flutter/material.dart';
import 'package:learnova/features/auth/signup/widgets/signupLeftPanel.dart';
import 'widgets/signup_form.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: width < 800
          // ---------------- MOBILE ----------------
          ? Container(
              color: Colors.white, // ✅ يمنع اللون الكحلي
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: const SignUpForm(),
                    ),
                  ),
                ),
              ),
            )

          // ---------------- DESKTOP ----------------
          : Row(
              children: [
                // LEFT PANEL
                Expanded(
                  flex: width < 1200 ? 3 : 2,
                  child: const SignupLeftPanel(),
                ),

                // RIGHT PANEL
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: const SignUpForm(),
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
}
