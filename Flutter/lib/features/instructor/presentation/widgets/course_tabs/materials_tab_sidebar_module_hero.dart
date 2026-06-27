part of 'materials_tab.dart';

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

