import 'package:flutter/material.dart';
import 'upload_materials_dialog.dart';
import 'package:learnova/features/instructor/presentation/widgets/create_exam_content.dart';
import 'package:go_router/go_router.dart';
import 'package:learnova/core/routing/routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MaterialsExplorerPage — pixel-perfect match to HTML prototype
// ─────────────────────────────────────────────────────────────────────────────

class MaterialsExplorerPage extends StatefulWidget {
  final String courseSlug;
  const MaterialsExplorerPage({super.key, required this.courseSlug});
  @override
  State<MaterialsExplorerPage> createState() => _MaterialsExplorerPageState();
}

// ── Design tokens (مطابق للبروتوتايب) ────────────────────────────────────────
class _K {
  static const pageBg   = Color(0xFFF6F7F8);
  static const white    = Colors.white;
  static const border   = Color(0xFFE5E7EB);
  static const divider  = Color(0xFFF0F2F4);
  static const text     = Color(0xFF111418);
  static const muted    = Color(0xFF617589);
  static const hint     = Color(0xFF94A3B8);
  static const blue     = Color(0xFF137FEC);
  static const blueHov  = Color(0xFF0E6FD4);
  static const blueSoft = Color(0xFFEFF6FF);
  static const green    = Color(0xFF16A34A);
  static const greenBg  = Color(0xFFBBF7D0);
  static const orange   = Color(0xFFF59E0B);
  static const red      = Color(0xFFEF4444);

  // badge colors
  static const badgeVideoBg = Color(0xFFDBEAFE);
  static const badgeVideoFg = Color(0xFF1D4ED8);
  static const badgeRevBg   = Color(0xFFFEF3C7);
  static const badgeRevFg   = Color(0xFFD97706);

  static const shadow = BoxShadow(color: Color(0x0A000000), blurRadius: 18, offset: Offset(0, 8));
}

// ── Node models ───────────────────────────────────────────────────────────────
enum _NodeType   { folder, material }
enum _MatKind    { video, pdf }
enum _Confidence { high, medium, low, none }

class _Node {
  final String id;
  final _NodeType type;
  String title;
  bool isExpanded;
  final List<_Node> children;
  final _MatKind? kind;
  final String? rangeLabel;   // "04:12 – 06:29"
  final String? fromLabel;    // "From \"Properties…\""
  int qualityScore;           // 0-100
  List<String> tags;
  String transcript1;
  String transcript2;
  _Confidence confidence;

  _Node.folder({
    required this.id, required this.title, this.isExpanded = true, List<_Node>? children,
  }) : type = _NodeType.folder, children = children ?? [], kind = null,
       rangeLabel = null, fromLabel = null, qualityScore = 0,
       tags = const [], transcript1 = '', transcript2 = '', confidence = _Confidence.none;

  _Node.material({
    required this.id, required this.title, required this.kind,
    this.rangeLabel, this.fromLabel, this.qualityScore = 92,
    this.tags = const ['#binary-tree','#algorithms','#recursion'],
    this.transcript1 = '', this.transcript2 = '', this.confidence = _Confidence.high,
  }) : type = _NodeType.material, children = const [], isExpanded = false;
}

enum _NodeMenuAction { newFolder, addMaterial, rename, delete }

// ── State ─────────────────────────────────────────────────────────────────────
class _MaterialsExplorerPageState extends State<MaterialsExplorerPage> {
  final _searchCtrl = TextEditingController();
  final _treScroll  = ScrollController();
  int _examStep = 1;
  late List<_Node> _roots;
  _Node? _selected;
  DateTime _lastSaved = DateTime.now().subtract(const Duration(minutes: 2));
  int _uid = 0;

  @override
  void initState() {
    super.initState();
    _roots = _buildDemo();
    // pre-select the "active" material matching the prototype screenshot
    _selected = _find(_roots, 'active_node');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _treScroll.dispose();
    super.dispose();
  }

  String _nid() => '${DateTime.now().microsecondsSinceEpoch}_${_uid++}';

