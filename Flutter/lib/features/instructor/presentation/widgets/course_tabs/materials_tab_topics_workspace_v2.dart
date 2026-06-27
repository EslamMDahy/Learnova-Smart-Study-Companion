part of 'materials_tab.dart';

class _ManualTabContent extends StatelessWidget {
  final TextEditingController ctrl;
  final String? error;
  const _ManualTabContent({required this.ctrl, this.error, super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink(); // unused, kept for compat
}

class _AITabContent extends StatelessWidget {
  const _AITabContent({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink(); // unused, kept for compat
}


class _AddTopicBtnW extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  final Color color, bg;
  const _AddTopicBtnW({required this.icon, required this.label, required this.onTap,
      required this.color, required this.bg,});
  @override
  Widget build(BuildContext context) => InkWell(hoverColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent, overlayColor: const WidgetStatePropertyAll(Colors.transparent), onTap: onTap,
      borderRadius: BorderRadius.circular(7), child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 13, color: color), const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],),),);
}

class _TopicsEmptyW extends StatelessWidget {
  final VoidCallback onAddManual;
  const _TopicsEmptyW({required this.onAddManual});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.tag_rounded, size: 22, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text('No topics yet',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textTitle),),
          const SizedBox(height: 6),
          Text(
            'Use the "Add Topic" button above to add the first topic for this material.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.6),
          ),
        ],
      ),
    ),
  );
}

class _TopicItemW extends StatelessWidget {
  final TopicItem topic; final int index; final VoidCallback onTap;
  const _TopicItemW({required this.topic, required this.index, required this.onTap});
  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final readiness = _topicReadinessMeta(topic.readiness);
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: [BoxShadow(color: AppColors.shadowSoft, blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.badgeIndigoBg, AppColors.purpleBg]),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text('${index + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(topic.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textTitle)),
              const SizedBox(height: 7),
              Wrap(spacing: 6, runSpacing: 6, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: readiness.bg, borderRadius: BorderRadius.circular(999)),
                  child: Text(readiness.label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: readiness.fg)),
                ),
                if (topic.estimatedDurationMinutes != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(999)),
                    child: Text('~${topic.estimatedDurationMinutes} min', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                  ),
                if (topic.learningOutcomeIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(999)),
                    child: Text('${topic.learningOutcomeIds.length} LO${topic.learningOutcomeIds.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
              ],),
            ],),),
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textHint),
            ),
          ],),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TOPIC DRILL-DOWN PANEL
// ─────────────────────────────────────────────────────────────────────────────


class _TopicPanelWidget extends StatelessWidget {
  final ModuleItem module;
  final MaterialItem material;
  final TopicItem topic;
  final bool topicDetailsLoaded;
  final bool topicDetailsFailed;
  final List<TopicItem> allMaterialTopics;
  final List<LearningOutcome> outcomes;
  final String? downloadUrl;
  final bool urlLoading;
  final VoidCallback onRefreshUrl;
  final bool previewInteractive;
  final bool canPop;
  final VoidCallback onBack;
  final VoidCallback onRenameTopic;
  final VoidCallback onEditTopicSummary;
  final VoidCallback onEditTopicStatus;
  final VoidCallback onMapTopicOutcomes;
  final VoidCallback onDeleteTopic;
  final VoidCallback onAddSubtopic;
  final ValueChanged<TopicItem> onOpenSubtopic;

  const _TopicPanelWidget({
    required this.module,
    required this.material,
    required this.topic,
    required this.topicDetailsLoaded,
    required this.topicDetailsFailed,
    required this.allMaterialTopics,
    required this.outcomes,
    required this.downloadUrl,
    required this.urlLoading,
    required this.onRefreshUrl,
    required this.previewInteractive,
    required this.canPop,
    required this.onBack,
    required this.onRenameTopic,
    required this.onEditTopicSummary,
    required this.onEditTopicStatus,
    required this.onMapTopicOutcomes,
    required this.onDeleteTopic,
    required this.onAddSubtopic,
    required this.onOpenSubtopic,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final isSubtopic = topic.parentTopicId != null;
    final parentTopic = isSubtopic
        ? allMaterialTopics.cast<TopicItem?>().firstWhere(
              (t) => t?.id == topic.parentTopicId,
              orElse: () => null,
            )
        : null;
    final subtopics = allMaterialTopics
        .where((t) => t.parentTopicId == topic.id)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final mappedOutcomes = _mappedSubOutcomesForTopic(topic, outcomes);
    final inheritedOutcomeIds = <int>{};
    for (final subtopic in subtopics) {
      inheritedOutcomeIds.addAll(subtopic.learningOutcomeIds);
      for (final raw in subtopic.linkedOutcomeIds) {
        final parsed = int.tryParse(raw);
        if (parsed != null) inheritedOutcomeIds.add(parsed);
      }
      final legacy = int.tryParse(subtopic.linkedOutcomeId ?? '');
      if (legacy != null) inheritedOutcomeIds.add(legacy);
    }
    final inheritedParentOutcomeIds = <int>{};
    for (final outcome in outcomes) {
      if (!inheritedOutcomeIds.contains(outcome.id)) continue;
      if (outcome.parentLearningOutcomeId != null) {
        inheritedParentOutcomeIds.add(outcome.parentLearningOutcomeId!);
      } else {
        inheritedParentOutcomeIds.add(outcome.id);
      }
    }
    final inheritedOutcomes = outcomes
        .where((o) => o.isParentOutcome && inheritedParentOutcomeIds.contains(o.id))
        .toList();

    final child = isSubtopic
        ? _SubtopicWorkspacePage(
            module: module,
            material: material,
            topic: topic,
            parentTopic: parentTopic,
            topicDetailsLoaded: topicDetailsLoaded,
            topicDetailsFailed: topicDetailsFailed,
            mappedOutcomes: mappedOutcomes,
            totalOutcomes: outcomes.length,
            downloadUrl: downloadUrl,
            urlLoading: urlLoading,
            onRefreshUrl: onRefreshUrl,
            previewInteractive: previewInteractive,
            canPop: canPop,
            onBack: onBack,
            onRename: onRenameTopic,
            onEditSummary: onEditTopicSummary,
            onEditStatus: onEditTopicStatus,
            onMapOutcomes: onMapTopicOutcomes,
            onDelete: onDeleteTopic,
          )
        : _TopicWorkspacePage(
            module: module,
            material: material,
            topic: topic,
            topicDetailsLoaded: topicDetailsLoaded,
            topicDetailsFailed: topicDetailsFailed,
            subtopics: subtopics,
            inheritedOutcomes: inheritedOutcomes,
            allOutcomes: outcomes,
            totalOutcomes: outcomes.length,
            downloadUrl: downloadUrl,
            urlLoading: urlLoading,
            onRefreshUrl: onRefreshUrl,
            previewInteractive: previewInteractive,
            canPop: canPop,
            onBack: onBack,
            onRename: onRenameTopic,
            onEditSummary: onEditTopicSummary,
            onEditStatus: onEditTopicStatus,
            onAddSubtopic: onAddSubtopic,
            onDelete: onDeleteTopic,
            onOpenSubtopic: onOpenSubtopic,
          );

    return Container(
      color: AppColors.pageBg,
      child: child,
    );
  }
}

class _TopicWorkspacePage extends StatelessWidget {
  final ModuleItem module;
  final MaterialItem material;
  final TopicItem topic;
  final bool topicDetailsLoaded;
  final bool topicDetailsFailed;
  final List<TopicItem> subtopics;
  final List<LearningOutcome> inheritedOutcomes;
  final List<LearningOutcome> allOutcomes;
  final int totalOutcomes;
  final String? downloadUrl;
  final bool urlLoading;
  final VoidCallback onRefreshUrl;
  final bool previewInteractive;
  final bool canPop;
  final VoidCallback onBack;
  final VoidCallback onRename;
  final VoidCallback onEditSummary;
  final VoidCallback onEditStatus;
  final VoidCallback onAddSubtopic;
  final VoidCallback onDelete;
  final ValueChanged<TopicItem> onOpenSubtopic;

