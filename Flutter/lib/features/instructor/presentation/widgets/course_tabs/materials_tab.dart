import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/storage/key_value_store_factory.dart';
import '../../../../../core/network/error_mapper.dart';
import '../../../../../core/utils/debounced_action.dart';
import '../../../../../core/routing/routes.dart';
import '../../../../../core/ui/pdf_preview_view.dart';
import '../../../../../core/ui/toast.dart';
import '../../../../../shared/widgets/app_ui_components.dart';
import '../../../data/courses_models.dart';
import '../../../data/courses_providers.dart';
import '../../../data/modules_models.dart';
import '../../../data/materials_models.dart';
import '../../../data/topics_models.dart';
import '../../../data/learning_outcomes_models.dart';
import '../../../data/modules_materials_providers.dart';
import '../../../data/question_bank_refresh_signal.dart';
import '../../controllers/course_details_controller.dart';
import '../../controllers/course_details_state.dart';
import '../../course_route_identity.dart';
import '../../controllers/selected_course_provider.dart';
import '../add_question_sheet.dart';
import '../course_outcomes_panel.dart';
import '../upload_material_sheet.dart';

import '../generate_questions_dialog.dart';
import '../question_bank/question_bank_authoring_flow.dart';
import '../module_selector_sheet.dart';

part 'materials_tab_sidebar.dart';
part 'materials_tab_sidebar_module_panel.dart';
part 'materials_tab_sidebar_module_hero.dart';
part 'materials_tab_sidebar_canvas.dart';
part 'materials_tab_material_panel.dart';
part 'materials_tab_material_document_stage.dart';
part 'materials_tab_material_side_deck.dart';
part 'materials_tab_material_capture_topics.dart';
part 'materials_tab_material_previews.dart';
part 'materials_tab_topics.dart';
part 'materials_tab_topics_dialogs.dart';
part 'materials_tab_topics_workspace_v2.dart';
part 'materials_tab_topics_studio.dart';
part 'materials_tab_topics_details.dart';
part 'materials_tab_dialogs.dart';
part 'materials_tab_types.dart';
part 'materials_tab_question_draft_banner.dart';
part 'materials_tab_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Color palette
// ─────────────────────────────────────────────────────────────────────────────
// Core types live in materials_tab_types.dart.

class CourseMaterialsTab extends ConsumerStatefulWidget {
  final MyCourseItem course;
  final VoidCallback? onOpenCourseAssistant;
  final bool courseAssistantBusy;

  const CourseMaterialsTab({
    super.key,
    required this.course,
    this.onOpenCourseAssistant,
    this.courseAssistantBusy = false,
  });

  @override
  ConsumerState<CourseMaterialsTab> createState() => _CourseMaterialsTabState();
}

