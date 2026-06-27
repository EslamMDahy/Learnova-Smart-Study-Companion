part of 'materials_tab.dart';

class _TopicHealthRow extends StatelessWidget {
  final String label;
  final double value;
  final String trailing;

  const _TopicHealthRow({required this.label, required this.value, required this.trailing});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textGray))),
            Text(trailing, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
          ],
        ),
        const SizedBox(height: 8),
        _TopicProgressTrack(value: value),
      ],
    );
  }
}

class _TopicTimelineStep extends StatelessWidget {
  final int index;
  final String title;
  final bool done;
  final bool last;

  const _TopicTimelineStep({required this.index, required this.title, required this.done, this.last = false});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: done ? _K.green : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: done
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : Text('$index', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary)),
            ),
            if (!last)
              Container(
                width: 2,
                height: 26,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: done ? AppColors.textTitle : AppColors.textMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopicEmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _TopicEmptyPanel({required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopicSoftIcon(icon: icon, color: AppColors.primary, bg: AppColors.primarySoft),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
                const SizedBox(height: 5),
                Text(message, style: TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicProgressTrack extends StatelessWidget {
  final double value;
  final bool bright;

  const _TopicProgressTrack({required this.value, this.bright = false});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final v = value.clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 8,
        color: bright ? Colors.white.withOpacity(0.16) : AppColors.border,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: v,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bright
                    ? [Colors.white, AppColors.infoBorder]
                    : [AppColors.primary, AppColors.purpleText],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicGlassChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TopicGlassChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBg.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }
}

class _TopicHeroPathItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TopicHeroPathItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withOpacity(0.78)),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.80)),
          ),
        ),
      ],
    );
  }
}

class _TopicHeroButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _TopicHeroButton.primary({required this.icon, required this.label, required this.onTap}) : primary = true;
  const _TopicHeroButton.secondary({required this.icon, required this.label, required this.onTap}) : primary = false;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Material(
      color: primary ? Colors.white : Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primary ? Colors.white : Colors.white.withOpacity(0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: primary ? AppColors.textTitle : Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: primary ? AppColors.textTitle : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicGlassMetric extends StatelessWidget {
  final String label;
  final String value;

  const _TopicGlassMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBg.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.72))),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
  }
}

class _TopicIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _TopicIconButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 15, color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}

