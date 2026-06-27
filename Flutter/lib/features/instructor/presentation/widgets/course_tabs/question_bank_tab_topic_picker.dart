part of 'question_bank_tab.dart';

class _QuestionGenerationTopicPickerDialog extends StatefulWidget {
  final List<_TopicTarget> topicTargets;

  const _QuestionGenerationTopicPickerDialog({required this.topicTargets});

  @override
  State<_QuestionGenerationTopicPickerDialog> createState() =>
      _QuestionGenerationTopicPickerDialogState();
}

class _QuestionGenerationTopicPickerDialogState
    extends State<_QuestionGenerationTopicPickerDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  int? _selectedTopicId;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_TopicTarget> get _filteredTargets {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return widget.topicTargets;
    return widget.topicTargets.where((target) {
      final label = _topicDisplayTitle(target).toLowerCase();
      final module = target.module.title.toLowerCase();
      final material = target.material.displayTitle.toLowerCase();
      final parent = (target.parentTopicTitle ?? '').toLowerCase();
      return label.contains(query) ||
          module.contains(query) ||
          material.contains(query) ||
          parent.contains(query);
    }).toList();
  }

  _TopicTarget? get _selectedTarget {
    final id = _selectedTopicId;
    if (id == null) return null;
    for (final target in widget.topicTargets) {
      if (target.topic.id == id) return target;
    }
    return null;
  }

  String _topicDisplayTitle(_TopicTarget target) {
    final parent = target.parentTopicTitle;
    if (parent != null && parent.trim().isNotEmpty) {
      return '$parent / ${target.topic.title}';
    }
    return target.topic.title;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTargets;
    final selected = _selectedTarget;
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 42,
                  spreadRadius: 2,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 18, 16),
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
                        child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Generate questions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textTitle,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Choose the topic you want to use as the AI generation scope.',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                 Divider(height: 1, color: AppColors.borderGray),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search topic, material, or module...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: AppColors.pageBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:  BorderSide(color: AppColors.borderGray),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:  BorderSide(color: AppColors.borderGray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ),
                Flexible(
                  child: filtered.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 34),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded, size: 42, color: AppColors.textMuted.withOpacity(0.65)),
                              const SizedBox(height: 12),
                              Text(
                                'No matching topics',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textTitle,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try a different topic, module, or material keyword.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final target = filtered[index];
                            final selected = _selectedTopicId == target.topic.id;
                            final isSubtopic = target.topic.parentTopicId != null;
                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => setState(() => _selectedTopicId = target.topic.id),
                              onDoubleTap: () => Navigator.of(context).pop(target),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.primarySoft : AppColors.cardBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selected ? AppColors.primary : AppColors.borderGray,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: selected ? AppColors.primary : AppColors.pageBg,
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        isSubtopic ? Icons.subdirectory_arrow_right_rounded : Icons.tag_rounded,
                                        size: 18,
                                        color: selected ? Colors.white : AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _topicDisplayTitle(target),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.textTitle,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${target.module.title} • ${target.material.displayTitle}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11.8,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Radio<int>(
                                      value: target.topic.id,
                                      groupValue: _selectedTopicId,
                                      onChanged: (value) => setState(() => _selectedTopicId = value),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  decoration:  BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.borderGray)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selected == null
                              ? '${widget.topicTargets.length} topic${widget.topicTargets.length == 1 ? '' : 's'} available'
                              : _topicDisplayTitle(selected),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: selected == null ? AppColors.textMuted : AppColors.textTitle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: selected == null
                            ? null
                            : () => Navigator.of(context).pop(selected),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Open Workspace'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

