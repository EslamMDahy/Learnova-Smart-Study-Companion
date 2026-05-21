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
    required this.previewInteractive,
  });

  @override
  Widget build(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    final pdfPreviewActive = widget.previewInteractive && !_reviewerDialogOpen;
    return Container(
      color: const Color(0xFFF3F6FA),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1120;
          final stageHeight = compact
              ? 620.0
              : (constraints.maxHeight - 190).clamp(620.0, 900.0).toDouble();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 96),
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
                ),
                const SizedBox(height: 18),
                if (compact)
                  Column(
                    children: [
                      _DocumentStage(
                        material: widget.material,
                        downloadUrl: widget.downloadUrl,
                        urlLoading: widget.urlLoading,
                        onRefreshUrl: widget.onRefreshUrl,
                        previewInteractive: pdfPreviewActive,
                        height: stageHeight,
                      ),
                      const SizedBox(height: 18),
                      _ReviewerSidePanel(
                        material: widget.material,
                        topics: widget.topics,
                        topicsLoading: widget.topicsLoading,
                        outcomes: widget.outcomes,
                        mappedOutcomeIds: widget.mappedOutcomeIds,
                        readyTopics: widget.readyTopics,
                        onTopicTap: widget.onTopicTap,
                        onCreateTopicManual: widget.onCreateTopicManual,
                        onReviewerDialogOpenChanged: _setReviewerDialogOpen,
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _DocumentStage(
                          material: widget.material,
                          downloadUrl: widget.downloadUrl,
                          urlLoading: widget.urlLoading,
                          onRefreshUrl: widget.onRefreshUrl,
                          previewInteractive: pdfPreviewActive,
                          height: stageHeight,
                        ),
                      ),
                      const SizedBox(width: 18),
                      SizedBox(
                        width: 430,
                        child: _ReviewerSidePanel(
                          material: widget.material,
                          topics: widget.topics,
                          topicsLoading: widget.topicsLoading,
                          outcomes: widget.outcomes,
                          mappedOutcomeIds: widget.mappedOutcomeIds,
                          readyTopics: widget.readyTopics,
                          onTopicTap: widget.onTopicTap,
                          onCreateTopicManual: widget.onCreateTopicManual,
                          onReviewerDialogOpenChanged: _setReviewerDialogOpen,
                        ),
                      ),
                    ],
                  ),
              ],
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
  });

  @override
  Widget build(BuildContext context) {
    final status = _materialStatusLabel(material);
    final statusColor = _materialStatusColor(material);
    final fileName = (material.fileName ?? '').trim();
    final subtitle = [
      if (fileName.isNotEmpty) fileName,
      module.title,
    ].join('  •  ');

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF147EF5), Color(0xFF5B8CFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33147EF5),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TinyBadge(
                      label: 'PDF Reviewer',
                      color: AppColors.primary,
                      background: const Color(0xFFEAF3FF),
                    ),
                    const SizedBox(width: 8),
                    _TinyBadge(
                      label: status,
                      color: statusColor,
                      background: statusColor.withOpacity(0.10),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  material.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1.1,
                    letterSpacing: -0.4,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textTitle,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ReviewerStatPill(
                icon: Icons.account_tree_outlined,
                label: 'Topics',
                value: '${topics.length}',
                helper: '$readyTopics ready',
              ),
              _ReviewerStatPill(
                icon: Icons.flag_outlined,
                label: 'Outcomes',
                value: totalOutcomeCount == 0 ? '—' : '$mappedOutcomeCount/$totalOutcomeCount',
                helper: totalOutcomeCount == 0 ? 'no outcomes' : 'mapped',
              ),
              _ReviewerStatPill(
                icon: Icons.storage_rounded,
                label: material.pageCount != null ? 'Pages' : 'Size',
                value: material.pageCount != null
                    ? '${material.pageCount}'
                    : material.fileSize != null
                        ? _MetaStripW._fmt(material.fileSize!)
                        : '—',
                helper: 'document',
              ),
              _HeaderIconButton(
                tooltip: 'Refresh preview URL',
                icon: urlLoading ? null : Icons.refresh_rounded,
                loading: urlLoading,
                onTap: urlLoading ? null : onRefreshUrl,
              ),
              if (downloadUrl != null && downloadUrl!.isNotEmpty)
                _OpenDocumentButton(url: downloadUrl!),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentStage extends StatelessWidget {
  final MaterialItem material;
  final String? downloadUrl;
  final bool urlLoading;
  final VoidCallback onRefreshUrl;
  final bool previewInteractive;
  final double height;

  const _DocumentStage({
    required this.material,
    required this.downloadUrl,
    required this.urlLoading,
    required this.onRefreshUrl,
    required this.previewInteractive,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26111827),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Column(
          children: [
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF101827), Color(0xFF151F32)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                    ),
                    child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Document canvas',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _documentMetaLine(material),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.58)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _DarkToolbarChip(icon: Icons.remove_red_eye_outlined, label: previewInteractive ? 'Live preview' : 'Dialog mode'),
                  const SizedBox(width: 8),
                  _DarkToolbarChip(icon: Icons.lock_outline_rounded, label: 'Source file'),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFF111827),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: _FilePreviewWidget(
                      material: material,
                      downloadUrl: downloadUrl,
                      loading: urlLoading,
                      onRefresh: onRefreshUrl,
                      interactive: previewInteractive,
                    ),
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

class _ReviewerSidePanel extends StatelessWidget {
  final MaterialItem material;
  final List<TopicItem> topics;
  final bool topicsLoading;
  final List<LearningOutcome> outcomes;
  final Set<int> mappedOutcomeIds;
  final int readyTopics;
  final void Function(TopicItem) onTopicTap;
  final Future<bool> Function(
    String title,
    String? description,
    List<int> learningOutcomeIds,
  ) onCreateTopicManual;
  final ValueChanged<bool> onReviewerDialogOpenChanged;

  const _ReviewerSidePanel({
    required this.material,
    required this.topics,
    required this.topicsLoading,
    required this.outcomes,
    required this.mappedOutcomeIds,
    required this.readyTopics,
    required this.onTopicTap,
    required this.onCreateTopicManual,
    required this.onReviewerDialogOpenChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ReviewerActionsPanel(
          outcomes: outcomes,
          onCreateTopicManual: onCreateTopicManual,
          onReviewerDialogOpenChanged: onReviewerDialogOpenChanged,
        ),
        const SizedBox(height: 14),
        _CoveragePanel(
          topics: topics,
          readyTopics: readyTopics,
          outcomes: outcomes,
          mappedOutcomeIds: mappedOutcomeIds,
        ),
        const SizedBox(height: 14),
        _TopicRoadmapPanel(
          topics: topics,
          topicsLoading: topicsLoading,
          onTopicTap: onTopicTap,
        ),
      ],
    );
  }
}

class _ReviewerActionsPanel extends StatelessWidget {
  final List<LearningOutcome> outcomes;
  final Future<bool> Function(
    String title,
    String? description,
    List<int> learningOutcomeIds,
  ) onCreateTopicManual;
  final ValueChanged<bool> onReviewerDialogOpenChanged;

  const _ReviewerActionsPanel({
    required this.outcomes,
    required this.onCreateTopicManual,
    required this.onReviewerDialogOpenChanged,
  });

  Future<void> _openCaptureTopicDialog(BuildContext context) async {
    // Native PDF iframes can sit above Flutter overlays on web and swallow clicks.
    // Pause/remove the preview first, wait one frame, then show the dialog.
    onReviewerDialogOpenChanged(true);
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) {
      onReviewerDialogOpenChanged(false);
      return;
    }

    try {
      await showDialog<void>(
        context: context,
        barrierColor: const Color(0xAA0F172A),
        builder: (dialogContext) {
          return _CaptureTopicDialog(
            outcomes: outcomes,
            onCreate: onCreateTopicManual,
          );
        },
      );
    } finally {
      onReviewerDialogOpenChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PremiumPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SoftIcon(icon: Icons.edit_note_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reviewer actions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textTitle),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Keep the workspace clean. Add topics only when you need them.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _openCaptureTopicDialog(context),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Capture topic from PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE7EDF5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 17, color: AppColors.textMuted),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'The topic form opens as a focused popup, so the PDF canvas stays clean.',
                    style: TextStyle(fontSize: 12.3, color: AppColors.textMuted, height: 1.35),
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

class _CaptureTopicDialog extends StatelessWidget {
  final List<LearningOutcome> outcomes;
  final Future<bool> Function(
    String title,
    String? description,
    List<int> learningOutcomeIds,
  ) onCreate;

  const _CaptureTopicDialog({
    required this.outcomes,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final maxDialogHeight = MediaQuery.of(context).size.height - 56;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: maxDialogHeight),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SingleChildScrollView(
              child: _CaptureTopicPanel(
                outcomes: outcomes,
                onCreate: onCreate,
                onSaved: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: Material(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.close_rounded, size: 19, color: AppColors.textMuted),
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

class _CaptureTopicPanel extends StatefulWidget {
  final List<LearningOutcome> outcomes;
  final Future<bool> Function(
    String title,
    String? description,
    List<int> learningOutcomeIds,
  ) onCreate;
  final VoidCallback? onSaved;

  const _CaptureTopicPanel({
    required this.outcomes,
    required this.onCreate,
    this.onSaved,
  });

  @override
  State<_CaptureTopicPanel> createState() => _CaptureTopicPanelState();
}

class _CaptureTopicPanelState extends State<_CaptureTopicPanel> {
  final _titleCtrl = TextEditingController();
  final _pageCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final Set<int> _selectedOutcomeIds = <int>{};
  bool _saving = false;
  bool _submitted = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _pageCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _saving) return;

    final note = _noteCtrl.text.trim();
    final pages = _pageCtrl.text.trim();
    final descriptionParts = <String>[
      if (pages.isNotEmpty) 'Page reference: $pages',
      if (note.isNotEmpty) note,
    ];

    setState(() => _saving = true);
    final ok = await widget.onCreate(
      title,
      descriptionParts.isEmpty ? null : descriptionParts.join('\n\n'),
      _selectedOutcomeIds.toList(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) return;

    _titleCtrl.clear();
    _pageCtrl.clear();
    _noteCtrl.clear();
    setState(() {
      _submitted = false;
      _selectedOutcomeIds.clear();
    });
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    return _PremiumPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE8EDF4))),
            ),
            child: Row(
              children: [
                _SoftIcon(icon: Icons.add_task_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capture a topic',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textTitle),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Turn the part you are reviewing into a structured lesson point.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CleanTextField(
                  controller: _titleCtrl,
                  enabled: !_saving,
                  label: 'Topic name',
                  hint: 'e.g. Variables, types, and expressions',
                  icon: Icons.title_rounded,
                  errorText: _submitted && _titleCtrl.text.trim().isEmpty ? 'Topic name is required' : null,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 10),
                _CleanTextField(
                  controller: _pageCtrl,
                  enabled: !_saving,
                  label: 'Page / section reference',
                  hint: 'Optional, e.g. pages 12–15',
                  icon: Icons.bookmark_border_rounded,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 10),
                _CleanTextField(
                  controller: _noteCtrl,
                  enabled: !_saving,
                  label: 'Instructor note',
                  hint: 'What should students understand here?',
                  icon: Icons.notes_rounded,
                  minLines: 3,
                  maxLines: 4,
                ),
                if (widget.outcomes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.flag_outlined, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 7),
                      const Expanded(
                        child: Text(
                          'Map learning outcomes',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.textMuted),
                        ),
                      ),
                      if (_selectedOutcomeIds.isNotEmpty)
                        Text(
                          '${_selectedOutcomeIds.length} selected',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 210),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final outcome in widget.outcomes) ...[
                            _OutcomeSelectTile(
                              outcome: outcome,
                              selected: _selectedOutcomeIds.contains(outcome.id),
                              enabled: !_saving,
                              onTap: () {
                                if (_saving) return;
                                setState(() {
                                  if (!_selectedOutcomeIds.add(outcome.id)) {
                                    _selectedOutcomeIds.remove(outcome.id);
                                  }
                                });
                              },
                            ),
                            if (outcome != widget.outcomes.last) const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add_rounded, size: 19),
                    label: Text(_saving ? 'Saving topic...' : 'Save topic to this PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.55),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
                    ),
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

class _CoveragePanel extends StatelessWidget {
  final List<TopicItem> topics;
  final int readyTopics;
  final List<LearningOutcome> outcomes;
  final Set<int> mappedOutcomeIds;

  const _CoveragePanel({
    required this.topics,
    required this.readyTopics,
    required this.outcomes,
    required this.mappedOutcomeIds,
  });

  @override
  Widget build(BuildContext context) {
    final topicProgress = topics.isEmpty ? 0.0 : readyTopics / topics.length;
    final outcomeProgress = outcomes.isEmpty ? 0.0 : mappedOutcomeIds.length / outcomes.length;

    return _PremiumPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SoftIcon(icon: Icons.insights_rounded, color: const Color(0xFF7C3AED)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Review coverage',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textTitle),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ProgressInsightRow(
            label: 'Topics reviewed',
            value: topics.isEmpty ? '0' : '$readyTopics/${topics.length}',
            progress: topicProgress,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _ProgressInsightRow(
            label: 'Outcomes mapped',
            value: outcomes.isEmpty ? '—' : '${mappedOutcomeIds.length}/${outcomes.length}',
            progress: outcomeProgress,
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE7EDF5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates_outlined, size: 18, color: Color(0xFFD97706)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _coverageHint,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _coverageHint {
    if (topics.isEmpty) return 'Start by capturing the first topic from the PDF section you are reviewing.';
    if (outcomes.isNotEmpty && mappedOutcomeIds.isEmpty) {
      return 'Topics exist, but none are mapped to learning outcomes yet.';
    }
    return 'Use this panel as a quick quality check before generating questions.';
  }
}

class _TopicRoadmapPanel extends StatelessWidget {
  final List<TopicItem> topics;
  final bool topicsLoading;
  final void Function(TopicItem) onTopicTap;

  const _TopicRoadmapPanel({
    required this.topics,
    required this.topicsLoading,
    required this.onTopicTap,
  });

  @override
  Widget build(BuildContext context) {
    final parentTopics = topics.where((t) => t.parentTopicId == null).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final childrenByParent = <int, List<TopicItem>>{};
    for (final topic in topics.where((t) => t.parentTopicId != null)) {
      childrenByParent.putIfAbsent(topic.parentTopicId!, () => <TopicItem>[]).add(topic);
    }
    for (final children in childrenByParent.values) {
      children.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }

    return _PremiumPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                _SoftIcon(icon: Icons.route_rounded, color: const Color(0xFF0F766E)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Topic map',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textTitle),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Open any topic to review or generate questions.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                _CountBadge(value: '${topics.length}'),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EDF4)),
          if (topicsLoading)
            const SizedBox(
              height: 190,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (topics.isEmpty)
            const _EmptyTopicMap()
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                shrinkWrap: true,
                itemCount: parentTopics.length,
                itemBuilder: (context, index) {
                  final topic = parentTopics[index];
                  final children = childrenByParent[topic.id] ?? const <TopicItem>[];
                  return Padding(
                    padding: EdgeInsets.only(bottom: index == parentTopics.length - 1 ? 0 : 10),
                    child: _RoadmapTopicTile(
                      topic: topic,
                      index: index,
                      children: children,
                      onTopicTap: onTopicTap,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _RoadmapTopicTile extends StatelessWidget {
  final TopicItem topic;
  final int index;
  final List<TopicItem> children;
  final void Function(TopicItem) onTopicTap;

  const _RoadmapTopicTile({
    required this.topic,
    required this.index,
    required this.children,
    required this.onTopicTap,
  });

  @override
  Widget build(BuildContext context) {
    final ready = topic.readiness == TopicReadiness.ready || topic.isReviewed;
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => onTopicTap(topic),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6EBF2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      topic.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.textTitle),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TinyBadge(
                    label: ready ? 'Ready' : 'Draft',
                    color: ready ? _K.green : _K.amber,
                    background: ready ? _K.greenSoft : _K.amberSoft,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
                ],
              ),
              if ((topic.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  topic.description!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.2, color: AppColors.textMuted, height: 1.35),
                ),
              ],
              if (children.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final child in children)
                      InkWell(
                        onTap: () => onTopicTap(child),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.subdirectory_arrow_right_rounded, size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 5),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 170),
                                child: Text(
                                  child.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textTitle),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CleanTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String hint;
  final IconData icon;
  final String? errorText;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onSubmitted;

  const _CleanTextField({
    required this.controller,
    required this.enabled,
    required this.label,
    required this.hint,
    required this.icon,
    this.errorText,
    this.minLines = 1,
    this.maxLines = 1,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      minLines: minLines,
      maxLines: maxLines,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textTitle),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textMuted),
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE4EAF2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE4EAF2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _OutcomeSelectTile extends StatelessWidget {
  final LearningOutcome outcome;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _OutcomeSelectTile({
    required this.outcome,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEAF3FF) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: selected ? AppColors.primary.withOpacity(0.40) : const Color(0xFFE4EAF2)),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selected ? AppColors.primary : const Color(0xFFCBD5E1)),
                ),
                child: selected ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outcome.code.isNotEmpty ? outcome.code : 'LO',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      outcome.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textTitle, height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressInsightRow extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _ProgressInsightRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.textMuted)),
            ),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress.clamp(0.0, 1.0).toDouble(),
            backgroundColor: const Color(0xFFE8EEF6),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _PremiumPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _PremiumPanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ReviewerStatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String helper;

  const _ReviewerStatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE6EBF2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
                Text(helper, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _TinyBadge({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String value;

  const _CountBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary),
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SoftIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 19, color: color),
    );
  }
}

class _DarkToolbarChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DarkToolbarChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withOpacity(0.76)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.76))),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final String tooltip;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onTap;

  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE6EBF2)),
            ),
            child: loading
                ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(icon, size: 19, color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}