  _Node? _find(List<_Node> nodes, String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
      final r = _find(n.children, id);
      if (r != null) return r;
    }
    return null;
  }

  List<_Node> _buildDemo() => [
    _Node.folder(id: _nid(), title: 'Introduction to Data Structures', isExpanded: true, children: [
      _Node.folder(id: _nid(), title: 'Lecture 3: Binary Trees', isExpanded: true, children: [
        _Node.folder(id: _nid(), title: 'Definition & Terminology', isExpanded: false, children: [
          _Node.material(
            id: _nid(), title: 'Terminology basics (PDF)', kind: _MatKind.pdf,
            fromLabel: 'From "Definition & Terminology"', qualityScore: 85,
            tags: const ['#binary-tree','#basics'],
            transcript1: 'This PDF covers core terminology used in binary trees.',
            transcript2: 'Backend will extract text and create highlights automatically.',
            confidence: _Confidence.medium,
          ),
        ]),
        _Node.folder(id: _nid(), title: 'Properties of Binary Trees', isExpanded: true, children: [
          _Node.material(
            id: _nid(),
            title: "The maximum number of nodes at level 'l' of a binary tree is…",
            kind: _MatKind.video, fromLabel: 'From "Properties of Binary Trees"',
            rangeLabel: '02:15 – 04:12', qualityScore: 88,
            tags: const ['#binary-tree','#properties'],
            transcript1: "The maximum number of nodes at level l of a binary tree is 2^l.",
            transcript2: "We explain the rule and show quick examples.",
            confidence: _Confidence.high,
          ),
          _Node.material(
            id: 'active_node',
            title: 'The maximum depth of a binary tree is the number of nodes along the longest path...',
            kind: _MatKind.video, fromLabel: 'From "Properties of Binary Trees"',
            rangeLabel: '04:12 – 06:29', qualityScore: 92,
            tags: const ['#binary-tree','#algorithms','#recursion'],
            transcript1: 'The maximum depth of a binary tree is the number of nodes along the longest path from the root node down to the farthest leaf node.',
            transcript2: 'In this section, we will explore a recursive approach to solve this. The algorithm is straightforward: if the tree is empty, the depth is 0. Otherwise, we calculate the depth of the left subtree and the right subtree, take the maximum of the two, and add 1 for the current node.',
            confidence: _Confidence.medium,
          ),
          _Node.material(
            id: _nid(), title: 'Recursive definition for calculating height…',
            kind: _MatKind.video, fromLabel: 'From "Properties of Binary Trees"',
            rangeLabel: '06:30 – 08:10', qualityScore: 90,
            tags: const ['#recursion','#height'],
            transcript1: 'Height is defined recursively: height(null)=0',
            transcript2: 'height(node)=1+max(height(left), height(right)).',
            confidence: _Confidence.none,
          ),
        ]),
      ]),
      _Node.folder(id: _nid(), title: 'Assignment 1: Tree Traversal', isExpanded: false, children: [
        _Node.material(
          id: _nid(), title: 'Assignment sheet (PDF)', kind: _MatKind.pdf,
          fromLabel: 'From "Assignments"', qualityScore: 80,
          tags: const ['#traversal','#assignment'],
          transcript1: 'Solve traversal problems: inorder, preorder, postorder.',
          transcript2: 'Submit your answers by the deadline.',
          confidence: _Confidence.none,
        ),
      ]),
    ]),
  ];

  // ── CRUD ──────────────────────────────────────────────────────────────────
  Future<void> _createFolder({_Node? parent}) async {
    final name = await _promptText('Create folder', 'Folder name', '', 'Create');
    if (name == null) return;
    setState(() {
      final n = _Node.folder(id: _nid(), title: name);
      (parent == null ? _roots : parent.children).add(n);
      if (parent != null) parent.isExpanded = true;
      _selected = n;
    });
  }

  Future<void> _renameNode(_Node node) async {
    final name = await _promptText('Rename', 'New name', node.title, 'Save');
    if (name == null) return;
    setState(() => node.title = name);
  }

  Future<void> _deleteNode(_Node node) async {
    final ok = await _confirm('Delete "${node.title}"?', 'Delete', danger: true);
    if (!ok) return;
    setState(() {
      _removeFromTree(node);
      if (_selected?.id == node.id) _selected = null;
    });
  }

  void _removeFromTree(_Node t) {
    void rm(List<_Node> list) {
      list.removeWhere((n) => n.id == t.id);
      for (final n in list) rm(n.children);
    }
    rm(_roots);
  }

  Future<void> _addMaterialToFolder(_Node folder) async {
    final title = await _promptText('Add material', 'Material title', '', 'Add');
    if (title == null) return;
    setState(() {
      folder.children.add(_Node.material(
        id: _nid(), title: title, kind: _MatKind.video,
        fromLabel: 'From "${folder.title}"', confidence: _Confidence.none,
      ));
      folder.isExpanded = true;
      _lastSaved = DateTime.now();
    });
  }

  void _setAllExpanded(bool v) {
    void walk(List<_Node> nodes) {
      for (final n in nodes) {
        if (n.type == _NodeType.folder) { n.isExpanded = v; walk(n.children); }
      }
    }
    setState(() => walk(_roots));
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showUpload() => showDialog(context: context, barrierDismissible: true, builder: (_) => const UploadMaterialsDialog());

  void _openExam() {
    _examStep = 1;
    showGeneralDialog(
      context: context, barrierDismissible: true, barrierLabel: '',
      pageBuilder: (_, __, ___) => Material(color: Colors.white, child: SafeArea(
        child: StatefulBuilder(builder: (ctx, ss) => CreateExamContent(
          currentStep: _examStep,
          onBack: () { if (_examStep > 1) ss(() => _examStep--); else Navigator.pop(ctx); },
          onNext: () { if (_examStep < 3) ss(() => _examStep++); else Navigator.pop(ctx); },
        )),
      )),
    );
  }

  void _handleNodeAction(_Node node, _NodeMenuAction action) async {
    switch (action) {
      case _NodeMenuAction.newFolder:   if (node.type == _NodeType.folder) await _createFolder(parent: node);  break;
      case _NodeMenuAction.addMaterial: if (node.type == _NodeType.folder) await _addMaterialToFolder(node);   break;
      case _NodeMenuAction.rename:      await _renameNode(node);   break;
      case _NodeMenuAction.delete:      await _deleteNode(node);   break;
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildHeader(),
      Expanded(child: Row(children: [
        _buildTreeSidebar(),
        Container(width: 1, color: _K.border),
        Expanded(child: _buildRightArea()),
      ])),
      _buildBottomBar(),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  HEADER — h:56, matching prototype exactly
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: _K.white,
        border: Border(bottom: BorderSide(color: _K.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        // Back button — secondary style
        _SecondaryBtn(
          label: 'Back',
          icon: Icons.chevron_left_rounded,
          onTap: () => context.go(Routes.instructorCourses),
          small: true,
        ),
        const SizedBox(width: 12),
        const Text('Materials Explorer',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _K.text)),
        const SizedBox(width: 10),
        // Version badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _K.pageBg,
            border: Border.all(color: _K.border),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text('v2.4',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _K.muted)),
        ),
        const SizedBox(width: 16),
        // Search — max-width 300, height 34
        SizedBox(width: 300, child: _ExplorerSearch(controller: _searchCtrl)),
        const Spacer(),
        // Add Material button
        _PrimaryBtn(label: 'Add Material', icon: Icons.add, onTap: _showUpload),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TREE SIDEBAR — w:300, white bg
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTreeSidebar() {
    return SizedBox(
      width: 300,
      child: Container(
        color: _K.white,
        child: Column(children: [
          // Toolbar — "HIERARCHY" + 3 icon buttons
          Container(
            height: 44,
            padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _K.border))),
            child: Row(children: [
              const Text('HIERARCHY',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _K.hint, letterSpacing: 0.5)),
              const Spacer(),
              _TbIconBtn(icon: Icons.close_rounded,            tooltip: 'Collapse all', onTap: () => _setAllExpanded(false)),
              _TbIconBtn(icon: Icons.unfold_more_rounded,      tooltip: 'Expand all',   onTap: () => _setAllExpanded(true)),
              _TbIconBtn(icon: Icons.menu_rounded,             tooltip: 'Filter',       onTap: () {}),
            ]),
          ),
          // Tree list
          Expanded(child: _roots.isEmpty ? _emptyTree() : _buildTreeList()),
          // Create New Topic button at the bottom of sidebar
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: _K.border))),
            child: _PrimaryBtn(label: 'Create New Topic', icon: Icons.add, onTap: () => _createFolder(), fullWidth: true),
          ),
        ]),
      ),
    );
  }

  Widget _emptyTree() => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.folder_open_rounded, size: 32, color: _K.blue),
        const SizedBox(height: 10),
        const Text('No folders yet',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _K.text), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        const Text('Create your first folder then add materials inside it.',
          style: TextStyle(fontSize: 12.5, color: _K.muted, height: 1.4), textAlign: TextAlign.center),
        const SizedBox(height: 14),
        _PrimaryBtn(label: 'Create folder', icon: Icons.create_new_folder_outlined, onTap: () => _createFolder(), fullWidth: true),
      ]),
    ),
  );

  Widget _buildTreeList() => ListView(
    controller: _treScroll,
    padding: const EdgeInsets.only(top: 8, bottom: 8),
    children: _roots.map((n) => _TreeNode(
      node: n, indent: 0,
      selectedId: _selected?.id,
      onTap: (n) => setState(() {
        if (n.type == _NodeType.folder) n.isExpanded = !n.isExpanded;
        _selected = n;
      }),
      onAction: _handleNodeAction,
    )).toList(),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  //  RIGHT AREA — folder state or material detail+analysis
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRightArea() {
    final sel = _selected;
    if (sel == null)                     return _buildEmptyState();
    if (sel.type == _NodeType.folder)    return _buildFolderState(sel);
    return _buildMaterialArea(sel);
  }

  Widget _buildEmptyState() => Container(
    color: _K.pageBg,
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.touch_app_rounded, size: 32, color: _K.blue),
      const SizedBox(height: 10),
      const Text('Select a folder or material',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _K.text)),
      const SizedBox(height: 6),
      const Text('Use the hierarchy panel on the left.',
        style: TextStyle(fontSize: 13, color: _K.muted)),
      const SizedBox(height: 14),
      _SecondaryBtn(label: 'Upload materials', icon: Icons.upload_rounded, onTap: _showUpload),
    ])),
  );

  Widget _buildFolderState(_Node folder) => Container(
    color: _K.pageBg,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Badges
        Row(children: [
          _Badge('FOLDER', _K.blueSoft, _K.blue),
          const SizedBox(width: 8),
          _Badge('READY', const Color(0xFFF0FDF4), _K.green),
        ]),
        const SizedBox(height: 10),
        // Title + actions
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(folder.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _K.text)),
            Text('Items inside: ${folder.children.length}',
              style: const TextStyle(fontSize: 12.5, color: _K.muted)),
          ])),
          _SmIconBtn(icon: Icons.edit_outlined,    tooltip: 'Edit',   onTap: () => _renameNode(folder)),
          _SmIconBtn(icon: Icons.delete_outline,   tooltip: 'Delete', onTap: () => _deleteNode(folder), color: _K.red),
        ]),
        const SizedBox(height: 16),
        // Two action cards
        Row(children: [
          Expanded(child: _SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Folder actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _K.text)),
            const SizedBox(height: 8),
            const Text('Upload materials inside this folder, then generate quizzes.',
              style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF334155))),
            const SizedBox(height: 14),
            Row(children: [
              _PrimaryBtn(label: 'Add material', icon: Icons.add, onTap: () => _addMaterialToFolder(folder)),
              const SizedBox(width: 8),
              _SecondaryBtn(label: 'Generate quiz', icon: Icons.auto_awesome, onTap: _openExam),
            ]),
          ]))),
          const SizedBox(width: 14),
          Expanded(child: _SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Quick tips', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _K.text)),
            const SizedBox(height: 8),
            const Text('Best practice: build folders as Topic → Subtopic then attach materials.',
              style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF334155))),
            const SizedBox(height: 14),
            Row(children: [
              _PrimaryBtn(label: 'New subfolder', icon: Icons.create_new_folder, onTap: () => _createFolder(parent: folder)),
              const SizedBox(width: 8),
              _SecondaryBtn(label: 'Rename', icon: Icons.edit, onTap: () => _renameNode(folder)),
            ]),
          ]))),
        ]),
        const SizedBox(height: 14),
        // Contents list
        _SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Folder contents', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _K.text)),
          const SizedBox(height: 10),
          if (folder.children.isEmpty)
            const Text('No materials yet. Add your first material from the button above.',
              style: TextStyle(color: _K.muted, fontSize: 13))
          else
            ...folder.children.map((c) => ListTile(
              contentPadding: EdgeInsets.zero, dense: true,
              leading: Icon(c.type == _NodeType.material ? Icons.article_outlined : Icons.folder_outlined, color: _K.muted, size: 18),
              title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _K.text)),
              trailing: const Icon(Icons.chevron_right_rounded, color: _K.hint),
              onTap: () => setState(() => _selected = c),
            )),
        ])),
      ]),
    ),
  );

  // ── Material detail + analysis (side by side, 1fr + 240px) ────────────────
  Widget _buildMaterialArea(_Node mat) {
    return Row(children: [
      // Detail panel (scrollable)
      Expanded(child: Container(
        color: const Color(0xFFF8FAFC),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 18, 80),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildDetailHeader(mat),
            const SizedBox(height: 16),
            _buildVideoPlayer(mat),
            const SizedBox(height: 14),
            _buildTranscriptCard(mat),
          ]),
        ),
      )),
      // Analysis panel — 240px, border-left, background #FAFBFC
      Container(
        width: 240,
        decoration: const BoxDecoration(
          color: Color(0xFFFAFBFC),
          border: Border(left: BorderSide(color: _K.border)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: _buildAnalysisPanel(mat),
        ),
      ),
    ]);
  }

  // Badge row + title row + meta — matching prototype
  Widget _buildDetailHeader(_Node mat) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    // Badge row
    Row(children: [
      _Badge(mat.kind == _MatKind.video ? 'VIDEO SEGMENT' : 'MATERIAL', _K.badgeVideoBg, _K.badgeVideoFg),
      if (mat.confidence == _Confidence.low) ...[
        const SizedBox(width: 8),
        _Badge('⚠ REVIEW NEEDED', _K.badgeRevBg, _K.badgeRevFg),
      ],
    ]),
    const SizedBox(height: 8),
    // Title row with edit/delete icons
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Text(mat.title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _K.text))),
      const SizedBox(width: 8),
      _SmIconBtn(icon: Icons.edit_outlined,  tooltip: 'Edit',   onTap: () => _renameNode(mat)),
      _SmIconBtn(icon: Icons.delete_outline, tooltip: 'Delete', onTap: () => _deleteNode(mat), color: _K.red),
    ]),
    // Meta
    const SizedBox(height: 4),
    if (mat.fromLabel != null)
      Text('${mat.fromLabel} • ${mat.rangeLabel ?? ''}',
        style: const TextStyle(fontSize: 12, color: _K.muted, fontWeight: FontWeight.w600)),
  ]);

  // Video placeholder — background #0f172a → #0A1B3D gradient, 16:9 aspect ratio
  Widget _buildVideoPlayer(_Node mat) {
    final startTime = mat.rangeLabel?.split('–').first.trim() ?? '00:00';
    final endTime   = mat.rangeLabel?.split('–').last.trim()  ?? '00:00';
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF0A1B3D)]),
          ),
          child: Stack(children: [
            // Play button — white transparent circle
            Center(child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Icon(Icons.play_arrow_rounded, size: 26, color: Colors.white)),
            )),
            // Progress bar at very bottom (3px)
            Positioned(bottom: 0, left: 0, right: 0, child: Container(
              height: 3,
              color: Colors.white.withValues(alpha: 0.20),
              child: Align(alignment: Alignment.centerLeft, child: FractionallySizedBox(
                widthFactor: 0.35,
                child: Container(color: _K.blue),
              )),
            )),
            // Timestamps above progress bar
            Positioned(bottom: 10, left: 10, right: 10, child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(startTime, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.8))),
                Text(endTime,   style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.8))),
              ],
            )),
          ]),
        ),
      ),
    );
  }

  // Transcript card — white bg, border, 12px radius
  Widget _buildTranscriptCard(_Node mat) => Container(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
    decoration: BoxDecoration(
      color: _K.white,
      border: Border.all(color: _K.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header with title + toolbar buttons
      Row(children: [
        const Icon(Icons.article_outlined, size: 15, color: _K.blue),
        const SizedBox(width: 7),
        const Expanded(child: Text('Transcript & Content',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _K.text))),
        // toolbar buttons: B I S↗
        _TxBtn(label: 'B', bold: true),
        const SizedBox(width: 4),
        _TxBtn(label: 'I', italic: true),
        const SizedBox(width: 4),
        _TxBtn(label: 'S̶'),
        const SizedBox(width: 4),
        _TxBtn(label: '↗'),
      ]),
      // Divider
      Container(margin: const EdgeInsets.symmetric(vertical: 10), height: 1, color: _K.divider),
      // Transcript text
      Text(mat.transcript1.isNotEmpty ? mat.transcript1 : 'Transcript will appear here.',
        style: const TextStyle(fontSize: 13, height: 1.65, color: Color(0xFF1E293B))),
      if (mat.transcript2.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(mat.transcript2, style: const TextStyle(fontSize: 13, height: 1.65, color: Color(0xFF1E293B))),
      ],
      // Suggestion row
      const SizedBox(height: 10),
      Row(children: const [
        Icon(Icons.auto_fix_high_rounded, size: 13, color: _K.blue),
        SizedBox(width: 6),
        Text('Suggestion: Simplify sentence structure?',
          style: TextStyle(fontSize: 11.5, color: _K.blue, fontWeight: FontWeight.w700)),
      ]),
    ]),
  );

  // Analysis panel — matching prototype exactly (240px wide)
  Widget _buildAnalysisPanel(_Node mat) {
    final score = mat.qualityScore.clamp(0, 100);
    final val   = score / 100.0;
    final isHigh = val >= 0.8;
    final scoreColor = isHigh ? _K.green : _K.orange;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // "AI Analysis" header
      Row(children: [
        const Icon(Icons.auto_awesome_rounded, size: 15, color: _K.blue),
        const SizedBox(width: 7),
        const Text('AI Analysis', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _K.text)),
      ]),
      const SizedBox(height: 14),

      // Content Quality Score
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Content Quality Score',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _K.muted)),
        Text('$score/100',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: scoreColor)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: val, minHeight: 6,
          backgroundColor: _K.pageBg,
          color: scoreColor,
        ),
      ),
      const SizedBox(height: 14),

      // Suggested Tags
      const Text('Suggested Tags', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _K.muted)),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: [
        ...mat.tags.map((t) => _TagChip(t)),
        _TagChip('+', dashed: true),
      ]),
      const SizedBox(height: 16),

      // Regenerate Analysis button — btn-ghost style
      SizedBox(width: double.infinity, child: _GhostBtn(
        label: 'Regenerate Analysis',
        icon: Icons.refresh_rounded,
        onTap: () => setState(() => mat.qualityScore = 80 + DateTime.now().second % 21),
      )),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BOTTOM BAR — matching prototype (position at very bottom of page)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBottomBar() {
    final diff = DateTime.now().difference(_lastSaved);
    final text = diff.inSeconds < 60 ? 'Last auto-saved just now'
               : diff.inMinutes < 60 ? 'Last auto-saved ${diff.inMinutes} mins ago'
               : 'Last auto-saved ${diff.inHours}h ago';
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: _K.white,
        border: Border(top: BorderSide(color: _K.border)),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle_outline_rounded, size: 14, color: _K.green),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: _K.muted, fontWeight: FontWeight.w600)),
        const Spacer(),
        // Generate Question button
        _GenerateBtn(label: 'Generate Question', icon: Icons.auto_awesome_rounded,
          onTap: _selected != null ? _openExam : null),
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Future<String?> _promptText(String title, String hint, String init, String action) =>
    showDialog<String>(context: context, barrierDismissible: true, builder: (_) {
      final c = TextEditingController(text: init);
      return AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(controller: c, autofocus: true,
          decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { final t = c.text.trim(); if (t.isNotEmpty) Navigator.pop(context, t); }, child: Text(action)),
        ],
      );
    });

  Future<bool> _confirm(String body, String action, {bool danger = false}) async {
    final r = await showDialog<bool>(context: context, barrierDismissible: true, builder: (_) => AlertDialog(
      title: Text(body, style: const TextStyle(fontWeight: FontWeight.w900)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: danger ? _K.red : null),
          onPressed: () => Navigator.pop(context, true), child: Text(action)),
      ],
    ));
    return r ?? false;
  }
}

