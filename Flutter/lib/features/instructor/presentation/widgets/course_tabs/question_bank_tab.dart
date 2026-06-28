import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
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
import '../../../data/question_bank_refresh_signal.dart';
import '../../../data/question_vocabulary.dart';
import '../../../data/questions_api.dart';
import '../../../data/topics_models.dart';
import '../../controllers/course_details_controller.dart';
import '../../controllers/course_details_state.dart';
import '../add_question_sheet.dart' as add_question_sheet;
import '../course_outcomes_panel.dart';
import '../question_bank/question_bank_authoring_flow.dart';
import 'create_exam_flow.dart';

part 'question_bank_tab_exam_setup.dart';
part 'question_bank_tab_exam_setup_components.dart';
part 'question_bank_tab_exam_setup_status.dart';
part 'question_bank_tab_exam_setup_pickers.dart';
part 'question_bank_tab_topic_picker.dart';
part 'question_bank_tab_workspace.dart';
part 'question_bank_tab_review.dart';
part 'question_bank_tab_edit_dialog.dart';



Future<void> showCourseCreateExamDialog({
  required BuildContext context,
  required WidgetRef ref,
  required MyCourseItem course,
  List<QuestionModel>? initialQuestions,
  VoidCallback? onChanged,
}) async {
  final questions = initialQuestions ?? await _loadCourseQuestionsForCreateExam(context, ref, course.id);
  if (questions == null) return;

  if (!context.mounted) return;
  unawaited(_warmCreateExamMetadata(ref, course.id));
  final templatesFuture = ref
      .read(examTemplatesStorageProvider)
      .load(course.id)
      .catchError((Object _) => ExamTemplateModel.defaults(course.id));
  final outcomes = ref.read(courseLOProvider(course.id));
  final latestState = ref.read(courseDetailsControllerProvider(course.id));
  final latestTopicTargets = _topicTargetsFromCourseDetailsState(latestState);

  final result = await showDialog<Object?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CreateExamStartDialog(
      course: course,
      templates: ExamTemplateModel.defaults(course.id),
      templatesFuture: templatesFuture,
      modules: latestState.modules,
      topicTargets: latestTopicTargets,
      outcomes: outcomes,
      questions: questions,
    ),
  );
  if (result == null || !context.mounted) return;

  if (result is _GeneratedExamResult) {
    onChanged?.call();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GeneratedExamSuccessDialog(
        exam: result.exam,
        template: result.template,
      ),
    );
    return;
  }

  if (result is _ExamStartConfig) {
    await showCreateExamFlowDialog(
      context: context,
      course: course,
      questions: questions,
      initialTemplate: result.template,
      initialScopeModuleId: result.moduleId,
      initialScopeMaterialId: result.materialId,
      initialScopeTopicIds: result.topicIds,
      initialScopeOutcomeIds: result.outcomeIds,
      initialTitle: result.title,
      onCreated: onChanged,
    );
  }
}

Future<void> _warmCreateExamMetadata(WidgetRef ref, int courseId) async {
  try {
    await Future.wait<void>([
      ref
          .read(courseDetailsControllerProvider(courseId).notifier)
          .loadModulesAndAllMaterials(hydrateTopicDetails: false),
      ensureCourseLearningOutcomesLoaded(ref, courseId),
    ]);
  } catch (_) {
    // The dialog can still fall back to metadata already attached to questions.
  }
}

Future<List<QuestionModel>?> _loadCourseQuestionsForCreateExam(
  BuildContext context,
  WidgetRef ref,
  int courseId,
) async {
  try {
    final response = await ref.read(questionsApiProvider).getCourseQuestions(
      courseId: courseId,
      summaryOnly: true,
    );
    return response.questions;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load course questions: ${mapApiFailure(e).message}')),
      );
    }
    return null;
  }
}

