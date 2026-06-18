part of 'materials_tab.dart';

class _SidebarWidget extends StatelessWidget {
  final double             width;
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
  final VoidCallback onToggleCollapsed;
  final bool refreshing;
  final bool selectionMode;
  final _TreeSelectionState treeSelection;
  final VoidCallback onToggleSelectionMode;
  final VoidCallback onClearSelection;
  final void Function(ModuleItem module, bool checked) onModuleCheckChanged;
  final void Function(ModuleItem module, MaterialItem material, bool checked) onMaterialCheckChanged;
  final void Function(ModuleItem module, MaterialItem material, TopicItem topic, bool checked) onTopicCheckChanged;
  final Set<int> expandedMaterialIds;
  final Set<int> expandedTopicIds;
  final void Function(MaterialItem material) onToggleMaterialExpanded;
  final void Function(TopicItem topic) onToggleTopicExpanded;

  const _SidebarWidget({
    this.width = 268,
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
    required this.onToggleCollapsed,
    required this.refreshing,
    required this.selectionMode,
    required this.treeSelection,
    required this.onToggleSelectionMode,
    required this.onClearSelection,
    required this.onModuleCheckChanged,
    required this.onMaterialCheckChanged,
    required this.onTopicCheckChanged,
    required this.expandedMaterialIds,
    required this.expandedTopicIds,
    required this.onToggleMaterialExpanded,
    required this.onToggleTopicExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final compactHeader = width < 302;
    final treeBusy = state.modulesLoading || refreshing;

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: _K.sidebar,
        border: Border(right: BorderSide(color: _K.div)),
      ),
      child: Column(
        children: [
          Container(
            height: 42,
            padding: EdgeInsets.symmetric(horizontal: selectionMode ? 10 : 12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: const Border(bottom: BorderSide(color: _K.div)),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_open_rounded, size: 14, color: AppColors.textHint),
                const SizedBox(width: 7),
                Expanded(
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
                if (selectionMode && !treeSelection.isEmpty) ...[
                  InkWell(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                    onTap: onClearSelection,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: _K.blueSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${treeSelection.totalCount}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                InkWell(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                  onTap: onToggleSelectionMode,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: compactHeader ? 6 : 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: selectionMode ? _K.blueSoft : AppColors.surfaceBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selectionMode ? AppColors.primary.withOpacity(0.18) : _K.div,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selectionMode ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          size: 12,
                          color: selectionMode ? AppColors.primary : AppColors.textHint,
                        ),
                        if (!compactHeader) ...[
                          const SizedBox(width: 4),
                          Text(
                            'Select',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: selectionMode ? AppColors.primary : AppColors.textHint,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                if (treeBusy)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                  )
                else
                  _IBtn(icon: Icons.refresh_rounded, tooltip: 'Refresh', onTap: onRefresh),
                _IBtn(
                  icon: Icons.keyboard_double_arrow_left_rounded,
                  tooltip: 'Collapse structure',
                  onTap: onToggleCollapsed,
                ),
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
                            padding: EdgeInsets.fromLTRB(selectionMode ? 6 : 8, 8, selectionMode ? 6 : 8, 10),
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
                                  selectionMode: selectionMode,
                                  treeSelection: treeSelection,
                                  onModuleCheckChanged: (checked) => onModuleCheckChanged(m, checked),
                                  onMaterialCheckChanged: (material, checked) => onMaterialCheckChanged(m, material, checked),
                                  onTopicCheckChanged: (material, topic, checked) => onTopicCheckChanged(m, material, topic, checked),
                                  expandedMaterialIds: expandedMaterialIds,
                                  expandedTopicIds: expandedTopicIds,
                                  onToggleMaterialExpanded: onToggleMaterialExpanded,
                                  onToggleTopicExpanded: onToggleTopicExpanded,
                                  dragHandle: ReorderableDragStartListener(
                                    index: i,
                                    child: Tooltip(
                                      message: 'Drag to reorder',
                                      child: SizedBox(
                                        width: selectionMode ? 18 : 22,
                                        height: selectionMode ? 18 : 22,
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

class _ResizableSidebarHost extends StatelessWidget {
  static const double _handleWidth = 10.0;

  final double width;
  final double minWidth;
  final double maxWidth;
  final bool isResizing;
  final Widget child;
  final VoidCallback onResizeStart;
  final void Function(double delta) onResize;
  final VoidCallback onResizeEnd;

  const _ResizableSidebarHost({
    required this.width,
    required this.minWidth,
    required this.maxWidth,
    required this.isResizing,
    required this.child,
    required this.onResizeStart,
    required this.onResize,
    required this.onResizeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width + _handleWidth,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: width, child: child),
          MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (_) => onResizeStart(),
              onHorizontalDragUpdate: (details) => onResize(details.delta.dx),
              onHorizontalDragEnd: (_) => onResizeEnd(),
              onHorizontalDragCancel: onResizeEnd,
              child: Container(
                width: _handleWidth,
                color: isResizing
                    ? AppColors.primary.withOpacity(0.08)
                    : _K.bg,
                child: Center(
                  child: Container(
                    width: 3,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isResizing
                          ? AppColors.primary.withOpacity(0.65)
                          : AppColors.textHint.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsedSidebarRail extends StatelessWidget {
  static const double railWidth = 52.0;

  final double width;
  final int modulesCount;
  final bool loading;
  final VoidCallback onExpand;
  final VoidCallback onAddModule;
  final VoidCallback onRefresh;

  const _CollapsedSidebarRail({
    this.width = railWidth,
    required this.modulesCount,
    required this.loading,
    required this.onExpand,
    required this.onAddModule,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: _K.sidebar,
        border: Border(right: BorderSide(color: _K.div)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Center(
              child: _RailButton(
                icon: Icons.keyboard_double_arrow_right_rounded,
                tooltip: 'Expand structure',
                onTap: onExpand,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _K.div),
          const SizedBox(height: 10),
          _RailButton(
            icon: Icons.account_tree_outlined,
            tooltip: '$modulesCount modules',
            onTap: onExpand,
            badge: loading ? null : modulesCount.toString(),
          ),
          const SizedBox(height: 8),
          _RailButton(icon: Icons.add_rounded, tooltip: 'Add module', onTap: onAddModule),
          const SizedBox(height: 8),
          _RailButton(icon: loading ? Icons.sync_rounded : Icons.refresh_rounded, tooltip: 'Refresh', onTap: onRefresh),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                'STRUCTURE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsedSidebarBar extends StatelessWidget {
  final int modulesCount;
  final bool loading;
  final VoidCallback onExpand;
  final VoidCallback onAddModule;
  final VoidCallback onRefresh;

  const _CollapsedSidebarBar({
    required this.modulesCount,
    required this.loading,
    required this.onExpand,
    required this.onAddModule,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: const Border(bottom: BorderSide(color: _K.div)),
      ),
      child: Row(
        children: [
          _RailButton(
            icon: Icons.keyboard_double_arrow_down_rounded,
            tooltip: 'Expand structure',
            onTap: onExpand,
            compact: true,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              loading ? 'Loading structure...' : 'Structure hidden · $modulesCount modules',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textTitle,
              ),
            ),
          ),
          _RailButton(icon: Icons.add_rounded, tooltip: 'Add module', onTap: onAddModule, compact: true),
          const SizedBox(width: 6),
          _RailButton(icon: loading ? Icons.sync_rounded : Icons.refresh_rounded, tooltip: 'Refresh', onTap: onRefresh, compact: true),
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final String? badge;
  final bool compact;

  const _RailButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 34.0;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: _K.div),
              ),
              child: Icon(icon, size: compact ? 15 : 16, color: AppColors.textMuted),
            ),
            if (badge != null)
              Positioned(
                right: -5,
                top: -5,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  height: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _K.sidebar, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


List<TopicItem> _rootTopicsForMaterial(List<TopicItem> topics) {
  final roots = topics.where((t) => t.parentTopicId == null).toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  return roots;
}

List<TopicItem> _childTopicsForParent(List<TopicItem> topics, int parentTopicId) {
  final children = topics.where((t) => t.parentTopicId == parentTopicId).toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  return children;
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
              Icon(Icons.folder_open_outlined, size: 28, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text(
                'No modules yet',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTitle,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create your first module to start building the course structure.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.45),
              ),
              const SizedBox(height: 12),
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
  final ModuleItem module;
  final bool isExpanded;
  final List<MaterialItem> materials;
  final bool loading;
  final List<TopicItem> moduleTopics;
  final _Ctx? active;
  final bool isDragging;
  final Widget? dragHandle;
  final VoidCallback onModuleTap;
  final void Function(MaterialItem) onMaterialTap;
  final void Function(MaterialItem, TopicItem) onTopicTap;
  final VoidCallback onAddMaterial;
  final bool selectionMode;
  final _TreeSelectionState treeSelection;
  final ValueChanged<bool> onModuleCheckChanged;
  final void Function(MaterialItem material, bool checked) onMaterialCheckChanged;
  final void Function(MaterialItem material, TopicItem topic, bool checked) onTopicCheckChanged;
  final Set<int> expandedMaterialIds;
  final Set<int> expandedTopicIds;
  final void Function(MaterialItem material) onToggleMaterialExpanded;
  final void Function(TopicItem topic) onToggleTopicExpanded;

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
    required this.selectionMode,
    required this.treeSelection,
    required this.onModuleCheckChanged,
    required this.onMaterialCheckChanged,
    required this.onTopicCheckChanged,
    required this.expandedMaterialIds,
    required this.expandedTopicIds,
    required this.onToggleMaterialExpanded,
    required this.onToggleTopicExpanded,
  });

  bool get _isSel => active?.type == _CType.module && active?.module?.id == module.id;

  Set<int> _selectableTopicIdsForTopic(TopicItem topic, List<TopicItem> allTopics) {
    final children = _childTopicsForParent(allTopics, topic.id);
    if (children.isEmpty) {
      return <int>{topic.id};
    }

    final ids = <int>{};
    for (final child in children) {
      ids.addAll(_selectableTopicIdsForTopic(child, allTopics));
    }
    return ids;
  }

  Set<int> _selectableTopicIdsForMaterial(MaterialItem material) {
    final materialTopics = moduleTopics.where((topic) => topic.materialId == material.id).toList();
    final roots = _rootTopicsForMaterial(materialTopics);
    final ids = <int>{};
    for (final root in roots) {
      ids.addAll(_selectableTopicIdsForTopic(root, materialTopics));
    }
    return ids;
  }

  bool? _moduleCheckValue() {
    final selectableTopicIds = <int>{};
    for (final material in materials) {
      selectableTopicIds.addAll(_selectableTopicIdsForMaterial(material));
    }

    if (selectableTopicIds.isEmpty) return false;

    final selectedCount = selectableTopicIds.where(treeSelection.topicIds.contains).length;
    if (selectedCount == 0) return false;
    if (selectedCount == selectableTopicIds.length) return true;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _isSel || isDragging;
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
            margin: EdgeInsets.fromLTRB(selectionMode ? 3 : 6, 0, selectionMode ? 3 : 6, 2),
            padding: EdgeInsets.fromLTRB(selectionMode ? 3 : 6, selectionMode ? 5 : 7, selectionMode ? 4 : 6, selectionMode ? 5 : 7),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFF7FAFF) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? const Color(0xFFD5E5FF) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                dragHandle ?? const SizedBox(width: 18, height: 18),
                if (selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: Transform.scale(
                        scale: .82,
                        child: Checkbox(
                          value: _moduleCheckValue(),
                          tristate: true,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (value) => onModuleCheckChanged(value ?? false),
                        ),
                      ),
                    ),
                  ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.chevron_right_rounded,
                  size: 14,
                  color: const Color(0xFF94A3B8),
                ),
                SizedBox(width: selectionMode ? 3 : 4),
                Icon(
                  Icons.folder_rounded,
                  size: 14,
                  color: selected ? AppColors.primary : const Color(0xFFEAB308),
                ),
                SizedBox(width: selectionMode ? 5 : 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.2,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: selected ? AppColors.primary : AppColors.textTitle,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${materials.length} material${materials.length == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 10.2, color: Color(0xFF94A3B8), height: 1.1),
                      ),
                    ],
                  ),
                ),
                if (module.isPublished)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                if (isExpanded) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                    onTap: onAddMaterial,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.add_rounded, size: 14, color: Color(0xFF94A3B8)),
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
        margin: EdgeInsets.fromLTRB(selectionMode ? 26 : 34, 6, 6, 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _K.div),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textHint),
            const SizedBox(width: 8),
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
    return Padding(
      padding: EdgeInsets.only(left: selectionMode ? 18 : 26),
      child: Column(
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
            selectionMode: selectionMode,
            treeSelection: treeSelection,
            onCheckChanged: (checked) => onMaterialCheckChanged(mat, checked),
            onTopicCheckChanged: (topic, checked) => onTopicCheckChanged(mat, topic, checked),
            isExpanded: expandedMaterialIds.contains(mat.id),
            expandedTopicIds: expandedTopicIds,
            onToggleExpanded: () => onToggleMaterialExpanded(mat),
            onToggleTopicExpanded: onToggleTopicExpanded,
          );
        }).toList(),
      ),
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
  final bool selectionMode;
  final _TreeSelectionState treeSelection;
  final ValueChanged<bool> onCheckChanged;
  final void Function(TopicItem topic, bool checked) onTopicCheckChanged;
  final bool isExpanded;
  final Set<int> expandedTopicIds;
  final VoidCallback onToggleExpanded;
  final void Function(TopicItem topic) onToggleTopicExpanded;

  const _MatRowWidget({
    required this.material,
    required this.topics,
    required this.isSelected,
    required this.active,
    required this.onTap,
    required this.onTopicTap,
    required this.selectionMode,
    required this.treeSelection,
    required this.onCheckChanged,
    required this.onTopicCheckChanged,
    required this.isExpanded,
    required this.expandedTopicIds,
    required this.onToggleExpanded,
    required this.onToggleTopicExpanded,
  });

  Set<int> _selectableTopicIdsForTopic(TopicItem topic) {
    final children = _childTopicsForParent(topics, topic.id);
    if (children.isEmpty) {
      return <int>{topic.id};
    }

    final ids = <int>{};
    for (final child in children) {
      ids.addAll(_selectableTopicIdsForTopic(child));
    }
    return ids;
  }

  Set<int> _selectableTopicIdsForMaterial() {
    final roots = _rootTopicsForMaterial(topics);
    final ids = <int>{};
    for (final root in roots) {
      ids.addAll(_selectableTopicIdsForTopic(root));
    }
    return ids;
  }

  bool? _materialCheckValue() {
    final selectableTopicIds = _selectableTopicIdsForMaterial();
    if (selectableTopicIds.isEmpty) return false;

    final selectedCount = selectableTopicIds.where(treeSelection.topicIds.contains).length;
    if (selectedCount == 0) return false;
    if (selectedCount == selectableTopicIds.length) return true;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const iconMap = {
      'video': (Icons.play_circle_outline_rounded, Color(0xFF2563EB)),
      'pdf': (Icons.picture_as_pdf_outlined, Color(0xFFEF4444)),
      'quiz': (Icons.quiz_outlined, Color(0xFF7C3AED)),
    };
    final (ico, col) = iconMap[material.type] ?? (Icons.article_outlined, AppColors.textMuted);
    final roots = _rootTopicsForMaterial(topics);

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
            margin: EdgeInsets.fromLTRB(0, 1, selectionMode ? 2 : 4, 1),
            padding: EdgeInsets.fromLTRB(selectionMode ? 5 : 8, selectionMode ? 5 : 7, selectionMode ? 4 : 6, selectionMode ? 5 : 7),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF7FAFF) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFFD5E5FF) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                if (selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: Transform.scale(
                        scale: .82,
                        child: Checkbox(
                          value: _materialCheckValue(),
                          tristate: true,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (value) => onCheckChanged(value ?? false),
                        ),
                      ),
                    ),
                  ),
                InkWell(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                  onTap: roots.isNotEmpty ? onToggleExpanded : null,
                  child: Icon(
                    roots.isEmpty
                        ? Icons.remove_rounded
                        : (isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.chevron_right_rounded),
                    size: 13,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: col.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(ico, size: 10, color: col),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.1,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? AppColors.primary : const Color(0xFF334155),
                        ),
                      ),
                      if (topics.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${roots.length} topic${roots.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), height: 1.1),
                        ),
                      ],
                    ],
                  ),
                ),
                _Dot(status: material.status),
              ],
            ),
          ),
        ),
        if (roots.isNotEmpty && isExpanded)
          Padding(
            padding: EdgeInsets.only(left: selectionMode ? 14 : 22),
            child: Column(
              children: roots
                  .map(
                    (topic) => _SidebarTopicNode(
                      topic: topic,
                      allTopics: topics,
                      active: active,
                      depth: 0,
                      onTap: onTopicTap,
                      selectionMode: selectionMode,
                      treeSelection: treeSelection,
                      onTopicCheckChanged: onTopicCheckChanged,
                      isExpanded: expandedTopicIds.contains(topic.id),
                      onToggleExpanded: () => onToggleTopicExpanded(topic),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _SidebarTopicNode extends StatelessWidget {
  final TopicItem topic;
  final List<TopicItem> allTopics;
  final _Ctx? active;
  final int depth;
  final ValueChanged<TopicItem> onTap;
  final bool selectionMode;
  final _TreeSelectionState treeSelection;
  final void Function(TopicItem topic, bool checked) onTopicCheckChanged;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  const _SidebarTopicNode({
    required this.topic,
    required this.allTopics,
    required this.active,
    required this.depth,
    required this.onTap,
    required this.selectionMode,
    required this.treeSelection,
    required this.onTopicCheckChanged,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  Set<int> _selectableTopicIdsForTopic(TopicItem item) {
    final children = _childTopicsForParent(allTopics, item.id);
    if (children.isEmpty) {
      return <int>{item.id};
    }

    final ids = <int>{};
    for (final child in children) {
      ids.addAll(_selectableTopicIdsForTopic(child));
    }
    return ids;
  }

  bool? _topicCheckValue() {
    final selectableTopicIds = _selectableTopicIdsForTopic(topic);
    if (selectableTopicIds.isEmpty) return false;

    final selectedCount = selectableTopicIds.where(treeSelection.topicIds.contains).length;
    if (selectedCount == 0) return false;
    if (selectedCount == selectableTopicIds.length) return true;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = active?.type == _CType.topic && active?.topic?.id == topic.id;
    final children = depth == 0 ? _childTopicsForParent(allTopics, topic.id) : const <TopicItem>[];
    final isRootTopic = depth == 0;
    final baseIndent = selectionMode
        ? (isRootTopic ? 4.0 : 22.0)
        : (isRootTopic ? 10.0 : 34.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.fromLTRB(baseIndent, 0, 4, 0),
          child: Stack(
            children: [
              if (isRootTopic)
                Positioned(
                  left: 6,
                  top: 0,
                  bottom: children.isNotEmpty && isExpanded ? -2 : 14,
                  child: Container(width: 1, color: AppColors.border),
                )
              else
                Positioned(
                  left: 6,
                  top: 0,
                  bottom: 14,
                  child: Container(width: 1, color: AppColors.border),
                ),
              Positioned(
                left: 6,
                top: 14,
                child: Container(width: 10, height: 1, color: AppColors.border),
              ),
              InkWell(
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                onTap: () => onTap(topic),
                child: Container(
                  margin: const EdgeInsets.only(left: 16),
                  padding: EdgeInsets.fromLTRB(selectionMode ? 4 : 6, 5, selectionMode ? 4 : 6, 5),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primarySoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: selected ? const Color(0xFFD5E5FF) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (selectionMode)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: Transform.scale(
                              scale: .82,
                              child: Checkbox(
                                value: _topicCheckValue(),
                                tristate: true,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (value) => onTopicCheckChanged(topic, value ?? false),
                              ),
                            ),
                          ),
                        ),
                      if (isRootTopic)
                        InkWell(
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                          onTap: children.isNotEmpty ? onToggleExpanded : null,
                          child: Icon(
                            children.isEmpty
                                ? Icons.remove_rounded
                                : (isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.chevron_right_rounded),
                            size: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        )
                      else
                        const SizedBox(width: 12, height: 12),
                      const SizedBox(width: 4),
                      Icon(
                        isRootTopic ? Icons.topic_outlined : Icons.subdirectory_arrow_right_rounded,
                        size: isRootTopic ? 12 : 11,
                        color: selected ? AppColors.primary : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          topic.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isRootTopic ? 11.2 : 10.7,
                            height: 1.15,
                            fontWeight: selected ? FontWeight.w700 : (isRootTopic ? FontWeight.w600 : FontWeight.w500),
                            color: selected ? AppColors.primary : (isRootTopic ? const Color(0xFF334155) : AppColors.textMuted),
                          ),
                        ),
                      ),
                      if (isRootTopic && children.isNotEmpty)
                        Text(
                          '${children.length}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isRootTopic && isExpanded)
          for (final child in children)
            _SidebarTopicNode(
              topic: child,
              allTopics: allTopics,
              active: active,
              depth: depth + 1,
              onTap: onTap,
              selectionMode: selectionMode,
              treeSelection: treeSelection,
              onTopicCheckChanged: onTopicCheckChanged,
              isExpanded: false,
              onToggleExpanded: () {},
            ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FOOTER
// ─────────────────────────────────────────────────────────────────────────────
class _FooterWidget extends StatelessWidget {
  final _Ctx ctx; final bool uploading; final bool canGenerate;
  final int? selectionCount;
  final VoidCallback onUpload, onGenerate, onClose;
  const _FooterWidget({required this.ctx, required this.uploading, required this.canGenerate,
      this.selectionCount,
      required this.onUpload, required this.onGenerate, required this.onClose,});

  bool get _showSelectionLabel => (selectionCount ?? 0) > 0;
  String get _label => _showSelectionLabel
      ? '${selectionCount!} selected'
      : switch (ctx.type) {
          _CType.module   => ctx.module?.title ?? 'Module',
          _CType.material => ctx.material?.displayTitle ?? 'Material',
          _CType.topic    => ctx.topic?.title ?? 'Topic',
        };
  IconData get _icon => _showSelectionLabel
      ? Icons.checklist_rounded
      : switch (ctx.type) {
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
            child: Padding(padding: const EdgeInsets.all(7),
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
              boxShadow: [
                const BoxShadow(color: Color(0x08000000), blurRadius: 18, offset: Offset(0, 8)),
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
                Text('Select a module or material', style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textTitle,),),
                const SizedBox(height: 8),
                Text(
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
    final readyMaterials = materials.where((m) => m.status == 'ready').length;
    final processingMaterials = materials.length - readyMaterials;
    final orderedMaterials = List<MaterialItem>.from(materials);

    return Container(
      color: const Color(0xFFF5F7FA),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final horizontalPadding = compact ? 16.0 : 24.0;
          const topPadding = 22.0;
          const bottomPadding = 104.0;
          final viewportHeight = constraints.hasBoundedHeight
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height;
          final contentMinHeight = (viewportHeight - topPadding - bottomPadding)
              .clamp(0.0, double.infinity)
              .toDouble();

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(horizontalPadding, topPadding, horizontalPadding, bottomPadding),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1240, minHeight: contentMinHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ModuleBlueHeader(
                      module: module,
                      description: description,
                      materialCount: orderedMaterials.length,
                      readyMaterials: readyMaterials,
                      processingMaterials: processingMaterials,
                      onUpload: uploading ? null : onUpload,
                      onRename: onRename,
                      onEditDescription: onEditDescription,
                      onTogglePublish: onTogglePublish,
                      onShare: onShare,
                    ),
                    if (uploading) ...[
                      const SizedBox(height: 12),
                      _UploadProgressWidget(progress: uploadProgress),
                    ],
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, bodyConstraints) {
                        final wideBody = bodyConstraints.maxWidth >= 980;
                        final materialsBoard = _ModuleMaterialsBoard(
                          materials: orderedMaterials,
                          onUpload: uploading ? null : onUpload,
                          onMaterialTap: onMaterialTap,
                        );
                        final adminPanel = _ModuleAdminPanel(
                          onChangePosition: onChangePosition,
                          onDelete: onDelete,
                        );

                        if (!wideBody) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              materialsBoard,
                              const SizedBox(height: 16),
                              adminPanel,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: materialsBoard),
                            const SizedBox(width: 18),
                            SizedBox(width: 320, child: adminPanel),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
class _ModuleHeaderDeck extends StatelessWidget {
  final ModuleItem module;
  final String description;
  final int materialCount;
  final int readyMaterials;
  final int processingMaterials;
  final double completion;
  final bool uploading;
  final VoidCallback? onUpload;
  final VoidCallback? onRename;
  final VoidCallback? onEditDescription;
  final VoidCallback? onTogglePublish;
  final VoidCallback? onShare;

  const _ModuleHeaderDeck({
    required this.module,
    required this.description,
    required this.materialCount,
    required this.readyMaterials,
    required this.processingMaterials,
    required this.completion,
    required this.uploading,
    required this.onUpload,
    required this.onRename,
    required this.onEditDescription,
    required this.onTogglePublish,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final title = module.title.trim().isEmpty ? 'Untitled module' : module.title.trim();
    final summary = description.isEmpty
        ? 'Add a short instructor summary so students understand the module goal before opening the learning files.'
        : description;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E7EF)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x080F172A), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 790;
          final titleArea = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.layers_rounded, size: 17, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Module workspace', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .6, color: AppColors.textHint)),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            _ModuleFlatBadge(
                              label: module.isPublished ? 'Published' : 'Draft',
                              icon: module.isPublished ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                              fg: module.isPublished ? AppColors.successText : const Color(0xFFD97706),
                              bg: module.isPublished ? AppColors.successBg : const Color(0xFFFFF7E6),
                            ),
                            _ModuleFlatBadge(label: 'Position ${module.orderIndex + 1}', icon: Icons.format_list_numbered_rounded, fg: AppColors.primary, bg: AppColors.primarySoft),
                            if (module.isShared) _ModuleFlatBadge(label: 'Shared', icon: Icons.ios_share_rounded, fg: AppColors.textMuted, bg: const Color(0xFFF8FAFC)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                maxLines: compact ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: compact ? 25 : 31, height: 1.08, letterSpacing: -.45, fontWeight: FontWeight.w900, color: AppColors.textTitle),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Text(
                  summary,
                  maxLines: compact ? 5 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, height: 1.5, fontWeight: FontWeight.w600, color: description.isEmpty ? AppColors.textHint : AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 16),
              _ModuleActionStrip(
                onUpload: onUpload,
                onRename: onRename,
                onEditDescription: onEditDescription,
                onTogglePublish: onTogglePublish,
                onShare: onShare,
                isPublished: module.isPublished,
                hasDescription: description.isNotEmpty,
              ),
            ],
          );

          final progressCard = _ModuleWorkspaceProgress(
            materialCount: materialCount,
            readyMaterials: readyMaterials,
            processingMaterials: processingMaterials,
            completion: completion,
            uploading: uploading,
            isPublished: module.isPublished,
            onUpload: onUpload,
            onTogglePublish: onTogglePublish,
          );

          if (compact) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [titleArea, const SizedBox(height: 18), progressCard]);
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: titleArea), const SizedBox(width: 18), SizedBox(width: 286, child: progressCard)]);
        },
      ),
    );
  }
}

class _ModuleWorkspaceProgress extends StatelessWidget {
  final int materialCount;
  final int readyMaterials;
  final int processingMaterials;
  final double completion;
  final bool uploading;
  final bool isPublished;
  final VoidCallback? onUpload;
  final VoidCallback? onTogglePublish;

  const _ModuleWorkspaceProgress({
    required this.materialCount,
    required this.readyMaterials,
    required this.processingMaterials,
    required this.completion,
    required this.uploading,
    required this.isPublished,
    required this.onUpload,
    required this.onTogglePublish,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE1E7EF)), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: _ModuleStatPill(label: 'Files', value: '$materialCount')),
              const SizedBox(width: 8),
              Expanded(child: _ModuleStatPill(label: 'Ready', value: '$readyMaterials')),
              const SizedBox(width: 8),
              Expanded(child: _ModuleStatPill(label: 'Queue', value: '$processingMaterials')),
            ]),
            const SizedBox(height: 15),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${(completion * 100).round()}%', style: TextStyle(fontSize: 30, height: .95, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
              const SizedBox(width: 8),
              Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('ready', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppColors.textMuted))),
            ]),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: completion, minHeight: 6, backgroundColor: const Color(0xFFE8EEF5), color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: onUpload,
                    icon: const Icon(Icons.upload_file_rounded, size: 15),
                    label: Text(uploading ? 'Uploading' : 'Upload'),
                    style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: AppColors.primary, foregroundColor: Colors.white, disabledBackgroundColor: AppColors.primary.withOpacity(.45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 38,
                width: 42,
                child: OutlinedButton(
                  onPressed: onTogglePublish,
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, side: const BorderSide(color: Color(0xFFDDE5EE)), foregroundColor: AppColors.textTitle, backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Icon(isPublished ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 17),
                ),
              ),
            ]),
          ],
        ),
      );
}