// =============================================================================
//  TREE NODE WIDGETS (recursive)
// =============================================================================
class _TreeNode extends StatelessWidget {
  final _Node node;
  final int indent;
  final String? selectedId;
  final ValueChanged<_Node> onTap;
  final Function(_Node, _NodeMenuAction) onAction;

  const _TreeNode({required this.node, required this.indent, required this.selectedId, required this.onTap, required this.onAction});

  @override
  Widget build(BuildContext context) => node.type == _NodeType.folder
    ? _FolderItem(node: node, indent: indent, selectedId: selectedId, onTap: onTap, onAction: onAction)
    : _MaterialItem(node: node, indent: indent, selectedId: selectedId, onTap: onTap, onAction: onAction);
}

// ── Folder row ────────────────────────────────────────────────────────────────
class _FolderItem extends StatelessWidget {
  final _Node node;
  final int indent;
  final String? selectedId;
  final ValueChanged<_Node> onTap;
  final Function(_Node, _NodeMenuAction) onAction;

  const _FolderItem({required this.node, required this.indent, required this.selectedId, required this.onTap, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedId == node.id;
    // Indent: 14px base + 14px per level (matches prototype tree-indent1=26, tree-indent2=44)
    final leftPad = 14.0 + indent * 16.0;

    // Icon color by level — matching prototype
    Color folderColor;
    IconData folderIcon;
    if (indent == 0)      { folderIcon = Icons.folder_rounded;       folderColor = _K.orange; }
    else if (indent == 1) { folderIcon = Icons.video_library_rounded; folderColor = _K.red;    }
    else                  { folderIcon = Icons.folder_outlined;       folderColor = _K.blue;   }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      MouseRegion(cursor: SystemMouseCursors.click, child: InkWell(
        onTap: () => onTap(node),
        child: Container(
          padding: EdgeInsets.fromLTRB(leftPad, 7, 8, 7),
          color: isSelected ? _K.blueSoft : Colors.transparent,
          child: Row(children: [
            // chevron
            Icon(node.isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
              size: 14, color: _K.muted),
            const SizedBox(width: 5),
            // folder icon
            Icon(folderIcon, size: 15, color: folderColor),
            const SizedBox(width: 7),
            // label
            Expanded(child: Text(node.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: isSelected ? _K.blue : _K.text))),
            // 3-dots menu (only on indent==1 like prototype)
            if (indent == 1)
              _NodeMenuBtn(node: node, onAction: onAction),
          ]),
        ),
      )),
      // Children
      if (node.isExpanded)
        ...node.children.map((c) => _TreeNode(
          node: c, indent: indent + 1, selectedId: selectedId, onTap: onTap, onAction: onAction)),
    ]);
  }
}

