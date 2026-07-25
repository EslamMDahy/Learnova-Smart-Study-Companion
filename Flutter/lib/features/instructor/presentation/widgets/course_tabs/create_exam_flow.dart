import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/error_mapper.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../data/courses_models.dart';
import '../../../data/exam_models.dart';
import '../../../data/exam_templates_storage.dart';
import '../../../data/materials_models.dart';
import '../../../data/modules_materials_providers.dart';
import '../../../data/modules_models.dart';
import '../../../data/question_models.dart';
import '../../../data/question_vocabulary.dart';
import '../../../data/topics_models.dart';
import '../../controllers/course_details_controller.dart';
import '../../controllers/course_details_state.dart';

part 'create_exam_flow_widgets.dart';

Future<bool?> showCreateExamFlowDialog({
  required BuildContext context,
  required MyCourseItem course,
  required List<QuestionModel> questions,
  Set<int> initialSelectedQuestionIds = const <int>{},
  ExamTemplateModel? initialTemplate,
  int? initialScopeModuleId,
  int? initialScopeMaterialId,
  int? initialScopeTopicId,
  int? initialScopeOutcomeId,
  Set<int> initialScopeTopicIds = const <int>{},
  Set<int> initialScopeOutcomeIds = const <int>{},
  String? initialTitle,
  VoidCallback? onCancel,
  VoidCallback? onCreated,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog.fullscreen(
      child: CreateExamFlow(
        course: course,
        questions: questions,
        initialSelectedQuestionIds: initialSelectedQuestionIds,
        initialTemplate: initialTemplate,
        initialScopeModuleId: initialScopeModuleId,
        initialScopeMaterialId: initialScopeMaterialId,
        initialScopeTopicId: initialScopeTopicId,
        initialScopeOutcomeId: initialScopeOutcomeId,
        initialScopeTopicIds: initialScopeTopicIds,
        initialScopeOutcomeIds: initialScopeOutcomeIds,
        initialTitle: initialTitle,
        onCancel: onCancel,
        onCreated: onCreated,
      ),
    ),
  );
}

class CreateExamFlow extends ConsumerStatefulWidget {
  final MyCourseItem course;
  final List<QuestionModel> questions;
  final Set<int> initialSelectedQuestionIds;
  final ExamTemplateModel? initialTemplate;
  final int? initialScopeModuleId;
  final int? initialScopeMaterialId;
  final int? initialScopeTopicId;
  final int? initialScopeOutcomeId;
  final Set<int> initialScopeTopicIds;
  final Set<int> initialScopeOutcomeIds;
  final String? initialTitle;
  final VoidCallback? onCancel;
  final VoidCallback? onCreated;

  const CreateExamFlow({
    super.key,
    required this.course,
    required this.questions,
    this.initialSelectedQuestionIds = const <int>{},
    this.initialTemplate,
    this.initialScopeModuleId,
    this.initialScopeMaterialId,
    this.initialScopeTopicId,
    this.initialScopeOutcomeId,
    this.initialScopeTopicIds = const <int>{},
    this.initialScopeOutcomeIds = const <int>{},
    this.initialTitle,
    this.onCancel,
    this.onCreated,
  });

  @override
  ConsumerState<CreateExamFlow> createState() => _CreateExamFlowState();
}

