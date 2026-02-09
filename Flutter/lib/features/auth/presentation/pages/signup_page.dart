import 'package:flutter/material.dart';
import '../widgets/signup_left_panel.dart';
import '../widgets/signup_form.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return Row(
              children: const [
                Expanded(flex: 5, child: SignupLeftPanel()),
                Expanded(flex: 5, child: SignUpForm(isMobile: false)),
              ],
            );
          }

          return const SignUpForm(isMobile: true);
        },
      ),
    );
  }
}
