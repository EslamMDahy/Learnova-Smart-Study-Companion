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
  Future<void> loadTopics(
    int moduleId, {
    bool force = false,
    bool hydrateDetails = true,
  }) async {
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
        hydrateDetails: hydrateDetails,
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
    bool hydrateDetails = true,
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
      final previousById = <int, TopicItem>{
        for (final TopicItem topic in state.topics[moduleId] ?? const <TopicItem>[])
          if (topic.materialId == materialId) topic.id: topic,
      };

      final listedTopics = res.topics
          .map(
            (topic) => _mergeTopicDetails(
              moduleId: moduleId,
              materialId: materialId,
              base: topic,
              previous: previousById[topic.id],
            ),
          )
          .toList(growable: false);
      final detailedTopics = hydrateDetails
          ? await _hydrateListedTopicDetails(
              moduleId: moduleId,
              materialId: materialId,
              topics: listedTopics,
            )
          : listedTopics;

      final mergedTopics = <TopicItem>[
        for (final TopicItem topic in state.topics[moduleId] ?? const <TopicItem>[])
          if (topic.materialId != materialId) topic,
        ...detailedTopics,
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


  Future<List<TopicItem>> _hydrateListedTopicDetails({
    required int moduleId,
    required int materialId,
    required List<TopicItem> topics,
  }) async {
    if (topics.isEmpty) return const <TopicItem>[];

    final previousById = <int, TopicItem>{
      for (final TopicItem topic in state.topics[moduleId] ?? const <TopicItem>[])
        if (topic.materialId == materialId) topic.id: topic,
    };
    final api = ref.read(topicsApiProvider);

    final hydrated = await Future.wait(topics.map((topic) async {
      final previous = previousById[topic.id];
      final normalized = _mergeTopicDetails(
        moduleId: moduleId,
        materialId: materialId,
        base: topic,
        previous: previous,
      );

      // The backend list endpoint is intentionally light and can omit
      // page_start/page_end and learning_outcomes. Hydrate every topic once
      // when a material opens so Sub LO mappings are visible without refresh.
      try {
        final detail = await api.getTopic(
          courseId: courseId,
          moduleId: moduleId,
          materialId: materialId,
          topicId: topic.id,
        );
        return _mergeTopicDetails(
          moduleId: moduleId,
          materialId: materialId,
          base: detail.topic,
          previous: normalized,
        );
      } catch (_) {
        return normalized;
      }
    }));

    return hydrated;
  }

  TopicItem _mergeTopicDetails({
    required int moduleId,
    required int materialId,
    required TopicItem base,
    TopicItem? previous,
  }) {
    final outcomeIds = base.learningOutcomeIds.isNotEmpty
        ? base.learningOutcomeIds
        : (previous?.learningOutcomeIds ?? const <int>[]);
    final outcomeStringIds = base.linkedOutcomeIds.isNotEmpty
        ? base.linkedOutcomeIds
        : (previous?.linkedOutcomeIds ?? outcomeIds.map((id) => id.toString()).toList());

    return base.copyWith(
      moduleId: moduleId,
      materialId: materialId,
      pageStart: base.pageStart ?? previous?.pageStart,
      pageEnd: base.pageEnd ?? previous?.pageEnd,
      source: previous?.source ?? base.source,
      difficulty: previous?.difficulty ?? base.difficulty,
      readiness: base.isReviewed
          ? TopicReadiness.ready
          : (previous?.readiness ?? base.readiness),
      linkedOutcomeId: base.linkedOutcomeId ?? previous?.linkedOutcomeId,
      linkedOutcomeIds: outcomeStringIds,
      learningOutcomeIds: outcomeIds,
      instructorNotes: previous?.instructorNotes,
      estimatedDurationMinutes: previous?.estimatedDurationMinutes,
      isRequired: previous?.isRequired ?? base.isRequired,
    );
  }

  Future<TopicItem?> loadTopicDetails({
    required int moduleId,
    required int materialId,
    required int topicId,
  }) async {
    try {
      final res = await ref.read(topicsApiProvider).getTopic(
            courseId: courseId,
            moduleId: moduleId,
            materialId: materialId,
            topicId: topicId,
          );

      final existing = List<TopicItem>.from(state.topics[moduleId] ?? const []);
      final idx = existing.indexWhere((topic) => topic.id == topicId);
      final previous = idx >= 0 ? existing[idx] : null;
      final loaded = _mergeTopicDetails(
        moduleId: moduleId,
        materialId: materialId,
        base: res.topic,
        previous: previous,
      );

      if (idx >= 0) {
        existing[idx] = loaded;
      } else {
        existing.add(loaded);
      }
      existing.sort((a, b) {
        final materialCmp = a.materialId.compareTo(b.materialId);
        if (materialCmp != 0) return materialCmp;
        return a.orderIndex.compareTo(b.orderIndex);
      });

      final newTopics = Map<int, List<TopicItem>>.from(state.topics)
        ..[moduleId] = existing;
      state = state.copyWith(topics: newTopics);
      return loaded;
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(ref, failure);
      return null;
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
      final normalizedOutcomeIds = requestedOutcomeIds.toSet().toList()..sort();
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
