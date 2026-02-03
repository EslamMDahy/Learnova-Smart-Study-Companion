import 'package:flutter/material.dart';

class SignupLeftPanel extends StatelessWidget {
  const SignupLeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage("assets/signup.png"),
          fit: BoxFit.cover,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha:0.55),
            Colors.black.withValues(alpha:0.55),
          ],
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ------- Logo + Learnova -------
          Row(
            children: [
              Image.asset("assets/logo.png", height: 40),
              const SizedBox(width: 12),
              const Text(
                "Learnova",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // ------- Title -------
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "AI-Powered Learning for the\n",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                TextSpan(
                  text: "Modern Campus",
                  style: TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ------- Description -------
          SizedBox(
            width: 420,
            child: const Text(
              "Experience personalized assessments, adaptive question banks, and intelligent insights designed for students, instructors, and administrators.",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // ------- 3 Features -------
          Row(
            children: [
              _featureTag("Adaptive Learning", Icons.timeline),
              const SizedBox(width: 12),
              _featureTag("Real-time Analytics", Icons.analytics_outlined),
              const SizedBox(width: 12),
              _featureTag("Enterprise Grade", Icons.shield_outlined),
            ],
          ),

          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // ---------- Feature Border Box ----------
  Widget _featureTag(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha:0.20), width: 1.2),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