class _CourseMaterialsTabState extends ConsumerState<CourseMaterialsTab>
    with AutomaticKeepAliveClientMixin {
  final Set<int>    _expanded = {};
  final Set<int>    _expandedMaterialIds = {};
  final Set<int>    _expandedTopicIds = {};
  _Ctx?             _sel;
  final List<_Ctx>  _stack   = [];
  final ScrollController _scroll = ScrollController();
  final DebouncedAction _uiStatePersistDebouncer =
      DebouncedAction(const Duration(milliseconds: 350));
  late final _session = createSessionStore();
  late final _questionDraftStore = createLocalStore();
  bool _restored = false;
  bool _dialogOpen = false;
  int? _draggingModuleId;
  bool _selectionMode = false;
  _TreeSelectionState _treeSelection = _TreeSelectionState.empty;
  bool _hideFooterForActive = false;
  bool _showQuestionAuthoring = false;
  Set<int> _authoringModuleIds = const <int>{};
  Set<int> _authoringMaterialIds = const <int>{};
  Set<int> _authoringTopicIds = const <int>{};
  QuestionAuthoringLaunchContext? _authoringLaunchContext;
  String? _cachedQuestionDraftRaw;
  _QuestionDraftInfo? _cachedQuestionDraftInfo;

  static const double _sidebarDefaultWidth = 286.0;
  static const double _sidebarCompactWidth = 252.0;
  static const double _sidebarMinWidth = 220.0;
  static const double _sidebarMaxWidth = 440.0;
  double? _sidebarWidth;
  bool _sidebarCollapsed = false;
  bool _sidebarResizing = false;
  bool _treeRefreshing = false;
  final Set<int> _topicDetailsRequested = <int>{};
  final Set<int> _topicDetailsLoaded = <int>{};
  final Set<int> _topicDetailsFailed = <int>{};

  @override
  bool get wantKeepAlive => true;

  String get _uiStateKey => 'course:${widget.course.id}:materials_ui';
  String get _questionDraftKey => 'learnova:qauthor:${widget.course.id}:last';

  void _runStateUpdate(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_persistUiState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(courseDetailsControllerProvider(widget.course.id).notifier)
          .loadModules();
    });
  }

  @override
  void dispose() {
    _uiStatePersistDebouncer.cancel();
    _persistUiStateNow();
    _scroll.dispose();
    super.dispose();
  }

  _Ctx? get _active => _stack.isNotEmpty ? _stack.last : _sel;

  Future<T?> _showManagedDialog<T>({
    required WidgetBuilder builder,
    Color? barrierColor,
    bool barrierDismissible = true,
  }) async {
    if (mounted) setState(() => _dialogOpen = true);
    try {
      return await showDialog<T>(
        context: context,
        barrierColor: barrierColor,
        barrierDismissible: barrierDismissible,
        builder: builder,
      );
    } finally {
      if (mounted) setState(() => _dialogOpen = false);
    }
  }

  Set<int> _intSetFromJson(Object? value) {
    return ((value as List?) ?? const <dynamic>[])
        .whereType<num>()
        .map((num item) => item.toInt())
        .toSet();
  }

  Map<String, dynamic> _authoringTargetToJson(QuestionAuthoringTarget target) {
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

  QuestionAuthoringTarget? _authoringTargetFromJson(Object? value) {
    if (value is! Map) return null;
    final Map<String, dynamic> map = Map<String, dynamic>.from(value);
    final int? topicId = (map['topicId'] as num?)?.toInt();
    final String topicName = (map['topicName']?.toString() ?? '').trim();
    if (topicId == null || topicName.isEmpty) return null;
    return QuestionAuthoringTarget(
      moduleId: (map['moduleId'] as num?)?.toInt(),
      moduleName: map['moduleName']?.toString(),
      materialId: (map['materialId'] as num?)?.toInt(),
      materialName: map['materialName']?.toString(),
      topicId: topicId,
      topicName: topicName,
      isSubtopic: map['isSubtopic'] == true,
      parentTopicName: map['parentTopicName']?.toString(),
    );
  }

  List<QuestionAuthoringTarget> _authoringTargetsFromJson(Object? value) {
    return ((value as List?) ?? const <dynamic>[])
        .map(_authoringTargetFromJson)
        .whereType<QuestionAuthoringTarget>()
        .toList();
  }

  QuestionAuthoringScopeKind? _authoringKindFromName(Object? value) {
    final String? name = value?.toString();
    if (name == null) return null;
    for (final QuestionAuthoringScopeKind kind in QuestionAuthoringScopeKind.values) {
      if (kind.name == name) return kind;
    }
    return null;
  }

  Map<String, dynamic>? _authoringLaunchContextToJson(
    QuestionAuthoringLaunchContext? launchContext,
  ) {
    if (launchContext == null) return null;
    return <String, dynamic>{
      'kind': launchContext.kind.name,
      'title': launchContext.title,
      'subtitle': launchContext.subtitle,
      'selectedModuleId': launchContext.selectedModuleId,
      'selectedMaterialId': launchContext.selectedMaterialId,
      'selectedTopicId': launchContext.selectedTopicId,
      'selectedModuleIds': launchContext.selectedModuleIds.toList(),
      'selectedMaterialIds': launchContext.selectedMaterialIds.toList(),
      'selectedTopicIds': launchContext.selectedTopicIds.toList(),
      'targetSnapshots': launchContext.targetSnapshots
          .map(_authoringTargetToJson)
          .toList(),
    };
  }

  QuestionAuthoringLaunchContext? _authoringLaunchContextFromJson(Object? value) {
    if (value is! Map) return null;
    final QuestionAuthoringScopeKind? kind = _authoringKindFromName(value['kind']);
    if (kind == null) return null;
    final String title = (value['title']?.toString() ?? '').trim();
    final String subtitle = (value['subtitle']?.toString() ?? '').trim();
    return QuestionAuthoringLaunchContext(
      kind: kind,
      title: title.isEmpty ? 'Selected content' : title,
      subtitle: subtitle.isEmpty ? 'Question workspace restored from materials.' : subtitle,
      selectedModuleId: (value['selectedModuleId'] as num?)?.toInt(),
      selectedMaterialId: (value['selectedMaterialId'] as num?)?.toInt(),
      selectedTopicId: (value['selectedTopicId'] as num?)?.toInt(),
      selectedModuleIds: _intSetFromJson(value['selectedModuleIds']),
      selectedMaterialIds: _intSetFromJson(value['selectedMaterialIds']),
      selectedTopicIds: _intSetFromJson(value['selectedTopicIds']),
      targetSnapshots: _authoringTargetsFromJson(value['targetSnapshots']),
    );
  }


  void _persistUiState() {
    _uiStatePersistDebouncer.run(_persistUiStateNow);
  }

  void _persistUiStateNow() {
    final sel = _sel;
    final active = _active;
    final payload = <String, dynamic>{
      'expanded': _expanded.toList(),
      'expandedMaterials': _expandedMaterialIds.toList(),
      'expandedTopics': _expandedTopicIds.toList(),
      'scrollOffset': _scroll.hasClients ? _scroll.offset : 0.0,
      'selectedType': sel?.type.name,
      'selectedModuleId': sel?.module?.id,
      'selectedMaterialId': sel?.material?.id,
      'selectedTopicId': sel?.topic?.id,
      'activeTopicId': active?.type == _CType.topic ? active?.topic?.id : null,
      'selectionMode': _selectionMode,
      'treeSelectionModuleIds': _treeSelection.moduleIds.toList(),
      'treeSelectionMaterialIds': _treeSelection.materialIds.toList(),
      'treeSelectionTopicIds': _treeSelection.topicIds.toList(),
      'questionAuthoringOpen': _showQuestionAuthoring,
      'authoringModuleIds': _authoringModuleIds.toList(),
      'authoringMaterialIds': _authoringMaterialIds.toList(),
      'authoringTopicIds': _authoringTopicIds.toList(),
      'authoringLaunchContext': _authoringLaunchContextToJson(_authoringLaunchContext),
      'sidebarWidth': _sidebarWidth,
      'sidebarCollapsed': _sidebarCollapsed,
    };
    _session.setString(_uiStateKey, jsonEncode(payload));
  }

  void _maybeRestoreUiState(CourseDetailsState st) {
    if (_restored) return;
    final raw = _session.getString(_uiStateKey);
    if (raw == null || raw.isEmpty) {
      _restored = true;
      return;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final expanded = ((map['expanded'] as List?) ?? [])
          .map((e) => (e as num).toInt())
          .toSet();
      final expandedMaterials = ((map['expandedMaterials'] as List?) ?? [])
          .map((e) => (e as num).toInt())
          .toSet();
      final expandedTopics = ((map['expandedTopics'] as List?) ?? [])
          .map((e) => (e as num).toInt())
          .toSet();
      final selectedType = map['selectedType']?.toString();
      final selectedModuleId = (map['selectedModuleId'] as num?)?.toInt();
      final selectedMaterialId = (map['selectedMaterialId'] as num?)?.toInt();
      final selectedTopicId = (map['selectedTopicId'] as num?)?.toInt();
      final activeTopicId = (map['activeTopicId'] as num?)?.toInt();
      final storedOffset = (map['scrollOffset'] as num?)?.toDouble() ?? 0.0;
      final bool restoreSelectionMode = map['selectionMode'] == true;
      final _TreeSelectionState restoredTreeSelection = _TreeSelectionState(
        moduleIds: _intSetFromJson(map['treeSelectionModuleIds']),
        materialIds: _intSetFromJson(map['treeSelectionMaterialIds']),
        topicIds: _intSetFromJson(map['treeSelectionTopicIds']),
      );
      final bool restoreAuthoring = map['questionAuthoringOpen'] == true;
      final Set<int> authoringModuleIds = _intSetFromJson(map['authoringModuleIds']);
      final Set<int> authoringMaterialIds = _intSetFromJson(map['authoringMaterialIds']);
      final Set<int> authoringTopicIds = _intSetFromJson(map['authoringTopicIds']);
      final QuestionAuthoringLaunchContext? restoredLaunchContext =
          _authoringLaunchContextFromJson(map['authoringLaunchContext']);
      final double? restoredSidebarWidth = (map['sidebarWidth'] as num?)?.toDouble();
      if (restoredSidebarWidth != null && restoredSidebarWidth.isFinite) {
        _sidebarWidth = restoredSidebarWidth
            .clamp(_sidebarMinWidth, _sidebarMaxWidth)
            .toDouble();
      }
      _sidebarCollapsed = map['sidebarCollapsed'] == true;

      _selectionMode = restoreSelectionMode || !restoredTreeSelection.isEmpty;
      _treeSelection = restoredTreeSelection;

      if (restoreAuthoring) {
        _showQuestionAuthoring = true;
        _hideFooterForActive = true;
        _authoringModuleIds = authoringModuleIds.isNotEmpty
            ? authoringModuleIds
            : restoredTreeSelection.moduleIds;
        _authoringMaterialIds = authoringMaterialIds.isNotEmpty
            ? authoringMaterialIds
            : restoredTreeSelection.materialIds;
        _authoringTopicIds = authoringTopicIds.isNotEmpty
            ? authoringTopicIds
            : restoredTreeSelection.topicIds;
        _authoringLaunchContext = restoredLaunchContext;
      }

      ModuleItem? findModule(int? id) {
        if (id == null) return null;
        for (final m in st.modules) {
          if (m.id == id) return m;
        }
        return null;
      }

      MaterialItem? findMaterial(int moduleId, int? materialId) {
        if (materialId == null) return null;
        final materials = st.materials[moduleId] ?? const <MaterialItem>[];
        for (final mat in materials) {
          if (mat.id == materialId) return mat;
        }
        return null;
      }

      TopicItem? findTopic(int moduleId, int materialId, int? topicId) {
        if (topicId == null) return null;
        final topics = st.topics[moduleId] ?? const <TopicItem>[];
        for (final t in topics) {
          if (t.id == topicId && t.materialId == materialId) return t;
        }
        return null;
      }

      final module = findModule(selectedModuleId);
      if (selectedModuleId != null && module == null && st.modules.isNotEmpty) {
        return;
      }

      _expanded
        ..clear()
        ..addAll(expanded.where((id) => st.modules.any((m) => m.id == id)));
      _expandedMaterialIds
        ..clear()
        ..addAll(expandedMaterials);
      _expandedTopicIds
        ..clear()
        ..addAll(expandedTopics);

      if (module != null && !st.materials.containsKey(module.id)) {
        ref.read(courseDetailsControllerProvider(widget.course.id).notifier).loadMaterials(module.id);
        return;
      }

      if (module != null && selectedMaterialId != null &&
          (selectedTopicId != null || !st.topicsLoadedMaterialIds.contains(selectedMaterialId))) {
        ref
            .read(courseDetailsControllerProvider(widget.course.id).notifier)
            .loadTopicsForMaterial(
              moduleId: module.id,
              materialId: selectedMaterialId,
            );
      }

      _sel = null;
      _stack.clear();

      if (module != null) {
        if (selectedType == _CType.module.name) {
          _sel = _Ctx.module(module);
        } else {
          final material = findMaterial(module.id, selectedMaterialId);
          if (material != null) {
            if (selectedType == _CType.material.name) {
              _sel = _Ctx.material(module, material);
            } else {
              final topic = findTopic(module.id, material.id, selectedTopicId);
              _sel = _Ctx.material(module, material);
              if (topic != null) {
                _stack.add(_Ctx.topic(module, material, topic));
                if (activeTopicId != null && activeTopicId != selectedTopicId) {
                  final activeTopic = findTopic(module.id, material.id, activeTopicId);
                  if (activeTopic != null) {
                    _stack
                      ..clear()
                      ..add(_Ctx.topic(module, material, activeTopic));
                  }
                }
              }
              ref.read(courseDetailsControllerProvider(widget.course.id).notifier).fetchDownloadUrl(moduleId: module.id, materialId: material.id);
              ensureCourseLearningOutcomesLoaded(ref, widget.course.id);
            }
          }
        }
      }

      _restored = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        final max = _scroll.position.maxScrollExtent;
        final target = storedOffset.clamp(0.0, max);
        _scroll.jumpTo(target);
      });
      if (mounted) setState(() {});
    } catch (_) {
      _restored = true;
    }
  }


  Future<void> _refreshStructureTree(CourseDetailsState snapshot) async {
    if (_treeRefreshing) return;

    final activeModuleId = (_active ?? _sel)?.module?.id;
    final moduleIdsToReload = <int>{
      ..._expanded,
      ...snapshot.materials.keys,
      ...snapshot.topics.keys,
      if (activeModuleId != null) activeModuleId,
    };

    setState(() => _treeRefreshing = true);
    final notifier = ref.read(courseDetailsControllerProvider(widget.course.id).notifier);

    try {
      await notifier.loadModules(force: true);
      if (!mounted) return;

      final refreshed = ref.read(courseDetailsControllerProvider(widget.course.id));
      final existingModuleIds = refreshed.modules.map((module) => module.id).toSet();
      final visibleModuleIds = moduleIdsToReload
          .where(existingModuleIds.contains)
          .toList()
        ..sort();

      if (visibleModuleIds.isEmpty && activeModuleId == null) {
        setState(() {
          _expanded.removeWhere((id) => !existingModuleIds.contains(id));
          _expandedMaterialIds.clear();
          _expandedTopicIds.clear();
          _treeSelection = _treeSelection.clear();
          _hideFooterForActive = false;
          _persistUiState();
        });
        return;
      }

      final materialIdsToReload = <int>{
        ..._expandedMaterialIds,
        ..._treeSelection.materialIds,
        if ((_active ?? _sel)?.material != null) (_active ?? _sel)!.material!.id,
      };

      for (final moduleId in visibleModuleIds) {
        await notifier.loadMaterials(moduleId, force: true);
        if (!mounted) return;

        final moduleMaterials = ref
                .read(courseDetailsControllerProvider(widget.course.id))
                .materials[moduleId] ??
            const <MaterialItem>[];
        final matchingMaterialIds = moduleMaterials
            .map((MaterialItem material) => material.id)
            .where(materialIdsToReload.contains)
            .toList();
        for (final materialId in matchingMaterialIds) {
          await notifier.loadTopicsForMaterial(
            moduleId: moduleId,
            materialId: materialId,
            force: true,
          );
          if (!mounted) return;
        }
      }

      final afterTreeReload = ref.read(courseDetailsControllerProvider(widget.course.id));
      final validMaterialIds = <int>{
        for (final materials in afterTreeReload.materials.values)
          for (final material in materials) material.id,
      };
      final validTopicIds = <int>{
        for (final topics in afterTreeReload.topics.values)
          for (final topic in topics) topic.id,
      };

      if (!mounted) return;
      setState(() {
        _expanded.removeWhere((id) => !existingModuleIds.contains(id));
        _expandedMaterialIds.removeWhere((id) => !validMaterialIds.contains(id));
        _expandedTopicIds.removeWhere((id) => !validTopicIds.contains(id));
        _treeSelection = _treeSelection.copyWith(
          moduleIds: _treeSelection.moduleIds.where(existingModuleIds.contains).toSet(),
          materialIds: _treeSelection.materialIds.where(validMaterialIds.contains).toSet(),
          topicIds: _treeSelection.topicIds.where(validTopicIds.contains).toSet(),
        );
        if (_treeSelection.isEmpty) {
          _hideFooterForActive = false;
        }
        _persistUiState();
      });
    } finally {
      if (mounted) setState(() => _treeRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildMaterialsScaffold(context);
  }

  _Ctx? _footerCtxFromSelection(CourseDetailsState st) {
    if (_treeSelection.moduleIds.isNotEmpty) {
      for (final module in st.modules) {
        if (_treeSelection.moduleIds.contains(module.id)) {
          return _Ctx.module(module);
        }
      }
    }

    if (_treeSelection.materialIds.isNotEmpty) {
      for (final module in st.modules) {
        final materials = st.materials[module.id] ?? const <MaterialItem>[];
        for (final material in materials) {
          if (_treeSelection.materialIds.contains(material.id)) {
            return _Ctx.material(module, material);
          }
        }
      }
    }

    if (_treeSelection.topicIds.isNotEmpty) {
      for (final module in st.modules) {
        final topics = st.topics[module.id] ?? const <TopicItem>[];
        for (final topic in topics) {
          if (_treeSelection.topicIds.contains(topic.id)) {
            final materials = st.materials[module.id] ?? const <MaterialItem>[];
            for (final material in materials) {
              if (material.id == topic.materialId) {
                return _Ctx.topic(module, material, topic);
              }
            }
          }
        }
      }
    }

    return null;
  }

  bool _canGenerate(_Ctx ctx, CourseDetailsState st) {
    switch (ctx.type) {
      case _CType.module:
        final mats = st.materials[ctx.module!.id] ?? const <MaterialItem>[];
        return mats.isNotEmpty;
      case _CType.material:
        return ctx.material != null;
      case _CType.topic:
        return ctx.material != null && ctx.topic != null;
    }
  }


  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      _hideFooterForActive = false;
      if (!_selectionMode) {
        _treeSelection = _treeSelection.clear();
      }
    });
    _persistUiState();
  }

  void _clearTreeSelection() {
    if (_treeSelection.isEmpty) return;
    setState(() {
      _treeSelection = _treeSelection.clear();
      _selectionMode = false;
      _hideFooterForActive = false;
    });
    _persistUiState();
  }

  List<MaterialItem> _materialsForModule(CourseDetailsState st, int moduleId) {
    return st.materials[moduleId] ?? const <MaterialItem>[];
  }

  List<TopicItem> _topicsForMaterial(CourseDetailsState st, int moduleId, int materialId) {
    final items = st.topics[moduleId] ?? const <TopicItem>[];
    return items.where((t) => t.materialId == materialId).toList();
  }

  List<TopicItem> _childTopics(List<TopicItem> topics, int parentTopicId) {
    final items = topics.where((t) => t.parentTopicId == parentTopicId).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return items;
  }


  Set<int> _selectableTopicIdsForTopic(List<TopicItem> materialTopics, TopicItem topic) {
    final children = _childTopics(materialTopics, topic.id);
    if (children.isEmpty) {
      return <int>{topic.id};
    }

    final ids = <int>{};
    for (final child in children) {
      ids.addAll(_selectableTopicIdsForTopic(materialTopics, child));
    }
    return ids;
  }

  Set<int> _selectableTopicIdsForMaterial(
    CourseDetailsState st,
    int moduleId,
    int materialId,
  ) {
    final materialTopics = _topicsForMaterial(st, moduleId, materialId);
    final roots = materialTopics.where((topic) => topic.parentTopicId == null).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final ids = <int>{};
    for (final root in roots) {
      ids.addAll(_selectableTopicIdsForTopic(materialTopics, root));
    }
    return ids;
  }

  Set<int> _selectableTopicIdsForModule(CourseDetailsState st, int moduleId) {
    final ids = <int>{};
    for (final material in _materialsForModule(st, moduleId)) {
      ids.addAll(_selectableTopicIdsForMaterial(st, moduleId, material.id));
    }
    return ids;
  }

  Set<int> _allSelectableTopicIds(CourseDetailsState st) {
    final ids = <int>{};
    for (final module in st.modules) {
      ids.addAll(_selectableTopicIdsForModule(st, module.id));
    }
    return ids;
  }

  _TreeSelectionState _normalizeTreeSelection(
    CourseDetailsState st, {
    required Set<int> moduleIds,
    required Set<int> materialIds,
    required Set<int> topicIds,
  }) {
    final nextTopics = topicIds.intersection(_allSelectableTopicIds(st));
    final nextMaterials = <int>{};
    final nextModules = <int>{};

    for (final module in st.modules) {
      final materials = _materialsForModule(st, module.id);
      var selectableMaterialsCount = 0;
      var selectedMaterialsCount = 0;

      for (final material in materials) {
        final selectableTopicIds = _selectableTopicIdsForMaterial(st, module.id, material.id);
        if (selectableTopicIds.isEmpty) continue;
        selectableMaterialsCount++;

        if (nextTopics.containsAll(selectableTopicIds)) {
          nextMaterials.add(material.id);
          selectedMaterialsCount++;
        }
      }

      if (selectableMaterialsCount > 0 && selectedMaterialsCount == selectableMaterialsCount) {
        nextModules.add(module.id);
      }
    }

    return _TreeSelectionState(
      moduleIds: nextModules,
      materialIds: nextMaterials,
      topicIds: nextTopics,
    );
  }

  void _toggleMaterialExpanded(MaterialItem material) {
    setState(() {
      if (!_expandedMaterialIds.add(material.id)) {
        _expandedMaterialIds.remove(material.id);
      }
      _persistUiState();
    });
  }

  void _toggleTopicExpanded(TopicItem topic) {
    setState(() {
      if (!_expandedTopicIds.add(topic.id)) {
        _expandedTopicIds.remove(topic.id);
      }
      _persistUiState();
    });
  }

  void _setModuleChecked(ModuleItem module, CourseDetailsState st, bool checked) {
    final selectableTopicIds = _selectableTopicIdsForModule(st, module.id);
    if (selectableTopicIds.isEmpty) return;

    setState(() {
      final nextTopics = {..._treeSelection.topicIds};
      if (checked) {
        nextTopics.addAll(selectableTopicIds);
      } else {
        nextTopics.removeAll(selectableTopicIds);
      }

      _treeSelection = _normalizeTreeSelection(
        st,
        moduleIds: const <int>{},
        materialIds: const <int>{},
        topicIds: nextTopics,
      );
    });
    _persistUiState();
  }

  void _setMaterialChecked(ModuleItem module, MaterialItem material, CourseDetailsState st, bool checked) {
    final selectableTopicIds = _selectableTopicIdsForMaterial(st, module.id, material.id);
    if (selectableTopicIds.isEmpty) return;

    setState(() {
      final nextTopics = {..._treeSelection.topicIds};
      if (checked) {
        nextTopics.addAll(selectableTopicIds);
      } else {
        nextTopics.removeAll(selectableTopicIds);
      }

      _treeSelection = _normalizeTreeSelection(
        st,
        moduleIds: const <int>{},
        materialIds: const <int>{},
        topicIds: nextTopics,
      );
    });
    _persistUiState();
  }

  void _setTopicChecked(
    ModuleItem module,
    MaterialItem material,
    TopicItem topic,
    CourseDetailsState st,
    bool checked,
  ) {
    final allTopics = _topicsForMaterial(st, module.id, material.id);
    final selectableTopicIds = _selectableTopicIdsForTopic(allTopics, topic);
    if (selectableTopicIds.isEmpty) return;

    setState(() {
      final nextTopics = {..._treeSelection.topicIds};
      if (checked) {
        nextTopics.addAll(selectableTopicIds);
      } else {
        nextTopics.removeAll(selectableTopicIds);
      }

      _treeSelection = _normalizeTreeSelection(
        st,
        moduleIds: const <int>{},
        materialIds: const <int>{},
        topicIds: nextTopics,
      );
    });
    _persistUiState();
  }

  void _ensureTopicDetailsLoaded(ModuleItem module, MaterialItem material, TopicItem topic) {
    if (topic.pageStart != null && topic.pageEnd != null) {
      _topicDetailsLoaded.add(topic.id);
      return;
    }
    if (_topicDetailsRequested.contains(topic.id)) return;
    _topicDetailsRequested.add(topic.id);
    _topicDetailsFailed.remove(topic.id);

    unawaited(
      ref
          .read(courseDetailsControllerProvider(widget.course.id).notifier)
          .loadTopicDetails(
            moduleId: module.id,
            materialId: material.id,
            topicId: topic.id,
          )
          .then((loaded) {
        if (!mounted) return;
        if (loaded == null) {
          setState(() => _topicDetailsFailed.add(topic.id));
          return;
        }
        _topicDetailsLoaded.add(loaded.id);
        setState(() {
          for (var i = 0; i < _stack.length; i++) {
            final ctx = _stack[i];
            if (ctx.type == _CType.topic && ctx.topic?.id == loaded.id) {
              _stack[i] = _Ctx.topic(module, material, loaded);
            }
          }
        });
        _persistUiState();
      }),
    );
  }

  // ── Tap handlers ────────────────────────────────────────────────────────
  void _tapModule(ModuleItem m, CourseDetailsState st) {
    setState(() {
      final alreadySel = _active?.type == _CType.module && _active?.module?.id == m.id;
      if (_expanded.contains(m.id) && alreadySel) {
        _expanded.remove(m.id); _sel = null; _stack.clear();
        _hideFooterForActive = false;
        _persistUiState();
      } else {
        _expanded.add(m.id); _sel = _Ctx.module(m); _stack.clear();
        _hideFooterForActive = false;
        if (!st.materials.containsKey(m.id)) {
          ref.read(courseDetailsControllerProvider(widget.course.id).notifier).loadMaterials(m.id);
        }
        _persistUiState();
      }
    });
  }

  void _tapMaterial(ModuleItem m, MaterialItem mat) {
    setState(() {
      _expanded.add(m.id);
      _expandedMaterialIds.add(mat.id);
      _sel = _Ctx.material(m, mat);
      _stack.clear();
      _hideFooterForActive = false;
    });
    _persistUiState();
    final notifier = ref.read(courseDetailsControllerProvider(widget.course.id).notifier);
    notifier.loadTopicsForMaterial(moduleId: m.id, materialId: mat.id);
    notifier.fetchDownloadUrl(moduleId: m.id, materialId: mat.id);
    ensureCourseLearningOutcomesLoaded(ref, widget.course.id);
  }

  void _tapTopic(ModuleItem m, MaterialItem mat, TopicItem t) {
    setState(() {
      _expanded.add(m.id);
      _expandedMaterialIds.add(mat.id);
      if (t.parentTopicId == null) {
        _expandedTopicIds.add(t.id);
      }
      _sel = _Ctx.material(m, mat);
      _stack..clear()..add(_Ctx.topic(m, mat, t));
      _hideFooterForActive = false;
    });
    _persistUiState();
    _ensureTopicDetailsLoaded(m, mat, t);
    ref.read(courseDetailsControllerProvider(widget.course.id).notifier)
        .fetchDownloadUrl(moduleId: m.id, materialId: mat.id);
  }

  Future<void> _handleModuleReorder(int oldIndex, int newIndex) async {
    final orderedModules = [...ref.read(courseDetailsControllerProvider(widget.course.id)).modules]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    if (orderedModules.length < 2) return;

    var targetIndex = newIndex;
    if (targetIndex > oldIndex) targetIndex -= 1;
    if (targetIndex < 0 || targetIndex >= orderedModules.length) return;

    final movedModule = orderedModules[oldIndex];
    final movedTitle = movedModule.title;
    final success = await ref
        .read(courseDetailsControllerProvider(widget.course.id).notifier)
        .reorderModule(moduleId: movedModule.id, newPosition: targetIndex);

    if (!mounted) return;
    setState(() => _draggingModuleId = null);
    if (success) {
      AppToast.success(
        context,
        title: 'Module reordered',
        message: '"$movedTitle" moved to position ${targetIndex + 1}.',
      );
      _persistUiState();
    } else {
      AppToast.error(
        context,
        title: 'Reorder failed',
        message: 'Could not update the module order. Please try again.',
      );
    }
  }

  void _drillTopic(TopicItem t) {
    final c = _sel; if (c?.module == null || c?.material == null) return;
    setState(() {
      _stack.add(_Ctx.topic(c!.module!, c.material!, t));
      _hideFooterForActive = false;
    });
    _persistUiState();
    _ensureTopicDetailsLoaded(c!.module!, c.material!, t);
  }

  void _pop() => setState(() { if (_stack.isNotEmpty) _stack.removeLast(); _hideFooterForActive = false; _persistUiState(); });

  // ── Right panel routing ──────────────────────────────────────────────────
  Widget _buildPanel(CourseDetailsState st) {
    final c = _active;
    if (c == null) return _EmptyStateWidget(onCreate: _showCreateModuleDialog);

    if (c.type == _CType.module) {
      return _ModulePanelWidget(
        module: c.module!, materials: st.materials[c.module!.id] ?? [],
        uploading: st.uploading, uploadProgress: st.uploadProgress,
        onUpload: () => _showUploadSheet(c.module!),
        onMaterialTap: (mat) => _tapMaterial(c.module!, mat),
        onRename: () => _showRenameDialog(c.module!),
        onEditDescription: () => _showEditDescriptionDialog(c.module!),
        onTogglePublish: () => _togglePublish(c.module!),
        onChangePosition: () => _showChangePositionDialog(c.module!),
        onDelete: () => _confirmDelete(c.module!),
        onShare: () => _showShareModuleDialog(c.module!),
      );
    }

    if (c.type == _CType.material) {
      final mid = c.module!.id;
      final matId = c.material!.id;
      final materialTopics = (st.topics[mid] ?? const <TopicItem>[])
          .where((t) => t.materialId == matId)
          .toList();
      final outcomes = ref.watch(courseLOProvider(widget.course.id));
      return _MaterialPanelWidget(
        module: c.module!, material: c.material!,
        topics: materialTopics, topicsLoading: st.topicsLoading[mid] ?? false,
        outcomes: outcomes,
        downloadUrl: st.downloadUrls[matId] ?? c.material!.downloadUrl,
        urlLoading: st.downloadUrlLoading[matId] ?? false,
        onTopicTap: _drillTopic,
        onCreateTopicManual: (title, description, learningOutcomeIds) =>
            _createManualTopicInline(
          module: c.module!,
          material: c.material!,
          title: title,
          description: description,
          learningOutcomeIds: learningOutcomeIds,
        ),
        onRefreshUrl: () => ref.read(courseDetailsControllerProvider(widget.course.id).notifier)
            .fetchDownloadUrl(moduleId: mid, materialId: matId, force: true),
        onDeleteMaterial: () => _confirmDeleteMaterial(c.module!, c.material!),
        previewInteractive: !_dialogOpen,
      );
    }

    final outcomes = ref.watch(courseLOProvider(widget.course.id));
    final mid = c.module!.id;
    final matId = c.material!.id;
    final materialTopics = (st.topics[mid] ?? const <TopicItem>[])
        .where((t) => t.materialId == matId)
        .toList();
    final activeTopic = materialTopics.firstWhere(
      (t) => t.id == c.topic!.id,
      orElse: () => c.topic!,
    );
    _ensureTopicDetailsLoaded(c.module!, c.material!, activeTopic);
    return _TopicPanelWidget(
      module: c.module!,
      material: c.material!,
      topic: activeTopic,
      topicDetailsLoaded: _topicDetailsLoaded.contains(activeTopic.id),
      topicDetailsFailed: _topicDetailsFailed.contains(activeTopic.id),
      allMaterialTopics: materialTopics,
      outcomes: outcomes,
      downloadUrl: st.downloadUrls[matId] ?? c.material!.downloadUrl,
      urlLoading: st.downloadUrlLoading[matId] ?? false,
      onRefreshUrl: () => ref.read(courseDetailsControllerProvider(widget.course.id).notifier)
          .fetchDownloadUrl(moduleId: mid, materialId: matId, force: true),
      previewInteractive: !_dialogOpen,
      canPop: _stack.isNotEmpty,
      onBack: _pop,
      onRenameTopic: () => _showRenameTopicDialog(c.module!, c.material!, activeTopic),
      onEditTopicSummary: () => _showTopicSummaryDialog(c.module!, c.material!, activeTopic),
      onEditTopicStatus: () => _showTopicStatusDialog(c.module!, c.material!, activeTopic),
      onMapTopicOutcomes: () => _showTopicOutcomeMappingDialog(c.module!, c.material!, activeTopic),
      onDeleteTopic: () => _confirmDeleteTopic(c.module!, c.material!, activeTopic),
      onOpenSubtopic: _drillTopic,
      onAddSubtopic: () => _showAddSubtopicDialog(c.module!, c.material!, activeTopic),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────
Future<void> _showRenameTopicDialog(ModuleItem m, MaterialItem mat, TopicItem topic) async {
  final ctrl = TextEditingController(text: topic.title);
  final result = await _showManagedDialog<bool>(
    barrierColor: Colors.black.withValues(alpha: 0.38),
    builder: (_) => _PreferencesDialogShell(
      title: topic.parentTopicId == null ? 'Rename topic' : 'Rename subtopic',
      subtitle: 'This popup changes the title only.',
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.drive_file_rename_outline_rounded, size: 18, color: AppColors.primary),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DialogTextField(
            controller: ctrl,
            hintText: 'Write a clear title',
            autofocus: true,
          ),
          const SizedBox(height: 16),
          _DialogActions(
            onCancel: () => Navigator.pop(context, false),
            onConfirm: () => Navigator.pop(context, true),
            confirmLabel: 'Save title',
          ),
        ],
      ),
    ),
  );

  if (result != true || !mounted) return;
  final title = ctrl.text.trim();
  ctrl.dispose();
  if (title.isEmpty) {
    AppToast.error(context, title: 'Title required', message: 'Topic title cannot be empty.');
    return;
  }
  await ref.read(courseDetailsControllerProvider(widget.course.id).notifier).updateTopic(
        topic.copyWith(moduleId: m.id, materialId: mat.id, title: title),
      );
  if (!mounted) return;
  AppToast.success(context, title: 'Title updated', message: 'The topic title was saved.');
}

