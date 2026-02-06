// features/admin/dashboard/widgets/empty_org_state.dart
import 'package:flutter/material.dart';
import 'create_org_dialog.dart';

class EmptyOrgState extends StatelessWidget {
  final VoidCallback onOrgCreated;
  const EmptyOrgState({super.key, required this.onOrgCreated});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("No Organization Found", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 16),
          const Text(
            "Welcome to Learnova. You haven’t set up or joined an organization\nyet. Create a new organization to start using the Smart Study\n Companion management tools..",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              // إظهار الـ Pop up
              final result = await showDialog(
                context: context,
                builder: (context) => const CreateOrgDialog(),
              );
              if (result == true) onOrgCreated(); // لو داس Create، نغير الحالة
            },
            child: const Text("Create Your Organization", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}