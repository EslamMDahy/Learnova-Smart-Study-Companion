import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/ui/toast.dart';
import '../../../data/courses_models.dart';
import '../../../data/modules_models.dart';
import '../../../data/materials_models.dart';
import '../../../data/topics_models.dart';
import '../../controllers/course_details_controller.dart';
import '../../controllers/course_details_state.dart';
import '../upload_material_sheet.dart';
import '../generate_questions_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Color palette
// ─────────────────────────────────────────────────────────────────────────────
class _K {
  _K._();
  static const purple     = Color(0xFF7C3AED);
  static const purpleSoft = Color(0xFFF5F3FF);
  static const purpleMid  = Color(0xFFEDE9FE);
  static const purpleBd   = Color(0xFFDDD6FE);
  static const amber      = Color(0xFFD97706);
  static const amberSoft  = Color(0xFFFFFBEB);
  static const green      = Color(0xFF16A34A);
  static const greenSoft  = Color(0xFFF0FDF4);
  static const red        = Color(0xFFDC2626);
  static const redSoft    = Color(0xFFFFF1F2);
  static const blue       = Color(0xFF2563EB);
  static const blueSoft   = Color(0xFFEFF6FF);
  static const blueMid    = Color(0xFFDBEAFE);
  static const div        = Color(0xFFEEEEEE);
  static const bg         = Color(0xFFF6F7F9);
  static const sidebar    = Color(0xFFFAFAFA);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Context types
// ─────────────────────────────────────────────────────────────────────────────
enum _CType { module, material, topic }

class _Ctx {
  final _CType       type;
  final ModuleItem?  module;
  final MaterialItem? material;
  final TopicItem?   topic;
  const _Ctx._({required this.type, this.module, this.material, this.topic});
  factory _Ctx.module(ModuleItem m)                     => _Ctx._(type: _CType.module, module: m);
  factory _Ctx.material(ModuleItem m, MaterialItem mat) => _Ctx._(type: _CType.material, module: m, material: mat);
  factory _Ctx.topic(ModuleItem m, MaterialItem mat, TopicItem t) =>
      _Ctx._(type: _CType.topic, module: m, material: mat, topic: t);
}

// ─────────────────────────────────────────────────────────────────────────────
//  CourseMaterialsTab
// ─────────────────────────────────────────────────────────────────────────────
class CourseMaterialsTab extends ConsumerStatefulWidget {
  final MyCourseItem course;
  const CourseMaterialsTab({super.key, required this.course});
  @override
  ConsumerState<CourseMaterialsTab> createState() => _CourseMaterialsTabState();
}

class _CourseMaterialsTabState extends ConsumerState<CourseMaterialsTab> {
  final Set<int>    _expanded = {};
  _Ctx?             _sel;
  final List<_Ctx>  _stack   = [];
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  _Ctx? get _active => _stack.isNotEmpty ? _stack.last : _sel;

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(courseDetailsControllerProvider(widget.course.id));
    return Column(children: [
      Expanded(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SidebarWidget(
            state: st,
            expanded: _expanded,
            active: _active,
            scroll: _scroll,
            onModuleTap: (m) => _tapModule(m, st),
            onMaterialTap: _tapMaterial,
            onTopicTap: _tapTopic,
            onAddMaterial: _showUploadSheet,
            onAddModule: _showCreateModuleDialog,
            onRefresh: () => ref
                .read(courseDetailsControllerProvider(widget.course.id).notifier)
                .loadModulesAndAllMaterials(force: true),
          ),
          Expanded(child: _buildPanel(st)),
        ]),
      ),
      if (_sel != null)
        _FooterWidget(
          ctx: _active ?? _sel!,
          uploading: st.uploading,
          onUpload: () { final m = _sel?.module; if (m != null) _showUploadSheet(m); },
          onGenerate: () => _openGenerateDialog(moduleId: _sel?.module?.id),
          onClose: () => setState(() { _sel = null; _stack.clear(); }),
        ),
    ]);
  }

  // ── Tap handlers ────────────────────────────────────────────────────────
  void _tapModule(ModuleItem m, CourseDetailsState st) {
    setState(() {
      final alreadySel = _active?.type == _CType.module && _active?.module?.id == m.id;
      if (_expanded.contains(m.id) && alreadySel) {
        _expanded.remove(m.id); _sel = null; _stack.clear();
      } else {
        _expanded.add(m.id); _sel = _Ctx.module(m); _stack.clear();
        if (!st.materials.containsKey(m.id))
          ref.read(courseDetailsControllerProvider(widget.course.id).notifier).loadMaterials(m.id);
      }
    });
  }

  void _tapMaterial(ModuleItem m, MaterialItem mat) {
    setState(() { _sel = _Ctx.material(m, mat); _stack.clear(); });
    ref.read(courseDetailsControllerProvider(widget.course.id).notifier).loadTopics(m.id);
    ref.read(courseDetailsControllerProvider(widget.course.id).notifier)
        .fetchDownloadUrl(moduleId: m.id, materialId: mat.id);
  }

  void _tapTopic(ModuleItem m, MaterialItem mat, TopicItem t) {
    setState(() { _sel = _Ctx.material(m, mat); _stack..clear()..add(_Ctx.topic(m, mat, t)); });
  }

  void _drillTopic(TopicItem t) {
    final c = _sel; if (c?.module == null || c?.material == null) return;
    setState(() { _stack.add(_Ctx.topic(c!.module!, c.material!, t)); });
  }

  void _pop() => setState(() { if (_stack.isNotEmpty) _stack.removeLast(); });

  // ── Right panel routing ──────────────────────────────────────────────────
  Widget _buildPanel(CourseDetailsState st) {
    final c = _active;
    if (c == null) return _EmptyStateWidget(onCreate: _showCreateModuleDialog);

    if (c.type == _CType.module)
      return _ModulePanelWidget(
        module: c.module!, materials: st.materials[c.module!.id] ?? [],
        uploading: st.uploading, uploadProgress: st.uploadProgress,
        onUpload: () => _showUploadSheet(c.module!),
        onMaterialTap: (mat) => _tapMaterial(c.module!, mat),
        onRename: () => _showRenameDialog(c.module!),
        onTogglePublish: () => _togglePublish(c.module!),
        onDelete: () => _confirmDelete(c.module!),
      );

    if (c.type == _CType.material) {
      final mid = c.module!.id; final matId = c.material!.id;
      return _MaterialPanelWidget(
        module: c.module!, material: c.material!,
        topics: st.topics[mid] ?? [], topicsLoading: st.topicsLoading[mid] ?? false,
        downloadUrl: st.downloadUrls[matId] ?? c.material!.downloadUrl,
        urlLoading: st.downloadUrlLoading[matId] ?? false,
        onTopicTap: _drillTopic,
        onAddTopicManual: () => _showAddTopicDialog(c.module!),
        onGenerateTopicsAI: () => _openGenerateDialog(moduleId: mid),
        onRefreshUrl: () => ref.read(courseDetailsControllerProvider(widget.course.id).notifier)
            .fetchDownloadUrl(moduleId: mid, materialId: matId, force: true),
      );
    }

    return _TopicPanelWidget(
      module: c.module!, material: c.material!, topic: c.topic!,
      canPop: _stack.isNotEmpty, onBack: _pop,
      onGenerate: () => _openGenerateDialog(moduleId: c.module!.id),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────
  Future<void> _showCreateModuleDialog() async {
    final tc = TextEditingController(), dc = TextEditingController();
    final ok = await showDialog<bool>(context: context,
        builder: (_) => _ModuleDialogWidget(titleCtrl: tc, descCtrl: dc));
    if (ok != true || !mounted) return;
    final m = await ref.read(courseDetailsControllerProvider(widget.course.id).notifier)
        .createModule(tc.text.trim(), description: dc.text.trim().isEmpty ? null : dc.text.trim());
    if (m != null && mounted) {
      AppToast.success(context, title: 'Module created', message: '"${m.title}" added.');
      setState(() { _expanded.add(m.id); _sel = _Ctx.module(m); _stack.clear(); });
    }
  }

  Future<void> _showUploadSheet(ModuleItem module) async {
    final results = await showDialog<List<UploadSheetResult>>(context: context,
        barrierColor: Colors.black.withOpacity(0.35),
        builder: (_) => UploadMaterialSheet(moduleTitle: module.title));
    if (results == null || results.isEmpty || !mounted) return;
    int ok = 0;
    for (final r in results) {
      if (!mounted) break;
      final success = await ref.read(courseDetailsControllerProvider(widget.course.id).notifier)
          .uploadMaterial(moduleId: module.id, bytes: r.bytes,
              filename: r.filename, contentType: r.contentType, title: r.title);
      if (success) ok++;
    }
    if (mounted && ok > 0)
      AppToast.success(context, title: 'Uploaded',
          message: ok == 1 ? '"${results.first.title}" is ready.' : '$ok files uploaded.');
  }

  Future<void> _showRenameDialog(ModuleItem m) async {
    final c = TextEditingController(text: m.title);
    final ok = await showDialog<bool>(context: context,
        barrierColor: Colors.black.withOpacity(0.35),
        builder: (_) => _SimpleDialog(title: 'Rename Module', ctrl: c,
            confirm: 'Rename', confirmColor: AppColors.primary));
    if (ok != true || !mounted || c.text.trim().isEmpty || c.text.trim() == m.title) return;
    AppToast.info(context, title: 'Coming soon', message: 'Rename coming soon.');
  }

  Future<void> _togglePublish(ModuleItem m) async =>
      AppToast.info(context, title: 'Coming soon',
          message: '${m.isPublished ? 'Unpublish' : 'Publish'} coming soon.');

  Future<void> _confirmDelete(ModuleItem m) async {
    final ok = await showDialog<bool>(context: context,
        barrierColor: Colors.black.withOpacity(0.35),
        builder: (_) => _ConfirmDialogWidget(title: 'Delete Module',
            body: 'Delete "${m.title}"? This will also remove all its materials.',
            confirm: 'Delete', confirmColor: const Color(0xFFEF4444)));
    if (ok != true || !mounted) return;
    AppToast.info(context, title: 'Coming soon', message: 'Deletion coming soon.');
  }

  Future<void> _showAddTopicDialog(ModuleItem m) async {
    final tc = TextEditingController(), dc = TextEditingController();
    final ok = await showDialog<bool>(context: context,
        builder: (_) => _AddTopicDialogWidget(
            moduleTitle: m.title, titleCtrl: tc, descCtrl: dc));
    if (ok != true || !mounted) return;
    AppToast.info(context, title: 'Coming soon',
        message: 'Manual topic creation coming soon.');
  }

  void _openGenerateDialog({int? moduleId}) => showDialog(context: context,
      builder: (_) => GenerateQuestionsDialog(
          courseId: widget.course.id, initialModuleId: moduleId));
}

// ─────────────────────────────────────────────────────────────────────────────
//  SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarWidget extends StatelessWidget {
  final CourseDetailsState state;
  final Set<int>           expanded;
  final _Ctx?              active;
  final ScrollController   scroll;
  final void Function(ModuleItem) onModuleTap;
  final void Function(ModuleItem, MaterialItem) onMaterialTap;
  final void Function(ModuleItem, MaterialItem, TopicItem) onTopicTap;
  final void Function(ModuleItem) onAddMaterial;
  final VoidCallback onAddModule;
  final VoidCallback onRefresh;

  const _SidebarWidget({
    required this.state, required this.expanded, required this.active,
    required this.scroll, required this.onModuleTap, required this.onMaterialTap,
    required this.onTopicTap, required this.onAddMaterial,
    required this.onAddModule, required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 272,
      decoration: const BoxDecoration(
          color: _K.sidebar,
          border: Border(right: BorderSide(color: _K.div))),
      child: Column(children: [
        // header
        Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(color: Colors.white,
              border: Border(bottom: BorderSide(color: _K.div))),
          child: Row(children: [
            const Icon(Icons.folder_open_rounded, size: 14, color: AppColors.textHint),
            const SizedBox(width: 7),
            const Text('STRUCTURE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                color: AppColors.textHint, letterSpacing: 1.0)),
            const Spacer(),
            if (state.modulesLoading)
              const SizedBox(width: 12, height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5)),
            _IBtn(icon: Icons.refresh_rounded, tooltip: 'Refresh', onTap: onRefresh),
          ])),

        // tree
        Expanded(
          child: state.modulesLoading && state.modules.isEmpty
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : state.modules.isEmpty
                  ? _SidebarEmpty(onAdd: onAddModule)
                  : ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: state.modules.length,
                      itemBuilder: (_, i) {
                        final m = state.modules[i];
                        return _ModuleRowWidget(
                          module: m, isExpanded: expanded.contains(m.id),
                          materials: state.materials[m.id] ?? [],
                          loading: state.materialsLoading[m.id] ?? false,
                          moduleTopics: state.topics[m.id] ?? [],
                          active: active,
                          onModuleTap: () => onModuleTap(m),
                          onMaterialTap: (mat) => onMaterialTap(m, mat),
                          onTopicTap: (mat, t) => onTopicTap(m, mat, t),
                          onAddMaterial: () => onAddMaterial(m),
                        );
                      }),
        ),

        // footer
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: _K.div))),
          child: SizedBox(
            width: double.infinity, height: 36,
            child: ElevatedButton.icon(
              onPressed: onAddModule,
              icon: const Icon(Icons.add_rounded, size: 15),
              label: const Text('Add Module',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SidebarEmpty extends StatelessWidget {
  final VoidCallback onAdd;
  const _SidebarEmpty({required this.onAdd});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(20),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 48, height: 48,
          decoration: BoxDecoration(color: _K.blueSoft, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.folder_open_outlined, size: 22, color: AppColors.primary)),
      const SizedBox(height: 10),
      const Text('No modules yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textTitle)),
      const SizedBox(height: 4),
      const Text('Create your first module below.', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
    ])));
}

