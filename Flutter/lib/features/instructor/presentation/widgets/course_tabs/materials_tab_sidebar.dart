part of 'materials_tab.dart';

class _SidebarWidget extends StatelessWidget {
  final CourseDetailsState state;
  final Set<int>           expanded;
  final _Ctx?              active;
  final ScrollController   scroll;
  final int?               draggingModuleId;
  final void Function(ModuleItem) onModuleTap;
  final void Function(ModuleItem, MaterialItem) onMaterialTap;
  final void Function(ModuleItem, MaterialItem, TopicItem) onTopicTap;
  final void Function(ModuleItem) onAddMaterial;
  final void Function(int oldIndex, int newIndex) onModuleReorder;
  final void Function(int? moduleId) onDragChanged;
  final VoidCallback onAddModule;
  final VoidCallback onRefresh;

  const _SidebarWidget({
    required this.state,
    required this.expanded,
    required this.active,
    required this.scroll,
    required this.draggingModuleId,
    required this.onModuleTap,
    required this.onMaterialTap,
    required this.onTopicTap,
    required this.onAddMaterial,
    required this.onModuleReorder,
    required this.onDragChanged,
    required this.onAddModule,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 268,
      decoration: const BoxDecoration(
        color: _K.sidebar,
        border: Border(right: BorderSide(color: _K.div)),
      ),
      child: Column(
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: _K.div)),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_open_rounded, size: 14, color: AppColors.textHint),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'STRUCTURE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textHint,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                if (state.modulesLoading)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                _IBtn(icon: Icons.refresh_rounded, tooltip: 'Refresh', onTap: onRefresh),
              ],
            ),
          ),
          Expanded(
            child: state.modulesLoading && state.modules.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : state.modules.isEmpty
                    ? _SidebarEmpty(onAdd: onAddModule)
                    : Builder(
                        builder: (context) {
                          final modules = [...state.modules]
                            ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
                          return ReorderableListView.builder(
                            key: const PageStorageKey('course-materials-sidebar-scroll'),
                            buildDefaultDragHandles: false,
                            proxyDecorator: (child, index, animation) {
                              return AnimatedBuilder(
                                animation: animation,
                                builder: (context, _) {
                                  final t = Curves.easeOutCubic.transform(animation.value);
                                  return Transform.scale(
                                    scale: 1.0 + (0.02 * t),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary.withOpacity(0.14),
                                              blurRadius: 16,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: child,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            onReorderStart: (index) => onDragChanged(modules[index].id),
                            onReorderEnd: (_) => onDragChanged(null),
                            onReorder: onModuleReorder,
                            scrollController: scroll,
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                            itemCount: modules.length,
                            itemBuilder: (_, i) {
                              final m = modules[i];
                              return Padding(
                                key: ValueKey('module-${m.id}'),
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _ModuleRowWidget(
                                  module: m,
                                  isExpanded: expanded.contains(m.id),
                                  materials: state.materials[m.id] ?? [],
                                  loading: state.materialsLoading[m.id] ?? false,
                                  moduleTopics: state.topics[m.id] ?? [],
                                  active: active,
                                  isDragging: draggingModuleId == m.id,
                                  onModuleTap: () => onModuleTap(m),
                                  onMaterialTap: (mat) => onMaterialTap(m, mat),
                                  onTopicTap: (mat, t) => onTopicTap(m, mat, t),
                                  onAddMaterial: () => onAddMaterial(m),
                                  dragHandle: ReorderableDragStartListener(
                                    index: i,
                                    child: Tooltip(
                                      message: 'Drag to reorder',
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: Icon(
                                          Icons.drag_indicator_rounded,
                                          size: 16,
                                          color: draggingModuleId == m.id
                                              ? AppColors.primary
                                              : AppColors.textHint,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _K.div)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: onAddModule,
                icon: const Icon(Icons.add_rounded, size: 15),
                label: const Text(
                  'Add Module',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarEmpty extends StatelessWidget {
  final VoidCallback onAdd;
  const _SidebarEmpty({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_open_outlined, size: 28, color: AppColors.textHint),
              const SizedBox(height: 12),
              const Text(
                'No modules yet',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTitle,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create your first module to start building the course structure.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.45),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Create first module'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── Module row ──────────────────────────────────────────────────────────────
class _ModuleRowWidget extends StatelessWidget {
  final ModuleItem    module;
  final bool          isExpanded;
  final List<MaterialItem> materials;
  final bool          loading;
  final List<TopicItem> moduleTopics;
  final _Ctx?         active;
  final bool          isDragging;
  final Widget?       dragHandle;
  final VoidCallback  onModuleTap;
  final void Function(MaterialItem) onMaterialTap;
  final void Function(MaterialItem, TopicItem) onTopicTap;
  final VoidCallback  onAddMaterial;

  const _ModuleRowWidget({
    required this.module,
    required this.isExpanded,
    required this.materials,
    required this.loading,
    required this.moduleTopics,
    required this.active,
    required this.isDragging,
    required this.dragHandle,
    required this.onModuleTap,
    required this.onMaterialTap,
    required this.onTopicTap,
    required this.onAddMaterial,
  });

  bool get _isSel => active?.type == _CType.module && active?.module?.id == module.id;

  @override
  Widget build(BuildContext context) {
    final highlight = _isSel || isDragging;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          onTap: onModuleTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(8, 9, 8, 9),
            decoration: BoxDecoration(
              color: highlight ? _K.blueSoft : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: highlight ? AppColors.primary.withOpacity(0.18) : _K.div,
              ),
            ),
            child: Row(
              children: [
                dragHandle ?? const SizedBox(width: 22, height: 22),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.chevron_right_rounded,
                  size: 15,
                  color: highlight ? AppColors.primary : AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.folder_rounded,
                  size: 16,
                  color: highlight ? AppColors.primary : const Color(0xFFEA580C),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: highlight ? AppColors.primary : AppColors.textTitle,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${materials.length} material${materials.length == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: module.isPublished ? _K.greenSoft : _K.amberSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    module.isPublished ? 'Live' : 'Draft',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: module.isPublished ? _K.green : _K.amber,
                    ),
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                    onTap: onAddMaterial,
                    borderRadius: BorderRadius.circular(9),
                    child: const Padding(
                      padding: EdgeInsets.all(3),
                      child: Icon(Icons.add_rounded, size: 14, color: AppColors.textHint),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
          firstChild: const SizedBox.shrink(),
          secondChild: _buildChildren(),
        ),
      ],
    );
  }

  Widget _buildChildren() {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5)),
        ),
      );
    }
    if (materials.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(34, 8, 6, 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _K.div),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textHint),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No materials yet. Use the plus button to upload one.',
                style: TextStyle(fontSize: 11, color: AppColors.textHint, height: 1.35),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: materials.map((mat) {
        final matSel = active?.material?.id == mat.id &&
            (active?.type == _CType.material || active?.type == _CType.topic);
        final scopedTopics = moduleTopics.where((t) => t.materialId == mat.id).toList();
        return _MatRowWidget(
          material: mat,
          topics: scopedTopics,
          isSelected: matSel,
          active: active,
          onTap: () => onMaterialTap(mat),
          onTopicTap: (t) => onTopicTap(mat, t),
        );
      }).toList(),
    );
  }
}

class _MatRowWidget extends StatelessWidget {
  final MaterialItem material;
  final List<TopicItem> topics;
  final bool isSelected;
  final _Ctx? active;
  final VoidCallback onTap;
  final void Function(TopicItem) onTopicTap;
  const _MatRowWidget({required this.material, required this.topics, required this.isSelected, required this.active, required this.onTap, required this.onTopicTap});

  @override
  Widget build(BuildContext context) {
    const iconMap = {
      'video': (Icons.play_circle_outline_rounded, Color(0xFF2563EB)),
      'pdf'  : (Icons.picture_as_pdf_outlined,    Color(0xFFDC2626)),
      'quiz' : (Icons.quiz_outlined,               Color(0xFF7C3AED)),
    };
    final (ico, col) = iconMap[material.type] ?? (Icons.article_outlined, AppColors.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.fromLTRB(28, 1, 6, 1),
            padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
            decoration: BoxDecoration(
              color: isSelected ? _K.blueSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                Container(width: 1, height: 14, color: _K.div, margin: const EdgeInsets.only(right: 8)),
                Icon(ico, size: 13, color: isSelected ? AppColors.primary : col),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    material.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : const Color(0xFF334155),
                    ),
                  ),
                ),
                _Dot(status: material.status),
              ],
            ),
          ),
        ),
        ...topics.map((t) {
          final tSel = active?.type == _CType.topic && active?.topic?.id == t.id;
          return InkWell(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            onTap: () => onTopicTap(t),
            child: Container(
              margin: const EdgeInsets.fromLTRB(42, 0, 6, 0),
              padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
              decoration: BoxDecoration(
                color: tSel ? AppColors.primarySoft : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  Container(width: 1, height: 11, color: _K.div, margin: const EdgeInsets.only(right: 7)),
                  Icon(Icons.tag_rounded, size: 10, color: tSel ? AppColors.primary : AppColors.textHint),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: tSel ? FontWeight.w600 : FontWeight.w400,
                        color: tSel ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FOOTER
// ─────────────────────────────────────────────────────────────────────────────
class _FooterWidget extends StatelessWidget {
  final _Ctx ctx; final bool uploading; final bool canGenerate;
  final VoidCallback onUpload, onGenerate, onClose;
  const _FooterWidget({required this.ctx, required this.uploading, required this.canGenerate,
      required this.onUpload, required this.onGenerate, required this.onClose,});

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
              blurRadius: 16, offset: const Offset(0, -4),),],),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: _K.blueSoft, borderRadius: BorderRadius.circular(7)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(_icon, size: 13, color: AppColors.primary), const SizedBox(width: 6),
            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 200),
                child: Text(_label, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.primary,),),),
          ],),),
        const Spacer(),
        _Btn(icon: Icons.auto_awesome_rounded, label: canGenerate ? 'Generate Questions' : 'No content yet',
            primary: true, disabled: !canGenerate, onTap: canGenerate ? onGenerate : null,),
        const SizedBox(width: 8),
        InkWell(hoverColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent, overlayColor: const WidgetStatePropertyAll(Colors.transparent), onTap: onClose, borderRadius: BorderRadius.circular(6),
            child: const Padding(padding: EdgeInsets.all(7),
                child: Icon(Icons.close_rounded, size: 15, color: AppColors.textHint),),),
      ],),
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
  Widget build(BuildContext context) => Container(
        color: _K.bg,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _K.div),
              boxShadow: const [
                BoxShadow(color: Color(0x08000000), blurRadius: 18, offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: _K.blueSoft,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.folder_open_rounded, size: 36, color: AppColors.primary),
                ),
                const SizedBox(height: 18),
                const Text('Select a module or material', style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textTitle,),),
                const SizedBox(height: 8),
                const Text(
                  'Use the structure panel to explore your modules, reorder them by dragging, or open a material to manage topics and content.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _K.blueSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.drag_indicator_rounded, size: 16, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Tip: drag modules in the left panel to reorder them', style: TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                OutlinedButton.icon(onPressed: onCreate,
                    icon: const Icon(Icons.add_rounded, size: 15),
                    label: const Text('New Module'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),),),
              ],
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  MODULE PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _ModulePanelWidget extends StatelessWidget {
  final ModuleItem module;
  final List<MaterialItem> materials;
  final bool uploading;
  final double uploadProgress;
  final VoidCallback onUpload;
  final void Function(MaterialItem) onMaterialTap;
  final VoidCallback? onRename, onEditDescription, onTogglePublish, onChangePosition, onDelete, onShare;

  const _ModulePanelWidget({
    required this.module,
    required this.materials,
    required this.uploading,
    required this.uploadProgress,
    required this.onUpload,
    required this.onMaterialTap,
    this.onRename,
    this.onEditDescription,
    this.onTogglePublish,
    this.onChangePosition,
    this.onDelete,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final description = (module.description ?? '').trim();
    final hasDescription = description.isNotEmpty;
    final readyMaterials = materials.where((m) => m.status == 'ready').length;
    final processingMaterials = materials.where((m) => m.status != 'ready').length;

    return Container(
      color: _K.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 112),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ModuleHeroWidget(module: module, materialCount: materials.length),
            const SizedBox(height: 20),
            _ModuleInsightsStrip(
              materialCount: materials.length,
              readyMaterials: readyMaterials,
              processingMaterials: processingMaterials,
              sharedCount: module.sharedWithCourseIds.length,
            ),
            const SizedBox(height: 20),
            if (uploading) ...[
              _UploadProgressWidget(progress: uploadProgress),
              const SizedBox(height: 18),
            ],
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1160;
                final infoCard = _CardWidget(
                  header: const _HdrWidget(
                    icon: Icons.dashboard_customize_rounded,
                    iconColor: AppColors.primary,
                    title: 'Module overview',
                  ),
                  child: Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, cardConstraints) {
                          final stacked = cardConstraints.maxWidth < 560;
                          final positionTile = _MiniInfoTile(
                            icon: Icons.layers_rounded,
                            iconBg: _K.blueSoft,
                            iconFg: AppColors.primary,
                            label: 'Position',
                            value: '#${module.orderIndex + 1}',
                            caption: 'Current order in this course',
                          );
                          final visibilityTile = _MiniInfoTile(
                            icon: module.isPublished ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                            iconBg: module.isPublished ? _K.greenSoft : _K.amberSoft,
                            iconFg: module.isPublished ? _K.green : _K.amber,
                            label: 'Visibility',
                            value: module.isPublished ? 'Live' : 'Draft',
                            caption: module.isPublished ? 'Visible to students' : 'Hidden from students',
                          );

                          if (stacked) {
                            return Column(
                              children: [
                                positionTile,
                                const SizedBox(height: 14),
                                visibilityTile,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: positionTile),
                              const SizedBox(width: 14),
                              Expanded(child: visibilityTile),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _MiniInfoTile(
                        icon: Icons.notes_rounded,
                        iconBg: const Color(0xFFF8FAFC),
                        iconFg: AppColors.textMuted,
                        label: 'Description',
                        value: hasDescription ? description : 'No description added yet',
                        caption: hasDescription
                            ? 'Used to describe this module for instructors and learners.'
                            : 'Add a short summary to make this module easier to understand.',
                        multiline: true,
                      ),
                    ],
                  ),
                );

                final actionsCard = Column(
                  children: [
                    _CardWidget(
                      header: const _HdrWidget(
                        icon: Icons.auto_fix_high_rounded,
                        iconColor: AppColors.primary,
                        title: 'Manage module',
                      ),
                      child: Column(
                        children: [
                          _PRow(
                            icon: Icons.drive_file_rename_outline_rounded,
                            iconBg: _K.blueSoft,
                            iconFg: AppColors.primary,
                            label: 'Rename module',
                            sub: 'Update the module title shown across the course.',
                            onTap: onRename,
                          ),
                          _DivW(),
                          _PRow(
                            icon: Icons.notes_rounded,
                            iconBg: _K.blueSoft,
                            iconFg: AppColors.primary,
                            label: 'Edit description',
                            sub: hasDescription ? 'Refine the current summary and teaching context.' : 'Add a short summary for this module.',
                            onTap: onEditDescription,
                          ),
                          _DivW(),
                          _PRow(
                            icon: Icons.upload_file_rounded,
                            iconBg: AppColors.primarySoft,
                            iconFg: AppColors.primary,
                            label: 'Upload material',
                            sub: uploading ? 'Upload in progress…' : 'Add a PDF, video, or document to this module.',
                            onTap: uploading ? null : onUpload,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CardWidget(
                      header: const _HdrWidget(
                        icon: Icons.settings_suggest_rounded,
                        iconColor: AppColors.primary,
                        title: 'Distribution & status',
                      ),
                      child: Column(
                        children: [
                          _PRow(
                            icon: module.isPublished ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            iconBg: module.isPublished ? _K.amberSoft : _K.greenSoft,
                            iconFg: module.isPublished ? _K.amber : _K.green,
                            label: module.isPublished ? 'Unpublish module' : 'Publish module',
                            sub: module.isPublished ? 'Hide this module from students.' : 'Make this module visible to students.',
                            onTap: onTogglePublish,
                          ),
                          _DivW(),
                          _PRow(
                            icon: Icons.swap_vert_rounded,
                            iconBg: _K.greenSoft,
                            iconFg: _K.green,
                            label: 'Change position',
                            sub: 'Currently #${module.orderIndex + 1} in the course structure.',
                            onTap: onChangePosition,
                          ),
                          _DivW(),
                          _PRow(
                            icon: Icons.share_rounded,
                            iconBg: const Color(0xFFF0FDF4),
                            iconFg: const Color(0xFF16A34A),
                            label: 'Share with another course',
                            sub: module.sharedWithCourseIds.isEmpty
                                ? 'Not shared with any other course.'
                                : 'Shared with ${module.sharedWithCourseIds.length} course${module.sharedWithCourseIds.length == 1 ? '' : 's'}.',
                            onTap: onShare,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CardWidget(
                      header: const _HdrWidget(
                        icon: Icons.delete_outline_rounded,
                        iconColor: Color(0xFFEF4444),
                        title: 'Danger zone',
                      ),
                      child: _SectionNoteWidget(
                        tone: _SectionTone.danger,
                        title: 'Delete this module',
                        description: 'This permanently removes the module from the course. Only do this when you are sure the content is no longer needed.',
                        actionLabel: 'Delete module',
                        onTap: onDelete,
                      ),
                    ),
                  ],
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: infoCard),
                      const SizedBox(width: 20),
                      Expanded(flex: 5, child: actionsCard),
                    ],
                  );
                }

                return Column(
                  children: [
                    infoCard,
                    const SizedBox(height: 18),
                    actionsCard,
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _CardWidget(
              header: _HdrWidget(
                icon: Icons.folder_open_rounded,
                iconColor: AppColors.primary,
                title: 'Materials',
                badge: '${materials.length}',
                trailing: _SmBtn(
                  icon: Icons.upload_rounded,
                  label: 'Upload',
                  disabled: uploading,
                  onTap: onUpload,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All files and learning assets attached to this module appear here.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  if (materials.isEmpty)
                    _MatEmptyWidget(onUpload: onUpload)
                  else
                    Column(
                      children: materials.asMap().entries.map(
                        (e) => Padding(
                          padding: EdgeInsets.only(bottom: e.key == materials.length - 1 ? 0 : 10),
                          child: _ModuleMaterialCard(
                            material: e.value,
                            onTap: () => onMaterialTap(e.value),
                          ),
                        ),
                      ).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _HPill extends StatelessWidget {
  final String l;
  final Color c;
  const _HPill(this.l, this.c);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Text(
          l,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c),
        ),
      );
}

String _relativeDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  if (difference.inDays <= 0) return 'today';
  if (difference.inDays == 1) return '1 day ago';
  if (difference.inDays < 30) return '${difference.inDays} days ago';
  final months = (difference.inDays / 30).floor();
  if (months <= 1) return '1 month ago';
  if (months < 12) return '$months months ago';
  final years = (months / 12).floor();
  return years <= 1 ? '1 year ago' : '$years years ago';
}

class _UploadProgressWidget extends StatelessWidget {
  final double progress;
  const _UploadProgressWidget({required this.progress});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _K.div),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Uploading material…',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE2E8F0),
                color: AppColors.primary,
                minHeight: 4,
              ),
            ),
          ],
        ),
      );
}

class _ModuleHeroWidget extends StatelessWidget {
  final ModuleItem module;
  final int materialCount;
  const _ModuleHeroWidget({required this.module, required this.materialCount});

  @override
  Widget build(BuildContext context) {
    final description = (module.description ?? '').trim();
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF145CCB), Color(0xFF137FEC), Color(0xFF4CB5FF)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;
          final rightCard = Container(
            constraints: const BoxConstraints(minWidth: 180),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Module order', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.74))),
                const SizedBox(height: 8),
                Text('#${module.orderIndex + 1}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, height: 1.0)),
                const SizedBox(height: 14),
                Text('Updated ${_relativeDate(module.updatedAt)}', style: TextStyle(fontSize: 11.8, height: 1.45, color: Colors.white.withOpacity(0.8))),
              ],
            ),
          );

          final body = ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HPill(module.isPublished ? '● Live' : '● Draft', module.isPublished ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24)),
                    const _HPill('MODULE', Colors.white70),
                    _HPill('$materialCount material${materialCount == 1 ? '' : 's'}', Colors.white70),
                    if (module.isShared) const _HPill('Shared', Colors.white70),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  module.title,
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, height: 1.04),
                ),
                const SizedBox(height: 12),
                Text(
                  description.isNotEmpty
                      ? description
                      : 'This module groups related materials and learning assets inside the course structure.',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.86), height: 1.6),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [body, const SizedBox(height: 20), rightCard],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: body), const SizedBox(width: 24), rightCard],
          );
        },
      ),
    );
  }
}