Future<void> _showTopicSummaryDialog(ModuleItem m, MaterialItem mat, TopicItem topic) async {
  final descriptionCtrl = TextEditingController(text: topic.description ?? '');
  final notesCtrl = TextEditingController(text: topic.instructorNotes ?? '');
  final result = await _showManagedDialog<bool>(
    barrierColor: Colors.black.withValues(alpha: 0.38),
    builder: (_) => _PreferencesDialogShell(
      title: 'Edit summary',
      subtitle: 'This popup only updates the scope and instructor notes.',
      maxWidth: 680,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.notes_rounded, size: 18, color: AppColors.primary),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Scope / description', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          _DialogTextField(
            controller: descriptionCtrl,
            hintText: 'What exactly does this topic cover?',
            multiline: true,
            autofocus: true,
          ),
          const SizedBox(height: 14),
          Text('Instructor notes', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          _DialogTextField(
            controller: notesCtrl,
            hintText: 'Examples, warnings, pacing notes, or delivery hints',
            multiline: true,
          ),
          const SizedBox(height: 16),
          _DialogActions(
            onCancel: () => Navigator.pop(context, false),
            onConfirm: () => Navigator.pop(context, true),
            confirmLabel: 'Save summary',
          ),
        ],
      ),
    ),
  );

  if (result != true || !mounted) return;
  final description = descriptionCtrl.text.trim();
  final notes = notesCtrl.text.trim();
  descriptionCtrl.dispose();
  notesCtrl.dispose();
  await ref.read(courseDetailsControllerProvider(widget.course.id).notifier).updateTopic(
        topic.copyWith(
          moduleId: m.id,
          materialId: mat.id,
          description: description.isEmpty ? null : description,
          instructorNotes: notes.isEmpty ? null : notes,
        ),
      );
  if (!mounted) return;
  AppToast.success(context, title: 'Summary updated', message: 'The topic summary was saved.');
}

