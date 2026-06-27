part of 'question_bank_authoring_flow.dart';

class _WorkspaceMetric {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _WorkspaceMetric(this.icon, this.title, this.value, this.subtitle);
}

class _StoredQuestionWorkspace {
  final List<add_question_sheet.QuestionAuthoringTarget> targets;
  final List<QuestionModel> questions;
  final Set<String> selectedIds;
  final _WorkspaceMode mode;
  final bool aiPolling;
  final int aiPollAttempts;
  final int pendingAiExpectedCount;
  final String? pendingAiRequestId;
  final DateTime? pendingAiStartedAt;
  final Set<int> pendingAiRequestTopicIds;
  final Set<int> receivedAiQuestionIds;
  final Set<int> knownRemoteIds;

  const _StoredQuestionWorkspace({
    required this.targets,
    required this.questions,
    required this.selectedIds,
    required this.mode,
    this.aiPolling = false,
    this.aiPollAttempts = 0,
    this.pendingAiExpectedCount = 0,
    this.pendingAiRequestId,
    this.pendingAiStartedAt,
    this.pendingAiRequestTopicIds = const <int>{},
    this.receivedAiQuestionIds = const <int>{},
    this.knownRemoteIds = const <int>{},
  });
}

class _ModeSpec {
  final _WorkspaceMode mode;
  final String title;
  final String subtitle;
  final IconData icon;

