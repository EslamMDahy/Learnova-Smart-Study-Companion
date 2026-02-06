import 'package:flutter/material.dart';
import 'widgets/forget_password_left_panel.dart';
import 'widgets/forget_password_form.dart';

class ForgetPasswordPage extends StatelessWidget {
  const ForgetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: width < 800
          // ---------------- MOBILE ----------------
          ? Container(
              color: Colors.white,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: const ForgetPasswordForm(),
                ),
              ),
            )
          // ---------------- DESKTOP ----------------
          : Row(
              children: [
                // LEFT PANEL
                Expanded(
                  flex: width < 1200 ? 3 : 2,
                  child: const ForgetPasswordLeftPanel(),
                ),

                // RIGHT PANEL (FORM CONTAINER)
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal:
                              80, 
                          vertical: 80,
                        ),
                        child: Align(
                          alignment: Alignment.topLeft, 
                          child: const ForgetPasswordForm(),
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
