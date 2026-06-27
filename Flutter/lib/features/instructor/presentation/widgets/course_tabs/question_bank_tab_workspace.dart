part of 'question_bank_tab.dart';

class _QuestionBankHeader extends StatelessWidget {
  final bool loading;
  final bool canCreateExam;
  final int totalQuestionsCount;
  final int visibleQuestionsCount;
  final int examReadyCount;
  final VoidCallback onRefresh;
  final VoidCallback onGenerateQuestions;
  final VoidCallback onCreateExam;

  const _QuestionBankHeader({
    required this.loading,
    required this.canCreateExam,
    required this.totalQuestionsCount,
    required this.visibleQuestionsCount,
    required this.examReadyCount,
    required this.onRefresh,
    required this.onGenerateQuestions,
    required this.onCreateExam,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF145CCB), Color(0xFF137FEC), Color(0xFF22C1F1)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: loading ? null : onGenerateQuestions,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.white.withOpacity(0.45),
                  disabledForegroundColor: AppColors.primary.withOpacity(0.45),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Generate Questions'),
              ),
              OutlinedButton.icon(
                onPressed: loading ? null : onRefresh,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white.withOpacity(0.5),
                  side: BorderSide(color: Colors.white.withOpacity(0.35)),
                  backgroundColor: Colors.white.withOpacity(0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh'),
              ),
              FilledButton.icon(
                onPressed: canCreateExam ? onCreateExam : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.white.withOpacity(0.45),
                  disabledForegroundColor: AppColors.primary.withOpacity(0.45),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                label: const Text('Create Exam'),
              ),
            ],
          );

          final stats = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _HeaderCounter(label: 'Total questions', value: totalQuestionsCount),
              _HeaderCounter(label: 'Visible', value: visibleQuestionsCount),
              _HeaderCounter(label: 'Exam-ready', value: examReadyCount),
            ],
          );

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Text(
                  'Question bank',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Assessment Library',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Search, inspect, edit, and assemble saved questions without leaving the course workspace.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.84),
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: 18),
                stats,
                const SizedBox(height: 10),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: copy),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  stats,
                  const SizedBox(height: 10),
                  actions,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}


class _HeaderCounter extends StatelessWidget {
  final String label;
  final int value;

