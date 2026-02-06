import 'package:flutter/material.dart';

class SignupLeftPanel extends StatelessWidget {
  const SignupLeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF071019), // لون غامق من فوق
            Color(0xFF02060A), // غامق أكتر من تحت
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // --- BACKGROUND IMAGE ---
          Opacity(
            opacity: 0.32,
            child: Image.asset(
              'assets/signup.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          // --- TEXT CONTENT ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO ROW
                Row(
                  children: [
                    Image.asset(
                      'assets/logo.png', // logo icon
                      height: 34,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Learnova",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // TITLE
                const Text(
                  "Empowering students\nand faculty with\nintelligent tools.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 15),

                // SUBTEXT
                const Text(
                  "Experience the future of academic assessment and learning\n"
                  "management driven by advanced AI. Join thousands of users\n"
                  "achieving better outcomes.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