class _ModuleInsightsStrip extends StatelessWidget {
  final int materialCount;
  final int readyMaterials;
  final int processingMaterials;
  final int sharedCount;

  const _ModuleInsightsStrip({required this.materialCount, required this.readyMaterials, required this.processingMaterials, required this.sharedCount});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.folder_copy_rounded, 'Materials', '$materialCount total', _K.blueSoft, AppColors.primary),
      (Icons.verified_rounded, 'Ready', '$readyMaterials available', _K.greenSoft, _K.green),
      (Icons.sync_rounded, 'Processing', '$processingMaterials pending', _K.amberSoft, _K.amber),
      (Icons.share_rounded, 'Shared', sharedCount == 0 ? 'Only in this course' : 'Shared with $sharedCount', const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 14.0;
        final itemWidth = constraints.maxWidth < 620
            ? constraints.maxWidth
            : (constraints.maxWidth < 1040
                ? (constraints.maxWidth - spacing) / 2
                : (constraints.maxWidth - (spacing * 3)) / 4);
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) => SizedBox(
            width: itemWidth,
            child: Container(
              constraints: const BoxConstraints(minHeight: 92),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _K.div),
                boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 3))],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: item.$4, borderRadius: BorderRadius.circular(13)),
                    child: Icon(item.$1, size: 20, color: item.$5),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.$2, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        Text(item.$3, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textTitle, height: 1.28)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),).toList(),
        );
      },
    );
  }
}