  const _TopicWorkspacePage({
    required this.module,
    required this.material,
    required this.topic,
    required this.topicDetailsLoaded,
    required this.topicDetailsFailed,
    required this.subtopics,
    required this.inheritedOutcomes,
    required this.allOutcomes,
    required this.totalOutcomes,
    required this.downloadUrl,
    required this.urlLoading,
    required this.onRefreshUrl,
    required this.previewInteractive,
    required this.canPop,
    required this.onBack,
    required this.onRename,
    required this.onEditSummary,
    required this.onEditStatus,
    required this.onAddSubtopic,
    required this.onDelete,
    required this.onOpenSubtopic,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final readySubtopics = subtopics.where((s) => s.readiness == TopicReadiness.ready || s.isReviewed).length;
    final mappedSubtopics = subtopics.where((s) => _mappedOutcomeIdsForTopic(s).isNotEmpty).length;
    final readiness = _topicPageScore(topic: topic, subtopics: subtopics);
    final description = (topic.description?.trim().isNotEmpty ?? false)
        ? topic.description!.trim()
        : 'No summary yet. Add one concise paragraph that explains the scope of this topic before breaking it into subtopics.';
    final stageHeight = _topicDocumentStageHeight(context);
    final pageRange = _effectiveLearningItemPdfPageRange(
      topic: topic,
      material: material,
      childTopics: subtopics,
    );
    final pageRangeLoading = pageRange == null &&
        _topicPageRangeIsLoading(topic, topicDetailsLoaded, topicDetailsFailed);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 104),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopicHeroV2(
                topic: topic,
                module: module,
                material: material,
                readiness: readiness,
                subtopicCount: subtopics.length,
                outcomeCount: inheritedOutcomes.length,
                canPop: canPop,
                onBack: onBack,
                onRename: onRename,
                onAddSubtopic: onAddSubtopic,
                onDelete: onDelete,
              ),
              const SizedBox(height: 18),
              _DocumentStage(
                material: material,
                downloadUrl: downloadUrl,
                urlLoading: urlLoading,
                onRefreshUrl: onRefreshUrl,
                previewInteractive: previewInteractive,
                height: stageHeight,
                pageRange: pageRange,
                pageRangeLoading: pageRangeLoading,
                requirePageRange: true,
                scopeTitle: 'Document viewer',
                scopeSubtitle: _learningItemDocumentSubtitle(
                  label: 'Topic',
                  topic: topic,
                  pageRange: pageRange,
                  loadingRange: pageRangeLoading,
                ),
              ),
              const SizedBox(height: 18),
              _TopicContentPanelV2(
                description: description,
                isSummaryEmpty: !(topic.description?.trim().isNotEmpty ?? false),
                subtopics: subtopics,
                inheritedOutcomes: inheritedOutcomes,
                allOutcomes: allOutcomes,
                totalOutcomes: totalOutcomes,
                readySubtopics: readySubtopics,
                mappedSubtopics: mappedSubtopics,
                onEditSummary: onEditSummary,
                onOpenSubtopic: onOpenSubtopic,
                onAddSubtopic: onAddSubtopic,
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _SubtopicWorkspacePage extends StatelessWidget {
  final ModuleItem module;
  final MaterialItem material;
  final TopicItem topic;
  final TopicItem? parentTopic;
  final bool topicDetailsLoaded;
  final bool topicDetailsFailed;
  final List<LearningOutcome> mappedOutcomes;
  final int totalOutcomes;
  final String? downloadUrl;
  final bool urlLoading;
  final VoidCallback onRefreshUrl;
  final bool previewInteractive;
  final bool canPop;
  final VoidCallback onBack;
  final VoidCallback onRename;
  final VoidCallback onEditSummary;
  final VoidCallback onEditStatus;
  final VoidCallback onMapOutcomes;
  final VoidCallback onDelete;

  const _SubtopicWorkspacePage({
    required this.module,
    required this.material,
    required this.topic,
    required this.parentTopic,
    required this.topicDetailsLoaded,
    required this.topicDetailsFailed,
    required this.mappedOutcomes,
    required this.totalOutcomes,
    required this.downloadUrl,
    required this.urlLoading,
    required this.onRefreshUrl,
    required this.previewInteractive,
    required this.canPop,
    required this.onBack,
    required this.onRename,
    required this.onEditSummary,
    required this.onEditStatus,
    required this.onMapOutcomes,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final score = _subtopicScore(topic: topic, mappedOutcomeCount: mappedOutcomes.length);
    final description = (topic.description?.trim().isNotEmpty ?? false)
        ? topic.description!.trim()
        : 'No subtopic explanation yet. Add the exact concept, skill, or paragraph range that this subtopic should cover.';
    final stageHeight = _topicDocumentStageHeight(context);
    final pageRange = _effectiveLearningItemPdfPageRange(
      topic: topic,
      material: material,
      parentTopic: parentTopic,
    );
    final pageRangeLoading = pageRange == null &&
        _topicPageRangeIsLoading(topic, topicDetailsLoaded, topicDetailsFailed);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 104),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubtopicHeroV2(
                topic: topic,
                parentTopicTitle: parentTopic?.title ?? 'Parent topic',
                mappedOutcomeCount: mappedOutcomes.length,
                score: score,
                canPop: canPop,
                onBack: onBack,
                onRename: onRename,
                onMapOutcomes: onMapOutcomes,
                onDelete: onDelete,
              ),
              const SizedBox(height: 18),
              _DocumentStage(
                material: material,
                downloadUrl: downloadUrl,
                urlLoading: urlLoading,
                onRefreshUrl: onRefreshUrl,
                previewInteractive: previewInteractive,
                height: stageHeight,
                pageRange: pageRange,
                pageRangeLoading: pageRangeLoading,
                requirePageRange: true,
                scopeTitle: 'Document viewer',
                scopeSubtitle: _learningItemDocumentSubtitle(
                  label: 'Subtopic',
                  topic: topic,
                  pageRange: pageRange,
                  loadingRange: pageRangeLoading,
                ),
              ),
              const SizedBox(height: 18),
              _SubtopicContentPanelV2(
                description: description,
                isSummaryEmpty: !(topic.description?.trim().isNotEmpty ?? false),
                mappedOutcomes: mappedOutcomes,
                totalOutcomes: totalOutcomes,
                onEditSummary: onEditSummary,
                onMapOutcomes: onMapOutcomes,
              ),
            ],
          ),
        ),
      ),
    );
  }

}

