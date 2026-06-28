part of 'materials_tab.dart';

class _PdfPageRange {
  final int start;
  final int end;

  const _PdfPageRange({required this.start, required this.end});

  int get pageCount => end - start + 1;

  String get label => start == end
      ? 'Page $start'
      : 'Pages $start–$end';

  String get countLabel => pageCount == 1
      ? '1 page'
      : '$pageCount pages';

  String get explicitLabel => start == end
      ? 'Start/End page $start'
      : 'Start $start • End $end';
}

_PdfPageRange? _topicPdfPageRange(TopicItem topic, MaterialItem material) {
  final rawStart = topic.pageStart;
  final rawEnd = topic.pageEnd;
  if (rawStart == null && rawEnd == null) return null;

  final start = rawStart ?? rawEnd;
  final end = rawEnd ?? rawStart;
  if (start == null || end == null || start <= 0 || end <= 0) return null;

  final orderedStart = start <= end ? start : end;
  final orderedEnd = end >= start ? end : start;

  final maxPages = material.pageCount;
  if (maxPages == null || maxPages <= 0) {
    return _PdfPageRange(start: orderedStart, end: orderedEnd);
  }

  final normalizedStart = orderedStart.clamp(1, maxPages).toInt();
  final normalizedEnd = orderedEnd.clamp(normalizedStart, maxPages).toInt();
  return _PdfPageRange(start: normalizedStart, end: normalizedEnd);
}

_PdfPageRange? _combinedTopicChildrenPdfPageRange(
  List<TopicItem> childTopics,
  MaterialItem material,
) {
  final ranges = childTopics
      .map((topic) => _topicPdfPageRange(topic, material))
      .whereType<_PdfPageRange>()
      .toList();
  if (ranges.isEmpty) return null;

  final start = ranges.map((range) => range.start).reduce((a, b) => a < b ? a : b);
  final end = ranges.map((range) => range.end).reduce((a, b) => a > b ? a : b);
  return _PdfPageRange(start: start, end: end);
}

_PdfPageRange? _effectiveLearningItemPdfPageRange({
  required TopicItem topic,
  required MaterialItem material,
  TopicItem? parentTopic,
  List<TopicItem> childTopics = const <TopicItem>[],
}) {
  return _topicPdfPageRange(topic, material) ??
      _combinedTopicChildrenPdfPageRange(childTopics, material) ??
      (parentTopic == null ? null : _topicPdfPageRange(parentTopic, material));
}

String _learningItemDocumentSubtitle({
  required String label,
  required TopicItem topic,
  _PdfPageRange? pageRange,
  bool loadingRange = false,
}) {
  final parts = <String>['$label: ${topic.title}'];
  if (pageRange != null) {
    parts.add(pageRange.explicitLabel);
  } else if (loadingRange) {
    parts.add('Loading start/end');
  } else {
    parts.add('Page range unavailable');
  }
  return parts.join(' • ');
}


bool _topicPageRangeIsLoading(TopicItem topic, bool detailsLoaded, bool detailsFailed) {
  return topic.isAiGenerated &&
      topic.pageStart == null &&
      topic.pageEnd == null &&
      !detailsLoaded &&
      !detailsFailed;
}

class _TopicRangeLoadingOverlay extends StatelessWidget {
  final String title;

  const _TopicRangeLoadingOverlay({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderGray),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowThin,
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.textTitle,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading the start/end pages for this document viewer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicRangeUnavailableOverlay extends StatelessWidget {
  final VoidCallback onRefresh;

  const _TopicRangeUnavailableOverlay({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderGray),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowThin,
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.description, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              'Start/end pages unavailable',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.textTitle,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This topic viewer needs page_start and page_end from the topic details. Refreshing the PDF URL will not open the full document here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh preview URL'),
            ),
          ],
        ),
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
  final _PdfPageRange? pageRange;
  final bool pageRangeLoading;
  final bool requirePageRange;
  final String? scopeTitle;
  final String? scopeSubtitle;