// ── Material row — matching prototype tree-item tree-indent3 style ────────────
class _MaterialItem extends StatelessWidget {
  final _Node node;
  final int indent;
  final String? selectedId;
  final ValueChanged<_Node> onTap;
  final Function(_Node, _NodeMenuAction) onAction;

  const _MaterialItem({required this.node, required this.indent, required this.selectedId, required this.onTap, required this.onAction});

  Color _dotColor() {
    switch (node.confidence) {
      case _Confidence.high:   return _K.green;
      case _Confidence.medium: return _K.orange;
      case _Confidence.low:    return _K.red;
      case _Confidence.none:   return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedId == node.id;
    final leftPad = 14.0 + indent * 16.0;
    // time = first part of range e.g. "04:12"
    final timeStr = node.rangeLabel?.split('–').first.trim() ?? '';
    final hasTime = timeStr.isNotEmpty;
    final hasDot  = node.confidence != _Confidence.none;
    final hasConf = isSelected && node.qualityScore > 0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => onTap(node),
        child: Container(
          // active-item style: margin 2px 6px, blue bg, radius 8
          margin: isSelected
            ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
            : EdgeInsets.zero,
          padding: EdgeInsets.fromLTRB(isSelected ? leftPad - 6 : leftPad, 7, 8, 7),
          decoration: BoxDecoration(
            color: isSelected ? _K.blueSoft : Colors.transparent,
            borderRadius: isSelected ? BorderRadius.circular(8) : null,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // time badge (plain text in prototype, no box)
              if (hasTime)
                Text(timeStr, style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: isSelected ? _K.blue : _K.hint)),
              SizedBox(width: hasTime ? 8 : 0),
              // label
              Expanded(child: Text(node.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? _K.blue : const Color(0xFF334155),
                  height: 1.35,
                ))),
              // dot
              if (hasDot)
                Container(width: 7, height: 7, margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(color: _dotColor(), shape: BoxShape.circle)),
              _NodeMenuBtn(node: node, onAction: onAction),
            ]),
            // Confidence bar — shown BELOW active item, padding-left 60px matching prototype
            if (hasConf) ...[
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(left: 46),
                child: Row(children: [
                  SizedBox(
                    width: 80,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: node.qualityScore / 100.0, minHeight: 3,
                        backgroundColor: _K.greenBg,
                        color: _K.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('${node.qualityScore}% Confidence',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _K.green)),
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

// ── Context menu ──────────────────────────────────────────────────────────────
class _NodeMenuBtn extends StatelessWidget {
  final _Node node;
  final Function(_Node, _NodeMenuAction) onAction;
  const _NodeMenuBtn({required this.node, required this.onAction});

  @override
  Widget build(BuildContext context) => PopupMenuButton<_NodeMenuAction>(
    tooltip: 'Actions',
    icon: const Icon(Icons.more_horiz_rounded, size: 14, color: _K.hint),
    padding: EdgeInsets.zero, iconSize: 14,
    onSelected: (a) => onAction(node, a),
    itemBuilder: (_) => [
      if (node.type == _NodeType.folder) ...[
        const PopupMenuItem(value: _NodeMenuAction.newFolder,
          child: Row(children: [Icon(Icons.create_new_folder_outlined, size: 15), SizedBox(width: 8), Text('New folder')])),
        const PopupMenuItem(value: _NodeMenuAction.addMaterial,
          child: Row(children: [Icon(Icons.add_to_photos_outlined, size: 15), SizedBox(width: 8), Text('Add material')])),
        const PopupMenuDivider(),
      ],
      const PopupMenuItem(value: _NodeMenuAction.rename,
        child: Row(children: [Icon(Icons.drive_file_rename_outline, size: 15), SizedBox(width: 8), Text('Rename')])),
      PopupMenuItem(value: _NodeMenuAction.delete,
        child: Row(children: [Icon(Icons.delete_outline, size: 15, color: _K.red), const SizedBox(width: 8),
          Text('Delete', style: TextStyle(color: _K.red))])),
    ],
  );
}

// =============================================================================
//  SHARED MICRO-WIDGETS — all matching prototype exactly
// =============================================================================

// Primary button — bg:blue, white text
class _PrimaryBtn extends StatefulWidget {
  final String label; final IconData icon; final VoidCallback onTap; final bool fullWidth;
  const _PrimaryBtn({required this.label, required this.icon, required this.onTap, this.fullWidth = false});
  @override State<_PrimaryBtn> createState() => _PrimaryBtnState();
}
class _PrimaryBtnState extends State<_PrimaryBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _h = true),
    onExit:  (_) => setState(() => _h = false),
    child: GestureDetector(onTap: widget.onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: widget.fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _h ? _K.blueHov : _K.blue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: widget.fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(widget.icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(widget.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
    )),
  );
}

// Secondary button — white bg, border
class _SecondaryBtn extends StatefulWidget {
  final String label; final IconData icon; final VoidCallback onTap; final bool small;
  const _SecondaryBtn({required this.label, required this.icon, required this.onTap, this.small = false});
  @override State<_SecondaryBtn> createState() => _SecondaryBtnState();
}
class _SecondaryBtnState extends State<_SecondaryBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _h = true),
    onExit:  (_) => setState(() => _h = false),
    child: GestureDetector(onTap: widget.onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: widget.small
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _h ? const Color(0xFFF1F5F9) : _K.white,
        border: Border.all(color: _K.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(widget.icon, size: widget.small ? 13 : 14, color: _K.text),
        SizedBox(width: widget.small ? 5 : 6),
        Text(widget.label, style: TextStyle(fontSize: widget.small ? 12 : 12.5, fontWeight: FontWeight.w700, color: _K.text)),
      ]),
    )),
  );
}

