import 'package:flutter/material.dart';

class EmptyOrgState extends StatelessWidget {
  final VoidCallback onCreateOrganizationPressed;

  const EmptyOrgState({
    super.key,
    required this.onCreateOrganizationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),

              const Text(
                "No Organization Found",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "Lexend",
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 60 / 48,
                  letterSpacing: -1.2,
                  color: Color(0xFF111418),
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                "Welcome to Learnova. You haven't set up or joined an organization\n"
                "yet. Create a new organization to start using the Smart Study\n"
                "Companion management tools.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "Lexend",
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 24 / 16,
                  color: Color(0xFF617589),
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: onCreateOrganizationPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF137FEC), // figma primary
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Create Your Organization",
                    style: TextStyle(
                      fontFamily: "Lexend",
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 21 / 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