// ─── Module row ──────────────────────────────────────────────────────────────
class _ModuleRowWidget extends StatelessWidget {
  final ModuleItem    module;
  final bool          isExpanded;
  final List<MaterialItem> materials;
  final bool          loading;
  final List<TopicItem> moduleTopics;
  final _Ctx?         active;
  final VoidCallback  onModuleTap;
  final void Function(MaterialItem) onMaterialTap;
  final void Function(MaterialItem, TopicItem) onTopicTap;
  final VoidCallback  onAddMaterial;

  const _ModuleRowWidget({
    required this.module, required this.isExpanded,
    required this.materials, required this.loading,
    required this.moduleTopics, required this.active,
    required this.onModuleTap, required this.onMaterialTap,
    required this.onTopicTap, required this.onAddMaterial,
  });

  bool get _isSel => active?.type == _CType.module && active?.module?.id == module.id;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InkWell(onTap: onModuleTap, child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        margin: const EdgeInsets.fromLTRB(6, 1, 6, 1),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(color: _isSel ? _K.blueSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          AnimatedRotation(turns: isExpanded ? 0.25 : 0, duration: const Duration(milliseconds: 130),
              child: Icon(Icons.chevron_right_rounded, size: 15,
                  color: _isSel ? AppColors.primary : AppColors.textHint)),
          const SizedBox(width: 5),
          Container(width: 22, height: 22,
              decoration: BoxDecoration(
                  color: _isSel ? _K.blueMid : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(5)),
              child: Icon(Icons.folder_rounded, size: 13,
                  color: _isSel ? AppColors.primary : const Color(0xFFEA580C))),
          const SizedBox(width: 8),
          Expanded(child: Text(module.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700,
                  color: _isSel ? AppColors.primary : AppColors.textTitle))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
                color: module.isPublished ? _K.greenSoft : _K.amberSoft,
                borderRadius: BorderRadius.circular(4)),
            child: Text(module.isPublished ? 'Live' : 'Draft',
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                    color: module.isPublished ? _K.green : _K.amber)),
          ),
          if (isExpanded) ...[
            const SizedBox(width: 3),
            Tooltip(message: 'Upload material', child: InkWell(onTap: onAddMaterial,
                borderRadius: BorderRadius.circular(5), child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(Icons.add_rounded, size: 14, color: AppColors.textHint)))),
          ],
        ]),
      )),
      if (isExpanded) _buildChildren(),
    ]);
  }

  Widget _buildChildren() {
    if (loading) return const Padding(padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(child: SizedBox(width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5))));
    if (materials.isEmpty) return const Padding(padding: EdgeInsets.fromLTRB(50, 5, 12, 8),
        child: Text('No materials — tap ＋ to upload',
            style: TextStyle(fontSize: 11, color: AppColors.textHint)));
    return Column(children: materials.map((mat) {
      final matSel = active?.material?.id == mat.id &&
          (active?.type == _CType.material || active?.type == _CType.topic);
      return _MatRowWidget(material: mat, topics: moduleTopics, isSelected: matSel,
          active: active, onTap: () => onMaterialTap(mat), onTopicTap: (t) => onTopicTap(mat, t));
    }).toList());
  }
}

