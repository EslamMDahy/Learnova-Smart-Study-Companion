import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/error_mapper.dart';
import '../../../../../shared/widgets/app_ui_components.dart';
import '../../../data/courses_models.dart';
import '../../../data/exam_models.dart';
import '../../../data/exam_templates_storage.dart';
import '../../../data/learning_outcomes_models.dart';
import '../../../data/materials_models.dart';
import '../../../data/modules_materials_providers.dart';
import '../../../data/modules_models.dart';
import '../../../data/question_models.dart';
import '../../../data/question_vocabulary.dart';
import '../../../data/questions_api.dart';
import '../../../data/topics_models.dart';
import '../../controllers/course_details_controller.dart';
import '../../controllers/course_details_state.dart';
import '../course_outcomes_panel.dart';
import 'create_exam_flow.dart';

class CourseQuestionBankTab extends ConsumerStatefulWidget {
  final MyCourseItem course;

  const CourseQuestionBankTab({super.key, required this.course});

  @override
  ConsumerState<CourseQuestionBankTab> createState() => _CourseQuestionBankTabState();
}

class _CourseQuestionBankTabState extends ConsumerState<CourseQuestionBankTab> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  String _search = '';
  QuestionType? _filterType;
  QuestionDifficulty? _filterDiff;
  QuestionSource? _filterSource;
  bool? _filterUsed;
  int? _filterModuleId;
  int? _filterMaterialId;
  int? _filterTopicId;
  int? _filterOutcomeId;
  String? _selectedQuestionId;
  _ExamStartConfig? _examStartConfig;

  bool _loading = true;
  bool _creatingExam = false;
  bool _treeRequested = false;
  String? _error;
  List<QuestionModel> _questions = [];
  int _pageIndex = 0;
  int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestions();
      _loadCourseTree();
      ensureCourseLearningOutcomesLoaded(ref, widget.course.id);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(questionsApiProvider);
      final resp = await api.getCourseQuestions(courseId: widget.course.id);
      if (!mounted) return;
      setState(() {
        _questions = resp.questions;
        _loading = false;
        _pageIndex = 0;
        if (_selectedQuestionId != null &&
            !_questions.any((question) => question.id == _selectedQuestionId)) {
          _selectedQuestionId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = mapApiFailure(e).message;
        _loading = false;
      });
    }
  }

  Future<void> _loadCourseTree() async {
    if (_treeRequested) return;
    _treeRequested = true;
    try {
      await ref
          .read(courseDetailsControllerProvider(widget.course.id).notifier)
          .loadModulesAndAllMaterials();
    } catch (_) {
      // The question list can still work without the full authoring tree.
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted || value == _search) return;
      setState(() {
        _search = value;
        _pageIndex = 0;
      });
    });
  }

  Future<void> _editQuestion(
    QuestionModel question,
    List<_TopicTarget> topicTargets,
  ) async {
    var editableQuestion = question;
    final qid = question.remoteId ?? int.tryParse(question.id);
    if (qid != null && qid > 0) {
      try {
        editableQuestion = await ref.read(questionsApiProvider).getQuestion(
              courseId: widget.course.id,
              questionId: qid,
            );
      } catch (_) {
        editableQuestion = question;
      }
    }

    if (!mounted) return;
    final updated = await showDialog<QuestionModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditQuestionDialog(
        courseId: widget.course.id,
        question: editableQuestion,
        topicTargets: topicTargets,
      ),
    );

    if (updated == null || !mounted) return;

    setState(() {
      _questions = _questions.map((item) {
        if (item.id == question.id || item.remoteId == question.remoteId) return updated;
        return item;
      }).toList();
      _selectedQuestionId = updated.id;
    });
  }

  void _openQuestionReview(
    QuestionModel question,
    List<_TopicTarget> topicTargets,
  ) {
    if (!mounted) return;
    setState(() => _selectedQuestionId = question.id);
    showDialog<void>(
      context: context,
      builder: (_) => _QuestionReviewDialog(
        courseId: widget.course.id,
        question: question,
        topicTargets: topicTargets,
      ),
    );
  }

  void _showDeleteUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Delete is not available in the current backend API contract.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseState = ref.watch(courseDetailsControllerProvider(widget.course.id));
    final courseOutcomes = ref.watch(courseLOProvider(widget.course.id));
    final topicTargets = _topicTargetsFromState(courseState);
    final topicTargetByTopicId = {for (final target in topicTargets) target.topic.id: target};
    final filtered = _applyFilters(_questions, topicTargetByTopicId);
    final totalPages = filtered.isEmpty ? 1 : ((filtered.length - 1) ~/ _pageSize) + 1;
    final safePageIndex = _pageIndex.clamp(0, totalPages - 1).toInt();
    final startIndex = filtered.isEmpty ? 0 : safePageIndex * _pageSize;
    final endIndex = filtered.isEmpty
        ? 0
        : (startIndex + _pageSize > filtered.length ? filtered.length : startIndex + _pageSize);
    final pageQuestions = filtered.isEmpty ? <QuestionModel>[] : filtered.sublist(startIndex, endIndex);
    final selectedQuestionId = _selectedQuestionId;
    final examReadyCount = _questions.where((question) => question.remoteId != null).length;

    if (_creatingExam) {
      final config = _examStartConfig;
      return CreateExamFlow(
        course: widget.course,
        questions: _questions,
        initialTemplate: config?.template,
        initialScopeModuleId: config?.moduleId,
        initialScopeMaterialId: config?.materialId,
        initialScopeTopicIds: config?.topicIds ?? const <int>{},
        initialScopeOutcomeIds: config?.outcomeIds ?? const <int>{},
        initialTitle: config?.title,
        onCancel: () => setState(() {
          _creatingExam = false;
          _examStartConfig = null;
        }),
        onCreated: () async {
          await _loadQuestions();
          if (!mounted) return;
          setState(() {
            _creatingExam = false;
            _examStartConfig = null;
          });
        },
      );
    }

    return Container(
      color: AppColors.pageBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _QuestionBankHeader(
                  loading: _loading,
                  canCreateExam: _questions.isNotEmpty,
                  totalQuestionsCount: _questions.length,
                  visibleQuestionsCount: filtered.length,
                  examReadyCount: examReadyCount,
                  onRefresh: _loadQuestions,
                  onCreateExam: _openCreateExamStart,
                ),
                const SizedBox(height: 16),
                _QuestionBankWorkspace(
                  loading: _loading,
                  error: _error == null ? null : _friendlyError(_error!),
                  questions: pageQuestions,
                  allQuestionsCount: _questions.length,
                  filteredQuestionsCount: filtered.length,
                  pageStartIndex: startIndex,
                  pageIndex: safePageIndex,
                  pageSize: _pageSize,
                  totalPages: totalPages,
                  selectedQuestionId: selectedQuestionId,
                  searchController: _searchController,
                  filterModuleId: _filterModuleId,
                  filterDiff: _filterDiff,
                  filterType: _filterType,
                  filterSource: _filterSource,
                  filterUsed: _filterUsed,
                  filterMaterialId: _filterMaterialId,
                  filterTopicId: _filterTopicId,
                  filterOutcomeId: _filterOutcomeId,
                  modules: courseState.modules,
                  topicTargets: topicTargets,
                  topicTargetByTopicId: topicTargetByTopicId,
                  allQuestions: _questions,
                  courseOutcomes: courseOutcomes,
                  onSearchChanged: _onSearchChanged,
                  onSelectQuestion: (question) => _openQuestionReview(question, topicTargets),
                  onModuleChanged: (value) => setState(() {
                    _filterModuleId = value;
                    _pageIndex = 0;
                    if (value == null) {
                      _filterMaterialId = null;
                      _filterTopicId = null;
                    } else if (_filterMaterialId != null &&
                        !_materialBelongsToModule(topicTargets, _filterMaterialId!, value)) {
                      _filterMaterialId = null;
                      _filterTopicId = null;
                    }
                  }),
                  onMaterialChanged: (value) => setState(() {
                    _filterMaterialId = value;
                    _pageIndex = 0;
                    if (value == null) {
                      _filterTopicId = null;
                    } else if (_filterTopicId != null &&
                        !_topicBelongsToMaterial(topicTargets, _filterTopicId!, value)) {
                      _filterTopicId = null;
                    }
                  }),
                  onTopicChanged: (value) => setState(() {
                    _filterTopicId = value;
                    _pageIndex = 0;
                  }),
                  onOutcomeChanged: (value) => setState(() {
                    _filterOutcomeId = value;
                    _pageIndex = 0;
                  }),
                  onSourceChanged: (value) => setState(() {
                    _filterSource = value;
                    _pageIndex = 0;
                  }),
                  onUsageChanged: (value) => setState(() {
                    _filterUsed = value;
                    _pageIndex = 0;
                  }),
                  onDifficultyChanged: (value) => setState(() {
                    _filterDiff = value;
                    _pageIndex = 0;
                  }),
                  onTypeChanged: (value) => setState(() {
                    _filterType = value;
                    _pageIndex = 0;
                  }),
                  onPageChanged: (value) => setState(() => _pageIndex = value),
                  onPageSizeChanged: (value) => setState(() {
                    _pageSize = value;
                    _pageIndex = 0;
                  }),
                  onClearFilters: _clearFilters,
                  onRetry: _loadQuestions,
                  onEditQuestion: _editQuestion,
                  onDeleteUnavailable: _showDeleteUnavailable,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateExamStart() async {
    if (_questions.isEmpty || _creatingExam) return;
    _loadCourseTree();
    ensureCourseLearningOutcomesLoaded(ref, widget.course.id);

    final Future<List<ExamTemplateModel>> templatesFuture = ref
        .read(examTemplatesStorageProvider)
        .load(widget.course.id)
        .catchError((Object _) => ExamTemplateModel.defaults(widget.course.id));

    final outcomes = ref.read(courseLOProvider(widget.course.id));
    final latestState = ref.read(courseDetailsControllerProvider(widget.course.id));
    final latestTopicTargets = _topicTargetsFromState(latestState);
    final config = await showDialog<_ExamStartConfig>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateExamStartDialog(
        course: widget.course,
        templates: ExamTemplateModel.defaults(widget.course.id),
        templatesFuture: templatesFuture,
        modules: latestState.modules,
        topicTargets: latestTopicTargets,
        outcomes: outcomes,
        questions: _questions,
        onGenerated: _loadQuestions,
      ),
    );
    if (config == null || !mounted) return;
    setState(() {
      _examStartConfig = config;
      _creatingExam = true;
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _search = '';
      _filterType = null;
      _filterDiff = null;
      _filterSource = null;
      _filterUsed = null;
      _filterModuleId = null;
      _filterMaterialId = null;
      _filterTopicId = null;
      _filterOutcomeId = null;
      _pageIndex = 0;
    });
  }

  List<QuestionModel> _applyFilters(List<QuestionModel> input, Map<int, _TopicTarget> topicTargetByTopicId) {
    return input.where((q) {
      final s = _search.trim().toLowerCase();
      if (s.isNotEmpty) {
        final matchesText = q.text.toLowerCase().contains(s);
        final matchesTopic = (q.topicName ?? '').toLowerCase().contains(s);
        final matchesModule = (q.moduleName ?? '').toLowerCase().contains(s);
        final matchesMaterial = (q.materialName ?? '').toLowerCase().contains(s);
        final matchesOutcome = q.learningOutcomes.any(
          (outcome) => outcome.title.toLowerCase().contains(s),
        );
        final matchesTags = q.tags.any((tag) => tag.toLowerCase().contains(s));
        final matchesType = q.typeLabel.toLowerCase().contains(s);
        final matchesDifficulty = q.difficultyLabel.toLowerCase().contains(s);
        final matchesSource = _sourceLabel(q.source).toLowerCase().contains(s);
        if (!matchesText &&
            !matchesTopic &&
            !matchesModule &&
            !matchesMaterial &&
            !matchesOutcome &&
            !matchesTags &&
            !matchesType &&
            !matchesDifficulty &&
            !matchesSource) {
          return false;
        }
      }
      final target = q.topicId == null ? null : topicTargetByTopicId[q.topicId];
      final moduleId = q.moduleId ?? target?.module.id;
      final materialId = q.materialId ?? target?.material.id;
      final topicId = q.topicId ?? target?.topic.id;

      if (_filterModuleId != null && moduleId != _filterModuleId) return false;
      if (_filterMaterialId != null && materialId != _filterMaterialId) return false;
      if (_filterTopicId != null && topicId != _filterTopicId) return false;
      if (_filterType != null && q.type != _filterType) return false;
      if (_filterDiff != null && q.difficulty != _filterDiff) return false;
      if (_filterSource != null && q.source != _filterSource) return false;
      if (_filterUsed != null && (q.usageCount > 0) != _filterUsed) return false;
      if (_filterOutcomeId != null && !q.learningOutcomes.any((outcome) => outcome.id == _filterOutcomeId)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<_TopicTarget> _topicTargetsFromState(CourseDetailsState courseState) {
    final result = <_TopicTarget>[];
    for (final module in courseState.modules) {
      final materials = courseState.materials[module.id] ?? const <MaterialItem>[];
      final materialsById = {for (final material in materials) material.id: material};
      final topics = courseState.topics[module.id] ?? const <TopicItem>[];
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
          topic: topic,
          parentTopicTitle: parentTitle,
        ),);
      }
    }
    result.sort((a, b) {
      final moduleCmp = a.module.orderIndex.compareTo(b.module.orderIndex);
      if (moduleCmp != 0) return moduleCmp;
      final materialCmp = a.material.displayTitle.compareTo(b.material.displayTitle);
      if (materialCmp != 0) return materialCmp;
      return a.topic.orderIndex.compareTo(b.topic.orderIndex);
    });
    return result;
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('session expired') || lower.contains('login again')) {
      return 'Your session expired while loading questions. Please log in again.';
    }
    return raw.trim().isNotEmpty ? raw : 'Could not load saved questions right now.';
  }
}


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