double _topicDocumentStageHeight(BuildContext context) {
  final viewportHeight = MediaQuery.of(context).size.height;
  return (viewportHeight * 0.88).clamp(760.0, 1120.0).toDouble();
}

int _topicPageScore({required TopicItem topic, required List<TopicItem> subtopics}) {
  var score = 28;
  if (topic.description?.trim().isNotEmpty ?? false) score += 18;
  if (subtopics.isNotEmpty) score += 24;
  if (subtopics.any((s) => _mappedOutcomeIdsForTopic(s).isNotEmpty)) score += 18;
  if (subtopics.any((s) => s.readiness == TopicReadiness.ready || s.isReviewed)) score += 12;
  return score.clamp(0, 100).toInt();
}

int _subtopicScore({required TopicItem topic, required int mappedOutcomeCount}) {
  var score = 22;
  if (topic.description?.trim().isNotEmpty ?? false) score += 24;
  if (mappedOutcomeCount > 0) score += 34;
  if (topic.readiness == TopicReadiness.ready || topic.isReviewed) {
    score += 20;
  } else if (topic.readiness == TopicReadiness.review) {
    score += 10;
  }
  return score.clamp(0, 100).toInt();
}

class _LearningItemTopBar extends StatelessWidget {
  final bool canPop;
  final VoidCallback onBack;
  final String label;
  final String materialTitle;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _LearningItemTopBar({
    required this.canPop,
    required this.onBack,
    required this.label,
    required this.materialTitle,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (canPop) ...[
            _SmallSurfaceButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
            const SizedBox(width: 10),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surfaceBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.picture_as_pdf_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  materialTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textGray),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.primary)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textTitle),
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _TopicHeroV2 extends StatelessWidget {
  final TopicItem topic;
  final ModuleItem module;
  final MaterialItem material;
  final int readiness;
  final int subtopicCount;
  final int outcomeCount;
  final bool canPop;
  final VoidCallback onBack;
  final VoidCallback onRename;
  final VoidCallback onAddSubtopic;
  final VoidCallback onDelete;

  const _TopicHeroV2({
    required this.topic,
    required this.module,
    required this.material,
    required this.readiness,
    required this.subtopicCount,
    required this.outcomeCount,
    required this.canPop,
    required this.onBack,
    required this.onRename,
    required this.onAddSubtopic,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _GradientShellV2(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const _WhitePillV2(icon: Icons.auto_stories_outlined, label: 'Topic'),
                  _WhitePillV2(icon: Icons.folder_open_outlined, label: module.title),
                  _WhitePillV2(icon: Icons.picture_as_pdf_outlined, label: material.displayTitle),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                topic.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 26 : 32,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Topic content and subtopics for this uploaded material.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.80)),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _TopicHeaderActionButton(
                    icon: Icons.account_tree_outlined,
                    label: 'Add subtopic',
                    onTap: onAddSubtopic,
                    primary: true,
                  ),
                  _TopicHeaderActionButton(
                    icon: Icons.drive_file_rename_outline_rounded,
                    label: 'Rename topic',
                    onTap: onRename,
                  ),
                  _TopicHeaderActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete topic',
                    onTap: onDelete,
                    danger: true,
                  ),
                ],
              ),
            ],
          );
          final scoreCard = _HeroScoreCardV2(
            label: 'Readiness',
            score: readiness,
            firstLabel: 'Subtopics',
            firstValue: '$subtopicCount',
            secondLabel: 'Outcomes',
            secondValue: '$outcomeCount',
          );
          if (compact) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [titleBlock, const SizedBox(height: 18), scoreCard]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 24),
              SizedBox(width: 320, child: scoreCard),
            ],
          );
        },
      ),
    );
  }

}