class _MatRowWidget extends StatelessWidget {
  final MaterialItem material;
  final List<TopicItem> topics;
  final bool isSelected;
  final _Ctx? active;
  final VoidCallback onTap;
  final void Function(TopicItem) onTopicTap;
  const _MatRowWidget({required this.material, required this.topics,
      required this.isSelected, required this.active,
      required this.onTap, required this.onTopicTap});

  @override
  Widget build(BuildContext context) {
    const iconMap = {
      'video': (Icons.play_circle_outline_rounded, Color(0xFF2563EB)),
      'pdf'  : (Icons.picture_as_pdf_outlined,    Color(0xFFDC2626)),
      'quiz' : (Icons.quiz_outlined,               Color(0xFF7C3AED)),
    };
    final (ico, col) = iconMap[material.type] ?? (Icons.article_outlined, AppColors.textMuted);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InkWell(onTap: onTap, child: Container(
        margin: const EdgeInsets.fromLTRB(26, 1, 6, 1),
        padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
        decoration: BoxDecoration(
            color: isSelected ? _K.blueSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(7)),
        child: Row(children: [
          Container(width: 1, height: 14, color: _K.div, margin: const EdgeInsets.only(right: 8)),
          Icon(ico, size: 13, color: isSelected ? AppColors.primary : col),
          const SizedBox(width: 7),
          Expanded(child: Text(material.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : const Color(0xFF334155)))),
          _Dot(status: material.status),
        ]),
      )),
      ...topics.map((t) {
        final tSel = active?.type == _CType.topic && active?.topic?.id == t.id;
        return InkWell(onTap: () => onTopicTap(t), child: Container(
          margin: const EdgeInsets.fromLTRB(40, 0, 6, 0),
          padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
          decoration: BoxDecoration(color: tSel ? _K.purpleSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(5)),
          child: Row(children: [
            Container(width: 1, height: 11, color: _K.div, margin: const EdgeInsets.only(right: 7)),
            Icon(Icons.tag_rounded, size: 10, color: tSel ? _K.purple : AppColors.textHint),
            const SizedBox(width: 5),
            Expanded(child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11,
                    fontWeight: tSel ? FontWeight.w600 : FontWeight.w400,
                    color: tSel ? _K.purple : AppColors.textMuted))),
          ]),
        ));
      }),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FOOTER
// ─────────────────────────────────────────────────────────────────────────────
class _FooterWidget extends StatelessWidget {
  final _Ctx ctx; final bool uploading;
  final VoidCallback onUpload, onGenerate, onClose;
  const _FooterWidget({required this.ctx, required this.uploading,
      required this.onUpload, required this.onGenerate, required this.onClose});

