part of 'question_bank_authoring_flow.dart';

class _AiQuestionConfig {
  QuestionType type;
  QuestionDifficulty difficulty;
  int count;

  _AiQuestionConfig({
    required this.type,
    required this.difficulty,
    required this.count,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.backendValue,
        'difficulty': difficulty.backendValue,
        'count': count,
      };
}

class _AiGenerationRequest {
  final List<Map<String, dynamic>> topics;

  const _AiGenerationRequest({required this.topics});

  int get topicCount => topics.length;

  int get totalQuestions {
    var total = 0;
    for (final Map<String, dynamic> topic in topics) {
      final List<dynamic> configs = topic['question_configs'] as List<dynamic>;
      for (final dynamic config in configs) {
        total += ((config as Map<String, dynamic>)['count'] as num).toInt();
      }
    }
    return total;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'topics': topics};
}

class _AiTopicSelection {
  final add_question_sheet.QuestionAuthoringTarget target;
  bool selected;
  final List<_AiQuestionConfig> configs;

  _AiTopicSelection({
    required this.target,
    required this.selected,
    required this.configs,
  });

  int get totalQuestions => configs.fold<int>(
        0,
        (int total, _AiQuestionConfig config) => total + config.count,
      );

  Map<String, dynamic> toRequestJson() => <String, dynamic>{
        'topic_id': target.topicId,
        'question_configs': configs
            .map((_AiQuestionConfig config) => config.toJson())
            .toList(),
      };
}

class _AiGenerationDialog extends StatefulWidget {
  final List<add_question_sheet.QuestionAuthoringTarget> targets;
  final int? initialTopicId;

  const _AiGenerationDialog({
    required this.targets,
    this.initialTopicId,
  });

  @override
  State<_AiGenerationDialog> createState() => _AiGenerationDialogState();
}

class _AiGenerationDialogState extends State<_AiGenerationDialog> {
  static const int _maxQuestionsPerRequest = 50;
  static const List<QuestionType> _supportedTypes = <QuestionType>[
    QuestionType.multipleChoice,
    QuestionType.multiSelect,
    QuestionType.trueFalse,
    QuestionType.shortAnswer,
    QuestionType.essay,
  ];

  final TextEditingController _searchController = TextEditingController();
  late final List<_AiTopicSelection> _selections;
  String _searchQuery = '';

  List<_AiTopicSelection> get _selectedTopics => _selections
      .where((_AiTopicSelection selection) => selection.selected)
      .toList();

  List<_AiTopicSelection> get _filteredTopics {
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _selections;
    return _selections.where((_AiTopicSelection selection) {
      final add_question_sheet.QuestionAuthoringTarget target = selection.target;
      return target.topicName.toLowerCase().contains(query) ||
          (target.parentTopicName ?? '').toLowerCase().contains(query) ||
          (target.materialName ?? '').toLowerCase().contains(query) ||
          (target.moduleName ?? '').toLowerCase().contains(query);
    }).toList();
  }

  int get _totalQuestions => _selectedTopics.fold<int>(
        0,
        (int total, _AiTopicSelection selection) =>
            total + selection.totalQuestions,
      );

  int get _selectedRuleCount => _selectedTopics.fold<int>(
        0,
        (int total, _AiTopicSelection selection) =>
            total + selection.configs.length,
      );