class _SubtopicHeroV2 extends StatelessWidget {
  final TopicItem topic;
  final String parentTopicTitle;
  final int mappedOutcomeCount;
  final int score;
  final bool canPop;
  final VoidCallback onBack;
  final VoidCallback onRename;
  final VoidCallback onMapOutcomes;
  final VoidCallback onDelete;

  const _SubtopicHeroV2({
    required this.topic,
    required this.parentTopicTitle,
    required this.mappedOutcomeCount,
    required this.score,
    required this.canPop,
    required this.onBack,
    required this.onRename,
    required this.onMapOutcomes,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _GradientShellV2(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const _WhitePillV2(icon: Icons.subdirectory_arrow_right_rounded, label: 'Subtopic'),
                  _WhitePillV2(icon: Icons.auto_stories_outlined, label: parentTopicTitle),
                  _WhitePillV2(icon: topic.isAiGenerated ? Icons.auto_awesome_rounded : Icons.edit_note_rounded, label: topic.isAiGenerated ? 'AI sourced' : 'Manual'),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                topic.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 26 : 32,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Final learning unit with its own Sub LO mapping.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.80)),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _TopicHeaderActionButton(
                    icon: Icons.flag_outlined,
                    label: 'Map Sub LO',
                    onTap: onMapOutcomes,
                    primary: true,
                  ),
                  _TopicHeaderActionButton(
                    icon: Icons.drive_file_rename_outline_rounded,
                    label: 'Rename subtopic',
                    onTap: onRename,
                  ),
                  _TopicHeaderActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete subtopic',
                    onTap: onDelete,
                    danger: true,
                  ),
                ],
              ),
            ],
          );
          final scoreCard = _HeroScoreCardV2(
            label: 'Readiness',
            score: score,
            firstLabel: 'Mapped Sub LO',
            firstValue: mappedOutcomeCount == 0 ? '0' : '1',
            secondLabel: 'Level',
            secondValue: 'Final',
          );
          if (compact) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [titleBlock, const SizedBox(height: 18), scoreCard]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 24),
              SizedBox(width: 320, child: scoreCard),
            ],
          );
        },
      ),
    );
  }

}

class _GradientShellV2 extends StatelessWidget {
  final Widget child;
  const _GradientShellV2({required this.child});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 228),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF137FEC), Color(0xFF0B66D7), Color(0xFF19A7F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
      child: Stack(
        children: [
          Positioned(
            right: -90,
            top: -90,
            child: Container(width: 260, height: 260, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.10))),
          ),
          Positioned(
            right: 210,
            bottom: -120,
            child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06))),
          ),
          Padding(padding: const EdgeInsets.all(24), child: child),
        ],
      ),
    );
  }

}

class _HeroScoreCardV2 extends StatelessWidget {
  final String label;
  final int score;
  final String firstLabel;
  final String firstValue;
  final String secondLabel;
  final String secondValue;

  const _HeroScoreCardV2({required this.label, required this.score, required this.firstLabel, required this.firstValue, required this.secondLabel, required this.secondValue});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white))), Text('$score%', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white))]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: score / 100, minHeight: 8, backgroundColor: Colors.white.withOpacity(0.18), color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: _GlassMetricV2(label: firstLabel, value: firstValue)), const SizedBox(width: 10), Expanded(child: _GlassMetricV2(label: secondLabel, value: secondValue))]),
        ],
      ),
    );
  }
}

class _TopicScopeCardV2 extends StatelessWidget {
  final String description;
  final bool isEmpty;
  final VoidCallback onEditSummary;
  const _TopicScopeCardV2({required this.description, required this.isEmpty, required this.onEditSummary});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _StudioPanelV2(
      icon: Icons.subject_rounded,
      title: 'Topic scope',
      subtitle: 'One short definition of what this parent topic covers.',
      trailing: _InlineTextActionV2(icon: Icons.edit_outlined, label: 'Edit summary', onTap: onEditSummary),
      child: Text(
        description,
        style: TextStyle(fontSize: 15, height: 1.65, fontWeight: isEmpty ? FontWeight.w600 : FontWeight.w700, color: isEmpty ? AppColors.textMuted : AppColors.textGray),
      ),
    );
  }
}

class _TopicArchitectureCardV2 extends StatelessWidget {
  final ModuleItem module;
  final MaterialItem material;
  final TopicItem topic;
  final int subtopicCount;
  final int inheritedOutcomeCount;
  final int totalOutcomes;

