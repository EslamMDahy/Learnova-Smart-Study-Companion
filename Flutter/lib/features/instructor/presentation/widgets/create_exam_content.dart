import 'package:flutter/material.dart';
import 'create_exam_content2.dart';
import 'create_exam_content3.dart';

class CreateExamContent extends StatefulWidget {
  final int currentStep;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const CreateExamContent({
    super.key,
    required this.currentStep,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<CreateExamContent> createState() => _CreateExamContentState();
}

class _CreateExamContentState extends State<CreateExamContent> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header Section ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Create New Exam",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Step ${widget.currentStep}: ${widget.currentStep == 1
                        ? 'Basic Details'
                        : widget.currentStep == 2
                        ? 'Add Questions'
                        : 'Settings'}",
                    style: TextStyle(
                      color: Colors.blueGrey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _headerActionBtn("Save Draft", isPrimary: false),
                  const SizedBox(width: 12),
                  _headerActionBtn("Publish Quiz", isPrimary: true),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // --- Stepper Section (Visual indicators) ---
          Row(
            children: [
              _buildStepItem(
                stepNumber: 1,
                label: "1. Basic Details",
                isActive: widget.currentStep == 1,
                isCompleted: widget.currentStep > 1,
              ),
              _buildDivider(),
              _buildStepItem(
                stepNumber: 2,
                label: "2. Add Questions",
                isActive: widget.currentStep == 2,
                isCompleted: widget.currentStep > 2,
              ),
              _buildDivider(),
              _buildStepItem(
                stepNumber: 3,
                label: "3. Settings",
                isActive: widget.currentStep == 3,
                isCompleted: widget.currentStep > 3,
              ),
            ],
          ),
          const SizedBox(height: 40),

          // --- Dynamic Content Area (The Switcher) ---
          // هنا الكود بيبدل المحتوى بناء على الخطوة الحالية
          _buildStepFormContent(),

          const SizedBox(height: 40),

          // --- Navigation Buttons (Bottom) ---
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed:
                      widget.onBack, // بيستخدم الـ callback اللي مبعوت من برا
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: Text(
                    widget.currentStep == 1
                        ? "Back to Dashboard"
                        : "Back to Previous",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: widget
                      .onNext, // بيستخدم الـ callback اللي مبعوت من برا للتحرك للأمام
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(widget.currentStep == 3 ? "Finish" : "Next Step"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // دالة اختيار المحتوى بناءً على الخطوة الحالية
  Widget _buildStepFormContent() {
    switch (widget.currentStep) {
      case 1:
        return _buildStep1Fields(); // فورم الخطوة الأولى موجود تحت في نفس الملف
      case 2:
        return const CreateExamContent2(); // بيعرض محتوى الملف التاني
      case 3:
        return const CreateExamContent3(); // بيعرض محتوى الملف التالت
      default:
        return const SizedBox.shrink();
    }
  }

  // --- Step 1 Fields (Basic Details) ---
  Widget _buildStep1Fields() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Quiz Title *"),
          TextField(
            decoration: _inputDecoration(
              "e.g., Midterm Exam - Data Structures",
            ),
          ),
          const SizedBox(height: 24),
          _buildLabel("Description / Instructions"),
          Text(
            "Provide instructions for students before they begin.",
            style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 5,
            decoration: _inputDecoration("Enter detailed instructions here..."),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Exam Category"),
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration("Quiz"),
                      items: const [
                        DropdownMenuItem(value: "Quiz", child: Text("Quiz")),
                      ],
                      onChanged: (v) {},
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Tags (Optional)"),
                    TextField(
                      decoration: _inputDecoration(
                        "Add tags separated by comma...",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- UI Helpers (نفس الـ Helpers اللي كانت عندك) ---
  Widget _headerActionBtn(String label, {required bool isPrimary}) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? const Color(0xFF2563EB) : Colors.white,
        foregroundColor: isPrimary ? Colors.white : const Color(0xFF0F172A),
        side: isPrimary
            ? BorderSide.none
            : const BorderSide(color: Color(0xFFE2E8F0)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  Widget _buildStepItem({
    required int stepNumber,
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    Color mainColor = isActive
        ? const Color(0xFF2563EB)
        : (isCompleted ? const Color(0xFF10B981) : Colors.blueGrey.shade300);
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive || isCompleted ? mainColor : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: mainColor, width: 2),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    "$stepNumber",
                    style: TextStyle(
                      color: isActive ? Colors.white : mainColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: isActive || isCompleted
                ? const Color(0xFF0F172A)
                : Colors.blueGrey.shade400,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() => Container(
    width: 40,
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color: Colors.blueGrey.shade200,
  );

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );
}
