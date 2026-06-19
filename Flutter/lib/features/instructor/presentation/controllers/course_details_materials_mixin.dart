part of 'course_details_controller.dart';




mixin _CourseDetailsMaterialsMixin on StateNotifier<CourseDetailsState> {
  Ref get ref;
  int get courseId;
// ── Materials ─────────────────────────────────────────────────────────────

  Future<void> loadMaterials(int moduleId, {bool force = false}) async {
    if (state.materialsLoading[moduleId] ?? false) return;
    if (state.materials.containsKey(moduleId) && !force) return;

    final newLoading = Map<int, bool>.from(state.materialsLoading)
      ..[moduleId] = true;
    state = state.copyWith(materialsLoading: newLoading);

    try {
      final res = await ref.read(materialsApiProvider).listMaterials(
            courseId: courseId,
            moduleId: moduleId,
          );
      final previousMaterialIds = state.materials[moduleId]
              ?.map((MaterialItem material) => material.id)
              .toSet() ??
          const <int>{};
      final newMats = Map<int, List<MaterialItem>>.from(state.materials)
        ..[moduleId] = res.materials;
      final newLoad = Map<int, bool>.from(state.materialsLoading)
        ..[moduleId] = false;
      final loadedTopicMaterialIds = force
          ? (<int>{...state.topicsLoadedMaterialIds}..removeAll(previousMaterialIds))
          : state.topicsLoadedMaterialIds;
      state = state.copyWith(
        materials: newMats,
        materialsLoading: newLoad,
        topicsLoadedMaterialIds: loadedTopicMaterialIds,
      );
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) return;
      final failure = mapApiFailure(e);
      AppErrorReporter.report(ref, failure);
      final newLoad = Map<int, bool>.from(state.materialsLoading)
        ..[moduleId] = false;
      state = state.copyWith(materialsLoading: newLoad);
    }
  }

  
// ── Download URLs ───────────────────────────────────────────────────────────

  /// Fetches (or returns cached) a fresh signed download URL for a material.
  Future<String?> fetchDownloadUrl({
    required int moduleId,
    required int materialId,
    bool force = false,
  }) async {
    if (!force && state.downloadUrls.containsKey(materialId)) {
      return state.downloadUrls[materialId];
    }
    if (state.downloadUrlLoading[materialId] ?? false) return null;

    final loadingMap = Map<int, bool>.from(state.downloadUrlLoading)
      ..[materialId] = true;
    state = state.copyWith(downloadUrlLoading: loadingMap);

    try {
      final url = await ref.read(materialsApiProvider).getDownloadUrl(
            courseId: courseId,
            moduleId: moduleId,
            materialId: materialId,
          );
      final urlMap = Map<int, String>.from(state.downloadUrls);
      if (url != null) urlMap[materialId] = url;
      final doneLoading = Map<int, bool>.from(state.downloadUrlLoading)
        ..[materialId] = false;
      state = state.copyWith(downloadUrls: urlMap, downloadUrlLoading: doneLoading);
      return url;
    } catch (_) {
      final doneLoading = Map<int, bool>.from(state.downloadUrlLoading)
        ..[materialId] = false;
      state = state.copyWith(downloadUrlLoading: doneLoading);
      return null;
    }
  }



  Future<bool> deleteMaterial({
    required int moduleId,
    required int materialId,
  }) async {
    try {
      await ref.read(materialsApiProvider).deleteMaterial(
            courseId: courseId,
            moduleId: moduleId,
            materialId: materialId,
          );

      final nextMaterials = Map<int, List<MaterialItem>>.from(state.materials);
      final current = nextMaterials[moduleId] ?? const <MaterialItem>[];
      nextMaterials[moduleId] = current
          .where((material) => material.id != materialId)
          .toList(growable: false);

      final nextTopics = Map<int, List<TopicItem>>.from(state.topics);
      final currentTopics = nextTopics[moduleId] ?? const <TopicItem>[];
      nextTopics[moduleId] = currentTopics
          .where((topic) => topic.materialId != materialId)
          .toList(growable: false);

      final nextLoadedTopicIds = <int>{...state.topicsLoadedMaterialIds}
        ..remove(materialId);
      final nextDownloadUrls = Map<int, String>.from(state.downloadUrls)
        ..remove(materialId);
      final nextDownloadLoading = Map<int, bool>.from(state.downloadUrlLoading)
        ..remove(materialId);

      state = state.copyWith(
        materials: nextMaterials,
        topics: nextTopics,
        topicsLoadedMaterialIds: nextLoadedTopicIds,
        downloadUrls: nextDownloadUrls,
        downloadUrlLoading: nextDownloadLoading,
      );
      return true;
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(ref, failure);
      return false;
    }
  }

  // ── Upload ──────────────────────────────────────────────────────────────

  Future<bool> uploadMaterial({
    required int moduleId,
    required Uint8List bytes,
    required String filename,
    required String contentType,
    String? title,
  }) async {
    final result = await uploadMaterialFlow(
      moduleId: moduleId,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      title: title,
    );
    return result != null;
  }

  Future<MaterialUploadFlowResult?> uploadMaterialFlow({
    required int moduleId,
    required Uint8List bytes,
    required String filename,
    required String contentType,
    String? title,
    void Function(double progress)? onUploadProgress,
  }) async {
    state = state.copyWith(uploading: true, uploadProgress: 0.0, uploadError: null);
    onUploadProgress?.call(0.0);

    try {
      final initResp = await ref.read(materialsApiProvider).initUpload(
            courseId: courseId,
            moduleId: moduleId,
            payload: MaterialInitUploadRequest(
              filename: filename,
              contentType: contentType,
              fileSizeBytes: bytes.length,
              title: title ?? filename,
            ),
          );

      state = state.copyWith(uploadProgress: 0.3);
      onUploadProgress?.call(0.3);

      await ref.read(materialsApiProvider).uploadToPresignedUrl(
            uploadUrl: initResp.uploadUrl,
            bytes: bytes,
            contentType: contentType,
            onSendProgress: (sent, total) {
              if (total <= 0) return;
              final p = (0.3 + (0.4 * sent / total)).clamp(0.0, 0.7).toDouble();
              state = state.copyWith(uploadProgress: p);
              onUploadProgress?.call(p);
            },
          );

      state = state.copyWith(uploadProgress: 0.7);
      onUploadProgress?.call(0.7);

      final confirm = await ref.read(materialsApiProvider).confirmUpload(
            materialId: initResp.materialId,
          );

      state = state.copyWith(uploading: false, uploadProgress: 1.0);
      onUploadProgress?.call(1.0);
      await loadMaterials(moduleId, force: true);
      return MaterialUploadFlowResult.fromConfirm(confirm);
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(ref, failure);
      state = state.copyWith(uploading: false, uploadError: failure.message);
      return null;
    }
  }

  
}
