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

class _AiGenerationDialog extends StatefulWidget {
  final List<add_question_sheet.QuestionAuthoringTarget> targets;

  const _AiGenerationDialog({required this.targets});

  @override
  State<_AiGenerationDialog> createState() => _AiGenerationDialogState();
}

class _AiGenerationDialogState extends State<_AiGenerationDialog> {
  final List<_AiQuestionConfig> _configs = <_AiQuestionConfig>[
    _AiQuestionConfig(
      type: QuestionType.multipleChoice,
      difficulty: QuestionDifficulty.medium,
      count: 5,
    ),
  ];

  static const int _maxQuestionsPerRequest = 50;
  late int _selectedTargetTopicId;

  add_question_sheet.QuestionAuthoringTarget? get _selectedTarget {
    if (widget.targets.isEmpty) return null;
    return widget.targets.firstWhere(
      (add_question_sheet.QuestionAuthoringTarget target) =>
          target.topicId == _selectedTargetTopicId,
      orElse: () => widget.targets.first,
    );
  }

  int get _configuredTotal => _configs.fold<int>(
        0,
        (int total, _AiQuestionConfig config) => total + config.count,
      );

  @override
  void initState() {
    super.initState();
    _selectedTargetTopicId =
        widget.targets.isNotEmpty ? widget.targets.first.topicId : -1;
  }

