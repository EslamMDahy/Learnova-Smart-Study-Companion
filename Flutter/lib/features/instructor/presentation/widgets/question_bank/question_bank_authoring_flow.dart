import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/ui/toast.dart';
import '../../../../../core/storage/key_value_store_factory.dart';
import '../../../../../core/utils/debounced_action.dart';
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

part 'question_bank_authoring_workspace_widgets.dart';
part 'question_bank_authoring_draft_edit_dialog.dart';
part 'question_bank_authoring_ai_generation_dialog.dart';
part 'question_bank_authoring_types.dart';
part 'question_bank_authoring_view.dart';


// Authoring types live in question_bank_authoring_types.dart.

class QuestionBankAuthoringFlow extends ConsumerStatefulWidget {
  final MyCourseItem course;
  final Set<int> initialModuleIds;
  final Set<int> initialMaterialIds;
  final Set<int> initialTopicIds;
  final bool embedded;
  final bool startInAiMode;
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
    this.startInAiMode = false,
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
  late _WorkspaceMode _mode;

  List<add_question_sheet.QuestionAuthoringTarget> _targets =
      const <add_question_sheet.QuestionAuthoringTarget>[];
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _selectedQuestionIds = <String>{};
  final List<QuestionModel> _draftQuestions = <QuestionModel>[];
  final DebouncedAction _draftPersistDebouncer =
      DebouncedAction(const Duration(milliseconds: 400));
  late final _draftStore = createLocalStore();