class _OpenDocumentButton extends StatelessWidget {
  final String url;

  const _OpenDocumentButton({required this.url});

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: _open,
        icon: const Icon(Icons.open_in_new_rounded, size: 16),
        label: const Text('Open PDF'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF111827),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _EmptyTopicMap extends StatelessWidget {
  const _EmptyTopicMap();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.route_outlined, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 13),
          const Text(
            'No topic map yet',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textTitle),
          ),
          const SizedBox(height: 6),
          const Text(
            'Capture topics while reading the PDF. They will appear here as a clean review map.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

String _materialStatusLabel(MaterialItem material) {
  if (material.isReady || material.status == 'uploaded') return 'Ready';
  if (material.isProcessing) return 'Processing';
  if (material.isError) return 'Needs attention';
  return 'Draft';
}

Color _materialStatusColor(MaterialItem material) {
  if (material.isReady || material.status == 'uploaded') return _K.green;
  if (material.isProcessing) return _K.amber;
  if (material.isError) return AppColors.dangerText;
  return AppColors.textMuted;
}

String _documentMetaLine(MaterialItem material) {
  final parts = <String>[];
  final fileName = (material.fileName ?? '').trim();
  if (fileName.isNotEmpty) parts.add(fileName);
  if (material.pageCount != null) parts.add('${material.pageCount} pages');
  if (material.fileSize != null) parts.add(_MetaStripW._fmt(material.fileSize!));
  if (parts.isEmpty) return material.type.toUpperCase();
  return parts.join('  •  ');
}

// ─────────────────────────────────────────────────────────────────────────────
//  FILE PREVIEW
// ─────────────────────────────────────────────────────────────────────────────
enum _PK { pdf, image, video, audio, link, other }

class _FilePreviewWidget extends StatelessWidget {
  final MaterialItem material; final String? downloadUrl;
  final bool loading; final VoidCallback onRefresh;
  final bool interactive;
  const _FilePreviewWidget({required this.material, required this.downloadUrl,
      required this.loading, required this.onRefresh, required this.interactive});

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
    if (loading) return const _LoaderW(label: 'Loading preview…');
    if (material.isProcessing && material.status != 'uploaded') {
      return const _PlaceholderW(icon: Icons.hourglass_top_rounded,
        iconColor: _K.amber, iconBg: _K.amberSoft, title: 'Processing…',
        sub: 'Your file is being processed. Preview will be available shortly.');
    }
    if (material.isError && material.status != 'uploaded') {
      return _PlaceholderW(icon: Icons.error_outline_rounded,
        iconColor: AppColors.dangerText, iconBg: _K.redSoft, title: 'Processing failed',
        sub: 'Something went wrong processing this file.',
        actionLabel: 'Retry', onAction: onRefresh);
    }
    if (downloadUrl == null || downloadUrl!.isEmpty) {
      return _PlaceholderW(icon: Icons.link_off_rounded, iconColor: AppColors.textMuted,
          iconBg: _K.bg, title: 'Preview unavailable',
          sub: 'Could not load a URL for this file.',
          actionLabel: 'Retry', onAction: onRefresh);
    }

    final url = downloadUrl!;
    return switch (_kind) {
      _PK.pdf   => _PdfPreviewWidget(url: url, material: material, interactive: interactive),
      _PK.image => _ImagePreviewWidget(url: url),
      _PK.video => _VideoPreviewWidget(url: url, material: material),
      _PK.audio => _AudioPreviewWidget(url: url, material: material),
      _PK.link  => _LinkPreviewWidget(url: url),
      _PK.other => _FallbackWidget(url: url, material: material),
    };
  }
}

