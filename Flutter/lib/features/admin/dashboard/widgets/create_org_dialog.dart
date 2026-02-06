import 'package:flutter/material.dart';

class CreateOrgDialog extends StatelessWidget {
  const CreateOrgDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(40),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Create New Organization",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 8),
              const Text(
                "Set up a new institutional account for your university, school, or research center.",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 32),

              // --- Section 1: Organization Details ---
              _buildFormSection(
                title: "Organization Details",
                icon: Icons.account_balance_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildTextField("Organization Name", "e.g. Stanford University")),
                      const SizedBox(width: 20),
                      Expanded(child: _buildDropdownField("Organization Type", "Select type...")),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildTextField("Primary Domain", "university.edu", icon: Icons.language)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildTextField("Location", "e.g. Palo Alto, CA")),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildLogoUploadSection(),
                ],
              ),

              const SizedBox(height: 24),

              // --- Section 2: Primary Administrator ---
              _buildFormSection(
                title: "Primary Administrator",
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildTextField("Full Name", "e.g. Dr. Jane Smith")),
                      const SizedBox(width: 20),
                      Expanded(child: _buildTextField("Administrator Email", "admin@university.edu")),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // --- Action Buttons ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Create Organization", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _buildFooterInfo(),
              const SizedBox(height: 24),
              const Text("© 2024 Learnova Academic Platform. All rights reserved.", 
                style: TextStyle(fontSize: 12, color: Colors.black38)),
            ],
          ),
        ),
      ),
    );
  }

  // --- الميثود الأساسية للـ Input Field ---
  Widget _buildTextField(String label, String hint, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 8),
        TextField(
          style: const TextStyle(color: Colors.black, fontSize: 14), 
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 18, color: Colors.black45) : null,
            filled: true,
            fillColor: Colors.white,
            hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            
            // الإطار العادي (قبل الضغط)
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            
            // ✅ الإطار عند الضغط (أزرق خفيف)
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF93C5FD), // لون أزرق خفيف (Blue 300)
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ميثود بناء الأقسام (الـ Cards البيضاء)
  Widget _buildFormSection({required String title, IconData? icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) Icon(icon, size: 20, color: const Color(0xFF2563EB)),
              if (icon != null) const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          ...children,
        ],
      ),
    );
  }

  // ميثود بناء الـ Dropdown (تم تعديل الإطار فيه أيضاً)
  Widget _buildDropdownField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black45),
              hint: Text(hint, style: const TextStyle(color: Colors.black26, fontSize: 13)),
              items: const [],
              onChanged: (v) {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Organization Logo", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF8FAFC),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined, color: Colors.black26),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Upload Logo", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 8),
                const Text("PNG, JPG up to 5MB. Recommended: 512x512px.", style: TextStyle(fontSize: 11, color: Colors.black45)),
              ],
            )
          ],
        ),
      ],
    );
  }

  Widget _buildFooterInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF)),
                children: [
                  TextSpan(text: "Need help? Check out our "),
                  TextSpan(text: "Setup Guide", style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                  TextSpan(text: " for university administrators or "),
                  TextSpan(text: "contact support", style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                  TextSpan(text: " for enterprise-specific features."),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}