class _TopicSoftIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;

  const _TopicSoftIcon({required this.icon, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _TopicSubtopicsCard extends StatelessWidget {
  final TopicItem topic;
  final List<TopicItem> subtopics;
  final VoidCallback onAddSubtopic;
  final ValueChanged<TopicItem> onOpenSubtopic;

  const _TopicSubtopicsCard({
    required this.topic,
    required this.subtopics,
    required this.onAddSubtopic,
    required this.onOpenSubtopic,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _CardWidget(
      header: _HdrWidget(
        icon: Icons.account_tree_outlined,
        iconColor: AppColors.primary,
        title: 'Subtopics',
        trailing: ElevatedButton.icon(
          onPressed: onAddSubtopic,
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Add Subtopic'),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: subtopics.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No subtopics yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textTitle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Break "${topic.title}" into smaller teaching units so notes and outcome coverage stay organized.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: onAddSubtopic,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Create first subtopic'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  for (final subtopic in subtopics) ...[
                    InkWell(
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onOpenSubtopic(subtopic),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderGray),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.infoBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.subdirectory_arrow_right_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subtopic.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textTitle,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${subtopic.difficulty.label} • ${subtopic.readiness.label}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
      ),
    );
  }
}

class _TopicHeroCard extends StatelessWidget {
  final ModuleItem module;
  final MaterialItem material;
  final TopicItem topic;
  final int mappedOutcomesCount;
  final bool isSubtopic;
  final String? parentTopicTitle;
  final _TopicMeta readinessMeta;
  final _TopicMeta difficultyMeta;
  final VoidCallback onManage;

  const _TopicHeroCard({
    required this.module,
    required this.material,
    required this.topic,
    required this.mappedOutcomesCount,
    required this.isSubtopic,
    this.parentTopicTitle,
    required this.readinessMeta,
    required this.difficultyMeta,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final created = '${topic.createdAt.day}/${topic.createdAt.month}/${topic.createdAt.year}';
    final statusChips = [
      _TopicStatusChip(
        icon: isSubtopic ? Icons.subdirectory_arrow_right_rounded : Icons.sell_outlined,
        label: isSubtopic ? 'Subtopic' : 'Topic',
        fg: AppColors.primary,
        bg: AppColors.primarySoft,
      ),
      if (topic.isRequired)
        _TopicStatusChip(
          icon: Icons.check_circle_outline_rounded,
          label: 'Required',
          fg: _K.blue,
          bg: _K.blueSoft,
        ),
      _TopicStatusChip(icon: readinessMeta.icon, label: readinessMeta.label, fg: readinessMeta.fg, bg: readinessMeta.bg),
      _TopicStatusChip(icon: difficultyMeta.icon, label: difficultyMeta.label, fg: difficultyMeta.fg, bg: difficultyMeta.bg),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.isDark
              ? [const Color(0xFF0F172A), AppColors.infoText, AppColors.purpleText]
              : [AppColors.primary, AppColors.infoText, AppColors.purpleText],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          const BoxShadow(
            color: Color(0x1A1D4ED8),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 8, runSpacing: 8, children: statusChips),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBg.withOpacity(0.14)),
                  ),
                  child: Icon(
                    isSubtopic ? Icons.subdirectory_arrow_right_rounded : Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.title,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _TopicBreadcrumb(icon: Icons.folder_outlined, text: module.title),
                          _TopicBreadcrumb(icon: Icons.article_outlined, text: material.displayTitle),
                          if (isSubtopic && parentTopicTitle != null)
                            _TopicBreadcrumb(icon: Icons.account_tree_outlined, text: parentTopicTitle!),
                          _TopicBreadcrumb(icon: Icons.calendar_today_outlined, text: 'Created $created'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: onManage,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.cardBg,
                    foregroundColor: AppColors.textTitle,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _HeroStat(
                    label: 'Mapped outcomes',
                    value: mappedOutcomesCount == 0 ? 'Unmapped' : '$mappedOutcomesCount linked',
                    helper: mappedOutcomesCount == 0 ? 'Needs alignment' : 'Aligned with course goals',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HeroStat(
                    label: 'Question workflow',
                    value: topic.readiness == TopicReadiness.ready ? 'Generation-ready' : 'Preparation mode',
                    helper: topic.readiness == TopicReadiness.ready ? 'Safe to build assessment coverage' : 'Refine content first',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HeroStat(
                    label: isSubtopic ? 'Hierarchy' : 'Topic type',
                    value: isSubtopic ? 'Nested under topic' : (topic.source == TopicSource.ai ? 'AI-assisted' : 'Instructor-led'),
                    helper: isSubtopic ? 'Final content level inside this material' : (topic.source == TopicSource.ai ? 'Generated from material context' : 'Created manually'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicInsightsGrid extends StatelessWidget {
  final TopicItem topic;
  final int mappedOutcomesCount;
  final bool isSubtopic;
  final String? parentTopicTitle;
  final _TopicMeta readinessMeta;
  final _TopicMeta difficultyMeta;

  const _TopicInsightsGrid({
    required this.topic,
    required this.mappedOutcomesCount,
    required this.isSubtopic,
    this.parentTopicTitle,
    required this.readinessMeta,
    required this.difficultyMeta,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final cards = [
      _TopicInsightData(
        title: 'Delivery status',
        value: readinessMeta.label,
        caption: topic.readiness == TopicReadiness.ready
            ? 'Ready for live teaching'
            : topic.readiness == TopicReadiness.review
                ? 'Needs final QA pass'
                : 'Still being prepared',
        icon: readinessMeta.icon,
        accent: readinessMeta.fg,
        softColor: readinessMeta.bg,
      ),
      _TopicInsightData(
        title: 'Difficulty',
        value: difficultyMeta.label,
        caption: topic.difficulty == TopicDifficulty.beginner
            ? 'Accessible introduction'
            : topic.difficulty == TopicDifficulty.intermediate
                ? 'Balanced depth'
                : 'Advanced treatment',
        icon: difficultyMeta.icon,
        accent: difficultyMeta.fg,
        softColor: difficultyMeta.bg,
      ),
      _TopicInsightData(
        title: 'Outcome coverage',
        value: mappedOutcomesCount == 0 ? 'Pending' : '$mappedOutcomesCount linked',
        caption: mappedOutcomesCount == 0
            ? 'No outcome alignment yet'
            : 'Connected to measurable outcomes',
        icon: Icons.flag_outlined,
        accent: _K.blue,
        softColor: _K.blueSoft,
      ),
      _TopicInsightData(
        title: isSubtopic ? 'Parent topic' : 'Instructor notes',
        value: isSubtopic
            ? (parentTopicTitle ?? 'Parent topic')
            : ((topic.instructorNotes?.trim().isNotEmpty ?? false) ? 'Available' : 'Missing'),
        caption: isSubtopic
            ? 'This subtopic is the final hierarchy level and cannot contain children.'
            : ((topic.instructorNotes?.trim().isNotEmpty ?? false)
                ? 'Delivery guidance has been added'
                : 'Add notes for examples and pacing'),
        icon: isSubtopic ? Icons.account_tree_outlined : Icons.sticky_note_2_outlined,
        accent: AppColors.primary,
        softColor: AppColors.primarySoft,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1100
            ? 4
            : constraints.maxWidth > 760
                ? 2
                : 1;
        final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 14) / crossAxisCount;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: cards
              .map((card) => SizedBox(
                    width: itemWidth,
                    child: _TopicInsightCard(data: card),
                  ),)
              .toList(),
        );
      },
    );
  }
}

class _TopicInsightData {
  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color accent;
  final Color softColor;

  const _TopicInsightData({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.accent,
    required this.softColor,
  });
}

class _TopicActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color softColor;
  final VoidCallback onTap;

  const _TopicActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.softColor,
    required this.onTap,
  });
}

class _TimelineEntry {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TimelineEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _TopicMeta {
  final String label;
  final IconData icon;
  final Color fg;
  final Color bg;

  const _TopicMeta({
    required this.label,
    required this.icon,
    required this.fg,
    required this.bg,
  });
}

class _TopicStatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color fg;
  final Color bg;

  const _TopicStatusChip({
    required this.icon,
    required this.label,
    required this.fg,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicBreadcrumb extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TopicBreadcrumb({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withOpacity(0.78)),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.84),
          ),
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final String helper;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBg.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.78),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Colors.white.withOpacity(0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicInsightCard extends StatelessWidget {
  final _TopicInsightData data;

  const _TopicInsightCard({required this.data});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.softColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.accent, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            data.title,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.textTitle),
          ),
          const SizedBox(height: 6),
          Text(
            data.caption,
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _TopicSmartActionsCard extends StatelessWidget {
  final List<_TopicActionData> actions;

  const _TopicSmartActionsCard({required this.actions});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _CardWidget(
      header: const _HdrWidget(
        icon: Icons.flash_on_rounded,
        iconColor: AppColors.primary,
        title: 'Smart Actions',
      ),
      child: Column(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            _TopicActionTile(data: actions[i]),
            if (i != actions.length - 1) Divider(height: 1, color: AppColors.borderSoft),
          ],
        ],
      ),
    );
  }
}

class _TopicActionTile extends StatelessWidget {
  final _TopicActionData data;

  const _TopicActionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: data.softColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(data.icon, color: data.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textTitle)),
                    const SizedBox(height: 4),
                    Text(data.subtitle, style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_outward_rounded, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicTimelineCard extends StatelessWidget {
  final List<_TimelineEntry> entries;

  const _TopicTimelineCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _CardWidget(
      header: const _HdrWidget(
        icon: Icons.schedule_rounded,
        iconColor: AppColors.primary,
        title: 'Topic timeline',
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          children: [
            for (var i = 0; i < entries.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(entries[i].icon, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entries[i].title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textTitle)),
                        const SizedBox(height: 4),
                        Text(entries[i].subtitle, style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.45)),
                      ],
                    ),
                  ),
                ],
              ),
              if (i != entries.length - 1) Padding(
                padding: const EdgeInsets.only(left: 15, top: 8, bottom: 8),
                child: Divider(height: 1, color: AppColors.borderSoft),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

_TopicMeta _topicReadinessMeta(TopicReadiness readiness) {
  switch (readiness) {
    case TopicReadiness.ready:
      return _TopicMeta(
        label: 'Ready',
        icon: Icons.check_circle_rounded,
        fg: _K.green,
        bg: _K.greenSoft,
      );
    case TopicReadiness.review:
      return const _TopicMeta(
        label: 'Needs Review',
        icon: Icons.pending_actions_rounded,
        fg: _K.amber,
        bg: _K.amberSoft,
      );
    case TopicReadiness.draft:
      return _TopicMeta(
        label: 'Draft',
        icon: Icons.edit_note_rounded,
        fg: AppColors.textMuted,
        bg: AppColors.headerBg,
      );
  }
}

_TopicMeta _topicDifficultyMeta(TopicDifficulty difficulty) {
  switch (difficulty) {
    case TopicDifficulty.beginner:
      return _TopicMeta(
        label: 'Beginner',
        icon: Icons.wb_sunny_outlined,
        fg: _K.blue,
        bg: _K.blueSoft,
      );
    case TopicDifficulty.intermediate:
      return const _TopicMeta(
        label: 'Intermediate',
        icon: Icons.stacked_bar_chart_rounded,
        fg: _K.amber,
        bg: _K.amberSoft,
      );
    case TopicDifficulty.advanced:
      return _TopicMeta(
        label: 'Advanced',
        icon: Icons.local_fire_department_outlined,
        fg: AppColors.dangerText,
        bg: AppColors.dangerBg,
      );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DIALOGS
// ─────────────────────────────────────────────────────────────────────────────