  String get _label => switch (ctx.type) {
    _CType.module   => ctx.module?.title ?? 'Module',
    _CType.material => ctx.material?.displayTitle ?? 'Material',
    _CType.topic    => ctx.topic?.title ?? 'Topic',
  };
  IconData get _icon => switch (ctx.type) {
    _CType.module   => Icons.folder_rounded,
    _CType.material => ctx.material?.type == 'video'
        ? Icons.play_circle_filled_rounded : Icons.picture_as_pdf_rounded,
    _CType.topic    => Icons.tag_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(color: Colors.white,
          border: const Border(top: BorderSide(color: _K.div)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 16, offset: const Offset(0, -4))]),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: _K.blueSoft, borderRadius: BorderRadius.circular(7)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(_icon, size: 13, color: AppColors.primary), const SizedBox(width: 6),
            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 200),
                child: Text(_label, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppColors.primary))),
          ])),
        const Spacer(),
        _Btn(icon: Icons.auto_awesome_rounded, label: 'Generate Questions',
            primary: true, onTap: onGenerate),
        const SizedBox(width: 8),
        InkWell(onTap: onClose, borderRadius: BorderRadius.circular(6),
            child: const Padding(padding: EdgeInsets.all(7),
                child: Icon(Icons.close_rounded, size: 15, color: AppColors.textHint))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyStateWidget extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyStateWidget({required this.onCreate});
  @override
  Widget build(BuildContext context) => Container(color: _K.bg, child: Center(child: Column(
    mainAxisSize: MainAxisSize.min, children: [
    Container(width: 72, height: 72,
        decoration: BoxDecoration(color: _K.blueSoft, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.folder_open_rounded, size: 34, color: AppColors.primary)),
    const SizedBox(height: 18),
    const Text('Select something to get started', style: TextStyle(
        fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textTitle)),
    const SizedBox(height: 6),
    const Text('Choose a module or material from the left panel.',
        style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
    const SizedBox(height: 22),
    OutlinedButton.icon(onPressed: onCreate,
        icon: const Icon(Icons.add_rounded, size: 15),
        label: const Text('New Module'),
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
  ])));
}

// ─────────────────────────────────────────────────────────────────────────────
//  MODULE PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _ModulePanelWidget extends StatelessWidget {
  final ModuleItem module; final List<MaterialItem> materials;
  final bool uploading; final double uploadProgress;
  final VoidCallback onUpload; final void Function(MaterialItem) onMaterialTap;
  final VoidCallback? onRename, onTogglePublish, onDelete;
  const _ModulePanelWidget({required this.module, required this.materials,
      required this.uploading, required this.uploadProgress,
      required this.onUpload, required this.onMaterialTap,
      this.onRename, this.onTogglePublish, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(color: _K.bg, child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _ModuleHeroWidget(module: module, materialCount: materials.length),
        const SizedBox(height: 16),
        if (uploading) ...[_UploadProgressWidget(progress: uploadProgress), const SizedBox(height: 14)],

        _CardWidget(
          header: _HdrWidget(icon: Icons.tune_rounded, iconColor: AppColors.primary, title: 'Preferences'),
          child: Column(children: [
            _PRow(icon: Icons.drive_file_rename_outline_rounded, iconBg: _K.blueSoft,
                iconFg: AppColors.primary, label: 'Rename Module', sub: module.title, onTap: onRename),
            _DivW(),
            _PRow(icon: Icons.notes_rounded, iconBg: _K.blueSoft, iconFg: AppColors.primary,
                label: 'Edit Description',
                sub: (module.description?.isNotEmpty == true) ? module.description! : 'No description yet',
                onTap: onRename),
            _DivW(),
            _PRow(icon: module.isPublished ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                iconBg: module.isPublished ? _K.amberSoft : _K.greenSoft,
                iconFg: module.isPublished ? _K.amber : _K.green,
                label: module.isPublished ? 'Unpublish' : 'Publish',
                sub: module.isPublished ? 'Hide from students' : 'Make visible to students',
                onTap: onTogglePublish),
            _DivW(),
            _PRow(icon: Icons.upload_file_rounded, iconBg: _K.purpleSoft, iconFg: _K.purple,
                label: 'Upload Material', sub: 'Add a PDF, video, or document',
                onTap: uploading ? null : onUpload),
            _DivW(),
            _PRow(icon: Icons.swap_vert_rounded, iconBg: _K.greenSoft, iconFg: _K.green,
                label: 'Change Position',
                sub: 'Currently #${module.orderIndex + 1} in the course', onTap: null),
            _DivW(),
            _PRow(icon: Icons.delete_outline_rounded,
                iconBg: const Color(0xFFFEE2E2), iconFg: const Color(0xFFEF4444),
                label: 'Delete Module', sub: 'Permanently remove this module',
                onTap: onDelete, danger: true),
          ]),
        ),
        const SizedBox(height: 16),

        _CardWidget(
          header: _HdrWidget(icon: Icons.folder_open_rounded, iconColor: AppColors.primary,
              title: 'Materials', badge: '${materials.length}',
              trailing: _SmBtn(icon: Icons.upload_rounded, label: 'Upload',
                  disabled: uploading, onTap: onUpload)),
          child: materials.isEmpty
              ? _MatEmptyWidget(onUpload: onUpload)
              : Column(children: materials.asMap().entries.map((e) =>
                  _MatListItemWidget(material: e.value, isLast: e.key == materials.length - 1,
                      onTap: () => onMaterialTap(e.value))).toList()),
        ),
      ]),
    ));
  }
}

class _ModuleHeroWidget extends StatelessWidget {
  final ModuleItem module; final int materialCount;
  const _ModuleHeroWidget({required this.module, required this.materialCount});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF137FEC), Color(0xFF42A5F5)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2),
            blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 6, children: [
            _HPill(module.isPublished ? '● Live' : '● Draft',
                module.isPublished ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24)),
            const _HPill('MODULE', Colors.white70),
            if (materialCount > 0) _HPill('$materialCount material${materialCount == 1 ? '' : 's'}', Colors.white70),
          ]),
          const SizedBox(height: 10),
          Text(module.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
              color: Colors.white, height: 1.2)),
          if (module.description != null) ...[
            const SizedBox(height: 5),
            Text(module.description!, style: TextStyle(fontSize: 13,
                color: Colors.white.withOpacity(0.75), height: 1.5)),
          ],
        ])),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.2))),
          child: Column(children: [
            Text('Order', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500)),
            const SizedBox(height: 3),
            Text('#${module.orderIndex + 1}', style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          ]),
        ),
      ]),
    );
  }
}

class _HPill extends StatelessWidget {
  final String l; final Color c; const _HPill(this.l, this.c);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2))),
    child: Text(l, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)));
}

class _UploadProgressWidget extends StatelessWidget {
  final double progress; const _UploadProgressWidget({required this.progress});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _K.div)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const SizedBox(width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5)),
        const SizedBox(width: 10),
        const Expanded(child: Text('Uploading material…',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
        Text('${(progress * 100).toInt()}%', style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: progress,
              backgroundColor: const Color(0xFFE2E8F0), color: AppColors.primary, minHeight: 4)),
    ]),
  );
}

class _MatEmptyWidget extends StatelessWidget {
  final VoidCallback onUpload; const _MatEmptyWidget({required this.onUpload});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 28),
    child: Center(child: Column(children: [
      const Icon(Icons.upload_file_outlined, size: 28, color: AppColors.textHint),
      const SizedBox(height: 8),
      const Text('No materials yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
      const SizedBox(height: 4),
      const Text('Upload a PDF, video, or document', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: onUpload,
          icon: const Icon(Icons.upload_rounded, size: 14), label: const Text('Upload Material'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary))),
    ])));
}

class _MatListItemWidget extends StatelessWidget {
  final MaterialItem material; final bool isLast; final VoidCallback onTap;
  const _MatListItemWidget({required this.material, required this.isLast, required this.onTap});
  static const _colors = {
    'video': (Icons.play_circle_filled_rounded, Color(0xFFDBEAFE), Color(0xFF2563EB)),
    'pdf'  : (Icons.picture_as_pdf_rounded,     Color(0xFFFEE2E2), Color(0xFFDC2626)),
    'quiz' : (Icons.quiz_rounded,                Color(0xFFF3E8FF), Color(0xFF9333EA)),
  };
  static const _status = {
    'ready'      : ('Ready',      Color(0xFFDCFCE7), Color(0xFF16A34A)),
    'processing' : ('Processing', Color(0xFFFEF3C7), Color(0xFFD97706)),
    'uploaded'   : ('Processing', Color(0xFFFEF3C7), Color(0xFFD97706)),
    'draft_upload': ('Uploading', Color(0xFFE0F2FE), Color(0xFF0369A1)),
    'error'      : ('Error',      Color(0xFFFEF2F2), Color(0xFFDC2626)),
  };
  @override
  Widget build(BuildContext context) {
    final (ico, ib, ic) = _colors[material.type] ??
        (Icons.insert_drive_file_rounded, const Color(0xFFF1F5F9), AppColors.textMuted);
    final (sl, sb, sf) = _status[material.status] ??
        (material.status, const Color(0xFFF1F5F9), AppColors.textMuted);
    return InkWell(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: _K.div))),
      child: Row(children: [
        Container(width: 34, height: 34,
            decoration: BoxDecoration(color: ib, borderRadius: BorderRadius.circular(9)),
            child: Icon(ico, size: 17, color: ic)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(material.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textTitle)),
          const SizedBox(height: 2),
          Text(material.type.toUpperCase(), style: const TextStyle(
              fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textHint, letterSpacing: 0.5)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: sb, borderRadius: BorderRadius.circular(5)),
            child: Text(sl, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: sf))),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right_rounded, size: 15, color: AppColors.textHint),
      ]),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MATERIAL PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _MaterialPanelWidget extends StatelessWidget {
  final ModuleItem module; final MaterialItem material;
  final List<TopicItem> topics; final bool topicsLoading;
  final String? downloadUrl; final bool urlLoading;
  final void Function(TopicItem) onTopicTap;
  final VoidCallback onAddTopicManual, onGenerateTopicsAI, onRefreshUrl;
  const _MaterialPanelWidget({required this.module, required this.material,
      required this.topics, required this.topicsLoading,
      required this.downloadUrl, required this.urlLoading,
      required this.onTopicTap, required this.onAddTopicManual,
      required this.onGenerateTopicsAI, required this.onRefreshUrl});

  @override
  Widget build(BuildContext context) {
    return Container(color: _K.bg, child: Column(children: [
      _MatHeaderWidget(module: module, material: material),
      Expanded(child: _FilePreviewWidget(material: material, downloadUrl: downloadUrl,
          loading: urlLoading, onRefresh: onRefreshUrl)),
    ]));
  }
}