  void _runStateUpdate(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

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
  bool _aiStreamInFlight = false;
  bool _reviewingQuestions = false;
  final Set<int> _detailHydrationInFlightIds = <int>{};
  final Set<int> _hydratedRemoteDetailIds = <int>{};

  int? _selectedTopicFilterId;
  String _selectedDifficultyFilter = 'Any Difficulty';
  String _selectedTypeFilter = 'All Types';
  String _selectedSourceFilter = 'All Sources';

  @override
  void initState() {
    super.initState();
    _mode = widget.startInAiMode ? _WorkspaceMode.ai : _WorkspaceMode.manual;
    _bootstrapLocalState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_hydrateInitialBackendState());
      if (_aiPolling) {
        _scheduleNextAiPoll(_resumeAiQuietDelay());
        unawaited(_watchAiGenerationStream());
      }
    });
  }

  @override
  void dispose() {
    _draftPersistDebouncer.cancel();
    _persistDraftStateNow();
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

    if (widget.startInAiMode &&
        (stored == null || stored.questions.isEmpty) &&
        !_aiPolling) {
      _mode = _WorkspaceMode.ai;
    }

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

    // Do not auto-hydrate saved questions into the authoring workspace.
    // The backend question bank is still the source of truth, but this screen is
    // a fresh creation workspace for the selected topic/material/module.
    // Loading old rows here made instructors think previous generated/manual
    // questions were being regenerated again.
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

        final bool activeAiRequest = parsed.aiPolling &&
            (parsed.pendingAiRequestTopicIds.isNotEmpty ||
                (parsed.pendingAiRequestId?.trim().isNotEmpty ?? false)) &&
            (parsed.pendingAiExpectedCount <= 0 ||
                parsed.receivedAiQuestionIds.length < parsed.pendingAiExpectedCount);

        if (activeAiRequest) return parsed;

        if (parsed.questions.isNotEmpty) {
          // Old saved question rows are not a draft anymore; they already live
          // in the database. Remove the stale local snapshot so reopening the
          // same topic starts from an empty authoring table.
          _draftStore.remove(key);
        }

        targetOnlyFallback ??= _StoredQuestionWorkspace(
          targets: parsed.targets.isNotEmpty ? parsed.targets : fallbackTargets,
          questions: const <QuestionModel>[],
          selectedIds: const <String>{},
          mode: _WorkspaceMode.manual,
          aiPolling: false,
          aiPollAttempts: 0,
          pendingAiExpectedCount: 0,
          pendingAiRequestId: null,
          pendingAiStartedAt: null,
          pendingAiRequestTopicIds: const <int>{},
          receivedAiQuestionIds: const <int>{},
          knownRemoteIds: parsed.knownRemoteIds,
        );
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
    final String? pendingAiRequestId = data['pendingAiRequestId']?.toString();
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

  void _persistDraftState() {
    _draftPersistDebouncer.run(_persistDraftStateNow);
  }

  void _persistDraftStateNow() {
    final bool hasPendingAiWork = _aiPolling ||
        (_pendingAiRequestId?.isNotEmpty ?? false) ||
        _pendingAiRequestTopicIds.isNotEmpty ||
        _receivedAiQuestionIds.isNotEmpty;
    final bool hasPendingAiReview =
        _draftQuestions.any(_isPendingAiReview);
    final bool shouldPersistQuestionRows = _aiPolling || hasPendingAiReview;
    final bool hasQuestionWork =
        shouldPersistQuestionRows && _draftQuestions.isNotEmpty;
    final List<String> selectedIdsForPersist = shouldPersistQuestionRows
        ? _selectedQuestionIds.toList()
        : const <String>[];

    if (!hasQuestionWork &&
        !hasPendingAiWork &&
        selectedIdsForPersist.isEmpty &&
        _targets.isEmpty) {
      _draftStore.remove(_draftStateKey);
      _draftStore.remove(_draftCourseKey);
      return;
    }

    final List<add_question_sheet.QuestionAuthoringTarget> targetsForPersist =
        _targets.isNotEmpty ? _targets : _targetsFromQuestions(_draftQuestions);
    final Map<String, dynamic> payload = <String, dynamic>{
      'courseId': widget.course.id,
      'mode': _mode.name,
      'savedAt': DateTime.now().toIso8601String(),
      'selectedIds': selectedIdsForPersist,
      'targets': targetsForPersist.map(_targetToDraftJson).toList(),
      'questions': shouldPersistQuestionRows
          ? _draftQuestions.map(_questionToDraftJson).toList()
          : const <Map<String, dynamic>>[],
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
    _draftStore.setString(_draftCourseKey, encoded);
  }


  void _clearDraftState() {
    _draftPersistDebouncer.cancel();
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
      barrierColor: Colors.black.withValues(alpha: 0.36),
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
      barrierColor: Colors.black.withValues(alpha: 0.34),
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

  bool _isPendingAiReview(QuestionModel question) {
    return question.source == QuestionSource.aiGenerated &&
        question.approvalStatus == QuestionApprovalStatus.pending &&
        (question.remoteId ?? int.tryParse(question.id)) != null;
  }

  List<QuestionModel> _pendingReviewQuestions([
    Iterable<QuestionModel>? questions,
  ]) {
    return (questions ?? _draftQuestions)
        .where(_isPendingAiReview)
        .toList();
  }

  void _toggleReviewSelection(QuestionModel question) {
    if (!_isPendingAiReview(question) || _reviewingQuestions) return;
    setState(() {
      if (!_selectedQuestionIds.add(question.id)) {
        _selectedQuestionIds.remove(question.id);
      }
    });
    _persistDraftState();
  }

  void _selectPendingForReview(Iterable<QuestionModel> questions) {
    if (_reviewingQuestions) return;
    final List<QuestionModel> pending = _pendingReviewQuestions(questions);
    setState(() {
      final bool allSelected = pending.isNotEmpty && pending.every(
        (QuestionModel question) => _selectedQuestionIds.contains(question.id),
      );
      if (allSelected) {
        _selectedQuestionIds.removeAll(
          pending.map((QuestionModel question) => question.id),
        );
      } else {
        _selectedQuestionIds.addAll(
          pending.map((QuestionModel question) => question.id),
        );
      }
    });
    _persistDraftState();
  }

  Future<void> _markSelectedQuestionsReviewed() async {
    final List<QuestionModel> selected = _pendingReviewQuestions().where(
      (QuestionModel question) => _selectedQuestionIds.contains(question.id),
    ).toList();
    await _approveQuestionsAsReviewed(selected);
  }

  Future<void> _markQuestionReviewed(QuestionModel question) async {
    await _approveQuestionsAsReviewed(<QuestionModel>[question]);
  }

  Future<void> _approveQuestionsAsReviewed(
    List<QuestionModel> questions,
  ) async {
    if (_reviewingQuestions) return;
    final List<QuestionModel> pending = questions.where(_isPendingAiReview).toList();
    if (pending.isEmpty) {
      AppToast.info(
        context,
        title: 'Nothing to review',
        message: 'Select one or more pending AI questions first.',
      );
      return;
    }

    final Map<int, List<QuestionModel>> questionsByTopic =
        <int, List<QuestionModel>>{};
    for (final QuestionModel question in pending) {
      final int? topicId = question.topicId;
      if (topicId == null) continue;
      questionsByTopic.putIfAbsent(topicId, () => <QuestionModel>[]).add(question);
    }

    if (questionsByTopic.isEmpty) {
      AppToast.error(
        context,
        title: 'Could not mark reviewed',
        message: 'The selected questions do not have a valid topic.',
      );
      return;
    }

    setState(() => _reviewingQuestions = true);

    final Set<int> approvedRemoteIds = <int>{};
    var failedTopics = 0;
    Object? lastError;

    for (final MapEntry<int, List<QuestionModel>> entry
        in questionsByTopic.entries) {
      final int topicId = entry.key;
      final add_question_sheet.QuestionAuthoringTarget? target =
          _findTarget(_targets, topicId);
      final QuestionModel first = entry.value.first;
      final int? moduleId = target?.moduleId ?? first.moduleId;
      final int? materialId = target?.materialId ?? first.materialId;
      final List<int> questionIds = entry.value
          .map((QuestionModel question) =>
              question.remoteId ?? int.tryParse(question.id))
          .whereType<int>()
          .toSet()
          .toList();

      if (moduleId == null || materialId == null || questionIds.isEmpty) {
        failedTopics++;
        continue;
      }

      try {
        final ApproveQuestionsResponse response =
            await ref.read(questionsApiProvider).approveTopicQuestions(
                  courseId: widget.course.id,
                  moduleId: moduleId,
                  materialId: materialId,
                  topicId: topicId,
                  questionIds: questionIds,
                );
        if (response.approvedCount > 0) {
          approvedRemoteIds.addAll(questionIds);
        } else {
          failedTopics++;
        }
      } catch (error) {
        failedTopics++;
        lastError = error;
      }
    }

    if (!mounted) return;

    if (approvedRemoteIds.isNotEmpty) {
      setState(() {
        for (var index = 0; index < _draftQuestions.length; index++) {
          final QuestionModel question = _draftQuestions[index];
          final int? remoteId =
              question.remoteId ?? int.tryParse(question.id);
          if (remoteId != null && approvedRemoteIds.contains(remoteId)) {
            _draftQuestions[index] = _copyQuestionWithApprovalStatus(
              question,
              QuestionApprovalStatus.approved,
            );
            _selectedQuestionIds.remove(question.id);
          }
        }
      });
      _persistDraftState();
      ref
          .read(questionBankRefreshSignalProvider(widget.course.id).notifier)
          .state++;
    }

    if (mounted) {
      setState(() => _reviewingQuestions = false);
    }

    if (approvedRemoteIds.isNotEmpty && failedTopics == 0) {
      AppToast.success(
        context,
        title: 'Marked as reviewed',
        message:
            '${approvedRemoteIds.length} question${approvedRemoteIds.length == 1 ? '' : 's'} will now be included in the question bank export.',
      );
      return;
    }

    if (approvedRemoteIds.isNotEmpty) {
      AppToast.warning(
        context,
        title: 'Partially reviewed',
        message:
            '${approvedRemoteIds.length} question(s) were marked reviewed. Some topic groups could not be updated.',
        duration: const Duration(seconds: 6),
      );
      return;
    }

    AppToast.error(
      context,
      title: 'Could not mark reviewed',
      message: lastError == null
          ? 'The selected questions are missing their material or module context.'
          : 'The backend did not approve the selected pending questions. Refresh the workspace and try again.',
      duration: const Duration(seconds: 6),
    );
  }

  QuestionModel _copyQuestionWithApprovalStatus(
    QuestionModel question,
    QuestionApprovalStatus approvalStatus,
  ) {
    return QuestionModel(
      id: question.id,
      remoteId: question.remoteId,
      text: question.text,
      type: question.type,
      difficulty: question.difficulty,
      source: question.source,
      approvalStatus: approvalStatus,
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
      courseId: question.courseId,
      moduleId: question.moduleId,
      moduleName: question.moduleName,
      materialId: question.materialId,
      materialName: question.materialName,
      topicId: question.topicId,
      topicName: question.topicName,
      learningOutcomes: question.learningOutcomes,
      createdBy: question.createdBy,
      createdAt: question.createdAt,
      updatedAt: DateTime.now(),
    );
  }


  Future<void> _handleGeneratePressed() async {
    final List<add_question_sheet.QuestionAuthoringTarget> generationTargets =
        _targets;
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
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder: (_) => _AiGenerationDialog(
        targets: generationTargets,
        initialTopicId: _selectedTopicFilterId,
      ),
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
      _pendingAiStartedAt = DateTime.now().subtract(const Duration(seconds: 3));
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

      final List<QuestionModel> immediateQuestions =
          await _hydrateImmediateGeneratedQuestions(api, resp.questions);
      if (!mounted) return;

      if (immediateQuestions.isNotEmpty) {
        for (final QuestionModel question in immediateQuestions) {
          final int? remoteId = question.remoteId ?? int.tryParse(question.id);
          if (remoteId != null) {
            _knownRemoteIds.add(remoteId);
            _receivedAiQuestionIds.add(remoteId);
          }
        }
        setState(() {
          _upsertDraftQuestions(immediateQuestions);
          _selectedQuestionIds
            ..clear()
            ..addAll(
              immediateQuestions
                  .where(_isPendingAiReview)
                  .map((QuestionModel question) => question.id),
            );
          _mode = _WorkspaceMode.ai;
        });
        _persistDraftState();
        ref
            .read(questionBankRefreshSignalProvider(widget.course.id).notifier)
            .state++;
      }

      if (resp.aiProcessingStarted) {
        final String? responseRequestId = resp.requestId?.trim();
        _pendingAiRequestId = responseRequestId == null || responseRequestId.isEmpty
            ? null
            : responseRequestId;
        AppToast.info(
          context,
          title: 'AI request sent',
          message:
              'Requested ${request.totalQuestions} question(s) across ${request.topicCount} topic${request.topicCount == 1 ? '' : 's'}. The workspace will keep watching for the generated questions.',
          duration: const Duration(seconds: 5),
        );
        setState(() => _mode = _WorkspaceMode.ai);
        _persistDraftState();
        _startAiPolling(firstDelay: _kFirstAiPollDelay);
        unawaited(_watchAiGenerationStream());
      } else if (immediateQuestions.isNotEmpty) {
        _pendingAiRequestId = null;
        _pendingAiExpectedCount = 0;
        _pendingAiRequestTopicIds.clear();
        _receivedAiQuestionIds.clear();
        _pendingAiStartedAt = null;
        _aiPolling = false;
        _persistDraftState();
        AppToast.success(
          context,
          title: '${immediateQuestions.length} questions ready',
          message:
              'The questions were loaded immediately and are waiting for instructor review.',
          duration: const Duration(seconds: 5),
        );
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

  Future<List<QuestionModel>> _hydrateImmediateGeneratedQuestions(
    QuestionsApi api,
    List<QuestionModel> summaries,
  ) async {
    final List<QuestionModel> hydrated = <QuestionModel>[];
    for (final QuestionModel summary in summaries) {
      final int? questionId = summary.remoteId ?? int.tryParse(summary.id);
      if (questionId == null || questionId <= 0) {
        hydrated.add(_decorateQuestionWithTargetContext(summary));
        continue;
      }
      try {
        final QuestionModel details = await api.getQuestion(
          courseId: widget.course.id,
          questionId: questionId,
        );
        _hydratedRemoteDetailIds.add(questionId);
        hydrated.add(
          _decorateQuestionWithTargetContext(
            _mergeQuestionContext(details, summary),
          ),
        );
      } catch (_) {
        hydrated.add(_decorateQuestionWithTargetContext(summary));
      }
    }
    return hydrated;
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

  void _stopAiPolling({bool clearCompletedRequest = false}) {
    _aiPollTimer?.cancel();
    _aiPollTimer = null;
    _aiPolling = false;
    _pendingAiRequestId = null;
    if (clearCompletedRequest) {
      _pendingAiRequestTopicIds.clear();
      _receivedAiQuestionIds.clear();
      _pendingAiExpectedCount = 0;
      _pendingAiStartedAt = null;
    }
    _persistDraftState();
    if (mounted) setState(() {});
  }

  Future<void> _watchAiGenerationStream() async {
    if (_aiStreamInFlight || !_aiPolling) return;
    _aiStreamInFlight = true;

    try {
      final event = await ref.read(questionsApiProvider).waitForQuestionGeneration(
            courseId: widget.course.id,
          );
      if (!mounted || !_aiPolling) return;

      if (event.isReady) {
        _aiPollTimer?.cancel();
        await _pollForAiQuestions();
      }
    } catch (_) {
      // Keep the existing polling fallback alive when the SSE connection is not
      // available or the backend still uses the temporary course-level channel.
    } finally {
      _aiStreamInFlight = false;
    }
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
          _selectedQuestionIds
            ..clear()
            ..addAll(
              hydrated
                  .where(_isPendingAiReview)
                  .map((QuestionModel question) => question.id),
            );
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
          _stopAiPolling(clearCompletedRequest: true);
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
  Widget build(BuildContext context) => _buildAuthoringScaffold(context);



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
        final String sourceLabel = question.source.label;
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
    final bool material = source == QuestionSource.nativeExtraction;
    final Color bg = ai
        ? AppColors.purpleBg
        : material
            ? AppColors.infoBg
            : AppColors.surfaceBg;
    final Color fg = ai
        ? AppColors.purpleText
        : material
            ? AppColors.primary
            : AppColors.textMuted;
    final IconData icon = ai
        ? Icons.auto_awesome_rounded
        : material
            ? Icons.description_outlined
            : Icons.edit_note_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            source.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: fg,
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



  Widget _iconAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    bool danger = false,
    bool compact = false,
  }) {
    final bool enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: compact ? 30 : 36,
          height: compact ? 30 : 36,
          decoration: BoxDecoration(
            color: !enabled
                ? AppColors.fieldDisabledBg
                : danger
                    ? AppColors.dangerBg
                    : AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: !enabled
                  ? AppColors.borderSoft
                  : danger
                      ? AppColors.dangerBorder
                      : AppColors.borderSoft,
            ),
          ),
          child: Icon(
            icon,
            size: compact ? 16 : 18,
            color: !enabled
                ? AppColors.textMuted.withValues(alpha: 0.55)
                : danger
                    ? AppColors.dangerText
                    : AppColors.textGray,
          ),
        ),
      ),
    );
  }
}



