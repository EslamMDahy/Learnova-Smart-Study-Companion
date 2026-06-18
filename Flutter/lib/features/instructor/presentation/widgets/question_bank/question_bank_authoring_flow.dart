import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/ui/toast.dart';
import '../../../../../core/storage/key_value_store_factory.dart';
import '../../../../../shared/widgets/components/dropdowns.dart';
import '../../../../../shared/widgets/components/inputs.dart';
import '../../../data/courses_models.dart';
import '../../../data/materials_models.dart';
import '../../../data/modules_materials_providers.dart';
import '../../../data/questions_api.dart';
import '../../../data/question_bank_refresh_signal.dart';
import '../../../data/modules_models.dart';
import '../../../data/question_models.dart';
import '../../../data/question_vocabulary.dart';
import '../../../data/topics_models.dart';
import '../../controllers/course_details_controller.dart';
import '../../controllers/course_details_state.dart';
import '../add_question_sheet.dart' as add_question_sheet;

enum _WorkspaceMode { manual, ai, review }
enum _WorkspaceExitAction { exit }

enum QuestionAuthoringScopeKind { module, material, topic, subtopic, selection }

class QuestionAuthoringLaunchContext {
  final QuestionAuthoringScopeKind kind;
  final String title;
  final String subtitle;
  final int? selectedModuleId;
  final int? selectedMaterialId;
  final int? selectedTopicId;
  final Set<int> selectedModuleIds;
  final Set<int> selectedMaterialIds;
  final Set<int> selectedTopicIds;
  final List<add_question_sheet.QuestionAuthoringTarget> targetSnapshots;

  const QuestionAuthoringLaunchContext({
    required this.kind,
    required this.title,
    required this.subtitle,
    this.selectedModuleId,
    this.selectedMaterialId,
    this.selectedTopicId,
    this.selectedModuleIds = const <int>{},
    this.selectedMaterialIds = const <int>{},
    this.selectedTopicIds = const <int>{},
    this.targetSnapshots = const <add_question_sheet.QuestionAuthoringTarget>[],
  });

  String get label {
    switch (kind) {
      case QuestionAuthoringScopeKind.module:
        return 'Module scope';
      case QuestionAuthoringScopeKind.material:
        return 'Material scope';
      case QuestionAuthoringScopeKind.topic:
        return 'Topic scope';
      case QuestionAuthoringScopeKind.subtopic:
        return 'Subtopic scope';
      case QuestionAuthoringScopeKind.selection:
        return 'Custom selection';
    }
  }
}


class QuestionBankAuthoringFlow extends ConsumerStatefulWidget {
  final MyCourseItem course;
  final Set<int> initialModuleIds;
  final Set<int> initialMaterialIds;
  final Set<int> initialTopicIds;
  final bool embedded;
  final QuestionAuthoringLaunchContext? launchContext;
  final VoidCallback? onClose;
  final VoidCallback? onSavedToQuestionBank;

  const QuestionBankAuthoringFlow({
    super.key,
    required this.course,
    this.initialModuleIds = const <int>{},
    this.initialMaterialIds = const <int>{},
    this.initialTopicIds = const <int>{},
    this.embedded = false,
    this.launchContext,
    this.onClose,
    this.onSavedToQuestionBank,
  });

  @override
  ConsumerState<QuestionBankAuthoringFlow> createState() =>
      _QuestionBankAuthoringFlowState();
}