// Ghost button — outline only
class _GhostBtn extends StatefulWidget {
  final String label; final IconData icon; final VoidCallback onTap;
  const _GhostBtn({required this.label, required this.icon, required this.onTap});
  @override State<_GhostBtn> createState() => _GhostBtnState();
}
class _GhostBtnState extends State<_GhostBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _h = true),
    onExit:  (_) => setState(() => _h = false),
    child: GestureDetector(onTap: widget.onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: _h ? _K.pageBg : Colors.transparent,
        border: Border.all(color: _K.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(widget.icon, size: 13, color: _K.muted),
        const SizedBox(width: 6),
        Text(widget.label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _K.muted)),
      ]),
    )),
  );
}

// Generate Question button — blue, matching .generate-btn in prototype
class _GenerateBtn extends StatefulWidget {
  final String label; final IconData icon; final VoidCallback? onTap;
  const _GenerateBtn({required this.label, required this.icon, this.onTap});
  @override State<_GenerateBtn> createState() => _GenerateBtnState();
}
class _GenerateBtnState extends State<_GenerateBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      child: GestureDetector(onTap: widget.onTap, child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? (_h ? _K.blueHov : _K.blue) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(widget.icon, size: 14, color: enabled ? Colors.white : _K.hint),
          const SizedBox(width: 7),
          Text(widget.label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: enabled ? Colors.white : _K.hint)),
        ]),
      )),
    );
  }
}