  @override
  void initState() {
    super.initState();
    final bool hasInitialTopic = widget.initialTopicId != null &&
        widget.targets.any(
          (add_question_sheet.QuestionAuthoringTarget target) =>
              target.topicId == widget.initialTopicId,
        );
    _selections = List<_AiTopicSelection>.generate(
      widget.targets.length,
      (int index) => _AiTopicSelection(
        target: widget.targets[index],
        selected: hasInitialTopic
            ? widget.targets[index].topicId == widget.initialTopicId
            : index == 0,
        configs: <_AiQuestionConfig>[
          _AiQuestionConfig(
            type: QuestionType.multipleChoice,
            difficulty: QuestionDifficulty.medium,
            count: 5,
          ),
        ],
      ),
    );
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _AiGenerationRequest request = _buildRequest();
    final int selectedCount = request.topicCount;
    final int totalQuestions = request.totalQuestions;
    final bool canGenerate = selectedCount > 0 &&
        totalQuestions > 0 &&
        totalQuestions <= _maxQuestionsPerRequest;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1060, maxHeight: 790),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGray),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxWidth < 820;
                return Column(
                  children: <Widget>[
                    _dialogHeader(compact: compact),
                    Divider(height: 1, color: AppColors.borderGray),
                    Expanded(
                      child: compact
                          ? SingleChildScrollView(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  SizedBox(
                                    height: 510,
                                    child: _buildTopicsPanel(compact: true),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildSummaryPanel(compact: true),
                                ],
                              ),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Expanded(
                                  flex: 65,
                                  child: Padding(
                                    padding: const EdgeInsets.all(22),
                                    child: _buildTopicsPanel(compact: false),
                                  ),
                                ),
                                VerticalDivider(
                                  width: 1,
                                  color: AppColors.borderGray,
                                ),
                                Expanded(
                                  flex: 35,
                                  child: Container(
                                    color: AppColors.surfaceBg,
                                    padding: const EdgeInsets.all(22),
                                    child: _buildSummaryPanel(compact: false),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    _dialogFooter(
                      canGenerate: canGenerate,
                      request: request,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogHeader({required bool compact}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 18 : 22, 18, 14, 16),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF137FEC), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Generate questions',
                  style: TextStyle(
                    fontSize: compact ? 18 : 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textTitle,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select several topics, then add one or more question rules to every topic.',
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
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
            icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsPanel({required bool compact}) {
    final List<_AiTopicSelection> visibleTopics = _filteredTopics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _sectionTitle(
          '1. Select topics',
          '${_selectedTopics.length} selected',
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search topics, materials, or modules...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchQuery.trim().isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: _searchController.clear,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
            filled: true,
            fillColor: AppColors.surfaceBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            TextButton.icon(
              onPressed: visibleTopics.isEmpty
                  ? null
                  : () => _setVisibleTopicsSelected(visibleTopics, true),
              icon: const Icon(Icons.done_all_rounded, size: 17),
              label: const Text('Select visible'),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: _selectedTopics.isEmpty
                  ? null
                  : () => setState(() {
                        for (final _AiTopicSelection selection in _selections) {
                          selection.selected = false;
                        }
                      }),
              child: const Text('Clear'),
            ),
            const Spacer(),
            Text(
              '${visibleTopics.length} available',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: visibleTopics.isEmpty
              ? _emptyTopicsState()
              : ListView.separated(
                  itemCount: visibleTopics.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 9),
                  itemBuilder: (_, int index) =>
                      _topicSelectionCard(visibleTopics[index], compact: compact),
                ),
        ),
      ],
    );
  }

  Widget _topicSelectionCard(
    _AiTopicSelection selection, {
    required bool compact,
  }) {
    final add_question_sheet.QuestionAuthoringTarget target = selection.target;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selection.selected
            ? AppColors.primary.withValues(alpha: 0.055)
            : AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: selection.selected
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.borderGray,
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Checkbox(
                value: selection.selected,
                onChanged: (bool? value) => setState(() {
                  selection.selected = value ?? false;
                }),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  target.isSubtopic
                      ? Icons.subdirectory_arrow_right_rounded
                      : Icons.topic_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _compactTargetLabel(target),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      target.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (!selection.selected)
                TextButton(
                  onPressed: () => setState(() => selection.selected = true),
                  child: const Text('Add'),
                ),
            ],
          ),
          if (selection.selected) ...<Widget>[
            const SizedBox(height: 11),
            Divider(height: 1, color: AppColors.borderGray),
            const SizedBox(height: 11),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Question rules',
                    style: TextStyle(
                      color: AppColors.textTitle,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${selection.configs.length} ${selection.configs.length == 1 ? 'rule' : 'rules'}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            ...List<Widget>.generate(
              selection.configs.length,
              (int index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == selection.configs.length - 1 ? 0 : 8,
                ),
                child: _questionRuleCard(
                  selection,
                  selection.configs[index],
                  index,
                  compact: compact,
                ),
              ),
            ),
            const SizedBox(height: 9),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _totalQuestions >= _maxQuestionsPerRequest
                    ? null
                    : () => _addQuestionRule(selection),
                icon: const Icon(Icons.add_rounded, size: 17),
                label: const Text('Add question rule'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.28),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _questionRuleCard(
    _AiTopicSelection selection,
    _AiQuestionConfig config,
    int index, {
    required bool compact,
  }) {
    final Widget ruleLabel = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Rule ${index + 1}',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 10.8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    final Widget removeButton = IconButton(
      tooltip: 'Remove this rule',
      visualDensity: VisualDensity.compact,
      onPressed: selection.configs.length <= 1
          ? null
          : () => setState(() => selection.configs.remove(config)),
      icon: Icon(
        Icons.delete_outline_rounded,
        size: 18,
        color: selection.configs.length <= 1
            ? AppColors.textMuted.withValues(alpha: 0.45)
            : AppColors.dangerText,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: compact
          ? Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    ruleLabel,
                    const Spacer(),
                    if (selection.configs.length > 1) removeButton,
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(child: _typeDropdown(config)),
                    const SizedBox(width: 8),
                    Expanded(child: _difficultyDropdown(config)),
                  ],
                ),
                const SizedBox(height: 8),
                _topicCountControl(config, width: double.infinity),
              ],
            )
          : Row(
              children: <Widget>[
                ruleLabel,
                const SizedBox(width: 8),
                Expanded(flex: 4, child: _typeDropdown(config)),
                const SizedBox(width: 8),
                Expanded(flex: 3, child: _difficultyDropdown(config)),
                const SizedBox(width: 8),
                _topicCountControl(config),
                if (selection.configs.length > 1) ...<Widget>[
                  const SizedBox(width: 4),
                  removeButton,
                ],
              ],
            ),
    );
  }

  Widget _typeDropdown(_AiQuestionConfig config) {
    return _smallDropdown<QuestionType>(
      value: config.type,
      items: _supportedTypes,
      label: (QuestionType value) => value.label,
      onChanged: (QuestionType? value) {
        if (value == null) return;
        setState(() => config.type = value);
      },
    );
  }

  Widget _difficultyDropdown(_AiQuestionConfig config) {
    return _smallDropdown<QuestionDifficulty>(
      value: config.difficulty,
      items: QuestionDifficulty.values,
      label: (QuestionDifficulty value) => value.label,
      onChanged: (QuestionDifficulty? value) {
        if (value == null) return;
        setState(() => config.difficulty = value);
      },
    );
  }

  Widget _topicCountControl(
    _AiQuestionConfig config, {
    double width = 142,
  }) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _miniCountButton(Icons.remove_rounded, () {
            setState(() {
              config.count = (config.count - 1).clamp(1, 50).toInt();
            });
          }),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '${config.count}',
                  style: TextStyle(
                    color: AppColors.textTitle,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'questions',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          _miniCountButton(Icons.add_rounded, () {
            if (_totalQuestions >= _maxQuestionsPerRequest) return;
            setState(() {
              config.count = (config.count + 1).clamp(1, 50).toInt();
            });
          }),
        ],
      ),
    );
  }

  void _addQuestionRule(_AiTopicSelection selection) {
    final int remaining = _maxQuestionsPerRequest - _totalQuestions;
    if (remaining <= 0) return;

    final Set<QuestionType> usedTypes = selection.configs
        .map((_AiQuestionConfig config) => config.type)
        .toSet();
    final QuestionType nextType = _supportedTypes.firstWhere(
      (QuestionType type) => !usedTypes.contains(type),
      orElse: () => _supportedTypes.first,
    );

    setState(() {
      selection.configs.add(
        _AiQuestionConfig(
          type: nextType,
          difficulty: QuestionDifficulty.medium,
          count: remaining >= 5 ? 5 : remaining,
        ),
      );
    });
  }


  Widget _buildSummaryPanel({required bool compact}) {
    final List<_AiTopicSelection> selected = _selectedTopics;
    final int total = _totalQuestions;
    final bool overLimit = total > _maxQuestionsPerRequest;

    final Widget selectedList = selected.isEmpty
        ? _inlineNotice(
            icon: Icons.info_outline_rounded,
            text: 'Select at least one topic to build the AI request.',
          )
        : ListView.separated(
            shrinkWrap: compact,
            physics: compact
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(),
            itemCount: selected.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, int index) => _summaryTopicCard(selected[index]),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _sectionTitle(
          'Request summary',
          '${selected.length} topics • $_selectedRuleCount rules',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _summaryTile(
                icon: Icons.account_tree_outlined,
                title: 'Selected topics',
                value: '${selected.length} / ${widget.targets.length}',
              ),
              const SizedBox(height: 12),
              _summaryTile(
                icon: Icons.format_list_numbered_rounded,
                title: 'Total questions',
                value: '$total / $_maxQuestionsPerRequest',
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: (total / _maxQuestionsPerRequest)
                      .clamp(0, 1)
                      .toDouble(),
                  backgroundColor: AppColors.borderSoft,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    overLimit ? AppColors.dangerText : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Topics in this request',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppColors.textTitle,
          ),
        ),
        const SizedBox(height: 9),
        if (compact) selectedList else Expanded(child: selectedList),
        const SizedBox(height: 12),
        _inlineNotice(
          icon: Icons.fact_check_outlined,
          text:
              'AI questions arrive as Pending review. Review them in the workspace, then mark them reviewed to include them in the Excel question bank export.',
        ),
        if (overLimit) ...<Widget>[
          const SizedBox(height: 10),
          _inlineNotice(
            icon: Icons.warning_amber_rounded,
            text:
                'Maximum $_maxQuestionsPerRequest questions per request. Reduce one or more topic counts.',
            danger: true,
          ),
        ],
      ],
    );
  }

  Widget _summaryTopicCard(_AiTopicSelection selection) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                constraints: const BoxConstraints(minWidth: 30),
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${selection.totalQuestions}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _compactTargetLabel(selection.target),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textTitle,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${selection.configs.length} ${selection.configs.length == 1 ? 'question rule' : 'question rules'}',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove topic',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => selection.selected = false),
                icon: Icon(
                  Icons.close_rounded,
                  size: 17,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Divider(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: 7),
          ...selection.configs.map(
            (_AiQuestionConfig config) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: <Widget>[
                  Container(
                    constraints: const BoxConstraints(minWidth: 30),
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBg,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: AppColors.borderSoft),
                    ),
                    child: Text(
                      '${config.count}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${config.type.label} • ${config.difficulty.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogFooter({
    required bool canGenerate,
    required _AiGenerationRequest request,
  }) {
    final String helper = request.topicCount == 0
        ? 'Select at least one topic.'
        : request.totalQuestions > _maxQuestionsPerRequest
            ? 'Reduce the total to $_maxQuestionsPerRequest questions or less.'
            : 'One request will be sent with ${request.topicCount} topic${request.topicCount == 1 ? '' : 's'} and $_selectedRuleCount rule${_selectedRuleCount == 1 ? '' : 's'}.';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: AppColors.borderGray)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              helper,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: canGenerate
                  ? () => Navigator.of(context).pop(request)
                  : null,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text('Generate ${request.totalQuestions}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.fieldDisabledBg,
                disabledForegroundColor: AppColors.textMuted,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String meta) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: AppColors.textTitle,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surfaceBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Text(
            meta,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textTitle,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _smallDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T value) label,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.cardBg,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted,
          ),
          items: items
              .map(
                (T item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    label(item),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textGray,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _miniCountButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.surfaceBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Icon(icon, size: 16, color: AppColors.textGray),
      ),
    );
  }

  Widget _inlineNotice({
    required IconData icon,
    required String text,
    bool danger = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: danger ? AppColors.dangerBg : AppColors.infoBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: danger
              ? AppColors.dangerText.withValues(alpha: 0.22)
              : AppColors.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon,
            size: 18,
            color: danger ? AppColors.dangerText : AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: danger ? AppColors.dangerText : AppColors.textMuted,
                fontWeight: FontWeight.w800,
                fontSize: 12.2,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyTopicsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          widget.targets.isEmpty
              ? 'No topics are available in this workspace.'
              : 'No topics match your search.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _setVisibleTopicsSelected(
    List<_AiTopicSelection> visibleTopics,
    bool selected,
  ) {
    setState(() {
      for (final _AiTopicSelection selection in visibleTopics) {
        selection.selected = selected;
      }
    });
  }

  _AiGenerationRequest _buildRequest() {
    return _AiGenerationRequest(
      topics: _selectedTopics
          .map((_AiTopicSelection selection) => selection.toRequestJson())
          .toList(),
    );
  }
}

add_question_sheet.QuestionAuthoringTarget? _findTarget(
  List<add_question_sheet.QuestionAuthoringTarget> targets,
  int topicId,
) {
  for (final add_question_sheet.QuestionAuthoringTarget target in targets) {
    if (target.topicId == topicId) return target;
  }
  return null;
}

String _compactTargetLabel(add_question_sheet.QuestionAuthoringTarget target) {
  final String topic = _compactText(target.topicName, max: 38);
  if (target.isSubtopic && target.parentTopicName != null) {
    return '${_compactText(target.parentTopicName!, max: 24)} › $topic';
  }
  return topic;
}

String _compactText(String value, {int max = 42}) {
  final String normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= max) return normalized;
  return '${normalized.substring(0, max - 1).trimRight()}…';
}