class _MatHeaderWidget extends StatelessWidget {
  final ModuleItem module; final MaterialItem material;
  const _MatHeaderWidget({required this.module, required this.material});
  static const _tc = {
    'video': (Color(0xFF2563EB), Color(0xFFDBEAFE)),
    'pdf'  : (Color(0xFFDC2626), Color(0xFFFEE2E2)),
    'image': (Color(0xFF7C3AED), Color(0xFFF3E8FF)),
    'audio': (Color(0xFF16A34A), Color(0xFFDCFCE7)),
    'quiz' : (Color(0xFF9333EA), Color(0xFFF3E8FF)),
  };
  @override
  Widget build(BuildContext context) {
    final (tcol, tbg) = _tc[material.type] ?? (AppColors.textMuted, const Color(0xFFF1F5F9));
    final (scol, sbg) = material.isReady ? (_K.green, _K.greenSoft)
        : material.isProcessing ? (_K.amber, _K.amberSoft)
        : (AppColors.dangerText, const Color(0xFFFFF1F2));
    final sl = material.isReady ? '● Ready' : material.isProcessing ? '● Processing' : '● Error';
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 16, 12),
      decoration: const BoxDecoration(color: Colors.white,
          border: Border(bottom: BorderSide(color: _K.div))),
      child: Row(children: [
        _TIcon(type: material.type, size: 36), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _Pill(l: material.type.toUpperCase(), fg: tcol, bg: tbg), const SizedBox(width: 6),
            _Pill(l: sl, fg: scol, bg: sbg),
          ]),
          const SizedBox(height: 4),
          Text(material.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textTitle)),
          Text('In "${module.title}"', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FILE PREVIEW
// ─────────────────────────────────────────────────────────────────────────────
enum _PK { pdf, image, video, audio, link, other }

class _FilePreviewWidget extends StatelessWidget {
  final MaterialItem material; final String? downloadUrl;
  final bool loading; final VoidCallback onRefresh;
  const _FilePreviewWidget({required this.material, required this.downloadUrl,
      required this.loading, required this.onRefresh});

  _PK get _kind {
    final t = material.type.toLowerCase(); final m = (material.mimeType ?? '').toLowerCase();
    if (t == 'video' || m.startsWith('video/')) return _PK.video;
    if (t == 'pdf'   || m == 'application/pdf') return _PK.pdf;
    if (t == 'image' || m.startsWith('image/')) return _PK.image;
    if (t == 'audio' || m.startsWith('audio/')) return _PK.audio;
    if (t == 'link') return _PK.link;
    return _PK.other;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return _LoaderW(label: 'Loading preview…');
    if (material.isProcessing) return _PlaceholderW(icon: Icons.hourglass_top_rounded,
        iconColor: _K.amber, iconBg: _K.amberSoft, title: 'Processing…',
        sub: 'Your file is being processed. Preview will be available shortly.');
    if (material.isError) return _PlaceholderW(icon: Icons.error_outline_rounded,
        iconColor: AppColors.dangerText, iconBg: _K.redSoft, title: 'Processing failed',
        sub: 'Something went wrong processing this file.',
        actionLabel: 'Retry', onAction: onRefresh);
    if (downloadUrl == null || downloadUrl!.isEmpty)
      return _PlaceholderW(icon: Icons.link_off_rounded, iconColor: AppColors.textMuted,
          iconBg: _K.bg, title: 'Preview unavailable',
          sub: 'Could not load a URL for this file.',
          actionLabel: 'Retry', onAction: onRefresh);

    final url = downloadUrl!;
    return switch (_kind) {
      _PK.pdf   => _PdfPreviewWidget(url: url, material: material),
      _PK.image => _ImagePreviewWidget(url: url),
      _PK.video => _VideoPreviewWidget(url: url, material: material),
      _PK.audio => _AudioPreviewWidget(url: url, material: material),
      _PK.link  => _LinkPreviewWidget(url: url),
      _PK.other => _FallbackWidget(url: url, material: material),
    };
  }
}

class _PdfPreviewWidget extends StatelessWidget {
  final String url; final MaterialItem material;
  const _PdfPreviewWidget({required this.url, required this.material});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(20), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      _MetaStripW(material: material), const SizedBox(height: 14),
      Expanded(child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _K.div),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(children: [
          // toolbar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 11, 14, 11),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _K.div)),
                borderRadius: BorderRadius.vertical(top: Radius.circular(13))),
            child: Row(children: [
              Container(width: 30, height: 30, decoration: BoxDecoration(
                  color: _K.redSoft, borderRadius: BorderRadius.circular(7)),
                  child: const Icon(Icons.picture_as_pdf_rounded, size: 15, color: _K.red)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(material.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textTitle)),
                if (material.pageCount != null)
                  Text('${material.pageCount} pages',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ])),
              _OBtn(url: url),
            ]),
          ),
          // body
          Expanded(child: Container(
            decoration: const BoxDecoration(color: Color(0xFFF8F9FB),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(13))),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 80, height: 80,
                  decoration: BoxDecoration(color: _K.redSoft, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.picture_as_pdf_rounded, size: 40, color: _K.red)),
              const SizedBox(height: 16),
              const Text('PDF Document', style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w800, color: AppColors.textTitle)),
              const SizedBox(height: 6),
              const Text('Tap "Open" to view this PDF in your browser.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.tryParse(url);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: const Text('Open PDF in Browser'),
                style: ElevatedButton.styleFrom(backgroundColor: _K.red, foregroundColor: Colors.white,
                    elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('URL copied to clipboard'), duration: Duration(seconds: 2)));
                },
                icon: const Icon(Icons.copy_rounded, size: 13),
                label: const Text('Copy URL'),
                style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
              ),
            ])),
          )),
        ]),
      )),
    ]));
  }
}

class _ImagePreviewWidget extends StatelessWidget {
  final String url; const _ImagePreviewWidget({required this.url});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(20),
    child: Container(decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(14), border: Border.all(color: _K.div)),
      child: ClipRRect(borderRadius: BorderRadius.circular(13), child: Stack(children: [
        Container(color: const Color(0xFFF8F9FB)),
        Center(child: Image.network(url, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _FallbackWidget(url: url, material: null),
            loadingBuilder: (_, child, p) => p == null ? child :
                const Center(child: CircularProgressIndicator(strokeWidth: 2)))),
        Positioned(top: 12, right: 12, child: _OBtn(url: url)),
      ]))));
}