// Small icon button (edit/delete) — 28×28
class _SmIconBtn extends StatelessWidget {
  final IconData icon; final String tooltip; final VoidCallback onTap; final Color color;
  const _SmIconBtn({required this.icon, required this.tooltip, required this.onTap, this.color = _K.muted});
  @override
  Widget build(BuildContext context) => Tooltip(message: tooltip, child: InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(6),
    child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 18, color: color)),
  ));
}

// Toolbar icon button — 26×26
class _TbIconBtn extends StatefulWidget {
  final IconData icon; final String tooltip; final VoidCallback onTap;
  const _TbIconBtn({required this.icon, required this.tooltip, required this.onTap});
  @override State<_TbIconBtn> createState() => _TbIconBtnState();
}
class _TbIconBtnState extends State<_TbIconBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => Tooltip(message: widget.tooltip, child: MouseRegion(
    onEnter: (_) => setState(() => _h = true),
    onExit:  (_) => setState(() => _h = false),
    child: GestureDetector(onTap: widget.onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 26, height: 26,
      decoration: BoxDecoration(
        color: _h ? _K.pageBg : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(widget.icon, size: 14, color: _K.hint),
    )),
  ));
}

// Transcript toolbar button (.tx-btn) — 28×28
class _TxBtn extends StatefulWidget {
  final String label; final bool bold; final bool italic;
  const _TxBtn({required this.label, this.bold = false, this.italic = false});
  @override State<_TxBtn> createState() => _TxBtnState();
}
class _TxBtnState extends State<_TxBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true),
    onExit:  (_) => setState(() => _h = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: _h ? _K.pageBg : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(child: Text(widget.label, style: TextStyle(
        fontSize: 12, fontWeight: widget.bold ? FontWeight.w900 : FontWeight.w500,
        fontStyle: widget.italic ? FontStyle.italic : FontStyle.normal,
        color: _K.muted,
      ))),
    ),
  );
}

