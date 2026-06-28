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
            color: AppColors.primary.withValues(alpha: 0.18),
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
                    color: Colors.white.withValues(alpha: 0.86),
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
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
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
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.14);
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
            foregroundColor: enabled ? foreground : Colors.white.withValues(alpha: 0.55),
            backgroundColor: enabled ? background : Colors.white.withValues(alpha: 0.08),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.55),
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
            side: BorderSide(color: widget.primary ? Colors.white : Colors.white.withValues(alpha: 0.28)),
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
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
              color: Colors.white.withValues(alpha: 0.14),
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
                    color: Colors.white.withValues(alpha: 0.72),
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