  const _TopicArchitectureCardV2({required this.module, required this.material, required this.topic, required this.subtopicCount, required this.inheritedOutcomeCount, required this.totalOutcomes});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _StudioPanelV2(
      icon: Icons.hub_outlined,
      title: 'Content architecture',
      subtitle: 'The only valid depth is Module → Material → Topic → Subtopics.',
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 720;
              final nodes = [
                _FlowNodeV2(icon: Icons.folder_outlined, label: 'Module', value: module.title),
                _FlowNodeV2(icon: Icons.picture_as_pdf_outlined, label: 'Material', value: material.displayTitle),
                _FlowNodeV2(icon: Icons.auto_stories_outlined, label: 'Topic', value: topic.title, active: true),
                _FlowNodeV2(icon: Icons.subdirectory_arrow_right_rounded, label: 'Subtopics', value: '$subtopicCount items'),
              ];
              if (stack) return Column(children: [for (var i = 0; i < nodes.length; i++) ...[nodes[i], if (i != nodes.length - 1) const SizedBox(height: 10)]]);
              return Row(children: [for (var i = 0; i < nodes.length; i++) ...[Expanded(child: nodes[i]), if (i != nodes.length - 1) Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.textHint))]]);
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.badgeBlueBorder)),
            child: Row(
              children: [
                const _MiniIconV2(icon: Icons.flag_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(child: Text('Parent topics do not own outcome mapping. This topic inherits coverage from mapped subtopics.', style: TextStyle(fontSize: 13, height: 1.45, fontWeight: FontWeight.w800, color: AppColors.badgeBlueFg))),
                Text('$inheritedOutcomeCount/$totalOutcomes', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicSubtopicStudioV2 extends StatelessWidget {
  final List<TopicItem> subtopics;
  final ValueChanged<TopicItem> onOpenSubtopic;
  final VoidCallback onAddSubtopic;

  const _TopicSubtopicStudioV2({required this.subtopics, required this.onOpenSubtopic, required this.onAddSubtopic});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _StudioPanelV2(
      icon: Icons.account_tree_outlined,
      title: 'Subtopic studio',
      subtitle: 'Break the topic into final learning units. Outcome mapping lives there.',
      trailing: _InlineTextActionV2(icon: Icons.add_rounded, label: 'Add subtopic', onTap: onAddSubtopic),
      child: subtopics.isEmpty
          ? _EmptySubtopicCanvasV2(onAddSubtopic: onAddSubtopic)
          : Column(
              children: [
                for (var i = 0; i < subtopics.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == subtopics.length - 1 ? 0 : 10),
                    child: _SubtopicPreviewTileV2(
                      index: i + 1,
                      subtopic: subtopics[i],
                      onTap: () => onOpenSubtopic(subtopics[i]),
                    ),
                  ),
              ],
            ),
    );
  }
}


class _TopicContentPanelV2 extends StatelessWidget {
  final String description;
  final bool isSummaryEmpty;
  final List<TopicItem> subtopics;
  final List<LearningOutcome> inheritedOutcomes;
  final List<LearningOutcome> allOutcomes;
  final int totalOutcomes;
  final int readySubtopics;
  final int mappedSubtopics;
  final VoidCallback onEditSummary;
  final ValueChanged<TopicItem> onOpenSubtopic;
  final VoidCallback onAddSubtopic;

  const _TopicContentPanelV2({
    required this.description,
    required this.isSummaryEmpty,
    required this.subtopics,
    required this.inheritedOutcomes,
    required this.allOutcomes,
    required this.totalOutcomes,
    required this.readySubtopics,
    required this.mappedSubtopics,
    required this.onEditSummary,
    required this.onOpenSubtopic,
    required this.onAddSubtopic,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final subtopicTotal = subtopics.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StudioPanelV2(
          icon: Icons.subject_rounded,
          title: 'Topic content',
          subtitle: 'Summary and learning outcome coverage.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.65,
                  fontWeight: isSummaryEmpty ? FontWeight.w600 : FontWeight.w800,
                  color: isSummaryEmpty ? AppColors.textMuted : AppColors.textGray,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ContentMetricPillV2(label: 'Subtopics', value: '$subtopicTotal'),
                  _ContentMetricPillV2(label: 'Ready', value: '$readySubtopics/$subtopicTotal'),
                  _ContentMetricPillV2(label: 'Mapped', value: '$mappedSubtopics/$subtopicTotal'),
                  _ContentMetricPillV2(label: 'Outcomes', value: '${inheritedOutcomes.length}/$totalOutcomes'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _StudioPanelV2(
          icon: Icons.account_tree_outlined,
          title: 'Subtopics',
          subtitle: 'Final learning units inside this topic. The mapped Sub LO appears on each item.',
          child: subtopics.isEmpty
              ? _EmptySubtopicCanvasV2(onAddSubtopic: onAddSubtopic, showAction: false)
              : Column(
                  children: [
                    for (var i = 0; i < subtopics.length; i++)
                      Padding(
                        padding: EdgeInsets.only(bottom: i == subtopics.length - 1 ? 0 : 10),
                        child: _SubtopicPreviewTileV2(
                          index: i + 1,
                          subtopic: subtopics[i],
                          outcomes: allOutcomes,
                          onTap: () => onOpenSubtopic(subtopics[i]),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _SubtopicContentPanelV2 extends StatelessWidget {
  final String description;
  final bool isSummaryEmpty;
  final List<LearningOutcome> mappedOutcomes;
  final int totalOutcomes;
  final VoidCallback onEditSummary;
  final VoidCallback onMapOutcomes;

  const _SubtopicContentPanelV2({
    required this.description,
    required this.isSummaryEmpty,
    required this.mappedOutcomes,
    required this.totalOutcomes,
    required this.onEditSummary,
    required this.onMapOutcomes,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _StudioPanelV2(
      icon: Icons.notes_rounded,
      title: 'Subtopic content',
      subtitle: 'Brief and learning-outcome mapping for this final unit.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              height: 1.65,
              fontWeight: isSummaryEmpty ? FontWeight.w600 : FontWeight.w800,
              color: isSummaryEmpty ? AppColors.textMuted : AppColors.textGray,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ContentMetricPillV2(label: 'Mapped Sub LO', value: mappedOutcomes.isEmpty ? '0' : '1'),
              _ContentMetricPillV2(label: 'Coverage', value: '${mappedOutcomes.length}/$totalOutcomes'),
            ],
          ),
          const SizedBox(height: 18),
          Text('Mapped Sub LO', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
          const SizedBox(height: 10),
          if (mappedOutcomes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  _MiniIconV2(icon: Icons.flag_circle_outlined, color: AppColors.warningText, bg: AppColors.warningSoftBg),
                  const SizedBox(width: 12),
                  Expanded(child: Text('No Sub LO is mapped yet. Use the header action to map this subtopic.', style: TextStyle(fontSize: 13.5, height: 1.45, fontWeight: FontWeight.w800, color: AppColors.textMuted))),
                ],
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < mappedOutcomes.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == mappedOutcomes.length - 1 ? 0 : 10),
                    child: _OutcomeMappingTileV2(outcome: mappedOutcomes[i], index: i + 1),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ContentMetricPillV2 extends StatelessWidget {
  final String label;
  final String value;
  const _ContentMetricPillV2({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
        ],
      ),
    );
  }
}

class _HeaderBackPillV2 extends StatelessWidget {
  final bool canPop;
  final VoidCallback onBack;
  const _HeaderBackPillV2({required this.canPop, required this.onBack});

  @override
  Widget build(BuildContext context) {
    if (!canPop) return const SizedBox.shrink();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onBack,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.arrow_back_rounded, size: 15, color: AppColors.primary),
              SizedBox(width: 6),
              Text('Back', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutcomeMappingTileV2 extends StatelessWidget {
  final LearningOutcome outcome;
  final int index;
  const _OutcomeMappingTileV2({required this.outcome, required this.index});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
            child: Text('$index', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              outcome.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w800, color: AppColors.textTitle),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicOpsPanelV2 extends StatelessWidget {
  final int readiness;
  final int readySubtopics;
  final int mappedSubtopics;
  final int subtopicCount;
  final int inheritedOutcomeCount;
  final VoidCallback onRename;
  final VoidCallback onEditSummary;
  final VoidCallback onEditStatus;
  final VoidCallback onAddSubtopic;
  final VoidCallback onDelete;

  const _TopicOpsPanelV2({
    required this.readiness,
    required this.readySubtopics,
    required this.mappedSubtopics,
    required this.subtopicCount,
    required this.inheritedOutcomeCount,
    required this.onRename,
    required this.onEditSummary,
    required this.onEditStatus,
    required this.onAddSubtopic,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _StudioPanelV2(
      icon: Icons.bolt_outlined,
      title: 'Topic actions',
      subtitle: 'Focused controls for this topic.',
      compact: true,
      child: Column(
        children: [
          _ActionTileV2(icon: Icons.drive_file_rename_outline_rounded, title: 'Rename topic', subtitle: 'Change title only.', onTap: onRename, primary: true),
          _ActionTileV2(icon: Icons.subject_rounded, title: 'Edit summary', subtitle: 'Scope and instructor notes.', onTap: onEditSummary),
          _ActionTileV2(icon: Icons.speed_rounded, title: 'Delivery state', subtitle: 'Difficulty and readiness.', onTap: onEditStatus),
          _ActionTileV2(icon: Icons.account_tree_outlined, title: 'Add subtopic', subtitle: 'Create final learning units.', onTap: onAddSubtopic),
          _ActionTileV2(icon: Icons.delete_outline_rounded, title: 'Delete topic', subtitle: 'Remove this topic branch.', onTap: onDelete, danger: true),
        ],
      ),
    );
  }

}

class _SubtopicBriefCardV2 extends StatelessWidget {
  final String description;
  final bool isEmpty;
  final VoidCallback onEditSummary;
  const _SubtopicBriefCardV2({required this.description, required this.isEmpty, required this.onEditSummary});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _StudioPanelV2(
      icon: Icons.notes_rounded,
      title: 'Subtopic brief',
      subtitle: 'The final teaching unit students are assessed against.',
      trailing: _InlineTextActionV2(icon: Icons.edit_outlined, label: 'Edit summary', onTap: onEditSummary),
      child: Text(description, style: TextStyle(fontSize: 15, height: 1.65, fontWeight: isEmpty ? FontWeight.w600 : FontWeight.w700, color: isEmpty ? AppColors.textMuted : AppColors.textGray)),
    );
  }
}

class _SubtopicOutcomeCardV2 extends StatelessWidget {
  final List<LearningOutcome> mappedOutcomes;
  final int totalOutcomes;
  final VoidCallback onMapOutcomes;
  const _SubtopicOutcomeCardV2({required this.mappedOutcomes, required this.totalOutcomes, required this.onMapOutcomes});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _StudioPanelV2(
      icon: Icons.flag_outlined,
      title: 'Sub LO mapping',
      subtitle: 'This subtopic can be linked to one Sub LO only.',
      trailing: _InlineTextActionV2(icon: Icons.edit_road_outlined, label: 'Map Sub LO', onTap: onMapOutcomes),
      child: mappedOutcomes.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  _MiniIconV2(icon: Icons.flag_circle_outlined, color: AppColors.warningText, bg: AppColors.warningSoftBg),
                  const SizedBox(width: 12),
                  Expanded(child: Text('No Sub LO mapped yet. Link this subtopic to the exact Sub LO it teaches.', style: TextStyle(fontSize: 14, height: 1.45, fontWeight: FontWeight.w800, color: AppColors.textGray))),
                ],
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < mappedOutcomes.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == mappedOutcomes.length - 1 ? 0 : 10),
                    child: _OutcomeTileV2(outcome: mappedOutcomes[i]),
                  ),
                const SizedBox(height: 12),
                _SignalRowV2(label: 'Sub LO mapping', value: mappedOutcomes.isEmpty ? 'Not mapped' : mappedOutcomes.first.title),
              ],
            ),
    );
  }
}

class _SubtopicContextCardV2 extends StatelessWidget {
  final ModuleItem module;
  final MaterialItem material;
  final TopicItem? parentTopic;
  final TopicItem subtopic;
  const _SubtopicContextCardV2({required this.module, required this.material, required this.parentTopic, required this.subtopic});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _StudioPanelV2(
      icon: Icons.route_outlined,
      title: 'Placement',
      subtitle: 'A subtopic cannot contain another level.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stack = constraints.maxWidth < 760;
          final nodes = [
            _FlowNodeV2(icon: Icons.folder_outlined, label: 'Module', value: module.title),
            _FlowNodeV2(icon: Icons.picture_as_pdf_outlined, label: 'Material', value: material.displayTitle),
            _FlowNodeV2(icon: Icons.auto_stories_outlined, label: 'Topic', value: parentTopic?.title ?? 'Parent topic'),
            _FlowNodeV2(icon: Icons.subdirectory_arrow_right_rounded, label: 'Subtopic', value: subtopic.title, active: true),
          ];
          if (stack) return Column(children: [for (var i = 0; i < nodes.length; i++) ...[nodes[i], if (i != nodes.length - 1) const SizedBox(height: 10)]]);
          return Row(children: [for (var i = 0; i < nodes.length; i++) ...[Expanded(child: nodes[i]), if (i != nodes.length - 1) Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.textHint))]]);
        },
      ),
    );
  }
}

class _SubtopicOpsPanelV2 extends StatelessWidget {
  final int score;
  final int mappedOutcomeCount;
  final VoidCallback onRename;
  final VoidCallback onEditSummary;
  final VoidCallback onEditStatus;
  final VoidCallback onMapOutcomes;
  final VoidCallback onDelete;

  const _SubtopicOpsPanelV2({required this.score, required this.mappedOutcomeCount, required this.onRename, required this.onEditSummary, required this.onEditStatus, required this.onMapOutcomes, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _StudioPanelV2(
      icon: Icons.bolt_outlined,
      title: 'Subtopic actions',
      subtitle: 'Focused controls for this subtopic.',
      compact: true,
      child: Column(
        children: [
          _ActionTileV2(icon: Icons.drive_file_rename_outline_rounded, title: 'Rename subtopic', subtitle: 'Change title only.', onTap: onRename, primary: true),
          _ActionTileV2(icon: Icons.subject_rounded, title: 'Edit summary', subtitle: 'Teaching note and scope.', onTap: onEditSummary),
          _ActionTileV2(icon: Icons.speed_rounded, title: 'Delivery state', subtitle: 'Difficulty and readiness.', onTap: onEditStatus),
          _ActionTileV2(icon: Icons.flag_outlined, title: 'Map outcomes', subtitle: 'Connect this unit to outcomes.', onTap: onMapOutcomes),
          _ActionTileV2(icon: Icons.delete_outline_rounded, title: 'Delete subtopic', subtitle: 'Remove this final unit.', onTap: onDelete, danger: true),
        ],
      ),
    );
  }

}

class _StudioPanelV2 extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  final bool compact;

  const _StudioPanelV2({required this.icon, required this.title, required this.subtitle, required this.child, this.trailing, this.compact = false});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(compact ? 16 : 20, compact ? 16 : 18, compact ? 16 : 20, compact ? 12 : 16),
            child: Row(
              children: [
                _MiniIconV2(icon: icon, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: compact ? 16 : 18, fontWeight: FontWeight.w900, color: AppColors.textTitle, letterSpacing: -0.2)),
                      const SizedBox(height: 3),
                      Text(subtitle, style: TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.divider),
          Padding(padding: EdgeInsets.all(compact ? 14 : 18), child: child),
        ],
      ),
    );
  }
}

class _ActionTileV2 extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;
  final bool danger;

  const _ActionTileV2({required this.icon, required this.title, required this.subtitle, required this.onTap, this.primary = false, this.danger = false});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final bg = primary
        ? AppColors.primary
        : danger
            ? AppColors.dangerBg
            : AppColors.surfaceBg;
    final fg = primary
        ? Colors.white
        : danger
            ? AppColors.dangerText
            : AppColors.textTitle;
    final sub = primary ? Colors.white.withOpacity(0.78) : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: primary ? Colors.white.withOpacity(0.14) : AppColors.cardBg.withOpacity(0.75), borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, size: 18, color: fg),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: fg)),
                      const SizedBox(height: 3),
                      Text(subtitle, style: TextStyle(fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w600, color: sub)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, size: 17, color: primary ? Colors.white : (danger ? AppColors.dangerText : AppColors.textHint)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubtopicPreviewTileV2 extends StatelessWidget {
  final int index;
  final TopicItem subtopic;
  final List<LearningOutcome> outcomes;
  final VoidCallback onTap;
  const _SubtopicPreviewTileV2({required this.index, required this.subtopic, this.outcomes = const [], required this.onTap});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final mappedOutcomes = _mappedSubOutcomesForTopic(subtopic, outcomes);
    final mappedCount = mappedOutcomes.length;
    final hasSummary = subtopic.description?.trim().isNotEmpty ?? false;
    return Material(
      color: AppColors.surfaceBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(15)),
                alignment: Alignment.center,
                child: Text(index.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primary)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subtopic.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
                    const SizedBox(height: 4),
                    Text(hasSummary ? subtopic.description!.trim() : 'No summary yet', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _SubtopicLoPreviewBadge(
                count: mappedCount,
                outcomes: mappedOutcomes,
                allOutcomes: outcomes,
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}


List<int> _mappedOutcomeIdsForTopic(TopicItem topic) {
  final ids = <int>{...topic.learningOutcomeIds};
  for (final raw in topic.linkedOutcomeIds) {
    final parsed = int.tryParse(raw);
    if (parsed != null) ids.add(parsed);
  }
  final legacy = int.tryParse(topic.linkedOutcomeId ?? '');
  if (legacy != null) ids.add(legacy);
  final sortedIds = ids.toList()..sort();
  return sortedIds;
}

List<LearningOutcome> _mappedSubOutcomesForTopic(TopicItem topic, List<LearningOutcome> outcomes) {
  final mappedIds = _mappedOutcomeIdsForTopic(topic).toSet();
  final subOutcomes = outcomes
      .where((outcome) => outcome.isSubOutcome && mappedIds.contains(outcome.id))
      .toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  if (subOutcomes.length <= 1) return subOutcomes;
  return <LearningOutcome>[subOutcomes.first];
}

class _SubtopicLoPreviewBadge extends StatelessWidget {
  final int count;
  final List<LearningOutcome> outcomes;
  final List<LearningOutcome> allOutcomes;

  const _SubtopicLoPreviewBadge({
    required this.count,
    required this.outcomes,
    required this.allOutcomes,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.warningSoftBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.warningBorder),
        ),
        child: Text(
          'No Sub LO map',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppColors.warningText),
        ),
      );
    }

    LearningOutcome? mappedSubLo;
    for (final outcome in outcomes) {
      if (outcome.isSubOutcome) {
        mappedSubLo = outcome;
        break;
      }
    }
    mappedSubLo ??= outcomes.isNotEmpty ? outcomes.first : null;

    final rawTitle = mappedSubLo?.title.trim() ?? '';
    final rawCode = mappedSubLo?.code.trim() ?? '';
    final label = rawTitle.isNotEmpty
        ? rawTitle
        : rawCode.isNotEmpty
            ? rawCode
            : '$count mapped';

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.badgeBlueBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flag_outlined, size: 13, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicHeaderActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool danger;

  const _TopicHeaderActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.danger = false,
  });

  @override
  State<_TopicHeaderActionButton> createState() => _TopicHeaderActionButtonState();
}

