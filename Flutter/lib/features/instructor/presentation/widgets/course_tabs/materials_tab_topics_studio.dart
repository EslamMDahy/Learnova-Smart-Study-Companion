part of 'materials_tab.dart';

class _TopicStudioTopBar extends StatelessWidget {
  final String materialTitle;
  final String topicTitle;
  final bool canPop;
  final VoidCallback onBack;
  final VoidCallback onEditTopic;

  const _TopicStudioTopBar({
    required this.materialTitle,
    required this.topicTitle,
    required this.canPop,
    required this.onBack,
    required this.onEditTopic,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(bottom: BorderSide(color: AppColors.borderGray)),
      ),
      child: Row(
        children: [
          if (canPop) ...[
            _TopicIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              tooltip: 'Back to PDF',
              onTap: onBack,
            ),
            const SizedBox(width: 10),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.headerBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.picture_as_pdf_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 190),
                  child: Text(
                    materialTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textHint),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              topicTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textTitle),
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: onEditTopic,
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Rename'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicStudioHero extends StatelessWidget {
  final ModuleItem module;
  final MaterialItem material;
  final TopicItem topic;
  final _TopicMeta readinessMeta;
  final _TopicMeta difficultyMeta;
  final bool isSubtopic;
  final String? parentTopicTitle;
  final int mappedOutcomesCount;
  final int subtopicCount;
  final int coverageScore;
  final VoidCallback onRenameTopic;
  final VoidCallback onEditTopicSummary;
  final VoidCallback onAddSubtopic;

  const _TopicStudioHero({
    required this.module,
    required this.material,
    required this.topic,
    required this.readinessMeta,
    required this.difficultyMeta,
    required this.isSubtopic,
    this.parentTopicTitle,
    required this.mappedOutcomesCount,
    required this.subtopicCount,
    required this.coverageScore,
    required this.onRenameTopic,
    required this.onEditTopicSummary,
    required this.onAddSubtopic,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final created = '${topic.createdAt.day}/${topic.createdAt.month}/${topic.createdAt.year}';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.isDark
              ? [const Color(0xFF08111F), const Color(0xFF0B2C73), AppColors.primary]
              : [AppColors.primary, AppColors.infoText, AppColors.purpleText],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          const BoxShadow(color: Color(0x24137FEC), blurRadius: 34, offset: Offset(0, 18)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.09),
              ),
            ),
          ),
          Positioned(
            right: 160,
            bottom: -90,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.purpleText.withOpacity(0.24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 900;
                final left = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: [
                        _TopicGlassChip(
                          icon: isSubtopic ? Icons.subdirectory_arrow_right_rounded : Icons.auto_stories_rounded,
                          label: isSubtopic ? 'Subtopic page' : 'Topic page',
                        ),
                        _TopicGlassChip(icon: readinessMeta.icon, label: readinessMeta.label),
                        _TopicGlassChip(icon: difficultyMeta.icon, label: difficultyMeta.label),
                        _TopicGlassChip(
                          icon: topic.source == TopicSource.ai ? Icons.auto_awesome_rounded : Icons.edit_note_rounded,
                          label: topic.source == TopicSource.ai ? 'AI-assisted' : 'Manual',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      topic.title,
                      style: const TextStyle(
                        fontSize: 30,
                        height: 1.13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 14,
                      runSpacing: 9,
                      children: [
                        _TopicHeroPathItem(icon: Icons.folder_open_outlined, label: module.title),
                        _TopicHeroPathItem(icon: Icons.picture_as_pdf_outlined, label: material.displayTitle),
                        if (isSubtopic && parentTopicTitle != null)
                          _TopicHeroPathItem(icon: Icons.account_tree_outlined, label: parentTopicTitle!),
                        _TopicHeroPathItem(icon: Icons.calendar_today_outlined, label: 'Created $created'),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _TopicHeroButton.primary(
                          icon: Icons.edit_rounded,
                          label: isSubtopic ? 'Rename subtopic' : 'Rename topic',
                          onTap: onRenameTopic,
                        ),
                        _TopicHeroButton.secondary(
                          icon: Icons.notes_rounded,
                          label: 'Edit summary',
                          onTap: onEditTopicSummary,
                        ),
                        if (!isSubtopic)
                          _TopicHeroButton.secondary(
                            icon: Icons.account_tree_outlined,
                            label: 'Add subtopic',
                            onTap: onAddSubtopic,
                          ),
                      ],
                    ),
                  ],
                );

                final metrics = _TopicHeroMetrics(
                  coverageScore: coverageScore,
                  mappedOutcomesCount: mappedOutcomesCount,
                  subtopicCount: subtopicCount,
                  isSubtopic: isSubtopic,
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      left,
                      const SizedBox(height: 18),
                      metrics,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: left),
                    const SizedBox(width: 26),
                    SizedBox(width: 350, child: metrics),
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

class _TopicHeroMetrics extends StatelessWidget {
  final int coverageScore;
  final int mappedOutcomesCount;
  final int subtopicCount;
  final bool isSubtopic;

  const _TopicHeroMetrics({
    required this.coverageScore,
    required this.mappedOutcomesCount,
    required this.subtopicCount,
    required this.isSubtopic,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBg.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Readiness score',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
              Text(
                '$coverageScore%',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TopicProgressTrack(value: coverageScore / 100, bright: true),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _TopicGlassMetric(label: 'Outcomes', value: mappedOutcomesCount == 0 ? '0' : '$mappedOutcomesCount')),
              const SizedBox(width: 10),
              Expanded(child: _TopicGlassMetric(label: isSubtopic ? 'Level' : 'Subtopics', value: isSubtopic ? 'Leaf' : '$subtopicCount')),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopicBriefBoard extends StatelessWidget {
  final TopicItem topic;
  final _TopicMeta readinessMeta;
  final _TopicMeta difficultyMeta;
  final int mappedOutcomesCount;
  final int subtopicCount;
  final bool isSubtopic;
  final String? parentTopicTitle;

  const _TopicBriefBoard({
    required this.topic,
    required this.readinessMeta,
    required this.difficultyMeta,
    required this.mappedOutcomesCount,
    required this.subtopicCount,
    required this.isSubtopic,
    this.parentTopicTitle,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final summary = (topic.description?.trim().isNotEmpty ?? false)
        ? topic.description!.trim()
        : 'No topic brief yet. Add a concise teaching scope so the instructor, instructors and reviewers know what this topic should cover.';
    return _TopicStudioCard(
      title: 'Teaching blueprint',
      subtitle: 'A clean snapshot of how this topic should be delivered and assessed.',
      icon: Icons.dashboard_customize_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary,
            style: TextStyle(
              fontSize: 14,
              height: 1.65,
              color: (topic.description?.trim().isNotEmpty ?? false) ? AppColors.textGray : AppColors.textMuted,
              fontWeight: (topic.description?.trim().isNotEmpty ?? false) ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 720;
              final tiles = [
                _TopicSummaryTile(
                  label: 'Delivery state',
                  value: readinessMeta.label,
                  helper: topic.readiness == TopicReadiness.ready
                      ? 'Ready for live delivery'
                      : topic.readiness == TopicReadiness.review
                          ? 'Needs final review pass'
                          : 'Still in preparation',
                  icon: readinessMeta.icon,
                  accent: readinessMeta.fg,
                  soft: readinessMeta.bg,
                ),
                _TopicSummaryTile(
                  label: 'Difficulty',
                  value: difficultyMeta.label,
                  helper: topic.difficulty == TopicDifficulty.beginner
                      ? 'Suitable for first exposure'
                      : topic.difficulty == TopicDifficulty.intermediate
                          ? 'Requires guided practice'
                          : 'Needs deeper scaffolding',
                  icon: difficultyMeta.icon,
                  accent: difficultyMeta.fg,
                  soft: difficultyMeta.bg,
                ),
                _TopicSummaryTile(
                  label: isSubtopic ? 'Parent topic' : 'Structure',
                  value: isSubtopic ? (parentTopicTitle ?? 'Parent topic') : '$subtopicCount subtopic${subtopicCount == 1 ? '' : 's'}',
                  helper: isSubtopic ? 'Nested teaching unit' : 'Breakdown inside this PDF',
                  icon: isSubtopic ? Icons.account_tree_outlined : Icons.schema_outlined,
                  accent: AppColors.primary,
                  soft: AppColors.primarySoft,
                ),
                _TopicSummaryTile(
                  label: 'Outcome map',
                  value: mappedOutcomesCount == 0 ? 'Unmapped' : '$mappedOutcomesCount linked',
                  helper: mappedOutcomesCount == 0 ? 'Needs alignment' : 'Connected to course goals',
                  icon: Icons.flag_outlined,
                  accent: _K.blue,
                  soft: _K.blueSoft,
                ),
              ];

              if (!wide) {
                return Column(
                  children: tiles
                      .map((tile) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: tile,
                          ),)
                      .toList(),
                );
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: tiles
                    .map(
                      (tile) => SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: tile,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TopicStructureBoard extends StatelessWidget {
  final ModuleItem module;
  final MaterialItem material;
  final TopicItem topic;
  final List<TopicItem> subtopics;
  final bool isSubtopic;
  final String? parentTopicTitle;

  const _TopicStructureBoard({
    required this.module,
    required this.material,
    required this.topic,
    required this.subtopics,
    required this.isSubtopic,
    this.parentTopicTitle,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _TopicStudioCard(
      title: isSubtopic ? 'Subtopic position' : 'Topic structure',
      subtitle: isSubtopic
          ? 'This item is the final level under a topic.'
          : 'This topic belongs to one material and can contain only subtopics.',
      icon: Icons.account_tree_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopicPathStrip(
            items: [
              _TopicPathNode(icon: Icons.folder_rounded, label: 'Module', value: module.title),
              _TopicPathNode(icon: Icons.picture_as_pdf_rounded, label: 'Material', value: material.displayTitle),
              if (isSubtopic)
                _TopicPathNode(icon: Icons.auto_stories_rounded, label: 'Parent topic', value: parentTopicTitle ?? 'Parent topic'),
              _TopicPathNode(
                icon: isSubtopic ? Icons.subdirectory_arrow_right_rounded : Icons.auto_stories_rounded,
                label: isSubtopic ? 'Subtopic' : 'Topic',
                value: topic.title,
              ),
            ],
          ),
          if (!isSubtopic) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _TopicSoftIcon(icon: Icons.schema_outlined, color: AppColors.primary, bg: AppColors.primarySoft),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subtopics.isEmpty ? 'Ready for subtopics' : '${subtopics.length} subtopic${subtopics.length == 1 ? '' : 's'} attached',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.textTitle),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtopics.isEmpty
                              ? 'Add subtopics when this topic needs smaller final learning points.'
                              : 'Learning-outcome coverage should be controlled from the subtopic level.',
                          style: TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopicFocusBoard extends StatelessWidget {
  final TopicItem topic;
  final _TopicMeta readinessMeta;
  final _TopicMeta difficultyMeta;
  final List<LearningOutcome> mappedOutcomes;
  final List<TopicItem> subtopics;
  final bool isSubtopic;
  final VoidCallback onEditSummary;
  final VoidCallback onMapOutcomes;

  const _TopicFocusBoard({
    required this.topic,
    required this.readinessMeta,
    required this.difficultyMeta,
    required this.mappedOutcomes,
    required this.subtopics,
    required this.isSubtopic,
    required this.onEditSummary,
    required this.onMapOutcomes,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final summary = topic.description?.trim();
    final notes = topic.instructorNotes?.trim();
    final hasSummary = summary != null && summary.isNotEmpty;
    final hasNotes = notes != null && notes.isNotEmpty;
    final hasChildren = subtopics.isNotEmpty;

    return _TopicStudioCard(
      title: isSubtopic ? 'Learning point' : 'Topic brief',
      subtitle: isSubtopic
          ? 'Subtopic details are handled separately from the parent topic page.'
          : 'One compact place for scope, state, and outcome-routing logic.',
      icon: Icons.view_quilt_outlined,
      action: TextButton.icon(
        onPressed: onEditSummary,
        icon: const Icon(Icons.edit_rounded, size: 16),
        label: const Text('Edit summary'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final tiles = [
                _TopicSummaryTile(
                  label: 'Delivery state',
                  value: readinessMeta.label,
                  helper: topic.readiness == TopicReadiness.ready
                      ? 'Ready for delivery'
                      : topic.readiness == TopicReadiness.review
                          ? 'Needs review'
                          : 'Still drafting',
                  icon: readinessMeta.icon,
                  accent: readinessMeta.fg,
                  soft: readinessMeta.bg,
                ),
                _TopicSummaryTile(
                  label: 'Difficulty',
                  value: difficultyMeta.label,
                  helper: topic.difficulty == TopicDifficulty.beginner
                      ? 'First exposure'
                      : topic.difficulty == TopicDifficulty.intermediate
                          ? 'Guided practice'
                          : 'Advanced depth',
                  icon: difficultyMeta.icon,
                  accent: difficultyMeta.fg,
                  soft: difficultyMeta.bg,
                ),
                _TopicSummaryTile(
                  label: isSubtopic ? 'Mapped outcomes' : 'Outcome rule',
                  value: isSubtopic
                      ? '${mappedOutcomes.length}'
                      : (hasChildren ? 'From subtopics' : '${mappedOutcomes.length} direct'),
                  helper: isSubtopic
                      ? 'Final-level mapping'
                      : (hasChildren ? 'Parent topic does not need direct LO links' : 'Can be mapped directly until subtopics exist'),
                  icon: Icons.flag_outlined,
                  accent: AppColors.primary,
                  soft: AppColors.primarySoft,
                ),
                _TopicSummaryTile(
                  label: isSubtopic ? 'Level' : 'Subtopics',
                  value: isSubtopic ? 'Leaf' : '${subtopics.length}',
                  helper: isSubtopic ? 'No children below this level' : 'Only one nested level is allowed',
                  icon: Icons.schema_outlined,
                  accent: AppColors.successText,
                  soft: AppColors.successBg,
                ),
              ];
              if (!wide) {
                return Column(
                  children: [
                    for (final tile in tiles) ...[
                      tile,
                      if (tile != tiles.last) const SizedBox(height: 10),
                    ],
                  ],
                );
              }
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final tile in tiles)
                    SizedBox(width: (constraints.maxWidth - 12) / 2, child: tile),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scope', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Text(
                  hasSummary ? summary : 'No summary yet. Add a short scope so this topic is easy to teach and review.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: hasSummary ? AppColors.textGray : AppColors.textMuted,
                    fontWeight: hasSummary ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Text('Instructor notes', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Text(
                  hasNotes ? notes : 'No notes yet.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    color: hasNotes ? AppColors.textGray : AppColors.textMuted,
                    fontWeight: hasNotes ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!isSubtopic) ...[
            const SizedBox(height: 14),
            Material(
              color: hasChildren ? AppColors.warningSoftBg : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: onMapOutcomes,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: hasChildren ? AppColors.warningBorder : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(hasChildren ? Icons.info_outline_rounded : Icons.flag_outlined, size: 18, color: hasChildren ? AppColors.warningText : AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          hasChildren
                              ? 'This topic has subtopics. Map learning outcomes on the subtopics instead of the parent.'
                              : 'No subtopics yet. This topic can be mapped directly to learning outcomes.',
                          style: TextStyle(fontSize: 12.5, height: 1.45, color: hasChildren ? AppColors.warningText : AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopicPathNode {
  final IconData icon;
  final String label;
  final String value;
  const _TopicPathNode({required this.icon, required this.label, required this.value});
}

class _TopicPathStrip extends StatelessWidget {
  final List<_TopicPathNode> items;
  const _TopicPathStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        if (compact) {
          return Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _TopicPathCard(node: items[i], active: i == items.length - 1),
                if (i != items.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              Expanded(child: _TopicPathCard(node: items[i], active: i == items.length - 1)),
              if (i != items.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textHint),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _TopicPathCard extends StatelessWidget {
  final _TopicPathNode node;
  final bool active;
  const _TopicPathCard({required this.node, required this.active});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? AppColors.primarySoft : AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: active ? AppColors.primary.withOpacity(0.25) : AppColors.border),
      ),
      child: Row(
        children: [
          _TopicSoftIcon(icon: node.icon, color: active ? AppColors.primary : AppColors.textMuted, bg: active ? AppColors.cardBg : AppColors.headerBg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(node.label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(node.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicLevelDiagram extends StatelessWidget {
  final bool isSubtopic;
  const _TopicLevelDiagram({required this.isSubtopic});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final levels = [
      ('Module', Icons.folder_rounded, false),
      ('Material', Icons.picture_as_pdf_rounded, false),
      ('Topic', Icons.auto_stories_rounded, !isSubtopic),
      ('Subtopic', Icons.subdirectory_arrow_right_rounded, isSubtopic),
    ];
    return Column(
      children: [
        for (var i = 0; i < levels.length; i++) ...[
          _TopicLevelRow(label: levels[i].$1, icon: levels[i].$2, active: levels[i].$3),
          if (i != levels.length - 1)
            Container(width: 2, height: 16, color: AppColors.border),
        ],
      ],
    );
  }
}

class _TopicLevelRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  const _TopicLevelRow({required this.label, required this.icon, required this.active});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active ? AppColors.primarySoft : AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? AppColors.primary.withOpacity(0.25) : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: active ? AppColors.primary : AppColors.textMuted),
          const SizedBox(width: 9),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: active ? AppColors.primary : AppColors.textMuted)),
          ),
          if (active)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
              child: const Text('current', style: TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w900)),
            ),
        ],
      ),
    );
  }
}

class _TopicOutcomeBoard extends StatelessWidget {
  final List<LearningOutcome> outcomes;
  final VoidCallback onEditTopic;

  const _TopicOutcomeBoard({required this.outcomes, required this.onEditTopic});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _TopicStudioCard(
      title: 'Outcome alignment',
      subtitle: outcomes.isEmpty
          ? 'This topic is not linked to learning outcomes yet.'
          : 'These outcomes are used as the assessment target for this topic.',
      icon: Icons.flag_outlined,
      action: TextButton.icon(
        onPressed: onEditTopic,
        icon: const Icon(Icons.add_link_rounded, size: 16),
        label: Text(outcomes.isEmpty ? 'Map outcomes' : 'Update map'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
      child: outcomes.isEmpty
          ? const _TopicEmptyPanel(
              icon: Icons.flag_outlined,
              title: 'No mapped outcomes',
              message: 'Open the edit popup and connect this topic to the outcomes it supports before generating graded questions.',
            )
          : Column(
              children: [
                for (var i = 0; i < outcomes.length; i++) ...[
                  _OutcomeTilePro(outcome: outcomes[i], index: i),
                  if (i != outcomes.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _TopicNotesBoard extends StatelessWidget {
  final TopicItem topic;
  final VoidCallback onEditTopic;

  const _TopicNotesBoard({required this.topic, required this.onEditTopic});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final notes = topic.instructorNotes?.trim();
    final hasNotes = notes != null && notes.isNotEmpty;
    return _TopicStudioCard(
      title: 'Instructor guidance',
      subtitle: 'Keep delivery cues, examples, warnings, and pacing notes close to the topic.',
      icon: Icons.sticky_note_2_outlined,
      action: TextButton.icon(
        onPressed: onEditTopic,
        icon: Icon(hasNotes ? Icons.edit_rounded : Icons.add_rounded, size: 16),
        label: Text(hasNotes ? 'Edit notes' : 'Add notes'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasNotes ? AppColors.surfaceBg : AppColors.warningSoftBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: hasNotes ? AppColors.border : AppColors.warningBorder),
        ),
        child: Text(
          hasNotes
              ? notes
              : 'No instructor notes yet. Add examples, common mistakes, pacing hints, or how this topic should be explained in class.',
          style: TextStyle(
            fontSize: 13.5,
            height: 1.65,
            color: hasNotes ? AppColors.textGray : AppColors.warningText,
            fontWeight: hasNotes ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _TopicSubtopicBoard extends StatelessWidget {
  final TopicItem topic;
  final List<TopicItem> subtopics;
  final VoidCallback onAddSubtopic;
  final ValueChanged<TopicItem> onOpenSubtopic;

  const _TopicSubtopicBoard({
    required this.topic,
    required this.subtopics,
    required this.onAddSubtopic,
    required this.onOpenSubtopic,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _TopicStudioCard(
      title: 'Subtopic map',
      subtitle: 'Break a broad topic into smaller teachable anchors.',
      icon: Icons.account_tree_outlined,
      action: FilledButton.icon(
        onPressed: onAddSubtopic,
        icon: const Icon(Icons.add_rounded, size: 16),
        label: const Text('Add subtopic'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
      child: subtopics.isEmpty
          ? _TopicEmptyPanel(
              icon: Icons.account_tree_outlined,
              title: 'No subtopics yet',
              message: 'Create smaller teaching units under "${topic.title}" when the section becomes too broad for one assessment anchor.',
            )
          : Column(
              children: [
                for (var i = 0; i < subtopics.length; i++) ...[
                  _SubtopicTilePro(
                    subtopic: subtopics[i],
                    index: i,
                    onTap: () => onOpenSubtopic(subtopics[i]),
                  ),
                  if (i != subtopics.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _TopicParentBoard extends StatelessWidget {
  final String? parentTopicTitle;

  const _TopicParentBoard({this.parentTopicTitle});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _TopicStudioCard(
      title: 'Hierarchy',
      subtitle: 'This item is a final-level subtopic.',
      icon: Icons.account_tree_outlined,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _TopicSoftIcon(icon: Icons.subdirectory_arrow_right_rounded, color: AppColors.primary, bg: AppColors.primarySoft),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Parent topic', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    parentTopicTitle ?? 'Parent topic',
                    style: TextStyle(fontSize: 15, color: AppColors.textTitle, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicCommandRail extends StatelessWidget {
  final TopicItem topic;
  final bool isSubtopic;
  final int coverageScore;
  final int mappedOutcomesCount;
  final int totalOutcomesCount;
  final int subtopicCount;
  final VoidCallback onRenameTopic;
  final VoidCallback onEditTopicSummary;
  final VoidCallback onEditTopicStatus;
  final VoidCallback onMapTopicOutcomes;
  final VoidCallback onDeleteTopic;
  final VoidCallback onAddSubtopic;

  const _TopicCommandRail({
    required this.topic,
    required this.isSubtopic,
    required this.coverageScore,
    required this.mappedOutcomesCount,
    required this.totalOutcomesCount,
    required this.subtopicCount,
    required this.onRenameTopic,
    required this.onEditTopicSummary,
    required this.onEditTopicStatus,
    required this.onMapTopicOutcomes,
    required this.onDeleteTopic,
    required this.onAddSubtopic,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final outcomeTotal = totalOutcomesCount == 0 ? mappedOutcomesCount : totalOutcomesCount;
    final outcomeProgress = outcomeTotal == 0
        ? 0.0
        : (mappedOutcomesCount / outcomeTotal).clamp(0.0, 1.0).toDouble();

    return Column(
      children: [
        _TopicStudioCard(
          title: isSubtopic ? 'Subtopic actions' : 'Topic actions',
          subtitle: isSubtopic
              ? 'This is a final-level learning point. It does not contain children.'
              : 'Each action opens a focused popup for one job only.',
          icon: Icons.tune_rounded,
          child: Column(
            children: [
              _TopicCommandButton(
                icon: Icons.drive_file_rename_outline_rounded,
                title: isSubtopic ? 'Rename subtopic' : 'Rename topic',
                subtitle: 'Change the title only.',
                primary: true,
                onTap: onRenameTopic,
              ),
              const SizedBox(height: 10),
              _TopicCommandButton(
                icon: Icons.notes_rounded,
                title: 'Edit summary',
                subtitle: 'Update scope and instructor notes.',
                onTap: onEditTopicSummary,
              ),
              const SizedBox(height: 10),
              _TopicCommandButton(
                icon: Icons.speed_rounded,
                title: 'Set delivery state',
                subtitle: 'Difficulty and readiness only.',
                onTap: onEditTopicStatus,
              ),
              const SizedBox(height: 10),
              _TopicCommandButton(
                icon: Icons.flag_outlined,
                title: 'Outcome mapping',
                subtitle: subtopicCount > 0 && !isSubtopic
                    ? 'Handled through subtopics.'
                    : 'Connect this item to course outcomes.',
                onTap: onMapTopicOutcomes,
              ),
              if (!isSubtopic) ...[
                const SizedBox(height: 10),
                _TopicCommandButton(
                  icon: Icons.account_tree_outlined,
                  title: 'Add subtopic',
                  subtitle: 'Create a final-level child item.',
                  onTap: onAddSubtopic,
                ),
              ],
              const SizedBox(height: 10),
              _TopicCommandButton(
                icon: Icons.delete_outline_rounded,
                title: isSubtopic ? 'Delete subtopic' : 'Delete topic',
                subtitle: 'Remove it from this material.',
                danger: true,
                onTap: onDeleteTopic,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _TopicStudioCard(
          title: 'Readiness signal',
          subtitle: 'A compact check for structure, notes, and outcome coverage.',
          icon: Icons.monitor_heart_outlined,
          child: Column(
            children: [
              _TopicHealthRow(label: 'Preparation', value: coverageScore / 100, trailing: '$coverageScore%'),
              const SizedBox(height: 14),
              _TopicHealthRow(
                label: 'Outcome alignment',
                value: outcomeProgress,
                trailing: '$mappedOutcomesCount/$outcomeTotal',
              ),
              const SizedBox(height: 14),
              _TopicHealthRow(
                label: isSubtopic ? 'Hierarchy' : 'Subtopics',
                value: isSubtopic ? 1.0 : (subtopicCount > 0 ? 1.0 : 0.0),
                trailing: isSubtopic ? 'Leaf' : '$subtopicCount',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _TopicStudioCard(
          title: 'Content level',
          subtitle: isSubtopic
              ? 'Subtopics are the last level in the structure.'
              : 'Topics sit between the material file and subtopics.',
          icon: Icons.schema_outlined,
          child: _TopicLevelDiagram(isSubtopic: isSubtopic),
        ),
      ],
    );
  }
}

class _TopicStudioCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? action;

  const _TopicStudioCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [BoxShadow(color: AppColors.shadowThin, blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopicSoftIcon(icon: icon, color: AppColors.primary, bg: AppColors.primarySoft),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 12),
                action!,
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _TopicSummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color accent;
  final Color soft;

  const _TopicSummaryTile({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.accent,
    required this.soft,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _TopicSoftIcon(icon: icon, color: accent, bg: soft),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                const SizedBox(height: 5),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
                const SizedBox(height: 3),
                Text(helper, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, height: 1.35, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicCommandButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool primary;
  final bool danger;
  final VoidCallback onTap;

  const _TopicCommandButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final bg = primary ? AppColors.primary : AppColors.surfaceBg;
    final accent = danger ? AppColors.dangerText : AppColors.primary;
    final fg = primary ? Colors.white : (danger ? AppColors.dangerText : AppColors.textTitle);
    final sub = primary ? Colors.white.withOpacity(0.72) : AppColors.textMuted;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primary ? AppColors.primary : (danger ? AppColors.dangerBorder : AppColors.border)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary ? Colors.white.withOpacity(0.14) : (danger ? AppColors.dangerBg : AppColors.primarySoft),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: primary ? Colors.white : accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: fg)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, height: 1.35, color: sub, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 18, color: primary ? Colors.white : AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutcomeTilePro extends StatelessWidget {
  final LearningOutcome outcome;
  final int index;

  const _OutcomeTilePro({required this.outcome, required this.index});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final code = outcome.code.trim().isEmpty ? 'LO${index + 1}' : outcome.code;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _K.blueSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(code, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(outcome.title, style: TextStyle(fontSize: 14, height: 1.35, fontWeight: FontWeight.w800, color: AppColors.textTitle)),
                if (outcome.description?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 5),
                  Text(outcome.description!.trim(), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtopicTilePro extends StatelessWidget {
  final TopicItem subtopic;
  final int index;
  final VoidCallback onTap;

  const _SubtopicTilePro({required this.subtopic, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final readiness = _topicReadinessMeta(subtopic.readiness);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text('${index + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subtopic.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textTitle)),
                    const SizedBox(height: 5),
                    Text('${subtopic.difficulty.label} • ${readiness.label}', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