  @override
  Widget build(BuildContext context) {
    final add_question_sheet.QuestionAuthoringTarget? selectedTarget =
        _selectedTarget;
    final _AiGenerationRequest request = selectedTarget == null
        ? const _AiGenerationRequest(topics: <Map<String, dynamic>>[])
        : _buildRequest(selectedTarget);
    final int totalQuestions = request.totalQuestions;
    final bool canGenerate = selectedTarget != null &&
        totalQuestions > 0 &&
        totalQuestions <= _maxQuestionsPerRequest;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 760),
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
                final bool compact = constraints.maxWidth < 780;
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
                                  _buildConfigPanel(compact: true),
                                  const SizedBox(height: 16),
                                  _buildSummaryPanel(
                                    selectedTarget: selectedTarget,
                                    totalQuestions: totalQuestions,
                                    compact: true,
                                  ),
                                ],
                              ),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Expanded(
                                  flex: 6,
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(22),
                                    child: _buildConfigPanel(compact: false),
                                  ),
                                ),
                                VerticalDivider(width: 1, color: AppColors.borderGray),
                                Expanded(
                                  flex: 4,
                                  child: Container(
                                    color: AppColors.surfaceBg,
                                    padding: const EdgeInsets.all(22),
                                    child: _buildSummaryPanel(
                                      selectedTarget: selectedTarget,
                                      totalQuestions: totalQuestions,
                                      compact: false,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    _dialogFooter(
                      canGenerate: canGenerate,
                      request: request,
                      totalQuestions: totalQuestions,
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
                  'Pick one topic, choose a preset or customize the rules, then send one clean AI request.',
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

  Widget _buildConfigPanel({required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _sectionTitle(
          '1. Target topic',
          widget.targets.length > 1 ? '${widget.targets.length} available' : 'locked',
        ),
        const SizedBox(height: 10),
        _targetSelector(),
        const SizedBox(height: 18),
        _sectionTitle('2. Quick presets', 'optional'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _presetChip(
              label: '5 MCQ • Medium',
              icon: Icons.checklist_rounded,
              configs: <_AiQuestionConfig>[
                _AiQuestionConfig(
                  type: QuestionType.multipleChoice,
                  difficulty: QuestionDifficulty.medium,
                  count: 5,
                ),
              ],
            ),
            _presetChip(
              label: '3 True/False • Easy',
              icon: Icons.rule_rounded,
              configs: <_AiQuestionConfig>[
                _AiQuestionConfig(
                  type: QuestionType.trueFalse,
                  difficulty: QuestionDifficulty.easy,
                  count: 3,
                ),
              ],
            ),
            _presetChip(
              label: 'Mixed 10',
              icon: Icons.auto_awesome_motion_rounded,
              configs: <_AiQuestionConfig>[
                _AiQuestionConfig(
                  type: QuestionType.multipleChoice,
                  difficulty: QuestionDifficulty.medium,
                  count: 5,
                ),
                _AiQuestionConfig(
                  type: QuestionType.trueFalse,
                  difficulty: QuestionDifficulty.easy,
                  count: 3,
                ),
                _AiQuestionConfig(
                  type: QuestionType.shortAnswer,
                  difficulty: QuestionDifficulty.medium,
                  count: 2,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        _sectionTitle(
          '3. Question rules',
          '${_configs.length} rule${_configs.length == 1 ? '' : 's'}',
        ),
        const SizedBox(height: 10),
        ...List<Widget>.generate(_configs.length, (int index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _configRow(index, compact: compact),
          );
        }),
        OutlinedButton.icon(
          onPressed: _configuredTotal >= _maxQuestionsPerRequest
              ? null
              : () {
                  setState(() {
                    _configs.add(
                      _AiQuestionConfig(
                        type: QuestionType.trueFalse,
                        difficulty: QuestionDifficulty.medium,
                        count: 3,
                      ),
                    );
                  });
                },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add rule'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            disabledForegroundColor: AppColors.textMuted,
            side: BorderSide(color: AppColors.borderSoft),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        if (_configuredTotal > _maxQuestionsPerRequest) ...<Widget>[
          const SizedBox(height: 10),
          _inlineNotice(
            icon: Icons.warning_amber_rounded,
            text: 'Maximum $_maxQuestionsPerRequest questions per AI request. Reduce the count before generating.',
            danger: true,
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryPanel({
    required add_question_sheet.QuestionAuthoringTarget? selectedTarget,
    required int totalQuestions,
    required bool compact,
  }) {
    final bool overLimit = totalQuestions > _maxQuestionsPerRequest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _sectionTitle('Request summary', '$totalQuestions requested'),
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
                icon: Icons.topic_outlined,
                title: 'Topic',
                value: selectedTarget == null
                    ? 'No topic selected'
                    : _compactTargetLabel(selectedTarget),
              ),
              const SizedBox(height: 12),
              _summaryTile(
                icon: Icons.format_list_numbered_rounded,
                title: 'Total questions',
                value: '$totalQuestions / $_maxQuestionsPerRequest',
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: (totalQuestions / _maxQuestionsPerRequest).clamp(0, 1).toDouble(),
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
          'Rules',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppColors.textTitle,
          ),
        ),
        const SizedBox(height: 10),
        if (compact)
          Column(
            children: List<Widget>.generate(_configs.length, (int index) {
              return Padding(
                padding: EdgeInsets.only(bottom: index == _configs.length - 1 ? 0 : 8),
                child: _ruleChip(_configs[index]),
              );
            }),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: _configs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, int index) => _ruleChip(_configs[index]),
            ),
          ),
        const SizedBox(height: 12),
        _inlineNotice(
          icon: Icons.info_outline_rounded,
          text: 'Generated questions are saved directly to the question bank. This workspace only shows the new batch from this visit.',
        ),
      ],
    );
  }

  Widget _dialogFooter({
    required bool canGenerate,
    required _AiGenerationRequest request,
    required int totalQuestions,
  }) {
    final String helper = totalQuestions > _maxQuestionsPerRequest
        ? 'Reduce the count to $_maxQuestionsPerRequest or less.'
        : totalQuestions == 0
            ? 'Add at least one question rule.'
            : 'One request will be sent for the selected topic.';

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
              onPressed: canGenerate ? () => Navigator.of(context).pop(request) : null,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text('Generate $totalQuestions'),
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

  Widget _targetSelector() {
    if (widget.targets.isEmpty) {
      return _emptyTargetCard();
    }

    if (widget.targets.length == 1) {
      return _targetCard(widget.targets.first, selected: true);
    }

    return DropdownButtonFormField<int>(
      initialValue: _selectedTargetTopicId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Selected topic',
        helperText: 'AI will generate questions for this topic only.',
        helperStyle: TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
        labelStyle: TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w800,
        ),
        filled: true,
        fillColor: AppColors.surfaceBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      dropdownColor: AppColors.cardBg,
      items: widget.targets
          .map(
            (add_question_sheet.QuestionAuthoringTarget target) =>
                DropdownMenuItem<int>(
              value: target.topicId,
              child: Text(
                _targetDropdownLabel(target),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (int? value) {
        if (value == null) return;
        setState(() => _selectedTargetTopicId = value);
      },
    );
  }

  String _targetDropdownLabel(add_question_sheet.QuestionAuthoringTarget target) {
    final String parent = target.parentTopicName == null
        ? ''
        : '${_compactText(target.parentTopicName!, max: 28)} › ';
    return '$parent${_compactText(target.topicName, max: 44)}  •  ${_compactText(target.materialName ?? target.moduleName ?? 'Course', max: 26)}';
  }

  Widget _emptyTargetCard() {
    return _inlineNotice(
      icon: Icons.info_outline_rounded,
      text: 'No topic was selected. Close this dialog and choose a topic first.',
    );
  }

  Widget _targetCard(
    add_question_sheet.QuestionAuthoringTarget target, {
    required bool selected,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.primary.withValues(alpha: 0.35) : AppColors.borderGray,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              target.isSubtopic
                  ? Icons.subdirectory_arrow_right_rounded
                  : Icons.topic_outlined,
              size: 17,
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
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  target.subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetChip({
    required String label,
    required IconData icon,
    required List<_AiQuestionConfig> configs,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(label),
      labelStyle: TextStyle(
        color: AppColors.textGray,
        fontWeight: FontWeight.w900,
        fontSize: 12.5,
      ),
      backgroundColor: AppColors.surfaceBg,
      side: BorderSide(color: AppColors.borderSoft),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      onPressed: () => setState(() {
        _configs
          ..clear()
          ..addAll(configs.map((config) => _AiQuestionConfig(
                type: config.type,
                difficulty: config.difficulty,
                count: config.count,
              )));
      }),
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

  Widget _ruleChip(_AiQuestionConfig config) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${config.count}',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${config.type.label} • ${config.difficulty.label}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textGray,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _configRow(int index, {required bool compact}) {
    final _AiQuestionConfig config = _configs[index];
    final Widget typeDropdown = _smallDropdown<QuestionType>(
      value: config.type,
      items: <QuestionType>[
        QuestionType.multipleChoice,
        QuestionType.multiSelect,
        QuestionType.trueFalse,
        QuestionType.shortAnswer,
        QuestionType.essay,
      ],
      label: (QuestionType value) => value.label,
      onChanged: (QuestionType? value) {
        if (value != null) setState(() => config.type = value);
      },
    );
    final Widget difficultyDropdown = _smallDropdown<QuestionDifficulty>(
      value: config.difficulty,
      items: QuestionDifficulty.values,
      label: (QuestionDifficulty value) => value.label,
      onChanged: (QuestionDifficulty? value) {
        if (value != null) setState(() => config.difficulty = value);
      },
    );
    final Widget countControl = _countControl(config);
    final Widget removeButton = _configs.length > 1
        ? IconButton(
            tooltip: 'Remove rule',
            onPressed: () => setState(() => _configs.removeAt(index)),
            icon: Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.dangerText),
          )
        : const SizedBox(width: 40);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: compact
          ? Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: typeDropdown),
                    const SizedBox(width: 10),
                    removeButton,
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(child: difficultyDropdown),
                    const SizedBox(width: 10),
                    countControl,
                  ],
                ),
              ],
            )
          : Row(
              children: <Widget>[
                Expanded(flex: 3, child: typeDropdown),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: difficultyDropdown),
                const SizedBox(width: 10),
                countControl,
                removeButton,
              ],
            ),
    );
  }

  Widget _countControl(_AiQuestionConfig config) {
    return SizedBox(
      width: 118,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          _miniCountButton(Icons.remove_rounded, () {
            setState(() => config.count = (config.count - 1).clamp(1, 50).toInt());
          }),
          Expanded(
            child: Text(
              '${config.count}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.textTitle,
                fontSize: 13.5,
              ),
            ),
          ),
          _miniCountButton(Icons.add_rounded, () {
            setState(() => config.count = (config.count + 1).clamp(1, 50).toInt());
          }),
        ],
      ),
    );
  }

  Widget _smallDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T value) label,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 38,
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
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
          items: items
              .map((T item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      label(item),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ),)
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
          color: AppColors.cardBg,
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

  _AiGenerationRequest _buildRequest(
    add_question_sheet.QuestionAuthoringTarget target,
  ) {
    return _AiGenerationRequest(
      topics: <Map<String, dynamic>>[
        <String, dynamic>{
          'topic_id': target.topicId,
          'question_configs': _configs.map((config) => config.toJson()).toList(),
        },
      ],
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