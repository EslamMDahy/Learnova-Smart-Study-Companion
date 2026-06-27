part of 'materials_tab.dart';

class _MaterialPanelWidget extends StatelessWidget {
  final ModuleItem module;
  final MaterialItem material;
  final List<TopicItem> topics;
  final bool topicsLoading;
  final List<LearningOutcome> outcomes;
  final String? downloadUrl;
  final bool urlLoading;
  final void Function(TopicItem) onTopicTap;
  final Future<bool> Function(
    String title,
    String? description,
    List<int> learningOutcomeIds,
  ) onCreateTopicManual;
  final VoidCallback onRefreshUrl;
  final VoidCallback onDeleteMaterial;
  final bool previewInteractive;

  const _MaterialPanelWidget({
    required this.module,
    required this.material,
    required this.topics,
    required this.topicsLoading,
    required this.outcomes,
    required this.downloadUrl,
    required this.urlLoading,
    required this.onTopicTap,
    required this.onCreateTopicManual,
    required this.onRefreshUrl,
    required this.onDeleteMaterial,
    required this.previewInteractive,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final mappedOutcomeIds = _mappedOutcomeIds(topics);
    final readyTopics = topics
        .where((t) => t.readiness == TopicReadiness.ready || t.isReviewed)
        .length;

    return _PdfReviewerWorkspace(
      module: module,
      material: material,
      topics: topics,
      topicsLoading: topicsLoading,
      outcomes: outcomes,
      mappedOutcomeIds: mappedOutcomeIds,
      readyTopics: readyTopics,
      downloadUrl: downloadUrl,
      urlLoading: urlLoading,
      previewInteractive: previewInteractive,
      onRefreshUrl: onRefreshUrl,
      onDeleteMaterial: onDeleteMaterial,
      onTopicTap: onTopicTap,
      onCreateTopicManual: onCreateTopicManual,
    );
  }

  Set<int> _mappedOutcomeIds(List<TopicItem> topics) {
    final ids = <int>{};
    for (final topic in topics) {
      ids.addAll(topic.learningOutcomeIds);
      if (topic.linkedOutcomeId != null) {
        final parsed = int.tryParse(topic.linkedOutcomeId!);
        if (parsed != null) ids.add(parsed);
      }
      for (final raw in topic.linkedOutcomeIds) {
        final parsed = int.tryParse(raw);
        if (parsed != null) ids.add(parsed);
      }
    }
    return ids;
  }
}

class _PdfReviewerWorkspace extends StatefulWidget {
  final ModuleItem module;
  final MaterialItem material;
  final List<TopicItem> topics;
  final bool topicsLoading;
  final List<LearningOutcome> outcomes;
  final Set<int> mappedOutcomeIds;
  final int readyTopics;
  final String? downloadUrl;
  final bool urlLoading;
  final bool previewInteractive;
  final VoidCallback onRefreshUrl;
  final VoidCallback onDeleteMaterial;
  final void Function(TopicItem) onTopicTap;
  final Future<bool> Function(
    String title,
    String? description,
    List<int> learningOutcomeIds,
  ) onCreateTopicManual;

  const _PdfReviewerWorkspace({
    required this.module,
    required this.material,
    required this.topics,
    required this.topicsLoading,
    required this.outcomes,
    required this.mappedOutcomeIds,
    required this.readyTopics,
    required this.downloadUrl,
    required this.urlLoading,
    required this.previewInteractive,
    required this.onRefreshUrl,
    required this.onDeleteMaterial,
    required this.onTopicTap,
    required this.onCreateTopicManual,
  });

  @override
  State<_PdfReviewerWorkspace> createState() => _PdfReviewerWorkspaceState();
}

class _PdfReviewerWorkspaceState extends State<_PdfReviewerWorkspace> {
  bool _reviewerDialogOpen = false;

  void _setReviewerDialogOpen(bool value) {
    if (!mounted || _reviewerDialogOpen == value) return;
    setState(() => _reviewerDialogOpen = value);
  }