class _QuestionBankAuthoringFlowState
    extends ConsumerState<QuestionBankAuthoringFlow> {
  bool _loading = false;
  _WorkspaceMode _mode = _WorkspaceMode.manual;

  List<add_question_sheet.QuestionAuthoringTarget> _targets =
      const <add_question_sheet.QuestionAuthoringTarget>[];
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _selectedQuestionIds = <String>{};
  final List<QuestionModel> _draftQuestions = <QuestionModel>[];
  late final _draftStore = createLocalStore();

  String get _draftStateKey {
    String pack(Set<int> values) {
      final List<int> sorted = values.toList()..sort();
      return sorted.join('-');
    }

    final Set<int> launchModules = widget.launchContext?.selectedModuleIds ?? const <int>{};
    final Set<int> launchMaterials = widget.launchContext?.selectedMaterialIds ?? const <int>{};
    final Set<int> launchTopics = widget.launchContext?.selectedTopicIds ?? const <int>{};
    final Set<int> moduleIds = widget.initialModuleIds.isNotEmpty ? widget.initialModuleIds : launchModules;
    final Set<int> materialIds = widget.initialMaterialIds.isNotEmpty ? widget.initialMaterialIds : launchMaterials;
    final Set<int> topicIds = widget.initialTopicIds.isNotEmpty ? widget.initialTopicIds : launchTopics;

    return 'learnova:qauthor:${widget.course.id}:m=${pack(moduleIds)}:f=${pack(materialIds)}:t=${pack(topicIds)}';
  }


  String get _draftCourseKey => 'learnova:qauthor:${widget.course.id}:last';

  // ── AI polling state ──────────────────────────────────────────────────────
  Timer? _aiPollTimer;
  bool _aiPolling = false;
  int _aiPollAttempts = 0;
  static const int _kMaxPollAttempts = 180;
  // The current backend accepts the AI generation request, then persists the
  // generated questions later from the AI callback. It does not return a
  // request_id/status endpoint, so the frontend watches the selected topic
  // question lists every 10 seconds and only adds rows that were not known
  // before the request started.
  static const Duration _kFirstAiPollDelay = Duration(seconds: 10);
  static const Duration _kResumeAiQuietDelay = Duration(seconds: 10);
  static const Duration _kCallbackWatchDelay = Duration(seconds: 10);
  static const Duration _kNormalAiPollDelay = Duration(seconds: 10);
  static const Duration _kLateAiPollDelay = Duration(seconds: 10);
  static const int _kMaxInitialQuestionDetailsToHydrate = 20;
  // Known question IDs before generation started (to detect new arrivals).
  // Filled from the questions already in the workspace so we do not need an
  // extra GET before calling the AI endpoint.
  Set<int> _knownRemoteIds = <int>{};
  Set<int> _pendingAiRequestTopicIds = <int>{};
  Set<int> _receivedAiQuestionIds = <int>{};
  int _pendingAiExpectedCount = 0;
  String? _pendingAiRequestId;
  DateTime? _pendingAiStartedAt;
  bool _aiPollInFlight = false;
  bool _remoteQuestionsLoadInFlight = false;
  bool _remoteQuestionsHiddenForSession = false;
  final Set<int> _detailHydrationInFlightIds = <int>{};
  final Set<int> _hydratedRemoteDetailIds = <int>{};

  int? _selectedTopicFilterId;
  String _selectedDifficultyFilter = 'Any Difficulty';
  String _selectedTypeFilter = 'All Types';
  String _selectedSourceFilter = 'All Sources';

  @override
  void initState() {
    super.initState();
    _bootstrapLocalState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_hydrateInitialBackendState());
      if (_aiPolling) {
        _scheduleNextAiPoll(_resumeAiQuietDelay());
      }
    });
  }

  @override
  void dispose() {
    _persistDraftState();
    _aiPollTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _bootstrapLocalState() {
    final List<add_question_sheet.QuestionAuthoringTarget> launchTargets =
        _fallbackTargetsFromLaunchContext();
    final _StoredQuestionWorkspace? stored = _restoreDraftState(launchTargets);

    final List<add_question_sheet.QuestionAuthoringTarget> storedTargets =
        stored?.targets ?? const <add_question_sheet.QuestionAuthoringTarget>[];
    _targets = _initialTargetsForLaunch(
      storedTargets: storedTargets,
      launchTargets: launchTargets,
      hasStoredQuestions: (stored?.questions.isNotEmpty ?? false),
    );

    if (stored != null && _targets.isEmpty && stored.questions.isNotEmpty) {
      _targets = _targetsFromQuestions(stored.questions);
    }

    if (stored != null) {
      _draftQuestions
        ..clear()
        ..addAll(stored.questions);
      _selectedQuestionIds
        ..clear()
        ..addAll(stored.selectedIds.intersection(
          stored.questions.map((QuestionModel question) => question.id).toSet(),
        ));
      _mode = stored.mode;
      _aiPolling = stored.aiPolling &&
          ((stored.pendingAiRequestId ?? '').isNotEmpty ||
              stored.pendingAiRequestTopicIds.isNotEmpty) &&
          (stored.pendingAiExpectedCount <= 0 ||
              stored.receivedAiQuestionIds.length < stored.pendingAiExpectedCount);
      _aiPollAttempts = stored.aiPollAttempts;
      _pendingAiExpectedCount = stored.pendingAiExpectedCount;
      _pendingAiRequestId = stored.pendingAiRequestId;
      _pendingAiStartedAt = stored.pendingAiStartedAt;
      _pendingAiRequestTopicIds = Set<int>.from(stored.pendingAiRequestTopicIds);
      _receivedAiQuestionIds = Set<int>.from(stored.receivedAiQuestionIds);
      _knownRemoteIds = <int>{
        ...stored.knownRemoteIds,
        ...stored.questions.map((QuestionModel question) => question.remoteId).whereType<int>(),
      };
    }

    _loading = false;
    if (_targets.isNotEmpty || _draftQuestions.isNotEmpty || _aiPolling) {
      _persistDraftState();
    }
  }


  List<add_question_sheet.QuestionAuthoringTarget> _initialTargetsForLaunch({
    required List<add_question_sheet.QuestionAuthoringTarget> storedTargets,
    required List<add_question_sheet.QuestionAuthoringTarget> launchTargets,
    required bool hasStoredQuestions,
  }) {
    // Exact refresh restores the same target set. Course-level drafts only
    // merge with a new launch when there is real unsaved question work.
    // Stale target-only course backups must not expand a single selected
    // subtopic into the whole previous material.
    if (launchTargets.isEmpty) return storedTargets;
    if (!hasStoredQuestions) return launchTargets;
    return _mergeTargets(storedTargets, launchTargets);
  }

  List<add_question_sheet.QuestionAuthoringTarget> _mergeTargets(
    List<add_question_sheet.QuestionAuthoringTarget> storedTargets,
    List<add_question_sheet.QuestionAuthoringTarget> incomingTargets,
  ) {
    final Map<int, add_question_sheet.QuestionAuthoringTarget> byTopicId =
        <int, add_question_sheet.QuestionAuthoringTarget>{};

    for (final add_question_sheet.QuestionAuthoringTarget target in storedTargets) {
      byTopicId[target.topicId] = target;
    }
    for (final add_question_sheet.QuestionAuthoringTarget target in incomingTargets) {
      byTopicId[target.topicId] = target;
    }

    return byTopicId.values.toList()
      ..sort((add_question_sheet.QuestionAuthoringTarget a, add_question_sheet.QuestionAuthoringTarget b) {
        final int moduleCompare = (a.moduleId ?? 0).compareTo(b.moduleId ?? 0);
        if (moduleCompare != 0) return moduleCompare;
        final int materialCompare = (a.materialId ?? 0).compareTo(b.materialId ?? 0);
        if (materialCompare != 0) return materialCompare;
        return a.topicId.compareTo(b.topicId);
      });
  }

  List<add_question_sheet.QuestionAuthoringTarget> _targetsFromQuestions(
    List<QuestionModel> questions,
  ) {
    final Map<int, add_question_sheet.QuestionAuthoringTarget> byTopic =
        <int, add_question_sheet.QuestionAuthoringTarget>{};
    for (final QuestionModel question in questions) {
      final int? topicId = question.topicId;
      final String topicName = (question.topicName ?? '').trim();
      if (topicId == null || topicName.isEmpty) continue;
      byTopic[topicId] = add_question_sheet.QuestionAuthoringTarget(
        moduleId: question.moduleId,
        moduleName: question.moduleName,
        materialId: question.materialId,
        materialName: question.materialName,
        topicId: topicId,
        topicName: topicName,
        isSubtopic: true,
      );
    }
    return byTopic.values.toList()
      ..sort((add_question_sheet.QuestionAuthoringTarget a, add_question_sheet.QuestionAuthoringTarget b) {
        final int moduleCompare = (a.moduleId ?? 0).compareTo(b.moduleId ?? 0);
        if (moduleCompare != 0) return moduleCompare;
        final int materialCompare = (a.materialId ?? 0).compareTo(b.materialId ?? 0);
        if (materialCompare != 0) return materialCompare;
        return a.topicId.compareTo(b.topicId);
      });
  }

  Future<void> _hydrateInitialBackendState() async {
    if (_targets.isEmpty) {
      await _hydrateTargetsFromBackend();
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      await _hydrateTargetsFromBackend();
    }

    if (!mounted) return;
    await _loadRemoteQuestionsForTargets();
  }

  Future<void> _loadRemoteQuestionsForTargets({bool hydrateDetails = true}) async {
    if (_remoteQuestionsLoadInFlight || _targets.isEmpty) return;

    final Set<int> targetTopicIds = _targets
        .map((add_question_sheet.QuestionAuthoringTarget target) => target.topicId)
        .toSet();
    if (targetTopicIds.isEmpty) return;

    _remoteQuestionsLoadInFlight = true;
    try {
      final QuestionsApi api = ref.read(questionsApiProvider);
      final CourseQuestionsResponse resp = await api.getCourseQuestions(
        courseId: widget.course.id,
      );

      if (!mounted || _remoteQuestionsHiddenForSession) return;

      final List<QuestionModel> relevant = resp.questions
          .where((QuestionModel question) =>
              question.topicId != null && targetTopicIds.contains(question.topicId))
          .toList()
        ..sort((QuestionModel a, QuestionModel b) => b.createdAt.compareTo(a.createdAt));

      if (relevant.isEmpty) return;

      setState(() {
        _upsertDraftQuestions(relevant);
        _selectedQuestionIds.clear();
      });
      _persistDraftState();

      if (hydrateDetails && !_aiPolling) {
        unawaited(
          _hydrateMissingQuestionDetails(
            relevant,
            maxCount: _kMaxInitialQuestionDetailsToHydrate,
          ),
        );
      }
    } catch (_) {
      // Initial DB hydration is a convenience layer only. The page should still
      // open from cached/local state if the backend is temporarily busy.
    } finally {
      _remoteQuestionsLoadInFlight = false;
    }
  }

  Future<void> _hydrateMissingQuestionDetails(
    List<QuestionModel> questions, {
    int? maxCount,
  }) async {
    final QuestionsApi api = ref.read(questionsApiProvider);
    final List<QuestionModel> candidates = questions
        .where(_questionNeedsAnswerDetails)
        .where((QuestionModel question) {
          final int? id = question.remoteId ?? int.tryParse(question.id);
          return id != null &&
              id > 0 &&
              !_hydratedRemoteDetailIds.contains(id) &&
              !_detailHydrationInFlightIds.contains(id);
        })
        .toList();

    final Iterable<QuestionModel> limited = maxCount == null
        ? candidates
        : candidates.take(maxCount);

    final List<QuestionModel> hydrated = <QuestionModel>[];
    for (final QuestionModel summary in limited) {
      if (!mounted) return;
      final int questionId = summary.remoteId ?? int.parse(summary.id);
      _detailHydrationInFlightIds.add(questionId);
      try {
        final QuestionModel details = await api.getQuestion(
          courseId: widget.course.id,
          questionId: questionId,
        );
        _hydratedRemoteDetailIds.add(questionId);
        hydrated.add(_mergeQuestionContext(details, summary));
      } catch (_) {
        // Keep the summary row visible even if details are temporarily busy.
      } finally {
        _detailHydrationInFlightIds.remove(questionId);
      }
    }

    if (!mounted || hydrated.isEmpty) return;
    setState(() => _upsertDraftQuestions(hydrated));
    _persistDraftState();
  }

  bool _questionNeedsAnswerDetails(QuestionModel question) {
    if ((question.expectedAnswer ?? '').trim().isNotEmpty) return false;
    if ((question.sampleAnswer ?? '').trim().isNotEmpty) return false;
    if (question.correctBool != null) return false;
    if ((question.correctOptionId ?? '').trim().isNotEmpty) return false;
    if (question.options.any((QuestionOption option) => option.isCorrect)) return false;
    return true;
  }

  Future<void> _hydrateTargetsFromBackend() async {
    final controller = ref.read(
      courseDetailsControllerProvider(widget.course.id).notifier,
    );
    await controller.loadModules();
    if (!mounted) return;

    final dynamic beforeLoad = ref.read(
      courseDetailsControllerProvider(widget.course.id),
    );
    final Set<int> moduleIdsToLoad = _moduleIdsForHydration(beforeLoad);
    final Set<int> materialIdsToLoad = _materialIdsForHydration(beforeLoad);

    if (moduleIdsToLoad.isEmpty) {
      await controller.loadModulesAndAllMaterials();
    } else {
      for (final int moduleId in moduleIdsToLoad) {
        await controller.loadMaterials(moduleId);
        if (!mounted) return;

        final CourseDetailsState afterMaterials = ref.read(
          courseDetailsControllerProvider(widget.course.id),
        );
        final List<MaterialItem> moduleMaterials =
            afterMaterials.materials[moduleId] ?? const <MaterialItem>[];
        final List<int> targetedMaterialIds = materialIdsToLoad.isEmpty
            ? const <int>[]
            : moduleMaterials
                .map((MaterialItem material) => material.id)
                .where(materialIdsToLoad.contains)
                .toList();

        if (targetedMaterialIds.isEmpty) {
          await controller.loadTopics(moduleId);
          if (!mounted) return;
        } else {
          for (final int materialId in targetedMaterialIds) {
            await controller.loadTopicsForMaterial(
              moduleId: moduleId,
              materialId: materialId,
            );
            if (!mounted) return;
          }
        }
      }
    }
    if (!mounted) return;

    final dynamic st = ref.read(courseDetailsControllerProvider(widget.course.id));
    final List<add_question_sheet.QuestionAuthoringTarget> resolved = _resolveTargets(st);
    if (resolved.isEmpty) return;

    setState(() {
      _targets = _replaceOrMergeHydratedTargets(resolved);
      if (_selectedTopicFilterId != null &&
          !_targets.any((add_question_sheet.QuestionAuthoringTarget target) =>
              target.topicId == _selectedTopicFilterId)) {
        _selectedTopicFilterId = null;
      }
    });
    _persistDraftState();
  }


  List<add_question_sheet.QuestionAuthoringTarget> _replaceOrMergeHydratedTargets(
    List<add_question_sheet.QuestionAuthoringTarget> resolved,
  ) {
    if (resolved.isEmpty) return _targets;
    if (_launchHasExplicitTargetSnapshots || _launchSelectedTopicIds.isNotEmpty) {
      if (_draftQuestions.isNotEmpty) {
        return _mergeTargets(_targets, resolved);
      }
      return _mergeTargets(const <add_question_sheet.QuestionAuthoringTarget>[], resolved);
    }
    return _mergeTargets(_targets, resolved);
  }

  bool get _launchHasExplicitTargetSnapshots =>
      (widget.launchContext?.targetSnapshots.isNotEmpty ?? false);

  Set<int> get _launchSelectedTopicIds => <int>{
        ...widget.initialTopicIds,
        ...(widget.launchContext?.selectedTopicIds ?? const <int>{}),
        if (widget.launchContext?.selectedTopicId != null)
          widget.launchContext!.selectedTopicId!,
      };

  Set<int> _moduleIdsForHydration(dynamic st) {
    final QuestionAuthoringLaunchContext? launch = widget.launchContext;
    final Set<int> moduleIds = <int>{
      ...widget.initialModuleIds,
      ...(launch?.selectedModuleIds ?? const <int>{}),
      if (launch?.selectedModuleId != null) launch!.selectedModuleId!,
      ..._targets.map((add_question_sheet.QuestionAuthoringTarget target) => target.moduleId).whereType<int>(),
    };
    if (moduleIds.isNotEmpty) return moduleIds;

    final Set<int> materialIds = <int>{
      ...widget.initialMaterialIds,
      ...(launch?.selectedMaterialIds ?? const <int>{}),
      if (launch?.selectedMaterialId != null) launch!.selectedMaterialId!,
      ..._targets.map((add_question_sheet.QuestionAuthoringTarget target) => target.materialId).whereType<int>(),
    };
    if (materialIds.isNotEmpty) {
      final Map<int, List<MaterialItem>> materialsMap =
          Map<int, List<MaterialItem>>.from(st.materials as Map<dynamic, dynamic>);
      for (final MapEntry<int, List<MaterialItem>> entry in materialsMap.entries) {
        if (entry.value.any((MaterialItem material) => materialIds.contains(material.id))) {
          moduleIds.add(entry.key);
        }
      }
    }
    return moduleIds;
  }

  Set<int> _materialIdsForHydration(dynamic st) {
    final QuestionAuthoringLaunchContext? launch = widget.launchContext;
    final Set<int> materialIds = <int>{
      ...widget.initialMaterialIds,
      ...(launch?.selectedMaterialIds ?? const <int>{}),
      if (launch?.selectedMaterialId != null) launch!.selectedMaterialId!,
      ..._targets
          .map((add_question_sheet.QuestionAuthoringTarget target) => target.materialId)
          .whereType<int>(),
    };

    // When only explicit topic IDs are available, try to discover their
    // material from already-cached topics without loading every material.
    if (materialIds.isEmpty) {
      final Set<int> topicIds = _launchSelectedTopicIds;
      final Map<int, List<TopicItem>> topicsMap =
          Map<int, List<TopicItem>>.from(st.topics as Map<dynamic, dynamic>);
      for (final List<TopicItem> topics in topicsMap.values) {
        for (final TopicItem topic in topics) {
          if (topicIds.contains(topic.id)) materialIds.add(topic.materialId);
        }
      }
    }

    return materialIds;
  }

  List<add_question_sheet.QuestionAuthoringTarget> _fallbackTargetsFromLaunchContext() {
    final QuestionAuthoringLaunchContext? launch = widget.launchContext;
    final List<add_question_sheet.QuestionAuthoringTarget> snapshots =
        launch?.targetSnapshots ?? const <add_question_sheet.QuestionAuthoringTarget>[];
    if (snapshots.isNotEmpty) {
      final Map<int, add_question_sheet.QuestionAuthoringTarget> byTopic =
          <int, add_question_sheet.QuestionAuthoringTarget>{};
      for (final add_question_sheet.QuestionAuthoringTarget target in snapshots) {
        byTopic[target.topicId] = target;
      }
      return byTopic.values.toList()
        ..sort((add_question_sheet.QuestionAuthoringTarget a, add_question_sheet.QuestionAuthoringTarget b) {
          final int moduleCompare = (a.moduleId ?? 0).compareTo(b.moduleId ?? 0);
          if (moduleCompare != 0) return moduleCompare;
          final int materialCompare = (a.materialId ?? 0).compareTo(b.materialId ?? 0);
          if (materialCompare != 0) return materialCompare;
          return a.topicId.compareTo(b.topicId);
        });
    }

    final Set<int> topicIds = <int>{
      ...widget.initialTopicIds,
      ...(launch?.selectedTopicIds ?? const <int>{}),
      if (launch?.selectedTopicId != null) launch!.selectedTopicId!,
    };

    if (topicIds.isEmpty) return const <add_question_sheet.QuestionAuthoringTarget>[];

    final List<int> sortedTopicIds = topicIds.toList()..sort();
    final Set<int> moduleIds = <int>{
      ...widget.initialModuleIds,
      ...(launch?.selectedModuleIds ?? const <int>{}),
      if (launch?.selectedModuleId != null) launch!.selectedModuleId!,
    };
    final Set<int> materialIds = <int>{
      ...widget.initialMaterialIds,
      ...(launch?.selectedMaterialIds ?? const <int>{}),
      if (launch?.selectedMaterialId != null) launch!.selectedMaterialId!,
    };

    final int? moduleId = moduleIds.length == 1 ? moduleIds.first : launch?.selectedModuleId;
    final int? materialId = materialIds.length == 1 ? materialIds.first : launch?.selectedMaterialId;
    final bool singleTopic = sortedTopicIds.length == 1;
    final bool launchIsSubtopic = launch?.kind == QuestionAuthoringScopeKind.subtopic;

    return <add_question_sheet.QuestionAuthoringTarget>[
      for (final int topicId in sortedTopicIds)
        add_question_sheet.QuestionAuthoringTarget(
          moduleId: moduleId,
          moduleName: moduleId == null ? null : widget.course.title,
          materialId: materialId,
          materialName: materialId == null ? null : launch?.title,
          topicId: topicId,
          topicName: singleTopic && launch != null
              ? launch.title
              : 'Selected topic $topicId',
          isSubtopic: launchIsSubtopic,
        ),
    ];
  }

  List<add_question_sheet.QuestionAuthoringTarget> _resolveTargets(dynamic st) {
    final List<ModuleItem> modules = st.modules as List<ModuleItem>;
    final Map<int, List<MaterialItem>> materialsMap =
        Map<int, List<MaterialItem>>.from(st.materials as Map<dynamic, dynamic>);
    final Map<int, List<TopicItem>> topicsMap =
        Map<int, List<TopicItem>>.from(st.topics as Map<dynamic, dynamic>);

    final List<add_question_sheet.QuestionAuthoringTarget> snapshotTargets =
        widget.launchContext?.targetSnapshots ?? const <add_question_sheet.QuestionAuthoringTarget>[];
    if (snapshotTargets.isNotEmpty) {
      return _mergeTargets(
        const <add_question_sheet.QuestionAuthoringTarget>[],
        snapshotTargets,
      );
    }

    final List<add_question_sheet.QuestionAuthoringTarget> resolved =
        <add_question_sheet.QuestionAuthoringTarget>[];
    final Set<int> seen = <int>{};
    final Set<int> effectiveTopicIds = _launchSelectedTopicIds;
    final QuestionAuthoringScopeKind? kind = widget.launchContext?.kind;
    final bool expandMaterials = effectiveTopicIds.isEmpty ||
        kind == QuestionAuthoringScopeKind.material ||
        kind == QuestionAuthoringScopeKind.module ||
        kind == QuestionAuthoringScopeKind.selection;
    final bool expandModules = effectiveTopicIds.isEmpty ||
        kind == QuestionAuthoringScopeKind.module;
    final Set<int> effectiveMaterialIds = expandMaterials
        ? (widget.initialMaterialIds.isNotEmpty
            ? widget.initialMaterialIds
            : (widget.launchContext?.selectedMaterialIds ?? const <int>{}))
        : const <int>{};
    final Set<int> effectiveModuleIds = expandModules
        ? (widget.initialModuleIds.isNotEmpty
            ? widget.initialModuleIds
            : (widget.launchContext?.selectedModuleIds ?? const <int>{}))
        : const <int>{};

    ModuleItem? findModule(int id) {
      for (final ModuleItem module in modules) {
        if (module.id == id) return module;
      }
      return null;
    }

    MaterialItem? findMaterial(int id) {
      for (final List<MaterialItem> mats in materialsMap.values) {
        for (final MaterialItem material in mats) {
          if (material.id == id) return material;
        }
      }
      return null;
    }

    TopicItem? findTopic(int id) {
      for (final List<TopicItem> topics in topicsMap.values) {
        for (final TopicItem topic in topics) {
          if (topic.id == id) return topic;
        }
      }
      return null;
    }

    void addLeafTargets(
      ModuleItem module,
      MaterialItem material,
      TopicItem topic,
      List<TopicItem> materialTopics,
    ) {
      final List<TopicItem> children = materialTopics
          .where((TopicItem item) => item.parentTopicId == topic.id)
          .toList()
        ..sort((TopicItem a, TopicItem b) =>
            a.orderIndex.compareTo(b.orderIndex),);

      if (children.isEmpty || topic.parentTopicId != null) {
        if (seen.add(topic.id)) {
          TopicItem? parent;
          if (topic.parentTopicId != null) {
            for (final TopicItem item in materialTopics) {
              if (item.id == topic.parentTopicId) {
                parent = item;
                break;
              }
            }
          }

          resolved.add(
            add_question_sheet.QuestionAuthoringTarget(
              moduleId: module.id,
              moduleName: module.title,
              materialId: material.id,
              materialName: material.displayTitle,
              topicId: topic.id,
              topicName: topic.title,
              isSubtopic: topic.parentTopicId != null,
              parentTopicName: parent?.title,
            ),
          );
        }
        return;
      }

      for (final TopicItem child in children) {
        addLeafTargets(module, material, child, materialTopics);
      }
    }

    for (final int topicId in effectiveTopicIds) {
      final TopicItem? topic = findTopic(topicId);
      if (topic == null) continue;
      final MaterialItem? material = findMaterial(topic.materialId);
      if (material == null) continue;
      final ModuleItem? module = findModule(material.moduleId);
      if (module == null) continue;
      final List<TopicItem> materialTopics =
          (topicsMap[module.id] ?? const <TopicItem>[])
              .where((TopicItem item) => item.materialId == material.id)
              .toList();
      addLeafTargets(module, material, topic, materialTopics);
    }

    for (final int materialId in effectiveMaterialIds) {
      final MaterialItem? material = findMaterial(materialId);
      if (material == null) continue;
      final ModuleItem? module = findModule(material.moduleId);
      if (module == null) continue;
      final List<TopicItem> materialTopics =
          (topicsMap[module.id] ?? const <TopicItem>[])
              .where((TopicItem item) => item.materialId == material.id)
              .toList();
      final List<TopicItem> roots = materialTopics
          .where((TopicItem item) => item.parentTopicId == null)
          .toList()
        ..sort((TopicItem a, TopicItem b) =>
            a.orderIndex.compareTo(b.orderIndex),);
      for (final TopicItem root in roots) {
        addLeafTargets(module, material, root, materialTopics);
      }
    }

    for (final int moduleId in effectiveModuleIds) {
      final ModuleItem? module = findModule(moduleId);
      if (module == null) continue;
      final List<MaterialItem> materials =
          materialsMap[module.id] ?? const <MaterialItem>[];
      final List<TopicItem> moduleTopics =
          topicsMap[module.id] ?? const <TopicItem>[];
      for (final MaterialItem material in materials) {
        final List<TopicItem> materialTopics = moduleTopics
            .where((TopicItem item) => item.materialId == material.id)
            .toList();
        final List<TopicItem> roots = materialTopics
            .where((TopicItem item) => item.parentTopicId == null)
            .toList()
          ..sort((TopicItem a, TopicItem b) =>
              a.orderIndex.compareTo(b.orderIndex),);
        for (final TopicItem root in roots) {
          addLeafTargets(module, material, root, materialTopics);
        }
      }
    }

    return resolved;
  }

  void _setMode(_WorkspaceMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    _persistDraftState();
  }

  _StoredQuestionWorkspace? _restoreDraftState(
    List<add_question_sheet.QuestionAuthoringTarget> fallbackTargets,
  ) {
    _StoredQuestionWorkspace? targetOnlyFallback;

    for (final String key in <String>[_draftStateKey, _draftCourseKey]) {
      final String? raw = _draftStore.getString(key);
      if (raw == null || raw.trim().isEmpty) continue;

      try {
        final _StoredQuestionWorkspace? parsed = _parseStoredWorkspace(
          raw,
          fallbackTargets,
        );
        if (parsed == null) continue;

        // A draft that contains questions or a running AI request is the real source of truth.
        // Exact target-only snapshots are allowed, but they must never block
        // restoring the course-level question draft created by Save draft.
        if (parsed.questions.isNotEmpty || parsed.aiPolling) return parsed;
        targetOnlyFallback ??= parsed;
      } catch (_) {
        _draftStore.remove(key);
      }
    }

    return targetOnlyFallback;
  }

  _StoredQuestionWorkspace? _parseStoredWorkspace(
    String raw,
    List<add_question_sheet.QuestionAuthoringTarget> fallbackTargets,
  ) {
    final Map<String, dynamic> data =
        Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final List<add_question_sheet.QuestionAuthoringTarget> storedTargets =
        ((data['targets'] as List?) ?? const <dynamic>[])
            .whereType<Map>()
            .map((Map item) => _targetFromDraftJson(Map<String, dynamic>.from(item)))
            .whereType<add_question_sheet.QuestionAuthoringTarget>()
            .toList();
    final List<add_question_sheet.QuestionAuthoringTarget> seedTargets =
        storedTargets.isNotEmpty ? storedTargets : fallbackTargets;
    final List<dynamic> rawQuestions =
        (data['questions'] as List?) ?? const <dynamic>[];
    final List<QuestionModel> questions = rawQuestions
        .whereType<Map>()
        .map((Map item) => _questionFromDraftJson(
              Map<String, dynamic>.from(item),
              seedTargets,
            ))
        .whereType<QuestionModel>()
        .toList();
    final List<add_question_sheet.QuestionAuthoringTarget> derivedTargets =
        _targetsFromQuestions(questions);
    final List<add_question_sheet.QuestionAuthoringTarget> effectiveTargets =
        storedTargets.isNotEmpty
            ? storedTargets
            : (derivedTargets.isNotEmpty ? derivedTargets : fallbackTargets);
    if (effectiveTargets.isEmpty && questions.isEmpty) return null;

    final Set<String> selectedIds =
        ((data['selectedIds'] as List?) ?? const <dynamic>[])
            .map((dynamic value) => value.toString())
            .toSet();
    final String rawMode =
        data['mode']?.toString() ?? _WorkspaceMode.manual.name;
    final _WorkspaceMode mode = _WorkspaceMode.values.firstWhere(
      (_WorkspaceMode item) => item.name == rawMode,
      orElse: () => _WorkspaceMode.manual,
    );
    final String? pendingAiRequestId = data['pendingAiRequestId'] == null
        ? null
        : data['pendingAiRequestId'].toString();
    final DateTime? pendingAiStartedAt = data['pendingAiStartedAt'] == null
        ? null
        : DateTime.tryParse(data['pendingAiStartedAt'].toString());
    final Set<int> pendingAiTopicIds = ((data['pendingAiRequestTopicIds'] as List?) ?? const <dynamic>[])
        .map((dynamic value) => value is num ? value.toInt() : int.tryParse(value.toString()))
        .whereType<int>()
        .toSet();
    final Set<int> receivedAiIds = ((data['receivedAiQuestionIds'] as List?) ?? const <dynamic>[])
        .map((dynamic value) => value is num ? value.toInt() : int.tryParse(value.toString()))
        .whereType<int>()
        .toSet();
    final Set<int> knownRemoteIds = ((data['knownRemoteIds'] as List?) ?? const <dynamic>[])
        .map((dynamic value) => value is num ? value.toInt() : int.tryParse(value.toString()))
        .whereType<int>()
        .toSet();
    return _StoredQuestionWorkspace(
      targets: effectiveTargets,
      questions: questions,
      selectedIds: selectedIds,
      mode: mode,
      aiPolling: data['aiPolling'] == true,
      aiPollAttempts: (data['aiPollAttempts'] as num?)?.toInt() ?? 0,
      pendingAiExpectedCount: (data['pendingAiExpectedCount'] as num?)?.toInt() ?? 0,
      pendingAiRequestId: pendingAiRequestId,
      pendingAiStartedAt: pendingAiStartedAt,
      pendingAiRequestTopicIds: pendingAiTopicIds,
      receivedAiQuestionIds: receivedAiIds,
      knownRemoteIds: knownRemoteIds,
    );
  }

  bool _storedWorkspaceHasQuestions(String key) {
    final String? raw = _draftStore.getString(key);
    if (raw == null || raw.trim().isEmpty) return false;
    try {
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return ((data['questions'] as List?) ?? const <dynamic>[]).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _persistDraftState() {
    final bool hasQuestionWork = _draftQuestions.isNotEmpty;
    final bool hasPendingAiWork = _aiPolling ||
        (_pendingAiRequestId?.isNotEmpty ?? false) ||
        _pendingAiRequestTopicIds.isNotEmpty ||
        _receivedAiQuestionIds.isNotEmpty;

    if (!hasQuestionWork &&
        !hasPendingAiWork &&
        _selectedQuestionIds.isEmpty &&
        _targets.isEmpty) {
      _draftStore.remove(_draftStateKey);
      if (!_storedWorkspaceHasQuestions(_draftCourseKey)) {
        _draftStore.remove(_draftCourseKey);
      }
      return;
    }

    final List<add_question_sheet.QuestionAuthoringTarget> targetsForPersist =
        _targets.isNotEmpty ? _targets : _targetsFromQuestions(_draftQuestions);
    final Map<String, dynamic> payload = <String, dynamic>{
      'courseId': widget.course.id,
      'mode': _mode.name,
      'savedAt': DateTime.now().toIso8601String(),
      'selectedIds': _selectedQuestionIds.toList(),
      'targets': targetsForPersist.map(_targetToDraftJson).toList(),
      'questions': _draftQuestions.map(_questionToDraftJson).toList(),
      'aiPolling': _aiPolling,
      'aiPollAttempts': _aiPollAttempts,
      'pendingAiExpectedCount': _pendingAiExpectedCount,
      'pendingAiRequestId': _pendingAiRequestId,
      'pendingAiStartedAt': _pendingAiStartedAt?.toIso8601String(),
      'pendingAiRequestTopicIds': _pendingAiRequestTopicIds.toList(),
      'receivedAiQuestionIds': _receivedAiQuestionIds.toList(),
      'knownRemoteIds': _knownRemoteIds.toList(),
    };
    final String encoded = jsonEncode(payload);
    _draftStore.setString(_draftStateKey, encoded);

    // The Materials banner resumes from the course-level key. Never replace a
    // question-bearing draft with a target-only workspace state; that was the
    // reason Continue opened an empty workspace and then removed the banner.
    if (hasQuestionWork || hasPendingAiWork || !_storedWorkspaceHasQuestions(_draftCourseKey)) {
      _draftStore.setString(_draftCourseKey, encoded);
    }
  }

  bool get _hasUnsavedDraftWork => _draftQuestions.isNotEmpty || _targets.isNotEmpty;

  void _clearDraftState() {
    _draftStore.remove(_draftStateKey);
    _draftStore.remove(_draftCourseKey);
  }

  Map<String, dynamic> _targetToDraftJson(
    add_question_sheet.QuestionAuthoringTarget target,
  ) {
    return <String, dynamic>{
      'moduleId': target.moduleId,
      'moduleName': target.moduleName,
      'materialId': target.materialId,
      'materialName': target.materialName,
      'topicId': target.topicId,
      'topicName': target.topicName,
      'isSubtopic': target.isSubtopic,
      'parentTopicName': target.parentTopicName,
    };
  }

  add_question_sheet.QuestionAuthoringTarget? _targetFromDraftJson(
    Map<String, dynamic> json,
  ) {
    final int? topicId = (json['topicId'] as num?)?.toInt();
    final String topicName = json['topicName']?.toString() ?? '';
    if (topicId == null || topicName.trim().isEmpty) return null;
    return add_question_sheet.QuestionAuthoringTarget(
      moduleId: (json['moduleId'] as num?)?.toInt(),
      moduleName: json['moduleName']?.toString(),
      materialId: (json['materialId'] as num?)?.toInt(),
      materialName: json['materialName']?.toString(),
      topicId: topicId,
      topicName: topicName,
      isSubtopic: json['isSubtopic'] == true,
      parentTopicName: json['parentTopicName']?.toString(),
    );
  }

  Map<String, dynamic> _questionToDraftJson(QuestionModel question) {
    return <String, dynamic>{
      'id': question.id,
      'remoteId': question.remoteId,
      'text': question.text,
      'type': question.type.name,
      'difficulty': question.difficulty.name,
      'source': question.source.name,
      'approvalStatus': question.approvalStatus.name,
      'options': question.options
          .map((QuestionOption option) => <String, dynamic>{
                'id': option.id,
                'text': option.text,
                'isCorrect': option.isCorrect,
                'explanation': option.explanation,
                'orderIndex': option.orderIndex,
              })
          .toList(),
      'correctOptionId': question.correctOptionId,
      'correctBool': question.correctBool,
      'sampleAnswer': question.sampleAnswer,
      'explanation': question.explanation,
      'expectedAnswer': question.expectedAnswer,
      'tags': question.tags,
      'usageCount': question.usageCount,
      'successRate': question.successRate,
      'maxScore': question.maxScore,
      'autoGradable': question.autoGradable,
      'courseId': question.courseId,
      'moduleId': question.moduleId,
      'moduleName': question.moduleName,
      'materialId': question.materialId,
      'materialName': question.materialName,
      'topicId': question.topicId,
      'topicName': question.topicName,
      'learningOutcomes': question.learningOutcomes
          .map((QuestionLearningOutcomeRef lo) => <String, dynamic>{
                'id': lo.id,
                'title': lo.title,
              })
          .toList(),
      'createdAt': question.createdAt.toIso8601String(),
      'updatedAt': question.updatedAt.toIso8601String(),
    };
  }

  QuestionModel? _questionFromDraftJson(
    Map<String, dynamic> json,
    List<add_question_sheet.QuestionAuthoringTarget> targets,
  ) {
    try {
      T enumByName<T>(List<T> values, String? name, T fallback) {
        for (final T value in values) {
          if ((value as dynamic).name == name) return value;
        }
        return fallback;
      }

      final int? topicId = (json['topicId'] as num?)?.toInt();
      add_question_sheet.QuestionAuthoringTarget? target;
      if (topicId != null) {
        for (final add_question_sheet.QuestionAuthoringTarget item in targets) {
          if (item.topicId == topicId) {
            target = item;
            break;
          }
        }
      }

      final List<QuestionOption> options = ((json['options'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((Map item) {
            final Map<String, dynamic> option = Map<String, dynamic>.from(item);
            return QuestionOption(
              id: option['id']?.toString() ?? option['orderIndex']?.toString() ?? '0',
              text: option['text']?.toString() ?? '',
              isCorrect: option['isCorrect'] == true,
              explanation: option['explanation']?.toString(),
              orderIndex: (option['orderIndex'] as num?)?.toInt() ?? 0,
            );
          })
          .toList();

      final List<QuestionLearningOutcomeRef> learningOutcomes =
          ((json['learningOutcomes'] as List?) ?? const <dynamic>[])
              .whereType<Map>()
              .map((Map item) {
                final Map<String, dynamic> lo = Map<String, dynamic>.from(item);
                return QuestionLearningOutcomeRef(
                  id: (lo['id'] as num?)?.toInt() ?? 0,
                  title: lo['title']?.toString() ?? '',
                );
              })
              .where((QuestionLearningOutcomeRef lo) => lo.id != 0)
              .toList();

      final DateTime createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now();
      final DateTime? updatedAt = DateTime.tryParse(json['updatedAt']?.toString() ?? '');

      return QuestionModel(
        id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        remoteId: (json['remoteId'] as num?)?.toInt(),
        text: json['text']?.toString() ?? '',
        type: enumByName<QuestionType>(
          QuestionType.values,
          json['type']?.toString(),
          QuestionType.multipleChoice,
        ),
        difficulty: enumByName<QuestionDifficulty>(
          QuestionDifficulty.values,
          json['difficulty']?.toString(),
          QuestionDifficulty.medium,
        ),
        source: enumByName<QuestionSource>(
          QuestionSource.values,
          json['source']?.toString(),
          QuestionSource.manual,
        ),
        approvalStatus: enumByName<QuestionApprovalStatus>(
          QuestionApprovalStatus.values,
          json['approvalStatus']?.toString(),
          QuestionApprovalStatus.pending,
        ),
        options: options,
        correctOptionId: json['correctOptionId']?.toString(),
        correctBool: json['correctBool'] is bool ? json['correctBool'] as bool : null,
        sampleAnswer: json['sampleAnswer']?.toString(),
        explanation: json['explanation']?.toString(),
        expectedAnswer: json['expectedAnswer']?.toString(),
        tags: ((json['tags'] as List?) ?? const <dynamic>[])
            .map((dynamic value) => value.toString())
            .toList(),
        usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
        successRate: (json['successRate'] as num?)?.toDouble(),
        maxScore: (json['maxScore'] as num?)?.toInt() ?? 1,
        autoGradable: json['autoGradable'] != false,
        courseId: (json['courseId'] as num?)?.toInt() ?? widget.course.id,
        moduleId: (json['moduleId'] as num?)?.toInt() ?? target?.moduleId,
        moduleName: json['moduleName']?.toString() ?? target?.moduleName,
        materialId: (json['materialId'] as num?)?.toInt() ?? target?.materialId,
        materialName: json['materialName']?.toString() ?? target?.materialName,
        topicId: topicId ?? target?.topicId,
        topicName: json['topicName']?.toString() ?? target?.topicName,
        learningOutcomes: learningOutcomes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (_) {
      return null;
    }
  }


  void _closeFlow() {
    if (widget.onClose != null) {
      widget.onClose!.call();
      return;
    }
    Navigator.of(context).maybePop();
  }

  Future<void> _requestBackToMaterials() async {
    final _WorkspaceExitAction? action = await showDialog<_WorkspaceExitAction>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.36),
      builder: (BuildContext dialogContext) => _WorkspaceExitDialog(
        questionCount: _draftQuestions.length,
        targetCount: _targets.length,
        aiRunning: _aiPolling,
      ),
    );

    if (action != _WorkspaceExitAction.exit || !mounted) return;

    _stopAiPolling();
    _draftQuestions.clear();
    _selectedQuestionIds.clear();
    _targets = const <add_question_sheet.QuestionAuthoringTarget>[];
    _clearDraftState();
    _closeFlow();
  }

  void _clearQuestionTable() {
    if (_draftQuestions.isEmpty) return;

    final Set<int> clearedRemoteIds = _draftQuestions
        .map((QuestionModel question) => question.remoteId ?? int.tryParse(question.id))
        .whereType<int>()
        .where((int id) => id > 0)
        .toSet();

    setState(() {
      _remoteQuestionsHiddenForSession = true;
      _knownRemoteIds.addAll(clearedRemoteIds);
      _selectedQuestionIds.clear();
      _draftQuestions.clear();
      _hydratedRemoteDetailIds.clear();
      _detailHydrationInFlightIds.clear();
    });
    _persistDraftState();

    AppToast.info(
      context,
      title: 'Table cleared',
      message: 'Existing backend questions were hidden from this workspace only. Nothing was deleted from the question bank.',
      duration: const Duration(seconds: 5),
    );
  }

  Future<void> _openAddQuestion() async {
    if (_targets.isEmpty) {
      AppToast.error(
        context,
        title: 'No topics found',
        message: 'Add topics or subtopics first.',
      );
      return;
    }

    await add_question_sheet.showAddQuestionDialog(
      context,
      moduleId: _targets.first.moduleId,
      moduleName: _targets.first.moduleName,
      materialId: _targets.first.materialId,
      materialName: _targets.first.materialName,
      topicId: _targets.first.topicId,
      topicName: _targets.first.topicName,
      topicTargets: _targets,
      onAdd: (QuestionModel question) async {
        final controller = ref.read(
          courseDetailsControllerProvider(widget.course.id).notifier,
        );
        final QuestionModel? saved = await controller.createQuestion(question);
        if (saved == null) {
          throw StateError('Could not create question');
        }
        if (!mounted) return;

        setState(() {
          _upsertDraftQuestions(<QuestionModel>[saved]);
          _selectedQuestionIds.clear();
          _mode = _WorkspaceMode.manual;
        });
        _persistDraftState();
        ref.read(questionBankRefreshSignalProvider(widget.course.id).notifier).state++;
        AppToast.success(
          context,
          title: 'Question added',
          message: 'The question was saved to the question bank.',
        );
      },
    );
  }

  Future<void> _openEditDraftQuestion(QuestionModel question) async {
    final QuestionModel? edited = await showDialog<QuestionModel>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.34),
      builder: (_) => _DraftQuestionEditDialog(
        question: question,
        targets: _targets,
      ),
    );

    if (edited == null || !mounted) return;

    final int? questionId = question.remoteId ?? int.tryParse(question.id);
    if (questionId == null || questionId <= 0) {
      setState(() {
        final int idx = _draftQuestions.indexWhere(
          (QuestionModel item) => item.id == question.id,
        );
        if (idx != -1) _draftQuestions[idx] = edited;
      });
      _persistDraftState();
      return;
    }

    try {
      final QuestionsApi api = ref.read(questionsApiProvider);
      final CreateQuestionPayload? normalizedPayload =
          api.buildCreatePayloadFromQuestion(edited);
      final QuestionModel saved = await api.updateQuestion(
        courseId: widget.course.id,
        questionId: questionId,
        payload: UpdateQuestionPayload(
          topicId: edited.topicId,
          questionText: edited.text,
          difficulty: edited.difficulty.backendValue,
          explanation: edited.explanation,
          options: normalizedPayload?.options,
          expectedAnswer: normalizedPayload?.expectedAnswer ??
              edited.expectedAnswer ??
              edited.sampleAnswer,
          gradingRubric: edited.gradingRubric,
          tags: edited.tags,
        ),
      );

      if (!mounted) return;
      setState(() {
        _upsertDraftQuestions(<QuestionModel>[
          _mergeQuestionContext(saved, edited),
        ]);
      });
      _persistDraftState();
      ref.read(questionBankRefreshSignalProvider(widget.course.id).notifier).state++;
      AppToast.success(
        context,
        title: 'Question updated',
        message: 'Changes were saved to the question bank.',
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.error(
        context,
        title: 'Could not update question',
        message: 'Please check the fields and try again.',
      );
    }
  }

  void _deleteDraftQuestion(QuestionModel question) {
    setState(() {
      _draftQuestions.removeWhere((QuestionModel item) => item.id == question.id);
      _selectedQuestionIds.remove(question.id);
    });
    _persistDraftState();
  }

  void _toggleSelection(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedQuestionIds.add(id);
      } else {
        _selectedQuestionIds.remove(id);
      }
    });
    _persistDraftState();
  }

  Future<void> _handleGeneratePressed() async {
    final List<add_question_sheet.QuestionAuthoringTarget> generationTargets =
        _targetsForCurrentTopicFilter();
    if (generationTargets.isEmpty) {
      AppToast.error(
        context,
        title: 'No generation target',
        message: 'Choose at least one topic or subtopic first.',
      );
      return;
    }

    final _AiGenerationRequest? request = await showDialog<_AiGenerationRequest>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.34),
      builder: (_) => _AiGenerationDialog(targets: generationTargets),
    );

    if (request == null || !mounted) return;

    // ── Send the real API request ──────────────────────────────────────────
    try {
      final api = ref.read(questionsApiProvider);
      final aiRequest = AiQuestionGenerationRequest(
        topics: request.topics.map((t) {
          final configs = (t['question_configs'] as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map((c) => AiQuestionGenerationConfig(
                    type: c['type'] as String,
                    difficulty: c['difficulty'] as String,
                    count: (c['count'] as num).toInt(),
                  ))
              .toList();
          return AiQuestionGenerationTopic(
            topicId: (t['topic_id'] as num).toInt(),
            questionConfigs: configs,
          );
        }).toList(),
      );

      // Mark the request locally before calling the AI endpoint.
      // We intentionally avoid an extra GET here because it was delaying the
      // actual AI request and could keep the backend DB pool busy. Old rows are
      // filtered out by local ids + created_at during polling.
      _pendingAiStartedAt = DateTime.now().subtract(const Duration(minutes: 2));
      _knownRemoteIds = <int>{
        ..._knownRemoteIds,
        ..._draftQuestions
            .map((QuestionModel q) => q.remoteId)
            .whereType<int>(),
      };
      _pendingAiRequestTopicIds = aiRequest.topics
          .map((AiQuestionGenerationTopic topic) => topic.topicId)
          .toSet();
      _receivedAiQuestionIds = <int>{};
      _pendingAiExpectedCount = request.totalQuestions;

      final resp = await api.generateQuestions(
        courseId: widget.course.id,
        payload: aiRequest,
      );

      if (!mounted) return;

      if (resp.aiProcessingStarted) {
        final String? responseRequestId = resp.requestId?.trim();
        _pendingAiRequestId = responseRequestId == null || responseRequestId.isEmpty
            ? null
            : responseRequestId;
        _remoteQuestionsHiddenForSession = false;
        AppToast.info(
          context,
          title: 'AI request sent',
          message: 'Requested ${request.totalQuestions} question(s). I will check the selected topic questions every 10 seconds until the backend callback saves them.',
          duration: const Duration(seconds: 5),
        );
        setState(() => _mode = _WorkspaceMode.ai);
        _persistDraftState();
        _startAiPolling(firstDelay: _kFirstAiPollDelay);
      } else {
        AppToast.warning(
          context,
          title: 'Request received',
          message: resp.message ??
              'Request submitted but AI processing has not started yet.',
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      AppToast.error(
        context,
        title: 'Generation failed',
        message: msg.contains('403')
            ? 'Only instructors can generate questions.'
            : msg.contains('404')
                ? 'One or more topics were not found. Please refresh and try again.'
                : msg.contains('422')
                    ? 'Invalid request. Check your configuration.'
                    : msg.contains('503')
                        ? 'AI service is temporarily unavailable. Please try again later.'
                        : 'Something went wrong. Please try again.',
        duration: const Duration(seconds: 6),
      );
    }
  }

  // ── AI Polling ────────────────────────────────────────────────────────────
  /// The AI endpoint returns as soon as the request is accepted. The actual
  /// questions arrive later through the backend callback, so the UI polls the
  /// smallest useful question list with a light backoff instead of hammering
  /// GET /courses/{id}/questions every few seconds.
  Duration _resumeAiQuietDelay() {
    if (_receivedAiQuestionIds.isNotEmpty) return _kCallbackWatchDelay;
    final DateTime? startedAt = _pendingAiStartedAt;
    if (startedAt == null) return _kResumeAiQuietDelay;
    final Duration elapsed = DateTime.now().difference(startedAt);
    final Duration remaining = _kResumeAiQuietDelay - elapsed;
    if (remaining > Duration.zero) return remaining;
    return _kCallbackWatchDelay;
  }

  void _startAiPolling({Duration firstDelay = _kFirstAiPollDelay}) {
    _aiPollTimer?.cancel();
    _aiPollAttempts = 0;
    _aiPolling = true;
    _persistDraftState();
    if (mounted) setState(() {});

    _scheduleNextAiPoll(firstDelay);
  }

  void _scheduleNextAiPoll([Duration? delay]) {
    if (!_aiPolling || !mounted) return;
    _aiPollTimer?.cancel();
    _aiPollTimer = Timer(
      delay ?? _nextAiPollDelay(),
      () => unawaited(_pollForAiQuestions()),
    );
  }

  Duration _nextAiPollDelay() {
    if (_receivedAiQuestionIds.isNotEmpty) return _kCallbackWatchDelay;
    if (_aiPollAttempts < 3) return _kNormalAiPollDelay;
    return _kLateAiPollDelay;
  }

  void _stopAiPolling() {
    _aiPollTimer?.cancel();
    _aiPollTimer = null;
    _aiPolling = false;
    _pendingAiRequestId = null;
    _persistDraftState();
    if (mounted) setState(() {});
  }

  Future<List<QuestionModel>> _fetchAiPollQuestionSummaries(QuestionsApi api) async {
    final Map<int, add_question_sheet.QuestionAuthoringTarget> targetsByTopic =
        <int, add_question_sheet.QuestionAuthoringTarget>{};
    for (final add_question_sheet.QuestionAuthoringTarget target in _targets) {
      if (_pendingAiRequestTopicIds.contains(target.topicId)) {
        targetsByTopic.putIfAbsent(target.topicId, () => target);
      }
    }

    final List<add_question_sheet.QuestionAuthoringTarget> preciseTargets =
        targetsByTopic.values
            .where((add_question_sheet.QuestionAuthoringTarget target) =>
                target.moduleId != null && target.materialId != null)
            .toList();

    // For a small topic-scoped request, this keeps polling cheap and avoids
    // repeatedly loading the whole course question bank while the AI callback
    // is still working.
    if (preciseTargets.isNotEmpty && preciseTargets.length <= 3) {
      final Map<int, QuestionModel> byRemoteId = <int, QuestionModel>{};
      try {
        for (final add_question_sheet.QuestionAuthoringTarget target in preciseTargets) {
          final CourseQuestionsResponse resp = await api.getTopicQuestions(
            courseId: widget.course.id,
            moduleId: target.moduleId!,
            materialId: target.materialId!,
            topicId: target.topicId,
          );
          for (final QuestionModel question in resp.questions) {
            final int? id = question.remoteId ?? int.tryParse(question.id);
            if (id != null) byRemoteId[id] = question;
          }
        }
        return byRemoteId.values.toList();
      } catch (_) {
        // Fallback to the course endpoint if a target snapshot is stale.
      }
    }

    final CourseQuestionsResponse resp = await api.getCourseQuestions(
      courseId: widget.course.id,
    );
    return resp.questions;
  }

  Future<void> _pollForAiQuestions() async {
    if (!mounted) {
      _stopAiPolling();
      return;
    }
    if (_aiPollInFlight) return;

    _aiPollInFlight = true;
    _aiPollAttempts++;
    if (_aiPollAttempts > _kMaxPollAttempts) {
      _aiPollInFlight = false;
      _stopAiPolling();
      if (mounted) {
        AppToast.warning(
          context,
          title: 'Generation is still running',
          message: _receivedAiQuestionIds.isEmpty
              ? 'The AI request was accepted. Keep this workspace open or reopen it later; saved questions will reload from the database.'
              : '${_receivedAiQuestionIds.length}/$_pendingAiExpectedCount question(s) arrived. Any remaining saved questions will reload from the database when you reopen this workspace.',
          duration: const Duration(seconds: 6),
        );
      }
      return;
    }

    try {
      final api = ref.read(questionsApiProvider);
      final List<QuestionModel> questionSummaries =
          await _fetchAiPollQuestionSummaries(api);

      if (!mounted) {
        _aiPollInFlight = false;
        _stopAiPolling();
        return;
      }

      final DateTime? requestStartedAt = _pendingAiStartedAt;
      final List<QuestionModel> newAiSummaries = questionSummaries
          .where((QuestionModel q) {
            final int? remoteId = q.remoteId;
            if (q.source != QuestionSource.aiGenerated || remoteId == null) {
              return false;
            }
            if (_knownRemoteIds.contains(remoteId) ||
                _receivedAiQuestionIds.contains(remoteId)) {
              return false;
            }
            if (q.topicId == null || !_pendingAiRequestTopicIds.contains(q.topicId)) {
              return false;
            }
            if (requestStartedAt != null && q.createdAt.isBefore(requestStartedAt)) {
              return false;
            }
            return true;
          })
          .toList();

      if (newAiSummaries.isNotEmpty) {
        final List<QuestionModel> hydrated = <QuestionModel>[];
        for (final QuestionModel summary in newAiSummaries) {
          final int? questionId = summary.remoteId ?? int.tryParse(summary.id);
          if (questionId == null || questionId <= 0) {
            hydrated.add(summary);
            continue;
          }
          try {
            final QuestionModel details = await api.getQuestion(
              courseId: widget.course.id,
              questionId: questionId,
            );
            _hydratedRemoteDetailIds.add(questionId);
            hydrated.add(_mergeQuestionContext(details, summary));
          } catch (_) {
            hydrated.add(summary);
          }
        }

        if (!mounted) {
          _aiPollInFlight = false;
          _stopAiPolling();
          return;
        }

        for (final QuestionModel question in newAiSummaries) {
          final int? id = question.remoteId;
          if (id != null) {
            _knownRemoteIds.add(id);
            _receivedAiQuestionIds.add(id);
          }
        }

        setState(() {
          _upsertDraftQuestions(hydrated);
          _selectedQuestionIds.clear();
          _mode = _WorkspaceMode.ai;
        });
        _persistDraftState();
        ref.read(questionBankRefreshSignalProvider(widget.course.id).notifier).state++;

        AppToast.success(
          context,
          title: '${newAiSummaries.length} AI question${newAiSummaries.length == 1 ? '' : 's'} saved',
          message: _pendingAiExpectedCount <= 0
              ? 'New generated questions are now visible.'
              : '${_receivedAiQuestionIds.length}/$_pendingAiExpectedCount question(s) received for this request.',
          duration: const Duration(seconds: 5),
        );

        if (_pendingAiExpectedCount > 0 &&
            _receivedAiQuestionIds.length >= _pendingAiExpectedCount) {
          _stopAiPolling();
        }
      }
    } catch (_) {
      // Silent — keep polling, transient errors are expected.
    } finally {
      _aiPollInFlight = false;
      if (_aiPolling && mounted) {
        _persistDraftState();
        _scheduleNextAiPoll();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final List<QuestionModel> visibleQuestions = List<QuestionModel>.unmodifiable(_draftQuestions);
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
                      _buildQuestionList(
                        title: 'Questions',
                        subtitle: 'Manual and AI questions are saved immediately. Filter, review answers, and edit anytime.',
                        emptyTitle: 'No questions yet',
                        emptyBody: 'Add a manual question or generate AI questions. New items appear here after the backend saves them.',
                        emptyActionLabel: 'Add question',
                        emptyAction: _targets.isEmpty ? null : _openAddQuestion,
                        questions: filteredQuestions,
                        totalVisible: visibleQuestions.length,
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
              color: Colors.white.withOpacity(0.82),
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
            color: AppColors.shadowBlue.withOpacity(0.22),
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
                color: Colors.white.withOpacity(0.09),
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

  Widget _buildWorkspaceActions({required bool compact}) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          if (!compact) ...<Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.tune_rounded, color: AppColors.primary, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Question actions',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textTitle,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _targets.isEmpty
                        ? 'Restoring selected topics…'
                        : '${_targets.length} target${_targets.length == 1 ? '' : 's'} ready for authoring.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            fit: compact ? FlexFit.tight : FlexFit.loose,
            child: Wrap(
              alignment: compact ? WrapAlignment.start : WrapAlignment.end,
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _workspaceActionButton(
                  icon: Icons.add_rounded,
                  label: 'Add question',
                  onPressed: _targets.isEmpty ? null : _openAddQuestion,
                  filled: true,
                ),
                _workspaceActionButton(
                  icon: Icons.auto_awesome_rounded,
                  label: _aiPolling ? 'Generating…' : 'Generate with AI',
                  onPressed: _targets.isEmpty || _aiPolling ? null : _handleGeneratePressed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _workspaceActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool filled = false,
  }) {
    final Color bg = filled ? AppColors.primary : AppColors.cardBg;
    final Color fg = filled ? Colors.white : AppColors.textTitle;
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          disabledBackgroundColor: AppColors.fieldDisabledBg,
          foregroundColor: fg,
          disabledForegroundColor: AppColors.textMuted,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
            side: BorderSide(
              color: filled ? AppColors.primary : AppColors.borderGray,
            ),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildWorkspaceSnapshot({required bool compact, required bool tight}) {
    final int selectedCount = _selectedDraftQuestions().length;
    final int manualCount = _manualDrafts().length;
    final int aiCount = _aiDrafts().length;
    final int unsavedCount = _draftQuestions.length;
    final List<_WorkspaceMetric> metrics = <_WorkspaceMetric>[
      _WorkspaceMetric(Icons.edit_note_rounded, 'Manual', '$manualCount', 'handwritten questions'),
      _WorkspaceMetric(Icons.auto_awesome_rounded, 'AI questions', '$aiCount', _aiPolling ? 'generation running' : 'ready to review'),
      _WorkspaceMetric(Icons.fact_check_outlined, 'Selected', '$selectedCount', 'selected locally'),
      _WorkspaceMetric(Icons.offline_pin_outlined, 'Backend', unsavedCount == 0 ? 'Ready' : 'Synced', 'question bank'),
    ];

    final Widget targetCard = _workspaceInfoCard(
      icon: Icons.account_tree_outlined,
      title: 'Question targets',
      subtitle: _scopeBreakdown(),
      body: _targets.isEmpty
          ? 'No valid topic targets were resolved. Go back to Materials and select topics or subtopics.'
          : _targets.take(4).map(_compactTargetLabel).join('  •  '),
    );

    final Widget safetyCard = _workspaceInfoCard(
      icon: Icons.security_rounded,
      title: 'Backend save',
      subtitle: 'Questions are saved directly to the backend.',
      body: _draftQuestions.isEmpty
          ? 'Add manual questions or generate AI questions. The question bank remains the source of truth.'
          : 'This workspace only keeps the selected target context locally.',
    );

    if (compact) {
      return Column(
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: metrics
                .map((metric) => SizedBox(width: 156, child: _workspaceMetricCard(metric)))
                .toList(),
          ),
          const SizedBox(height: 12),
          targetCard,
          const SizedBox(height: 12),
          safetyCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: tight ? 6 : 5,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: metrics
                .map((metric) => SizedBox(width: tight ? 148 : 168, child: _workspaceMetricCard(metric)))
                .toList(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(flex: 4, child: targetCard),
        const SizedBox(width: 12),
        Expanded(flex: 4, child: safetyCard),
      ],
    );
  }

  Widget _headerChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
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
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.19)),
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
              color: Colors.white.withOpacity(0.76),
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
    final Color bg = filled ? Colors.white : Colors.white.withOpacity(0.13);
    final Color fg = filled ? AppColors.primary : Colors.white;
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          disabledBackgroundColor: Colors.white.withOpacity(0.10),
          foregroundColor: fg,
          disabledForegroundColor: Colors.white.withOpacity(0.45),
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
            side: BorderSide(color: Colors.white.withOpacity(filled ? 0 : 0.18)),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _workspaceMetricCard(_WorkspaceMetric metric) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(metric.icon, color: AppColors.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textTitle,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  metric.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  metric.subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _workspaceInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String body,
  }) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
                const SizedBox(height: 3),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                const SizedBox(height: 7),
                Text(body, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textGray)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabs({required bool compact}) {
    final List<_ModeSpec> specs = <_ModeSpec>[
      _ModeSpec(
        mode: _WorkspaceMode.manual,
        title: 'Manual Questions',
        subtitle: '${_manualDrafts().length} questions',
        icon: Icons.edit_note_rounded,
      ),
      _ModeSpec(
        mode: _WorkspaceMode.ai,
        title: 'AI',
        subtitle: _aiPolling ? 'generating…' : '${_aiDrafts().length} questions',
        icon: Icons.auto_awesome_rounded,
      ),
      _ModeSpec(
        mode: _WorkspaceMode.review,
        title: 'Review',
        subtitle: '${_selectedDraftQuestions().length} ready',
        icon: Icons.fact_check_outlined,
      ),
    ];

    return Container(
      height: compact ? null : 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: compact
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: specs
                    .map(
                      (spec) => SizedBox(
                        width: 190,
                        child: _buildModeTab(spec, compact: compact),
                      ),
                    )
                    .toList(),
              ),
            )
          : Row(
              children: specs
                  .map((spec) => Expanded(child: _buildModeTab(spec, compact: compact)))
                  .toList(),
            ),
    );
  }

  Widget _buildModeTab(_ModeSpec spec, {required bool compact}) {
    final bool active = _mode == spec.mode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => _setMode(spec.mode),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.borderSoft.withOpacity(0.45),
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                spec.icon,
                size: 17,
                color: active ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      spec.title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: active ? Colors.white : AppColors.textTitle,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      spec.subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.8,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white.withOpacity(0.82) : AppColors.textMuted,
                        height: 1,
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
      'Manual',
      'AI',
    ];

    final Widget search = FigmaUmSearch40(
      controller: _searchCtrl,
      hint: 'Search by question, topic, or tag...',
      onChanged: (_) => setState(() {}),
    );

    final Widget topicFilter = _TopicTreeFilterButton(
      selectedTopicId: _selectedTopicFilterId,
      targets: _targets,
      onChanged: (int? id) {
        setState(() => _selectedTopicFilterId = id);
      },
    );

    final Widget difficultyFilter = FigmaUmDropdown40(
      width: compact ? 170 : 158,
      value: _selectedDifficultyFilter,
      items: difficultyItems,
      onChanged: (String value) => setState(() => _selectedDifficultyFilter = value),
    );

    final Widget typeFilter = FigmaUmDropdown40(
      width: compact ? 148 : 136,
      value: _selectedTypeFilter,
      items: typeItems,
      onChanged: (String value) => setState(() => _selectedTypeFilter = value),
    );

    final Widget sourceFilter = FigmaUmDropdown40(
      width: compact ? 150 : 136,
      value: _selectedSourceFilter,
      items: sourceItems,
      onChanged: (String value) => setState(() => _selectedSourceFilter = value),
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
            color: Colors.black.withOpacity(0.03),
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

  Widget _buildModeContent({
    required List<QuestionModel> filteredQuestions,
    required int totalVisible,
  }) {
    switch (_mode) {
      case _WorkspaceMode.manual:
        return _buildQuestionList(
          title: 'Manual questions',
          subtitle: 'Manual questions are saved to the question bank immediately.',
          emptyTitle: 'No manual questions yet',
          emptyBody: 'Add the first question. It will be saved to the question bank immediately.',
          emptyActionLabel: 'Add question',
          emptyAction: _openAddQuestion,
          questions: filteredQuestions,
          totalVisible: totalVisible,
        );
      case _WorkspaceMode.ai:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_aiPolling)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.badgeBlueBg,
                  borderRadius: BorderRadius.circular(13),
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
                        'AI generation is running. Questions appear here automatically after the backend saves them.',
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
            _buildQuestionList(
              title: 'AI questions',
              subtitle: 'Generate, inspect answers, and edit weak items.',
              emptyTitle: _aiPolling ? 'Waiting for AI questions' : 'No AI questions yet',
              emptyBody: _aiPolling
                  ? 'This page updates automatically when generated questions arrive.'
                  : 'Use Generate with AI from the header to configure the request for the selected targets.',
              emptyActionLabel: _aiPolling ? null : 'Generate with AI',
              emptyAction: _aiPolling ? null : _handleGeneratePressed,
              questions: filteredQuestions,
              totalVisible: totalVisible,
            ),
          ],
        );
      case _WorkspaceMode.review:
        return _buildQuestionList(
          title: 'Review questions',
          subtitle: 'Questions shown here are already saved in the question bank.',
          emptyTitle: 'No selected questions',
          emptyBody: 'Select questions to review them here.',
          emptyActionLabel: 'Go to manual questions',
          emptyAction: () => _setMode(_WorkspaceMode.manual),
          questions: filteredQuestions,
          totalVisible: totalVisible,
          reviewMode: true,
        );
    }
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
            color: Colors.black.withOpacity(0.035),
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

  Widget _buildQuestionReviewCard(
    QuestionModel question, {
    required bool selected,
    required bool reviewMode,
  }) {
    final bool isDraft = _draftQuestions.any((QuestionModel item) => item.id == question.id);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? AppColors.selectedBg.withOpacity(0.46) : AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.infoBorder : AppColors.borderGray,
          width: selected ? 1.35 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Checkbox(
                value: selected,
                onChanged: (bool? value) => _toggleSelection(question.id, value ?? false),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                side: BorderSide(color: AppColors.borderSoft),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: <Widget>[
                        _tablePill(question.typeLabel),
                        _difficultyPill(question.difficultyLabel),
                        _sourcePill(question.source),
                        if (selected) _readyPill(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      question.text,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.38,
                        color: AppColors.textTitle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: <Widget>[
                        _inlineMeta(Icons.account_tree_outlined, _questionTargetLabel(question)),
                        if (question.tags.isNotEmpty)
                          _inlineMeta(Icons.sell_outlined, question.tags.take(3).join(', ')),
                      ],
                    ),
                  ],
                ),
              ),
              if (isDraft) ...<Widget>[
                const SizedBox(width: 10),
                _iconAction(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit question',
                  onTap: () => _openEditDraftQuestion(question),
                ),
                const SizedBox(width: 6),
                _iconAction(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Remove from workspace',
                  danger: true,
                  onTap: () => _deleteDraftQuestion(question),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _answerPanel(question),
          if (question.options.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: question.options
                  .map((QuestionOption option) => _optionChip(question, option))
                  .toList(),
            ),
          ],
          if ((question.explanation ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.borderGray),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.lightbulb_outline_rounded, size: 17, color: AppColors.warningText),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      question.explanation!.trim(),
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textGray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _answerPanel(QuestionModel question) {
    final String answer = _answerSummary(question);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.greenBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.check_rounded, size: 17, color: AppColors.greenText),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Answer',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.25,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  answer,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textTitle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionChip(QuestionModel question, QuestionOption option) {
    final bool correct = _isCorrectOption(question, option);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: correct ? AppColors.greenBg : AppColors.cardBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: correct ? AppColors.successText.withOpacity(0.32) : AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (correct) ...<Widget>[
            Icon(Icons.check_circle_rounded, size: 14, color: AppColors.greenText),
            const SizedBox(width: 6),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              option.text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.3,
                fontWeight: FontWeight.w800,
                color: correct ? AppColors.greenText : AppColors.textGray,
              ),
            ),
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
                    Divider(height: 1, color: AppColors.borderGray.withOpacity(0.75)),
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
        color: selected ? AppColors.primary.withOpacity(0.12) : AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: selected ? AppColors.primary.withOpacity(0.35) : AppColors.borderGray,
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
      color: selected ? AppColors.selectedBg.withOpacity(0.55) : AppColors.cardBg,
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

  List<QuestionModel> _visibleQuestionsForMode() {
    switch (_mode) {
      case _WorkspaceMode.manual:
        return _manualDrafts();
      case _WorkspaceMode.ai:
        return _aiDrafts();
      case _WorkspaceMode.review:
        return _selectedDraftQuestions();
    }
  }

  List<QuestionModel> _manualDrafts() {
    return _draftQuestions
        .where((QuestionModel q) => q.source == QuestionSource.manual)
        .toList();
  }

  List<QuestionModel> _aiDrafts() {
    return _draftQuestions
        .where((QuestionModel q) => q.source == QuestionSource.aiGenerated)
        .toList();
  }

  List<QuestionModel> _selectedDraftQuestions() {
    return _draftQuestions
        .where((QuestionModel q) => _selectedQuestionIds.contains(q.id))
        .toList();
  }

  List<add_question_sheet.QuestionAuthoringTarget> _targetsForCurrentTopicFilter() {
    if (_selectedTopicFilterId == null) return _targets;
    return _targets
        .where((add_question_sheet.QuestionAuthoringTarget target) =>
            target.topicId == _selectedTopicFilterId,)
        .toList();
  }

  List<QuestionModel> _filteredQuestions(List<QuestionModel> questions) {
    final Set<int> targetTopicIds = _targets
        .map((add_question_sheet.QuestionAuthoringTarget target) => target.topicId)
        .toSet();
    final String rawSearch = _searchCtrl.text.trim().toLowerCase();

    final List<QuestionModel> filtered = questions.where((QuestionModel question) {
      final bool topicAllowed = targetTopicIds.isEmpty ||
          (question.topicId != null && targetTopicIds.contains(question.topicId));
      if (!topicAllowed) return false;

      if (_selectedTopicFilterId != null && question.topicId != _selectedTopicFilterId) {
        return false;
      }

      if (_selectedDifficultyFilter != 'Any Difficulty' &&
          question.difficultyLabel.toLowerCase() != _selectedDifficultyFilter.toLowerCase()) {
        return false;
      }

      if (_selectedTypeFilter != 'All Types' &&
          question.typeLabel.toLowerCase() != _selectedTypeFilter.toLowerCase()) {
        return false;
      }

      if (_selectedSourceFilter != 'All Sources') {
        final String sourceLabel = question.source == QuestionSource.aiGenerated ? 'AI' : 'Manual';
        if (sourceLabel != _selectedSourceFilter) return false;
      }

      if (rawSearch.isNotEmpty) {
        final String haystack = <String>[
          question.text,
          question.contextLabel,
          question.typeLabel,
          _questionTargetLabel(question),
          ...question.tags,
        ].join(' ').toLowerCase();
        if (!haystack.contains(rawSearch)) return false;
      }

      return true;
    }).toList();

    filtered.sort((QuestionModel a, QuestionModel b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  String _headerSubtitle() {
    final QuestionAuthoringLaunchContext? launch = widget.launchContext;
    if (launch != null && launch.subtitle.trim().isNotEmpty) {
      return launch.subtitle;
    }
    if (widget.initialTopicIds.isNotEmpty) {
      return '${_primaryScopeTitle()} • questions will use this topic and its subtopics if they exist.';
    }
    if (widget.initialMaterialIds.isNotEmpty) {
      return '${_primaryScopeTitle()} • questions will use this file topics and subtopics.';
    }
    if (widget.initialModuleIds.isNotEmpty) {
      return '${_primaryScopeTitle()} • questions will use this module content tree.';
    }
    return '${_primaryScopeTitle()} • questions will use the selected content tree.';
  }

  String _primaryScopeTitle() {
    final QuestionAuthoringLaunchContext? launch = widget.launchContext;
    if (launch != null && launch.title.trim().isNotEmpty) {
      return launch.title;
    }
    if (_targets.isEmpty) return widget.course.title;
    final Set<String> materialNames = _targets
        .map((add_question_sheet.QuestionAuthoringTarget target) => target.materialName ?? '')
        .where((String name) => name.trim().isNotEmpty)
        .toSet();
    if (widget.initialMaterialIds.length == 1 && materialNames.length == 1) {
      return materialNames.first;
    }
    if (widget.initialTopicIds.length == 1) {
      return _compactTargetLabel(_targets.first);
    }
    final Set<String> moduleNames = _targets
        .map((add_question_sheet.QuestionAuthoringTarget target) => target.moduleName ?? '')
        .where((String name) => name.trim().isNotEmpty)
        .toSet();
    if (widget.initialModuleIds.length == 1 && moduleNames.length == 1) {
      return moduleNames.first;
    }
    return widget.course.title;
  }

  String _scopeLabel() {
    final QuestionAuthoringLaunchContext? launch = widget.launchContext;
    if (launch != null) return launch.label;
    if (widget.initialTopicIds.isNotEmpty) return 'Topic scope';
    if (widget.initialMaterialIds.isNotEmpty) return 'Material scope';
    if (widget.initialModuleIds.isNotEmpty) return 'Module scope';
    return 'Selected scope';
  }

  String _scopeBreakdown() {
    final int moduleCount = _targets.map((t) => t.moduleId).whereType<int>().toSet().length;
    final int materialCount = _targets.map((t) => t.materialId).whereType<int>().toSet().length;
    return '$moduleCount module • $materialCount file • ${_targets.length} topics';
  }

  void _upsertDraftQuestions(List<QuestionModel> questions) {
    for (final QuestionModel incoming in questions.map(_decorateQuestionWithTargetContext)) {
      final int index = _draftQuestions.indexWhere(
        (QuestionModel existing) => _sameQuestionIdentity(existing, incoming),
      );
      if (index == -1) {
        _draftQuestions.insert(0, incoming);
      } else {
        _draftQuestions[index] = incoming;
      }
    }
    _draftQuestions.sort(
      (QuestionModel a, QuestionModel b) => b.createdAt.compareTo(a.createdAt),
    );
  }

  bool _sameQuestionIdentity(QuestionModel a, QuestionModel b) {
    if (a.remoteId != null && b.remoteId != null) return a.remoteId == b.remoteId;
    return a.id == b.id;
  }

  QuestionModel _mergeQuestionContext(QuestionModel saved, QuestionModel fallback) {
    return QuestionModel(
      id: saved.id,
      remoteId: saved.remoteId,
      text: saved.text,
      type: saved.type,
      difficulty: saved.difficulty,
      source: saved.source,
      approvalStatus: saved.approvalStatus,
      options: saved.options.isEmpty ? fallback.options : saved.options,
      correctOptionId: saved.correctOptionId ?? fallback.correctOptionId,
      correctBool: saved.correctBool ?? fallback.correctBool,
      sampleAnswer: saved.sampleAnswer ?? fallback.sampleAnswer,
      explanation: saved.explanation ?? fallback.explanation,
      expectedAnswer: saved.expectedAnswer ?? fallback.expectedAnswer,
      gradingRubric: saved.gradingRubric ?? fallback.gradingRubric,
      tags: saved.tags.isEmpty ? fallback.tags : saved.tags,
      usageCount: saved.usageCount,
      successRate: saved.successRate,
      averageTimeSeconds: saved.averageTimeSeconds,
      maxScore: saved.maxScore,
      autoGradable: saved.autoGradable,
      courseId: saved.courseId ?? widget.course.id,
      moduleId: fallback.moduleId,
      moduleName: fallback.moduleName,
      materialId: fallback.materialId,
      materialName: fallback.materialName,
      topicId: saved.topicId ?? fallback.topicId,
      topicName: fallback.topicName,
      learningOutcomes: saved.learningOutcomes.isEmpty
          ? fallback.learningOutcomes
          : saved.learningOutcomes,
      createdBy: saved.createdBy ?? fallback.createdBy,
      createdAt: saved.createdAt,
      updatedAt: saved.updatedAt,
    );
  }

  QuestionModel _decorateQuestionWithTargetContext(QuestionModel question) {
    final add_question_sheet.QuestionAuthoringTarget? target = question.topicId == null
        ? null
        : _findTarget(_targets, question.topicId!);
    if (target == null) return question;
    return QuestionModel(
      id: question.id,
      remoteId: question.remoteId,
      text: question.text,
      type: question.type,
      difficulty: question.difficulty,
      source: question.source,
      approvalStatus: question.approvalStatus,
      options: question.options,
      correctOptionId: question.correctOptionId,
      correctBool: question.correctBool,
      sampleAnswer: question.sampleAnswer,
      explanation: question.explanation,
      expectedAnswer: question.expectedAnswer,
      gradingRubric: question.gradingRubric,
      tags: question.tags,
      usageCount: question.usageCount,
      successRate: question.successRate,
      averageTimeSeconds: question.averageTimeSeconds,
      maxScore: question.maxScore,
      autoGradable: question.autoGradable,
      courseId: question.courseId ?? widget.course.id,
      moduleId: target.moduleId ?? question.moduleId,
      moduleName: target.moduleName ?? question.moduleName,
      materialId: target.materialId ?? question.materialId,
      materialName: target.materialName ?? question.materialName,
      topicId: target.topicId,
      topicName: target.topicName,
      learningOutcomes: question.learningOutcomes,
      createdBy: question.createdBy,
      createdAt: question.createdAt,
      updatedAt: question.updatedAt,
    );
  }

  String _questionTargetLabel(QuestionModel question) {
    for (final add_question_sheet.QuestionAuthoringTarget target in _targets) {
      if (target.topicId == question.topicId) return _compactTargetLabel(target);
    }
    return question.topicName ?? 'Unassigned topic';
  }

  Widget _scopeChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _countPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textGray,
        ),
      ),
    );
  }

  Widget _inlineMeta(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _difficultyPill(String label) {
    final String normalized = label.toLowerCase();
    late Color textColor;
    late Color backgroundColor;

    switch (normalized) {
      case 'easy':
        textColor = AppColors.successText;
        backgroundColor = AppColors.successBg;
        break;
      case 'hard':
        textColor = AppColors.dangerTitle;
        backgroundColor = AppColors.dangerBg;
        break;
      default:
        textColor = AppColors.warningText;
        backgroundColor = AppColors.warningBg;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
      ),
    );
  }

  Widget _sourcePill(QuestionSource source) {
    final bool ai = source == QuestionSource.aiGenerated;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ai ? AppColors.purpleBg : AppColors.infoBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            ai ? Icons.auto_awesome_rounded : Icons.edit_note_rounded,
            size: 13,
            color: ai ? AppColors.purpleText : AppColors.primary,
          ),
          const SizedBox(width: 5),
          Text(
            ai ? 'AI' : 'Manual',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: ai ? AppColors.purpleText : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tablePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textGray,
        ),
      ),
    );
  }

  Widget _softPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: AppColors.textGray,
        ),
      ),
    );
  }

  Widget _readyPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.greenBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Selected for review',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: AppColors.greenText,
        ),
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool danger = false,
    bool compact = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: compact ? 30 : 36,
          height: compact ? 30 : 36,
          decoration: BoxDecoration(
            color: danger ? AppColors.dangerBg : AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: danger ? AppColors.dangerBorder : AppColors.borderSoft),
          ),
          child: Icon(
            icon,
            size: compact ? 16 : 18,
            color: danger ? AppColors.dangerText : AppColors.textGray,
          ),
        ),
      ),
    );
  }
}



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