class _ModuleStatPill extends StatelessWidget {
  final String label;
  final String value;
  const _ModuleStatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE6ECF3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 18, height: 1, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 10.2, fontWeight: FontWeight.w900, color: AppColors.textMuted)),
        ]),
      );
}

class _ModuleActionStrip extends StatelessWidget {
  final VoidCallback? onUpload;
  final VoidCallback? onRename;
  final VoidCallback? onEditDescription;
  final VoidCallback? onTogglePublish;
  final VoidCallback? onShare;
  final bool isPublished;
  final bool hasDescription;

  const _ModuleActionStrip({required this.onUpload, required this.onRename, required this.onEditDescription, required this.onTogglePublish, required this.onShare, required this.isPublished, required this.hasDescription});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 9,
        runSpacing: 9,
        children: [
          _ModuleFlatButton(label: 'Upload material', icon: Icons.upload_file_rounded, onTap: onUpload, primary: true),
          _ModuleFlatButton(label: 'Rename', icon: Icons.drive_file_rename_outline_rounded, onTap: onRename),
          _ModuleFlatButton(label: hasDescription ? 'Edit summary' : 'Add summary', icon: Icons.notes_rounded, onTap: onEditDescription),
          _ModuleFlatButton(label: isPublished ? 'Unpublish' : 'Publish', icon: isPublished ? Icons.visibility_off_rounded : Icons.visibility_rounded, onTap: onTogglePublish),
          _ModuleFlatButton(label: 'Share', icon: Icons.ios_share_rounded, onTap: onShare),
        ],
      );
}