class _CreateExamStartDialog extends ConsumerStatefulWidget {
  final MyCourseItem course;
  final List<ExamTemplateModel> templates;
  final Future<List<ExamTemplateModel>>? templatesFuture;
  final List<ModuleItem> modules;
  final List<_TopicTarget> topicTargets;
  final List<LearningOutcome> outcomes;
  final List<QuestionModel> questions;
  final Future<void> Function()? onGenerated;

  const _CreateExamStartDialog({
    required this.course,
    required this.templates,
    this.templatesFuture,
    required this.modules,
    required this.topicTargets,
    required this.outcomes,
    required this.questions,
    this.onGenerated,
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
    _titleCtrl.text = _defaultExamTitle(_template);
    _loadTemplatesInPlace();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDialogCourseTreeLoaded());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensureDialogCourseTreeLoaded() async {
    if (_dialogTreeRequested) return;
    _dialogTreeRequested = true;
    try {
      await Future.wait([
        ref
            .read(courseDetailsControllerProvider(widget.course.id).notifier)
            .loadModulesAndAllMaterials(force: true),
        ensureCourseLearningOutcomesLoaded(ref, widget.course.id, force: true),
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
    if (currentTitle.isEmpty || currentTitle == previousDefault) {
      _titleCtrl.text = _defaultExamTitle(template);
    }
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


  List<QuestionModel> _eligibleQuestionsForTemplate(List<QuestionModel> matching) {
    final difficulty = _template.preferredDifficulty;
    if (difficulty == null) return matching;
    return matching.where((question) => question.difficulty == difficulty).toList();
  }

  List<_TemplateRequirementGap> _templateRequirementGaps(List<QuestionModel> matching) {
    final activeSections = _template.sections.where((section) => section.questionCount > 0).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    if (activeSections.isEmpty) {
      final available = _eligibleQuestionsForTemplate(matching).length;
      return available >= _template.questionCount
          ? const <_TemplateRequirementGap>[]
          : [
              _TemplateRequirementGap(
                label: 'Total questions',
                requiredCount: _template.questionCount,
                availableCount: available,
              ),
            ];
    }

    final eligible = _eligibleQuestionsForTemplate(matching);
    final gaps = <_TemplateRequirementGap>[];
    for (final section in activeSections) {
      final type = parseQuestionType(section.questionType);
      final difficultyCounts = _sectionDifficultyDistribution(section);
      if (difficultyCounts.isEmpty) {
        final available = eligible.where((question) => question.type == type).length;
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
    if (!_hasRequiredScope) {
      setState(() => _error = backendGenerate && _scopeMode == _ExamScopeMode.outcomes
          ? 'The generate-exam endpoint needs topic/subtopic scope. Switch to Topics or use Build manually.'
          : _scopeRequiredMessage);
      return null;
    }

    if (backendGenerate && _scopeMode != _ExamScopeMode.topics) {
      setState(() => _error = 'Backend generation currently supports topic/subtopic scope. Use Build manually for learning outcomes.');
      return null;
    }

    final matching = _matchingQuestions(topicTargets);
    if (matching.isEmpty) {
      setState(() => _error = 'No saved questions match the selected scope. Choose a different topic/subtopic or learning outcome.');
      return null;
    }

    final gaps = _templateRequirementGaps(matching);
    if (gaps.isNotEmpty) {
      setState(() => _error = _gapsMessage(gaps));
      return null;
    }

    return gaps;
  }

  void _continue(List<_TopicTarget> topicTargets) {
    final title = _validatedExamTitle();
    if (title == null) return;
    final validation = _validateScopeAndDistribution(
      backendGenerate: false,
      topicTargets: topicTargets,
    );
    if (validation == null) return;

    Navigator.of(context).pop(_ExamStartConfig(
      template: _template,
      title: title,
      moduleId: _moduleId,
      materialId: _materialId,
      topicIds: _scopeMode == _ExamScopeMode.topics ? Set<int>.from(_topicIds) : const <int>{},
      outcomeIds: _scopeMode == _ExamScopeMode.outcomes ? Set<int>.from(_outcomeIds) : const <int>{},
    ),);
  }

  Map<String, dynamic> _difficultyDistributionForTemplate(
    ExamTemplateModel template,
    List<QuestionModel> matching,
  ) {
    final sections = _effectiveDistributionSections(template);
    final result = <String, dynamic>{};

    for (var index = 0; index < sections.length; index++) {
      final section = sections[index];
      final orderIndex = section.orderIndex > 0 ? section.orderIndex : index + 1;
      final type = parseQuestionType(section.questionType);
      final configured = _difficultyPercentagesFromCounts(_sectionDifficultyDistribution(section));
      if (configured.isNotEmpty) {
        result['$orderIndex'] = configured;
      } else {
        final candidates = matching.where((question) => question.type == type).toList();
        result['$orderIndex'] = _difficultyPercentages(candidates);
      }
    }

    if (result.isEmpty) {
      result['1'] = const <String, int>{'medium': 100};
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

  Map<String, int> _difficultyPercentages(List<QuestionModel> questions) {
    final counts = <String, int>{
      'easy': questions.where((question) => question.difficulty == QuestionDifficulty.easy).length,
      'medium': questions.where((question) => question.difficulty == QuestionDifficulty.medium).length,
      'hard': questions.where((question) => question.difficulty == QuestionDifficulty.hard).length,
    };
    final total = counts.values.fold<int>(0, (sum, count) => sum + count);
    if (total <= 0) return const <String, int>{'medium': 100};

    final nonZeroKeys = counts.entries.where((entry) => entry.value > 0).map((entry) => entry.key).toList();
    var assigned = 0;
    final distribution = <String, int>{};
    for (var i = 0; i < nonZeroKeys.length; i++) {
      final key = nonZeroKeys[i];
      final value = counts[key] ?? 0;
      final percent = i == nonZeroKeys.length - 1 ? 100 - assigned : (value * 100 / total).round();
      distribution[key] = percent;
      assigned += percent;
    }

    if (distribution.isEmpty) return const <String, int>{'medium': 100};
    final sum = distribution.values.fold<int>(0, (a, b) => a + b);
    if (sum != 100) {
      final adjustKey = distribution.containsKey('medium') ? 'medium' : distribution.keys.first;
      distribution[adjustKey] = (distribution[adjustKey] ?? 0) + (100 - sum);
    }
    return distribution;
  }

  Map<String, int> _difficultyPercentagesFromCounts(Map<String, int> counts) {
    final positive = <String, int>{};
    for (final entry in counts.entries) {
      if (entry.value > 0) positive[entry.key] = entry.value;
    }
    final total = positive.values.fold<int>(0, (sum, count) => sum + count);
    if (total <= 0) return const <String, int>{};

    var assigned = 0;
    final result = <String, int>{};
    final entries = positive.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final percent = i == entries.length - 1 ? 100 - assigned : (entry.value * 100 / total).round();
      if (percent > 0) result[entry.key] = percent;
      assigned += percent;
    }
    if (result.isEmpty) return const <String, int>{'medium': 100};
    final sum = result.values.fold<int>(0, (a, b) => a + b);
    if (sum != 100) {
      final adjustKey = result.containsKey('medium') ? 'medium' : result.keys.first;
      result[adjustKey] = (result[adjustKey] ?? 0) + (100 - sum);
    }
    return result;
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

      final topicIds = _topicIds.toList()..sort();
      final distribution = _difficultyDistributionForTemplate(
        savedTemplate,
        _matchingQuestions(topicTargets),
      );
      final exam = await ref.read(examsApiProvider).generateExamFromTemplate(
            courseId: widget.course.id,
            templateId: templateId,
            payload: GenerateExamFromTemplatePayload(
              title: title,
              topicIds: topicIds,
              sectionDifficultyDistribution: distribution,
            ),
          );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => _GeneratedExamSuccessDialog(exam: exam, template: savedTemplate),
      );
      if (!mounted) return;
      await widget.onGenerated?.call();
      if (!mounted) return;
      Navigator.of(context).pop();
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
    final outcomeOptions = _learningOutcomeSetupOptions(widget.questions, effectiveOutcomes);
    final matching = _matchingQuestions(effectiveTopicTargets);
    final eligibleMatching = _eligibleQuestionsForTemplate(matching);
    final requirementGaps = _templateRequirementGaps(matching);
    final templateItems = _templates.isNotEmpty ? _templates : <ExamTemplateModel>[_template];

    final templateValue = _template.name;
    final templateLabels = templateItems.map((item) => item.name).toList();
    final moduleValue = _selectedModuleLabel(effectiveModules, _moduleId);
    final moduleItems = <String>['All modules', ...effectiveModules.map(_moduleLabel)];
    final materialValue = _selectedMaterialFilterLabel(materialOptions, _materialId);
    final materialItems = <String>['All materials', ...materialOptions.map((option) => option.label)];
    final titleReady = _titleCtrl.text.trim().isNotEmpty;
    final scopeReady = _hasRequiredScope && matching.isNotEmpty && requirementGaps.isEmpty;
    final canBuildManually = titleReady && scopeReady && !_generating;
    final canGenerate = canBuildManually && _scopeMode == _ExamScopeMode.topics;

    final generateStatus = _generateStatusText(
      titleReady: titleReady,
      matchingCount: matching.length,
      gaps: requirementGaps,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120, maxHeight: 820),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: AppColors.cardBg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ExamSetupHeader(
                  courseTitle: widget.course.title,
                  totalQuestions: widget.questions.length,
                  onClose: _generating ? null : () => Navigator.of(context).pop(),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                    child: _SetupAlert(message: _error!, tone: _SetupAlertTone.danger),
                  ),
                if (_templatesLoading)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 18, 24, 0),
                    child: _SetupAlert(
                      message: 'Syncing saved exam templates from the backend. You can continue with the visible options.',
                      tone: _SetupAlertTone.info,
                    ),
                  ),
                if (treeLoading && effectiveTopicTargets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 18, 24, 0),
                    child: _SetupAlert(
                      message: 'Loading course materials and topics directly from the backend...',
                      tone: _SetupAlertTone.info,
                    ),
                  ),
                Flexible(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 900;
                      final blueprintPanel = _SetupPanel(
                        title: 'Blueprint',
                        subtitle: 'Name the exam and select the template the backend should use.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SetupTextField(
                              label: 'Exam title',
                              controller: _titleCtrl,
                              enabled: !_generating,
                              onChanged: (_) => setState(() => _error = null),
                            ),
                            const SizedBox(height: 14),
                            _SetupDropdownField(
                              label: 'Template',
                              width: double.infinity,
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
                            ),
                            const SizedBox(height: 14),
                            LayoutBuilder(
                              builder: (context, inner) {
                                final twoCols = inner.maxWidth >= 560;
                                final width = twoCols ? (inner.maxWidth - 12) / 2 : inner.maxWidth;
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
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
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            _TemplateInsightCard(template: _template),
                            const SizedBox(height: 14),
                            _SetupMetricGrid(
                              matchingCount: eligibleMatching.length,
                              targetCount: _template.questionCount,
                              durationMinutes: _template.durationMinutes,
                              publishAfterSave: _template.publishAfterSave,
                            ),
                          ],
                        ),
                      );

                      final scopePanel = _SetupPanel(
                        title: 'Question source',
                        subtitle: 'Choose the exact scope. Generate uses topics; manual build also supports outcomes.',
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
                              duration: const Duration(milliseconds: 160),
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
                            const SizedBox(height: 14),
                            _TemplateDistributionStatus(template: _template, gaps: requirementGaps),
                            const SizedBox(height: 14),
                            _BackendGenerateStatus(
                              enabled: canGenerate,
                              templateWillBeSaved: _template.backendId == null,
                              message: generateStatus,
                            ),
                          ],
                        ),
                      );

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                        child: compact
                            ? Column(
                                children: [
                                  blueprintPanel,
                                  const SizedBox(height: 16),
                                  scopePanel,
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 360, child: blueprintPanel),
                                  const SizedBox(width: 18),
                                  Expanded(child: scopePanel),
                                ],
                              ),
                      );
                    },
                  ),
                ),
                Divider(height: 1, color: AppColors.borderGray),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: _generating ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: canBuildManually ? () => _continue(effectiveTopicTargets) : null,
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text('Build manually'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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

  String _generateStatusText({
    required bool titleReady,
    required int matchingCount,
    required List<_TemplateRequirementGap> gaps,
  }) {
    if (!titleReady) return 'Add an exam title first.';
    if (_scopeMode != _ExamScopeMode.topics) {
      return 'Backend generate-exam accepts topic/subtopic IDs. Learning outcomes can still be used in the manual builder.';
    }
    if (_topicIds.isEmpty) return 'Select one or more topics/subtopics to enable backend generation.';
    if (matchingCount == 0) return 'No backend-saved questions match this scope.';
    if (gaps.isNotEmpty) return _gapsMessage(gaps);
    if (_template.backendId == null) {
      return 'Ready. The selected template will be saved to the backend first, then generate-exam will create the exam.';
    }
    return 'Ready to call generate-exam with ${_topicIds.length} selected topic${_topicIds.length == 1 ? '' : 's'}.';
  }
}


