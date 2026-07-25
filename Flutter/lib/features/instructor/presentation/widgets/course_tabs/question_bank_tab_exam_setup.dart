part of 'question_bank_tab.dart';

enum _ExamScopeMode { topics, outcomes }

class _ExamStartConfig {
  final ExamTemplateModel template;
  final String? title;
  final int? moduleId;
  final int? materialId;
  final Set<int> topicIds;
  final Set<int> outcomeIds;

  const _ExamStartConfig({
    required this.template,
    this.title,
    this.moduleId,
    this.materialId,
    this.topicIds = const <int>{},
    this.outcomeIds = const <int>{},
  });
}

class _GeneratedExamResult {
  final ExamModel exam;
  final ExamTemplateModel template;

  const _GeneratedExamResult({
    required this.exam,
    required this.template,
  });
}

class _CreateExamStartDialog extends ConsumerStatefulWidget {
  final MyCourseItem course;
  final List<ExamTemplateModel> templates;
  final Future<List<ExamTemplateModel>>? templatesFuture;
  final List<ModuleItem> modules;
  final List<_TopicTarget> topicTargets;
  final List<LearningOutcome> outcomes;
  final List<QuestionModel> questions;
  const _CreateExamStartDialog({
    required this.course,
    required this.templates,
    this.templatesFuture,
    required this.modules,
    required this.topicTargets,
    required this.outcomes,
    required this.questions,
  });

  @override
  ConsumerState<_CreateExamStartDialog> createState() => _CreateExamStartDialogState();
}

class _CreateExamStartDialogState extends ConsumerState<_CreateExamStartDialog> {
  final TextEditingController _titleCtrl = TextEditingController();
  late List<ExamTemplateModel> _templates;
  late ExamTemplateModel _template;
  bool _templatesLoading = false;
  bool _generating = false;
  int _setupStep = 0;
  Map<String, _GenerationDifficultyDraft> _difficultyDrafts = <String, _GenerationDifficultyDraft>{};
  int? _moduleId;
  int? _materialId;
  final Set<int> _topicIds = <int>{};
  final Set<int> _outcomeIds = <int>{};
  bool _dialogTreeRequested = false;
  _ExamScopeMode _scopeMode = _ExamScopeMode.topics;
  String? _error;

