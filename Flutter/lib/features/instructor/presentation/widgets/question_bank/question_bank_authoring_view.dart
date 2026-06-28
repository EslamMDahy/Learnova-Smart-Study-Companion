part of 'question_bank_authoring_flow.dart';

extension _QuestionBankAuthoringFlowView on _QuestionBankAuthoringFlowState {
  Widget _buildAuthoringScaffold(BuildContext context) {
    final List<QuestionModel> visibleQuestions = _draftQuestions;
    final List<QuestionModel> filteredQuestions = _filteredQuestions(visibleQuestions);

    final Widget body = Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 900;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 24,
                compact ? 14 : 22,
                compact ? 14 : 24,
                110,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildHeader(compact: compact),
                      const SizedBox(height: 12),
                      _buildFiltersBar(compact: compact),
                      const SizedBox(height: 12),
                      RepaintBoundary(
                        child: _buildQuestionList(
                          title: 'Questions',
                          subtitle: 'Fresh workspace. Only questions created in this visit appear here; saved questions stay in the main question bank.',
                          emptyTitle: 'No questions yet',
                          emptyBody: 'Add a manual question or generate AI questions for this topic. Previously saved questions are intentionally hidden here.',
                          emptyActionLabel: 'Add question',
                          emptyAction: _targets.isEmpty ? null : _openAddQuestion,
                          questions: filteredQuestions,
                          totalVisible: visibleQuestions.length,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    return _wrapBody(body);
  }

  Widget _wrapBody(Widget child) {
    if (widget.embedded) return child;
    return Dialog.fullscreen(child: child);
  }

  Widget _buildHeader({required bool compact}) {
    final int selectedCount = _selectedDraftQuestions().length;
    final Widget left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _BackToMaterialsButton(
          onPressed: () => unawaited(_requestBackToMaterials()),
          compact: compact,
          onDark: true,
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _headerChip(Icons.school_outlined, widget.course.title),
            _headerChip(Icons.account_tree_outlined, _scopeLabel()),
            _headerChip(Icons.adjust_rounded, '${_targets.length} target${_targets.length == 1 ? '' : 's'}'),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Question Workspace',
          style: TextStyle(
            fontSize: compact ? 27 : 34,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.05,
            letterSpacing: -0.9,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(
            _headerSubtitle(),
            style: TextStyle(
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.45,
            ),
          ),
        ),
      ],
    );

    final Widget right = SizedBox(
      width: compact ? double.infinity : 470,
      child: Column(
        crossAxisAlignment:
            compact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: <Widget>[
          Wrap(
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _headerStat('${_draftQuestions.length}', 'Questions'),
              _headerStat('${_aiDrafts().length}', 'AI'),
              _headerStat('$selectedCount', 'Review'),
            ],
          ),
          SizedBox(height: compact ? 18 : 54),
          _buildHeaderActionGroup(compact: compact),
        ],
      ),
    );

    return Container(
      constraints: const BoxConstraints(minHeight: 198),
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[Color(0xFF137FEC), Color(0xFF1D6FE8), Color(0xFF25A7E8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowBlue.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -80,
            bottom: -120,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
          ),
          compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    left,
                    const SizedBox(height: 18),
                    right,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: left),
                    const SizedBox(width: 24),
                    right,
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildHeaderActionGroup({required bool compact}) {
    return Wrap(
      alignment: compact ? WrapAlignment.start : WrapAlignment.end,
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        _headerActionButton(
          icon: Icons.add_rounded,
          label: 'Add question',
          onPressed: _targets.isEmpty ? null : _openAddQuestion,
          filled: true,
        ),
        _headerActionButton(
          icon: Icons.auto_awesome_rounded,
          label: _aiPolling ? 'Generating…' : 'Generate with AI',
          onPressed: _targets.isEmpty || _aiPolling ? null : _handleGeneratePressed,
        ),
      ],
    );
  }




  Widget _headerChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String value, String label) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.19)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool filled = false,
  }) {
    final Color bg = filled ? Colors.white : Colors.white.withValues(alpha: 0.13);
    final Color fg = filled ? AppColors.primary : Colors.white;
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.10),
          foregroundColor: fg,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
            side: BorderSide(color: Colors.white.withValues(alpha: filled ? 0 : 0.18)),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }





  Widget _buildFiltersBar({required bool compact}) {
    final List<String> difficultyItems = <String>[
      'Any Difficulty',
      QuestionDifficulty.easy.label,
      QuestionDifficulty.medium.label,
      QuestionDifficulty.hard.label,
    ];
    final List<String> typeItems = <String>[
      'All Types',
      QuestionType.multipleChoice.label,
      QuestionType.multiSelect.label,
      QuestionType.trueFalse.label,
      QuestionType.shortAnswer.label,
      QuestionType.essay.label,
    ];
    final List<String> sourceItems = <String>[
      'All Sources',
      QuestionSource.manual.label,
      QuestionSource.aiGenerated.label,
      QuestionSource.nativeExtraction.label,
    ];

    final Widget search = FigmaUmSearch40(
      controller: _searchCtrl,
      hint: 'Search by question, topic, or tag...',
      onChanged: (_) => _runStateUpdate(() {}),
    );

    final Widget topicFilter = _TopicTreeFilterButton(
      selectedTopicId: _selectedTopicFilterId,
      targets: _targets,
      onChanged: (int? id) {
        _runStateUpdate(() => _selectedTopicFilterId = id);
      },
    );

    final Widget difficultyFilter = FigmaUmDropdown40(
      width: compact ? 170 : 158,
      value: _selectedDifficultyFilter,
      items: difficultyItems,
      onChanged: (String value) => _runStateUpdate(() => _selectedDifficultyFilter = value),
    );

    final Widget typeFilter = FigmaUmDropdown40(
      width: compact ? 148 : 136,
      value: _selectedTypeFilter,
      items: typeItems,
      onChanged: (String value) => _runStateUpdate(() => _selectedTypeFilter = value),
    );

    final Widget sourceFilter = FigmaUmDropdown40(
      width: compact ? 150 : 136,
      value: _selectedSourceFilter,
      items: sourceItems,
      onChanged: (String value) => _runStateUpdate(() => _selectedSourceFilter = value),
    );

    return Container(
      height: compact ? null : 56,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 12 : 0),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                search,
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      SizedBox(width: 220, child: topicFilter),
                      const SizedBox(width: 10),
                      difficultyFilter,
                      const SizedBox(width: 10),
                      typeFilter,
                      const SizedBox(width: 10),
                      sourceFilter,
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: <Widget>[
                Expanded(child: search),
                const SizedBox(width: 12),
                SizedBox(width: 230, child: topicFilter),
                const SizedBox(width: 10),
                difficultyFilter,
                const SizedBox(width: 10),
                typeFilter,
                const SizedBox(width: 10),
                sourceFilter,
              ],
            ),
    );
  }


  Widget _buildQuestionList({
    required String title,
    required String subtitle,
    required String emptyTitle,
    required String emptyBody,
    String? emptyActionLabel,
    VoidCallback? emptyAction,
    required List<QuestionModel> questions,
    required int totalVisible,
    bool reviewMode = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    reviewMode ? Icons.fact_check_outlined : Icons.view_agenda_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textTitle,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_draftQuestions.isNotEmpty && !reviewMode) ...<Widget>[
                  OutlinedButton.icon(
                    onPressed: _aiPolling ? null : _clearQuestionTable,
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: const Text('Clear table'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textTitle,
                      disabledForegroundColor: AppColors.textMuted,
                      side: BorderSide(color: AppColors.borderGray),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                _countPill('$totalVisible total'),
                const SizedBox(width: 8),
                _countPill('${questions.length} shown'),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderGray),
          if (_aiPolling)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.badgeBlueBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.badgeBlueBorder),
                ),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Waiting for the AI callback. The selected topic questions are checked every 10 seconds.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.badgeBlueFg,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _stopAiPolling,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        'Stop watching',
                        style: TextStyle(fontSize: 12, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (questions.isEmpty)
            SizedBox(
              height: 330,
              child: _buildEmptyState(
                title: emptyTitle,
                body: emptyBody,
                actionLabel: emptyActionLabel,
                action: emptyAction,
              ),
            )
          else
            _buildQuestionTable(
              questions: questions,
              reviewMode: reviewMode,
            ),
        ],
      ),
    );
  }




  bool _isCorrectOption(QuestionModel question, QuestionOption option) {
    if (option.isCorrect) return true;
    if (question.correctOptionId != null && option.id == question.correctOptionId) return true;
    final String expected = (question.expectedAnswer ?? '').trim();
    if (expected.isEmpty) return false;
    final List<String> parts = expected.split(',').map((String value) => value.trim()).toList();
    return parts.contains(option.id) || parts.contains(option.text);
  }

  String _answerSummary(QuestionModel question) {
    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.multiSelect:
        final List<QuestionOption> correctOptions = question.options.where((QuestionOption option) => _isCorrectOption(question, option)).toList();
        if (correctOptions.isNotEmpty) return correctOptions.map((QuestionOption option) => option.text).join(', ');
        final String answerFallback = (question.expectedAnswer ?? question.correctOptionId ?? '').trim();
        return answerFallback.isEmpty ? 'No answer set' : answerFallback;
      case QuestionType.trueFalse:
        if (question.correctBool != null) return question.correctBool! ? 'True' : 'False';
        final String tfFallback = (question.expectedAnswer ?? '').trim();
        return tfFallback.isEmpty ? 'No answer set' : tfFallback;
      case QuestionType.shortAnswer:
      case QuestionType.essay:
      case QuestionType.fillInTheBlank:
      case QuestionType.numeric:
      case QuestionType.code:
        final String textFallback = (question.expectedAnswer ?? question.sampleAnswer ?? '').trim();
        return textFallback.isEmpty ? 'No answer set' : textFallback;
    }
  }

  Widget _buildQuestionTable({
    required List<QuestionModel> questions,
    required bool reviewMode,
  }) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: <Widget>[
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              color: AppColors.surfaceBg,
              child: Row(
                children: <Widget>[
                  _tableHeader('#', width: 50),
                  _tableHeader('Question', flex: 5),
                  _tableHeader('Topic', flex: 3),
                  _tableHeader('Answer', flex: 3),
                  _tableHeader('Type', width: 116),
                  _tableHeader('Difficulty', width: 104),
                  _tableHeader('Source', width: 88),
                  SizedBox(
                    width: 82,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('Actions', style: _tableHeaderStyle()),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.borderGray),
            ...List<Widget>.generate(questions.length, (int index) {
              final QuestionModel question = questions[index];
              return Column(
                children: <Widget>[
                  _buildQuestionTableRow(
                    question,
                    index: index + 1,
                    selected: _selectedQuestionIds.contains(question.id),
                    reviewMode: reviewMode,
                  ),
                  if (index != questions.length - 1)
                    Divider(height: 1, color: AppColors.borderGray.withValues(alpha: 0.75)),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(String label, {int? flex, double? width}) {
    final Widget child = Text(label, overflow: TextOverflow.ellipsis, style: _tableHeaderStyle());
    if (width != null) return SizedBox(width: width, child: child);
    return Expanded(flex: flex ?? 1, child: child);
  }

  TextStyle _tableHeaderStyle() {
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.35,
      color: AppColors.textMuted,
    );
  }

  Widget _questionIndexBadge(int index, {required bool selected}) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: selected ? AppColors.primary.withValues(alpha: 0.35) : AppColors.borderGray,
        ),
      ),
      child: Text(
        '$index',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: selected ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildQuestionTableRow(
    QuestionModel question, {
    required int index,
    required bool selected,
    required bool reviewMode,
  }) {
    final bool isDraft = _draftQuestions.any((QuestionModel item) => item.id == question.id);
    return Material(
      color: selected ? AppColors.selectedBg.withValues(alpha: 0.55) : AppColors.cardBg,
      child: InkWell(
        onTap: isDraft ? () => _openEditDraftQuestion(question) : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 50,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _questionIndexBadge(index, selected: selected),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    question.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.2,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                      color: AppColors.textTitle,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    _questionTargetLabel(question),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.2,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    _answerSummary(question),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.2,
                      fontWeight: FontWeight.w800,
                      color: AppColors.successText,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 116, child: Align(alignment: Alignment.centerLeft, child: _tablePill(question.typeLabel))),
              SizedBox(width: 104, child: Align(alignment: Alignment.centerLeft, child: _difficultyPill(question.difficultyLabel))),
              SizedBox(width: 88, child: Align(alignment: Alignment.centerLeft, child: _sourcePill(question.source))),
              SizedBox(
                width: 82,
                child: isDraft
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          _iconAction(
                            icon: Icons.visibility_outlined,
                            tooltip: 'View and edit',
                            compact: true,
                            onTap: () => _openEditDraftQuestion(question),
                          ),
                          const SizedBox(width: 6),
                          _iconAction(
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'Remove from workspace',
                            danger: true,
                            compact: true,
                            onTap: () => _deleteDraftQuestion(question),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String body,
    String? actionLabel,
    VoidCallback? action,
  }) {
    return Center(
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFF137FEC), Color(0xFF4F46E5)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.playlist_add_check_circle_outlined, color: Colors.white),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textTitle,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (actionLabel != null && action != null) ...<Widget>[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: action,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}
