import 'package:flutter/material.dart';
import 'package:learnova/features/instructor/presentation/widgets/create_exam_content.dart';
import 'upload_materials_dialog.dart';

class MaterialsExplorerPage extends StatefulWidget {
  const MaterialsExplorerPage({super.key});

  @override
  State<MaterialsExplorerPage> createState() => _MaterialsExplorerPageState();
}

class _MaterialsExplorerPageState extends State<MaterialsExplorerPage> {
  // متغير للتحكم في الخطوة الحالية للاختبار عند فتحه في Navigator
  int _currentExamStep = 1;

  // Function مساعدة لفتح الـ Pop-up الخاص برفع الملفات
  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const UploadMaterialsDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildFullWidthTopBar(context),
          const Divider(height: 1, color: Color(0xFFEDF2F7)),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAdvancedHierarchy(),
                const VerticalDivider(width: 1, color: Color(0xFFEDF2F7)),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          color: const Color(0xFFF8FAFC),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildContentHeaderWithActions(),
                                const SizedBox(height: 24),
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: _buildBlackVideoPlayer(),
                                      ),
                                      const SizedBox(width: 20),
                                      SizedBox(
                                        width: 280,
                                        child: _buildAIAnalysisCard(),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildDetailedTranscriptContent(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _buildVideoAreaBottomStatus(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- شريط الحالة السفلي وزر توليد الأسئلة ---
  Widget _buildVideoAreaBottomStatus(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDF2F7))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Last auto-saved 2 mins ago",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          ElevatedButton(
            onPressed: () {
              // إعادة تعيين الخطوة إلى 1 عند فتح النافذة
              _currentExamStep = 1;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    // نستخدم StatefulBuilder هنا لكي نتمكن من تحديث الحالة (setState) داخل الصفحة الجديدة
                    body: StatefulBuilder(
                      builder:
                          (BuildContext context, StateSetter setInternalState) {
                            return CreateExamContent(
                              currentStep: _currentExamStep,
                              onBack: () {
                                if (_currentExamStep > 1) {
                                  setInternalState(() => _currentExamStep--);
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                              onNext: () {
                                if (_currentExamStep < 3) {
                                  setInternalState(() => _currentExamStep++);
                                } else {
                                  // إذا انتهت الخطوات نغلق الصفحة
                                  Navigator.pop(context);
                                }
                              },
                            );
                          },
                    ),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0655FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Generate Question",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- الجزء العلوي (Top Bar) ---
  Widget _buildFullWidthTopBar(BuildContext context) => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      children: [
        const Text(
          "Materials Explorer",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => _showUploadDialog(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text("Add Material"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    ),
  );

  // --- قائمة الملفات الجانبية (Sidebar) ---
  Widget _buildAdvancedHierarchy() {
    return Container(
      width: 300,
      color: const Color(0xFFFBFBFB),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  "EXPLORER",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.create_new_folder_outlined,
                  size: 18,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.note_add_outlined,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildTreeRow(
                  label: "Data Structures Course",
                  type: "folder",
                  depth: 0,
                  isOpen: true,
                ),
                _buildTreeRow(
                  label: "01 - Introduction",
                  type: "folder",
                  depth: 1,
                  isOpen: true,
                ),
                _buildTreeRow(label: "Syllabus.pdf", type: "file", depth: 2),
                _buildTreeRow(
                  label: "Intro_Video.mp4",
                  type: "video",
                  depth: 2,
                  isSelected: true,
                ),
                _buildTreeRow(
                  label: "02 - Binary Trees",
                  type: "folder",
                  depth: 1,
                  isOpen: false,
                ),
                _buildTreeRow(label: "README.md", type: "file", depth: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeRow({
    required String label,
    required String type,
    required int depth,
    bool isOpen = false,
    bool isSelected = false,
  }) {
    IconData iconData;
    Color iconColor;
    switch (type) {
      case "folder":
        iconData = isOpen
            ? Icons.keyboard_arrow_down
            : Icons.keyboard_arrow_right;
        iconColor = const Color(0xFF64748B);
        break;
      case "video":
        iconData = Icons.play_circle_outline;
        iconColor = const Color(0xFF3B82F6);
        break;
      default:
        iconData = Icons.insert_drive_file_outlined;
        iconColor = const Color(0xFF94A3B8);
    }
    return InkWell(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.only(
          left: 12.0 + (depth * 16.0),
          right: 12,
          top: 6,
          bottom: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE2E8F0) : Colors.transparent,
          border: isSelected
              ? const Border(
                  left: BorderSide(color: Color(0xFF3B82F6), width: 2),
                )
              : null,
        ),
        child: Row(
          children: [
            if (type == "folder")
              Icon(iconData, size: 18, color: iconColor)
            else
              const SizedBox(width: 18),
            const SizedBox(width: 6),
            Icon(
              type == "folder"
                  ? (isOpen ? Icons.folder_open : Icons.folder)
                  : iconData,
              size: 18,
              color: type == "folder" ? const Color(0xFFF59E0B) : iconColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF334155),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedTranscriptContent() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Transcript & Content",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                _editorIcon(Icons.format_bold),
                _editorIcon(Icons.format_italic),
                _editorIcon(Icons.format_list_bulleted),
                _editorIcon(Icons.link),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Topic Analysis & Implementation",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "This section covers the core logic and properties essential for understanding binary trees...",
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editorIcon(IconData icon) => Padding(
    padding: const EdgeInsets.only(left: 12),
    child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
  );

  Widget _buildBlackVideoPlayer() => Container(
    height: 400,
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Center(
      child: Icon(Icons.play_circle_fill, size: 60, color: Colors.white),
    ),
  );

  Widget _buildAIAnalysisCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.psychology_outlined,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  "AI Analysis",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Quality Score",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            _buildProgressIndicator(0.92, Colors.green),
            const SizedBox(height: 20),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                "#binary-tree",
                "#recursion",
              ].map((t) => _tagChip(t)).toList(),
            ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {},
            child: const Text("Regenerate", style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    ),
  );

  Widget _buildContentHeaderWithActions() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Maximum Depth Calculation",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          Text(
            "Topic Analysis & Code Implementation",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ],
      ),
      Row(
        children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined)),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    ],
  );

  Widget _tagChip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      t,
      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
    ),
  );

  Widget _buildProgressIndicator(double v, Color c) => LinearProgressIndicator(
    value: v,
    backgroundColor: const Color(0xFFF1F5F9),
    color: c,
    minHeight: 6,
    borderRadius: BorderRadius.circular(10),
  );
}