class _ModuleFlatButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;
  const _ModuleFlatButton({required this.label, required this.icon, required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 36,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 15),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            elevation: 0,
            foregroundColor: primary ? Colors.white : AppColors.textTitle,
            backgroundColor: primary ? AppColors.primary : Colors.white,
            disabledForegroundColor: AppColors.textHint,
            side: BorderSide(color: primary ? AppColors.primary : const Color(0xFFDDE5EE)),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 0),
            textStyle: const TextStyle(fontSize: 12.3, fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
}

class _ModuleWorkflowRail extends StatelessWidget {
  final bool hasMaterials;
  final int readyMaterials;
  final int processingMaterials;
  final bool hasDescription;
  final bool isPublished;

  const _ModuleWorkflowRail({required this.hasMaterials, required this.readyMaterials, required this.processingMaterials, required this.hasDescription, required this.isPublished});

  @override
  Widget build(BuildContext context) {
    final processed = hasMaterials && processingMaterials == 0 && readyMaterials > 0;
    final steps = [
      _WorkflowStepData(label: 'Source', hint: hasMaterials ? 'File attached' : 'Upload required', complete: hasMaterials, icon: Icons.file_present_rounded),
      _WorkflowStepData(label: 'Processing', hint: processed ? 'Ready' : '$processingMaterials in queue', complete: processed, icon: Icons.memory_rounded),
      _WorkflowStepData(label: 'Summary', hint: hasDescription ? 'Added' : 'Missing', complete: hasDescription, icon: Icons.subject_rounded),
      _WorkflowStepData(label: 'Publish', hint: isPublished ? 'Visible' : 'Hidden', complete: isPublished, icon: Icons.public_rounded),
    ];

    return _ModuleFlatPanel(
      title: 'Workspace pipeline',
      subtitle: 'Content preparation path',
      icon: Icons.account_tree_rounded,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            if (compact) {
              return Column(children: [for (int i = 0; i < steps.length; i++) ...[_ModuleWorkflowStep(data: steps[i], index: i + 1), if (i != steps.length - 1) const SizedBox(height: 8)]]);
            }
            return Row(children: [for (int i = 0; i < steps.length; i++) ...[Expanded(child: _ModuleWorkflowStep(data: steps[i], index: i + 1)), if (i != steps.length - 1) const SizedBox(width: 10)]]);
          },
        ),
      ),
    );
  }
}

