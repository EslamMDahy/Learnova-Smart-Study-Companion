part of 'course_details_controller.dart';



mixin _CourseDetailsTopicsMixin on StateNotifier<CourseDetailsState> {
  Ref get ref;
  int get courseId;
  Future<void> loadMaterials(int moduleId, {bool force = false});
// ── Topics ──────────────────────────────────────────────────────────────

  bool topicsForMaterialLoaded(int materialId) {
    return state.topicsLoadedMaterialIds.contains(materialId);
  }

  /// Eager loader kept for flows that truly need the whole module tree.
  /// Materials page interactions should prefer [loadTopicsForMaterial].
  Future<void> loadTopics(int moduleId, {bool force = false}) async {
    if (state.topicsLoading[moduleId] ?? false) return;

    if ((state.materials[moduleId] ?? const <MaterialItem>[]).isEmpty) {
      await loadMaterials(moduleId, force: force);
    }
    final materials = state.materials[moduleId] ?? const <MaterialItem>[];
    if (materials.isEmpty) {
      final newTopics = Map<int, List<TopicItem>>.from(state.topics)
        ..[moduleId] = const <TopicItem>[];
      state = state.copyWith(topics: newTopics);
      return;
    }

    final materialIds = materials.map((MaterialItem material) => material.id).toSet();
    if (!force && materialIds.every(state.topicsLoadedMaterialIds.contains)) {
      return;
    }

    for (final MaterialItem material in materials) {
      await loadTopicsForMaterial(
        moduleId: moduleId,
        materialId: material.id,
        force: force,
      );
    }
  }

  /// Lazy topic loader for one material/file.
  ///
  /// This prevents opening or refreshing the Materials tab from firing
  /// `/topics` requests for every uploaded file in the module. The UI calls
  /// this only when a material is opened, or when a specific material has to be
  /// restored after refresh.
  Future<void> loadTopicsForMaterial({
    required int moduleId,
    required int materialId,
    bool force = false,
  }) async {
    if (state.topicsLoading[moduleId] ?? false) return;
    if (!force && state.topicsLoadedMaterialIds.contains(materialId)) return;

    final newLoading = Map<int, bool>.from(state.topicsLoading)
      ..[moduleId] = true;
    state = state.copyWith(topicsLoading: newLoading);

    try {
      final res = await ref.read(topicsApiProvider).listTopics(
            courseId: courseId,
            moduleId: moduleId,
            materialId: materialId,
          );

      final mergedTopics = <TopicItem>[
        for (final TopicItem topic in state.topics[moduleId] ?? const <TopicItem>[])
          if (topic.materialId != materialId) topic,
        ...res.topics,
      ]..sort((a, b) {
          final materialCmp = a.materialId.compareTo(b.materialId);
          if (materialCmp != 0) return materialCmp;
          return a.orderIndex.compareTo(b.orderIndex);
        });

      final newTopics = Map<int, List<TopicItem>>.from(state.topics)
        ..[moduleId] = mergedTopics;
      final newLoad = Map<int, bool>.from(state.topicsLoading)
        ..[moduleId] = false;
      final loadedMaterialIds = <int>{...state.topicsLoadedMaterialIds, materialId};
      state = state.copyWith(
        topicsLoading: newLoad,
        topics: newTopics,
        topicsLoadedMaterialIds: loadedMaterialIds,
      );
      return;
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(ref, failure);
      final newLoad = Map<int, bool>.from(state.topicsLoading)
        ..[moduleId] = false;
      state = state.copyWith(topicsLoading: newLoad);
      return;
    }
  }

  Future<TopicItem?> createTopic({
    required int moduleId,
    required int materialId,
    required TopicCreateRequest payload,
  }) async {
    try {
      final created = await ref.read(topicsApiProvider).createTopic(
            courseId:   courseId,
            moduleId:   moduleId,
            materialId: materialId,
            payload:    payload,
          );
      final requestedOutcomeIds = payload.learningOutcomeIds.isNotEmpty
          ? payload.learningOutcomeIds
          : payload.linkedOutcomeIds
              .map((s) => int.tryParse(s))
              .whereType<int>()
              .toList();
      final normalizedOutcomeIds = requestedOutcomeIds.isEmpty
          ? const <int>[]
          : <int>[requestedOutcomeIds.first];
      final topic = created.copyWith(
        moduleId: moduleId,
        materialId: materialId,
        parentTopicId: payload.parentTopicId ?? created.parentTopicId,
        learningOutcomeIds: normalizedOutcomeIds,
        linkedOutcomeId: normalizedOutcomeIds.isEmpty ? null : normalizedOutcomeIds.first.toString(),
        linkedOutcomeIds: normalizedOutcomeIds.map((id) => id.toString()).toList(),
      );
      final existing = List<TopicItem>.from(state.topics[moduleId] ?? []);
      existing.add(topic);
      existing.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      final newTopics = Map<int, List<TopicItem>>.from(state.topics)
        ..[moduleId] = existing;
      state = state.copyWith(
        topics: newTopics,
        topicsLoadedMaterialIds: <int>{...state.topicsLoadedMaterialIds, materialId},
      );
      return topic;
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(ref, failure);
      return null;
    }
  }

  Future<void> updateTopic(TopicItem topic) async {
    try {
      final updated = await ref.read(topicsApiProvider).updateTopic(
            courseId:   courseId,
            moduleId:   topic.moduleId,
            materialId: topic.materialId,
            topicId:    topic.id,
            payload:    TopicUpdateRequest(
              title:              topic.title,
              description:        topic.description,
              parentTopicId:      topic.parentTopicId,
              learningOutcomeIds: topic.learningOutcomeIds.isNotEmpty
                  ? topic.learningOutcomeIds
                  : topic.linkedOutcomeIds
                      .map((s) => int.tryParse(s))
                      .whereType<int>()
                      .toList(),
            ),
          );
      final mergedUpdated = updated.copyWith(
        moduleId: topic.moduleId,
        materialId: topic.materialId,
        difficulty: topic.difficulty,
        readiness: topic.readiness,
        linkedOutcomeId: topic.linkedOutcomeId,
        linkedOutcomeIds: topic.linkedOutcomeIds,
        learningOutcomeIds: topic.learningOutcomeIds,
        parentTopicId: topic.parentTopicId,
        instructorNotes: topic.instructorNotes,
        estimatedDurationMinutes: topic.estimatedDurationMinutes,
        isRequired: topic.isRequired,
        source: topic.source,
      );
      final existing = List<TopicItem>.from(state.topics[topic.moduleId] ?? const []);
      final idx = existing.indexWhere((t) => t.id == topic.id);
      if (idx >= 0) {
        existing[idx] = mergedUpdated;
      } else {
        existing.add(mergedUpdated);
      }
      final newTopics = Map<int, List<TopicItem>>.from(state.topics)
        ..[topic.moduleId] = existing;
      state = state.copyWith(topics: newTopics);
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(ref, failure);
    }
  }

  Future<void> deleteTopic({
    required int moduleId,
    required int topicId,
    required int materialId,
  }) async {
    if (materialId <= 0) {
      throw ArgumentError.value(materialId, 'materialId', 'materialId is required for deleting a topic');
    }

    try {
      await ref.read(topicsApiProvider).deleteTopic(
            courseId: courseId,
            moduleId: moduleId,
            materialId: materialId,
            topicId: topicId,
          );
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(ref, failure);
      return;
    }
    final existing = List<TopicItem>.from(state.topics[moduleId] ?? const []);
    final newTopics = Map<int, List<TopicItem>>.from(state.topics)
      ..[moduleId] = existing.where((t) => t.id != topicId).toList();
    state = state.copyWith(topics: newTopics);
  }

  
}