class _VideoPreviewWidget extends StatelessWidget {
  final String url; final MaterialItem material;
  const _VideoPreviewWidget({required this.url, required this.material});
  static String _fmt(int s) {
    final h = s ~/ 3600; final m = (s % 3600) ~/ 60; final sec = s % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m ${sec}s';
  }
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _MetaStripW(material: material), const SizedBox(height: 14),
      Expanded(child: Container(
        decoration: BoxDecoration(color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(14), border: Border.all(color: _K.div)),
        child: ClipRRect(borderRadius: BorderRadius.circular(13),
            child: Stack(alignment: Alignment.center, children: [
          Container(decoration: BoxDecoration(gradient: RadialGradient(
              colors: [const Color(0xFF1A2332), const Color(0xFF0D1117)]))),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 80, height: 80,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.2))),
                child: const Icon(Icons.play_arrow_rounded, size: 44, color: Colors.white)),
            const SizedBox(height: 16),
            Text(material.displayTitle, style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.w700, color: Colors.white)),
            if (material.durationSeconds != null) ...[
              const SizedBox(height: 4),
              Text(_fmt(material.durationSeconds!),
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55))),
            ],
            const SizedBox(height: 22),
            ElevatedButton.icon(onPressed: () {},
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('Open Video'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    foregroundColor: Colors.white, elevation: 0,
                    side: BorderSide(color: Colors.white.withOpacity(0.25)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)))),
          ]),
        ])))),
    ]));
}

class _AudioPreviewWidget extends StatelessWidget {
  final String url; final MaterialItem material;
  const _AudioPreviewWidget({required this.url, required this.material});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(20),
    child: Container(padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _K.div)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 80, height: 80, decoration: BoxDecoration(
            color: _K.greenSoft, borderRadius: BorderRadius.circular(22)),
            child: const Icon(Icons.headphones_rounded, size: 40, color: _K.green)),
        const SizedBox(height: 18),
        Text(material.displayTitle, textAlign: TextAlign.center, style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textTitle)),
        if (material.durationSeconds != null) ...[
          const SizedBox(height: 6),
          Text('Duration: ${material.durationSeconds! ~/ 60}m ${material.durationSeconds! % 60}s',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
        const SizedBox(height: 24),
        _OBtn(url: url, big: true),
      ])));
}

class _LinkPreviewWidget extends StatelessWidget {
  final String url; const _LinkPreviewWidget({required this.url});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(20),
    child: Container(padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _K.div)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(
            color: _K.blueSoft, borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.link_rounded, size: 34, color: AppColors.primary)),
        const SizedBox(height: 16),
        const Text('External Link', style: TextStyle(fontSize: 17,
            fontWeight: FontWeight.w800, color: AppColors.textTitle)),
        const SizedBox(height: 8),
        Text(url, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 20), _OBtn(url: url, big: true),
      ])));
}

class _FallbackWidget extends StatelessWidget {
  final String url; final MaterialItem? material;
  const _FallbackWidget({required this.url, required this.material});
  @override
  Widget build(BuildContext context) => _PlaceholderW(icon: Icons.insert_drive_file_rounded,
      iconColor: AppColors.textMuted, iconBg: _K.bg, title: 'Preview not available',
      sub: material != null ? 'This file type (${material!.type}) cannot be previewed inline.'
          : 'Preview not available.', actionLabel: 'Open / Download', onAction: () {});
}

class _LoaderW extends StatelessWidget {
  final String label; const _LoaderW({required this.label});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const CircularProgressIndicator(strokeWidth: 2), const SizedBox(height: 12),
    Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted))]));
}

class _PlaceholderW extends StatelessWidget {
  final IconData icon; final Color iconColor, iconBg;
  final String title, sub; final String? actionLabel; final VoidCallback? onAction;
  const _PlaceholderW({required this.icon, required this.iconColor, required this.iconBg,
      required this.title, required this.sub, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 70, height: 70,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(18)),
          child: Icon(icon, size: 32, color: iconColor)),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textTitle)),
      const SizedBox(height: 6),
      Text(sub, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
          textAlign: TextAlign.center),
      if (actionLabel != null && onAction != null) ...[
        const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: onAction,
            icon: const Icon(Icons.open_in_new_rounded, size: 14), label: Text(actionLabel!)),
      ],
    ])));
}

class _MetaStripW extends StatelessWidget {
  final MaterialItem material; const _MetaStripW({required this.material});
  static String _fmt(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String)>[];
    if (material.fileSize != null) items.add((Icons.storage_rounded, _fmt(material.fileSize!)));
    if (material.pageCount != null) items.add((Icons.menu_book_rounded, '${material.pageCount} pages'));
    if (material.durationSeconds != null) { final s = material.durationSeconds!;
      items.add((Icons.timer_rounded, '${s ~/ 60}m ${s % 60}s')); }
    final d = material.uploadedAt;
    items.add((Icons.calendar_today_rounded, 'Uploaded ${d.day}/${d.month}/${d.year}'));
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 14, runSpacing: 5, children: items.map((it) =>
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(it.$1, size: 12, color: AppColors.textHint), const SizedBox(width: 4),
          Text(it.$2, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
        ])).toList());
  }
}

class _OBtn extends StatelessWidget {
  final String url; final bool big; const _OBtn({required this.url, this.big = false});

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (big) return ElevatedButton.icon(onPressed: _open,
        icon: const Icon(Icons.open_in_new_rounded, size: 14), label: const Text('Open'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
            foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
    return Material(color: AppColors.primary, borderRadius: BorderRadius.circular(7),
        child: InkWell(onTap: _open, borderRadius: BorderRadius.circular(7),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.open_in_new_rounded, size: 12, color: Colors.white),
                  SizedBox(width: 5),
                  Text('Open', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ]))));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TOPICS SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────
class _TopicsSidebarWidget extends StatelessWidget {
  final List<TopicItem> topics; final bool loading;
  final void Function(TopicItem) onTopicTap;
  final VoidCallback onAddManual, onGenerateAI;
  const _TopicsSidebarWidget({required this.topics, required this.loading,
      required this.onTopicTap, required this.onAddManual, required this.onGenerateAI});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // header
      Container(padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _K.div))),
          child: Row(children: [
            Container(width: 24, height: 24, decoration: BoxDecoration(
                color: _K.purpleSoft, borderRadius: BorderRadius.circular(7)),
                alignment: Alignment.center,
                child: const Icon(Icons.tag_rounded, size: 13, color: _K.purple)),
            const SizedBox(width: 8),
            const Text('Topics', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textTitle)),
            if (!loading && topics.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: _K.purpleSoft, borderRadius: BorderRadius.circular(10)),
                  child: Text('${topics.length}', style: const TextStyle(
                      fontSize: 10.5, fontWeight: FontWeight.w700, color: _K.purple))),
            ],
            const Spacer(),
            if (loading) const SizedBox(width: 13, height: 13,
                child: CircularProgressIndicator(strokeWidth: 1.5)),
          ])),

      // add buttons
      Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _K.div))),
        child: Row(children: [
          Expanded(child: _AddTopicBtnW(icon: Icons.edit_rounded, label: 'Manual',
              onTap: onAddManual, color: AppColors.primary, bg: _K.blueSoft)),
          const SizedBox(width: 6),
          Expanded(child: _AddTopicBtnW(icon: Icons.auto_awesome_rounded, label: 'AI',
              onTap: onGenerateAI, color: _K.purple, bg: _K.purpleSoft)),
        ]),
      ),

      // list
      Expanded(child: loading
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(strokeWidth: 2), SizedBox(height: 8),
              Text('Loading topics…', style: TextStyle(fontSize: 12, color: AppColors.textMuted))]))
          : topics.isEmpty
              ? _TopicsEmptyW(onAddManual: onAddManual, onGenerateAI: onGenerateAI)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: topics.length,
                  itemBuilder: (_, i) => _TopicItemW(
                      topic: topics[i], index: i, onTap: () => onTopicTap(topics[i])))),
    ]);
  }
}

