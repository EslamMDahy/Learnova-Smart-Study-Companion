import 'package:flutter/material.dart';
import 'package:learnova/features/auth/login/login_page.dart';

class ForgetPasswordForm extends StatelessWidget {
  const ForgetPasswordForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- ICON ----------------
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.refresh, color: Color(0xFF137FEC), size: 26),
            ),
          ),

          const SizedBox(height: 24),

          // ---------------- TITLE ----------------
          const Text(
            "Forgot password?",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 12),

          // ---------------- DESCRIPTION ----------------
          const Text(
            "No worries, we'll send you reset instructions. Please enter\n"
            "the email associated with your account.",
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF617589),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // ---------------- EMAIL LABEL ----------------
          const Text(
            "Email address",
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          // ---------------- EMAIL FIELD ----------------
          TextField(
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: "student@university.edu",
              hintStyle: const TextStyle(color: Color(0xFF9AA4B2)),
              prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFDBE0E6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFDBE0E6),
                  width: 1.3,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ---------------- BUTTON ----------------
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF137FEC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Send Reset Link",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ---------------- RETURN LOGIN ----------------
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: Color(0xFF617589),
                    ),
                    SizedBox(width: 6),
                    Text(
                      "Return to Log In",
                      style: TextStyle(
                        color: Color(0xFF617589),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          const Divider(color: Color(0xFFDBE0E6)),

          const SizedBox(height: 16),

          // ---------------- FOOTER INFO ----------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.verified_user, color: Color(0xFF137FEC), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Secure, enterprise-grade authentication. If you don't receive an email "
                  "within 5 minutes, please check your spam folder or contact university IT support.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF617589),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
