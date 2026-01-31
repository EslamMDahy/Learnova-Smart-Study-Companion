import 'package:flutter/material.dart';
import '../widgets/left_panel.dart';
import '../widgets/login_form.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/routes.dart';



class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return Row(
              children: const [
                Expanded(flex: 6, child: LeftPanel()),
                Expanded(flex: 4, child: LoginForm(isMobile: false)),
              ],
            );
          }

          return const LoginForm(isMobile: true);
        },
      ),
    );
  }
}
