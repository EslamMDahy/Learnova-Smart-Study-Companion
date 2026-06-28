part of 'materials_tab.dart';

class _K {
  _K._();
  static const amber      = Color(0xFFD97706);
  static const amberSoft  = Color(0xFFFFFBEB);
  static Color get green => AppColors.successText;
  static Color get greenSoft => AppColors.successBg;
  static const redSoft    = Color(0xFFFFF1F2);
  static Color get blueSoft => AppColors.primarySoft;
  static Color get blueMid => AppColors.badgeBlueBg;
  static const div        = Color(0xFFEEEEEE);
  static const bg         = Color(0xFFF6F7F9);
  static const sidebar    = Color(0xFFFAFAFA);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Context types
// ─────────────────────────────────────────────────────────────────────────────
enum _CType { module, material, topic }

class _Ctx {
  final _CType       type;
  final ModuleItem?  module;
  final MaterialItem? material;
  final TopicItem?   topic;
  const _Ctx._({required this.type, this.module, this.material, this.topic});
  factory _Ctx.module(ModuleItem m)                     => _Ctx._(type: _CType.module, module: m);
  factory _Ctx.material(ModuleItem m, MaterialItem mat) => _Ctx._(type: _CType.material, module: m, material: mat);
  factory _Ctx.topic(ModuleItem m, MaterialItem mat, TopicItem t) =>
      _Ctx._(type: _CType.topic, module: m, material: mat, topic: t);
}

// ─────────────────────────────────────────────────────────────────────────────
//  CourseMaterialsTab
// ─────────────────────────────────────────────────────────────────────────────


class _TreeSelectionState {
  final Set<int> moduleIds;
  final Set<int> materialIds;
  final Set<int> topicIds;

  const _TreeSelectionState({
    this.moduleIds = const <int>{},
    this.materialIds = const <int>{},
    this.topicIds = const <int>{},
  });

  static const empty = _TreeSelectionState();

  bool get isEmpty => topicIds.isEmpty;
  int get totalCount => topicIds.length;

  _TreeSelectionState copyWith({
    Set<int>? moduleIds,
    Set<int>? materialIds,
    Set<int>? topicIds,
  }) {
    return _TreeSelectionState(
      moduleIds: moduleIds ?? this.moduleIds,
      materialIds: materialIds ?? this.materialIds,
      topicIds: topicIds ?? this.topicIds,
    );
  }

  _TreeSelectionState clear() => empty;
}

class _QuestionDraftInfo {
  final int questionCount;
  final int targetCount;
  final Set<int> moduleIds;
  final Set<int> materialIds;
  final Set<int> topicIds;
  final QuestionAuthoringLaunchContext launchContext;

  const _QuestionDraftInfo({
    required this.questionCount,
    required this.targetCount,
    required this.moduleIds,
    required this.materialIds,
    required this.topicIds,
    required this.launchContext,
  });
}