Future<void> _showTopicStatusDialog(ModuleItem m, MaterialItem mat, TopicItem topic) async {
  TopicDifficulty difficulty = topic.difficulty;
  TopicReadiness readiness = topic.readiness;

  final result = await _showManagedDialog<bool>(
    barrierColor: Colors.black.withValues(alpha: 0.38),
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => _PreferencesDialogShell(
        title: 'Set delivery state',
        subtitle: 'This popup only changes difficulty and readiness.',
        maxWidth: 600,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.speed_rounded, size: 18, color: AppColors.primary),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Difficulty', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in TopicDifficulty.values)
                  ChoiceChip(
                    label: Text(value.label),
                    selected: difficulty == value,
                    onSelected: (_) => setDialogState(() => difficulty = value),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Readiness', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in TopicReadiness.values)
                  ChoiceChip(
                    label: Text(value.label),
                    selected: readiness == value,
                    onSelected: (_) => setDialogState(() => readiness = value),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _DialogActions(
              onCancel: () => Navigator.pop(dialogContext, false),
              onConfirm: () => Navigator.pop(dialogContext, true),
              confirmLabel: 'Save state',
            ),
          ],
        ),
      ),
    ),
  );

  if (result != true || !mounted) return;
  await ref.read(courseDetailsControllerProvider(widget.course.id).notifier).updateTopic(
        topic.copyWith(
          moduleId: m.id,
          materialId: mat.id,
          difficulty: difficulty,
          readiness: readiness,
        ),
      );
  if (!mounted) return;
  AppToast.success(context, title: 'State updated', message: 'Delivery state was saved.');
}