class _MiniInfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String label;
  final String value;
  final String caption;
  final bool multiline;

  const _MiniInfoTile({required this.icon, required this.iconBg, required this.iconFg, required this.label, required this.value, required this.caption, this.multiline = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _K.div),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: iconFg),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.2)),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: multiline ? null : 1,
                  overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textTitle, height: 1.45),
                ),
                const SizedBox(height: 4),
                Text(caption, style: const TextStyle(fontSize: 11.8, color: AppColors.textMuted, height: 1.55)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _SectionTone { normal, danger }

class _SectionNoteWidget extends StatelessWidget {
  final _SectionTone tone;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback? onTap;

  const _SectionNoteWidget({required this.tone, required this.title, required this.description, required this.actionLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDanger = tone == _SectionTone.danger;
    final bg = isDanger ? const Color(0xFFFFF5F5) : const Color(0xFFFAFBFD);
    final border = isDanger ? const Color(0xFFFECACA) : _K.div;
    final fg = isDanger ? const Color(0xFFDC2626) : AppColors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final textBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isDanger ? const Color(0xFFB91C1C) : AppColors.textTitle)),
              const SizedBox(height: 6),
              Text(description, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.45)),
            ],
          );
          final button = OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: fg,
              side: BorderSide(color: fg),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(actionLabel),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [textBlock, const SizedBox(height: 14), button],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: textBlock), const SizedBox(width: 14), button],
          );
        },
      ),
    );
  }
}

