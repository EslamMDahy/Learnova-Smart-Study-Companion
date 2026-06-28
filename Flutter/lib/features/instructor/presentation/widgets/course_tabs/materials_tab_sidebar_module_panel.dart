part of 'materials_tab.dart';

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
              decoration: BoxDecoration(color: AppColors.primarySoft, border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)), borderRadius: BorderRadius.circular(12)),
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
                Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: bg, border: Border.all(color: fg.withValues(alpha: 0.14)), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: fg)),
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
        decoration: BoxDecoration(color: bg, border: Border.all(color: fg.withValues(alpha: 0.16)), borderRadius: BorderRadius.circular(9)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: fg), const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 11.3, fontWeight: FontWeight.w900, color: fg))]),
      );
}