List<_TopicTarget> _topicTargetsFromCourseDetailsState(CourseDetailsState courseState) {
  final result = <_TopicTarget>[];
  for (final module in courseState.modules) {
    final materials = courseState.materials[module.id] ?? const <MaterialItem>[];
    final materialsById = {for (final material in materials) material.id: material};
    final topics = courseState.topics[module.id] ?? const <TopicItem>[];
    final topicById = {for (final topic in topics) topic.id: topic};
    for (final topic in topics) {
      final material = materialsById[topic.materialId];
      if (material == null) continue;
      final parentTitle = topic.parentTopicId == null
          ? null
          : topicById[topic.parentTopicId]?.title;
      result.add(_TopicTarget(
        module: module,
        material: material,
        topic: topic,
        parentTopicTitle: parentTitle,
      ));
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

class CourseQuestionBankTab extends ConsumerStatefulWidget {
  final MyCourseItem course;

  const CourseQuestionBankTab({super.key, required this.course});

  @override
  ConsumerState<CourseQuestionBankTab> createState() => _CourseQuestionBankTabState();
}

class _CourseQuestionBankTabState extends ConsumerState<CourseQuestionBankTab> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  CancelToken? _questionsCancelToken;
  int _questionsRequestSerial = 0;
  final Map<String, String> _questionSearchTextById = <String, String>{};

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
  bool _showQuestionAuthoring = false;
  Set<int> _authoringModuleIds = const <int>{};
  Set<int> _authoringMaterialIds = const <int>{};
  Set<int> _authoringTopicIds = const <int>{};
  QuestionAuthoringLaunchContext? _authoringLaunchContext;

  bool _loading = true;
  bool _creatingExam = false;
  bool _treeRequested = false;
  Future<void>? _treeLoadFuture;
  String? _error;
  List<QuestionModel> _questions = [];
  int _pageIndex = 0;
  int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadQuestions());
      unawaited(_loadCourseTree());
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _questionsCancelToken?.cancel('Question bank disposed');
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    if (!mounted) return;

    final requestSerial = ++_questionsRequestSerial;
    _questionsCancelToken?.cancel('Newer question bank request started');
    final cancelToken = CancelToken();
    _questionsCancelToken = cancelToken;
    final showBlockingLoader = _questions.isEmpty;

    setState(() {
      if (showBlockingLoader) _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(questionsApiProvider);
      final resp = await api.getCourseQuestions(
        courseId: widget.course.id,
        cancelToken: cancelToken,
        summaryOnly: true,
      );
      if (!mounted || requestSerial != _questionsRequestSerial) return;
      final sortedQuestions = _sortQuestionsNewestFirst(resp.questions);
      _rebuildQuestionSearchIndex(sortedQuestions);
      setState(() {
        _questions = sortedQuestions;
        _loading = false;
        _pageIndex = 0;
        if (_selectedQuestionId != null &&
            !_questions.any((question) => question.id == _selectedQuestionId)) {
          _selectedQuestionId = null;
        }
      });
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      if (!mounted || requestSerial != _questionsRequestSerial) return;
      setState(() {
        _error = mapApiFailure(e).message;
        _loading = false;
      });
    } finally {
      if (identical(_questionsCancelToken, cancelToken)) {
        _questionsCancelToken = null;
      }
    }
  }

  void _rebuildQuestionSearchIndex(List<QuestionModel> questions) {
    _questionSearchTextById
      ..clear()
      ..addEntries(
        questions.map(
          (question) => MapEntry(question.id, _buildQuestionSearchText(question)),
        ),
      );
  }

  void _upsertQuestionSearchIndex(QuestionModel question) {
    _questionSearchTextById[question.id] = _buildQuestionSearchText(question);
  }

  String _buildQuestionSearchText(QuestionModel q) {
    final buffer = StringBuffer()
      ..write(q.text)
      ..write(' ')
      ..write(q.topicName ?? '')
      ..write(' ')
      ..write(q.moduleName ?? '')
      ..write(' ')
      ..write(q.materialName ?? '')
      ..write(' ')
      ..write(q.typeLabel)
      ..write(' ')
      ..write(q.difficultyLabel)
      ..write(' ')
      ..write(_sourceLabel(q.source));
    for (final outcome in q.learningOutcomes) {
      buffer
        ..write(' ')
        ..write(outcome.title);
    }
    for (final tag in q.tags) {
      buffer
        ..write(' ')
        ..write(tag);
    }
    return buffer.toString().toLowerCase();
  }

  Future<void> _loadCourseTree({bool force = false}) async {
    final inFlight = _treeLoadFuture;
    if (inFlight != null && !force) return inFlight;
    if (_treeRequested && !force) return;

    _treeRequested = true;
    final future = ref
        .read(courseDetailsControllerProvider(widget.course.id).notifier)
        .loadModulesAndAllMaterials(
          force: force,
          hydrateTopicDetails: false,
        );
    _treeLoadFuture = future;

    try {
      await future;
    } catch (_) {
      _treeRequested = false;
      // The question list can still work without the full authoring tree.
    } finally {
      if (identical(_treeLoadFuture, future)) {
        _treeLoadFuture = null;
      }
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

    _upsertQuestionSearchIndex(updated);
    setState(() {
      _questions = _sortQuestionsNewestFirst(_questions.map((item) {
        if (item.id == question.id || item.remoteId == question.remoteId) return updated;
        return item;
      }).toList());
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
    ref.listen<int>(questionBankRefreshSignalProvider(widget.course.id), (previous, next) {
      if (previous == null || previous == next) return;
      unawaited(_loadQuestions());
    });

    final courseState = ref.watch(courseDetailsControllerProvider(widget.course.id));
    const courseOutcomes = <LearningOutcome>[];
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

    if (_showQuestionAuthoring) {
      return QuestionBankAuthoringFlow(
        course: widget.course,
        initialModuleIds: _authoringModuleIds,
        initialMaterialIds: _authoringMaterialIds,
        initialTopicIds: _authoringTopicIds,
        embedded: true,
        startInAiMode: true,
        launchContext: _authoringLaunchContext,
        onClose: _closeQuestionAuthoring,
        onSavedToQuestionBank: _closeQuestionAuthoringAfterSave,
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
                  onGenerateQuestions: _openGenerateQuestionsTopicPicker,
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

  Future<void> _openGenerateQuestionsTopicPicker() async {
    try {
      await _loadCourseTree();
    } catch (_) {
      // The dialog below will still use whatever data is already cached.
    }

    if (!mounted) return;
    final latestState = ref.read(courseDetailsControllerProvider(widget.course.id));
    final topicTargets = _topicTargetsFromState(latestState);

    if (topicTargets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No topics found yet. Upload a material and wait for topics before generating questions.'),
        ),
      );
      return;
    }

    final selected = await showDialog<_TopicTarget>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _QuestionGenerationTopicPickerDialog(topicTargets: topicTargets),
    );
    if (selected == null || !mounted) return;
    _openQuestionAuthoringForTopic(selected);
  }

  void _openQuestionAuthoringForTopic(_TopicTarget target) {
    final isSubtopic = target.topic.parentTopicId != null;
    final moduleIds = <int>{target.module.id};
    final materialIds = <int>{target.material.id};
    final topicIds = <int>{target.topic.id};
    final targetSnapshot = add_question_sheet.QuestionAuthoringTarget(
      moduleId: target.module.id,
      moduleName: target.module.title,
      materialId: target.material.id,
      materialName: target.material.displayTitle,
      topicId: target.topic.id,
      topicName: target.topic.title,
      isSubtopic: isSubtopic,
      parentTopicName: target.parentTopicTitle,
    );

    setState(() {
      _authoringModuleIds = moduleIds;
      _authoringMaterialIds = materialIds;
      _authoringTopicIds = topicIds;
      _authoringLaunchContext = QuestionAuthoringLaunchContext(
        kind: isSubtopic
            ? QuestionAuthoringScopeKind.subtopic
            : QuestionAuthoringScopeKind.topic,
        title: targetSnapshot.label,
        subtitle: '${target.module.title} • ${target.material.displayTitle}',
        selectedModuleId: target.module.id,
        selectedMaterialId: target.material.id,
        selectedTopicId: target.topic.id,
        selectedModuleIds: moduleIds,
        selectedMaterialIds: materialIds,
        selectedTopicIds: topicIds,
        targetSnapshots: <add_question_sheet.QuestionAuthoringTarget>[targetSnapshot],
      );
      _showQuestionAuthoring = true;
    });
  }

  void _closeQuestionAuthoring() {
    if (!mounted) return;
    setState(() {
      _showQuestionAuthoring = false;
      _authoringModuleIds = const <int>{};
      _authoringMaterialIds = const <int>{};
      _authoringTopicIds = const <int>{};
      _authoringLaunchContext = null;
    });
  }

  void _closeQuestionAuthoringAfterSave() {
    _closeQuestionAuthoring();
    unawaited(_loadQuestions());
  }

  Future<void> _openCreateExamStart() async {
    if (_questions.isEmpty || _creatingExam) return;
    await showCourseCreateExamDialog(
      context: context,
      ref: ref,
      course: widget.course,
      initialQuestions: _questions,
      onChanged: () {
        unawaited(_loadQuestions());
      },
    );
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
    final searchText = _search.trim().toLowerCase();
    final hasSearch = searchText.isNotEmpty;
    final hasTopicFilters = _filterModuleId != null || _filterMaterialId != null || _filterTopicId != null;
    final hasQuestionFilters = _filterType != null ||
        _filterDiff != null ||
        _filterSource != null ||
        _filterUsed != null ||
        _filterOutcomeId != null;

    if (!hasSearch && !hasTopicFilters && !hasQuestionFilters) {
      return _sortQuestionsNewestFirst(input);
    }

    final result = <QuestionModel>[];
    for (final q in input) {
      if (hasSearch) {
        final haystack = _questionSearchTextById[q.id] ?? _buildQuestionSearchText(q);
        if (!haystack.contains(searchText)) continue;
      }

      if (hasTopicFilters) {
        final target = q.topicId == null ? null : topicTargetByTopicId[q.topicId];
        final moduleId = q.moduleId ?? target?.module.id;
        final materialId = q.materialId ?? target?.material.id;
        final topicId = q.topicId ?? target?.topic.id;
        if (_filterModuleId != null && moduleId != _filterModuleId) continue;
        if (_filterMaterialId != null && materialId != _filterMaterialId) continue;
        if (_filterTopicId != null && topicId != _filterTopicId) continue;
      }

      if (_filterType != null && q.type != _filterType) continue;
      if (_filterDiff != null && q.difficulty != _filterDiff) continue;
      if (_filterSource != null && q.source != _filterSource) continue;
      if (_filterUsed != null && (q.usageCount > 0) != _filterUsed) continue;
      if (_filterOutcomeId != null && !q.learningOutcomes.any((outcome) => outcome.id == _filterOutcomeId)) {
        continue;
      }
      result.add(q);
    }
    return _sortQuestionsNewestFirst(result);
  }

  List<_TopicTarget> _topicTargetsFromState(CourseDetailsState courseState) {
    final result = <_TopicTarget>[];
    for (final module in courseState.modules) {
      final materials = courseState.materials[module.id] ?? const <MaterialItem>[];
      final materialsById = {for (final material in materials) material.id: material};
      final topics = courseState.topics[module.id] ?? const <TopicItem>[];
      final topicById = {for (final topic in topics) topic.id: topic};
      for (final topic in topics) {
        final material = materialsById[topic.materialId];
        if (material == null) continue;
        final parentTitle = topic.parentTopicId == null
            ? null
            : topicById[topic.parentTopicId]?.title;
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


  List<QuestionModel> _sortQuestionsNewestFirst(List<QuestionModel> questions) {
    final sorted = List<QuestionModel>.of(questions);
    sorted.sort((a, b) {
      final createdCmp = b.createdAt.compareTo(a.createdAt);
      if (createdCmp != 0) return createdCmp;
      final updatedCmp = b.updatedAt.compareTo(a.updatedAt);
      if (updatedCmp != 0) return updatedCmp;
      final bId = b.remoteId ?? int.tryParse(b.id) ?? 0;
      final aId = a.remoteId ?? int.tryParse(a.id) ?? 0;
      return bId.compareTo(aId);
    });
    return sorted;
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('session expired') || lower.contains('login again')) {
      return 'Your session expired while loading questions. Please log in again.';
    }
    return raw.trim().isNotEmpty ? raw : 'Could not load saved questions right now.';
  }
}