  const _HeaderCounter({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 11.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}


class _QuestionBankWorkspace extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<QuestionModel> questions;
  final int allQuestionsCount;
  final int filteredQuestionsCount;
  final int pageStartIndex;
  final int pageIndex;
  final int pageSize;
  final int totalPages;
  final String? selectedQuestionId;
  final TextEditingController searchController;
  final int? filterModuleId;
  final int? filterMaterialId;
  final int? filterTopicId;
  final int? filterOutcomeId;
  final QuestionDifficulty? filterDiff;
  final QuestionType? filterType;
  final QuestionSource? filterSource;
  final bool? filterUsed;
  final List<ModuleItem> modules;
  final List<_TopicTarget> topicTargets;
  final Map<int, _TopicTarget> topicTargetByTopicId;
  final List<QuestionModel> allQuestions;
  final List<LearningOutcome> courseOutcomes;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<QuestionModel> onSelectQuestion;
  final ValueChanged<int?> onModuleChanged;
  final ValueChanged<int?> onMaterialChanged;
  final ValueChanged<int?> onTopicChanged;
  final ValueChanged<int?> onOutcomeChanged;
  final ValueChanged<QuestionDifficulty?> onDifficultyChanged;
  final ValueChanged<QuestionType?> onTypeChanged;
  final ValueChanged<QuestionSource?> onSourceChanged;
  final ValueChanged<bool?> onUsageChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onRetry;
  final void Function(QuestionModel question, List<_TopicTarget> topicTargets) onEditQuestion;
  final VoidCallback onDeleteUnavailable;

  const _QuestionBankWorkspace({
    required this.loading,
    required this.error,
    required this.questions,
    required this.allQuestionsCount,
    required this.filteredQuestionsCount,
    required this.pageStartIndex,
    required this.pageIndex,
    required this.pageSize,
    required this.totalPages,
    required this.selectedQuestionId,
    required this.searchController,
    required this.filterModuleId,
    required this.filterMaterialId,
    required this.filterTopicId,
    required this.filterOutcomeId,
    required this.filterDiff,
    required this.filterType,
    required this.filterSource,
    required this.filterUsed,
    required this.modules,
    required this.topicTargets,
    required this.topicTargetByTopicId,
    required this.allQuestions,
    required this.courseOutcomes,
    required this.onSearchChanged,
    required this.onSelectQuestion,
    required this.onModuleChanged,
    required this.onMaterialChanged,
    required this.onTopicChanged,
    required this.onOutcomeChanged,
    required this.onDifficultyChanged,
    required this.onTypeChanged,
    required this.onSourceChanged,
    required this.onUsageChanged,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    required this.onClearFilters,
    required this.onRetry,
    required this.onEditQuestion,
    required this.onDeleteUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = searchController.text.trim().isNotEmpty ||
        filterOutcomeId != null ||
        filterType != null;

    Widget body;
    if (loading) {
      body = const _QuestionBankSkeleton();
    } else if (error != null) {
      body = SizedBox(height: 360, child: _QuestionBankError(message: error!, onRetry: onRetry));
    } else if (questions.isEmpty) {
      body = SizedBox(height: 360, child: _QuestionBankEmpty(hasQuestions: allQuestionsCount > 0));
    } else {
      body = RepaintBoundary(
        child: _QuestionRows(
          questions: questions,
          topicTargetByTopicId: topicTargetByTopicId,
          selectedQuestionId: selectedQuestionId,
          pageStartIndex: pageStartIndex,
          onSelectQuestion: onSelectQuestion,
          onEditQuestion: (question) => onEditQuestion(question, topicTargets),
          onDeleteUnavailable: onDeleteUnavailable,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuestionBankToolbar(
          searchController: searchController,
          filterModuleId: filterModuleId,
          filterDiff: filterDiff,
          filterType: filterType,
          filterSource: filterSource,
          filterUsed: filterUsed,
          filterMaterialId: filterMaterialId,
          filterTopicId: filterTopicId,
          filterOutcomeId: filterOutcomeId,
          modules: modules,
          topicTargets: topicTargets,
          allQuestions: allQuestions,
          courseOutcomes: courseOutcomes,
          hasFilters: hasFilters,
          resultCount: filteredQuestionsCount,
          totalCount: allQuestionsCount,
          onSearchChanged: onSearchChanged,
          onModuleChanged: onModuleChanged,
          onMaterialChanged: onMaterialChanged,
          onTopicChanged: onTopicChanged,
          onOutcomeChanged: onOutcomeChanged,
          onDifficultyChanged: onDifficultyChanged,
          onTypeChanged: onTypeChanged,
          onSourceChanged: onSourceChanged,
          onUsageChanged: onUsageChanged,
          onClearFilters: onClearFilters,
        ),
        const SizedBox(height: 12),
        _QuestionBankTableCard(
          body: body,
          loading: loading,
          error: error,
          allQuestionsCount: allQuestionsCount,
          pageIndex: pageIndex,
          pageSize: pageSize,
          totalPages: totalPages,
          resultCount: filteredQuestionsCount,
          pageCount: questions.length,
          pageStartIndex: pageStartIndex,
          onPageChanged: onPageChanged,
          onPageSizeChanged: onPageSizeChanged,
        ),
      ],
    );
  }
}


class _QuestionBankTableCard extends StatelessWidget {
  final Widget body;
  final bool loading;
  final String? error;
  final int allQuestionsCount;
  final int pageIndex;
  final int pageSize;
  final int totalPages;
  final int resultCount;
  final int pageCount;
  final int pageStartIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  const _QuestionBankTableCard({
    required this.body,
    required this.loading,
    required this.error,
    required this.allQuestionsCount,
    required this.pageIndex,
    required this.pageSize,
    required this.totalPages,
    required this.resultCount,
    required this.pageCount,
    required this.pageStartIndex,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowThin,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            body,
            if (!loading && error == null && allQuestionsCount > 0)
              _QuestionBankPagination(
                pageIndex: pageIndex,
                pageSize: pageSize,
                totalPages: totalPages,
                resultCount: resultCount,
                pageCount: pageCount,
                pageStartIndex: pageStartIndex,
                onPageChanged: onPageChanged,
                onPageSizeChanged: onPageSizeChanged,
              ),
          ],
        ),
      ),
    );
  }
}
class _QuestionBankToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final int? filterModuleId;
  final int? filterMaterialId;
  final int? filterTopicId;
  final int? filterOutcomeId;
  final QuestionDifficulty? filterDiff;
  final QuestionType? filterType;
  final QuestionSource? filterSource;
  final bool? filterUsed;
  final List<ModuleItem> modules;
  final List<_TopicTarget> topicTargets;
  final List<QuestionModel> allQuestions;
  final List<LearningOutcome> courseOutcomes;
  final bool hasFilters;
  final int resultCount;
  final int totalCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int?> onModuleChanged;
  final ValueChanged<int?> onMaterialChanged;
  final ValueChanged<int?> onTopicChanged;
  final ValueChanged<int?> onOutcomeChanged;
  final ValueChanged<QuestionDifficulty?> onDifficultyChanged;
  final ValueChanged<QuestionType?> onTypeChanged;
  final ValueChanged<QuestionSource?> onSourceChanged;
  final ValueChanged<bool?> onUsageChanged;
  final VoidCallback onClearFilters;

  const _QuestionBankToolbar({
    required this.searchController,
    required this.filterModuleId,
    required this.filterMaterialId,
    required this.filterTopicId,
    required this.filterOutcomeId,
    required this.filterDiff,
    required this.filterType,
    required this.filterSource,
    required this.filterUsed,
    required this.modules,
    required this.topicTargets,
    required this.allQuestions,
    required this.courseOutcomes,
    required this.hasFilters,
    required this.resultCount,
    required this.totalCount,
    required this.onSearchChanged,
    required this.onModuleChanged,
    required this.onMaterialChanged,
    required this.onTopicChanged,
    required this.onOutcomeChanged,
    required this.onDifficultyChanged,
    required this.onTypeChanged,
    required this.onSourceChanged,
    required this.onUsageChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final outcomeOptions = _learningOutcomeSetupOptions(allQuestions, courseOutcomes);
    final outcomeValue = _selectedOutcomeFilterLabel(outcomeOptions, filterOutcomeId);
    final typeValue = filterType?.label ?? 'All types';

    final outcomeItems = <String>['All LOs', ...outcomeOptions.map((option) => option.label)];
    const typeItems = <String>[
      'All types',
      'Multiple Choice',
      'Multi-Select',
      'True / False',
      'Short Answer',
      'Essay',
      'Fill in the Blank',
      'Numeric',
      'Code',
    ];

    Widget dropdown({
      required double width,
      required String value,
      required List<String> items,
      required ValueChanged<String> onChanged,
    }) {
      return FigmaUmDropdown40(
        width: width,
        value: value,
        items: items,
        onChanged: onChanged,
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowThin,
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fieldWidth = constraints.maxWidth >= 1180 ? 250.0 : 220.0;
          final clearWidth = hasFilters ? 78.0 : 0.0;
          final fixedWidth = fieldWidth + fieldWidth + 88 + clearWidth + (hasFilters ? 40 : 30);
          final minSearchWidth = constraints.maxWidth >= 900 ? 360.0 : 280.0;
          final rowWidth = constraints.maxWidth < fixedWidth + minSearchWidth
              ? fixedWidth + minSearchWidth
              : constraints.maxWidth;

          final filtersRow = SizedBox(
            width: rowWidth,
            child: Row(
              children: [
                Expanded(
                  child: FigmaUmSearch40(
                    controller: searchController,
                    hint: 'Search question, topic, LO, tag...',
                    onChanged: onSearchChanged,
                  ),
                ),
                const SizedBox(width: 10),
                dropdown(
                  width: fieldWidth,
                  value: outcomeValue,
                  items: outcomeItems,
                  onChanged: (value) {
                    if (value == 'All LOs') {
                      onOutcomeChanged(null);
                      return;
                    }
                    final option = outcomeOptions.cast<_FilterOption?>().firstWhere(
                          (item) => item != null && item.label == value,
                          orElse: () => null,
                        );
                    onOutcomeChanged(option?.id);
                  },
                ),
                const SizedBox(width: 10),
                dropdown(
                  width: fieldWidth,
                  value: typeValue,
                  items: typeItems,
                  onChanged: (value) => onTypeChanged(_typeFromLabel(value)),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 88,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.headerBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '$resultCount / $totalCount',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (hasFilters) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 78,
                    height: 40,
                    child: TextButton.icon(
                      onPressed: onClearFilters,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );

          if (rowWidth == constraints.maxWidth) return filtersRow;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: filtersRow,
          );
        },
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  final String label;
  final double width;
  final Widget child;

  const _FilterField({
    required this.label,
    required this.width,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10.8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.35,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}





class _QuestionTableHeader extends StatelessWidget {
  const _QuestionTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 96, child: _HeaderCell('#')),
          Expanded(flex: 50, child: _HeaderCell('Question')),
          SizedBox(width: 24),
          Expanded(flex: 34, child: _HeaderCell('Topic')),
          SizedBox(width: 22),
          SizedBox(width: 150, child: _HeaderCell('Type')),
          SizedBox(width: 16),
          SizedBox(width: 88, child: _HeaderCell('Actions')),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;

  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    );
  }
}
class _QuestionRows extends StatelessWidget {
  final List<QuestionModel> questions;
  final Map<int, _TopicTarget> topicTargetByTopicId;
  final String? selectedQuestionId;
  final int pageStartIndex;
  final ValueChanged<QuestionModel> onSelectQuestion;
  final ValueChanged<QuestionModel> onEditQuestion;
  final VoidCallback onDeleteUnavailable;

  const _QuestionRows({
    required this.questions,
    required this.topicTargetByTopicId,
    required this.selectedQuestionId,
    required this.pageStartIndex,
    required this.onSelectQuestion,
    required this.onEditQuestion,
    required this.onDeleteUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _QuestionTableHeader(),
        for (var i = 0; i < questions.length; i++)
          _QuestionRow(
            index: pageStartIndex + i,
            question: questions[i],
            topicTarget: questions[i].topicId == null ? null : topicTargetByTopicId[questions[i].topicId],
            selected: selectedQuestionId == questions[i].id,
            isLast: i == questions.length - 1,
            onTap: () => onSelectQuestion(questions[i]),
            onEdit: () => onEditQuestion(questions[i]),
            onDeleteUnavailable: onDeleteUnavailable,
          ),
      ],
    );
  }
}
class _QuestionRow extends StatelessWidget {
  final int index;
  final QuestionModel question;
  final _TopicTarget? topicTarget;
  final bool selected;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDeleteUnavailable;

  const _QuestionRow({
    required this.index,
    required this.question,
    required this.topicTarget,
    required this.selected,
    required this.isLast,
    required this.onTap,
    required this.onEdit,
    required this.onDeleteUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    final q = question;
    final topic = _topicPathFromTarget(topicTarget, q);

    final rowColor = index.isEven ? AppColors.cardBg : AppColors.surfaceBg.withOpacity(0.45);

    return Material(
      color: rowColor,
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
              bottom: isLast ? BorderSide.none : BorderSide(color: AppColors.border),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                child: Align(
                  alignment: Alignment.center,
                  child: _QuestionNumber(index: index, selected: selected),
                ),
              ),
              Expanded(
                flex: 50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      q.text.replaceAll('\n', ' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 13.6,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _QuestionMiniPill(icon: Icons.bolt_rounded, label: _sourceLabel(q.source)),
                        _QuestionMiniPill(icon: Icons.insights_rounded, label: _usageLabel(q.usageCount)),
                        if (q.learningOutcomes.isNotEmpty)
                          _QuestionMiniPill(
                            icon: Icons.track_changes_rounded,
                            label: '${q.learningOutcomes.length} LO${q.learningOutcomes.length == 1 ? '' : 's'}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 34,
                child: Text(
                  topic,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textTitle,
                    fontSize: 12.4,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 22),
              SizedBox(
                width: 150,
                child: _SoftStatusPill(label: q.typeLabel, icon: Icons.quiz_outlined),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 88,
                child: _RowActions(
                  onEdit: onEdit,
                  onDeleteUnavailable: onDeleteUnavailable,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionMiniPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuestionMiniPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textHint),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftStatusPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SoftStatusPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textHint),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textTitle,
                fontSize: 11.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyPill extends StatelessWidget {
  final QuestionDifficulty difficulty;

  const _DifficultyPill({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (difficulty) {
      case QuestionDifficulty.easy:
        color = AppColors.successText;
        break;
      case QuestionDifficulty.medium:
        color = AppColors.warningText;
        break;
      case QuestionDifficulty.hard:
        color = AppColors.dangerText;
        break;
    }
    return Container(
      height: 30,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        difficulty.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11.2,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDeleteUnavailable;

  const _RowActions({required this.onEdit, required this.onDeleteUnavailable});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Edit question',
          child: IconButton(
            visualDensity: VisualDensity.compact,
            splashRadius: 18,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
          ),
        ),
        Tooltip(
          message: 'Delete is not available in the current backend API',
          child: IconButton(
            visualDensity: VisualDensity.compact,
            splashRadius: 18,
            onPressed: onDeleteUnavailable,
            icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.dangerText),
          ),
        ),
      ],
    );
  }
}

class _QuestionNumber extends StatelessWidget {
  final int index;
  final bool selected;

  const _QuestionNumber({required this.index, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${index + 1}',
        style: TextStyle(
          color: selected ? Colors.white : AppColors.primary,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _QuestionBankPagination extends StatelessWidget {
  final int pageIndex;
  final int pageSize;
  final int totalPages;
  final int resultCount;
  final int pageCount;
  final int pageStartIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  const _QuestionBankPagination({
    required this.pageIndex,
    required this.pageSize,
    required this.totalPages,
    required this.resultCount,
    required this.pageCount,
    required this.pageStartIndex,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final from = resultCount == 0 ? 0 : pageStartIndex + 1;
    final to = resultCount == 0 ? 0 : pageStartIndex + pageCount;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(
            'Showing $from-$to of $resultCount',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          FigmaUmDropdown40(
            width: 104,
            value: '$pageSize / page',
            items: const ['10 / page', '20 / page'],
            onChanged: (value) => onPageSizeChanged(value.startsWith('20') ? 20 : 10),
          ),
          const SizedBox(width: 8),
          _PagerButton(
            icon: Icons.chevron_left_rounded,
            enabled: pageIndex > 0,
            onTap: () => onPageChanged(pageIndex - 1),
          ),
          const SizedBox(width: 6),
          Text(
            '${pageIndex + 1} / $totalPages',
            style: TextStyle(color: AppColors.textTitle, fontSize: 12, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 6),
          _PagerButton(
            icon: Icons.chevron_right_rounded,
            enabled: pageIndex + 1 < totalPages,
            onTap: () => onPageChanged(pageIndex + 1),
          ),
        ],
      ),
    );
  }
}

class _PagerButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PagerButton({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? AppColors.headerBg : AppColors.surfaceBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 20, color: enabled ? AppColors.textTitle : AppColors.textHint),
      ),
    );
  }
}