class _TopicHeaderActionButtonState extends State<_TopicHeaderActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final Color background = widget.primary
        ? Colors.white
        : widget.danger
            ? (_hovered ? Colors.white.withOpacity(0.24) : Colors.white.withOpacity(0.16))
            : (_hovered ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.14));
    final Color foreground = widget.primary
        ? AppColors.primary
        : widget.danger
            ? const Color(0xFFFFD7D7)
            : Colors.white;

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

class _EmptySubtopicCanvasV2 extends StatelessWidget {
  final VoidCallback onAddSubtopic;
  final bool showAction;
  const _EmptySubtopicCanvasV2({required this.onAddSubtopic, this.showAction = true});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          const _MiniIconV2(icon: Icons.account_tree_outlined, color: AppColors.primary),
          const SizedBox(height: 12),
          Text('No subtopics yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
          const SizedBox(height: 6),
          Text('Create subtopics before mapping learning outcomes. This keeps the topic as a clean parent container.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, height: 1.45, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
          if (showAction) ...[
            const SizedBox(height: 16),
            _HeroActionV2.primary(icon: Icons.add_rounded, label: 'Create first subtopic', onTap: onAddSubtopic),
          ],
        ],
      ),
    );
  }
}

class _OutcomeTileV2 extends StatelessWidget {
  final LearningOutcome outcome;
  const _OutcomeTileV2({required this.outcome});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          const _MiniIconV2(icon: Icons.flag_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text('${outcome.code} • ${outcome.title}', style: TextStyle(fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w800, color: AppColors.textTitle))),
        ],
      ),
    );
  }
}