  const _ModeSpec({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _BackToMaterialsButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool compact;
  final bool onDark;

  const _BackToMaterialsButton({
    required this.onPressed,
    required this.compact,
    this.onDark = false,
  });

  @override
  State<_BackToMaterialsButton> createState() => _BackToMaterialsButtonState();
}

class _BackToMaterialsButtonState extends State<_BackToMaterialsButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          height: 42,
          padding: EdgeInsets.symmetric(horizontal: widget.compact ? 12 : 14),
          decoration: BoxDecoration(
            color: widget.onDark
                ? Colors.white.withOpacity(_hovered ? 0.22 : 0.14)
                : (_hovered ? AppColors.primary : AppColors.cardBg),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.onDark
                  ? Colors.white.withOpacity(0.22)
                  : (_hovered ? AppColors.primary : AppColors.infoBorder),
              width: 1.2,
            ),
            boxShadow: widget.onDark
                ? const <BoxShadow>[]
                : <BoxShadow>[
                    BoxShadow(
                      color: AppColors.shadowBlue.withOpacity(_hovered ? 0.28 : 0.18),
                      blurRadius: _hovered ? 16 : 10,
                      offset: Offset(0, _hovered ? 6 : 3),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: widget.onDark ? Colors.white.withOpacity(0.16) : (_hovered ? Colors.white.withOpacity(0.18) : AppColors.infoBg),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: widget.onDark ? Colors.white : (_hovered ? Colors.white : AppColors.primary),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                'Back to Materials',
                style: TextStyle(
                  fontSize: widget.compact ? 12.5 : 13,
                  fontWeight: FontWeight.w900,
                  color: widget.onDark ? Colors.white : (_hovered ? Colors.white : AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterMenu extends StatelessWidget {
  final double width;
  final String label;
  final List<String> items;
  final ValueChanged<String> onSelected;

  const _FilterMenu({
    required this.width,
    required this.label,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final List<String> normalizedItems = <String>[];
    for (final String item in items) {
      if (!normalizedItems.contains(item)) normalizedItems.add(item);
    }

    return SizedBox(
      width: width,
      height: 48,
      child: PopupMenuButton<String>(
        tooltip: '',
        color: AppColors.cardBg,
        elevation: 5,
        surfaceTintColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.borderGray),
        ),
        position: PopupMenuPosition.under,
        offset: const Offset(0, 8),
        onSelected: onSelected,
        itemBuilder: (BuildContext context) {
          return normalizedItems.map((String item) {
            final bool isSelected = item == label;
            return PopupMenuItem<String>(
              value: item,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.selectedBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textGray,
                  ),
                ),
              ),
            );
          }).toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textGray,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicTreeFilterButton extends StatelessWidget {
  final int? selectedTopicId;
  final List<add_question_sheet.QuestionAuthoringTarget> targets;
  final ValueChanged<int?> onChanged;

  const _TopicTreeFilterButton({
    required this.selectedTopicId,
    required this.targets,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final add_question_sheet.QuestionAuthoringTarget? selected =
        selectedTopicId == null ? null : _findTarget(targets, selectedTopicId!);
    final String label = selected == null ? 'All Topics' : _compactTargetLabel(selected);

    return InkWell(
      onTap: () async {
        final int? result = await showDialog<int?>(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.30),
          builder: (_) => _TopicTreeFilterDialog(
            targets: targets,
            selectedTopicId: selectedTopicId,
          ),
        );
        if (result != -999999) onChanged(result);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.account_tree_outlined, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textGray,
                ),
              ),
            ),
            Icon(Icons.unfold_more_rounded, color: AppColors.textMuted, size: 19),
          ],
        ),
      ),
    );
  }
}

class _TopicTreeFilterDialog extends StatefulWidget {
  final int? selectedTopicId;
  final List<add_question_sheet.QuestionAuthoringTarget> targets;

  const _TopicTreeFilterDialog({
    required this.selectedTopicId,
    required this.targets,
  });

  @override
  State<_TopicTreeFilterDialog> createState() => _TopicTreeFilterDialogState();
}

class _TopicTreeFilterDialogState extends State<_TopicTreeFilterDialog> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = _searchCtrl.text.trim().toLowerCase();
    final List<add_question_sheet.QuestionAuthoringTarget> filtered = widget.targets.where((target) {
      if (query.isEmpty) return true;
      return <String>[
        target.topicName,
        target.parentTopicName ?? '',
        target.materialName ?? '',
        target.moduleName ?? '',
      ].join(' ').toLowerCase().contains(query);
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 680),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 14, 16),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_tree_outlined, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Topic filter',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textTitle,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Pick one topic/subtopic from the resolved course tree.',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(-999999),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGray),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
                      hintText: 'Search topic, material, or module...',
                      hintStyle: TextStyle(color: AppColors.textHint),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  children: <Widget>[
                    _treeOption(
                      context,
                      selected: widget.selectedTopicId == null,
                      icon: Icons.all_inclusive_rounded,
                      title: 'All Topics',
                      subtitle: '${widget.targets.length} targets in current scope',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 8),
                    ..._buildGroupedTargetRows(context, filtered),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedTargetRows(
    BuildContext context,
    List<add_question_sheet.QuestionAuthoringTarget> targets,
  ) {
    final List<Widget> rows = <Widget>[];
    String? currentModule;
    String? currentMaterial;

    for (final add_question_sheet.QuestionAuthoringTarget target in targets) {
      if (target.moduleName != currentModule) {
        currentModule = target.moduleName;
        rows.add(_groupHeader(Icons.school_outlined, currentModule ?? 'Module'));
        currentMaterial = null;
      }
      if (target.materialName != currentMaterial) {
        currentMaterial = target.materialName;
        rows.add(_groupHeader(Icons.description_outlined, currentMaterial ?? 'Material', indent: 14));
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(left: 28, top: 6),
          child: _treeOption(
            context,
            selected: widget.selectedTopicId == target.topicId,
            icon: target.isSubtopic ? Icons.subdirectory_arrow_right_rounded : Icons.topic_outlined,
            title: _compactTargetLabel(target),
            subtitle: target.isSubtopic ? 'Subtopic' : 'Topic',
            onTap: () => Navigator.of(context).pop(target.topicId),
          ),
        ),
      );
    }
    return rows;
  }

  Widget _groupHeader(IconData icon, String title, {double indent = 0}) {
    return Padding(
      padding: EdgeInsets.only(left: indent, top: 14, bottom: 6),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.45,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _treeOption(
    BuildContext context, {
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.selectedBg : AppColors.surfaceBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: selected ? AppColors.primary.withOpacity(0.50) : AppColors.borderGray),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.cardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: selected ? Colors.white : AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.2,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textTitle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceExitDialog extends StatelessWidget {
  final int questionCount;
  final int targetCount;
  final bool aiRunning;

  const _WorkspaceExitDialog({
    required this.questionCount,
    required this.targetCount,
    required this.aiRunning,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderGray),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.warningBg,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: AppColors.warningText,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Exit question workspace?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textTitle,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$questionCount question${questionCount == 1 ? '' : 's'} shown across $targetCount target${targetCount == 1 ? '' : 's'}. Questions already created are saved in the question bank.${aiRunning ? ' AI generation may continue in the background.' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.borderGray),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textGray,
                          side: BorderSide(color: AppColors.borderSoft),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Stay'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(_WorkspaceExitAction.exit),
                        icon: const Icon(Icons.check_rounded, size: 17),
                        label: const Text('Exit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
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