class _DraftQuestionEditDialog extends StatefulWidget {
  final QuestionModel question;
  final List<add_question_sheet.QuestionAuthoringTarget> targets;

  const _DraftQuestionEditDialog({
    required this.question,
    required this.targets,
  });

  @override
  State<_DraftQuestionEditDialog> createState() => _DraftQuestionEditDialogState();
}

class _DraftQuestionEditDialogState extends State<_DraftQuestionEditDialog> {
  late final TextEditingController _questionCtrl;
  late final TextEditingController _explanationCtrl;
  late QuestionDifficulty _difficulty;
  late int? _topicId;

  @override
  void initState() {
    super.initState();
    _questionCtrl = TextEditingController(text: widget.question.text);
    _explanationCtrl = TextEditingController(text: widget.question.explanation ?? '');
    _difficulty = widget.question.difficulty;
    _topicId = widget.question.topicId;
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _explanationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                      child: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Edit question',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textTitle,
                        ),
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
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                child: Column(
                  children: <Widget>[
                    _dialogField(
                      controller: _questionCtrl,
                      label: 'Question text',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _dialogField(
                      controller: _explanationCtrl,
                      label: 'Explanation / note',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    _answerPreview(),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _simpleDropdown<QuestionDifficulty>(
                            label: 'Difficulty',
                            value: _difficulty,
                            items: QuestionDifficulty.values,
                            itemLabel: (QuestionDifficulty value) => value.label,
                            onChanged: (QuestionDifficulty? value) {
                              if (value != null) setState(() => _difficulty = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _simpleDropdown<int>(
                            label: 'Topic / Subtopic',
                            value: _topicId,
                            items: widget.targets.map((t) => t.topicId).toList(),
                            itemLabel: (int value) => _compactTargetLabel(_findTarget(widget.targets, value)!),
                            onChanged: (int? value) => setState(() => _topicId = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Apply changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
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

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: AppColors.textGray, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
        filled: true,
        fillColor: AppColors.surfaceBg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _answerPreview() {
    final QuestionModel question = widget.question;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.check_circle_outline_rounded, size: 17, color: AppColors.successText),
              const SizedBox(width: 8),
              Text(
                'Answer',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _dialogAnswerSummary(question),
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w800,
              color: AppColors.textTitle,
            ),
          ),
          if (question.options.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: question.options.map((QuestionOption option) {
                final bool correct = _dialogIsCorrectOption(question, option);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: correct ? AppColors.greenBg : AppColors.cardBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: correct
                          ? AppColors.successText.withOpacity(0.32)
                          : AppColors.borderSoft,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (correct) ...<Widget>[
                        Icon(Icons.check_rounded, size: 14, color: AppColors.successText),
                        const SizedBox(width: 5),
                      ],
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: Text(
                          option.text,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: correct ? AppColors.successText : AppColors.textGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  bool _dialogIsCorrectOption(QuestionModel question, QuestionOption option) {
    if (option.isCorrect) return true;
    if (question.correctOptionId != null && option.id == question.correctOptionId) return true;
    final String expected = (question.expectedAnswer ?? '').trim();
    if (expected.isEmpty) return false;
    final List<String> parts = expected.split(',').map((String value) => value.trim()).toList();
    return parts.contains(option.id) || parts.contains(option.text);
  }

  String _dialogAnswerSummary(QuestionModel question) {
    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.multiSelect:
        final List<QuestionOption> correctOptions = question.options
            .where((QuestionOption option) => _dialogIsCorrectOption(question, option))
            .toList();
        if (correctOptions.isNotEmpty) {
          return correctOptions.map((QuestionOption option) => option.text).join(', ');
        }
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

  Widget _simpleDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T value) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
        filled: true,
        fillColor: AppColors.surfaceBg,
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
      items: items
          .map((T value) => DropdownMenuItem<T>(
                value: value,
                child: Text(
                  itemLabel(value),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textGray, fontWeight: FontWeight.w700),
                ),
              ),)
          .toList(),
      onChanged: onChanged,
    );
  }

  void _submit() {
    final String text = _questionCtrl.text.trim();
    if (text.isEmpty || _topicId == null) return;
    final add_question_sheet.QuestionAuthoringTarget? target = _findTarget(widget.targets, _topicId!);

    Navigator.of(context).pop(
      QuestionModel(
        id: widget.question.id,
        remoteId: widget.question.remoteId,
        text: text,
        type: widget.question.type,
        difficulty: _difficulty,
        source: widget.question.source,
        approvalStatus: widget.question.approvalStatus,
        options: widget.question.options,
        correctOptionId: widget.question.correctOptionId,
        correctBool: widget.question.correctBool,
        sampleAnswer: widget.question.sampleAnswer,
        explanation: _explanationCtrl.text.trim().isEmpty ? null : _explanationCtrl.text.trim(),
        expectedAnswer: widget.question.expectedAnswer,
        tags: widget.question.tags,
        usageCount: widget.question.usageCount,
        successRate: widget.question.successRate,
        maxScore: widget.question.maxScore,
        autoGradable: widget.question.autoGradable,
        courseId: widget.question.courseId,
        moduleId: target?.moduleId ?? widget.question.moduleId,
        moduleName: target?.moduleName ?? widget.question.moduleName,
        materialId: target?.materialId ?? widget.question.materialId,
        materialName: target?.materialName ?? widget.question.materialName,
        topicId: target?.topicId ?? widget.question.topicId,
        topicName: target?.topicName ?? widget.question.topicName,
        learningOutcomes: widget.question.learningOutcomes,
        createdAt: widget.question.createdAt,
      ),
    );
  }
}

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

  late int _selectedTargetTopicId;

  add_question_sheet.QuestionAuthoringTarget? get _selectedTarget {
    if (widget.targets.isEmpty) return null;
    return widget.targets.firstWhere(
      (add_question_sheet.QuestionAuthoringTarget target) =>
          target.topicId == _selectedTargetTopicId,
      orElse: () => widget.targets.first,
    );
  }

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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderGray),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 16, 18),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: <Color>[Color(0xFF137FEC), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Generate AI questions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textTitle,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose one topic, then set the question type, difficulty, and count.',
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
              Divider(height: 1, color: AppColors.borderGray),
              Expanded(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 5,
                      child: ListView(
                        padding: const EdgeInsets.all(22),
                        children: <Widget>[
                          _sectionTitle(
                            'Generation topic',
                            widget.targets.length > 1
                                ? '${widget.targets.length} available'
                                : '1 selected',
                          ),
                          const SizedBox(height: 10),
                          _targetSelector(),
                          if (widget.targets.length > 1) ...<Widget>[
                            const SizedBox(height: 8),
                            Text(
                              'AI will generate questions for the selected topic only.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          _sectionTitle(
                            'Question rules',
                            '${_configs.length} rule${_configs.length == 1 ? '' : 's'}',
                          ),
                          const SizedBox(height: 10),
                          ...List<Widget>.generate(_configs.length, (int index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _configRow(index),
                            );
                          }),
                          OutlinedButton.icon(
                            onPressed: () {
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
                            label: const Text('Add another rule'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.borderSoft),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    VerticalDivider(width: 1, color: AppColors.borderGray),
                    Expanded(
                      flex: 4,
                      child: Container(
                        color: AppColors.surfaceBg,
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _sectionTitle('Summary', '$totalQuestions requested'),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.borderGray),
                                ),
                                child: SingleChildScrollView(
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
                                        title: 'Questions',
                                        value: '$totalQuestions total',
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        'Rules',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.textTitle,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      ..._configs.map(((_AiQuestionConfig config) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: _ruleChip(config),
                                        );
                                      })),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: selectedTarget == null
                                    ? null
                                    : () => Navigator.of(context).pop(request),
                                icon: const Icon(Icons.auto_awesome_rounded),
                                label: const Text('Generate questions'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppColors.borderGray,
                                  disabledForegroundColor: AppColors.textMuted,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
        Text(
          meta,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
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
      value: _selectedTargetTopicId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Select one topic',
        labelStyle: TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: AppColors.surfaceBg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      dropdownColor: AppColors.cardBg,
      items: widget.targets
          .map(
            (add_question_sheet.QuestionAuthoringTarget target) =>
                DropdownMenuItem<int>(
              value: target.topicId,
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 2),
                  Text(
                    target.subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
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

  Widget _emptyTargetCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No topic was selected. Close this dialog and choose a topic first.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _targetCard(
    add_question_sheet.QuestionAuthoringTarget target, {
    required bool selected,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withOpacity(0.06) : AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.primary.withOpacity(0.35) : AppColors.borderGray,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
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
                    fontWeight: FontWeight.w600,
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
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
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
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Text(
        '${config.count} × ${config.type.label} • ${config.difficulty.label}',
        style: TextStyle(
          color: AppColors.textGray,
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    );
  }

  Widget _configRow(int index) {
    final _AiQuestionConfig config = _configs[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: _smallDropdown<QuestionType>(
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
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _smallDropdown<QuestionDifficulty>(
              value: config.difficulty,
              items: QuestionDifficulty.values,
              label: (QuestionDifficulty value) => value.label,
              onChanged: (QuestionDifficulty? value) {
                if (value != null) setState(() => config.difficulty = value);
              },
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 86,
            child: Row(
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
                    ),
                  ),
                ),
                _miniCountButton(Icons.add_rounded, () {
                  setState(() => config.count = (config.count + 1).clamp(1, 50).toInt());
                }),
              ],
            ),
          ),
          if (_configs.length > 1) ...<Widget>[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => setState(() => _configs.removeAt(index)),
              icon: Icon(Icons.close_rounded, size: 18, color: AppColors.dangerText),
            ),
          ],
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
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        dropdownColor: AppColors.cardBg,
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
    );
  }

  Widget _miniCountButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Icon(icon, size: 16, color: AppColors.textGray),
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