enum _SetupAlertTone { info, danger }

class _ExamSetupHeader extends StatelessWidget {
  final String courseTitle;
  final int totalQuestions;
  final VoidCallback? onClose;

  const _ExamSetupHeader({
    required this.courseTitle,
    required this.totalQuestions,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 18, 22),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(bottom: BorderSide(color: AppColors.borderGray)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF145CCB), Color(0xFF22C1F1)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.22), blurRadius: 22, offset: const Offset(0, 10))],
            ),
            child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Create Exam',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textTitle,
                          fontSize: 22,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.primary.withOpacity(0.16)),
                      ),
                      child: Text(
                        '$totalQuestions questions',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  courseTitle.trim().isEmpty
                      ? 'Generate from backend templates or build a curated set manually.'
                      : '$courseTitle • Generate from backend templates or build a curated set manually.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, color: AppColors.textMuted, size: 22),
          ),
        ],
      ),
    );
  }
}

class _SetupAlert extends StatelessWidget {
  final String message;
  final _SetupAlertTone tone;

  const _SetupAlert({required this.message, required this.tone});

  @override
  Widget build(BuildContext context) {
    final danger = tone == _SetupAlertTone.danger;
    final bg = danger ? AppColors.dangerBg : AppColors.infoBg;
    final border = danger ? AppColors.dangerBorder : AppColors.infoBorder;
    final color = danger ? AppColors.dangerText : AppColors.infoText;
    final icon = danger ? Icons.error_outline_rounded : Icons.info_outline_rounded;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SetupPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textTitle,
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.2, height: 1.35, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SetupTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _SetupTextField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
        TextField(
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
          textInputAction: TextInputAction.done,
          style: TextStyle(color: AppColors.textTitle, fontWeight: FontWeight.w800, fontSize: 13.2),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? AppColors.fieldBg : AppColors.fieldDisabledBg,
            hintText: 'e.g. Java Midterm - Chapter 1',
            hintStyle: TextStyle(color: AppColors.textHint, fontWeight: FontWeight.w600, fontSize: 13),
            prefixIcon: Icon(Icons.drive_file_rename_outline_rounded, size: 18, color: AppColors.textMuted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderGray),
            ),
          ),
        ),
      ],
    );
  }
}

class _TemplateInsightCard extends StatelessWidget {
  final ExamTemplateModel template;

  const _TemplateInsightCard({required this.template});

