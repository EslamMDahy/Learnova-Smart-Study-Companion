import 'package:flutter/material.dart';

import 'upload_materials_dialog.dart';
import 'package:learnova/features/instructor/presentation/widgets/create_exam_content.dart';

/// Materials Explorer content-only page.
/// IMPORTANT:
/// - Do NOT add Sidebar/TopHeader/Scaffold layout here.
/// - This page must be rendered inside InstructorShell (which already provides layout).
class MaterialsExplorerPage extends StatefulWidget {
  final String courseSlug;

  const MaterialsExplorerPage({
    super.key,
    required this.courseSlug,
  });

  @override
  State<MaterialsExplorerPage> createState() => _MaterialsExplorerPageState();
}

class _MaterialsExplorerPageState extends State<MaterialsExplorerPage> {
  final _materialsSearchController = TextEditingController();

  // For the "Generate Question" flow (croquis).
  int _currentExamStep = 1;

  @override
  void dispose() {
    _materialsSearchController.dispose();
    super.dispose();
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const UploadMaterialsDialog(),
    );
  }

  void _openGenerateQuestionFlow() {
    _currentExamStep = 1;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Generate Question",
      pageBuilder: (_, __, ___) {
        return Material(
          color: Colors.white,
          child: SafeArea(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setInternalState) {
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
                      Navigator.pop(context);
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Content-only root (no Scaffold) so InstructorShell owns the layout.
    return Container(
      color: const Color(0xFFF6F7F8),
      child: Column(
        children: [
          _buildMaterialsHeader(),
          const Divider(height: 1, color: Color(0xFFEDF2F7)),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHierarchyPanel(),
                const VerticalDivider(width: 1, color: Color(0xFFEDF2F7)),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          color: const Color(0xFFF8FAFC),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildVideoSegmentHeader(),
                                const SizedBox(height: 16),
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(flex: 3, child: _buildBlackVideoPlayer()),
                                      const SizedBox(width: 20),
                                      SizedBox(width: 300, child: _buildAIAnalysisCard()),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildTranscriptCard(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _buildBottomStatusBar(),
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

  /* -------------------------------------------------------------------------- */
  /*                                    HEADER                                  */
  /* -------------------------------------------------------------------------- */

  Widget _buildMaterialsHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white,
      child: Row(
        children: [
          Row(
            children: [
              const Text(
                "Materials Explorer",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  "v2.4",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Optional: show course slug small (debug / breadcrumb-like)
              Text(
                widget.courseSlug,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 320,
            child: _Search40(
              controller: _materialsSearchController,
              hint: "Search topics, subtitles...",
              onChanged: (_) {},
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _showUploadDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Add Material"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                   HIERARCHY                                */
  /* -------------------------------------------------------------------------- */

  /// Long titles should not wrap ("مكبوس").
  /// Instead, keep them on one line and allow horizontal scrolling.
  Widget _scrollableTitle(
    String title,
    TextStyle style, {
    bool expand = true,
  }) {
    final cleaned = title.replaceAll('\n', ' ');
    final textWidget = ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: false),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Text(cleaned, style: style, softWrap: false),
      ),
    );

    return expand ? Expanded(child: textWidget) : textWidget;
  }

  Widget _buildHierarchyPanel() {
    return Container(
      width: 582,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 24,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 51,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0x80F8FAFC),
            child: Row(
              children: [
                const Text(
                  "HIERARCHY",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                Icon(Icons.unfold_more_rounded, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 10),
                Icon(Icons.swap_vert_rounded, size: 18, color: Colors.grey[600]),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _treeGroup(
                  title: "Introduction to Data Structures",
                  icon: Icons.folder_open_rounded,
                  children: [
                    _treeGroup(
                      title: "Lecture 3: Binary Trees",
                      icon: Icons.folder_open_rounded,
                      indent: 1,
                      children: [
                        _treeLeaf("Definition & Terminology", indent: 2, isSelected: false),
                        _treeGroup(
                          title: "Properties of Binary Trees",
                          icon: Icons.folder_open_rounded,
                          indent: 2,
                          children: [
                            _segmentLeaf(
                              "02:15",
                              "The maximum number of nodes at level l of a binary tree is...",
                              indent: 3,
                            ),
                            _segmentLeaf(
                              "04:12",
                              "The maximum depth of a binary tree is the number of nodes\nalong the longest path...",
                              indent: 3,
                              isSelected: true,
                            ),
                            _segmentLeaf(
                              "06:30",
                              "Recursive definition for calculating height...",
                              indent: 3,
                            ),
                          ],
                        ),
                      ],
                    ),
                    _treeLeaf("Assignment 1: Tree Traversal", indent: 1, isSelected: false),
                  ],
                ),
                const SizedBox(height: 12),
                _createNewTopicButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _createNewTopicButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(4, 8, 4, 16),
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
        label: const Text("Create New Topic"),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF334155),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          backgroundColor: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _treeGroup({
    required String title,
    required IconData icon,
    required List<Widget> children,
    int indent = 0,
  }) {
    final left = 8.0 + (indent * 18);
    return Padding(
      padding: EdgeInsets.only(left: left, right: 8, top: 6, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.expand_more_rounded, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Icon(icon, size: 18, color: const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              _scrollableTitle(
                title,
                const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Widget _treeLeaf(String title, {required int indent, required bool isSelected}) {
    final left = 36.0 + (indent * 18);
    return Container(
      margin: EdgeInsets.only(left: left, right: 8, top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected ? Border.all(color: const Color(0xFFBFDBFE)) : null,
      ),
      child: Row(
        children: [
          Icon(Icons.article_outlined, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          _scrollableTitle(
            title,
            TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentLeaf(
    String time,
    String title, {
    required int indent,
    bool isSelected = false,
  }) {
    final left = 36.0 + (indent * 18);
    return Container(
      margin: EdgeInsets.only(left: left, right: 8, top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected ? Border.all(color: const Color(0xFFBFDBFE)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxVersus(isSelected),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _scrollableTitle(
            title,
            TextStyle(
              fontSize: 12,
              height: 1.25,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF334155),
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                              MAIN CONTENT (RIGHT)                          */
  /* -------------------------------------------------------------------------- */

  Widget _buildVideoSegmentHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _pill("VIDEO SEGMENT", const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
                  const SizedBox(width: 8),
                  _pill("REVIEW NEEDED", const Color(0xFFFFF7ED), const Color(0xFFEA580C)),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                "Maximum Depth Calculation",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              const Text(
                'From "Properties of Binary Trees" • 04:12 - 06:29',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: "Edit",
          onPressed: () {},
          icon: const Icon(Icons.edit_outlined, color: Color(0xFF64748B)),
        ),
        IconButton(
          tooltip: "Delete",
          onPressed: () {},
          icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
        ),
      ],
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.2),
      ),
    );
  }

  Widget _buildBlackVideoPlayer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 340,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1220),
              Color(0xFF0A1B3D),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.25,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Text(
                    '''
int maxDepth(Node? root) {
  if (root == null) return 0;

  final left = maxDepth(root.left);
  final right = maxDepth(root.right);

  return 1 + (left > right ? left : right);
}
''',
                    style: const TextStyle(
                      fontFamily: "monospace",
                      fontSize: 12,
                      height: 1.6,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            Center(
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Icon(Icons.play_arrow_rounded, size: 44, color: Colors.white),
              ),
            ),

            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: 0.68,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("04:12", style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.75))),
                      Text("06:29", style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.75))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("AI Analysis", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),

          const Text("Content Quality Score", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: const LinearProgressIndicator(
                    value: 0.92,
                    minHeight: 8,
                    backgroundColor: Color(0xFFF1F5F9),
                    color: Color(0xFF22C55E),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text("92/100", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ],
          ),

          const SizedBox(height: 14),
          const Text("Suggested Tags", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tag("#binary-tree"),
              _tag("#algorithms"),
              _tag("#recursion"),
              _tag("+"),
            ],
          ),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Regenerate Analysis"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTranscriptCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Transcript & Content", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              _toolIcon(Icons.format_bold_rounded),
              _toolIcon(Icons.format_italic_rounded),
              _toolIcon(Icons.format_list_bulleted_rounded),
              _toolIcon(Icons.format_quote_rounded),
              const Spacer(),
              _toolIcon(Icons.tune_rounded),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            "The maximum depth of a binary tree is the number of nodes along the longest path from the root node down to the farthest leaf node.",
            style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 12),
          const Text(
            "In this section, we will explore a recursive approach to solve this. The algorithm is straightforward: if the tree is empty, the depth is 0. Otherwise, we calculate the depth of the left subtree and the right subtree, take the maximum of the two, and add 1 for the current node.",
            style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Text(
                "Suggestion: Simplify sentence structure?",
                style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                  BOTTOM BAR                                */
  /* -------------------------------------------------------------------------- */

  Widget _buildBottomStatusBar() {
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
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          ElevatedButton(
            onPressed: _openGenerateQuestionFlow,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0655FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text("Generate Question", style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            SMALL LOCAL SEARCH WIDGET                        */
/* -------------------------------------------------------------------------- */

class _Search40 extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _Search40({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: "Manrope",
          fontSize: 14,
          height: 19 / 14,
          color: Color(0xFF374151),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: "Manrope",
            fontSize: 14,
            height: 19 / 14,
            color: Color(0xFF9CA3AF),
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF9CA3AF)),
          contentPadding: const EdgeInsets.only(top: 10, bottom: 11),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFBFDBFE), width: 1.2),
          ),
        ),
      ),
    );
  }
}

/// Small helper to keep segment time box decoration clean.
class BoxVersus extends BoxDecoration {
  BoxVersus(bool isSelected)
      : super(
          color: isSelected ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        );
}
