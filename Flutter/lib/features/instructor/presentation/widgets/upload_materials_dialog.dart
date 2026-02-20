import 'package:flutter/material.dart';

class UploadMaterialsDialog extends StatelessWidget {
  const UploadMaterialsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 900,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Upload Course Materials", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              "Add resources for the AI to analyze and generate study aids.\nSupported formats: PDF, DOCX, PPTX, MP4. Max file size: 500MB.",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildDragAndDropArea()),
                const SizedBox(width: 24),
                Expanded(flex: 1, child: _buildUploadQueue()),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B)))),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text("Save to Course"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragAndDropArea() {
    return Column(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE), width: 1), 
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: Color(0xFFDBEAFE), shape: BoxShape.circle), child: const Icon(Icons.cloud_upload_outlined, size: 40, color: Color(0xFF2563EB))),
              const SizedBox(height: 16),
              const Text("Drag & Drop files here", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("or click to browse from your computer.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white), child: const Text("Browse Files")),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _guidelineRow(Icons.info_outline, "Ensure scanned PDFs have OCR enabled for better AI analysis."),
              const SizedBox(height: 8),
              _guidelineRow(Icons.info_outline, "Video lectures should have clear audio for accurate transcription."),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadQueue() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Upload Queue", style: TextStyle(fontWeight: FontWeight.bold)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)), child: const Text("3 Files", style: TextStyle(fontSize: 10, color: Color(0xFF2563EB)))),
            ],
          ),
          const SizedBox(height: 20),
          _uploadItem("Lecture_04_Neural_Nets.pdf", "2.4 MB", 0.45, Colors.red),
          _uploadItem("Assignment_Brief_v2.docx", "AI Analyzing Content...", null, Colors.blue),
          _uploadItem("Guest_Speaker_Session.mp4", "Ready for Review", 1.0, Colors.purple, isDone: true),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () {}, child: const Text("Clear Completed"))),
        ],
      ),
    );
  }

  Widget _uploadItem(String name, String status, double? progress, Color iconColor, {bool isDone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(Icons.description, color: iconColor.withOpacity(0.2), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(status, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                if (progress != null && !isDone) ...[const SizedBox(height: 4), LinearProgressIndicator(value: progress, minHeight: 4, borderRadius: BorderRadius.circular(2))],
                if (isDone) ...[const SizedBox(height: 4), const Row(children: [Icon(Icons.check_circle, size: 12, color: Colors.green), SizedBox(width: 4), Text("Ready for Review", style: TextStyle(fontSize: 10, color: Colors.green))])]
              ],
            ),
          ),
          const Icon(Icons.close, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _guidelineRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
      ],
    );
  }
}