class _WorkflowStepData {
  final String label;
  final String hint;
  final bool complete;
  final IconData icon;
  const _WorkflowStepData({required this.label, required this.hint, required this.complete, required this.icon});
}

class _ModuleWorkflowStep extends StatelessWidget {
  final _WorkflowStepData data;
  final int index;
  const _ModuleWorkflowStep({required this.data, required this.index});

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 74),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: data.complete ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC), border: Border.all(color: data.complete ? const Color(0xFFBBF7D0) : const Color(0xFFE1E7EF)), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: data.complete ? AppColors.successText : Colors.white, border: Border.all(color: data.complete ? AppColors.successText : const Color(0xFFDDE5EE)), borderRadius: BorderRadius.circular(10)),
            child: Icon(data.complete ? Icons.check_rounded : data.icon, size: 16, color: data.complete ? Colors.white : AppColors.textMuted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(data.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
              const SizedBox(height: 3),
              Text(data.hint, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
            ]),
          ),
        ]),
      );
}

class _ModuleMaterialsBoard extends StatelessWidget {
  final List<MaterialItem> materials;
  final VoidCallback? onUpload;
  final void Function(MaterialItem) onMaterialTap;

  const _ModuleMaterialsBoard({required this.materials, required this.onUpload, required this.onMaterialTap});