  @override
  Widget build(BuildContext context) {
    final distribution = _templateDistributionText(template);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [BoxShadow(color: AppColors.shadowThin, blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.schema_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  template.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textTitle, fontSize: 13.5, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  distribution.isEmpty ? 'Uses total question count.' : 'Distribution: $distribution',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11.7, height: 1.35, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _SetupChip(label: template.examType.toUpperCase()),
                    _SetupChip(label: template.backendId == null ? 'Local template' : 'Backend template'),
                    _SetupChip(label: template.shuffleQuestions ? 'Shuffle questions' : 'Fixed order'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupMetricGrid extends StatelessWidget {
  final int matchingCount;
  final int targetCount;
  final int durationMinutes;
  final bool publishAfterSave;

  const _SetupMetricGrid({
    required this.matchingCount,
    required this.targetCount,
    required this.durationMinutes,
    required this.publishAfterSave,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCols = constraints.maxWidth >= 300;
        final width = twoCols ? (constraints.maxWidth - 10) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SetupMetricTile(width: width, label: 'Matching', value: '$matchingCount'),
            _SetupMetricTile(width: width, label: 'Target', value: '$targetCount'),
            _SetupMetricTile(width: width, label: 'Duration', value: '$durationMinutes min'),
            _SetupMetricTile(width: width, label: 'Mode', value: publishAfterSave ? 'Publish' : 'Draft'),
          ],
        );
      },
    );
  }
}

class _SetupMetricTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;

  const _SetupMetricTile({required this.width, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textTitle, fontSize: 14.5, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _SetupChip extends StatelessWidget {
  final String label;

  const _SetupChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Text(
        label,
        style: TextStyle(color: AppColors.textMuted, fontSize: 10.2, fontWeight: FontWeight.w900, letterSpacing: 0.2),
      ),
    );
  }
}

class _BackendGenerateStatus extends StatelessWidget {
  final bool enabled;
  final bool templateWillBeSaved;
  final String message;

  const _BackendGenerateStatus({
    required this.enabled,
    required this.templateWillBeSaved,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.successText : AppColors.warningText;
    final bg = enabled ? AppColors.successBg : AppColors.warningSoftBg;
    final border = enabled ? AppColors.greenBorder : AppColors.warningBorder;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(enabled ? Icons.rocket_launch_rounded : Icons.rule_rounded, color: color, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  enabled ? 'Backend generate-exam is ready' : 'Generate-exam requirements',
                  style: TextStyle(color: color, fontSize: 12.4, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: color, fontSize: 11.8, height: 1.35, fontWeight: FontWeight.w700),
                ),
                if (enabled && templateWillBeSaved) ...[
                  const SizedBox(height: 6),
                  Text(
                    'This local template will be created in the backend automatically before generation.',
                    style: TextStyle(color: color, fontSize: 11.4, height: 1.35, fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratedExamSuccessDialog extends StatelessWidget {
  final ExamModel exam;
  final ExamTemplateModel template;

  const _GeneratedExamSuccessDialog({required this.exam, required this.template});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      icon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.check_circle_rounded, color: AppColors.successText, size: 28),
      ),
      title: const Text('Exam generated'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The backend generate-exam endpoint created the exam successfully.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.45, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          _GeneratedExamLine(label: 'Exam', value: exam.title),
          _GeneratedExamLine(label: 'Template', value: template.name),
          _GeneratedExamLine(label: 'Questions', value: '${exam.totalQuestions}'),
          _GeneratedExamLine(label: 'Score', value: exam.totalScore.toStringAsFixed(exam.totalScore.truncateToDouble() == exam.totalScore ? 0 : 1)),
          _GeneratedExamLine(label: 'Status', value: exam.isPublished ? 'Published' : 'Draft'),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _GeneratedExamLine extends StatelessWidget {
  final String label;
  final String value;

  const _GeneratedExamLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w900)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: AppColors.textTitle, fontSize: 12.5, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _TemplateRequirementGap {
  final String label;
  final int requiredCount;
  final int availableCount;

  const _TemplateRequirementGap({
    required this.label,
    required this.requiredCount,
    required this.availableCount,
  });
}

class _TemplateDistributionStatus extends StatelessWidget {
  final ExamTemplateModel template;
  final List<_TemplateRequirementGap> gaps;

  const _TemplateDistributionStatus({required this.template, required this.gaps});

  @override
  Widget build(BuildContext context) {
    final distribution = _templateDistributionText(template);
    if (distribution.isEmpty) {
      return Text(
        'Template uses total question count only.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700),
      );
    }
    final ok = gaps.isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: ok ? AppColors.successBg : AppColors.dangerBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ok ? AppColors.successText.withOpacity(0.24) : AppColors.dangerBorder),
      ),
      child: Text(
        ok ? 'Distribution ready: $distribution' : 'Distribution shortage: ${gaps.map((gap) => '${gap.label} ${gap.availableCount}/${gap.requiredCount}').join(' • ')}',
        style: TextStyle(
          color: ok ? AppColors.successText : AppColors.dangerText,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Map<String, int> _sectionDifficultyDistribution(ExamTemplateSectionModel section) {
  final result = <String, int>{};
  for (final entry in section.difficultyDistribution.entries) {
    final key = entry.key.trim().toLowerCase();
    if (entry.value <= 0) continue;
    if (key == 'easy' || key == 'medium' || key == 'hard') result[key] = entry.value;
  }
  return result;
}

String _difficultyCountsText(Map<String, int> counts) {
  if (counts.isEmpty) return '';
  final parts = <String>[];
  final easy = counts['easy'] ?? 0;
  final medium = counts['medium'] ?? 0;
  final hard = counts['hard'] ?? 0;
  if (easy > 0) parts.add('E$easy');
  if (medium > 0) parts.add('M$medium');
  if (hard > 0) parts.add('H$hard');
  return parts.join('/');
}

String _difficultyLabelFromKey(String key) {
  switch (key.trim().toLowerCase()) {
    case 'easy':
      return 'Easy';
    case 'hard':
      return 'Hard';
    default:
      return 'Medium';
  }
}

String _templateDistributionText(ExamTemplateModel template) {
  final sections = template.sections.where((section) => section.questionCount > 0).toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  if (sections.isEmpty) return '';
  return sections.map((section) {
    final difficulty = _difficultyCountsText(_sectionDifficultyDistribution(section));
    return '${section.questionCount} ${_shortTemplateQuestionTypeLabel(section.questionType)}${difficulty.isEmpty ? '' : ' ($difficulty)'}';
  }).join(' / ');
}

String _templateQuestionTypeLabel(String questionType) {
  switch (questionType) {
    case 'true_false':
      return 'True / False';
    case 'short_answer':
      return 'Short Answer';
    case 'essay':
      return 'Essay';
    case 'multi_select':
      return 'Multi-Select';
    case 'fill_in_the_blank':
    case 'fill_in_blank':
      return 'Fill in the Blank';
    case 'numeric':
      return 'Numeric';
    case 'code':
      return 'Code';
    default:
      return 'Multiple Choice';
  }
}

String _shortTemplateQuestionTypeLabel(String questionType) {
  switch (questionType) {
    case 'true_false':
      return 'TF';
    case 'short_answer':
      return 'SA';
    case 'essay':
      return 'Essay';
    case 'multi_select':
      return 'MS';
    case 'fill_in_the_blank':
    case 'fill_in_blank':
      return 'Blank';
    case 'numeric':
      return 'Num';
    case 'code':
      return 'Code';
    default:
      return 'MCQ';
  }
}

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
          const SizedBox(height: 6),
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ScopeModeOption(
              title: 'Topics / Subtopics',
              subtitle: selectedTopicCount == 0 ? 'Required' : '$selectedTopicCount selected',
              selected: mode == _ExamScopeMode.topics,
              onTap: () => onChanged(_ExamScopeMode.topics),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ScopeModeOption(
              title: 'Learning Outcomes',
              subtitle: selectedOutcomeCount == 0 ? 'Required' : '$selectedOutcomeCount selected',
              selected: mode == _ExamScopeMode.outcomes,
              onTap: () => onChanged(_ExamScopeMode.outcomes),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeModeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ScopeModeOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: selected ? AppColors.borderGray : Colors.transparent),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
              : const [],
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
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
                      color: selected ? AppColors.textTitle : AppColors.textMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
      title: 'Select topics / subtopics',
      subtitle: visibleSelectedIds.isEmpty
          ? 'Required. Pick one or more topics/subtopics.'
          : '${visibleSelectedIds.length} selected',
      onSelectAll: visibleIds.isEmpty ? null : () => onChanged(visibleIds),
      onClear: visibleSelectedIds.isEmpty ? null : () => onChanged(<int>{}),
      child: targets.isEmpty
          ? const _SetupPickerEmpty(message: 'No topics found for the selected module/material.')
          : SizedBox(
              height: 292,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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

                    Set<int> branchIds(_TopicTarget target) {
                      final result = <int>{target.topic.id};
                      void collect(int parentId) {
                        for (final child in childrenByParent[parentId] ?? const <_TopicTarget>[]) {
                          result.add(child.topic.id);
                          collect(child.topic.id);
                        }
                      }
                      collect(target.topic.id);
                      return result;
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

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(7),
                            onTap: () => toggleBranch(target),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(6 + (depth * 22), 3, 6, 3),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: Checkbox(
                                      value: checked,
                                      tristate: true,
                                      onChanged: (_) => toggleBranch(target),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  if (depth > 0) ...[
                                    Icon(Icons.subdirectory_arrow_right_rounded, size: 15, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                  ] else if (hasChildren) ...[
                                    Icon(Icons.account_tree_outlined, size: 15, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                  ],
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
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        if (hasChildren)
                                          Text(
                                            '${children.length} subtopic${children.length == 1 ? '' : 's'}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 10.7,
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

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
                            child: Text(
                              groupLabels[entry.key] ?? 'Material',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
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
  final List<_FilterOption> outcomes;
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
    final allIds = outcomes.map((outcome) => outcome.id).toSet();
    return _SetupPickerFrame(
      title: 'Select learning outcomes',
      subtitle: selectedOutcomeIds.isEmpty ? 'Required. Pick one or more learning outcomes.' : '${selectedOutcomeIds.length} selected',
      onSelectAll: allIds.isEmpty ? null : () => onChanged(allIds),
      onClear: selectedOutcomeIds.isEmpty ? null : () => onChanged(<int>{}),
      child: outcomes.isEmpty
          ? const _SetupPickerEmpty(message: 'No learning outcomes found for this course yet.')
          : SizedBox(
              height: 276,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: outcomes.map((outcome) {
                    final selected = selectedOutcomeIds.contains(outcome.id);
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        final next = Set<int>.from(selectedOutcomeIds);
                        selected ? next.remove(outcome.id) : next.add(outcome.id);
                        onChanged(next);
                      },
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 210, maxWidth: 340),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primarySoft : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: selected ? AppColors.primary.withOpacity(0.38) : AppColors.borderGray),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              size: 16,
                              color: selected ? AppColors.primary : AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                outcome.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textTitle,
                                  fontSize: 12.2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
                        fontSize: 12.7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
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
          const SizedBox(height: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SetupInlineSummary extends StatelessWidget {
  final int matchingCount;
  final int targetCount;
  final int durationMinutes;
  final bool publishAfterSave;

  const _SetupInlineSummary({
    required this.matchingCount,
    required this.targetCount,
    required this.durationMinutes,
    required this.publishAfterSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        children: [
          Expanded(child: _SetupSummaryText(label: 'Matching', value: '$matchingCount')),
          _SetupSummaryDivider(),
          Expanded(child: _SetupSummaryText(label: 'Target', value: '$targetCount')),
          _SetupSummaryDivider(),
          Expanded(child: _SetupSummaryText(label: 'Duration', value: '$durationMinutes min')),
          _SetupSummaryDivider(),
          Expanded(child: _SetupSummaryText(label: 'Mode', value: publishAfterSave ? 'Publish' : 'Draft')),
        ],
      ),
    );
  }
}

class _SetupSummaryText extends StatelessWidget {
  final String label;
  final String value;

  const _SetupSummaryText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textTitle,
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SetupSummaryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: AppColors.borderGray,
    );
  }
}

class _StartTemplateDigest extends StatelessWidget {
  final ExamTemplateModel template;

  const _StartTemplateDigest({required this.template});

  @override
  Widget build(BuildContext context) {
    final mode = template.publishAfterSave ? 'Publish after save' : 'Save as draft';
    final distribution = _templateDistributionText(template);
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${template.questionCount} questions • ${template.durationMinutes} min${distribution.isEmpty ? '' : ' • $distribution'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.input.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '${template.maxAttempts} attempt${template.maxAttempts == 1 ? '' : 's'} • ${template.passingScore.toStringAsFixed(0)}% pass • $mode',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.mutedSmall.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StartMatchSummary extends StatelessWidget {
  final int matchingCount;
  final int targetCount;
  final bool publishAfterSave;

  const _StartMatchSummary({
    required this.matchingCount,
    required this.targetCount,
    required this.publishAfterSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        children: [
          _StartMiniStat(label: 'Matching', value: '$matchingCount'),
          _StartDivider(),
          _StartMiniStat(label: 'Target', value: '$targetCount'),
          _StartDivider(),
          _StartMiniStat(label: 'Mode', value: publishAfterSave ? 'Publish' : 'Draft'),
        ],
      ),
    );
  }
}

class _StartMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _StartMiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppText.mutedSmall.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: AppText.input.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: AppColors.borderGray,
    );
  }
}

class _StartSelect<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _StartSelect({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          menuMaxHeight: 320,
          hint: items.isNotEmpty ? items.first.child : null,
          items: items,
          onChanged: onChanged,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.muted, size: 22),
          style: AppText.input.copyWith(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.fieldBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            hintStyle: AppText.hint,
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: AppColors.borderGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: AppColors.dangerText),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: AppColors.dangerText, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _StartSummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _StartSummaryCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textTitle, fontWeight: FontWeight.w900, fontSize: 13)),
                const SizedBox(height: 3),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700, fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StartMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StartMetric({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 9),
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w800))),
          Text(value, style: TextStyle(color: AppColors.textTitle, fontSize: 17, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _StartPreview extends StatelessWidget {
  final List<QuestionModel> questions;

  const _StartPreview({required this.questions});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Matching question sample'.toUpperCase(), style: TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
          const SizedBox(height: 10),
          if (questions.isEmpty)
            Text('No question sample available.', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700))
          else
            ...questions.map((question) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 15, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          question.text.replaceAll('\n', ' '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.textTitle, fontSize: 12.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),),
        ],
      ),
    );
  }
}

class _QuestionBankHeader extends StatelessWidget {
  final bool loading;
  final bool canCreateExam;
  final int totalQuestionsCount;
  final int visibleQuestionsCount;
  final int examReadyCount;
  final VoidCallback onRefresh;
  final VoidCallback onCreateExam;

  const _QuestionBankHeader({
    required this.loading,
    required this.canCreateExam,
    required this.totalQuestionsCount,
    required this.visibleQuestionsCount,
    required this.examReadyCount,
    required this.onRefresh,
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
      body = _QuestionRows(
        questions: questions,
        topicTargetByTopicId: topicTargetByTopicId,
        selectedQuestionId: selectedQuestionId,
        pageStartIndex: pageStartIndex,
        onSelectQuestion: onSelectQuestion,
        onEditQuestion: (question) => onEditQuestion(question, topicTargets),
        onDeleteUnavailable: onDeleteUnavailable,
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
            blurRadius: 22,
            offset: const Offset(0, 10),
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
            blurRadius: 18,
            offset: const Offset(0, 8),
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

class _QuestionReviewDialog extends ConsumerStatefulWidget {
  final int courseId;
  final QuestionModel question;
  final List<_TopicTarget> topicTargets;

  const _QuestionReviewDialog({
    required this.courseId,
    required this.question,
    required this.topicTargets,
  });

  @override
  ConsumerState<_QuestionReviewDialog> createState() => _QuestionReviewDialogState();
}

class _QuestionReviewDialogState extends ConsumerState<_QuestionReviewDialog> {
  late QuestionModel _question;
  bool _loadingDetails = false;
  String? _detailsError;

  @override
  void initState() {
    super.initState();
    _question = widget.question;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFullQuestion());
  }

  Future<void> _loadFullQuestion() async {
    final questionId = widget.question.remoteId ?? int.tryParse(widget.question.id);
    if (questionId == null || questionId <= 0) return;
    if (!mounted) return;
    setState(() {
      _loadingDetails = true;
      _detailsError = null;
    });
    try {
      final hydrated = await ref.read(questionsApiProvider).getQuestion(
            courseId: widget.courseId,
            questionId: questionId,
          );
      if (!mounted) return;
      setState(() {
        _question = hydrated;
        _loadingDetails = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailsError = mapApiFailure(e).message;
        _loadingDetails = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final compact = size.width < 760;
    return Dialog(
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 42,
        vertical: compact ? 18 : 34,
      ),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 940,
          maxHeight: size.height * 0.88,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: AppColors.cardBg,
            child: _QuestionInspector(
              question: _question,
              topicTargets: widget.topicTargets,
              loadingDetails: _loadingDetails,
              detailsError: _detailsError,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionInspector extends StatelessWidget {
  final QuestionModel? question;
  final List<_TopicTarget> topicTargets;
  final bool loadingDetails;
  final String? detailsError;
  final VoidCallback? onClose;

  const _QuestionInspector({
    required this.question,
    required this.topicTargets,
    this.loadingDetails = false,
    this.detailsError,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final q = question;
    if (q == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        color: AppColors.cardBg,
        child: Center(
          child: Text(
            'Select a question to review the answer and details.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, height: 1.5, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    final target = _targetForQuestion(topicTargets, q);
    final topicPath = _topicPathFromTarget(target, q);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 16, 18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF145CCB), Color(0xFF137FEC), Color(0xFF22C1F1)],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.22)),
                ),
                child: const Icon(Icons.fact_check_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Question review',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$topicPath • ${q.typeLabel} • ${q.difficultyLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (loadingDetails) ...[
                  const _InspectorNotice(
                    icon: Icons.sync_rounded,
                    message: 'Loading the full question record from the backend...',
                    tone: _InspectorNoticeTone.info,
                  ),
                  const SizedBox(height: 14),
                ],
                if (detailsError != null) ...[
                  _InspectorNotice(
                    icon: Icons.warning_amber_rounded,
                    message: 'Full question details could not be loaded. Showing the cached row data. ${detailsError!}',
                    tone: _InspectorNoticeTone.warning,
                  ),
                  const SizedBox(height: 14),
                ],
                _InspectorSection(
                  title: 'Question',
                  child: Text(
                    q.text,
                    style: TextStyle(
                      color: AppColors.textTitle,
                      fontSize: 17,
                      height: 1.45,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.15,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _InspectorSection(
                  title: 'Answer',
                  child: _AnswerPreview(question: q),
                ),
                if (q.explanation != null && q.explanation!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _InspectorSection(
                    title: 'Explanation',
                    child: _MutedBox(q.explanation!),
                  ),
                ],
                if (q.gradingRubric != null) ...[
                  const SizedBox(height: 14),
                  _InspectorSection(
                    title: 'Grading rubric',
                    child: _MutedBox(_jsonish(q.gradingRubric)),
                  ),
                ],
                const SizedBox(height: 14),
                _InspectorSection(
                  title: 'Learning outcomes',
                  child: q.learningOutcomes.isEmpty
                      ? const _MutedBox('No learning outcome is linked to this question.')
                      : Column(
                          children: q.learningOutcomes
                              .map((outcome) => _OutcomeLine(title: outcome.title))
                              .toList(),
                        ),
                ),
                if (q.tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _InspectorSection(
                    title: 'Tags',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: q.tags.map((tag) => _TagChip(tag)).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}



enum _InspectorNoticeTone { info, warning }

class _InspectorNotice extends StatelessWidget {
  final IconData icon;
  final String message;
  final _InspectorNoticeTone tone;

  const _InspectorNotice({
    required this.icon,
    required this.message,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final warning = tone == _InspectorNoticeTone.warning;
    final fg = warning ? AppColors.warningText : AppColors.primary;
    final bg = warning ? AppColors.warningSoftBg : AppColors.primarySoft;
    final border = warning ? AppColors.warningBorder : AppColors.primary.withOpacity(0.22);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionMetadataGrid extends StatelessWidget {
  final QuestionModel question;
  final _TopicTarget? target;
  final String topicPath;

  const _QuestionMetadataGrid({
    required this.question,
    required this.target,
    required this.topicPath,
  });

  @override
  Widget build(BuildContext context) {
    final q = question;
    final items = <_QuestionMetadataItem>[
      _QuestionMetadataItem(icon: Icons.tag_rounded, label: 'Question ID', value: q.remoteId?.toString() ?? q.id),
      _QuestionMetadataItem(icon: Icons.book_outlined, label: 'Course ID', value: _optionalInt(q.courseId)),
      _QuestionMetadataItem(icon: Icons.view_module_outlined, label: 'Module', value: _firstText([target?.module.title, q.moduleName])),
      _QuestionMetadataItem(icon: Icons.description_outlined, label: 'Material', value: _firstText([target?.material.displayTitle, q.materialName])),
      _QuestionMetadataItem(icon: Icons.account_tree_outlined, label: 'Topic', value: topicPath),
      _QuestionMetadataItem(icon: Icons.category_outlined, label: 'Type', value: q.typeLabel),
      _QuestionMetadataItem(icon: Icons.speed_rounded, label: 'Difficulty', value: q.difficultyLabel),
      _QuestionMetadataItem(icon: Icons.bolt_rounded, label: 'Source', value: _sourceLabel(q.source)),
      _QuestionMetadataItem(icon: Icons.verified_outlined, label: 'Approval', value: _approvalLabel(q.approvalStatus)),
      _QuestionMetadataItem(icon: Icons.score_outlined, label: 'Max score', value: '${q.maxScore}'),
      _QuestionMetadataItem(icon: Icons.auto_awesome_outlined, label: 'Auto gradable', value: q.autoGradable ? 'Yes' : 'No'),
      _QuestionMetadataItem(icon: Icons.insights_rounded, label: 'Usage', value: _usageLabel(q.usageCount)),
      _QuestionMetadataItem(icon: Icons.trending_up_rounded, label: 'Success rate', value: _successRate(q.successRate)),
      _QuestionMetadataItem(icon: Icons.timer_outlined, label: 'Avg time', value: _seconds(q.averageTimeSeconds)),
      _QuestionMetadataItem(icon: Icons.person_outline_rounded, label: 'Created by', value: _optionalInt(q.createdBy)),
      _QuestionMetadataItem(icon: Icons.event_outlined, label: 'Created', value: _shortDate(q.createdAt)),
      _QuestionMetadataItem(icon: Icons.update_rounded, label: 'Updated', value: _shortDate(q.updatedAt)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.maxWidth < 620;
        final width = tight ? constraints.maxWidth : (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map((item) => SizedBox(
                    width: width,
                    child: _QuestionMetadataTile(item: item),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _QuestionMetadataItem {
  final IconData icon;
  final String label;
  final String value;

  const _QuestionMetadataItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _QuestionMetadataTile extends StatelessWidget {
  final _QuestionMetadataItem item;

  const _QuestionMetadataTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.6,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textTitle,
                    fontSize: 12.4,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
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
class _InspectorSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _InspectorSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.65,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _AnswerPreview extends StatelessWidget {
  final QuestionModel question;

  const _AnswerPreview({required this.question});

  @override
  Widget build(BuildContext context) {
    if (question.options.isNotEmpty) {
      final hasCorrect = question.options.asMap().entries.any((entry) => _isCorrectOption(question, entry.value, index: entry.key));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List<Widget>.generate(question.options.length, (index) {
            final option = question.options[index];
            final correct = _isCorrectOption(question, option, index: index);
            return _AnswerOptionCard(
              index: index,
              option: option,
              correct: correct,
              multiSelect: question.type == QuestionType.multiSelect,
            );
          }),
          if (!hasCorrect && _answerText(question).isNotEmpty) ...[
            const SizedBox(height: 4),
            _InspectorNotice(
              icon: Icons.info_outline_rounded,
              message: 'Stored expected answer: ${_answerText(question)}. It does not match any visible option id.',
              tone: _InspectorNoticeTone.warning,
            ),
          ],
        ],
      );
    }

    if (question.type == QuestionType.trueFalse) {
      final answer = question.correctBool ?? (question.expectedAnswer?.toLowerCase() == 'true' ? true : question.expectedAnswer?.toLowerCase() == 'false' ? false : null);
      if (answer != null) {
        return Row(
          children: [
            Expanded(child: _BooleanAnswerPreview(label: 'True', selected: answer == true)),
            const SizedBox(width: 10),
            Expanded(child: _BooleanAnswerPreview(label: 'False', selected: answer == false)),
          ],
        );
      }
    }

    final answer = _answerText(question);
    return _MutedBox(answer.isEmpty ? 'No answer stored for this question.' : answer);
  }
}

class _AnswerOptionCard extends StatelessWidget {
  final int index;
  final QuestionOption option;
  final bool correct;
  final bool multiSelect;

  const _AnswerOptionCard({
    required this.index,
    required this.option,
    required this.correct,
    required this.multiSelect,
  });

  @override
  Widget build(BuildContext context) {
    final label = String.fromCharCode(65 + index);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: correct ? AppColors.successBg : AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: correct ? AppColors.greenBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: correct ? AppColors.successText : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: correct ? AppColors.successText : AppColors.border),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: correct ? Colors.white : AppColors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  correct
                      ? Icons.check_circle_rounded
                      : multiSelect
                          ? Icons.check_box_outline_blank_rounded
                          : Icons.radio_button_unchecked_rounded,
                  size: 17,
                  color: correct ? AppColors.successText : AppColors.textHint,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  option.text,
                  style: TextStyle(
                    color: correct ? AppColors.successText : AppColors.textTitle,
                    fontSize: 12.8,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (correct)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.62),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.greenBorder),
                  ),
                  child: Text(
                    'Correct',
                    style: TextStyle(
                      color: AppColors.successText,
                      fontSize: 10.6,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          if ((option.explanation ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 45),
              child: Text(
                option.explanation!.trim(),
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BooleanAnswerPreview extends StatelessWidget {
  final String label;
  final bool selected;

  const _BooleanAnswerPreview({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.successBg : AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? AppColors.greenBorder : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: selected ? AppColors.successText : AppColors.textHint,
          ),
          const SizedBox(width: 9),
          Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.successText : AppColors.textTitle,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorKv extends StatelessWidget {
  final String label;
  final String value;

  const _InspectorKv({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textTitle,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutcomeLine extends StatelessWidget {
  final String title;

  const _OutcomeLine({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.track_changes_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: AppColors.textTitle, fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _MutedBox extends StatelessWidget {
  final String text;

  const _MutedBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12.5,
          height: 1.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EditQuestionDialog extends ConsumerStatefulWidget {
  final int courseId;
  final QuestionModel question;
  final List<_TopicTarget> topicTargets;

  const _EditQuestionDialog({
    required this.courseId,
    required this.question,
    required this.topicTargets,
  });

  @override
  ConsumerState<_EditQuestionDialog> createState() => _EditQuestionDialogState();
}

class _EditQuestionDialogState extends ConsumerState<_EditQuestionDialog> {
  late final TextEditingController _questionController;
  late final TextEditingController _explanationController;
  late final TextEditingController _answerController;
  late final TextEditingController _tagsController;
  late QuestionDifficulty _difficulty;
  late int? _topicId;
  late List<_EditableOption> _options;
  late bool? _boolAnswer;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _questionController = TextEditingController(text: q.text);
    _explanationController = TextEditingController(text: q.explanation ?? '');
    _answerController = TextEditingController(text: _initialAnswerText(q));
    _tagsController = TextEditingController(text: q.tags.join(', '));
    _difficulty = q.difficulty;
    _topicId = q.topicId ?? (widget.topicTargets.isNotEmpty ? widget.topicTargets.first.topic.id : null);
    _boolAnswer = q.correctBool;
    _options = _initialOptions(q);
  }

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
    _answerController.dispose();
    _tagsController.dispose();
    for (final option in _options) {
      option.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final qid = widget.question.remoteId ?? int.tryParse(widget.question.id);
    if (qid == null || qid <= 0) {
      setState(() => _error = 'This question does not have a backend id.');
      return;
    }

    final validation = _validate();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final payload = _buildPayload();
      await ref.read(questionsApiProvider).updateQuestion(
            courseId: widget.courseId,
            questionId: qid,
            payload: payload,
          );
      final hydrated = await ref.read(questionsApiProvider).getQuestion(
            courseId: widget.courseId,
            questionId: qid,
          );
      if (!mounted) return;
      Navigator.of(context).pop(hydrated);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = mapApiFailure(e).message;
      });
    }
  }

  String? _validate() {
    if (_questionController.text.trim().isEmpty) return 'Question text is required.';
    if (_topicId == null || _topicId! <= 0) return 'A topic is required.';
    final type = widget.question.type;
    if (!_backendEditableType(type)) {
      return '${type.label} is not editable with the current backend question contract.';
    }
    if (type == QuestionType.multipleChoice || type == QuestionType.multiSelect) {
      final cleanOptions = _options.where((option) => option.controller.text.trim().isNotEmpty).toList();
      if (cleanOptions.length < 2) return 'At least two non-empty options are required.';
      if (!cleanOptions.any((option) => option.correct)) return 'Select at least one correct option.';
      if (type == QuestionType.multipleChoice && cleanOptions.where((option) => option.correct).length != 1) {
        return 'Multiple choice needs exactly one correct option.';
      }
    }
    if (type == QuestionType.trueFalse && _boolAnswer == null) return 'Select True or False.';
    if (type == QuestionType.shortAnswer && _answerController.text.trim().isEmpty) {
      return 'Expected answer is required for short answer questions.';
    }
    return null;
  }

  UpdateQuestionPayload _buildPayload() {
    final type = widget.question.type;
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    if (type == QuestionType.multipleChoice || type == QuestionType.multiSelect) {
      final cleanOptions = _options.where((option) => option.controller.text.trim().isNotEmpty).toList();
      final optionIds = List.generate(cleanOptions.length, (index) => index.toString());
      final createOptions = List.generate(cleanOptions.length, (index) {
        return CreateQuestionOption(id: optionIds[index], text: cleanOptions[index].controller.text.trim());
      });
      final correctIds = <String>[];
      for (var i = 0; i < cleanOptions.length; i++) {
        if (cleanOptions[i].correct) correctIds.add(optionIds[i]);
      }
      return UpdateQuestionPayload(
        topicId: _topicId,
        questionText: _questionController.text.trim(),
        difficulty: _difficulty.backendValue,
        explanation: _explanationController.text.trim(),
        options: createOptions,
        expectedAnswer: type == QuestionType.multiSelect ? correctIds : correctIds.first,
        tags: tags,
      );
    }

    if (type == QuestionType.trueFalse) {
      return UpdateQuestionPayload(
        topicId: _topicId,
        questionText: _questionController.text.trim(),
        difficulty: _difficulty.backendValue,
        explanation: _explanationController.text.trim(),
        expectedAnswer: (_boolAnswer ?? false).toString(),
        tags: tags,
      );
    }

    return UpdateQuestionPayload(
      topicId: _topicId,
      questionText: _questionController.text.trim(),
      difficulty: _difficulty.backendValue,
      explanation: _explanationController.text.trim(),
      expectedAnswer: _answerController.text.trim(),
      tags: tags,
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final editable = _backendEditableType(q.type);
    final size = MediaQuery.of(context).size;
    final compact = size.width < 900;
    final width = compact ? size.width * 0.94 : 860.0;
    final height = size.height < 760 ? size.height * 0.94 : size.height * 0.86;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 32,
        vertical: compact ? 18 : 36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width,
            maxHeight: height.clamp(640.0, 820.0).toDouble(),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.pageBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Question',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textTitle,
                                height: 1.22,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              editable
                                  ? 'Update this saved assessment item using the same authoring workspace.'
                                  : '${q.typeLabel} cannot be updated by the current backend question contract.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _saving ? null : () => Navigator.of(context).pop(),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderGray),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_error != null) ...[
                                    _EditErrorBanner(message: _error!),
                                    const SizedBox(height: 16),
                                  ],
                                  _buildMetaSection(q, editable),
                                  const SizedBox(height: 18),
                                  _buildQuestionTextSection(q, editable),
                                  const SizedBox(height: 18),
                                  _buildAnswerSection(q, editable),
                                  const SizedBox(height: 18),
                                  _buildExplanationSection(editable),
                                  const SizedBox(height: 18),
                                  _buildTagsSection(editable),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Row(
                    children: [
                      const _TinyMeta(icon: Icons.lock_outline_rounded, label: 'Type locked'),
                      const Spacer(),
                      TextButton(
                        onPressed: _saving ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _saving || !editable ? null : _save,
                        style: _editPrimaryButtonStyle(),
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: Text(_saving ? 'Saving...' : 'Save Changes'),
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

  Widget _buildMetaSection(QuestionModel q, bool editable) {
    Widget topicField() => _TopicSelectorField(
          value: _topicId,
          targets: widget.topicTargets,
          fallbackTopicName: q.topicName,
          enabled: !_saving && editable,
          onChanged: (value) => setState(() => _topicId = value),
        );

    Widget difficultyField() => AppModernDropdown<QuestionDifficulty>(
          label: 'Difficulty',
          value: _difficulty,
          icon: Icons.signal_cellular_alt_rounded,
          items: const <DropdownMenuItem<QuestionDifficulty>>[
            DropdownMenuItem<QuestionDifficulty>(
              value: QuestionDifficulty.easy,
              child: Text('Easy'),
            ),
            DropdownMenuItem<QuestionDifficulty>(
              value: QuestionDifficulty.medium,
              child: Text('Medium'),
            ),
            DropdownMenuItem<QuestionDifficulty>(
              value: QuestionDifficulty.hard,
              child: Text('Hard'),
            ),
          ],
          onChanged: (value) {
            if (_saving || !editable || value == null) return;
            setState(() => _difficulty = value);
          },
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              topicField(),
              const SizedBox(height: 16),
              difficultyField(),
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 2, child: topicField()),
            const SizedBox(width: 16),
            Expanded(child: difficultyField()),
          ],
        );
      },
    );
  }


  Widget _buildQuestionTextSection(QuestionModel q, bool editable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _EditSectionLabel('Question Text')),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                q.typeLabel,
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBg,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    const _EditToolbarButton(label: 'B'),
                    const SizedBox(width: 4),
                    const _EditToolbarButton(label: 'I', italic: true),
                    const SizedBox(width: 4),
                    const _EditToolbarButton(label: 'U', underlined: true),
                    const SizedBox(width: 8),
                    Icon(Icons.format_list_bulleted_rounded, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Icon(Icons.image_outlined, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Icon(Icons.code_rounded, size: 16, color: AppColors.textMuted),
                    const Spacer(),
                    if (_topicId != null)
                      Flexible(
                        child: Text(
                          _topicPickerLabel(widget.topicTargets, _topicId) ?? q.topicName ?? 'Selected topic',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              TextField(
                controller: _questionController,
                enabled: !_saving && editable,
                minLines: 5,
                maxLines: 5,
                decoration: _editInputDecoration(
                  'Enter your question here... e.g. What is the primary function of the mitochondria?',
                ).copyWith(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerSection(QuestionModel q, bool editable) {
    if (q.type == QuestionType.multipleChoice || q.type == QuestionType.multiSelect) {
      return _buildMultipleChoiceSection(q.type, editable);
    }
    if (q.type == QuestionType.trueFalse) {
      return _buildTrueFalseSection(editable);
    }
    return _buildWrittenAnswerSection(q.type, editable);
  }

  Widget _buildMultipleChoiceSection(QuestionType type, bool editable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _EditSectionLabel('Answer Options'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                type == QuestionType.multiSelect ? 'Select all correct answers' : 'Select the correct answer',
                style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w500),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: !_saving && editable && _options.length < 8
                  ? () {
                      setState(() {
                        _options.add(_EditableOption(controller: TextEditingController(), correct: false));
                      });
                    }
                  : null,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: const Text('Add another option'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List<Widget>.generate(_options.length, (index) {
          final option = _options[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 26),
                  child: type == QuestionType.multiSelect
                      ? Checkbox(
                          value: option.correct,
                          onChanged: !_saving && editable
                              ? (value) {
                                  setState(() => option.correct = value ?? false);
                                }
                              : null,
                        )
                      : InkWell(
                          onTap: !_saving && editable
                              ? () {
                                  setState(() {
                                    for (var i = 0; i < _options.length; i++) {
                                      _options[i].correct = i == index;
                                    }
                                  });
                                }
                              : null,
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: option.correct ? AppColors.primary : AppColors.borderSoft,
                                width: option.correct ? 5 : 1.5,
                              ),
                              color: AppColors.cardBg,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Option ${String.fromCharCode(65 + index)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: option.controller,
                        enabled: !_saving && editable,
                        decoration: _editInputDecoration(index == 0 ? 'Powerhouse of the cell' : 'Enter answer option'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: IconButton(
                    onPressed: !_saving && editable && _options.length > 2
                        ? () {
                            final removed = _options.removeAt(index);
                            removed.controller.dispose();
                            setState(() {});
                          }
                        : null,
                    icon: const Icon(Icons.delete_outline_rounded, size: 19),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrueFalseSection(bool editable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EditSectionLabel('Correct Answer'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _EditBooleanAnswerCard(
                label: 'True',
                selected: _boolAnswer ?? false,
                enabled: !_saving && editable,
                onTap: () => setState(() => _boolAnswer = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _EditBooleanAnswerCard(
                label: 'False',
                selected: _boolAnswer == false,
                enabled: !_saving && editable,
                onTap: () => setState(() => _boolAnswer = false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWrittenAnswerSection(QuestionType type, bool editable) {
    final hint = type == QuestionType.essay
        ? 'Enter the expected problem-solving answer or rubric.'
        : 'Enter the expected short answer.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EditSectionLabel('Expected Answer'),
        const SizedBox(height: 10),
        TextField(
          controller: _answerController,
          enabled: !_saving && editable,
          maxLines: 4,
          decoration: _editInputDecoration(hint),
        ),
      ],
    );
  }

  Widget _buildExplanationSection(bool editable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EditSectionLabel('Explanation (Optional)'),
        const SizedBox(height: 10),
        TextField(
          controller: _explanationController,
          enabled: !_saving && editable,
          maxLines: 3,
          decoration: _editInputDecoration('Explain why the correct answer is correct...'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'This will be shown to students after they submit their answer.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagsSection(bool editable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EditSectionLabel('Tags (Optional)'),
        const SizedBox(height: 10),
        TextField(
          controller: _tagsController,
          enabled: !_saving && editable,
          decoration: _editInputDecoration('Tags, comma separated'),
        ),
      ],
    );
  }

  ButtonStyle _editPrimaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    );
  }

  InputDecoration _editInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textHint,
      ),
      filled: true,
      fillColor: AppColors.surfaceBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    );
  }

}

class _LockedQuestionTypeTabs extends StatelessWidget {
  final QuestionType type;

  const _LockedQuestionTypeTabs({required this.type});

  static const _types = <QuestionType>[
    QuestionType.multipleChoice,
    QuestionType.multiSelect,
    QuestionType.trueFalse,
    QuestionType.shortAnswer,
    QuestionType.essay,
  ];

  @override
  Widget build(BuildContext context) {
    final displayedTypes = _types.contains(type) ? _types : <QuestionType>[..._types, type];
    return Container(
      height: 62,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderGray)),
      ),
      child: Row(
        children: displayedTypes.map((item) {
          final selected = item == type;
          return Expanded(
            child: Container(
              height: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EditErrorBanner extends StatelessWidget {
  final String message;

  const _EditErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: AppColors.dangerText,
          fontSize: 12.5,
          height: 1.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EditSectionLabel extends StatelessWidget {
  final String text;

  const _EditSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textTitle,
      ),
    );
  }
}

class _EditToolbarButton extends StatelessWidget {
  final String label;
  final bool italic;
  final bool underlined;

  const _EditToolbarButton({
    required this.label,
    this.italic = false,
    this.underlined = false,
  });

  @override
  Widget build(BuildContext context) {
    var style = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      color: AppColors.textMuted,
    );
    if (italic) style = style.copyWith(fontStyle: FontStyle.italic);
    if (underlined) style = style.copyWith(decoration: TextDecoration.underline);
    return Text(label, style: style);
  }
}

class _EditBooleanAnswerCard extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _EditBooleanAnswerCard({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: selected ? AppColors.infoBg : AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.borderSoft,
                  width: selected ? 5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: AppColors.textTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicSelectorField extends StatelessWidget {
  final int? value;
  final List<_TopicTarget> targets;
  final String? fallbackTopicName;
  final bool enabled;
  final ValueChanged<int?> onChanged;

  const _TopicSelectorField({
    required this.value,
    required this.targets,
    required this.fallbackTopicName,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label = _topicPickerLabel(targets, value) ?? fallbackTopicName ?? 'No topic selected';
    Future<void> openPicker() async {
      if (!enabled || targets.isEmpty) return;
      final selected = await showDialog<int>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.30),
        builder: (_) => _TopicPickerDialog(
          selectedTopicId: value,
          targets: targets,
        ),
      );
      if (selected != null) onChanged(selected);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Topic',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppColors.textGray,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: targets.isEmpty ? null : openPicker,
          child: Container(
            height: 44,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: targets.isEmpty ? AppColors.surfaceBg : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: targets.isEmpty ? AppColors.border : AppColors.primary.withOpacity(0.45)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_tree_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: targets.isEmpty ? AppColors.textMuted : AppColors.textGray,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.unfold_more_rounded, color: AppColors.textMuted, size: 19),
              ],
            ),
          ),
        ),
      ],
    );
  }

}

class _TopicPickerDialog extends StatefulWidget {
  final int? selectedTopicId;
  final List<_TopicTarget> targets;

  const _TopicPickerDialog({required this.selectedTopicId, required this.targets});

  @override
  State<_TopicPickerDialog> createState() => _TopicPickerDialogState();
}

class _TopicPickerDialogState extends State<_TopicPickerDialog> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = widget.targets.where((target) {
      if (query.isEmpty) return true;
      return <String>[
        target.topic.title,
        target.parentTopicTitle ?? '',
        target.material.displayTitle,
        target.module.title,
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
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 14, 16),
                child: Row(
                  children: [
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
                        children: [
                          Text(
                            'Choose target topic',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textTitle,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Pick the exact topic or subtopic where this question belongs.',
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
                      onPressed: () => Navigator.of(context).pop(),
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
                    controller: _search,
                    onChanged: (value) => setState(() => _query = value),
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
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No matching topics found.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        children: _buildGroupedTargetRows(context, filtered),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedTargetRows(BuildContext context, List<_TopicTarget> targets) {
    final rows = <Widget>[];
    String? currentModule;
    String? currentMaterial;

    for (final target in targets) {
      if (target.module.title != currentModule) {
        currentModule = target.module.title;
        rows.add(_groupHeader(Icons.school_outlined, currentModule));
        currentMaterial = null;
      }
      if (target.material.displayTitle != currentMaterial) {
        currentMaterial = target.material.displayTitle;
        rows.add(_groupHeader(Icons.description_outlined, currentMaterial, indent: 14));
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(left: 28, top: 6),
          child: _treeOption(
            context,
            selected: widget.selectedTopicId == target.topic.id,
            icon: target.parentTopicTitle == null ? Icons.topic_outlined : Icons.subdirectory_arrow_right_rounded,
            title: target.parentTopicTitle == null ? target.topic.title : '${target.parentTopicTitle} / ${target.topic.title}',
            subtitle: '${target.module.title} • ${target.material.displayTitle} • ${target.parentTopicTitle == null ? 'Topic' : 'Subtopic'}',
            onTap: () => Navigator.of(context).pop(target.topic.id),
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
        children: [
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
          border: Border.all(
            color: selected ? AppColors.primary.withOpacity(0.50) : AppColors.borderGray,
          ),
        ),
        child: Row(
          children: [
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
                children: [
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

class _TopicPickerRow extends StatelessWidget {
  final _TopicTarget target;
  final bool selected;
  final VoidCallback onTap;

  const _TopicPickerRow({required this.target, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.headerBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                selected ? Icons.check_rounded : Icons.topic_outlined,
                color: selected ? Colors.white : AppColors.textMuted,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(target.topic.title, style: TextStyle(color: AppColors.textTitle, fontSize: 13.2, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    '${target.module.title} → ${target.material.displayTitle}${target.parentTopicTitle == null ? '' : ' → ${target.parentTopicTitle}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditOptionsPanel extends StatelessWidget {
  final QuestionType type;
  final List<_EditableOption> options;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _EditOptionsPanel({
    required this.type,
    required this.options,
    required this.enabled,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Answer options', style: TextStyle(color: AppColors.textTitle, fontWeight: FontWeight.w900)),
              ),
              TextButton.icon(
                onPressed: enabled && options.length < 8 ? onAdd : null,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add option'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(options.length, (index) {
            final option = options[index];
            final label = String.fromCharCode(65 + index);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  if (type == QuestionType.multiSelect)
                    Checkbox(
                      value: option.correct,
                      onChanged: enabled
                          ? (value) {
                              option.correct = value ?? false;
                              onChanged();
                            }
                          : null,
                    )
                  else
                    Radio<int>(
                      value: index,
                      groupValue: options.indexWhere((item) => item.correct),
                      onChanged: enabled
                          ? (value) {
                              if (value == null) return;
                              for (var i = 0; i < options.length; i++) {
                                options[i].correct = i == value;
                              }
                              onChanged();
                            }
                          : null,
                    ),
                  SizedBox(
                    width: 28,
                    child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: option.controller,
                      enabled: enabled,
                      onChanged: (_) => onChanged(),
                      decoration: _editDecoration('Option ${index + 1}'),
                    ),
                  ),
                  IconButton(
                    onPressed: enabled && options.length > 2 ? () => onRemove(index) : null,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            );
          }),
          Text(
            type == QuestionType.multiSelect
                ? 'Select every correct option.'
                : 'Select exactly one correct option.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TrueFalseEditor extends StatelessWidget {
  final bool? value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _TrueFalseEditor({required this.value, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Correct answer', style: TextStyle(color: AppColors.textTitle, fontWeight: FontWeight.w900)),
          ),
          ChoiceChip(
            selected: value ?? false,
            label: const Text('True'),
            onSelected: enabled ? (_) => onChanged(true) : null,
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            selected: value == false,
            label: const Text('False'),
            onSelected: enabled ? (_) => onChanged(false) : null,
          ),
        ],
      ),
    );
  }
}

class _EditableOption {
  final TextEditingController controller;
  bool correct;

  _EditableOption({required this.controller, required this.correct});
}

class _TopicTarget {
  final ModuleItem module;
  final MaterialItem material;
  final TopicItem topic;
  final String? parentTopicTitle;

  const _TopicTarget({
    required this.module,
    required this.material,
    required this.topic,
    this.parentTopicTitle,
  });
}

class _TypeBadge extends StatelessWidget {
  final String label;

  const _TypeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return _Badge(
      label: label,
      background: AppColors.badgeBlueBg,
      foreground: AppColors.badgeBlueFg,
      border: AppColors.badgeBlueBorder,
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final QuestionDifficulty diff;

  const _DifficultyBadge({required this.diff});

  @override
  Widget build(BuildContext context) {
    switch (diff) {
      case QuestionDifficulty.easy:
        return _Badge(
          label: 'Easy',
          background: AppColors.successBg,
          foreground: AppColors.successText,
          border: AppColors.greenBorder,
        );
      case QuestionDifficulty.medium:
        return _Badge(
          label: 'Medium',
          background: AppColors.warningSoftBg,
          foreground: AppColors.warningText,
          border: AppColors.warningBorder,
        );
      case QuestionDifficulty.hard:
        return _Badge(
          label: 'Hard',
          background: AppColors.dangerBg,
          foreground: AppColors.dangerText,
          border: AppColors.dangerBorder,
        );
    }
  }
}

class _SourceBadge extends StatelessWidget {
  final QuestionSource source;

  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    switch (source) {
      case QuestionSource.aiGenerated:
        return _Badge(
          label: 'AI generated',
          background: AppColors.purpleBg,
          foreground: AppColors.purpleText,
          border: AppColors.purpleBorder,
        );
      case QuestionSource.imported:
        return _Badge(
          label: 'Imported',
          background: AppColors.badgeIndigoBg,
          foreground: AppColors.badgeIndigoFg,
          border: AppColors.badgeIndigoBorder,
        );
      case QuestionSource.manual:
        return _Badge(
          label: 'Manual',
          background: AppColors.surfaceBg,
          foreground: AppColors.textMuted,
          border: AppColors.border,
        );
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color border;

  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: foreground, fontSize: 10.8, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _TinyMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TinyMeta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textHint),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: AppColors.textMuted, fontSize: 11.2, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _QuestionBankSkeleton extends StatelessWidget {
  const _QuestionBankSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: List.generate(
          7,
          (index) => Container(
            margin: EdgeInsets.only(bottom: index == 6 ? 0 : 10),
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.surfaceBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionBankEmpty extends StatelessWidget {
  final bool hasQuestions;

  const _QuestionBankEmpty({required this.hasQuestions});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.quiz_outlined, size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              hasQuestions ? 'No questions match the current filters' : 'No saved questions yet',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textTitle, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Text(
                hasQuestions
                    ? 'Adjust the search term, learning outcome, or question type to reveal more questions.'
                    : 'Questions will appear here after they are saved from the material generation workspace or manual authoring flow.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionBankError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _QuestionBankError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 42, color: AppColors.dangerText),
            const SizedBox(height: 14),
            Text(
              'Could not load question bank',
              style: TextStyle(color: AppColors.textTitle, fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _editDecoration(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surfaceBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
      ),
    );


bool _isCorrectOption(QuestionModel question, QuestionOption option, {int? index}) {
  if (option.isCorrect) return true;
  if (question.correctOptionId != null && question.correctOptionId == option.id) return true;

  final normalizedTokens = _expectedAnswerTokens(question)
      .map((token) => token.trim().toLowerCase())
      .where((token) => token.isNotEmpty)
      .toSet();
  if (normalizedTokens.isEmpty) return false;

  final keys = <String>{
    option.id,
    option.orderIndex.toString(),
  };
  if (index != null) {
    keys.add(String.fromCharCode(65 + index));
    keys.add(index.toString());
    keys.add('${index + 1}');
    keys.add('opt_$index');
  }

  return keys.map((key) => key.trim().toLowerCase()).any(normalizedTokens.contains);
}

List<String> _expectedAnswerTokens(QuestionModel question) {
  final expected = question.expectedAnswer;
  if (expected == null || expected.trim().isEmpty) return const <String>[];
  return expected
      .replaceAll('[', '')
      .replaceAll(']', '')
      .replaceAll('"', '')
      .replaceAll("'", '')
      .split(',')
      .map((token) => token.trim())
      .where((token) => token.isNotEmpty)
      .toList();
}

String _jsonish(Object? value) {
  if (value == null) return '—';
  if (value is String) return value.trim().isEmpty ? '—' : value;
  try {
    return const JsonEncoder.withIndent('  ').convert(value);
  } catch (_) {
    return value.toString();
  }
}

String _firstText(List<String?> values) {
  for (final value in values) {
    final clean = value?.trim();
    if (clean != null && clean.isNotEmpty) return clean;
  }
  return '—';
}

String _optionalInt(int? value) => value == null ? '—' : '$value';

String _successRate(double? value) {
  if (value == null) return '—';
  final normalized = value <= 1 ? value * 100 : value;
  return '${normalized.toStringAsFixed(normalized == normalized.roundToDouble() ? 0 : 1)}%';
}

String _seconds(double? value) {
  if (value == null) return '—';
  if (value < 60) return '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}s';
  final minutes = value / 60;
  return '${minutes.toStringAsFixed(minutes == minutes.roundToDouble() ? 0 : 1)}m';
}


class _FilterOption {
  final int id;
  final String label;

  const _FilterOption({required this.id, required this.label});
}

_TopicTarget? _targetForQuestion(List<_TopicTarget> targets, QuestionModel question) {
  final topicId = question.topicId;
  if (topicId == null) return null;
  for (final target in targets) {
    if (target.topic.id == topicId) return target;
  }
  return null;
}

bool _materialBelongsToModule(List<_TopicTarget> targets, int materialId, int moduleId) {
  for (final target in targets) {
    if (target.material.id == materialId && target.module.id == moduleId) return true;
  }
  return false;
}

bool _topicBelongsToMaterial(List<_TopicTarget> targets, int topicId, int materialId) {
  for (final target in targets) {
    if (target.topic.id == topicId && target.material.id == materialId) return true;
  }
  return false;
}

List<_FilterOption> _materialFilterOptions(List<_TopicTarget> targets, int? moduleId) {
  final seen = <int>{};
  final result = <_FilterOption>[];
  for (final target in targets) {
    if (moduleId != null && target.module.id != moduleId) continue;
    if (!seen.add(target.material.id)) continue;
    final label = '${target.module.title} / ${target.material.displayTitle}';
    result.add(_FilterOption(id: target.material.id, label: label));
  }
  result.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  return result;
}

List<_FilterOption> _topicFilterOptions(
  List<_TopicTarget> targets, {
  int? moduleId,
  int? materialId,
}) {
  final seen = <int>{};
  final result = <_FilterOption>[];
  for (final target in targets) {
    if (moduleId != null && target.module.id != moduleId) continue;
    if (materialId != null && target.material.id != materialId) continue;
    if (!seen.add(target.topic.id)) continue;
    final topicLabel = target.parentTopicTitle == null
        ? target.topic.title
        : '${target.parentTopicTitle} / ${target.topic.title}';
    result.add(_FilterOption(
      id: target.topic.id,
      label: '${target.material.displayTitle} / $topicLabel',
    ),);
  }
  result.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  return result;
}

List<_FilterOption> _learningOutcomeFilterOptions(List<QuestionModel> questions) {
  final seen = <int>{};
  final result = <_FilterOption>[];
  for (final question in questions) {
    for (final outcome in question.learningOutcomes) {
      if (!seen.add(outcome.id)) continue;
      result.add(_FilterOption(id: outcome.id, label: outcome.title));
    }
  }
  result.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  return result;
}

List<_FilterOption> _learningOutcomeSetupOptions(
  List<QuestionModel> questions,
  List<LearningOutcome> courseOutcomes,
) {
  final byId = <int, String>{};
  for (final outcome in courseOutcomes) {
    final title = outcome.title.trim();
    byId[outcome.id] = title.isEmpty ? 'LO ${outcome.id}' : title;
  }
  for (final question in questions) {
    for (final outcome in question.learningOutcomes) {
      final title = outcome.title.trim();
      byId.putIfAbsent(outcome.id, () => title.isEmpty ? 'LO ${outcome.id}' : title);
    }
  }
  final result = byId.entries
      .map((entry) => _FilterOption(id: entry.key, label: entry.value))
      .toList()
    ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  return result;
}

String _selectedMaterialFilterLabel(List<_FilterOption> options, int? id) {
  if (id == null) return 'All materials';
  for (final option in options) {
    if (option.id == id) return option.label;
  }
  return 'All materials';
}

String _selectedTopicFilterLabel(List<_FilterOption> options, int? id) {
  if (id == null) return 'All topics / subtopics';
  for (final option in options) {
    if (option.id == id) return option.label;
  }
  return 'All topics / subtopics';
}

String _selectedOutcomeFilterLabel(List<_FilterOption> options, int? id) {
  if (id == null) return 'All LOs';
  for (final option in options) {
    if (option.id == id) return option.label;
  }
  return 'All LOs';
}

String _sourceLabel(QuestionSource source) {
  switch (source) {
    case QuestionSource.aiGenerated:
      return 'AI';
    case QuestionSource.imported:
      return 'Imported';
    case QuestionSource.manual:
      return 'Manual';
  }
}

QuestionSource? _sourceFromLabel(String label) {
  switch (label) {
    case 'AI':
      return QuestionSource.aiGenerated;
    case 'Imported':
      return QuestionSource.imported;
    case 'Manual':
      return QuestionSource.manual;
    default:
      return null;
  }
}

bool? _usageFromLabel(String label) {
  switch (label) {
    case 'Used in exams':
      return true;
    case 'Unused':
      return false;
    default:
      return null;
  }
}

String _approvalLabel(QuestionApprovalStatus status) {
  switch (status) {
    case QuestionApprovalStatus.pending:
      return 'Pending review';
    case QuestionApprovalStatus.rejected:
      return 'Rejected';
    case QuestionApprovalStatus.approved:
      return 'Approved';
  }
}

String _usageLabel(int count) => count == 0 ? 'Unused' : 'Used in $count exam${count == 1 ? '' : 's'}';

String _shortDate(DateTime date) {
  if (date.millisecondsSinceEpoch == 0) return 'Unknown date';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _topicPathFromTarget(_TopicTarget? target, QuestionModel question) {
  if (target == null) return question.topicName ?? 'Not assigned';
  if (target.parentTopicTitle == null) return target.topic.title;
  return '${target.parentTopicTitle} / ${target.topic.title}';
}

String _contextLabel(QuestionModel question) {
  if ((question.topicName ?? '').trim().isNotEmpty) return question.topicName!.trim();
  if ((question.materialName ?? '').trim().isNotEmpty) return question.materialName!.trim();
  if ((question.moduleName ?? '').trim().isNotEmpty) return question.moduleName!.trim();
  return 'Not assigned';
}

String _answerText(QuestionModel question) {
  if (question.correctBool != null) return question.correctBool! ? 'True' : 'False';
  if (question.options.isNotEmpty && (question.expectedAnswer ?? '').trim().isNotEmpty) {
    final labels = _expectedAnswerTokens(question)
        .map((token) => _answerTokenLabel(question, token))
        .where((token) => token.trim().isNotEmpty)
        .toList(growable: false);
    if (labels.isNotEmpty) return labels.join(', ');
  }
  if ((question.expectedAnswer ?? '').trim().isNotEmpty) return question.expectedAnswer!.trim();
  if ((question.sampleAnswer ?? '').trim().isNotEmpty) return question.sampleAnswer!.trim();
  if ((question.correctOptionId ?? '').trim().isNotEmpty) return question.correctOptionId!.trim();
  return '';
}

String _answerTokenLabel(QuestionModel question, String token) {
  final normalized = token.trim().replaceAll('"', '').replaceAll("'", '');
  if (normalized.isEmpty) return '';

  final numericIndex = int.tryParse(normalized);
  if (numericIndex != null && numericIndex >= 0 && numericIndex < question.options.length) {
    return String.fromCharCode(65 + numericIndex);
  }

  final upper = normalized.toUpperCase();
  for (var i = 0; i < question.options.length; i++) {
    final option = question.options[i];
    if (option.id.trim().toUpperCase() == upper) {
      return String.fromCharCode(65 + i);
    }
  }
  return normalized;
}

String _moduleLabel(ModuleItem module) => module.title.trim().isEmpty ? 'Module ${module.id}' : module.title.trim();

String _selectedModuleLabel(List<ModuleItem> modules, int? id) {
  if (id == null) return 'All modules';
  for (final module in modules) {
    if (module.id == id) return _moduleLabel(module);
  }
  return 'All modules';
}

QuestionDifficulty? _difficultyFromLabel(String label) {
  switch (label) {
    case 'Easy':
      return QuestionDifficulty.easy;
    case 'Medium':
      return QuestionDifficulty.medium;
    case 'Hard':
      return QuestionDifficulty.hard;
    default:
      return null;
  }
}

QuestionType? _typeFromLabel(String label) {
  switch (label) {
    case 'Multiple Choice':
      return QuestionType.multipleChoice;
    case 'True / False':
      return QuestionType.trueFalse;
    case 'Short Answer':
      return QuestionType.shortAnswer;
    case 'Essay':
      return QuestionType.essay;
    case 'Multi-Select':
      return QuestionType.multiSelect;
    case 'Fill in the Blank':
      return QuestionType.fillInTheBlank;
    case 'Numeric':
      return QuestionType.numeric;
    case 'Code':
      return QuestionType.code;
    default:
      return null;
  }
}

bool _backendEditableType(QuestionType type) {
  return type == QuestionType.multipleChoice ||
      type == QuestionType.multiSelect ||
      type == QuestionType.trueFalse ||
      type == QuestionType.shortAnswer ||
      type == QuestionType.essay;
}

String _initialAnswerText(QuestionModel q) {
  if (q.type == QuestionType.shortAnswer || q.type == QuestionType.essay) {
    return q.sampleAnswer ?? q.expectedAnswer ?? '';
  }
  return q.expectedAnswer ?? '';
}

List<_EditableOption> _initialOptions(QuestionModel q) {
  if (q.options.isEmpty) {
    return [
      _EditableOption(controller: TextEditingController(), correct: true),
      _EditableOption(controller: TextEditingController(), correct: false),
    ];
  }
  return q.options.map((option) {
    final correct = option.isCorrect || option.id == q.correctOptionId;
    return _EditableOption(
      controller: TextEditingController(text: option.text),
      correct: correct,
    );
  }).toList();
}

String? _topicPickerLabel(List<_TopicTarget> targets, int? topicId) {
  if (topicId == null) return null;
  for (final target in targets) {
    if (target.topic.id == topicId) return target.topic.title;
  }
  return null;
}

String? _moduleNameFromTargets(List<_TopicTarget> targets, int? topicId) {
  if (topicId == null) return null;
  for (final target in targets) {
    if (target.topic.id == topicId) return target.module.title;
  }
  return null;
}

String? _materialNameFromTargets(List<_TopicTarget> targets, int? topicId) {
  if (topicId == null) return null;
  for (final target in targets) {
    if (target.topic.id == topicId) return target.material.displayTitle;
  }
  return null;
}

String? _topicNameFromTargets(List<_TopicTarget> targets, int? topicId) {
  if (topicId == null) return null;
  for (final target in targets) {
    if (target.topic.id == topicId) return target.topic.title;
  }
  return null;
}
