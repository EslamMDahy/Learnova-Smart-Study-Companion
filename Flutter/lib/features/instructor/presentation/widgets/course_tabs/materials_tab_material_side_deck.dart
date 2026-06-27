part of 'materials_tab.dart';

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
    Theme.of(context);
    return _MaterialSideDeck(
      material: material,
      topics: topics,
      topicsLoading: topicsLoading,
      outcomes: outcomes,
      mappedOutcomeIds: mappedOutcomeIds,
      readyTopics: readyTopics,
      onTopicTap: onTopicTap,
      onCreateTopicManual: onCreateTopicManual,
      onReviewerDialogOpenChanged: onReviewerDialogOpenChanged,
    );
  }
}

class _MaterialSideDeck extends StatelessWidget {
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

  const _MaterialSideDeck({
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

  Future<void> _openCaptureTopicDialog(BuildContext context) async {
    onReviewerDialogOpenChanged(true);
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) {
      onReviewerDialogOpenChanged(false);
      return;
    }

    try {
      await showDialog<void>(
        context: context,
        barrierColor: AppColors.overlayStrong,
        builder: (dialogContext) {
          return _CaptureTopicDialog(
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
    Theme.of(context);
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
    final topicProgress = topics.isEmpty ? 0.0 : readyTopics / topics.length;
    final outcomeProgress = outcomes.isEmpty ? 0.0 : mappedOutcomeIds.length / outcomes.length;
    final visibleTopics = parentTopics.take(5).toList();

    return _PremiumPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 15),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderGray)),
            ),
            child: Row(
              children: [
                const _SoftIcon(icon: Icons.account_tree_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'File structure',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textTitle),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'This file only contains topics and subtopics inside its module.',
                        style: TextStyle(fontSize: 12.3, color: AppColors.textMuted, height: 1.35),
                      ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MaterialPathSummary(
                  topicCount: parentTopics.length,
                  subtopicCount: subtopicCount,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _openCaptureTopicDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Add topic to this file'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _MaterialMetricTile(label: 'Topics', value: '${parentTopics.length}', caption: '$readyTopics ready')),
                    const SizedBox(width: 10),
                    Expanded(child: _MaterialMetricTile(label: 'Subtopics', value: '$subtopicCount', caption: 'nested items')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _MaterialMetricTile(label: 'Outcomes', value: outcomes.isEmpty ? '—' : '${mappedOutcomeIds.length}/${outcomes.length}', caption: 'mapped')),
                    const SizedBox(width: 10),
                    Expanded(child: _MaterialMetricTile(label: 'Source', value: material.type.toUpperCase(), caption: material.pageCount != null ? '${material.pageCount} pages' : 'file')),
                  ],
                ),
                const SizedBox(height: 18),
                _ProgressInsightRow(
                  label: 'Topic review',
                  value: topics.isEmpty ? '0' : '$readyTopics/${topics.length}',
                  progress: topicProgress,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                _ProgressInsightRow(
                  label: 'Outcome mapping',
                  value: outcomes.isEmpty ? '—' : '${mappedOutcomeIds.length}/${outcomes.length}',
                  progress: outcomeProgress,
                  color: AppColors.purpleText,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Topics in this file',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.textTitle),
                      ),
                    ),
                    _CountBadge(value: '${topics.length}'),
                  ],
                ),
                const SizedBox(height: 11),
                if (topicsLoading)
                  Container(
                    height: 150,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (topics.isEmpty)
                  const _EmptyTopicMap()
                else ...[
                  for (var i = 0; i < visibleTopics.length; i++) ...[
                    _MaterialCompactTopicTile(
                      topic: visibleTopics[i],
                      index: i,
                      children: childrenByParent[visibleTopics[i].id] ?? const <TopicItem>[],
                      onTopicTap: onTopicTap,
                    ),
                    if (i != visibleTopics.length - 1) const SizedBox(height: 9),
                  ],
                  if (parentTopics.length > visibleTopics.length) ...[
                    const SizedBox(height: 10),
                    Text(
                      '+ ${parentTopics.length - visibleTopics.length} more topic${parentTopics.length - visibleTopics.length == 1 ? '' : 's'} in the structure tree',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialPathSummary extends StatelessWidget {
  final int topicCount;
  final int subtopicCount;

  const _MaterialPathSummary({required this.topicCount, required this.subtopicCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        children: [
          const _MaterialPathStep(icon: Icons.insert_drive_file_rounded, title: 'Material file', value: 'current'),
          const _MaterialPathConnector(),
          _MaterialPathStep(icon: Icons.topic_rounded, title: 'Topics', value: '$topicCount'),
          const _MaterialPathConnector(),
          _MaterialPathStep(icon: Icons.subdirectory_arrow_right_rounded, title: 'Subtopics', value: '$subtopicCount'),
        ],
      ),
    );
  }
}

class _MaterialPathStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _MaterialPathStep({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 17, color: AppColors.primary),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textTitle),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _MaterialPathConnector extends StatelessWidget {
  const _MaterialPathConnector();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 1.5,
        height: 14,
        margin: const EdgeInsets.only(left: 16.25),
        color: AppColors.borderGray,
      ),
    );
  }
}

class _MaterialMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String caption;

  const _MaterialMetricTile({required this.label, required this.value, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted)),
          const SizedBox(height: 5),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textTitle, height: 1.0)),
          const SizedBox(height: 5),
          Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _MaterialCompactTopicTile extends StatelessWidget {
  final TopicItem topic;
  final int index;
  final List<TopicItem> children;
  final void Function(TopicItem) onTopicTap;

  const _MaterialCompactTopicTile({required this.topic, required this.index, required this.children, required this.onTopicTap});

  @override
  Widget build(BuildContext context) {
    final ready = topic.readiness == TopicReadiness.ready || topic.isReviewed;
    return Material(
      color: AppColors.surfaceBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onTopicTap(topic),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topic.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
                    const SizedBox(height: 4),
                    Text(
                      children.isEmpty ? 'No subtopics yet' : '${children.length} subtopic${children.length == 1 ? '' : 's'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _TinyBadge(
                label: ready ? 'Ready' : 'Draft',
                color: ready ? _K.green : _K.amber,
                background: ready ? _K.greenSoft : _K.amberSoft,
              ),
            ],
          ),
        ),
      ),
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
        barrierColor: AppColors.overlayStrong,
        builder: (dialogContext) {
          return _CaptureTopicDialog(
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
    Theme.of(context);
    return _PremiumPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SoftIcon(icon: Icons.edit_note_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reviewer actions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textTitle),
                    ),
                    const SizedBox(height: 3),
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
              color: AppColors.surfaceBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGray),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 17, color: AppColors.textMuted),
                const SizedBox(width: 9),
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

