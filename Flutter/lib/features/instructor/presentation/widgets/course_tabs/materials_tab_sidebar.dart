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
                        color: selectionMode ? AppColors.primary.withValues(alpha: 0.18) : _K.div,
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
                                              color: AppColors.primary.withValues(alpha: 0.14),
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
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : _K.bg,
                child: Center(
                  child: Container(
                    width: 3,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isResizing
                          ? AppColors.primary.withValues(alpha: 0.65)
                          : AppColors.textHint.withValues(alpha: 0.28),
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
                    color: col.withValues(alpha: 0.10),
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
  final VoidCallback? onAskAi;
  final bool assistantBusy;

  const _FooterWidget({required this.ctx, required this.uploading, required this.canGenerate,
      this.selectionCount,
      required this.onUpload, required this.onGenerate, this.onAskAi,
      this.assistantBusy = false, required this.onClose,});

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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
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
        if (onAskAi != null) ...[
          _Btn(
            icon: assistantBusy ? Icons.hourglass_top_rounded : Icons.auto_awesome_rounded,
            label: assistantBusy ? 'Course AI…' : 'Chat with AI',
            primary: false,
            disabled: assistantBusy,
            onTap: assistantBusy ? null : onAskAi,
          ),
          const SizedBox(width: 8),
        ],
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

