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