  @override
  Widget build(BuildContext context) => _ModuleFlatPanel(
        title: 'Learning materials',
        subtitle: '${materials.length} item${materials.length == 1 ? '' : 's'} in this module',
        icon: Icons.folder_copy_rounded,
        trailing: _ModuleFlatButton(label: 'Add material', icon: Icons.add_rounded, onTap: onUpload),
        child: materials.isEmpty
            ? _ModuleEmptyMaterials(onUpload: onUpload)
            : Column(children: [const _MaterialsTableHeader(), for (int i = 0; i < materials.length; i++) _ModuleMaterialListTile(index: i + 1, material: materials[i], onTap: () => onMaterialTap(materials[i]))]),
      );
}

class _MaterialsTableHeader extends StatelessWidget {
  const _MaterialsTableHeader();

  @override
  Widget build(BuildContext context) => Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(bottom: BorderSide(color: Color(0xFFE1E7EF)))),
        child: Row(children: [
          SizedBox(width: 42, child: Text('#', style: _ModuleTableHeaderStyle.style(context))),
          Expanded(flex: 5, child: Text('Material', style: _ModuleTableHeaderStyle.style(context))),
          Expanded(flex: 2, child: Text('Type', style: _ModuleTableHeaderStyle.style(context))),
          Expanded(flex: 2, child: Text('Status', style: _ModuleTableHeaderStyle.style(context))),
          SizedBox(width: 36, child: Text('', style: _ModuleTableHeaderStyle.style(context))),
        ]),
      );
}

class _ModuleTableHeaderStyle {
  static TextStyle style(BuildContext context) => TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: .55, color: AppColors.textHint);
}

class _ModuleEmptyMaterials extends StatelessWidget {
  final VoidCallback? onUpload;
  const _ModuleEmptyMaterials({required this.onUpload});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
        color: Colors.white,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE1E7EF)), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.primarySoft, border: Border.all(color: AppColors.primary.withOpacity(0.16)), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('No material attached', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
                const SizedBox(height: 5),
                Text('Upload a PDF, video, or document. Topics and question generation can start after processing.', style: TextStyle(fontSize: 12.4, height: 1.45, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(width: 14),
            _ModuleFlatButton(label: 'Upload', icon: Icons.upload_file_rounded, onTap: onUpload, primary: true),
          ]),
        ),
      );
}

class _ModuleMaterialListTile extends StatefulWidget {
  final int index;
  final MaterialItem material;
  final VoidCallback onTap;
  const _ModuleMaterialListTile({required this.index, required this.material, required this.onTap});

  @override
  State<_ModuleMaterialListTile> createState() => _ModuleMaterialListTileState();
}

class _ModuleMaterialListTileState extends State<_ModuleMaterialListTile> {
  bool _hovered = false;

  (IconData, Color, Color) get _typeVisual {
    switch (widget.material.type) {
      case 'video':
        return (Icons.play_circle_outline_rounded, const Color(0xFF2563EB), const Color(0xFFEFF6FF));
      case 'pdf':
        return (Icons.picture_as_pdf_outlined, const Color(0xFFDC2626), const Color(0xFFFEF2F2));
      case 'quiz':
        return (Icons.quiz_outlined, const Color(0xFF7C3AED), const Color(0xFFF5F3FF));
      default:
        return (Icons.article_outlined, const Color(0xFF64748B), const Color(0xFFF8FAFC));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = widget.material.status == 'ready';
    final (icon, fg, bg) = _typeVisual;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: _hovered ? const Color(0xFFF8FAFC) : Colors.white, border: const Border(bottom: BorderSide(color: Color(0xFFEFF3F7)))),
          child: Row(children: [
            SizedBox(width: 42, child: Text(widget.index.toString().padLeft(2, '0'), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppColors.textHint))),
            Expanded(
              flex: 5,
              child: Row(children: [
                Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: bg, border: Border.all(color: fg.withOpacity(0.14)), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: fg)),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.material.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.textTitle))),
              ]),
            ),
            Expanded(flex: 2, child: Text(widget.material.type.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppColors.textMuted))),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _ModuleFlatBadge(label: ready ? 'Ready' : 'Processing', icon: ready ? Icons.check_rounded : Icons.hourglass_top_rounded, fg: ready ? AppColors.successText : const Color(0xFFD97706), bg: ready ? AppColors.successBg : const Color(0xFFFFF7E6)),
              ),
            ),
            SizedBox(width: 36, child: Icon(Icons.arrow_forward_rounded, size: 16, color: _hovered ? AppColors.primary : AppColors.textHint)),
          ]),
        ),
      ),
    );
  }
}

class _ModuleSetupPanel extends StatelessWidget {
  final double completion;
  final int materialCount;
  final int readyMaterials;
  final int processingMaterials;
  final bool hasDescription;
  final bool isPublished;
  final DateTime updatedAt;

