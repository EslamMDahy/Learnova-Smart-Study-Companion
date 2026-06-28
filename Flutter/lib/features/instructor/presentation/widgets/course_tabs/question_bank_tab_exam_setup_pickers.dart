part of 'question_bank_tab.dart';

class _SetupDropdownField extends StatelessWidget {
  final String label;
  final double width;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _SetupDropdownField({
    required this.label,
    required this.width,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          FigmaUmDropdown40(
            width: width,
            value: value,
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ScopeModeSelector extends StatelessWidget {
  final _ExamScopeMode mode;
  final int selectedTopicCount;
  final int selectedOutcomeCount;
  final ValueChanged<_ExamScopeMode> onChanged;

  const _ScopeModeSelector({
    required this.mode,
    required this.selectedTopicCount,
    required this.selectedOutcomeCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 560;
        final options = [
          _ScopeModeOption(
            title: 'Topics / Subtopics',
            subtitle: selectedTopicCount == 0 ? 'Backend generation can use all topics' : '$selectedTopicCount selected',
            icon: Icons.account_tree_outlined,
            selected: mode == _ExamScopeMode.topics,
            onTap: () => onChanged(_ExamScopeMode.topics),
          ),
          _ScopeModeOption(
            title: 'Learning Outcomes',
            subtitle: selectedOutcomeCount == 0 ? 'Manual build only' : '$selectedOutcomeCount selected',
            icon: Icons.flag_outlined,
            selected: mode == _ExamScopeMode.outcomes,
            onTap: () => onChanged(_ExamScopeMode.outcomes),
          ),
        ];

        if (stacked) {
          return Column(
            children: [
              options[0],
              const SizedBox(height: 10),
              options[1],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: options[0]),
            const SizedBox(width: 10),
            Expanded(child: options[1]),
          ],
        );
      },
    );
  }
}

class _ScopeModeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ScopeModeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary.withValues(alpha: 0.28) : AppColors.borderGray),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.cardBg,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: selected ? AppColors.primary : AppColors.borderGray),
              ),
              child: Icon(icon, color: selected ? Colors.white : AppColors.textMuted, size: 18),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textTitle,
                      fontSize: 12.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.primary : AppColors.textMuted,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupTopicTreePicker extends StatelessWidget {
  final List<_TopicTarget> targets;
  final Set<int> selectedTopicIds;
  final ValueChanged<Set<int>> onChanged;

  const _SetupTopicTreePicker({
    super.key,
    required this.targets,
    required this.selectedTopicIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final visibleIds = targets.map((target) => target.topic.id).toSet();
    final visibleSelectedIds = selectedTopicIds.intersection(visibleIds);
    final groups = <String, List<_TopicTarget>>{};
    final groupLabels = <String, String>{};
    for (final target in targets) {
      final key = '${target.module.id}:${target.material.id}';
      groups.putIfAbsent(key, () => <_TopicTarget>[]).add(target);
      groupLabels[key] = '${target.module.title} • ${target.material.displayTitle}';
    }

    return _SetupPickerFrame(
      title: 'Topics / Subtopics',
      subtitle: visibleSelectedIds.isEmpty
          ? 'No selection means the backend will use all topics in the course.'
          : '${visibleSelectedIds.length} selected from the visible list',
      onSelectAll: visibleIds.isEmpty ? null : () => onChanged(visibleIds),
      onClear: visibleSelectedIds.isEmpty ? null : () => onChanged(<int>{}),
      child: targets.isEmpty
          ? const _SetupPickerEmpty(message: 'No topics found for the selected module/material.')
          : SizedBox(
              height: 300,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: groups.entries.map((entry) {
                    final items = entry.value;
                    final byId = {for (final target in items) target.topic.id: target};
                    final childrenByParent = <int, List<_TopicTarget>>{};
                    final roots = <_TopicTarget>[];

                    for (final target in items) {
                      final parentId = target.topic.parentTopicId;
                      if (parentId != null && byId.containsKey(parentId)) {
                        childrenByParent.putIfAbsent(parentId, () => <_TopicTarget>[]).add(target);
                      } else {
                        roots.add(target);
                      }
                    }

                    roots.sort((a, b) => a.topic.orderIndex.compareTo(b.topic.orderIndex));
                    for (final children in childrenByParent.values) {
                      children.sort((a, b) => a.topic.orderIndex.compareTo(b.topic.orderIndex));
                    }

                    final branchIdsCache = <int, Set<int>>{};

                    Set<int> branchIds(_TopicTarget target) {
                      return branchIdsCache.putIfAbsent(target.topic.id, () {
                        final result = <int>{target.topic.id};
                        void collect(int parentId) {
                          for (final child in childrenByParent[parentId] ?? const <_TopicTarget>[]) {
                            result.add(child.topic.id);
                            collect(child.topic.id);
                          }
                        }

                        collect(target.topic.id);
                        return result;
                      });
                    }

                    void toggleBranch(_TopicTarget target) {
                      final ids = branchIds(target);
                      final next = Set<int>.from(selectedTopicIds)..removeWhere((id) => !visibleIds.contains(id));
                      final allSelected = ids.every(next.contains);
                      if (allSelected) {
                        next.removeAll(ids);
                      } else {
                        next.addAll(ids);
                      }
                      onChanged(next);
                    }

                    Widget buildNode(_TopicTarget target, int depth) {
                      final ids = branchIds(target);
                      final selectedCount = ids.where(selectedTopicIds.contains).length;
                      final checked = selectedCount == 0
                          ? false
                          : selectedCount == ids.length
                              ? true
                              : null;
                      final children = childrenByParent[target.topic.id] ?? const <_TopicTarget>[];
                      final hasChildren = children.isNotEmpty;
                      final selected = checked == true;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => toggleBranch(target),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              margin: EdgeInsets.only(left: depth * 24.0, bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.primarySoft : AppColors.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: selected ? AppColors.primary.withValues(alpha: 0.24) : AppColors.borderGray),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: Checkbox(
                                      value: checked,
                                      tristate: true,
                                      onChanged: (_) => toggleBranch(target),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: selected ? AppColors.cardBg : AppColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Icon(
                                      depth > 0
                                          ? Icons.subdirectory_arrow_right_rounded
                                          : hasChildren
                                              ? Icons.account_tree_outlined
                                              : Icons.topic_outlined,
                                      size: 16,
                                      color: selected ? AppColors.primary : AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          target.topic.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: AppColors.textTitle,
                                            fontSize: 12.6,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        if (hasChildren) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '${children.length} subtopic${children.length == 1 ? '' : 's'}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 10.8,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ...children.map((child) => buildNode(child, depth + 1)),
                        ],
                      );
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderGray),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.folder_open_rounded, size: 16, color: AppColors.textMuted),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  groupLabels[entry.key] ?? 'Material',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11.3,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...roots.map((target) => buildNode(target, 0)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }
}

class _SetupOutcomePicker extends StatelessWidget {
  final List<LearningOutcome> outcomes;
  final Set<int> selectedOutcomeIds;
  final ValueChanged<Set<int>> onChanged;

  const _SetupOutcomePicker({
    super.key,
    required this.outcomes,
    required this.selectedOutcomeIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final allIds = outcomes.map((outcome) => outcome.id).where((id) => id > 0).toSet();
    final visibleSelectedIds = selectedOutcomeIds.intersection(allIds);
    final byId = {for (final outcome in outcomes) outcome.id: outcome};
    final childrenByParent = <int, List<LearningOutcome>>{};
    final roots = <LearningOutcome>[];

    for (final outcome in outcomes) {
      final parentId = outcome.parentLearningOutcomeId;
      if (parentId != null && byId.containsKey(parentId)) {
        childrenByParent.putIfAbsent(parentId, () => <LearningOutcome>[]).add(outcome);
      } else {
        roots.add(outcome);
      }
    }

    int compareOutcomes(LearningOutcome a, LearningOutcome b) {
      final aCode = a.code.trim();
      final bCode = b.code.trim();
      if (aCode.isNotEmpty && bCode.isNotEmpty) {
        final codeCompare = aCode.toLowerCase().compareTo(bCode.toLowerCase());
        if (codeCompare != 0) return codeCompare;
      }
      final difficultyCompare = a.difficulty.index.compareTo(b.difficulty.index);
      if (difficultyCompare != 0) return difficultyCompare;
      return a.id.compareTo(b.id);
    }

    roots.sort(compareOutcomes);
    for (final children in childrenByParent.values) {
      children.sort(compareOutcomes);
    }

    final branchIdsCache = <int, Set<int>>{};
    Set<int> branchIds(LearningOutcome outcome) {
      return branchIdsCache.putIfAbsent(outcome.id, () {
        final result = <int>{outcome.id};
        void collect(int parentId) {
          for (final child in childrenByParent[parentId] ?? const <LearningOutcome>[]) {
            result.add(child.id);
            collect(child.id);
          }
        }

        collect(outcome.id);
        return result;
      });
    }

    void toggleBranch(LearningOutcome outcome) {
      final ids = branchIds(outcome);
      final next = Set<int>.from(selectedOutcomeIds)..removeWhere((id) => !allIds.contains(id));
      final allSelected = ids.every(next.contains);
      if (allSelected) {
        next.removeAll(ids);
      } else {
        next.addAll(ids);
      }
      onChanged(next);
    }

    Widget buildNode(LearningOutcome outcome, int depth) {
      final ids = branchIds(outcome);
      final selectedCount = ids.where(selectedOutcomeIds.contains).length;
      final checked = selectedCount == 0
          ? false
          : selectedCount == ids.length
              ? true
              : null;
      final children = childrenByParent[outcome.id] ?? const <LearningOutcome>[];
      final hasChildren = children.isNotEmpty;
      final selected = checked == true;
      final isChild = outcome.parentLearningOutcomeId != null;
      final title = outcome.title.trim().isEmpty ? 'Learning outcome ${outcome.id}' : outcome.title.trim();
      final code = outcome.code.trim();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => toggleBranch(outcome),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: EdgeInsets.only(left: depth * 24.0, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primarySoft : AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? AppColors.primary.withValues(alpha: 0.24) : AppColors.borderGray),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: Checkbox(
                      value: checked,
                      tristate: true,
                      onChanged: (_) => toggleBranch(outcome),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.cardBg : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      isChild
                          ? Icons.subdirectory_arrow_right_rounded
                          : hasChildren
                              ? Icons.account_tree_outlined
                              : Icons.flag_outlined,
                      size: 16,
                      color: selected ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            if (code.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: AppColors.borderGray),
                                ),
                                child: Text(
                                  code,
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10.2,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                            ],
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textTitle,
                                  fontSize: 12.6,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasChildren
                              ? '${children.length} assessment criteria'
                              : isChild
                                  ? '${outcome.difficulty.label} criterion'
                                  : 'Learning outcome',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...children.map((child) => buildNode(child, depth + 1)),
        ],
      );
    }

    return _SetupPickerFrame(
      title: 'Learning outcomes',
      subtitle: visibleSelectedIds.isEmpty ? 'Select parent outcomes or individual criteria for manual building.' : '${visibleSelectedIds.length} selected',
      onSelectAll: allIds.isEmpty ? null : () => onChanged(allIds),
      onClear: visibleSelectedIds.isEmpty ? null : () => onChanged(<int>{}),
      child: outcomes.isEmpty
          ? const _SetupPickerEmpty(message: 'No learning outcomes found for this course yet.')
          : SizedBox(
              height: 300,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: roots.map((outcome) => buildNode(outcome, 0)).toList(),
                ),
              ),
            ),
    );
  }
}

class _SetupPickerFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClear;

  const _SetupPickerFrame({
    required this.title,
    required this.subtitle,
    required this.child,
    this.onSelectAll,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: onSelectAll,
                child: const Text('Select all'),
              ),
              TextButton(
                onPressed: onClear,
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SetupPickerEmpty extends StatelessWidget {
  final String message;

  const _SetupPickerEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 22),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12.2,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}