Future<void> _showTopicOutcomeMappingDialog(ModuleItem m, MaterialItem mat, TopicItem topic) async {
  final outcomes = ref.read(courseLOProvider(widget.course.id));

  if (topic.parentTopicId == null) {
    final allTopics = ref.read(courseDetailsControllerProvider(widget.course.id)).topics[m.id] ?? const <TopicItem>[];
    final subtopics = allTopics.where((t) => t.parentTopicId == topic.id).toList();
    final childMappedIds = <int>{};
    for (final subtopic in subtopics) {
      childMappedIds.addAll(subtopic.learningOutcomeIds);
      for (final raw in subtopic.linkedOutcomeIds) {
        final parsed = int.tryParse(raw);
        if (parsed != null) childMappedIds.add(parsed);
      }
      final legacy = int.tryParse(subtopic.linkedOutcomeId ?? '');
      if (legacy != null) childMappedIds.add(legacy);
    }
    final parentIds = <int>{};
    for (final outcome in outcomes) {
      if (childMappedIds.contains(outcome.id)) {
        if (outcome.parentLearningOutcomeId != null) {
          parentIds.add(outcome.parentLearningOutcomeId!);
        } else {
          parentIds.add(outcome.id);
        }
      }
    }
    final parentLabels = outcomes
        .where((outcome) => parentIds.contains(outcome.id))
        .toList();

    await _showManagedDialog<void>(
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => _PreferencesDialogShell(
        title: 'LO labels come from subtopics',
        subtitle: 'Sub LOs are mapped on subtopics. This topic shows the parent LO labels automatically.',
        maxWidth: 620,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.account_tree_outlined, size: 18, color: AppColors.primary),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                subtopics.isEmpty
                    ? 'Create subtopics first, then map each subtopic to one Sub LO only.'
                    : 'Visible labels are calculated from each subtopic’s single Sub LO mapping.',
                style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textGray, fontWeight: FontWeight.w700),
              ),
            ),
            if (parentLabels.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Visible on this topic', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final outcome in parentLabels)
                    Chip(label: Text('${outcome.code} • ${outcome.title}')),
                ],
              ),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: 'Got it',
              onTap: () => Navigator.pop(context),
              fullWidth: true,
              height: 40,
            ),
          ],
        ),
      ),
    );
    return;
  }

  final subOutcomes = outcomes.where((outcome) => outcome.isSubOutcome).toList();
  final parents = outcomes.where((outcome) => outcome.isParentOutcome).toList();
  final childrenByParent = groupSubOutcomesByParent(outcomes);
  final outcomesById = <int, LearningOutcome>{
    for (final outcome in outcomes) outcome.id: outcome,
  };

  int? parentIdForOutcomeId(int id) {
    final outcome = outcomesById[id];
    if (outcome == null) return null;
    return outcome.parentLearningOutcomeId ?? (outcome.isParentOutcome ? outcome.id : null);
  }

  final selectedOutcomeIds = <int>{..._mappedOutcomeIdsForTopic(topic)}
    ..removeWhere((id) => outcomesById[id]?.isSubOutcome != true);
  if (selectedOutcomeIds.length > 1) {
    final firstSelectedId = (selectedOutcomeIds.toList()..sort()).first;
    selectedOutcomeIds
      ..clear()
      ..add(firstSelectedId);
  }
  int? selectedParentId = selectedOutcomeIds.isEmpty
      ? null
      : parentIdForOutcomeId(selectedOutcomeIds.first);

  final result = await _showManagedDialog<bool>(
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        final selectedCount = selectedOutcomeIds.length;
        return _PreferencesDialogShell(
          title: 'Map Sub LO to subtopic',
          subtitle: 'Choose one Sub LO only. Selecting another Sub LO replaces the current mapping.',
          maxWidth: 860,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.badgeBlueBorder),
            ),
            child: const Icon(Icons.route_outlined, size: 19, color: AppColors.primary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: const Icon(Icons.subdirectory_arrow_right_rounded, size: 17, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(topic.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
                          const SizedBox(height: 2),
                          Text('Subtopic Sub LO mapping', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: selectedCount == 0 ? AppColors.cardBg : AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: selectedCount == 0 ? AppColors.border : AppColors.badgeBlueBorder),
                      ),
                      child: Text(
                        selectedCount == 0
                            ? 'No Sub LO selected'
                            : outcomesById[selectedOutcomeIds.first]?.title ?? '1 Sub LO selected',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: selectedCount == 0 ? AppColors.textMuted : AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (subOutcomes.isEmpty)
                const _CriteriaMappingEmptyState()
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 470),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Scrollbar(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: parents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final parent = parents[i];
                          final children = [...(childrenByParent[parent.id] ?? const <LearningOutcome>[])]
                            ..sort((a, b) {
                              final difficultyOrder = a.difficulty.index.compareTo(b.difficulty.index);
                              if (difficultyOrder != 0) return difficultyOrder;
                              return a.code.compareTo(b.code);
                            });

                          return _CriteriaMappingLoGroup(
                            parent: parent,
                            criteria: children,
                            selectedIds: selectedOutcomeIds,
                            activeParentId: selectedParentId,
                            onToggle: (criterion) => setDialogState(() {
                              final criterionParentId = parentIdForOutcomeId(criterion.id);
                              if (selectedOutcomeIds.contains(criterion.id)) {
                                selectedOutcomeIds.clear();
                                selectedParentId = null;
                                return;
                              }

                              selectedOutcomeIds
                                ..clear()
                                ..add(criterion.id);
                              selectedParentId = criterionParentId;
                            }),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 42,
                    child: FilledButton.icon(
                      onPressed: subOutcomes.isEmpty ? null : () => Navigator.pop(dialogContext, true),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Save mapping'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );

  if (result != true || !mounted) return;
  final mappedIds = selectedOutcomeIds.toList()..sort();
  await ref.read(courseDetailsControllerProvider(widget.course.id).notifier).updateTopic(
        topic.copyWith(
          moduleId: m.id,
          materialId: mat.id,
          learningOutcomeIds: mappedIds,
          linkedOutcomeId: mappedIds.isEmpty ? null : mappedIds.first.toString(),
          linkedOutcomeIds: mappedIds.map((id) => id.toString()).toList(),
        ),
      );
  if (!mounted) return;
  AppToast.success(context, title: 'Sub LO mapping updated', message: 'The subtopic mapping was saved.');
}

Future<void> _confirmDeleteTopic(ModuleItem m, MaterialItem mat, TopicItem topic) async {
  final ok = await _showManagedDialog<bool>(
        barrierColor: Colors.black.withValues(alpha: 0.38),
        builder: (_) => _ConfirmDialogWidget(
          title: topic.parentTopicId == null ? 'Delete Topic' : 'Delete Subtopic',
          body: 'Delete "${topic.title}"? This action cannot be undone.',
          confirm: 'Delete',
          confirmColor: AppColors.dangerText,
        ),
      ) ??
      false;
  if (!ok || !mounted) return;

  await ref.read(courseDetailsControllerProvider(widget.course.id).notifier).deleteTopic(
        moduleId: m.id,
        materialId: mat.id,
        topicId: topic.id,
      );
  if (!mounted) return;
  setState(() {
    _sel = _Ctx.material(m, mat);
    _stack.clear();
    _persistUiState();
  });
  AppToast.success(context, title: 'Deleted', message: 'The item was removed from this material.');
}

Future<void> _showAddSubtopicDialog(
  ModuleItem m,
  MaterialItem mat,
  TopicItem parent,
) async {
  final outcomes = ref.read(courseLOProvider(widget.course.id));

  final result = await _showManagedDialog<_TopicDialogResult>(
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (_) => _AddTopicDialogV2(outcomes: outcomes, isSubtopic: true),
  );

  if (result == null || !mounted) return;

  final title = result.title.trim();
  if (title.isEmpty) return;

  final notifier =
      ref.read(courseDetailsControllerProvider(widget.course.id).notifier);

  final topic = await notifier.createTopic(
    moduleId: m.id,
    materialId: mat.id,
    payload: TopicCreateRequest(
      title: title,
      parentTopicId: parent.id,
      learningOutcomeIds: result.learningOutcomeIds,
    ),
  );

  if (!mounted) return;

  if (topic != null) {
    AppToast.success(context,
        title: 'Subtopic added', message: '"${topic.title}" created.',);
  }
}

Future<void> _showCreateModuleDialog() async {
  final currentModules =
      ref.read(courseDetailsControllerProvider(widget.course.id)).modules;

  if (mounted) setState(() => _dialogOpen = true);

  final result = await showModuleSelectorSheet(
    context,
    widget.course.id,
    currentModules: currentModules,
  );

  if (mounted) setState(() => _dialogOpen = false);

  if (result == null || !mounted) return;

  final notifier =
      ref.read(courseDetailsControllerProvider(widget.course.id).notifier);

  if (result.isNew) {
    final m = await notifier.createModule(
      result.newTitle!,
      description: result.newDescription,
    );

    if (m != null && mounted) {
      AppToast.success(context,
          title: 'Module created', message: '"${m.title}" added.',);
    }
    return;
  }

  final sourceModule = result.existing;
  final sourceCourseId = result.sourceCourseId;
  if (sourceModule == null || sourceCourseId == null) {
    AppToast.error(
      context,
      title: 'Copy failed',
      message: 'Could not determine which module to copy.',
    );
    return;
  }

  final copied = await notifier.copyModule(
    sourceCourseId: sourceCourseId,
    moduleId: sourceModule.id,
    targetCourseId: widget.course.id,
  );

  if (!mounted) return;

  if (copied != null) {
    final refreshedModule = ref
        .read(courseDetailsControllerProvider(widget.course.id))
        .modules
        .where((m) => m.id == copied.id)
        .cast<ModuleItem?>()
        .firstWhere((m) => m != null, orElse: () => copied);

    setState(() {
      _expanded.add(refreshedModule!.id);
      _sel = _Ctx.module(refreshedModule);
      _stack.clear();
      _persistUiState();
    });
    if (refreshedModule != null) {
      await ref
          .read(courseDetailsControllerProvider(widget.course.id).notifier)
          .loadMaterials(refreshedModule.id);
    }

    if (!mounted) return;

    AppToast.success(
      context,
      title: 'Module copied',
      message: '"${sourceModule.title}" added.',
    );
  } else {
    AppToast.error(
      context,
      title: 'Copy failed',
      message: 'Could not copy module. Please try again.',
    );
  }
}

  Future<void> _showUploadSheet(ModuleItem module) async {
    final saved = await _showManagedDialog<bool>(
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => UploadMaterialSheet(
        moduleTitle: module.title,
        onUpload: (file, update) => _uploadAndWaitForMaterial(
          module: module,
          file: file,
          update: update,
        ),
      ),
    );

    await ref
        .read(courseDetailsControllerProvider(widget.course.id).notifier)
        .loadMaterials(module.id, force: true);

    if (!mounted || saved != true) return;
    AppToast.success(
      context,
      title: 'Materials ready',
      message: 'Uploaded files were processed and saved to the course.',
    );
  }

  Future<UploadSheetUploadResult> _uploadAndWaitForMaterial({
    required ModuleItem module,
    required UploadSheetResult file,
    required void Function(UploadSheetUploadUpdate update) update,
  }) async {
    final notifier = ref.read(courseDetailsControllerProvider(widget.course.id).notifier);

    update(const UploadSheetUploadUpdate(
      stage: UploadSheetProcessingStage.uploading,
      progress: 0,
      message: 'Creating upload slot...',
    ));

    final result = await notifier.uploadMaterialFlow(
      moduleId: module.id,
      bytes: file.bytes,
      filename: file.filename,
      contentType: file.contentType,
      title: file.title,
      onUploadProgress: (progress) {
        update(UploadSheetUploadUpdate(
          stage: UploadSheetProcessingStage.uploading,
          progress: progress,
          message: progress < 0.7
              ? 'Uploading PDF to storage...'
              : 'Confirming upload and starting AI...',
        ));
      },
    );

    if (result == null) {
      update(const UploadSheetUploadUpdate(
        stage: UploadSheetProcessingStage.error,
        message: 'Upload failed before AI processing started.',
      ));
      return const UploadSheetUploadResult.error(
        'Upload failed before AI processing started.',
      );
    }

    return _waitForMaterialContentAndQuestions(
      moduleId: module.id,
      materialId: result.materialId,
      update: update,
    );
  }

  Future<UploadSheetUploadResult> _waitForMaterialContentAndQuestions({
    required int moduleId,
    required int materialId,
    required void Function(UploadSheetUploadUpdate update) update,
  }) async {
    final notifier = ref.read(courseDetailsControllerProvider(widget.course.id).notifier);
    final materialsApi = ref.read(materialsApiProvider);
    final questionsApi = ref.read(questionsApiProvider);

    update(const UploadSheetUploadUpdate(
      stage: UploadSheetProcessingStage.processing,
      message: 'AI is extracting the material topic tree...',
    ));

    bool contentStructureReady = false;
    try {
      final event = await materialsApi.waitForContentStructureGeneration(
        courseId: widget.course.id,
        materialId: materialId,
      );
      contentStructureReady = event.isReady;
    } catch (_) {
      contentStructureReady = false;
    }

    if (!contentStructureReady) {
      final fallbackReady = await _waitForMaterialReady(
        moduleId: moduleId,
        materialId: materialId,
        update: update,
      );
      if (fallbackReady != true) {
        return UploadSheetUploadResult.error(
          fallbackReady == false
              ? 'AI topic extraction returned an error. Check the material pipeline.'
              : 'AI topic extraction is taking too long. Refresh materials and try again.',
          materialId: materialId,
        );
      }
    }

    update(const UploadSheetUploadUpdate(
      stage: UploadSheetProcessingStage.processing,
      message: 'Topics received. Loading the material tree...',
    ));

    await notifier.loadMaterials(moduleId, force: true);
    await notifier.loadTopicsForMaterial(
      moduleId: moduleId,
      materialId: materialId,
      force: true,
    );

    if (!mounted) {
      return UploadSheetUploadResult.ready(
        materialId: materialId,
        message: 'Material saved. Topic extraction completed.',
      );
    }

    final controllerState = ref.read(courseDetailsControllerProvider(widget.course.id));
    final materialTopics = (controllerState.topics[moduleId] ?? const <TopicItem>[])
        .where((TopicItem topic) => topic.materialId == materialId)
        .toList(growable: false);
    final subtopicCount = materialTopics
        .where((TopicItem topic) => topic.parentTopicId != null)
        .length;

    if (materialTopics.isEmpty) {
      return UploadSheetUploadResult.ready(
        materialId: materialId,
        message: 'Material saved. The backend callback arrived, but no topics were returned yet.',
      );
    }

    update(UploadSheetUploadUpdate(
      stage: UploadSheetProcessingStage.processing,
      message: 'Topics received (${materialTopics.length}). Waiting for questions extracted from the material...',
    ));

    if (subtopicCount == 0) {
      return UploadSheetUploadResult.ready(
        materialId: materialId,
        message: 'Topic tree saved. No subtopics were available for material question extraction yet.',
      );
    }

    try {
      final extractResponse = await questionsApi.extractNativeQuestionsFromMaterial(
        courseId: widget.course.id,
        materialId: materialId,
      );
      if (!extractResponse.aiProcessingStarted) {
        return UploadSheetUploadResult.ready(
          materialId: materialId,
          message: extractResponse.message.trim().isNotEmpty
              ? extractResponse.message
              : 'Topic tree saved. Question extraction did not start yet.',
        );
      }
    } catch (e) {
      final message = mapApiFailure(e).message;
      return UploadSheetUploadResult.ready(
        materialId: materialId,
        message: 'Topic tree saved, but material question extraction could not start: $message',
      );
    }

    update(const UploadSheetUploadUpdate(
      stage: UploadSheetProcessingStage.processing,
      message: 'Question extraction request accepted. Waiting for the backend callback...',
    ));

    var nativeQuestionsReady = false;
    try {
      final event = await questionsApi.waitForNativeQuestionExtraction(
        courseId: widget.course.id,
        materialId: materialId,
      );
      nativeQuestionsReady = event.isReady;
    } catch (_) {
      nativeQuestionsReady = false;
    }

    if (!nativeQuestionsReady) {
      return UploadSheetUploadResult.ready(
        materialId: materialId,
        message: 'Topic tree saved. Question extraction is still running; refresh the question bank shortly.',
      );
    }

    update(const UploadSheetUploadUpdate(
      stage: UploadSheetProcessingStage.processing,
      message: 'Questions received. Refreshing the material question list...',
    ));

    var materialQuestionCount = 0;
    try {
      final questionResponse = await questionsApi.getMaterialQuestions(
        courseId: widget.course.id,
        moduleId: moduleId,
        materialId: materialId,
      );
      materialQuestionCount = questionResponse.questions.length;
      ref.read(questionBankRefreshSignalProvider(widget.course.id).notifier).state++;
    } catch (_) {
      ref.read(questionBankRefreshSignalProvider(widget.course.id).notifier).state++;
    }

    return UploadSheetUploadResult.ready(
      materialId: materialId,
      message: materialQuestionCount > 0
          ? 'Ready to save. Topics and $materialQuestionCount material question(s) were saved.'
          : 'Ready to save. Topics were saved; no material questions were returned yet.',
    );
  }

  Future<bool?> _waitForMaterialReady({
    required int moduleId,
    required int materialId,
    required void Function(UploadSheetUploadUpdate update) update,
  }) async {
    final notifier = ref.read(courseDetailsControllerProvider(widget.course.id).notifier);

    for (var attempt = 0; attempt < 60; attempt++) {
      if (!mounted) return null;
      await Future<void>.delayed(const Duration(seconds: 2));
      await notifier.loadMaterials(moduleId, force: true);
      final state = ref.read(courseDetailsControllerProvider(widget.course.id));
      final materials = state.materials[moduleId] ?? const <MaterialItem>[];
      MaterialItem? material;
      for (final item in materials) {
        if (item.id == materialId) {
          material = item;
          break;
        }
      }

      final status = material?.status.trim().toLowerCase();
      if (status == 'ready') {
        update(const UploadSheetUploadUpdate(
          stage: UploadSheetProcessingStage.ready,
          progress: 1,
          message: 'Ready to save. AI analysis completed.',
        ));
        return true;
      }
      if (status == 'error') {
        update(const UploadSheetUploadUpdate(
          stage: UploadSheetProcessingStage.error,
          message: 'AI processing failed for this file.',
        ));
        return false;
      }

      update(UploadSheetUploadUpdate(
        stage: UploadSheetProcessingStage.processing,
        message: status == null || status.isEmpty
            ? 'Waiting for AI processing status...'
            : 'AI processing: ${status.replaceAll('_', ' ')}...',
      ));
    }

    return null;
  }

  Future<void> _showShareModuleDialog(ModuleItem m) async {
    final targetCourse = await _showManagedDialog<MyCourseItem>(
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => _ShareModuleDialog(module: m, currentCourseId: widget.course.id),
    );
    if (targetCourse == null || !mounted) return;

    final copied = await ref
        .read(courseDetailsControllerProvider(widget.course.id).notifier)
        .copyModule(
          sourceCourseId: widget.course.id,
          moduleId: m.id,
          targetCourseId: targetCourse.id,
        );

    if (!mounted) return;
    if (copied != null) {
      AppToast.success(
        context,
        title: 'Module copied',
        message: '"${m.title}" has been copied to "${targetCourse.safeTitle}".',
      );
    } else {
      AppToast.error(context,
          title: 'Copy failed',
          message: 'Could not copy module. Please try again.',);
    }
  }

  Future<void> _showRenameDialog(ModuleItem m) async {
    final c = TextEditingController(text: m.title);
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => _SimpleDialog(
        title: 'Rename Module',
        ctrl: c,
        confirm: 'Save',
        confirmColor: AppColors.primary,
      ),
    );
    final title = c.text.trim();
    if (ok != true || !mounted || title.isEmpty || title == m.title) return;

    final updated = await ref.read(courseDetailsControllerProvider(widget.course.id).notifier)
        .updateModule(moduleId: m.id, title: title);
    if (!mounted) return;

    if (updated != null) {
      setState(() {
        if (_active?.type == _CType.module && _active?.module?.id == updated.id) {
          _sel = _Ctx.module(updated);
        }
      });
      AppToast.success(context, title: 'Module renamed', message: 'The module name was updated.');
    } else {
      AppToast.error(context, title: 'Rename failed', message: 'Please try again.');
    }
  }

  Future<void> _showEditDescriptionDialog(ModuleItem m) async {
    final c = TextEditingController(text: m.description ?? '');
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => _DescriptionDialog(ctrl: c),
    );
    final description = c.text.trim();
    final normalizedExisting = (m.description ?? '').trim();
    if (ok != true || !mounted || description == normalizedExisting) return;

    final updated = await ref.read(courseDetailsControllerProvider(widget.course.id).notifier)
        .updateModule(moduleId: m.id, description: description);
    if (!mounted) return;

    if (updated != null) {
      setState(() {
        if (_active?.type == _CType.module && _active?.module?.id == updated.id) {
          _sel = _Ctx.module(updated);
        }
      });
      AppToast.success(context, title: 'Description updated', message: 'Module description saved successfully.');
    } else {
      AppToast.error(context, title: 'Update failed', message: 'Please try again.');
    }
  }

  Future<void> _togglePublish(ModuleItem m) async {
    final updated = await ref.read(courseDetailsControllerProvider(widget.course.id).notifier)
        .updateModule(moduleId: m.id, isPublished: !m.isPublished);
    if (!mounted) return;

    if (updated != null) {
      setState(() {
        if (_active?.type == _CType.module && _active?.module?.id == updated.id) {
          _sel = _Ctx.module(updated);
        }
      });
      AppToast.success(
        context,
        title: updated.isPublished ? 'Module published' : 'Module unpublished',
        message: updated.isPublished ? 'The module is now visible to students.' : 'The module is now hidden from students.',
      );
    } else {
      AppToast.error(context, title: 'Update failed', message: 'Please try again.');
    }
  }

  Future<void> _showChangePositionDialog(ModuleItem m) async {
    final sortedModules = [...ref.read(courseDetailsControllerProvider(widget.course.id)).modules]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final selected = await _showManagedDialog<int>(
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => _ChangeModulePositionDialog(
        module: m,
        modules: sortedModules,
      ),
    );
    if (selected == null || !mounted) return;

    final success = await ref.read(courseDetailsControllerProvider(widget.course.id).notifier)
        .reorderModule(moduleId: m.id, newPosition: selected - 1);
    if (!mounted) return;

    if (success) {
      final refreshed = ref.read(courseDetailsControllerProvider(widget.course.id)).modules
          .firstWhere((module) => module.id == m.id, orElse: () => m);
      setState(() {
        if (_active?.type == _CType.module && _active?.module?.id == m.id) {
          _sel = _Ctx.module(refreshed);
        }
      });
      AppToast.success(context, title: 'Position updated', message: 'Module moved to #$selected.');
    } else {
      AppToast.error(context, title: 'Reorder failed', message: 'Please try again.');
    }
  }

  Future<void> _confirmDeleteMaterial(ModuleItem module, MaterialItem material) async {
    final ok = await _showManagedDialog<bool>(
          barrierColor: Colors.black.withValues(alpha: 0.35),
          builder: (_) => _ConfirmDialogWidget(
            title: 'Delete File',
            body: 'Delete "${material.title}"? This will remove the PDF and its generated topics.',
            confirm: 'Delete',
            confirmColor: AppColors.dangerText,
          ),
        ) ??
        false;
    if (!ok || !mounted) return;

    final success = await ref
        .read(courseDetailsControllerProvider(widget.course.id).notifier)
        .deleteMaterial(moduleId: module.id, materialId: material.id);
    if (!mounted) return;

    if (success) {
      final refreshedState =
          ref.read(courseDetailsControllerProvider(widget.course.id));
      final refreshedModule = refreshedState.modules.firstWhere(
        (item) => item.id == module.id,
        orElse: () => module,
      );
      setState(() {
        _sel = _Ctx.module(refreshedModule);
        _stack.clear();
        _hideFooterForActive = false;
        _persistUiState();
      });
      AppToast.success(
        context,
        title: 'File deleted',
        message: '"${material.title}" was removed from this module.',
      );
    } else {
      AppToast.error(
        context,
        title: 'Delete failed',
        message: 'Please try again.',
      );
    }
  }

  Future<void> _confirmDelete(ModuleItem m) async {
    final ok = await _showManagedDialog<bool>(
        barrierColor: Colors.black.withValues(alpha: 0.35),
        builder: (_) => _ConfirmDialogWidget(title: 'Delete Module',
            body: 'Delete "${m.title}"? This will also remove all its materials.',
            confirm: 'Delete', confirmColor: const Color(0xFFEF4444),),);
    if (ok != true || !mounted) return;

    final success = await ref.read(courseDetailsControllerProvider(widget.course.id).notifier)
        .deleteModule(m.id);
    if (!mounted) return;

    if (success) {
      setState(() {
        _expanded.remove(m.id);
        if (_active?.module?.id == m.id) {
          _sel = null;
          _stack.clear();
        }
      });
      AppToast.success(context, title: 'Module deleted', message: '"${m.title}" was removed.');
    } else {
      AppToast.error(context, title: 'Delete failed', message: 'Please try again.');
    }
  }

  Future<bool> _createManualTopicInline({
    required ModuleItem module,
    required MaterialItem material,
    required String title,
    String? description,
    List<int> learningOutcomeIds = const [],
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return false;

    final notifier = ref.read(courseDetailsControllerProvider(widget.course.id).notifier);
    final topic = await notifier.createTopic(
      moduleId: module.id,
      materialId: material.id,
      payload: TopicCreateRequest(
        title: trimmedTitle,
        description: description?.trim().isEmpty ?? false ? null : description?.trim(),
        learningOutcomeIds: learningOutcomeIds,
      ),
    );

    if (!mounted) return false;

    if (topic != null) {
      AppToast.success(
        context,
        title: 'Topic added',
        message: '"${topic.title}" was attached to this PDF.',
      );
      return true;
    }

    AppToast.error(
      context,
      title: 'Could not add topic',
      message: 'Please try again.',
    );
    return false;
  }

  Set<int> _leafTopicIdsForActive(_Ctx active, CourseDetailsState st) {
    switch (active.type) {
      case _CType.module:
        final ModuleItem? module = active.module;
        if (module == null) return const <int>{};
        return _selectableTopicIdsForModule(st, module.id);
      case _CType.material:
        final ModuleItem? module = active.module;
        final MaterialItem? material = active.material;
        if (module == null || material == null) return const <int>{};
        return _selectableTopicIdsForMaterial(st, module.id, material.id);
      case _CType.topic:
        final ModuleItem? module = active.module;
        final MaterialItem? material = active.material;
        final TopicItem? topic = active.topic;
        if (module == null || material == null || topic == null) return const <int>{};
        return _selectableTopicIdsForTopic(
          _topicsForMaterial(st, module.id, material.id),
          topic,
        );
    }
  }

  List<QuestionAuthoringTarget> _authoringTargetsForTopicIds(
    CourseDetailsState st,
    Set<int> topicIds,
  ) {
    if (topicIds.isEmpty) return const <QuestionAuthoringTarget>[];
    final List<QuestionAuthoringTarget> targets = <QuestionAuthoringTarget>[];

    for (final ModuleItem module in st.modules) {
      final List<TopicItem> moduleTopics = st.topics[module.id] ?? const <TopicItem>[];
      if (moduleTopics.isEmpty) continue;
      final List<MaterialItem> moduleMaterials = _materialsForModule(st, module.id);

      for (final TopicItem topic in moduleTopics) {
        if (!topicIds.contains(topic.id)) continue;
        MaterialItem? material;
        for (final MaterialItem item in moduleMaterials) {
          if (item.id == topic.materialId) {
            material = item;
            break;
          }
        }

        TopicItem? parent;
        if (topic.parentTopicId != null) {
          for (final TopicItem item in moduleTopics) {
            if (item.id == topic.parentTopicId && item.materialId == topic.materialId) {
              parent = item;
              break;
            }
          }
        }

        targets.add(
          QuestionAuthoringTarget(
            moduleId: module.id,
            moduleName: module.title,
            materialId: material?.id ?? topic.materialId,
            materialName: material?.displayTitle,
            topicId: topic.id,
            topicName: topic.title,
            isSubtopic: topic.parentTopicId != null,
            parentTopicName: parent?.title,
          ),
        );
      }
    }

    targets.sort((QuestionAuthoringTarget a, QuestionAuthoringTarget b) {
      final int moduleCompare = (a.moduleId ?? 0).compareTo(b.moduleId ?? 0);
      if (moduleCompare != 0) return moduleCompare;
      final int materialCompare = (a.materialId ?? 0).compareTo(b.materialId ?? 0);
      if (materialCompare != 0) return materialCompare;
      return a.topicId.compareTo(b.topicId);
    });
    return targets;
  }

  void _warmAuthoringTreeData(_Ctx active) {
    final ModuleItem? module = active.module;
    if (module == null) return;
    final notifier = ref.read(courseDetailsControllerProvider(widget.course.id).notifier);
    unawaited(notifier.loadMaterials(module.id));
    final int? materialId = active.material?.id;
    if (materialId != null) {
      unawaited(notifier.loadTopicsForMaterial(moduleId: module.id, materialId: materialId));
    }
  }

  void _openQuestionAuthoringFromSelection(_Ctx active) {
    final CourseDetailsState st = ref.read(
      courseDetailsControllerProvider(widget.course.id),
    );
    final bool hasTreeSelection = _selectionMode && !_treeSelection.isEmpty;
    final Set<int> topicIds = hasTreeSelection
        ? <int>{..._treeSelection.topicIds}
        : _leafTopicIdsForActive(active, st);

    final Set<int> moduleIds = hasTreeSelection
        ? <int>{..._treeSelection.moduleIds}
        : <int>{if (active.module != null) active.module!.id};

    final Set<int> materialIds = hasTreeSelection
        ? <int>{..._treeSelection.materialIds}
        : <int>{if (active.material != null) active.material!.id};

    final QuestionAuthoringLaunchContext launchContext =
        _buildAuthoringLaunchContext(
      active,
      st,
      hasTreeSelection: hasTreeSelection,
      resolvedModuleIds: moduleIds,
      resolvedMaterialIds: materialIds,
      resolvedTopicIds: topicIds,
    );

    if (moduleIds.isEmpty && materialIds.isEmpty && topicIds.isEmpty) {
      _openGenerateDialog(
        moduleId: active.module?.id,
        materialId: active.material?.id,
        topicId: active.topic?.id,
      );
      return;
    }

    if (topicIds.isEmpty) {
      _warmAuthoringTreeData(active);
    }

    setState(() {
      _authoringModuleIds = moduleIds;
      _authoringMaterialIds = materialIds;
      _authoringTopicIds = topicIds;
      _authoringLaunchContext = launchContext;
      _showQuestionAuthoring = true;
      _hideFooterForActive = true;
    });
    _persistUiState();
  }

  QuestionAuthoringLaunchContext _buildAuthoringLaunchContext(
    _Ctx active,
    CourseDetailsState st, {
    required bool hasTreeSelection,
    required Set<int> resolvedModuleIds,
    required Set<int> resolvedMaterialIds,
    required Set<int> resolvedTopicIds,
  }) {
    final List<QuestionAuthoringTarget> targetSnapshots =
        _authoringTargetsForTopicIds(st, resolvedTopicIds);
    if (!hasTreeSelection) {
      switch (active.type) {
        case _CType.module:
          final ModuleItem? module = active.module;
          return QuestionAuthoringLaunchContext(
            kind: QuestionAuthoringScopeKind.module,
            title: module?.title ?? 'Selected module',
            subtitle: 'Questions will be built from every topic and subtopic inside this module.',
            selectedModuleId: module?.id,
            selectedModuleIds: resolvedModuleIds.isNotEmpty
                ? resolvedModuleIds
                : <int>{if (module != null) module.id},
            selectedMaterialIds: resolvedMaterialIds,
            selectedTopicIds: resolvedTopicIds,
            targetSnapshots: targetSnapshots,
          );
        case _CType.material:
          final ModuleItem? module = active.module;
          final MaterialItem? material = active.material;
          return QuestionAuthoringLaunchContext(
            kind: QuestionAuthoringScopeKind.material,
            title: material?.displayTitle ?? 'Selected material',
            subtitle: module == null
                ? 'Questions will be built from this file structure.'
                : '${module.title} • questions will use this file topics and subtopics.',
            selectedModuleId: module?.id,
            selectedMaterialId: material?.id,
            selectedModuleIds: resolvedModuleIds.isNotEmpty
                ? resolvedModuleIds
                : <int>{if (module != null) module.id},
            selectedMaterialIds: resolvedMaterialIds.isNotEmpty
                ? resolvedMaterialIds
                : <int>{if (material != null) material.id},
            selectedTopicIds: resolvedTopicIds,
            targetSnapshots: targetSnapshots,
          );
        case _CType.topic:
          final ModuleItem? module = active.module;
          final MaterialItem? material = active.material;
          final TopicItem? topic = active.topic;
          final bool isSubtopic = topic?.parentTopicId != null;
          return QuestionAuthoringLaunchContext(
            kind: isSubtopic
                ? QuestionAuthoringScopeKind.subtopic
                : QuestionAuthoringScopeKind.topic,
            title: topic?.title ?? 'Selected topic',
            subtitle: isSubtopic
                ? 'Questions will target this specific subtopic.'
                : 'Questions will use this topic and its subtopics if they exist.',
            selectedModuleId: module?.id,
            selectedMaterialId: material?.id,
            selectedTopicId: topic?.id,
            selectedModuleIds: resolvedModuleIds.isNotEmpty
                ? resolvedModuleIds
                : <int>{if (module != null) module.id},
            selectedMaterialIds: resolvedMaterialIds.isNotEmpty
                ? resolvedMaterialIds
                : <int>{if (material != null) material.id},
            selectedTopicIds: resolvedTopicIds.isNotEmpty
                ? resolvedTopicIds
                : <int>{if (topic != null) topic.id},
            targetSnapshots: targetSnapshots,
          );
      }
    }

    final Set<int> containingModuleIds = <int>{};
    final Set<int> containingMaterialIds = <int>{};
    final Set<int> selectedTopicIds = <int>{...resolvedTopicIds};

    for (final ModuleItem module in st.modules) {
      final List<TopicItem> topics = st.topics[module.id] ?? const <TopicItem>[];
      for (final TopicItem topic in topics) {
        if (!selectedTopicIds.contains(topic.id)) continue;
        containingModuleIds.add(module.id);
        containingMaterialIds.add(topic.materialId);
      }
    }

    final Set<int> moduleIds = <int>{
      ...containingModuleIds,
      ...resolvedModuleIds,
      ..._treeSelection.moduleIds,
    };
    final Set<int> materialIds = <int>{
      ...containingMaterialIds,
      ...resolvedMaterialIds,
      ..._treeSelection.materialIds,
    };

    ModuleItem? selectedModule;
    MaterialItem? selectedMaterial;
    TopicItem? selectedTopic;

    if (_treeSelection.moduleIds.length == 1) {
      selectedModule = _findModuleById(st, _treeSelection.moduleIds.first);
    }
    if (_treeSelection.materialIds.length == 1) {
      selectedMaterial = _findMaterialById(st, _treeSelection.materialIds.first);
    }
    if (_treeSelection.topicIds.length == 1) {
      selectedTopic = _findTopicById(st, _treeSelection.topicIds.first);
      selectedMaterial ??= selectedTopic == null ? null : _findMaterialById(st, selectedTopic.materialId);
      selectedModule ??= selectedMaterial == null ? null : _findModuleById(st, selectedMaterial.moduleId);
    }

    if (selectedModule != null && _treeSelection.moduleIds.length == 1) {
      return QuestionAuthoringLaunchContext(
        kind: QuestionAuthoringScopeKind.module,
        title: selectedModule.title,
        subtitle: 'Full module selected from the structure tree.',
        selectedModuleId: selectedModule.id,
        selectedModuleIds: moduleIds,
        selectedMaterialIds: materialIds,
        selectedTopicIds: selectedTopicIds,
        targetSnapshots: targetSnapshots,
      );
    }

    if (selectedMaterial != null && _treeSelection.materialIds.length == 1) {
      return QuestionAuthoringLaunchContext(
        kind: QuestionAuthoringScopeKind.material,
        title: selectedMaterial.displayTitle,
        subtitle: 'Full material file selected from the structure tree.',
        selectedModuleId: selectedModule?.id ?? selectedMaterial.moduleId,
        selectedMaterialId: selectedMaterial.id,
        selectedModuleIds: moduleIds,
        selectedMaterialIds: materialIds,
        selectedTopicIds: selectedTopicIds,
        targetSnapshots: targetSnapshots,
      );
    }

    if (selectedTopic != null && _treeSelection.topicIds.length == 1) {
      final bool isSubtopic = selectedTopic.parentTopicId != null;
      return QuestionAuthoringLaunchContext(
        kind: isSubtopic
            ? QuestionAuthoringScopeKind.subtopic
            : QuestionAuthoringScopeKind.topic,
        title: selectedTopic.title,
        subtitle: isSubtopic
            ? 'One subtopic selected from the structure tree.'
            : 'One topic selected from the structure tree.',
        selectedModuleId: selectedModule?.id,
        selectedMaterialId: selectedMaterial?.id,
        selectedTopicId: selectedTopic.id,
        selectedModuleIds: moduleIds,
        selectedMaterialIds: materialIds,
        selectedTopicIds: selectedTopicIds,
        targetSnapshots: targetSnapshots,
      );
    }

    return QuestionAuthoringLaunchContext(
      kind: QuestionAuthoringScopeKind.selection,
      title: '${selectedTopicIds.length} selected content targets',
      subtitle: 'Custom selection across ${moduleIds.length} module${moduleIds.length == 1 ? '' : 's'} and ${materialIds.length} file${materialIds.length == 1 ? '' : 's'}.',
      selectedModuleIds: moduleIds,
      selectedMaterialIds: materialIds,
      selectedTopicIds: selectedTopicIds,
      targetSnapshots: targetSnapshots,
    );
  }

  ModuleItem? _findModuleById(CourseDetailsState st, int id) {
    for (final ModuleItem module in st.modules) {
      if (module.id == id) return module;
    }
    return null;
  }

  MaterialItem? _findMaterialById(CourseDetailsState st, int id) {
    for (final List<MaterialItem> materials in st.materials.values) {
      for (final MaterialItem material in materials) {
        if (material.id == id) return material;
      }
    }
    return null;
  }

  TopicItem? _findTopicById(CourseDetailsState st, int id) {
    for (final List<TopicItem> topics in st.topics.values) {
      for (final TopicItem topic in topics) {
        if (topic.id == id) return topic;
      }
    }
    return null;
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
    _persistUiState();
  }

  void _openQuestionBankAfterSave() {
    _closeQuestionAuthoring();
    if (!mounted) return;
    SelectedCourseCache.set(widget.course);
    context.go(Routes.courseQuestionBank(buildCourseRouteSlug(widget.course)));
  }

  void _openGenerateDialog({int? moduleId, int? materialId, int? topicId}) => _showManagedDialog(
      builder: (_) => GenerateQuestionsDialog(
        courseId: widget.course.id,
        initialModuleId: moduleId,
        initialMaterialId: materialId,
        initialTopicId: topicId,
      ),);
}

Color _criteriaDifficultyColor(OutcomeDifficulty level) {
  switch (level) {
    case OutcomeDifficulty.beginner:
      return const Color(0xFF16A34A);
    case OutcomeDifficulty.intermediate:
      return const Color(0xFFF59E0B);
    case OutcomeDifficulty.advanced:
      return const Color(0xFFDC2626);
  }
}

IconData _criteriaDifficultyIcon(OutcomeDifficulty level) {
  switch (level) {
    case OutcomeDifficulty.beginner:
      return Icons.eco_rounded;
    case OutcomeDifficulty.intermediate:
      return Icons.bolt_rounded;
    case OutcomeDifficulty.advanced:
      return Icons.local_fire_department_rounded;
  }
}

class _CriteriaIconDot extends StatelessWidget {
  final OutcomeDifficulty difficulty;
  const _CriteriaIconDot({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final color = _criteriaDifficultyColor(difficulty);
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Icon(_criteriaDifficultyIcon(difficulty), size: 14, color: color),
    );
  }
}

class _CriteriaMappingEmptyState extends StatelessWidget {
  const _CriteriaMappingEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.flag_outlined, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No Sub LOs yet. Create an LO from the Outcomes tab, then add Sub LOs under it.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.45, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _CriteriaMappingLoGroup extends StatelessWidget {
  final LearningOutcome parent;
  final List<LearningOutcome> criteria;
  final Set<int> selectedIds;
  final int? activeParentId;
  final ValueChanged<LearningOutcome> onToggle;

  const _CriteriaMappingLoGroup({
    required this.parent,
    required this.criteria,
    required this.selectedIds,
    required this.activeParentId,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final selectedCount = criteria.where((criterion) => selectedIds.contains(criterion.id)).length;
    final isActiveLo = activeParentId == parent.id;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActiveLo ? AppColors.badgeBlueBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.badgeBlueBorder)),
                  child: Text(parent.code, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppColors.primary)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(parent.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)),
                  child: Text(
                    selectedCount == 0
                        ? '${criteria.length} Sub LOs'
                        : '1 selected here',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: selectedCount == 0 ? AppColors.textMuted : AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          if (criteria.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text('No Sub LOs added under this LO yet.', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                children: [
                  for (final criterion in criteria) ...[
                    _CriteriaMappingTile(
                      criterion: criterion,
                      selected: selectedIds.contains(criterion.id),
                      onTap: () => onToggle(criterion),
                    ),
                    if (criterion != criteria.last) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _criterionShortCode(String code) {
  final trimmed = code.trim();
  final withoutWordPrefix = trimmed.replaceFirst(RegExp(r'^(Easy|Medium|Hard)', caseSensitive: false), '').trim();
  final withoutLetterPrefix = withoutWordPrefix.replaceFirst(RegExp(r'^[PMD](?=\d)', caseSensitive: false), '').trim();
  return withoutLetterPrefix.isEmpty ? trimmed : withoutLetterPrefix;
}

class _CriteriaMappingTile extends StatelessWidget {
  final LearningOutcome criterion;
  final bool selected;
  final VoidCallback onTap;

  const _CriteriaMappingTile({required this.criterion, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _criteriaDifficultyColor(criterion.difficulty);
    final description = (criterion.description ?? '').trim();
    return Material(
      color: selected ? color.withValues(alpha: 0.08) : AppColors.surfaceBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? color.withValues(alpha: 0.38) : AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? color : AppColors.cardBg,
                  border: Border.all(color: selected ? color : AppColors.border),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              _CriteriaIconDot(difficulty: criterion.difficulty),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withValues(alpha: 0.26))),
                child: Text(_criterionShortCode(criterion.code), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: color)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(criterion.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textTitle)),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    ],
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

// Question draft banner lives in materials_tab_question_draft_banner.dart.

// ─────────────────────────────────────────────────────────────────────────────
//  SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────