  const _ModuleSetupPanel({required this.completion, required this.materialCount, required this.readyMaterials, required this.processingMaterials, required this.hasDescription, required this.isPublished, required this.updatedAt});

  @override
  Widget build(BuildContext context) => _ModuleFlatPanel(
        title: 'Inspector',
        subtitle: 'Module readiness',
        icon: Icons.fact_check_rounded,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('${(completion * 100).round()}%', style: TextStyle(fontSize: 34, height: 1, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
              const Spacer(),
              _ModuleFlatBadge(label: isPublished ? 'Live' : 'Hidden', icon: isPublished ? Icons.visibility_rounded : Icons.visibility_off_rounded, fg: isPublished ? AppColors.successText : const Color(0xFFD97706), bg: isPublished ? AppColors.successBg : const Color(0xFFFFF7E6)),
            ]),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: completion, minHeight: 6, backgroundColor: const Color(0xFFE8EEF5), color: AppColors.primary)),
            const SizedBox(height: 16),
            _ModuleGateRow(complete: isPublished, label: isPublished ? 'Visible to students' : 'Module is still hidden'),
            _ModuleGateRow(complete: materialCount > 0, label: materialCount > 0 ? '$materialCount material${materialCount == 1 ? '' : 's'} attached' : 'No learning material'),
            _ModuleGateRow(complete: hasDescription, label: hasDescription ? 'Summary exists' : 'Summary missing'),
            const SizedBox(height: 12),
            Container(height: 1, color: const Color(0xFFE1E7EF)),
            const SizedBox(height: 12),
            _ModuleMiniFact(label: 'Ready files', value: '$readyMaterials'),
            const SizedBox(height: 8),
            _ModuleMiniFact(label: 'Processing queue', value: '$processingMaterials'),
            const SizedBox(height: 8),
            _ModuleMiniFact(label: 'Updated', value: _relativeDate(updatedAt)),
          ]),
        ),
      );
}

class _ModuleGateRow extends StatelessWidget {
  final bool complete;
  final String label;
  const _ModuleGateRow({required this.complete, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 19, height: 19, alignment: Alignment.center, decoration: BoxDecoration(color: complete ? AppColors.successText : Colors.white, border: Border.all(color: complete ? AppColors.successText : const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(6)), child: complete ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontSize: 12.3, height: 1.35, fontWeight: FontWeight.w800, color: AppColors.textTitle))),
        ]),
      );
}

class _ModuleAdminPanel extends StatelessWidget {
  final VoidCallback? onChangePosition;
  final VoidCallback? onDelete;
  const _ModuleAdminPanel({required this.onChangePosition, required this.onDelete});

  @override
  Widget build(BuildContext context) => _ModuleFlatPanel(
        title: 'Administration',
        subtitle: 'Structure controls',
        icon: Icons.tune_rounded,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            _ModuleAdminAction(icon: Icons.swap_vert_rounded, title: 'Change position', subtitle: 'Move this module in the course sequence.', onTap: onChangePosition),
            const SizedBox(height: 9),
            _ModuleAdminAction(icon: Icons.delete_outline_rounded, title: 'Delete module', subtitle: 'Remove the module and its structure.', danger: true, onTap: onDelete),
          ]),
        ),
      );
}

class _ModuleAdminAction extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool danger;
  final VoidCallback? onTap;
  const _ModuleAdminAction({required this.icon, required this.title, required this.subtitle, required this.onTap, this.danger = false});

  @override
  State<_ModuleAdminAction> createState() => _ModuleAdminActionState();
}

class _ModuleAdminActionState extends State<_ModuleAdminAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fg = widget.danger ? AppColors.dangerText : AppColors.textTitle;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(color: _hovered ? const Color(0xFFF8FAFC) : Colors.white, border: Border.all(color: widget.danger ? AppColors.dangerBorder : const Color(0xFFE1E7EF)), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: widget.danger ? AppColors.dangerBg : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)), child: Icon(widget.icon, size: 17, color: widget.danger ? AppColors.dangerText : AppColors.textMuted)),
            const SizedBox(width: 11),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.title, style: TextStyle(fontSize: 12.8, fontWeight: FontWeight.w900, color: fg)),
                const SizedBox(height: 3),
                Text(widget.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, height: 1.35, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              ]),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 15, color: _hovered ? fg : AppColors.textHint),
          ]),
        ),
      ),
    );
  }
}

class _ModuleFlatPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _ModuleFlatPanel({required this.title, required this.icon, required this.child, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE1E7EF)), borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 14, offset: Offset(0, 6))]),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 13),
            child: Row(children: [
              Container(width: 32, height: 32, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 16, color: AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
                  if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMuted))],
                ]),
              ),
              if (trailing != null) trailing!,
            ]),
          ),
          Container(height: 1, color: const Color(0xFFE1E7EF)),
          child,
        ]),
      );
}

class _ModuleFlatBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color fg;
  final Color bg;
  const _ModuleFlatBadge({required this.label, required this.icon, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(color: bg, border: Border.all(color: fg.withOpacity(0.16)), borderRadius: BorderRadius.circular(9)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: fg), const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 11.3, fontWeight: FontWeight.w900, color: fg))]),
      );
}

class _ModuleBlueHeader extends StatelessWidget {
  final ModuleItem module;
  final String description;
  final int materialCount;
  final int readyMaterials;
  final int processingMaterials;
  final VoidCallback? onUpload;
  final VoidCallback? onRename;
  final VoidCallback? onEditDescription;
  final VoidCallback? onTogglePublish;
  final VoidCallback? onShare;

  const _ModuleBlueHeader({
    required this.module,
    required this.description,
    required this.materialCount,
    required this.readyMaterials,
    required this.processingMaterials,
    required this.onUpload,
    required this.onRename,
    required this.onEditDescription,
    required this.onTogglePublish,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final title = module.title.trim().isEmpty ? 'Untitled module' : module.title.trim();
    final moduleSummary = description.isNotEmpty
        ? description
        : 'This module is the first level in the course structure. Add materials, then organize them into topics and subtopics.';

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 228),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF137FEC), Color(0xFF0B66D7), Color(0xFF19A7F8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final statWidth = compact ? double.infinity : 240.0;

          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ModuleHeroPill(
                    label: module.isPublished ? 'Published' : 'Draft',
                    icon: module.isPublished ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  ),
                  _ModuleHeroPill(
                    label: '$materialCount material${materialCount == 1 ? '' : 's'}',
                    icon: Icons.folder_copy_rounded,
                  ),
                  if (module.isShared)
                    const _ModuleHeroPill(
                      label: 'Shared',
                      icon: Icons.share_rounded,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                maxLines: compact ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 26 : 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.05,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: Text(
                  moduleSummary,
                  maxLines: compact ? 4 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.86),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _ModuleHeroActionStrip(
                onUpload: onUpload,
                onRename: onRename,
                onEditDescription: onEditDescription,
                onTogglePublish: onTogglePublish,
                onShare: onShare,
                isPublished: module.isPublished,
                hasDescription: description.isNotEmpty,
              ),
            ],
          );

          final statsCard = Container(
            width: statWidth,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ModuleHeroMetric(
                  label: 'Order',
                  value: '#${module.orderIndex + 1}',
                  icon: Icons.format_list_numbered_rounded,
                ),
                const SizedBox(height: 12),
                _ModuleHeroMetric(
                  label: 'Ready files',
                  value: '$readyMaterials/$materialCount',
                  icon: Icons.verified_rounded,
                ),
                const SizedBox(height: 12),
                _ModuleHeroMetric(
                  label: 'Updated',
                  value: _relativeDate(module.updatedAt),
                  icon: Icons.schedule_rounded,
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleBlock, const SizedBox(height: 18), statsCard],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 22),
              statsCard,
            ],
          );
        },
      ),
    );
  }
}


class _ModuleHeroActionStrip extends StatelessWidget {
  final VoidCallback? onUpload;
  final VoidCallback? onRename;
  final VoidCallback? onEditDescription;
  final VoidCallback? onTogglePublish;
  final VoidCallback? onShare;
  final bool isPublished;
  final bool hasDescription;