class _AddTopicBtnW extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  final Color color, bg;
  const _AddTopicBtnW({required this.icon, required this.label, required this.onTap,
      required this.color, required this.bg});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap,
      borderRadius: BorderRadius.circular(7), child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 13, color: color), const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ])));
}

class _TopicsEmptyW extends StatelessWidget {
  final VoidCallback onAddManual, onGenerateAI;
  const _TopicsEmptyW({required this.onAddManual, required this.onGenerateAI});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(14),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(
          color: _K.purpleSoft, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.auto_awesome_rounded, size: 22, color: _K.purple)),
      const SizedBox(height: 10),
      const Text('No topics yet', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textTitle)),
      const SizedBox(height: 5),
      const Text('Add manually or let AI generate topics from this material.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.5)),
    ]));
}

class _TopicItemW extends StatelessWidget {
  final TopicItem topic; final int index; final VoidCallback onTap;
  const _TopicItemW({required this.topic, required this.index, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child: Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _K.div))),
    child: Row(children: [
      Container(width: 26, height: 26, decoration: BoxDecoration(
          color: _K.purpleSoft, borderRadius: BorderRadius.circular(7)),
          alignment: Alignment.center,
          child: Text('${index + 1}', style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, color: _K.purple))),
      const SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(topic.title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTitle)),
        if (topic.estimatedDurationMinutes != null)
          Text('~${topic.estimatedDurationMinutes}m',
              style: const TextStyle(fontSize: 10.5, color: AppColors.textHint)),
      ])),
      const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textHint),
    ])));
}

// ─────────────────────────────────────────────────────────────────────────────
//  TOPIC DRILL-DOWN PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _TopicPanelWidget extends StatelessWidget {
  final ModuleItem module; final MaterialItem material; final TopicItem topic;
  final bool canPop; final VoidCallback onBack, onGenerate;
  const _TopicPanelWidget({required this.module, required this.material,
      required this.topic, required this.canPop, required this.onBack, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Container(color: _K.bg, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // nav bar
      Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(color: Colors.white,
              border: Border(bottom: BorderSide(color: _K.div))),
          child: Row(children: [
            if (canPop) InkWell(onTap: onBack, borderRadius: BorderRadius.circular(7),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: _K.bg, borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: _K.div)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.arrow_back_ios_new_rounded, size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 5),
                      Text(material.displayTitle, style: const TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    ]))),
            if (canPop) const SizedBox(width: 10),
            const Icon(Icons.tag_rounded, size: 14, color: _K.purple), const SizedBox(width: 6),
            Expanded(child: Text(topic.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textTitle))),
          ])),

      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 6, children: [
            _Pill(l: 'TOPIC', fg: _K.purple, bg: _K.purpleSoft),
            if (topic.isRequired) _Pill(l: 'REQUIRED', fg: _K.blue, bg: _K.blueMid),
          ]),
          const SizedBox(height: 14),
          Text(topic.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
              color: AppColors.textTitle, height: 1.3)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.folder_outlined, size: 12, color: AppColors.textHint), const SizedBox(width: 5),
            Text(module.title, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 5),
                child: Text('›', style: TextStyle(fontSize: 12, color: AppColors.textHint))),
            const Icon(Icons.article_outlined, size: 12, color: AppColors.textHint), const SizedBox(width: 5),
            Expanded(child: Text(material.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
          ]),
          const SizedBox(height: 20),

          if (topic.description?.isNotEmpty == true) ...[
            _CardWidget(
              header: _HdrWidget(icon: Icons.description_outlined, iconColor: AppColors.primary, title: 'Description'),
              child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Text(topic.description!, style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted, height: 1.6)))),
            const SizedBox(height: 14),
          ],

          _CardWidget(
            header: _HdrWidget(icon: Icons.info_outline_rounded, iconColor: AppColors.primary, title: 'Details'),
            child: Column(children: [
              if (topic.estimatedDurationMinutes != null)
                _MRowW(icon: Icons.timer_outlined, label: 'Est. Duration', value: '${topic.estimatedDurationMinutes} min'),
              _MRowW(icon: Icons.sort_rounded, label: 'Order', value: '#${topic.orderIndex + 1}'),
              if (topic.parentTopicId != null)
                _MRowW(icon: Icons.account_tree_outlined, label: 'Sub-topic of', value: 'Topic #${topic.parentTopicId}'),
              _MRowW(icon: Icons.calendar_today_outlined, label: 'Created',
                  value: '${topic.createdAt.day}/${topic.createdAt.month}/${topic.createdAt.year}', isLast: true),
            ])),
          const SizedBox(height: 16),

          // generate CTA
          _CardWidget(noPadding: true, child: InkWell(onTap: onGenerate,
            borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(
                    color: _K.purpleSoft, borderRadius: BorderRadius.circular(11)),
                    child: const Icon(Icons.auto_awesome_rounded, size: 20, color: _K.purple)),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Generate Questions', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textTitle)),
                  SizedBox(height: 2),
                  Text('Create AI-generated questions for this topic.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ])),
                const SizedBox(width: 10),
                Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: _K.purple, borderRadius: BorderRadius.circular(8)),
                    child: const Text('Generate', style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white))),
              ])))),
        ]),
      )),
    ]));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DIALOGS
// ─────────────────────────────────────────────────────────────────────────────
class _ModuleDialogWidget extends StatelessWidget {
  final TextEditingController titleCtrl, descCtrl;
  const _ModuleDialogWidget({required this.titleCtrl, required this.descCtrl});
  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: const Row(children: [Icon(Icons.add_box_outlined, size: 18, color: AppColors.primary),
        SizedBox(width: 8), Text('New Module', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))]),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: titleCtrl, autofocus: true, decoration: InputDecoration(
          hintText: 'e.g. Lecture 1: Introduction', labelText: 'Title *',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
      const SizedBox(height: 12),
      TextField(controller: descCtrl, maxLines: 2, decoration: InputDecoration(
          hintText: 'Optional description', labelText: 'Description',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
          onPressed: () { if (titleCtrl.text.trim().isEmpty) return; Navigator.pop(context, true); },
          child: const Text('Create')),
    ]);
}