class _FlowNodeV2 extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool active;
  const _FlowNodeV2({required this.icon, required this.label, required this.value, this.active = false});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: active ? AppColors.primarySoft : AppColors.surfaceBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: active ? AppColors.badgeBlueBorder : AppColors.border)),
      child: Row(
        children: [
          _MiniIconV2(icon: icon, color: active ? AppColors.primary : AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhitePillV2 extends StatelessWidget {
  final IconData icon;
  final String label;
  const _WhitePillV2({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withOpacity(0.18))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _HeroActionV2 extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _HeroActionV2._({required this.icon, required this.label, required this.onTap, required this.filled});
  const _HeroActionV2.primary({required IconData icon, required String label, required VoidCallback onTap}) : this._(icon: icon, label: label, onTap: onTap, filled: true);
  const _HeroActionV2.secondary({required IconData icon, required String label, required VoidCallback onTap}) : this._(icon: icon, label: label, onTap: onTap, filled: false);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.white : Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: filled ? AppColors.primary : Colors.white),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: filled ? AppColors.primary : Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassMetricV2 extends StatelessWidget {
  final String label;
  final String value;
  const _GlassMetricV2({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.12))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.70))), const SizedBox(height: 5), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white))]),
    );
  }
}

class _MiniIconV2 extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? bg;
  const _MiniIconV2({required this.icon, required this.color, this.bg});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: bg ?? AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _SmallSurfaceButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallSurfaceButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Material(
      color: AppColors.surfaceBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 16, color: AppColors.textGray)),
      ),
    );
  }
}

