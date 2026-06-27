part of 'materials_tab.dart';

class _CaptureTopicDialog extends StatelessWidget {
  final Future<bool> Function(
    String title,
    String? description,
    List<int> learningOutcomeIds,
  ) onCreate;

  const _CaptureTopicDialog({
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
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
                onCreate: onCreate,
                onSaved: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: Material(
                color: AppColors.surfaceBg,
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
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(Icons.close_rounded, size: 19, color: AppColors.textMuted),
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
  final Future<bool> Function(
    String title,
    String? description,
    List<int> learningOutcomeIds,
  ) onCreate;
  final VoidCallback? onSaved;

  const _CaptureTopicPanel({
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
      const <int>[],
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) return;

    _titleCtrl.clear();
    _pageCtrl.clear();
    _noteCtrl.clear();
    setState(() {
      _submitted = false;
    });
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _PremiumPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderGray)),
            ),
            child: Row(
              children: [
                const _SoftIcon(icon: Icons.add_task_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capture a topic',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textTitle),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Create a parent topic under this material. Outcomes are mapped later through subtopics.',
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.18)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.account_tree_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Outcome mapping belongs to subtopics',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.textTitle),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create the parent topic first. If it has subtopics, map each subtopic to its learning outcomes so the topic inherits coverage from its children.',
                              style: TextStyle(fontSize: 12.2, color: AppColors.textMuted, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                    label: Text(_saving ? 'Saving topic...' : 'Save topic'),
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
    Theme.of(context);
    final topicProgress = topics.isEmpty ? 0.0 : readyTopics / topics.length;
    final outcomeProgress = outcomes.isEmpty ? 0.0 : mappedOutcomeIds.length / outcomes.length;

    return _PremiumPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SoftIcon(icon: Icons.insights_rounded, color: AppColors.purpleText),
              const SizedBox(width: 12),
              Expanded(
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
            color: AppColors.purpleText,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.surfaceBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGray),
            ),
            child: Row(
              children: [
                Icon(Icons.tips_and_updates_outlined, size: 18, color: AppColors.warningText),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _coverageHint,
                    style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
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

    return _PremiumPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                const _SoftIcon(icon: Icons.route_rounded, color: Color(0xFF0F766E)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Topic map',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textTitle),
                      ),
                      const SizedBox(height: 3),
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
          Divider(height: 1, color: AppColors.borderGray),
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
    Theme.of(context);
    return Material(
      color: AppColors.surfaceBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => onTopicTap(topic),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.textTitle),
                    ),
                    if ((topic.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        topic.description!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.2, color: AppColors.textMuted, height: 1.35),
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
                                  color: AppColors.cardBg,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.subdirectory_arrow_right_rounded, size: 13, color: AppColors.textMuted),
                                    const SizedBox(width: 5),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 170),
                                      child: Text(
                                        child.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textTitle),
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
              const SizedBox(width: 14),
              const _TopicViewAction(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicViewAction extends StatelessWidget {
  const _TopicViewAction();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.only(left: 13, right: 8),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'View',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.primary),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_rounded, size: 17, color: AppColors.primary),
        ],
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
    Theme.of(context);
    return TextField(
      controller: controller,
      enabled: enabled,
      minLines: minLines,
      maxLines: maxLines,
      onSubmitted: onSubmitted,
      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textTitle),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surfaceBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        labelStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textMuted),
        hintStyle: TextStyle(fontSize: 13, color: AppColors.textHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.borderGray),
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
    Theme.of(context);
    return Material(
      color: selected ? AppColors.infoBg : AppColors.surfaceBg,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: selected ? AppColors.primary.withOpacity(0.40) : AppColors.borderGray),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selected ? AppColors.primary : AppColors.borderSoft),
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
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textTitle, height: 1.25),
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
    Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.textMuted)),
            ),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress.clamp(0.0, 1.0).toDouble(),
            backgroundColor: AppColors.borderSoft,
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
    Theme.of(context);
    return Container(
      width: 112,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
                Text(helper, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
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
    Theme.of(context);
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
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
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
    Theme.of(context);
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
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBg.withOpacity(0.10)),
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
    Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surfaceBg,
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
              border: Border.all(color: AppColors.borderGray),
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
    Theme.of(context);
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: _open,
        icon: const Icon(Icons.open_in_new_rounded, size: 16),
        label: const Text('Open PDF'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textTitle,
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
    Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.route_outlined, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 13),
          Text(
            'No topic map yet',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textTitle),
          ),
          const SizedBox(height: 6),
          Text(
            'Capture topics while reading the PDF. They will appear here as a clean review map.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.45),
          ),
        ],
      ),
    );
  }
}


IconData _materialTypeIcon(MaterialItem material) {
  switch (material.type.toLowerCase()) {
    case 'video':
      return Icons.play_circle_fill_rounded;
    case 'audio':
      return Icons.headphones_rounded;
    case 'link':
      return Icons.link_rounded;
    case 'document':
      return Icons.description_rounded;
    case 'presentation':
      return Icons.slideshow_rounded;
    case 'quiz':
      return Icons.quiz_rounded;
    case 'image':
      return Icons.image_rounded;
    case 'pdf':
    default:
      return Icons.picture_as_pdf_rounded;
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

String _documentMetaLine(
  MaterialItem material, {
  _PdfPageRange? pageRange,
  String? scopeSubtitle,
}) {
  final parts = <String>[];
  final subtitle = (scopeSubtitle ?? '').trim();
  if (subtitle.isNotEmpty) parts.add(subtitle);
  final fileName = (material.fileName ?? '').trim();
  if (fileName.isNotEmpty) parts.add(fileName);
  if (pageRange != null) {
    parts.add('${pageRange.explicitLabel} (${pageRange.countLabel})');
  } else if (material.pageCount != null) {
    parts.add('${material.pageCount} pages');
  }
  if (material.fileSize != null) parts.add(_MetaStripW._fmt(material.fileSize!));
  if (parts.isEmpty) return material.type.toUpperCase();
  return parts.join('  •  ');
}

// ─────────────────────────────────────────────────────────────────────────────
//  FILE PREVIEW
// ─────────────────────────────────────────────────────────────────────────────