  const _ModuleHeroActionStrip({
    required this.onUpload,
    required this.onRename,
    required this.onEditDescription,
    required this.onTogglePublish,
    required this.onShare,
    required this.isPublished,
    required this.hasDescription,
  });

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 9,
        runSpacing: 9,
        children: [
          _ModuleHeroActionButton(
            label: 'Upload material',
            icon: Icons.upload_file_rounded,
            onTap: onUpload,
            primary: true,
          ),
          _ModuleHeroActionButton(
            label: 'Rename',
            icon: Icons.drive_file_rename_outline_rounded,
            onTap: onRename,
          ),
          _ModuleHeroActionButton(
            label: hasDescription ? 'Edit summary' : 'Add summary',
            icon: Icons.notes_rounded,
            onTap: onEditDescription,
          ),
          _ModuleHeroActionButton(
            label: isPublished ? 'Unpublish' : 'Publish',
            icon: isPublished ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            onTap: onTogglePublish,
          ),
          _ModuleHeroActionButton(
            label: 'Share',
            icon: Icons.ios_share_rounded,
            onTap: onShare,
          ),
        ],
      );
}

class _ModuleHeroActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;

  const _ModuleHeroActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  @override
  State<_ModuleHeroActionButton> createState() => _ModuleHeroActionButtonState();
}

class _ModuleHeroActionButtonState extends State<_ModuleHeroActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final Color background = widget.primary
        ? Colors.white
        : _hovered
            ? Colors.white.withOpacity(0.22)
            : Colors.white.withOpacity(0.14);
    final Color foreground = widget.primary ? AppColors.primary : Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        height: 38,
        child: OutlinedButton.icon(
          onPressed: widget.onTap,
          icon: Icon(widget.icon, size: 15),
          label: Text(widget.label),
          style: OutlinedButton.styleFrom(
            elevation: 0,
            foregroundColor: enabled ? foreground : Colors.white.withOpacity(0.55),
            backgroundColor: enabled ? background : Colors.white.withOpacity(0.08),
            disabledForegroundColor: Colors.white.withOpacity(0.55),
            disabledBackgroundColor: Colors.white.withOpacity(0.08),
            side: BorderSide(color: widget.primary ? Colors.white : Colors.white.withOpacity(0.28)),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 0),
            textStyle: const TextStyle(fontSize: 12.3, fontWeight: FontWeight.w900),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }
}

class _ModuleHeroPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ModuleHeroPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
}

class _ModuleHeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ModuleHeroMetric({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.72),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _ModuleStructureCard extends StatelessWidget {
  final ModuleItem module;
  final List<MaterialItem> materials;
  final int readyMaterials;
  final int processingMaterials;
  final VoidCallback onUpload;
  final void Function(MaterialItem) onMaterialTap;

  const _ModuleStructureCard({
    required this.module,
    required this.materials,
    required this.readyMaterials,
    required this.processingMaterials,
    required this.onUpload,
    required this.onMaterialTap,
  });

  @override
  Widget build(BuildContext context) {
    return _CanvasSection(
      title: 'Module workspace',
      icon: Icons.account_tree_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ModuleHierarchyStrip(materialCount: materials.length),
          const SizedBox(height: 16),
          _ModuleStatusBrief(
            isPublished: module.isPublished,
            hasDescription: (module.description ?? '').trim().isNotEmpty,
            materialCount: materials.length,
            readyMaterials: readyMaterials,
            processingMaterials: processingMaterials,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Materials in this module',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textTitle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      materials.isEmpty
                          ? 'Upload the first file to start building topics.'
                          : 'Open a file to manage its topics and subtopics.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ModuleTinyButton(
                icon: Icons.upload_rounded,
                label: 'Upload',
                onTap: onUpload,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (materials.isEmpty)
            _MatEmptyWidget(onUpload: onUpload)
          else
            Column(
              children: materials.asMap().entries.map(
                (e) => Padding(
                  padding: EdgeInsets.only(bottom: e.key == materials.length - 1 ? 0 : 12),
                  child: _ModuleMaterialCard(
                    material: e.value,
                    onTap: () => onMaterialTap(e.value),
                  ),
                ),
              ).toList(),
            ),
        ],
      ),
    );
  }
}

class _ModuleHierarchyStrip extends StatelessWidget {
  final int materialCount;
  const _ModuleHierarchyStrip({required this.materialCount});

  @override
  Widget build(BuildContext context) {
    final nodes = [
      (Icons.layers_rounded, 'Module'),
      (Icons.insert_drive_file_rounded, 'Materials'),
      (Icons.flag_rounded, 'Topics'),
      (Icons.subdirectory_arrow_right_rounded, 'Subtopics'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          final children = <Widget>[];
          for (var i = 0; i < nodes.length; i++) {
            final (icon, label) = nodes[i];
            children.add(_HierarchyNode(icon: icon, label: label, active: i == 0));
            if (i != nodes.length - 1) {
              children.add(Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 8),
                child: Icon(
                  compact ? Icons.keyboard_arrow_down_rounded : Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textHint,
                ),
              ),);
            }
          }
          return compact
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)
              : Row(children: children);
        },
      ),
    );
  }
}

class _HierarchyNode extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _HierarchyNode({required this.icon, required this.label, required this.active});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: active ? Border.all(color: AppColors.primary.withOpacity(0.28)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: active ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: active ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
}

class _ModuleStatusBrief extends StatelessWidget {
  final bool isPublished;
  final bool hasDescription;
  final int materialCount;
  final int readyMaterials;
  final int processingMaterials;

  const _ModuleStatusBrief({
    required this.isPublished,
    required this.hasDescription,
    required this.materialCount,
    required this.readyMaterials,
    required this.processingMaterials,
  });