class _MatEmptyWidget extends StatelessWidget {
  final VoidCallback onUpload;
  const _MatEmptyWidget({required this.onUpload});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFBFD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _K.div),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: _K.blueSoft, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.upload_file_outlined, size: 24, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              const Text('No materials yet', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textTitle)),
              const SizedBox(height: 5),
              const Text('Upload a PDF, video, or document to turn this module into usable learning content.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.5)),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.upload_rounded, size: 14),
                label: const Text('Upload material'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ModuleMaterialCard extends StatelessWidget {
  final MaterialItem material;
  final VoidCallback onTap;
  const _ModuleMaterialCard({required this.material, required this.onTap});

  static const _colors = {
    'video': (Icons.play_circle_filled_rounded, Color(0xFFDBEAFE), Color(0xFF2563EB), 'Video'),
    'pdf': (Icons.picture_as_pdf_rounded, Color(0xFFFEE2E2), Color(0xFFDC2626), 'PDF'),
    'quiz': (Icons.quiz_rounded, Color(0xFFF3E8FF), Color(0xFF9333EA), 'Quiz'),
  };
  static const _status = {
    'ready': ('Ready', Color(0xFFDCFCE7), Color(0xFF16A34A)),
    'processing': ('Processing', Color(0xFFFEF3C7), Color(0xFFD97706)),
    'uploaded': ('Processing', Color(0xFFFEF3C7), Color(0xFFD97706)),
    'draft_upload': ('Uploading', Color(0xFFE0F2FE), Color(0xFF0369A1)),
    'error': ('Error', Color(0xFFFEF2F2), Color(0xFFDC2626)),
  };

  @override
  Widget build(BuildContext context) {
    final (ico, ib, ic, typeLabel) = _colors[material.type] ??
        (Icons.insert_drive_file_rounded, const Color(0xFFF1F5F9), AppColors.textMuted, material.type.toUpperCase());
    final (sl, sb, sf) = _status[material.status] ??
        (material.status, const Color(0xFFF1F5F9), AppColors.textMuted);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _K.div),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: ib, borderRadius: BorderRadius.circular(12)),
              child: Icon(ico, size: 22, color: ic),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(material.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textTitle, height: 1.3)),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Text(typeLabel, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textHint, letterSpacing: 0.4)),
                      if (material.pageCount != null)
                        Text('${material.pageCount} pages', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(color: sb, borderRadius: BorderRadius.circular(999)),
              child: Text(sl, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: sf)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
//  MATERIAL PANEL
// ─────────────────────────────────────────────────────────────────────────────
