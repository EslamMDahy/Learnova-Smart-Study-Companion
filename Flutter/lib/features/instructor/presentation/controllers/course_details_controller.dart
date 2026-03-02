import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_error_bus.dart';
import '../../../../core/network/error_mapper.dart';

import '../../data/modules_models.dart';
import '../../data/materials_models.dart';
import '../../data/topics_models.dart';
import '../../data/question_models.dart';
import '../../data/modules_materials_providers.dart';

import 'course_details_state.dart';

final courseDetailsControllerProvider = StateNotifierProvider
    .family<CourseDetailsController, CourseDetailsState, int>(
  (ref, courseId) => CourseDetailsController(ref, courseId),
);

class CourseDetailsController extends StateNotifier<CourseDetailsState> {
  CourseDetailsController(this._ref, this._courseId)
      : super(const CourseDetailsState());

  final Ref _ref;
  final int _courseId;
  CancelToken? _cancel;

  // ── Modules ───────────────────────────────────────────────────────────────

  Future<void> loadModules({bool force = false}) async {
    if (state.modulesLoading) return;
    if (state.modules.isNotEmpty && !force) return;
    _cancel?.cancel();
    _cancel = CancelToken();

    state = state.copyWith(modulesLoading: true);

    try {
      final res = await _ref.read(modulesApiProvider).listModules(
            courseId: _courseId,
            cancelToken: _cancel,
          );
      state = state.copyWith(modulesLoading: false, modules: res.modules);
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) return;
      final failure = mapApiFailure(e);
      AppErrorReporter.report(_ref, failure);
      state = state.copyWith(modulesLoading: false, modulesError: failure.message);
    }
  }

  /// Loads modules then eagerly loads materials + topics for all modules so
  /// Overview statistics are immediately available.
  Future<void> loadModulesAndAllMaterials({bool force = false}) async {
    await loadModules(force: force);
    final futures = state.modules
        .where((m) => force || !state.materials.containsKey(m.id))
        .expand((m) => [loadMaterials(m.id), loadTopics(m.id)]);
    await Future.wait(futures);
  }

  Future<ModuleItem?> createModule(String title, {String? description}) async {
    try {
      final module = await _ref.read(modulesApiProvider).createModule(
            courseId: _courseId,
            payload: ModuleCreateRequest(title: title, description: description),
          );
      state = state.copyWith(modules: [...state.modules, module]);
      return module;
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(_ref, failure);
      return null;
    }
  }

  // ── Materials ─────────────────────────────────────────────────────────────

  Future<void> loadMaterials(int moduleId) async {
    if (state.materialsLoading[moduleId] ?? false) return;

    final newLoading = Map<int, bool>.from(state.materialsLoading)
      ..[moduleId] = true;
    state = state.copyWith(materialsLoading: newLoading);

    try {
      final res = await _ref.read(materialsApiProvider).listMaterials(
            courseId: _courseId,
            moduleId: moduleId,
          );
      final newMats = Map<int, List<MaterialItem>>.from(state.materials)
        ..[moduleId] = res.materials;
      final newLoad = Map<int, bool>.from(state.materialsLoading)
        ..[moduleId] = false;
      state = state.copyWith(materials: newMats, materialsLoading: newLoad);
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) return;
      final failure = mapApiFailure(e);
      AppErrorReporter.report(_ref, failure);
      final newLoad = Map<int, bool>.from(state.materialsLoading)
        ..[moduleId] = false;
      state = state.copyWith(materialsLoading: newLoad);
    }
  }

  // ── Topics ────────────────────────────────────────────────────────────────

  Future<void> loadTopics(int moduleId, {bool force = false}) async {
    if (state.topicsLoading[moduleId] ?? false) return;
    if (state.topics.containsKey(moduleId) && !force) return;

    final newLoading = Map<int, bool>.from(state.topicsLoading)
      ..[moduleId] = true;
    state = state.copyWith(topicsLoading: newLoading);

    try {
      final res = await _ref.read(topicsApiProvider).listTopics(
            courseId: _courseId,
            moduleId: moduleId,
          );
      final sorted = List<TopicItem>.from(res.topics)
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      final newTopics = Map<int, List<TopicItem>>.from(state.topics)
        ..[moduleId] = sorted;
      final newLoad = Map<int, bool>.from(state.topicsLoading)
        ..[moduleId] = false;
      state = state.copyWith(topics: newTopics, topicsLoading: newLoad);
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) return;
      // Non-fatal — topics may not be implemented yet on backend.
      final newLoad = Map<int, bool>.from(state.topicsLoading)
        ..[moduleId] = false;
      // Store empty list so we don't retry on every render.
      final newTopics = Map<int, List<TopicItem>>.from(state.topics)
        ..[moduleId] = [];
      state = state.copyWith(topicsLoading: newLoad, topics: newTopics);
    }
  }

  // ── Download URLs ─────────────────────────────────────────────────────────

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
      final url = await _ref.read(materialsApiProvider).getDownloadUrl(
            courseId: _courseId,
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

  // ── Upload ────────────────────────────────────────────────────────────────

  Future<bool> uploadMaterial({
    required int moduleId,
    required Uint8List bytes,
    required String filename,
    required String contentType,
    String? title,
  }) async {
    state = state.copyWith(uploading: true, uploadProgress: 0.0);

    try {
      final initResp = await _ref.read(materialsApiProvider).initUpload(
            courseId: _courseId,
            moduleId: moduleId,
            payload: MaterialInitUploadRequest(
              filename: filename,
              contentType: contentType,
              fileSizeBytes: bytes.length,
              title: title ?? filename,
            ),
          );

      state = state.copyWith(uploadProgress: 0.3);

      await _ref.read(materialsApiProvider).uploadToPresignedUrl(
            uploadUrl: initResp.uploadUrl,
            bytes: bytes,
            contentType: contentType,
            onSendProgress: (sent, total) {
              if (total <= 0) return;
              final p = (0.3 + (0.4 * sent / total)).clamp(0.0, 0.7);
              state = state.copyWith(uploadProgress: p);
            },
          );

      state = state.copyWith(uploadProgress: 0.7);

      await _ref.read(materialsApiProvider).confirmUpload(
            materialId: initResp.materialId,
          );

      state = state.copyWith(uploading: false, uploadProgress: 1.0);
      await loadMaterials(moduleId);
      return true;
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(_ref, failure);
      state = state.copyWith(uploading: false, uploadError: failure.message);
      return false;
    }
  }

  // ── Question Bank ─────────────────────────────────────────────────────────

  void addQuestion(QuestionModel question) {
    state = state.copyWith(questions: [question, ...state.questions]);
  }

  void deleteQuestion(String questionId) {
    state = state.copyWith(
      questions: state.questions.where((q) => q.id != questionId).toList(),
    );
  }

  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }
}