  const _DocumentStage({
    required this.material,
    required this.downloadUrl,
    required this.urlLoading,
    required this.onRefreshUrl,
    required this.previewInteractive,
    required this.height,
    this.pageRange,
    this.pageRangeLoading = false,
    this.requirePageRange = false,
    this.scopeTitle,
    this.scopeSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final viewerStateLabel = previewInteractive ? 'Live preview' : 'Safe mode';
    final title = scopeTitle ?? 'Document viewer';
    final meta = _documentMetaLine(material, pageRange: pageRange, scopeSubtitle: scopeSubtitle);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowThin,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border(bottom: BorderSide(color: AppColors.borderGray)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
                  ),
                  child: Icon(_materialTypeIcon(material), color: AppColors.primary, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.textTitle),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.2, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (pageRange != null) ...[
                  _ViewerToolbarChip(
                    icon: Icons.filter_alt_rounded,
                    label: pageRange!.explicitLabel,
                    highlighted: true,
                  ),
                  const SizedBox(width: 8),
                ] else if (pageRangeLoading) ...[
                  const _ViewerToolbarChip(
                    icon: Icons.hourglass_top_rounded,
                    label: 'Loading start/end',
                    highlighted: true,
                  ),
                  const SizedBox(width: 8),
                ],
                _ViewerToolbarChip(
                  icon: previewInteractive ? Icons.visibility_rounded : Icons.lock_outline_rounded,
                  label: viewerStateLabel,
                  highlighted: previewInteractive,
                ),
                const SizedBox(width: 8),
                _ViewerIconButton(
                  tooltip: 'Refresh preview URL',
                  icon: urlLoading ? null : Icons.refresh_rounded,
                  loading: urlLoading,
                  onTap: urlLoading ? null : onRefreshUrl,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.documentCanvasBg,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    border: Border.all(color: AppColors.borderGray),
                  ),
                  child: pageRangeLoading
                      ? const _TopicRangeLoadingOverlay(
                          title: 'Preparing topic pages',
                        )
                      : requirePageRange && pageRange == null
                          ? _TopicRangeUnavailableOverlay(onRefresh: onRefreshUrl)
                          : _FilePreviewWidget(
                              material: material,
                              downloadUrl: downloadUrl,
                              loading: urlLoading,
                              onRefresh: onRefreshUrl,
                              interactive: previewInteractive,
                              pageRange: pageRange,
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

class _ViewerToolbarChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;

  const _ViewerToolbarChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.primary : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primarySoft : AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: highlighted ? AppColors.primary.withValues(alpha: 0.22) : AppColors.borderGray),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

class _ViewerIconButton extends StatelessWidget {
  final String tooltip;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onTap;

  const _ViewerIconButton({
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
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGray),
            ),
            child: loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(icon, size: 18, color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}

class _FileTopicsSection extends StatelessWidget {
  final MaterialItem material;
  final List<TopicItem> topics;
  final bool topicsLoading;
  final List<LearningOutcome> outcomes;
  final Set<int> mappedOutcomeIds;
  final int readyTopics;
  final void Function(TopicItem) onTopicTap;
  final VoidCallback onAddTopic;

  const _FileTopicsSection({
    required this.material,
    required this.topics,
    required this.topicsLoading,
    required this.outcomes,
    required this.mappedOutcomeIds,
    required this.readyTopics,
    required this.onTopicTap,
    required this.onAddTopic,
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
    final subtopicCount = topics.length - parentTopics.length;
    final outcomeText = outcomes.isEmpty ? '—' : '${mappedOutcomeIds.length}/${outcomes.length}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
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
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                final title = Row(
                  children: [
                    const _SoftIcon(icon: Icons.account_tree_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Topics in this file', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
                          const SizedBox(height: 3),
                          Text(
                            'Manual topics connected to this uploaded material.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final action = ElevatedButton.icon(
                  onPressed: onAddTopic,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add topic'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 12), action],
                  );
                }
                return Row(children: [Expanded(child: title), const SizedBox(width: 14), action]);
              },
            ),
          ),
          Divider(height: 1, color: AppColors.borderGray),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TopicSummaryChip(label: 'Topics', value: '${parentTopics.length}'),
                _TopicSummaryChip(label: 'Subtopics', value: '$subtopicCount'),
                _TopicSummaryChip(label: 'Ready', value: topics.isEmpty ? '0' : '$readyTopics/${topics.length}'),
                _TopicSummaryChip(label: 'Outcomes', value: outcomeText),
              ],
            ),
          ),
          if (topicsLoading)
            const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (topics.isEmpty)
            const _EmptyTopicMap()
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                children: [
                  for (var i = 0; i < parentTopics.length; i++) ...[
                    _RoadmapTopicTile(
                      topic: parentTopics[i],
                      index: i,
                      children: childrenByParent[parentTopics[i].id] ?? const <TopicItem>[],
                      onTopicTap: onTopicTap,
                    ),
                    if (i != parentTopics.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TopicSummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const _TopicSummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
          const SizedBox(width: 7),
          Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
        ],
      ),
    );
  }
}