  @override
  Widget build(BuildContext context) {
    final checks = [
      _ModuleCheckItem(
        icon: Icons.visibility_rounded,
        title: isPublished ? 'Visible to students' : 'Hidden from students',
        detail: isPublished ? 'Published' : 'Draft',
        complete: isPublished,
      ),
      _ModuleCheckItem(
        icon: Icons.folder_copy_rounded,
        title: materialCount == 0 ? 'No materials yet' : '$materialCount material${materialCount == 1 ? '' : 's'} attached',
        detail: materialCount == 0 ? 'Upload needed' : '$readyMaterials ready, $processingMaterials processing',
        complete: materialCount > 0,
      ),
      _ModuleCheckItem(
        icon: Icons.notes_rounded,
        title: hasDescription ? 'Description added' : 'No description',
        detail: hasDescription ? 'Context is clear' : 'Add context',
        complete: hasDescription,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        if (compact) {
          return Column(
            children: checks.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: item,
            ),).toList(),
          );
        }
        return Row(
          children: [
            for (var i = 0; i < checks.length; i++) ...[
              Expanded(child: checks[i]),
              if (i != checks.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _ModuleCheckItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final bool complete;

  const _ModuleCheckItem({required this.icon, required this.title, required this.detail, required this.complete});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: complete ? AppColors.successBg : AppColors.surfaceBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: complete ? AppColors.successText.withOpacity(0.18) : AppColors.borderGray),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: complete ? Colors.white.withOpacity(0.6) : AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 16, color: complete ? AppColors.successText : AppColors.textMuted),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.textTitle),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ModuleControlDock extends StatelessWidget {
  final ModuleItem module;
  final int materialCount;
  final int readyMaterials;
  final int processingMaterials;
  final bool hasDescription;
  final bool uploading;
  final VoidCallback? onUpload;
  final VoidCallback? onRename;
  final VoidCallback? onEditDescription;
  final VoidCallback? onTogglePublish;
  final VoidCallback? onChangePosition;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const _ModuleControlDock({
    required this.module,
    required this.materialCount,
    required this.readyMaterials,
    required this.processingMaterials,
    required this.hasDescription,
    required this.uploading,
    required this.onUpload,
    required this.onRename,
    required this.onEditDescription,
    required this.onTogglePublish,
    required this.onChangePosition,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final completed = [module.isPublished, materialCount > 0, hasDescription].where((v) => v).length;
    final progress = completed / 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CanvasSection(
          title: 'Module health',
          icon: Icons.insights_rounded,
          compactHeader: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textTitle, height: 1),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'setup complete',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: AppColors.headerBg,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              _ModuleMiniFact(label: 'Materials', value: '$materialCount'),
              const SizedBox(height: 8),
              _ModuleMiniFact(label: 'Ready', value: '$readyMaterials'),
              const SizedBox(height: 8),
              _ModuleMiniFact(label: 'Processing', value: '$processingMaterials'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _CanvasSection(
          title: 'Actions',
          icon: Icons.bolt_rounded,
          compactHeader: true,
          child: Column(
            children: [
              _ActionTile(
                icon: Icons.upload_file_rounded,
                iconBg: AppColors.primarySoft,
                iconFg: AppColors.primary,
                title: uploading ? 'Uploading material…' : 'Upload material',
                subtitle: 'Attach a PDF, video, or document to this module.',
                onTap: onUpload,
                emphasis: true,
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.drive_file_rename_outline_rounded,
                iconBg: AppColors.headerBg,
                iconFg: AppColors.textMuted,
                title: 'Rename',
                subtitle: 'Change the module title in the structure tree.',
                onTap: onRename,
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.notes_rounded,
                iconBg: AppColors.headerBg,
                iconFg: AppColors.textMuted,
                title: hasDescription ? 'Edit description' : 'Add description',
                subtitle: 'Keep the module purpose clear.',
                onTap: onEditDescription,
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: module.isPublished ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                iconBg: module.isPublished ? const Color(0xFFFFF4E5) : AppColors.successBg,
                iconFg: module.isPublished ? const Color(0xFFD97706) : AppColors.successText,
                title: module.isPublished ? 'Unpublish' : 'Publish',
                subtitle: module.isPublished ? 'Hide from students.' : 'Make visible to students.',
                onTap: onTogglePublish,
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.swap_vert_rounded,
                iconBg: AppColors.headerBg,
                iconFg: AppColors.textMuted,
                title: 'Change position',
                subtitle: 'Move this module in the course order.',
                onTap: onChangePosition,
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.share_rounded,
                iconBg: AppColors.successBg,
                iconFg: AppColors.successText,
                title: 'Share module',
                subtitle: module.sharedWithCourseIds.isEmpty
                    ? 'Reuse this module in another course.'
                    : 'Shared with ${module.sharedWithCourseIds.length} course${module.sharedWithCourseIds.length == 1 ? '' : 's'}.',
                onTap: onShare,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _CanvasDangerSection(onDelete: onDelete),
      ],
    );
  }
}

class _ModuleMiniFact extends StatelessWidget {
  final String label;
  final String value;

  const _ModuleMiniFact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12.5, color: AppColors.textTitle, fontWeight: FontWeight.w900),
          ),
        ],
      );
}

class _ModuleTinyButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ModuleTinyButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _HeaderChip({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _CanvasSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final bool compactHeader;

  const _CanvasSection({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
    this.compactHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compactHeader ? 18 : 20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          const BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textTitle,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SoftStatTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String label;
  final String value;
  final String description;

  const _SoftStatTile({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.label,
    required this.value,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: iconFg),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textTitle,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionBlock extends StatelessWidget {
  final bool hasDescription;
  final String description;

  const _DescriptionBlock({
    required this.hasDescription,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.headerBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.notes_rounded, size: 18, color: AppColors.textMuted),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasDescription ? description : 'No description added yet',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textTitle,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasDescription
                      ? 'This text helps instructors and students understand the purpose of the module.'
                      : 'Add a short summary to make this module clearer for instructors and students.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool emphasis;

  const _ActionTile({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasis = false,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) {
        if (!disabled) setState(() => _hovered = true);
      },
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.emphasis
                ? AppColors.primarySoft
                : (_hovered && !disabled ? AppColors.surfaceBg : AppColors.cardBg),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Opacity(
            opacity: disabled ? 0.45 : 1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: widget.iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, size: 18, color: widget.iconFg),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _hovered && !disabled ? AppColors.primary : AppColors.textTitle,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: disabled ? AppColors.textHint : AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CanvasDangerSection extends StatelessWidget {
  final VoidCallback? onDelete;

  const _CanvasDangerSection({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.dangerText),
              const SizedBox(width: 10),
              Text(
                'Danger zone',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dangerText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Delete this module only when you are sure its content is no longer needed in the course.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.dangerText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('Delete module'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.dangerText,
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
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
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGray),
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
                backgroundColor: AppColors.border,
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
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF145CCB), AppColors.primary, Color(0xFF4CB5FF)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;
          final rightCard = Container(
            constraints: const BoxConstraints(minWidth: 180),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
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
                Text('Updated ${_relativeDate(module.updatedAt)}', style: TextStyle(fontSize: 11.8, height: 1.45, color: Colors.white.withOpacity(0.86))),
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
            children: [Expanded(child: body), const SizedBox(width: 20), rightCard],
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
      (Icons.share_rounded, 'Shared', sharedCount == 0 ? 'Only in this course' : 'Shared with $sharedCount', AppColors.successBg, AppColors.successText),
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
                boxShadow: [const BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 3))],
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
                        Text(item.$2, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        Text(item.$3, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textTitle, height: 1.28)),
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
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.2)),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: multiline ? null : 1,
                  overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textTitle, height: 1.45),
                ),
                const SizedBox(height: 4),
                Text(caption, style: TextStyle(fontSize: 11.8, color: AppColors.textMuted, height: 1.55)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_field
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
    final border = isDanger ? AppColors.dangerBorder : _K.div;
    final fg = isDanger ? AppColors.dangerText : AppColors.primary;
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
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isDanger ? AppColors.dangerTitle : AppColors.textTitle)),
              const SizedBox(height: 6),
              Text(description, style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.45)),
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
            color: AppColors.surfaceBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGray),
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
              Text('No materials yet', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textTitle)),
              const SizedBox(height: 5),
              Text('Upload a PDF, video, or document to turn this module into usable learning content.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.5)),
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

  static Map<String, (IconData, Color, Color, String)> get _colors => {
    'video': (Icons.play_circle_filled_rounded, AppColors.badgeBlueBg, const Color(0xFF2563EB), 'Video'),
    'pdf': (Icons.picture_as_pdf_rounded, const Color(0xFFFEE2E2), AppColors.dangerText, 'PDF'),
    'quiz': (Icons.quiz_rounded, const Color(0xFFF3E8FF), const Color(0xFF9333EA), 'Quiz'),
  };
  static Map<String, (String, Color, Color)> get _status => {
    'ready': ('Ready', AppColors.successBg, AppColors.successText),
    'processing': ('Processing', const Color(0xFFFEF3C7), const Color(0xFFD97706)),
    'uploaded': ('Processing', const Color(0xFFFEF3C7), const Color(0xFFD97706)),
    'draft_upload': ('Uploading', const Color(0xFFE0F2FE), const Color(0xFF0369A1)),
    'error': ('Error', AppColors.dangerBg, AppColors.dangerText),
  };

  @override
  Widget build(BuildContext context) {
    final (ico, ib, ic, typeLabel) = _colors[material.type] ??
        (Icons.insert_drive_file_rounded, AppColors.headerBg, AppColors.textMuted, material.type.toUpperCase());
    final (sl, sb, sf) = _status[material.status] ??
        (material.status, AppColors.headerBg, AppColors.textMuted);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderGray),
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
                  Text(material.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textTitle, height: 1.3)),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Text(typeLabel, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textHint, letterSpacing: 0.4)),
                      if (material.pageCount != null)
                        Text('${material.pageCount} pages', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
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
            Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
//  MATERIAL PANEL
// ─────────────────────────────────────────────────────────────────────────────