// Badge pill (.badge)
class _Badge extends StatelessWidget {
  final String label; final Color bg; final Color fg;
  const _Badge(this.label, this.bg, this.fg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.2)),
  );
}

// Tag chip (.tag / .tag-add)
class _TagChip extends StatelessWidget {
  final String label; final bool dashed;
  const _TagChip(this.label, {this.dashed = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: dashed ? Colors.transparent : const Color(0xFFF1F5F9),
      border: Border.all(color: _K.border),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
      color: dashed ? _K.hint : const Color(0xFF334155))),
  );
}

// Search field — height 34, bg pageBg (.explorer-search input)
class _ExplorerSearch extends StatelessWidget {
  final TextEditingController controller;
  const _ExplorerSearch({required this.controller});
  @override
  Widget build(BuildContext context) => SizedBox(height: 34, child: TextField(
    controller: controller,
    style: const TextStyle(fontSize: 12.5, color: _K.text),
    decoration: InputDecoration(
      hintText: 'Search topics, subtitles...',
      hintStyle: const TextStyle(fontSize: 12.5, color: _K.hint),
      filled: true, fillColor: _K.pageBg,
      prefixIcon: const Icon(Icons.search_rounded, size: 14, color: _K.hint),
      contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _K.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _K.blue, width: 1.5)),
    ),
  ));
}

// Section card (white bg, border, 12px radius)
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _K.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _K.border),
      boxShadow: const [_K.shadow],
    ),
    child: child,
  );
}