class _PdfPreviewWidget extends StatefulWidget {
  final String url; final MaterialItem material;
  final bool interactive;
  const _PdfPreviewWidget({required this.url, required this.material, required this.interactive});
  @override
  State<_PdfPreviewWidget> createState() => _PdfPreviewWidgetState();
}

class _PdfPreviewWidgetState extends State<_PdfPreviewWidget> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'pdf-iframe-${widget.material.id}';
    _registerView();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePointerEvents());
  }

  void _updatePointerEvents() {
    updatePdfPreviewInteractivity(viewType: _viewId, interactive: widget.interactive);
  }

  @override
  void didUpdateWidget(covariant _PdfPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interactive != widget.interactive || oldWidget.url != widget.url) {
      _updatePointerEvents();
    }
  }

  void _registerView() {
    registerPdfPreviewView(
      viewType: _viewId,
      url: widget.url,
      interactive: widget.interactive,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.interactive) {
      return _PlaceholderW(
        icon: Icons.picture_as_pdf_rounded,
        iconColor: AppColors.primary,
        iconBg: _K.blueSoft,
        title: 'Preview hidden while editing',
        sub: 'The PDF viewer is hidden so the popup controls stay fully clickable.',
        actionLabel: 'Open file',
        onAction: () async {
          final uri = Uri.tryParse(widget.url);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.platformDefault);
          }
        },
      );
    }
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
      child: HtmlElementView(viewType: _viewId),
    );
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
          Container(decoration: const BoxDecoration(gradient: RadialGradient(
              colors: [Color(0xFF1A2332), Color(0xFF0D1117)]))),
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
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.55))),
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
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
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
          Text(it.$2, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
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
    if (big) {
      return ElevatedButton.icon(onPressed: _open,
        icon: const Icon(Icons.open_in_new_rounded, size: 14), label: const Text('Open'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
            foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
    }
    return Material(color: AppColors.primary, borderRadius: BorderRadius.circular(7),
        child: InkWell(hoverColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent, overlayColor: const WidgetStatePropertyAll(Colors.transparent), onTap: _open, borderRadius: BorderRadius.circular(7),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.open_in_new_rounded, size: 12, color: Colors.white),
                  SizedBox(width: 5),
                  Text('Open', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                ]))));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TOPICS SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────