  Future<void> _openCaptureTopicDialog(BuildContext context) async {
    _setReviewerDialogOpen(true);
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) {
      _setReviewerDialogOpen(false);
      return;
    }

    try {
      await showDialog<void>(
        context: context,
        barrierColor: AppColors.overlayStrong,
        builder: (dialogContext) {
          return _CaptureTopicDialog(onCreate: widget.onCreateTopicManual);
        },
      );
    } finally {
      _setReviewerDialogOpen(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfPreviewActive = widget.previewInteractive && !_reviewerDialogOpen;

    return Container(
      color: const Color(0xFFF5F7FA),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final narrow = constraints.maxWidth < 980;
          final horizontalPadding = compact ? 16.0 : 24.0;
          const topPadding = 22.0;
          const bottomPadding = 104.0;
          final viewportHeight = constraints.hasBoundedHeight ? constraints.maxHeight : MediaQuery.of(context).size.height;
          final contentMinHeight = (viewportHeight - topPadding - bottomPadding).clamp(0.0, double.infinity).toDouble();
          final stageHeight = compact
              ? 620.0
              : (viewportHeight * (narrow ? 0.82 : 0.88)).clamp(760.0, 1120.0).toDouble();

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(horizontalPadding, topPadding, horizontalPadding, bottomPadding),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1240, minHeight: contentMinHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReviewerShellHeader(
                      module: widget.module,
                      material: widget.material,
                      topics: widget.topics,
                      readyTopics: widget.readyTopics,
                      mappedOutcomeCount: widget.mappedOutcomeIds.length,
                      totalOutcomeCount: widget.outcomes.length,
                      downloadUrl: widget.downloadUrl,
                      urlLoading: widget.urlLoading,
                      onRefreshUrl: widget.onRefreshUrl,
                      onDeleteMaterial: widget.onDeleteMaterial,
                      onAddTopic: () => _openCaptureTopicDialog(context),
                    ),
                    const SizedBox(height: 18),
                    _DocumentStage(
                      material: widget.material,
                      downloadUrl: widget.downloadUrl,
                      urlLoading: widget.urlLoading,
                      onRefreshUrl: widget.onRefreshUrl,
                      previewInteractive: pdfPreviewActive,
                      height: stageHeight,
                    ),
                    const SizedBox(height: 18),
                    _FileTopicsSection(
                      material: widget.material,
                      topics: widget.topics,
                      topicsLoading: widget.topicsLoading,
                      outcomes: widget.outcomes,
                      mappedOutcomeIds: widget.mappedOutcomeIds,
                      readyTopics: widget.readyTopics,
                      onTopicTap: widget.onTopicTap,
                      onAddTopic: () => _openCaptureTopicDialog(context),
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

class _ReviewerShellHeader extends StatelessWidget {
  final ModuleItem module;
  final MaterialItem material;
  final List<TopicItem> topics;
  final int readyTopics;
  final int mappedOutcomeCount;
  final int totalOutcomeCount;
  final String? downloadUrl;
  final bool urlLoading;
  final VoidCallback onRefreshUrl;
  final VoidCallback onDeleteMaterial;
  final VoidCallback onAddTopic;

  const _ReviewerShellHeader({
    required this.module,
    required this.material,
    required this.topics,
    required this.readyTopics,
    required this.mappedOutcomeCount,
    required this.totalOutcomeCount,
    required this.downloadUrl,
    required this.urlLoading,
    required this.onRefreshUrl,
    required this.onDeleteMaterial,
    required this.onAddTopic,
  });

  @override
  Widget build(BuildContext context) {
    final status = _materialStatusLabel(material);
    final parentTopics = topics.where((t) => t.parentTopicId == null).length;
    final subTopics = topics.length - parentTopics;
    final fileName = (material.fileName ?? '').trim();
    final description = (material.description ?? '').trim();
    final subtitle = description.isEmpty ? '${module.title} • ${_documentMetaLine(material)}' : description;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF137FEC), Color(0xFF0B66D7), Color(0xFF19A7F8)],
        ),
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
          final compact = constraints.maxWidth < 780;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _BlueHeaderPill(icon: _materialTypeIcon(material), label: material.type.toUpperCase()),
                  _BlueHeaderPill(icon: Icons.circle_rounded, label: status),
                  if (fileName.isNotEmpty) _BlueHeaderPill(icon: Icons.attach_file_rounded, label: fileName),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                material.displayTitle,
                maxLines: compact ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 32,
                  height: 1.05,
                  letterSpacing: -0.7,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Text(
                  subtitle,
                  maxLines: compact ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.82),
                  ),
                ),
              ),
            ],
          );

          final metrics = Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              _BlueHeaderMetric(label: 'Topics', value: '$parentTopics'),
              _BlueHeaderMetric(label: 'Subtopics', value: '$subTopics'),
              _BlueHeaderMetric(label: 'Ready', value: topics.isEmpty ? '0' : '$readyTopics/${topics.length}'),
              _BlueHeaderMetric(label: 'Outcomes', value: totalOutcomeCount == 0 ? '—' : '$mappedOutcomeCount/$totalOutcomeCount'),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              _BlueHeaderPrimaryButton(
                icon: Icons.add_rounded,
                label: 'Add topic',
                onTap: onAddTopic,
              ),
              _BlueHeaderIconAction(
                tooltip: 'Refresh preview URL',
                icon: urlLoading ? null : Icons.refresh_rounded,
                loading: urlLoading,
                onTap: urlLoading ? null : onRefreshUrl,
              ),
              if (downloadUrl != null && downloadUrl!.isNotEmpty) _BlueHeaderOpenAction(url: downloadUrl!),
              _BlueHeaderDangerButton(
                icon: Icons.delete_outline_rounded,
                label: 'Delete file',
                onTap: onDeleteMaterial,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 18),
                metrics,
                const SizedBox(height: 16),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: title),
              const SizedBox(width: 24),
              SizedBox(
                width: 430,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    metrics,
                    const SizedBox(height: 16),
                    actions,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BlueHeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BlueHeaderPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withOpacity(0.92)),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.92)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueHeaderMetric extends StatelessWidget {
  final String label;
  final String value;

  const _BlueHeaderMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.74))),
          const SizedBox(height: 6),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0)),
        ],
      ),
    );
  }
}