class _AddTopicDialogWidget extends StatelessWidget {
  final String moduleTitle;
  final TextEditingController titleCtrl, descCtrl;
  const _AddTopicDialogWidget({required this.moduleTitle, required this.titleCtrl, required this.descCtrl});
  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [Icon(Icons.tag_rounded, size: 17, color: _K.purple), SizedBox(width: 8),
          Text('Add Topic', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))]),
      const SizedBox(height: 3),
      Text('in "$moduleTitle"', style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w400)),
    ]),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.fromLTRB(12, 10, 12, 10), margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(color: _K.purpleSoft, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _K.purpleBd)),
          child: const Row(children: [Icon(Icons.auto_awesome_rounded, size: 15, color: _K.purple),
              SizedBox(width: 8),
              Expanded(child: Text('Tip: Use AI to auto-generate topics from your PDF.',
                  style: TextStyle(fontSize: 11.5, color: _K.purple, fontWeight: FontWeight.w500, height: 1.4)))])),
      TextField(controller: titleCtrl, autofocus: true, decoration: InputDecoration(
          hintText: 'e.g. Introduction to Cryptography', labelText: 'Topic Title *',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
      const SizedBox(height: 12),
      TextField(controller: descCtrl, maxLines: 3, decoration: InputDecoration(
          hintText: 'Optional description…', labelText: 'Description',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _K.purple, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
          onPressed: () { if (titleCtrl.text.trim().isEmpty) return; Navigator.pop(context, true); },
          child: const Text('Add Topic')),
    ]);
}

class _SimpleDialog extends StatelessWidget {
  final String title, confirm; final TextEditingController ctrl; final Color confirmColor;
  const _SimpleDialog({required this.title, required this.ctrl, required this.confirm, required this.confirmColor});
  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
    content: TextField(controller: ctrl, autofocus: true, decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
      ElevatedButton(onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
          child: Text(confirm)),
    ]);
}

class _ConfirmDialogWidget extends StatelessWidget {
  final String title, body, confirm; final Color confirmColor;
  const _ConfirmDialogWidget({required this.title, required this.body, required this.confirm, required this.confirmColor});
  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
    content: Text(body, style: const TextStyle(fontSize: 13.5, height: 1.5)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
      ElevatedButton(onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
          child: Text(confirm)),
    ]);
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED MICRO WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _CardWidget extends StatelessWidget {
  final Widget child; final _HdrWidget? header; final bool noPadding;
  const _CardWidget({required this.child, this.header, this.noPadding = false});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _K.div)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (header != null) ...[header!, const Divider(height: 1, color: _K.div)],
      child,
    ]));
}

class _HdrWidget extends StatelessWidget {
  final IconData icon; final Color iconColor; final String title;
  final String? badge; final Widget? trailing;
  const _HdrWidget({required this.icon, required this.iconColor, required this.title,
      this.badge, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
    child: Row(children: [
      Icon(icon, size: 14, color: iconColor), const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textTitle)),
      if (badge != null) ...[const SizedBox(width: 7),
        Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: _K.blueSoft, borderRadius: BorderRadius.circular(10)),
            child: Text(badge!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)))],
      const Spacer(), if (trailing != null) trailing!,
    ]));
}

class _SmBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap; final bool disabled;
  const _SmBtn({required this.icon, required this.label, required this.onTap, this.disabled = false});
  @override
  Widget build(BuildContext context) => InkWell(onTap: disabled ? null : onTap,
    borderRadius: BorderRadius.circular(7), child: Opacity(opacity: disabled ? 0.4 : 1.0,
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: _K.blueSoft, borderRadius: BorderRadius.circular(7)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: AppColors.primary), const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ]))));
}

class _Pill extends StatelessWidget {
  final String l; final Color fg, bg; const _Pill({required this.l, required this.fg, required this.bg});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(l, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.1)));
}

class _PRow extends StatelessWidget {
  final IconData icon; final Color iconBg, iconFg;
  final String label, sub; final VoidCallback? onTap; final bool danger;
  const _PRow({required this.icon, required this.iconBg, required this.iconFg,
      required this.label, required this.sub, this.onTap, this.danger = false});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child: Opacity(opacity: onTap == null ? 0.45 : 1.0,
    child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 14, 12), child: Row(children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: iconFg)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: danger ? const Color(0xFFEF4444) : AppColors.textTitle)),
        const SizedBox(height: 2),
        Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
      ])),
      Icon(Icons.chevron_right_rounded, size: 16,
          color: danger ? const Color(0xFFEF4444).withOpacity(0.4) : AppColors.textHint),
    ]))));
}

class _DivW extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: _K.div, indent: 16, endIndent: 16);
}

class _MRowW extends StatelessWidget {
  final IconData icon; final String label, value; final bool isLast;
  const _MRowW({required this.icon, required this.label, required this.value, this.isLast = false});
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 10), child: Row(children: [
      Icon(icon, size: 13, color: AppColors.textHint), const SizedBox(width: 8),
      SizedBox(width: 110, child: Text(label, style: const TextStyle(
          fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500))),
      Expanded(child: Text(value, style: const TextStyle(
          fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textTitle))),
    ])),
    if (!isLast) const Divider(height: 1, color: _K.div, indent: 16, endIndent: 16),
  ]);
}

class _TIcon extends StatelessWidget {
  final String type; final double size; const _TIcon({required this.type, this.size = 40});
  static const _m = {
    'video': (Icons.play_circle_filled_rounded, Color(0xFFDBEAFE), Color(0xFF2563EB)),
    'pdf'  : (Icons.picture_as_pdf_rounded,     Color(0xFFFEE2E2), Color(0xFFDC2626)),
    'quiz' : (Icons.quiz_rounded,                Color(0xFFF3E8FF), Color(0xFF9333EA)),
  };
  @override
  Widget build(BuildContext context) {
    final (ico, bg, fg) = _m[type] ??
        (Icons.insert_drive_file_rounded, const Color(0xFFF1F5F9), AppColors.textMuted);
    return Container(width: size, height: size,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
        child: Icon(ico, size: size * 0.48, color: fg));
  }
}

class _Dot extends StatelessWidget {
  final String status; const _Dot({required this.status});
  @override
  Widget build(BuildContext context) {
    final c = switch (status) {
      'ready'       => _K.green,
      'processing'  => _K.amber,
      'uploaded'    => _K.amber,
      'draft_upload'=> const Color(0xFF0369A1),
      'error'       => AppColors.dangerText,
      _             => AppColors.textHint,
    };
    return Container(width: 6, height: 6, margin: const EdgeInsets.only(left: 5),
        decoration: BoxDecoration(color: c, shape: BoxShape.circle));
  }
}

class _IBtn extends StatelessWidget {
  final IconData icon; final String tooltip; final VoidCallback onTap;
  const _IBtn({required this.icon, required this.tooltip, required this.onTap});
  @override
  Widget build(BuildContext context) => Tooltip(message: tooltip, child: InkWell(onTap: onTap,
      borderRadius: BorderRadius.circular(6), child: Padding(padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 14, color: AppColors.textHint))));
}

class _Btn extends StatelessWidget {
  final IconData icon; final String label; final bool primary; final VoidCallback? onTap;
  const _Btn({required this.icon, required this.label, this.primary = false, this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: primary ? AppColors.primary : Colors.transparent,
    borderRadius: BorderRadius.circular(8),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: primary ? null : BoxDecoration(
                border: Border.all(color: _K.div), borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 13, color: primary ? Colors.white : AppColors.textTitle),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700,
                  color: primary ? Colors.white : AppColors.textTitle)),
            ]))));
}