class _InlineTextActionV2 extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _InlineTextActionV2({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return TextButton.icon(onPressed: onTap, icon: Icon(icon, size: 15), label: Text(label), style: TextButton.styleFrom(foregroundColor: AppColors.primary));
  }
}

class _SignalRowV2 extends StatelessWidget {
  final String label;
  final String value;
  const _SignalRowV2({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Row(children: [Expanded(child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textMuted))), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textTitle))]),
    );
  }
}

class _TinyBadgeV2 extends StatelessWidget {
  final String label;
  const _TinyBadgeV2({required this.label});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.primary)),
    );
  }
}

int _topicCoverageScore({
  required TopicItem topic,
  required List<LearningOutcome> mappedOutcomes,
  required List<TopicItem> subtopics,
  required bool isSubtopic,
}) {
  var score = 20;
  if (topic.description?.trim().isNotEmpty ?? false) score += 18;
  if (topic.instructorNotes?.trim().isNotEmpty ?? false) score += 18;
  if (mappedOutcomes.isNotEmpty) score += 22;
  if (topic.readiness == TopicReadiness.ready) {
    score += 18;
  } else if (topic.readiness == TopicReadiness.review) {
    score += 10;
  }
  if (!isSubtopic && subtopics.isNotEmpty) score += 4;
  return score.clamp(0, 100).toInt();
}