class _BlueHeaderPrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BlueHeaderPrimaryButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _BlueHeaderDangerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BlueHeaderDangerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.10),
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.34)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _BlueHeaderIconAction extends StatelessWidget {
  final String tooltip;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onTap;

  const _BlueHeaderIconAction({required this.tooltip, required this.icon, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: loading
                ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _BlueHeaderOpenAction extends StatelessWidget {
  final String url;

  const _BlueHeaderOpenAction({required this.url});

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: _open,
        icon: const Icon(Icons.open_in_new_rounded, size: 16),
        label: const Text('Open file'),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          side: BorderSide(color: Colors.white.withOpacity(0.72)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _MaterialWorkspacePipeline extends StatelessWidget {
  final MaterialItem material;
  final List<TopicItem> topics;
  final int readyTopics;
  final int mappedOutcomeCount;
  final int totalOutcomeCount;
  final bool previewReady;
  final bool previewLoading;

  const _MaterialWorkspacePipeline({
    required this.material,
    required this.topics,
    required this.readyTopics,
    required this.mappedOutcomeCount,
    required this.totalOutcomeCount,
    required this.previewReady,
    required this.previewLoading,
  });

  @override
  Widget build(BuildContext context) {
    final sourceReady = !material.isError;
    final structureReady = topics.isNotEmpty;
    final coverageReady = totalOutcomeCount == 0 ? false : mappedOutcomeCount > 0;
    final publishReady = material.isReady && structureReady && (totalOutcomeCount == 0 || coverageReady);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 13),
            child: Row(
              children: [
                const _SoftIcon(icon: Icons.schema_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Review pipeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
                      const SizedBox(height: 3),
                      Text('Prepare the file before generating topics, outcomes, and questions.', style: TextStyle(fontSize: 12.4, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderGray),
          Padding(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 680;
                final steps = [
                  _MaterialWorkflowStep(
                    title: 'Source',
                    value: sourceReady ? 'File attached' : 'Error',
                    icon: Icons.insert_drive_file_rounded,
                    complete: sourceReady,
                    active: !sourceReady,
                  ),
                  _MaterialWorkflowStep(
                    title: 'Preview',
                    value: previewLoading ? 'Loading' : previewReady ? 'Available' : 'Needs refresh',
                    icon: Icons.visibility_rounded,
                    complete: previewReady,
                    active: previewLoading || !previewReady,
                  ),
                  _MaterialWorkflowStep(
                    title: 'Structure',
                    value: topics.isEmpty ? 'No topics' : '$readyTopics/${topics.length} ready',
                    icon: Icons.account_tree_rounded,
                    complete: structureReady,
                    active: structureReady && readyTopics < topics.length,
                  ),
                  _MaterialWorkflowStep(
                    title: 'Coverage',
                    value: totalOutcomeCount == 0 ? 'No outcomes' : '$mappedOutcomeCount/$totalOutcomeCount mapped',
                    icon: Icons.flag_rounded,
                    complete: coverageReady,
                    active: !coverageReady,
                  ),
                  _MaterialWorkflowStep(
                    title: 'Ready',
                    value: publishReady ? 'Usable' : _materialStatusLabel(material),
                    icon: Icons.verified_rounded,
                    complete: publishReady,
                    active: material.isProcessing,
                  ),
                ];

                if (compact) {
                  return Column(
                    children: [
                      for (var i = 0; i < steps.length; i++) ...[
                        steps[i],
                        if (i != steps.length - 1) const SizedBox(height: 9),
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    for (var i = 0; i < steps.length; i++) ...[
                      Expanded(child: steps[i]),
                      if (i != steps.length - 1) const SizedBox(width: 10),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialWorkflowStep extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool complete;
  final bool active;

  const _MaterialWorkflowStep({
    required this.title,
    required this.value,
    required this.icon,
    required this.complete,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final bg = complete ? AppColors.successBg : active ? AppColors.primarySoft : AppColors.surfaceBg;
    final fg = complete ? AppColors.successText : active ? AppColors.primary : AppColors.textMuted;
    final border = complete ? AppColors.greenBorder : active ? AppColors.primary.withOpacity(0.20) : AppColors.borderGray;

    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
            child: Icon(complete ? Icons.check_rounded : icon, size: 16, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
                const SizedBox(height: 3),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.8, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialCommandBar extends StatelessWidget {
  final String? downloadUrl;
  final bool urlLoading;
  final VoidCallback onRefreshUrl;
  final VoidCallback onAddTopic;

  const _MaterialCommandBar({
    required this.downloadUrl,
    required this.urlLoading,
    required this.onRefreshUrl,
    required this.onAddTopic,
  });

  Future<void> _openUrl() async {
    final url = downloadUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: onAddTopic,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add topic'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
          _MaterialToolbarButton(
            icon: urlLoading ? null : Icons.refresh_rounded,
            label: urlLoading ? 'Refreshing...' : 'Refresh preview',
            loading: urlLoading,
            onTap: urlLoading ? null : onRefreshUrl,
          ),
          _MaterialToolbarButton(
            icon: Icons.open_in_new_rounded,
            label: 'Open file',
            onTap: (downloadUrl == null || downloadUrl!.isEmpty) ? null : _openUrl,
          ),
        ],
      ),
    );
  }
}

class _MaterialToolbarButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const _MaterialToolbarButton({
    required this.icon,
    required this.label,
    this.loading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: loading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon, size: 17),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textTitle,
          disabledForegroundColor: AppColors.textHint,
          side: BorderSide(color: AppColors.borderGray),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _MaterialInspectorPanel extends StatelessWidget {
  final MaterialItem material;
  final List<TopicItem> topics;
  final int readyTopics;
  final int mappedOutcomeCount;
  final int totalOutcomeCount;
  final bool previewReady;

  const _MaterialInspectorPanel({
    required this.material,
    required this.topics,
    required this.readyTopics,
    required this.mappedOutcomeCount,
    required this.totalOutcomeCount,
    required this.previewReady,
  });

  @override
  Widget build(BuildContext context) {
    final hasTopics = topics.isNotEmpty;
    final hasMapping = totalOutcomeCount > 0 && mappedOutcomeCount > 0;
    final checks = <bool>[previewReady, hasTopics, material.isReady, totalOutcomeCount == 0 ? hasTopics : hasMapping];
    final completion = checks.where((item) => item).length / checks.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowThin,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 16, 17, 14),
            child: Row(
              children: [
                const _SoftIcon(icon: Icons.fact_check_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Inspector', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
                      const SizedBox(height: 3),
                      Text('File readiness', style: TextStyle(fontSize: 12.2, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                _TinyBadge(
                  label: _materialStatusLabel(material),
                  color: _materialStatusColor(material),
                  background: _materialStatusColor(material).withOpacity(0.10),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderGray),
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 15, 17, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${(completion * 100).round()}%', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, height: 1.0, color: AppColors.textTitle)),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text('ready', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.textMuted)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: completion.clamp(0.0, 1.0).toDouble(),
                    backgroundColor: AppColors.borderSoft,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 15),
                _InspectorChecklistRow(label: previewReady ? 'Preview URL ready' : 'Preview needs refresh', checked: previewReady),
                const SizedBox(height: 9),
                _InspectorChecklistRow(label: hasTopics ? '${topics.length} topic${topics.length == 1 ? '' : 's'} attached' : 'No topics attached', checked: hasTopics),
                const SizedBox(height: 9),
                _InspectorChecklistRow(label: material.isReady ? 'Processing completed' : 'Still processing', checked: material.isReady),
                const SizedBox(height: 9),
                _InspectorChecklistRow(
                  label: totalOutcomeCount == 0 ? 'No outcomes in course' : '$mappedOutcomeCount outcome${mappedOutcomeCount == 1 ? '' : 's'} mapped',
                  checked: totalOutcomeCount == 0 ? hasTopics : hasMapping,
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: AppColors.borderGray),
                const SizedBox(height: 13),
                _InspectorStatRow(label: 'Type', value: material.type.toUpperCase()),
                const SizedBox(height: 9),
                _InspectorStatRow(label: 'Ready topics', value: topics.isEmpty ? '0' : '$readyTopics/${topics.length}'),
                const SizedBox(height: 9),
                _InspectorStatRow(label: 'Updated', value: _relativeDate(material.updatedAt)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorChecklistRow extends StatelessWidget {
  final String label;
  final bool checked;

  const _InspectorChecklistRow({required this.label, required this.checked});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: checked ? AppColors.successText : AppColors.cardBg,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: checked ? AppColors.successText : AppColors.borderSoft),
          ),
          child: checked ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
        ),
        const SizedBox(width: 9),
        Expanded(child: Text(label, style: TextStyle(fontSize: 12.7, fontWeight: FontWeight.w800, color: AppColors.textTitle))),
      ],
    );
  }
}

class _InspectorStatRow extends StatelessWidget {
  final String label;
  final String value;

  const _InspectorStatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textMuted))),
        Text(value, style: TextStyle(fontSize: 12.8, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
      ],
    );
  }
}


class _GradientHeaderPill extends StatelessWidget {
  final String label;
  final Color? dotColor;

  const _GradientHeaderPill({required this.label, this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: AppColors.textTitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientHeaderMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _GradientHeaderMetric({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.textTitle, height: 1.0),
          ),
        ],
      ),
    );
  }
}

class _GradientHeaderIconButton extends StatelessWidget {
  final String tooltip;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onTap;

  const _GradientHeaderIconButton({required this.tooltip, required this.icon, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGray),
            ),
            child: loading
                ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(icon, size: 18, color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}

class _GradientHeaderOpenButton extends StatelessWidget {
  final String url;

  const _GradientHeaderOpenButton({required this.url});

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: _open,
        icon: const Icon(Icons.open_in_new_rounded, size: 16),
        label: const Text('Open file'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