  @override
  void initState() {
    super.initState();
    _templates = widget.templates.isNotEmpty
        ? List<ExamTemplateModel>.from(widget.templates)
        : ExamTemplateModel.defaults(widget.course.id);
    _template = _preferredTemplate(_templates);
    _difficultyDrafts = _buildDifficultyDrafts(_template);
    _titleCtrl.text = _defaultExamTitle(_template);
    _loadTemplatesInPlace();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDialogCourseTreeLoaded());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _disposeDifficultyDrafts();
    super.dispose();
  }

  Future<void> _ensureDialogCourseTreeLoaded() async {
    if (_dialogTreeRequested) return;
    _dialogTreeRequested = true;
    try {
      await Future.wait<void>([
        ref
            .read(courseDetailsControllerProvider(widget.course.id).notifier)
            .loadModulesAndAllMaterials(hydrateTopicDetails: false),
        ensureCourseLearningOutcomesLoaded(ref, widget.course.id),
      ]);
    } catch (_) {
      // The dialog can still fall back to question-bank metadata.
    } finally {
      if (mounted) setState(() {});
    }
  }

  bool _isCourseTreeLoading(CourseDetailsState state) {
    return state.modulesLoading ||
        state.materialsLoading.values.any((loading) => loading) ||
        state.topicsLoading.values.any((loading) => loading);
  }

  List<_TopicTarget> _topicTargetsFromCourseState(CourseDetailsState state) {
    final result = <_TopicTarget>[];
    for (final module in state.modules) {
      final materials = state.materials[module.id] ?? const <MaterialItem>[];
      final materialsById = {for (final material in materials) material.id: material};
      final topics = state.topics[module.id] ?? const <TopicItem>[];
      for (final topic in topics) {
        final material = materialsById[topic.materialId];
        if (material == null) continue;
        String? parentTitle;
        if (topic.parentTopicId != null) {
          for (final candidate in topics) {
            if (candidate.id == topic.parentTopicId) {
              parentTitle = candidate.title;
              break;
            }
          }
        }
        result.add(_TopicTarget(
          module: module,
          material: material,
          topic: topic.copyWith(moduleId: module.id),
          parentTopicTitle: parentTitle,
        ));
      }
    }
    result.sort(_compareTopicTargets);
    return result;
  }

  List<_TopicTarget> _topicTargetsFromQuestions(List<QuestionModel> questions) {
    final now = DateTime.fromMillisecondsSinceEpoch(0);
    final modulesById = <int, ModuleItem>{};
    final materialsById = <int, MaterialItem>{};
    final targetsByTopicId = <int, _TopicTarget>{};

    for (final question in questions) {
      final moduleId = question.moduleId;
      final materialId = question.materialId;
      final topicId = question.topicId;
      if (moduleId == null || materialId == null || topicId == null) continue;

      final module = modulesById.putIfAbsent(
        moduleId,
        () => ModuleItem(
          id: moduleId,
          courseId: widget.course.id,
          title: (question.moduleName ?? '').trim().isEmpty
              ? 'Module $moduleId'
              : question.moduleName!.trim(),
          orderIndex: moduleId,
          isPublished: true,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final material = materialsById.putIfAbsent(
        materialId,
        () => MaterialItem(
          id: materialId,
          moduleId: moduleId,
          title: (question.materialName ?? '').trim().isEmpty
              ? 'Material $materialId'
              : question.materialName!.trim(),
          type: 'document',
          status: 'ready',
          uploadedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      targetsByTopicId.putIfAbsent(
        topicId,
        () => _TopicTarget(
          module: module,
          material: material,
          topic: TopicItem(
            id: topicId,
            materialId: materialId,
            title: (question.topicName ?? '').trim().isEmpty
                ? 'Topic $topicId'
                : question.topicName!.trim(),
            orderIndex: topicId,
            createdAt: now,
            updatedAt: now,
            moduleId: moduleId,
          ),
        ),
      );
    }

    final result = targetsByTopicId.values.toList()..sort(_compareTopicTargets);
    return result;
  }

  List<_TopicTarget> _mergeTopicTargets(List<List<_TopicTarget>> groups) {
    final byTopicId = <int, _TopicTarget>{};
    for (final group in groups) {
      for (final target in group) {
        byTopicId.putIfAbsent(target.topic.id, () => target);
      }
    }
    final result = byTopicId.values.toList()..sort(_compareTopicTargets);
    return result;
  }

  List<ModuleItem> _mergeModules(
    List<ModuleItem> courseStateModules,
    List<ModuleItem> initialModules,
    List<_TopicTarget> targets,
  ) {
    final byId = <int, ModuleItem>{};
    for (final module in courseStateModules) {
      byId[module.id] = module;
    }
    for (final module in initialModules) {
      byId.putIfAbsent(module.id, () => module);
    }
    for (final target in targets) {
      byId.putIfAbsent(target.module.id, () => target.module);
    }
    final result = byId.values.toList()
      ..sort((a, b) {
        final orderCmp = a.orderIndex.compareTo(b.orderIndex);
        if (orderCmp != 0) return orderCmp;
        return _moduleLabel(a).toLowerCase().compareTo(_moduleLabel(b).toLowerCase());
      });
    return result;
  }

  int _compareTopicTargets(_TopicTarget a, _TopicTarget b) {
    final moduleCmp = a.module.orderIndex.compareTo(b.module.orderIndex);
    if (moduleCmp != 0) return moduleCmp;
    final materialCmp = a.material.displayTitle.toLowerCase().compareTo(
          b.material.displayTitle.toLowerCase(),
        );
    if (materialCmp != 0) return materialCmp;
    final topicOrderCmp = a.topic.orderIndex.compareTo(b.topic.orderIndex);
    if (topicOrderCmp != 0) return topicOrderCmp;
    return a.topic.title.toLowerCase().compareTo(b.topic.title.toLowerCase());
  }

  String _defaultExamTitle(ExamTemplateModel template) {
    final base = widget.course.title.trim().isEmpty ? 'Course' : widget.course.title.trim();
    final templateName = template.name.trim().isEmpty ? 'Exam' : template.name.trim();
    return '$base • $templateName';
  }

  void _applyTemplate(ExamTemplateModel template) {
    final previousDefault = _defaultExamTitle(_template);
    final currentTitle = _titleCtrl.text.trim();
    _template = template;
    _disposeDifficultyDrafts();
    _difficultyDrafts = _buildDifficultyDrafts(template);
    if (currentTitle.isEmpty || currentTitle == previousDefault) {
      _titleCtrl.text = _defaultExamTitle(template);
    }
  }

  Map<String, _GenerationDifficultyDraft> _buildDifficultyDrafts(ExamTemplateModel template) {
    final drafts = <String, _GenerationDifficultyDraft>{};
    final sections = _effectiveDistributionSections(template);
    for (var index = 0; index < sections.length; index++) {
      final section = sections[index];
      final orderIndex = section.orderIndex > 0 ? section.orderIndex : index + 1;
      drafts['$orderIndex'] = _GenerationDifficultyDraft(
        sectionLabel: _templateQuestionTypeLabel(section.questionType),
        questionCount: section.questionCount,
      );
    }
    return drafts;
  }

  void _disposeDifficultyDrafts() {
    for (final draft in _difficultyDrafts.values) {
      draft.dispose();
    }
    _difficultyDrafts = <String, _GenerationDifficultyDraft>{};
  }

  String? _difficultyConfigError() {
    final sections = _effectiveDistributionSections(_template);
    for (var index = 0; index < sections.length; index++) {
      final section = sections[index];
      final orderIndex = section.orderIndex > 0 ? section.orderIndex : index + 1;
      final draft = _difficultyDrafts['$orderIndex'];
      if (draft == null) continue;
      if (draft.hasNegativeValue) return '${draft.sectionLabel} difficulty percentages cannot be negative.';
      final total = draft.totalPercent;
      if (total != 100) {
        return '${draft.sectionLabel} difficulty mix must sum to 100%. Current total is $total%.';
      }
    }
    return null;
  }

  Map<String, int> _difficultyPercentagesForSection(ExamTemplateSectionModel section, int index) {
    final orderIndex = section.orderIndex > 0 ? section.orderIndex : index + 1;
    return _difficultyDrafts['$orderIndex']?.percentages ?? const <String, int>{'medium': 100};
  }

  Map<String, int> _requiredDifficultyCountsForSection(ExamTemplateSectionModel section, int index) {
    return _countsFromDifficultyPercentages(section.questionCount, _difficultyPercentagesForSection(section, index));
  }

  Map<String, int> _countsFromDifficultyPercentages(int total, Map<String, int> percentages) {
    if (total <= 0) return const <String, int>{};
    final entries = <MapEntry<String, int>>[];
    for (final key in const ['easy', 'medium', 'hard']) {
      final value = percentages[key] ?? 0;
      if (value > 0) entries.add(MapEntry(key, value));
    }
    if (entries.isEmpty) return <String, int>{'medium': total};

    var assigned = 0;
    final result = <String, int>{};
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final count = i == entries.length - 1 ? total - assigned : (total * entry.value / 100).round();
      if (count > 0) result[entry.key] = count;
      assigned += count;
    }
    return result;
  }

  ExamTemplateModel _preferredTemplate(List<ExamTemplateModel> templates) {
    return templates.firstWhere(
      (item) => !item.isCustom,
      orElse: () => templates.isNotEmpty
          ? templates.first
          : ExamTemplateModel.custom(widget.course.id),
    );
  }

  Future<void> _loadTemplatesInPlace() async {
    final future = widget.templatesFuture;
    if (future == null) return;
    _templatesLoading = true;
    try {
      final loaded = await future;
      if (!mounted) return;
      final nextTemplates = loaded.isNotEmpty ? loaded : ExamTemplateModel.defaults(widget.course.id);
      final currentId = _template.id;
      final stillExists = nextTemplates.any((item) => item.id == currentId);
      setState(() {
        _templates = nextTemplates;
        if (!stillExists || _template.isCustom) {
          _applyTemplate(_preferredTemplate(nextTemplates));
        }
        _templatesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _templatesLoading = false);
    }
  }

  bool get _hasRequiredScope {
    return _scopeMode == _ExamScopeMode.topics ? _topicIds.isNotEmpty : _outcomeIds.isNotEmpty;
  }

  String get _scopeRequiredMessage {
    return _scopeMode == _ExamScopeMode.topics
        ? 'Select at least one topic or subtopic before building the question set.'
        : 'Select at least one learning outcome before building the question set.';
  }

  List<QuestionModel> _matchingQuestions(List<_TopicTarget> topicTargets) {
    if (!_hasRequiredScope) return const <QuestionModel>[];

    final targetByTopicId = {for (final target in topicTargets) target.topic.id: target};
    return widget.questions.where((question) {
      if (question.remoteId == null) return false;
      final target = question.topicId == null ? null : targetByTopicId[question.topicId];
      final moduleId = question.moduleId ?? target?.module.id;
      final materialId = question.materialId ?? target?.material.id;
      final topicId = question.topicId ?? target?.topic.id;

      if (_moduleId != null && moduleId != _moduleId) return false;
      if (_materialId != null && materialId != _materialId) return false;

      if (_scopeMode == _ExamScopeMode.topics) {
        if (topicId == null || !_topicIds.contains(topicId)) return false;
      }

      if (_scopeMode == _ExamScopeMode.outcomes) {
        if (!question.learningOutcomes.any((outcome) => _outcomeIds.contains(outcome.id))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<QuestionModel> _backendGenerationQuestions(List<_TopicTarget> topicTargets) {
    final targetByTopicId = {for (final target in topicTargets) target.topic.id: target};
    return widget.questions.where((question) {
      if (question.remoteId == null) return false;
      final target = question.topicId == null ? null : targetByTopicId[question.topicId];
      final moduleId = question.moduleId ?? target?.module.id;
      final materialId = question.materialId ?? target?.material.id;
      final topicId = question.topicId ?? target?.topic.id;

      if (_moduleId != null && moduleId != _moduleId) return false;
      if (_materialId != null && materialId != _materialId) return false;
      if (_topicIds.isNotEmpty && (topicId == null || !_topicIds.contains(topicId))) return false;

      return true;
    }).toList();
  }

  List<LearningOutcome> _learningOutcomeTreeOptions(
    List<QuestionModel> questions,
    List<LearningOutcome> courseOutcomes,
  ) {
    final byId = <int, LearningOutcome>{};
    for (final outcome in courseOutcomes) {
      if (outcome.id <= 0) continue;
      byId[outcome.id] = outcome;
    }
    for (final question in questions) {
      for (final outcome in question.learningOutcomes) {
        if (outcome.id <= 0) continue;
        byId.putIfAbsent(
          outcome.id,
          () => LearningOutcome(
            id: outcome.id,
            courseId: widget.course.id,
            title: outcome.title.trim().isEmpty ? 'LO ${outcome.id}' : outcome.title.trim(),
          ),
        );
      }
    }
    return assignLearningOutcomeCodes(byId.values.toList(growable: false));
  }

  List<QuestionModel> _eligibleQuestionsForTemplate(List<QuestionModel> matching) {
    final difficulty = _template.preferredDifficulty;
    if (difficulty == null) return matching;
    return matching.where((question) => question.difficulty == difficulty).toList();
  }

  List<_TemplateRequirementGap> _templateTypeRequirementGaps(List<QuestionModel> matching) {
    final activeSections = _template.sections.where((section) => section.questionCount > 0).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    if (activeSections.isEmpty) {
      return matching.length >= _template.questionCount
          ? const <_TemplateRequirementGap>[]
          : [
              _TemplateRequirementGap(
                label: 'Total questions',
                requiredCount: _template.questionCount,
                availableCount: matching.length,
              ),
            ];
    }

    final gaps = <_TemplateRequirementGap>[];
    for (final section in activeSections) {
      final type = parseQuestionType(section.questionType);
      final available = matching.where((question) => question.type == type).length;
      if (available < section.questionCount) {
        gaps.add(_TemplateRequirementGap(
          label: _templateQuestionTypeLabel(section.questionType),
          requiredCount: section.questionCount,
          availableCount: available,
        ));
      }
    }
    return gaps;
  }

  List<_TemplateRequirementGap> _templateRequirementGaps(List<QuestionModel> matching) {
    final activeSections = _effectiveDistributionSections(_template);
    final gaps = <_TemplateRequirementGap>[];
    for (var index = 0; index < activeSections.length; index++) {
      final section = activeSections[index];
      if (section.questionCount <= 0) continue;
      final type = parseQuestionType(section.questionType);
      final difficultyCounts = _requiredDifficultyCountsForSection(section, index);
      if (difficultyCounts.isEmpty) {
        final available = matching.where((question) => question.type == type).length;
        if (available < section.questionCount) {
          gaps.add(_TemplateRequirementGap(
            label: _templateQuestionTypeLabel(section.questionType),
            requiredCount: section.questionCount,
            availableCount: available,
          ));
        }
        continue;
      }

      for (final entry in difficultyCounts.entries) {
        final difficulty = parseQuestionDifficulty(entry.key);
        final available = matching.where((question) => question.type == type && question.difficulty == difficulty).length;
        if (available < entry.value) {
          gaps.add(_TemplateRequirementGap(
            label: '${_templateQuestionTypeLabel(section.questionType)} ${_difficultyLabelFromKey(entry.key)}',
            requiredCount: entry.value,
            availableCount: available,
          ));
        }
      }
    }
    return gaps;
  }

  String _gapsMessage(List<_TemplateRequirementGap> gaps) {
    return 'Not enough questions for this template distribution: ${gaps.map((gap) => '${gap.label} requires ${gap.requiredCount}, found ${gap.availableCount}').join('; ')}.';
  }

  String? _validatedExamTitle() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Enter an exam title before continuing.');
      return null;
    }
    return title;
  }

  List<_TemplateRequirementGap>? _validateScopeAndDistribution({
    required bool backendGenerate,
    required List<_TopicTarget> topicTargets,
  }) {
    if (backendGenerate) {
      if (_scopeMode != _ExamScopeMode.topics) {
        setState(() => _error = 'Backend generation uses topic/subtopic scope. Switch to Topics or use Build manually for learning outcomes.');
        return null;
      }

      final difficultyError = _difficultyConfigError();
      if (difficultyError != null) {
        setState(() => _error = difficultyError);
        return null;
      }

      final matching = _backendGenerationQuestions(topicTargets);
      final gaps = _templateRequirementGaps(matching);
      if (gaps.isNotEmpty) {
        setState(() => _error = _gapsMessage(gaps));
        return null;
      }

      return gaps;
    }

    if (!_hasRequiredScope) {
      setState(() => _error = _scopeRequiredMessage);
      return null;
    }

    final matching = _matchingQuestions(topicTargets);
    if (matching.isEmpty) {
      setState(() => _error = 'No saved questions match the selected scope. Choose a different topic/subtopic or learning outcome.');
      return null;
    }

    final gaps = _templateTypeRequirementGaps(matching);
    if (gaps.isNotEmpty) {
      setState(() => _error = _gapsMessage(gaps));
      return null;
    }

    return gaps;
  }

  void _continue(List<_TopicTarget> topicTargets) {
    final title = _validatedExamTitle();
    if (title == null) return;

    if (_hasRequiredScope) {
      final validation = _validateScopeAndDistribution(
        backendGenerate: false,
        topicTargets: topicTargets,
      );
      if (validation == null) return;
    }

    Navigator.of(context).pop(_ExamStartConfig(
      template: _template,
      title: title,
      moduleId: _moduleId,
      materialId: _materialId,
      topicIds: _scopeMode == _ExamScopeMode.topics ? Set<int>.from(_topicIds) : const <int>{},
      outcomeIds: _scopeMode == _ExamScopeMode.outcomes ? Set<int>.from(_outcomeIds) : const <int>{},
    ),);
  }

  void _goToDifficultyStep() {
    final title = _validatedExamTitle();
    if (title == null) return;
    if (_scopeMode != _ExamScopeMode.topics) {
      setState(() => _error = 'Generate Exam uses topic/subtopic scope. Switch to Topics, or use Build manually for learning outcomes.');
      return;
    }
    setState(() {
      _setupStep = 1;
      _error = null;
    });
  }

  void _goBackToSetupStep() {
    if (_generating) return;
    setState(() {
      _setupStep = 0;
      _error = null;
    });
  }

  Map<String, dynamic> _difficultyDistributionForTemplate(
    ExamTemplateModel backendTemplate, {
    ExamTemplateModel? draftTemplate,
  }) {
    final backendSections = _effectiveDistributionSections(backendTemplate);
    final draftSections = _effectiveDistributionSections(draftTemplate ?? backendTemplate);
    final result = <String, dynamic>{};

    for (var index = 0; index < backendSections.length; index++) {
      final backendSection = backendSections[index];
      final draftSection = index < draftSections.length ? draftSections[index] : backendSection;
      final backendOrderIndex = backendSection.orderIndex > 0 ? backendSection.orderIndex : index + 1;
      final draftIndex = draftSections.indexOf(draftSection);
      result['$backendOrderIndex'] = _difficultyPercentagesForSection(
        draftSection,
        draftIndex < 0 ? index : draftIndex,
      );
    }

    if (result.isEmpty) {
      result['1'] = const <String, int>{'easy': 0, 'medium': 100, 'hard': 0};
    }
    return result;
  }

  List<ExamTemplateSectionModel> _effectiveDistributionSections(ExamTemplateModel template) {
    final sections = template.sections.where((section) => section.questionCount > 0).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    if (sections.isNotEmpty) return sections;
    final distributionSections = template.distributionSections;
    if (distributionSections.isNotEmpty) return distributionSections;

    final now = DateTime.fromMillisecondsSinceEpoch(0);
    return [
      ExamTemplateSectionModel(
        title: 'Multiple Choice Questions',
        questionType: 'multiple_choice',
        questionCount: template.questionCount > 0 ? template.questionCount : 1,
        pointsPerQuestion: 1,
        sectionScore: (template.questionCount > 0 ? template.questionCount : 1).toDouble(),
        orderIndex: 1,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  Future<void> _generateExamFromBackend(List<_TopicTarget> topicTargets) async {
    if (_generating) return;
    final title = _validatedExamTitle();
    if (title == null) return;
    final validation = _validateScopeAndDistribution(
      backendGenerate: true,
      topicTargets: topicTargets,
    );
    if (validation == null) return;

    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      final savedTemplate = await ref
          .read(examTemplatesStorageProvider)
          .ensureBackendTemplate(widget.course.id, _template.copyWith(courseId: widget.course.id));
      final templateId = savedTemplate.backendId;
      if (templateId == null) {
        throw const FormatException('Could not save the selected template before generating the exam.');
      }

      final rawTemplate = await ref.read(examsApiProvider).getExamTemplateRaw(
            courseId: widget.course.id,
            templateId: templateId,
          );
      final backendTemplate = ExamTemplateModel.fromJson({
        ...rawTemplate,
        'course_id': widget.course.id,
      });
      final topicIds = _topicIds.toList()..sort();
      final distribution = _difficultyDistributionForTemplate(
        backendTemplate,
        draftTemplate: _template,
      );
      final exam = await ref.read(examsApiProvider).generateExamFromTemplate(
            courseId: widget.course.id,
            templateId: templateId,
            payload: GenerateExamFromTemplatePayload(
              title: title,
              topicIds: topicIds.isEmpty ? null : topicIds,
              sectionDifficultyDistribution: distribution,
            ),
          );

      if (!mounted) return;
      Navigator.of(context).pop(_GeneratedExamResult(exam: exam, template: savedTemplate));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _error = mapApiFailure(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseState = ref.watch(courseDetailsControllerProvider(widget.course.id));
    final liveOutcomes = ref.watch(courseLOProvider(widget.course.id));
    final courseTreeTargets = _topicTargetsFromCourseState(courseState);
    final questionMetadataTargets = _topicTargetsFromQuestions(widget.questions);
    final effectiveTopicTargets = _mergeTopicTargets([
      courseTreeTargets,
      widget.topicTargets,
      questionMetadataTargets,
    ]);
    final effectiveModules = _mergeModules(
      courseState.modules,
      widget.modules,
      effectiveTopicTargets,
    );
    final effectiveOutcomes = liveOutcomes.isNotEmpty ? liveOutcomes : widget.outcomes;
    final treeLoading = _isCourseTreeLoading(courseState);

    final materialOptions = _materialFilterOptions(effectiveTopicTargets, _moduleId);
    final visibleTargets = effectiveTopicTargets.where((target) {
      if (_moduleId != null && target.module.id != _moduleId) return false;
      if (_materialId != null && target.material.id != _materialId) return false;
      return true;
    }).toList();
    final outcomeOptions = _learningOutcomeTreeOptions(widget.questions, effectiveOutcomes);
    final manualMatching = _matchingQuestions(effectiveTopicTargets);
    final generationMatching = _backendGenerationQuestions(effectiveTopicTargets);
    final matching = _scopeMode == _ExamScopeMode.topics ? generationMatching : manualMatching;
    final eligibleMatching = _eligibleQuestionsForTemplate(matching);
    final requirementGaps = _scopeMode == _ExamScopeMode.topics
        ? _templateRequirementGaps(generationMatching)
        : _templateTypeRequirementGaps(manualMatching);
    final difficultyError = _difficultyConfigError();
    final templateItems = _templates.isNotEmpty ? _templates : <ExamTemplateModel>[_template];

    final templateValue = _template.name;
    final templateLabels = templateItems.map((item) => item.name).toList();
    final moduleValue = _selectedModuleLabel(effectiveModules, _moduleId);
    final moduleItems = <String>['All modules', ...effectiveModules.map(_moduleLabel)];
    final materialValue = _selectedMaterialFilterLabel(materialOptions, _materialId);
    final materialItems = <String>['All materials', ...materialOptions.map((option) => option.label)];
    final titleReady = _titleCtrl.text.trim().isNotEmpty;
    final generateReady = _scopeMode == _ExamScopeMode.topics && difficultyError == null && requirementGaps.isEmpty;
    final canBuildManually = titleReady && !_generating;
    final canGoNext = titleReady && _scopeMode == _ExamScopeMode.topics && !_generating;
    final canGenerate = titleReady && generateReady && !_generating;

    final generateStatus = _generateStatusText(
      titleReady: titleReady,
      matchingCount: matching.length,
      gaps: requirementGaps,
      difficultyError: difficultyError,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120, maxHeight: 760),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Material(
            color: AppColors.cardBg,
            child: Column(
              children: [
                _ExamSetupHeader(
                  courseTitle: widget.course.title,
                  totalQuestions: widget.questions.length,
                  onClose: _generating ? null : () => Navigator.of(context).pop(),
                ),
                _DialogNoticeStack(
                  children: [
                    if (_error != null) _SetupAlert(message: _error!, tone: _SetupAlertTone.danger),
                    if (_templatesLoading)
                      const _SetupAlert(
                        message: 'Syncing exam templates from the backend. You can continue with the visible options.',
                        tone: _SetupAlertTone.info,
                      ),
                    if (treeLoading && effectiveTopicTargets.isEmpty)
                      const _SetupAlert(
                        message: 'Loading course structure from the backend...',
                        tone: _SetupAlertTone.info,
                      ),
                  ],
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 900;

                      Widget informationFields() {
                        return LayoutBuilder(
                          builder: (context, inner) {
                            final stacked = inner.maxWidth < 590;
                            final templateField = _SetupDropdownField(
                              label: 'Template',
                              width: stacked ? inner.maxWidth : (inner.maxWidth - 12) * 0.42,
                              value: templateValue,
                              items: templateLabels,
                              onChanged: (value) {
                                final selected = templateItems.cast<ExamTemplateModel?>().firstWhere(
                                      (item) => item != null && item.name == value,
                                      orElse: () => null,
                                    );
                                if (selected == null) return;
                                setState(() {
                                  _applyTemplate(selected);
                                  _error = null;
                                });
                              },
                            );
                            final titleField = SizedBox(
                              width: stacked ? inner.maxWidth : (inner.maxWidth - 12) * 0.58,
                              child: _SetupTextField(
                                label: 'Exam title',
                                controller: _titleCtrl,
                                enabled: !_generating,
                                onChanged: (_) => setState(() => _error = null),
                              ),
                            );
                            if (stacked) {
                              return Column(
                                children: [
                                  titleField,
                                  const SizedBox(height: 12),
                                  templateField,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                titleField,
                                const SizedBox(width: 12),
                                templateField,
                              ],
                            );
                          },
                        );
                      }

                      Widget filters() {
                        return LayoutBuilder(
                          builder: (context, inner) {
                            final stacked = inner.maxWidth < 520;
                            final width = stacked ? inner.maxWidth : (inner.maxWidth - 12) / 2;
                            final fields = <Widget>[
                              _SetupDropdownField(
                                label: 'Module scope',
                                width: width,
                                value: moduleValue,
                                items: moduleItems,
                                onChanged: (value) {
                                  final module = effectiveModules.cast<ModuleItem?>().firstWhere(
                                        (item) => item != null && _moduleLabel(item) == value,
                                        orElse: () => null,
                                      );
                                  setState(() {
                                    _moduleId = module?.id;
                                    _materialId = null;
                                    _topicIds.clear();
                                    _error = null;
                                  });
                                },
                              ),
                              _SetupDropdownField(
                                label: 'Material scope',
                                width: width,
                                value: materialValue,
                                items: materialItems,
                                onChanged: (value) {
                                  final option = materialOptions.cast<_FilterOption?>().firstWhere(
                                        (item) => item != null && item.label == value,
                                        orElse: () => null,
                                      );
                                  setState(() {
                                    _materialId = option?.id;
                                    _topicIds.clear();
                                    _error = null;
                                  });
                                },
                              ),
                            ];
                            if (stacked) {
                              return Column(
                                children: [
                                  fields[0],
                                  const SizedBox(height: 12),
                                  fields[1],
                                ],
                              );
                            }
                            return Row(
                              children: [
                                fields[0],
                                const SizedBox(width: 12),
                                fields[1],
                              ],
                            );
                          },
                        );
                      }

                      final informationPanel = _SetupPanel(
                        title: 'Exam information',
                        subtitle: 'Name the exam and select the backend template that defines the sections.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            informationFields(),
                            const SizedBox(height: 16),
                            filters(),
                          ],
                        ),
                      );

                      final sourcePanel = _SetupPanel(
                        title: 'Question source',
                        subtitle: _scopeMode == _ExamScopeMode.topics
                            ? 'Select topics or leave the selection empty so the backend can use every topic in the course.'
                            : 'Learning outcomes are available for manual exam building only.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ScopeModeSelector(
                              mode: _scopeMode,
                              selectedTopicCount: _topicIds.length,
                              selectedOutcomeCount: _outcomeIds.length,
                              onChanged: (mode) {
                                if (mode == _scopeMode || _generating) return;
                                setState(() {
                                  _scopeMode = mode;
                                  if (mode == _ExamScopeMode.topics) {
                                    _outcomeIds.clear();
                                  } else {
                                    _topicIds.clear();
                                  }
                                  _error = null;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 140),
                              child: _scopeMode == _ExamScopeMode.topics
                                  ? _SetupTopicTreePicker(
                                      key: const ValueKey<String>('topics'),
                                      targets: visibleTargets,
                                      selectedTopicIds: _topicIds,
                                      onChanged: (ids) {
                                        if (_generating) return;
                                        setState(() {
                                          _topicIds
                                            ..clear()
                                            ..addAll(ids);
                                          _error = null;
                                        });
                                      },
                                    )
                                  : _SetupOutcomePicker(
                                      key: const ValueKey<String>('outcomes'),
                                      outcomes: outcomeOptions,
                                      selectedOutcomeIds: _outcomeIds,
                                      onChanged: (ids) {
                                        if (_generating) return;
                                        setState(() {
                                          _outcomeIds
                                            ..clear()
                                            ..addAll(ids);
                                          _error = null;
                                        });
                                      },
                                    ),
                            ),
                          ],
                        ),
                      );

                      final difficultyPanel = _SetupPanel(
                        title: 'Section difficulty',
                        subtitle: 'Set Easy, Medium, and Hard percentages for every backend template section. Each section must total 100%.',
                        child: _GenerationDifficultyPanel(
                          sections: _effectiveDistributionSections(_template),
                          drafts: _difficultyDrafts,
                          enabled: !_generating,
                          onChanged: () => setState(() => _error = null),
                        ),
                      );

                      final summaryPanel = _ExamSetupSummaryPanel(
                        currentStep: _setupStep,
                        showWorkflow: !compact,
                        titleReady: titleReady,
                        scopeMode: _scopeMode,
                        selectedScopeCount: _scopeMode == _ExamScopeMode.topics ? _topicIds.length : _outcomeIds.length,
                        matchingCount: matching.length,
                        eligibleCount: eligibleMatching.length,
                        targetCount: _template.questionCount,
                        durationMinutes: _template.durationMinutes,
                        publishAfterSave: _template.publishAfterSave,
                        template: _template,
                        gaps: requirementGaps,
                        canGenerate: canGenerate,
                        canBuildManually: canBuildManually,
                        templateWillBeSaved: _template.backendId == null,
                        backendMessage: generateStatus,
                      );

                      final pageTitle = _setupStep == 0
                          ? const _SetupPageTitle(
                              title: 'Define exam setup',
                              subtitle: 'Start with the exam metadata and source. The backend generation flow accepts topics; manual build can use topics or learning outcomes.',
                            )
                          : const _SetupPageTitle(
                              title: 'Review section difficulty',
                              subtitle: 'These percentages are sent to generate-exam as section_difficulty_distribution using the real backend section order_index values.',
                            );

                      final stepContent = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          pageTitle,
                          const SizedBox(height: 18),
                          if (_setupStep == 0) ...[
                            informationPanel,
                            const SizedBox(height: 16),
                            sourcePanel,
                          ] else ...[
                            difficultyPanel,
                          ],
                        ],
                      );

                      if (compact) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SetupStepIndicator(currentStep: _setupStep),
                              const SizedBox(height: 14),
                              summaryPanel,
                              const SizedBox(height: 18),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: KeyedSubtree(
                                  key: ValueKey<int>(_setupStep),
                                  child: stepContent,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 304,
                            color: AppColors.surfaceMuted,
                            padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
                            child: SingleChildScrollView(child: summaryPanel),
                          ),
                          VerticalDivider(width: 1, color: AppColors.borderGray),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(26, 22, 26, 24),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: KeyedSubtree(
                                  key: ValueKey<int>(_setupStep),
                                  child: stepContent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Divider(height: 1, color: AppColors.borderGray),
                Container(
                  color: AppColors.cardBg,
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: _generating ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      if (_setupStep == 1) ...[
                        OutlinedButton.icon(
                          onPressed: _generating ? null : _goBackToSetupStep,
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Back'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (_setupStep == 0) ...[
                        OutlinedButton.icon(
                          onPressed: canBuildManually ? () => _continue(effectiveTopicTargets) : null,
                          icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                          label: const Text('Build manually'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: canGoNext ? _goToDifficultyStep : null,
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: const Text('Continue'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                          ),
                        ),
                      ] else ...[
                        FilledButton.icon(
                          onPressed: canGenerate ? () => _generateExamFromBackend(effectiveTopicTargets) : null,
                          icon: _generating
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(strokeWidth: 2.3, color: Colors.white),
                                )
                              : const Icon(Icons.auto_awesome_rounded, size: 18),
                          label: Text(_generating ? 'Generating...' : 'Generate Exam'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
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
      ),
    );
  }

  String _generateStatusText({
    required bool titleReady,
    required int matchingCount,
    required List<_TemplateRequirementGap> gaps,
    required String? difficultyError,
  }) {
    if (!titleReady) return 'Add an exam title first.';
    if (_scopeMode != _ExamScopeMode.topics) {
      return 'Backend generate-exam accepts topic/subtopic IDs. Learning outcomes can still be used in the manual builder.';
    }
    if (difficultyError != null) return difficultyError;
    if (gaps.isNotEmpty) {
      return 'Not enough saved questions for this template and difficulty mix. Adjust the source, template, or percentages before generating.';
    }
    if (matchingCount == 0) return 'No saved questions match the selected source.';
    if (_topicIds.isEmpty) return 'Ready to generate from all course topics using the current question bank.';
    if (_template.backendId == null) {
      return 'Ready. The selected template will be saved to the backend first, then generate-exam will create the exam.';
    }
    return 'Ready to call generate-exam with ${_topicIds.length} selected topic${_topicIds.length == 1 ? '' : 's'}.';
  }
}