class _CreateExamFlowState extends ConsumerState<CreateExamFlow> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '60');
  final _attemptsCtrl = TextEditingController(text: '1');
  final _passingScoreCtrl = TextEditingController(text: '60');

  int _step = 1;
  bool _templateSeeded = false;
  bool _saving = false;
  bool _publishAfterSave = false;
  bool _shuffleQuestions = true;
  bool _shuffleAnswers = false;
  bool _showResultImmediately = true;
  bool _allowReview = true;
  String _examType = 'quiz';
  late ExamTemplateModel _selectedTemplate;
  String? _error;

  int? _scopeModuleId;
  int? _scopeMaterialId;
  final Set<int> _scopeTopicIds = <int>{};
  final Set<int> _scopeOutcomeIds = <int>{};
  DateTime? _availableFrom;
  DateTime? _availableTo;

  final List<int> _selectedQuestionIds = <int>[];
  bool _treeRequested = false;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.initialTemplate ?? ExamTemplateModel.custom(widget.course.id);
    _scopeModuleId = widget.initialScopeModuleId;
    _scopeMaterialId = widget.initialScopeMaterialId;
    _scopeTopicIds.addAll(widget.initialScopeTopicIds);
    if (widget.initialScopeTopicId != null) _scopeTopicIds.add(widget.initialScopeTopicId!);
    _scopeOutcomeIds.addAll(widget.initialScopeOutcomeIds);
    if (widget.initialScopeOutcomeId != null) _scopeOutcomeIds.add(widget.initialScopeOutcomeId!);
    final initialTitle = widget.initialTitle?.trim();
    _titleCtrl.text = initialTitle != null && initialTitle.isNotEmpty
        ? initialTitle
        : '${widget.course.title} ${_selectedTemplate.name}';
    _applyTemplateModel(_selectedTemplate, updateTitle: true);
    for (final id in widget.initialSelectedQuestionIds) {
      if (!_selectedQuestionIds.contains(id) && _questionById(id) != null) {
        _selectedQuestionIds.add(id);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCourseTree());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _instructionsCtrl.dispose();
    _durationCtrl.dispose();
    _attemptsCtrl.dispose();
    _passingScoreCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCourseTree() async {
    if (_treeRequested) return;
    _treeRequested = true;
    try {
      await ref
          .read(courseDetailsControllerProvider(widget.course.id).notifier)
          .loadModulesAndAllMaterials();
    } catch (_) {
      // Create exam can still work from question metadata if the course tree is unavailable.
    }
  }

  List<QuestionModel> get _savedQuestions => widget.questions.where((q) => q.remoteId != null).toList();

  QuestionModel? _questionById(int id) {
    for (final question in _savedQuestions) {
      if (question.remoteId == id) return question;
    }
    return null;
  }

  List<QuestionModel> _selectedQuestions() {
    final result = <QuestionModel>[];
    for (final id in _selectedQuestionIds) {
      final question = _questionById(id);
      if (question != null) result.add(question);
    }
    return result;
  }

  double get _totalPoints => _selectedQuestions().fold<double>(
        0,
        (sum, question) => sum + question.maxScore.toDouble(),
      );

  String? _backendExamSectionType(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'multiple_choice';
      case QuestionType.trueFalse:
        return 'true_false';
      case QuestionType.shortAnswer:
        return 'short_answer';
      case QuestionType.essay:
        return 'essay';
      case QuestionType.multiSelect:
        return 'multi_select';
      case QuestionType.fillInTheBlank:
      case QuestionType.numeric:
      case QuestionType.code:
        return null;
    }
  }

  String _sectionTitle(String questionType) {
    switch (questionType) {
      case 'true_false':
        return 'True / False Questions';
      case 'short_answer':
        return 'Short Answer Questions';
      case 'essay':
        return 'Essay Questions';
      case 'multi_select':
        return 'Multi-Select Questions';
      default:
        return 'Multiple Choice Questions';
    }
  }

  void _cancelFlow() {
    if (_saving) return;
    widget.onCancel?.call();
  }

  List<_TopicTarget> _topicTargetsFromState(CourseDetailsState state) {
    final result = <_TopicTarget>[];
    for (final module in state.modules) {
      final materials = state.materials[module.id] ?? const <MaterialItem>[];
      final materialById = {for (final material in materials) material.id: material};
      final topics = state.topics[module.id] ?? const <TopicItem>[];
      for (final topic in topics) {
        final material = materialById[topic.materialId];
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

  _TopicTarget? _targetForQuestion(List<_TopicTarget> targets, QuestionModel question) {
    final topicId = question.topicId;
    if (topicId == null) return null;
    for (final target in targets) {
      if (target.topic.id == topicId) return target;
    }
    return null;
  }

  List<QuestionModel> _scopeQuestions(List<_TopicTarget> targets) {
    return _savedQuestions.where((question) {
      final target = _targetForQuestion(targets, question);
      final moduleId = question.moduleId ?? target?.module.id;
      final materialId = question.materialId ?? target?.material.id;
      final topicId = question.topicId ?? target?.topic.id;

      if (_scopeModuleId != null && moduleId != _scopeModuleId) return false;
      if (_scopeMaterialId != null && materialId != _scopeMaterialId) return false;
      if (_scopeTopicIds.isNotEmpty && (topicId == null || !_scopeTopicIds.contains(topicId))) return false;
      if (_scopeOutcomeIds.isNotEmpty &&
          !question.learningOutcomes.any((outcome) => _scopeOutcomeIds.contains(outcome.id))) {
        return false;
      }
      return true;
    }).toList();
  }

  void _toggleQuestion(QuestionModel question, bool selected) {
    final id = question.remoteId;
    if (id == null) return;
    setState(() {
      if (selected) {
        if (!_selectedQuestionIds.contains(id)) _selectedQuestionIds.add(id);
      } else {
        _selectedQuestionIds.remove(id);
      }
    });
  }

  void _applyTemplateModel(ExamTemplateModel template, {bool updateTitle = false}) {
    _selectedTemplate = template;
    _examType = template.examType;
    _durationCtrl.text = template.durationMinutes.toString();
    _attemptsCtrl.text = template.maxAttempts.toString();
    _passingScoreCtrl.text = template.passingScore.toStringAsFixed(0);
    _shuffleQuestions = template.shuffleQuestions;
    _shuffleAnswers = template.shuffleAnswers;
    _showResultImmediately = template.showResultImmediately;
    _allowReview = template.allowReview;
    _publishAfterSave = template.publishAfterSave;
    if (_instructionsCtrl.text.trim().isEmpty && template.instructions.trim().isNotEmpty) {
      _instructionsCtrl.text = template.instructions.trim();
    }
    if (updateTitle && _titleCtrl.text.trim().isEmpty) {
      _titleCtrl.text = '${widget.course.title} ${template.name}';
    }
  }

  void _seedQuestionsFromTemplate(List<_TopicTarget> targets) {
    if (_templateSeeded) return;
    _templateSeeded = true;
    if (_selectedQuestionIds.isNotEmpty) return;

    final template = _selectedTemplate;
    final scoped = _scopeQuestions(targets).where((question) => question.remoteId != null).toList();
    scoped.sort((a, b) {
      final usageCmp = a.usageCount.compareTo(b.usageCount);
      if (usageCmp != 0) return usageCmp;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    final ids = template.sections.where((section) => section.questionCount > 0).isNotEmpty
        ? _seedDistributedQuestionIds(scoped, template)
        : _seedLegacyQuestionIds(scoped, template);

    if (ids.isEmpty) return;
    setState(() => _selectedQuestionIds.addAll(ids));
  }

  List<int> _seedDistributedQuestionIds(List<QuestionModel> scoped, ExamTemplateModel template) {
    final ids = <int>[];
    final used = <int>{};
    final activeSections = template.sections.where((section) => section.questionCount > 0).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    for (final section in activeSections) {
      final type = _questionTypeFromTemplateSection(section.questionType);
      if (type == null) continue;
      final difficultyCounts = section.difficultyDistribution.entries.where((entry) => entry.value > 0).toList();

      if (difficultyCounts.isNotEmpty) {
        for (final entry in difficultyCounts) {
          final difficulty = _questionDifficultyFromTemplateKey(entry.key);
          final candidates = scoped.where((question) {
            final id = question.remoteId;
            if (id == null || used.contains(id)) return false;
            if (question.type != type) return false;
            if (question.difficulty != difficulty) return false;
            return true;
          }).toList();

          for (final question in candidates.take(entry.value)) {
            final id = question.remoteId;
            if (id == null || !used.add(id)) continue;
            ids.add(id);
          }
        }
        continue;
      }

      final candidates = scoped.where((question) {
        final id = question.remoteId;
        if (id == null || used.contains(id)) return false;
        if (question.type != type) return false;
        if (template.preferredDifficulty != null && question.difficulty != template.preferredDifficulty) return false;
        return true;
      }).toList();

      for (final question in candidates.take(section.questionCount)) {
        final id = question.remoteId;
        if (id == null || !used.add(id)) continue;
        ids.add(id);
      }
    }

    return ids;
  }

  List<int> _seedLegacyQuestionIds(List<QuestionModel> scoped, ExamTemplateModel template) {
    final preferred = scoped.where((question) {
      if (template.preferredType != null && question.type != template.preferredType) return false;
      if (template.preferredDifficulty != null && question.difficulty != template.preferredDifficulty) return false;
      return true;
    }).toList();

    final ordered = <QuestionModel>[...preferred];
    for (final question in scoped) {
      if (!ordered.any((item) => item.remoteId == question.remoteId)) ordered.add(question);
    }

    final ids = <int>[];
    for (final question in ordered.take(template.questionCount)) {
      final id = question.remoteId;
      if (id != null && !ids.contains(id)) ids.add(id);
    }
    return ids;
  }

  QuestionType? _questionTypeFromTemplateSection(String raw) {
    switch (raw.trim()) {
      case 'multiple_choice':
        return QuestionType.multipleChoice;
      case 'true_false':
        return QuestionType.trueFalse;
      case 'short_answer':
        return QuestionType.shortAnswer;
      case 'essay':
        return QuestionType.essay;
      case 'multi_select':
        return QuestionType.multiSelect;
      case 'fill_in_the_blank':
      case 'fill_in_blank':
        return QuestionType.fillInTheBlank;
      case 'numeric':
        return QuestionType.numeric;
      case 'code':
        return QuestionType.code;
      default:
        return null;
    }
  }

  QuestionDifficulty _questionDifficultyFromTemplateKey(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'easy':
        return QuestionDifficulty.easy;
      case 'hard':
        return QuestionDifficulty.hard;
      default:
        return QuestionDifficulty.medium;
    }
  }

  String? _templateSelectionError() {
    final activeSections = _selectedTemplate.sections.where((section) => section.questionCount > 0).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    if (activeSections.isEmpty) return null;

    final selected = _selectedQuestions();
    final gaps = <String>[];
    for (final section in activeSections) {
      final type = _questionTypeFromTemplateSection(section.questionType);
      if (type == null) continue;
      final count = selected.where((question) => question.type == type).length;
      if (count < section.questionCount) {
        gaps.add('${_shortTemplateTypeLabel(section.questionType)} $count/${section.questionCount}');
      }
    }
    if (gaps.isEmpty) return null;
    return 'The selected question set does not satisfy the template distribution: ${gaps.join(' • ')}.';
  }

  Future<void> _next(List<_TopicTarget> targets) async {
    setState(() => _error = null);
    if (_step == 1) {
      if (_selectedQuestionIds.isEmpty) {
        setState(() => _error = 'Select at least one question.');
        return;
      }
      final templateError = _templateSelectionError();
      if (templateError != null) {
        setState(() => _error = templateError);
        return;
      }
      setState(() => _step = 2);
      return;
    }
    if (_step == 2) {
      if (_titleCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Exam title is required.');
        return;
      }
      if (_availableFrom != null && _availableTo != null && !_availableTo!.isAfter(_availableFrom!)) {
        setState(() => _error = 'End date must be after start date.');
        return;
      }
      setState(() => _step = 3);
      return;
    }
    await _saveExam();
  }

  void _back() {
    if (_saving) return;
    if (_step == 1) {
      _cancelFlow();
      return;
    }
    setState(() {
      _step -= 1;
      _error = null;
    });
  }

  Future<void> _saveExam() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final duration = int.tryParse(_durationCtrl.text.trim());
      final attempts = int.tryParse(_attemptsCtrl.text.trim());
      final passingScore = double.tryParse(_passingScoreCtrl.text.trim());
      final selectedQuestions = _selectedQuestions();
      final unsupportedQuestions = selectedQuestions
          .where((question) => _backendExamSectionType(question.type) == null)
          .toList();
      if (unsupportedQuestions.isNotEmpty) {
        throw FormatException(
          'The current exam backend accepts multiple-choice, multi-select, true/false, short-answer, and essay questions only. Remove unsupported questions before saving.',
        );
      }

      final groupedQuestionIds = <String, List<int>>{};
      for (final question in selectedQuestions) {
        final questionId = question.remoteId;
        final questionType = _backendExamSectionType(question.type);
        if (questionId == null || questionType == null) continue;
        groupedQuestionIds.putIfAbsent(questionType, () => <int>[]).add(questionId);
      }

      final api = ref.read(examsApiProvider);
      final exam = await api.createExam(
        courseId: widget.course.id,
        payload: ExamCreatePayload(
          title: _titleCtrl.text.trim(),
          description: _emptyToNull(_descriptionCtrl.text),
          instructions: _emptyToNull(_instructionsCtrl.text),
          examType: _examType,
          durationMinutes: duration != null && duration > 0 ? duration : null,
          maxAttempts: attempts != null && attempts > 0 ? attempts : 1,
          passingScore: passingScore != null && passingScore >= 0 ? passingScore : null,
          shuffleQuestions: _shuffleQuestions,
          shuffleOptions: _shuffleAnswers,
          availableFrom: _availableFrom,
          availableTo: _availableTo,
        ),
      );

      for (final entry in groupedQuestionIds.entries) {
        final section = await api.createSection(
          courseId: widget.course.id,
          examId: exam.id,
          payload: ExamSectionCreatePayload(
            title: _sectionTitle(entry.key),
            questionType: entry.key,
            timeLimitMinutes: duration != null && duration > 0 ? duration : null,
          ),
        );
        await api.addQuestions(
          courseId: widget.course.id,
          examId: exam.id,
          sectionId: section.id,
          questionIds: entry.value,
        );
      }

      if (_publishAfterSave) {
        await api.publishExam(courseId: widget.course.id, examId: exam.id);
      }

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => _ExamSavedDialog(
          title: _publishAfterSave ? 'Exam published' : 'Exam saved',
          message: _publishAfterSave
              ? 'The exam was created, questions were attached, and the exam was published successfully.'
              : 'The exam was created and questions were attached successfully.',
          examId: exam.id,
        ),
      );
      if (!mounted) return;
      widget.onCreated?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = mapApiFailure(e).message;
      });
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final courseState = ref.watch(courseDetailsControllerProvider(widget.course.id));
    final targets = _topicTargetsFromState(courseState);
    final scoped = _scopeQuestions(targets);
    final selected = _selectedQuestions();
    if (!_templateSeeded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _seedQuestionsFromTemplate(targets);
      });
    }

    return Container(
      color: AppColors.surfaceBg,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 22, 28, 14),
                    child: Column(
                      children: [
                        _Stepper(current: _step),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          _ErrorBanner(message: _error!),
                        ],
                        const SizedBox(height: 16),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 140),
                            child: KeyedSubtree(
                              key: ValueKey<int>(_step),
                              child: switch (_step) {
                                1 => _QuestionSelectionStep(
                                    targets: targets,
                                    questions: selected,
                                    template: _selectedTemplate,
                                    scopedCount: scoped.length,
                                    onRemove: (QuestionModel question) => _toggleQuestion(question, false),
                                    onReplace: (QuestionModel question) => _replaceQuestion(question, targets),
                                  ),
                                2 => _SettingsStep(
                                    titleCtrl: _titleCtrl,
                                    descriptionCtrl: _descriptionCtrl,
                                    instructionsCtrl: _instructionsCtrl,
                                    durationCtrl: _durationCtrl,
                                    attemptsCtrl: _attemptsCtrl,
                                    passingScoreCtrl: _passingScoreCtrl,
                                    examType: _examType,
                                    selectedTemplate: _selectedTemplate,
                                    availableFrom: _availableFrom,
                                    availableTo: _availableTo,
                                    shuffleQuestions: _shuffleQuestions,
                                    shuffleAnswers: _shuffleAnswers,
                                    showResultImmediately: _showResultImmediately,
                                    allowReview: _allowReview,
                                    publishAfterSave: _publishAfterSave,
                                    totalPoints: _totalPoints,
                                    onExamTypeChanged: (value) => setState(() => _examType = value),
                                    onStartChanged: (value) => setState(() => _availableFrom = value),
                                    onEndChanged: (value) => setState(() => _availableTo = value),
                                    onShuffleQuestionsChanged: (value) => setState(() => _shuffleQuestions = value),
                                    onShuffleAnswersChanged: (value) => setState(() => _shuffleAnswers = value),
                                    onShowResultChanged: (value) => setState(() => _showResultImmediately = value),
                                    onAllowReviewChanged: (value) => setState(() => _allowReview = value),
                                    onPublishChanged: (value) => setState(() => _publishAfterSave = value),
                                  ),
                                _ => _PreviewStep(
                                    targets: targets,
                                    questions: selected,
                                    totalPoints: _totalPoints,
                                    title: _titleCtrl.text.trim(),
                                    publishAfterSave: _publishAfterSave,
                                    showResultImmediately: _showResultImmediately,
                                    allowReview: _allowReview,
                                  ),
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _FlowFooter(
              step: _step,
              saving: _saving,
              publishAfterSave: _publishAfterSave,
              onBack: _back,
              onNext: () => _next(targets),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _replaceQuestion(QuestionModel original, List<_TopicTarget> targets) async {
    final replacement = await showDialog<QuestionModel>(
      context: context,
      builder: (_) => _ReplaceQuestionDialog(
        original: original,
        candidates: _replacementCandidates(original, targets, relaxed: false),
        relaxedCandidates: _replacementCandidates(original, targets, relaxed: true),
      ),
    );
    final newId = replacement?.remoteId;
    final oldId = original.remoteId;
    if (newId == null || oldId == null || !mounted) return;
    setState(() {
      final index = _selectedQuestionIds.indexOf(oldId);
      if (index == -1) return;
      _selectedQuestionIds[index] = newId;
      final seen = <int>{};
      _selectedQuestionIds.removeWhere((id) => !seen.add(id));
    });
  }

  List<QuestionModel> _replacementCandidates(
    QuestionModel original,
    List<_TopicTarget> targets, {
    required bool relaxed,
  }) {
    final selected = _selectedQuestionIds.toSet();
    final originalId = original.remoteId;
    final originalLoIds = original.learningOutcomes.map((lo) => lo.id).toSet();
    return _scopeQuestions(targets).where((candidate) {
      final id = candidate.remoteId;
      if (id == null || id == originalId || selected.contains(id)) return false;
      if (!relaxed) {
        if (candidate.type != original.type) return false;
        if (candidate.difficulty != original.difficulty) return false;
        final sameTopic = candidate.topicId != null && candidate.topicId == original.topicId;
        final sharesLo = originalLoIds.isNotEmpty &&
            candidate.learningOutcomes.any((lo) => originalLoIds.contains(lo.id));
        return sameTopic || sharesLo;
      }
      if (candidate.type == original.type) return true;
      final sameTopic = candidate.topicId != null && candidate.topicId == original.topicId;
      final sharesLo = originalLoIds.isNotEmpty &&
          candidate.learningOutcomes.any((lo) => originalLoIds.contains(lo.id));
      return sameTopic || sharesLo;
    }).toList();
  }
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

  String get topicLabel => parentTopicTitle == null ? topic.title : '$parentTopicTitle / ${topic.title}';
}

