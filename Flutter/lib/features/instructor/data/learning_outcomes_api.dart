import 'dart:math' as math;

import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import 'learning_outcomes_cache.dart';
import 'learning_outcomes_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LearningOutcomesApi
//
//  FastAPI contract from domains/learningOutcomes:
//    GET    /courses/{course_id}/learning-outcomes
//    POST   /courses/{course_id}/learning-outcomes
//    GET    /courses/{course_id}/learning-outcomes/{id}
//    PATCH  /courses/{course_id}/learning-outcomes/{id}/update
//    DELETE /courses/{course_id}/learning-outcomes/{id}/delete
//
//  Important backend rules:
//    Parent LO: title, description?, level: null, no parent_learning_outcome_id
//    Sub LO:    title, description?, level: enum, parent_learning_outcome_id
//
//  The list endpoint omits parent_learning_outcome_id, so list items are
//  hydrated through GET /{id} before the UI uses the hierarchy.
// ─────────────────────────────────────────────────────────────────────────────

class LearningOutcomesApi {
  final ApiClient _client;
  LearningOutcomesApi(this._client);

  final Map<String, Future<LearningOutcome>> _inFlightCreates =
      <String, Future<LearningOutcome>>{};

  // ─── LIST ─────────────────────────────────────────────────────────────────
  Future<LearningOutcomeListResponse> listOutcomes({
    required int courseId,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _fetchOutcomesFromNetwork(
        courseId: courseId,
        cancelToken: cancelToken,
      );
    } catch (error) {
      if (_isCancelled(error)) rethrow;

      final cached = LearningOutcomesCache.load(courseId: courseId);
      if (cached.isNotEmpty) {
        return LearningOutcomeListResponse(
          courseId: courseId,
          outcomes: assignLearningOutcomeCodes(cached),
        );
      }

      // Last-resort fallback for old backend rows/list-shape mismatches.
      final recovered = await _recoverOutcomesByProbingIds(
        courseId: courseId,
        cancelToken: cancelToken,
      );
      if (recovered.isNotEmpty) {
        LearningOutcomesCache.save(courseId: courseId, outcomes: recovered);
        return LearningOutcomeListResponse(
          courseId: courseId,
          outcomes: assignLearningOutcomeCodes(recovered),
        );
      }

      rethrow;
    }
  }

  Future<LearningOutcomeListResponse> _fetchOutcomesFromNetwork({
    required int courseId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.learningOutcomes(courseId),
      cancelToken: cancelToken,
    );
    final data = res.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid response from GET learning-outcomes');
    }

    final parsed = LearningOutcomeListResponse.fromJson(data);
    final hydrated = await _hydrateListItems(
      courseId: courseId,
      parsed: parsed,
      cancelToken: cancelToken,
    );
    LearningOutcomesCache.save(courseId: courseId, outcomes: hydrated.outcomes);
    return hydrated;
  }

  Future<LearningOutcomeListResponse> _hydrateListItems({
    required int courseId,
    required LearningOutcomeListResponse parsed,
    CancelToken? cancelToken,
  }) async {
    if (parsed.outcomes.isEmpty) return parsed;

    // The backend list query does not return parent_learning_outcome_id. If the
    // frontend trusts that list directly, criteria are mistaken for parent LOs
    // and later creates can hit backend conflicts. Hydrate every item best-effort.
    final detailed = await Future.wait(
      parsed.outcomes.map(
        (outcome) => getOutcome(
          courseId: courseId,
          outcomeId: outcome.id,
          cancelToken: cancelToken,
        ).catchError((Object error, StackTrace stackTrace) {
          if (_isCancelled(error)) {
            Error.throwWithStackTrace(error, stackTrace);
          }
          return outcome;
        }),
      ),
    );

    return LearningOutcomeListResponse(
      courseId: parsed.courseId,
      outcomes: assignLearningOutcomeCodes(detailed),
    );
  }

  Future<List<LearningOutcome>> _recoverOutcomesByProbingIds({
    required int courseId,
    CancelToken? cancelToken,
  }) async {
    const maxProbeId = 300;
    const batchSize = 16;
    final recovered = <int, LearningOutcome>{};
    var highestRecoveredId = 0;

    for (var start = 1; start <= maxProbeId; start += batchSize) {
      if (cancelToken?.isCancelled == true) {
        throw DioException(
          requestOptions: RequestOptions(path: Endpoints.learningOutcomes(courseId)),
          type: DioExceptionType.cancel,
        );
      }

      final end = math.min(maxProbeId, start + batchSize - 1);
      final batch = await Future.wait<LearningOutcome?>(
        [
          for (var id = start; id <= end; id++)
            _tryGetOutcomeForRecovery(
              courseId: courseId,
              outcomeId: id,
              cancelToken: cancelToken,
            ),
        ],
      );

      for (final outcome in batch) {
        if (outcome == null) continue;
        if (outcome.courseId != null && outcome.courseId != courseId) continue;
        recovered[outcome.id] = outcome;
        highestRecoveredId = math.max(highestRecoveredId, outcome.id);
      }

      if (recovered.isNotEmpty && start > highestRecoveredId + 96) break;
    }

    return assignLearningOutcomeCodes(recovered.values.toList(growable: false));
  }

  Future<LearningOutcome?> _tryGetOutcomeForRecovery({
    required int courseId,
    required int outcomeId,
    CancelToken? cancelToken,
  }) async {
    try {
      final outcome = await getOutcome(
        courseId: courseId,
        outcomeId: outcomeId,
        cancelToken: cancelToken,
      );
      if (outcome.id <= 0 || outcome.title.trim().isEmpty) return null;
      return outcome;
    } catch (error) {
      if (_isCancelled(error)) rethrow;
      return null;
    }
  }

  bool _isCancelled(Object error) {
    return error is DioException && error.type == DioExceptionType.cancel;
  }

  bool _isConflict(Object error) {
    return error is DioException && error.response?.statusCode == 409;
  }

  // ─── CREATE ───────────────────────────────────────────────────────────────
  Future<LearningOutcome> createOutcome({
    required int courseId,
    required LearningOutcome outcome,
    List<int>? topicIds,
    CancelToken? cancelToken,
  }) async {
    final normalized = _normalizeOutcomeForCreate(outcome);
    final key = _createKey(courseId: courseId, outcome: normalized, topicIds: topicIds);

    final existingFlight = _inFlightCreates[key];
    if (existingFlight != null) return existingFlight;

    final future = _createOutcomeOnce(
      courseId: courseId,
      outcome: normalized,
      topicIds: topicIds,
      cancelToken: cancelToken,
    );

    _inFlightCreates[key] = future;
    try {
      return await future;
    } finally {
      _inFlightCreates.remove(key);
    }
  }

  Future<LearningOutcome> _createOutcomeOnce({
    required int courseId,
    required LearningOutcome outcome,
    List<int>? topicIds,
    CancelToken? cancelToken,
  }) async {
    final beforePost = await _findExistingTitleConflict(
      courseId: courseId,
      outcome: outcome,
      forceNetwork: true,
      cancelToken: cancelToken,
    );
    if (beforePost != null) {
      if (_isSameBackendSlot(beforePost, outcome)) return beforePost;
      throw LearningOutcomeTitleConflictException(
        attemptedTitle: outcome.title,
        existing: beforePost,
      );
    }

    try {
      final res = await _client.post<Map<String, dynamic>>(
        Endpoints.learningOutcomes(courseId),
        data: outcome.toCreateJson(topicIds: topicIds),
        cancelToken: cancelToken,
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final saved = LearningOutcome.fromJson(data);
        await _mergeSavedIntoCache(courseId: courseId, saved: saved);
        return saved;
      }
      throw const FormatException('Invalid response from POST learning-outcomes');
    } catch (error) {
      if (_isCancelled(error)) rethrow;

      // If the database rejects a duplicate title with 409, do not retry with a
      // different invalid payload. Re-read the backend and convert duplicate
      // creates into a deterministic frontend result.
      if (_isConflict(error)) {
        final afterConflict = await _findExistingTitleConflict(
          courseId: courseId,
          outcome: outcome,
          forceNetwork: true,
          cancelToken: cancelToken,
        );
        if (afterConflict != null) {
          if (_isSameBackendSlot(afterConflict, outcome)) return afterConflict;
          throw LearningOutcomeTitleConflictException(
            attemptedTitle: outcome.title,
            existing: afterConflict,
          );
        }
      }

      rethrow;
    }
  }

  LearningOutcome _normalizeOutcomeForCreate(LearningOutcome outcome) {
    final isSub = outcome.parentLearningOutcomeId != null;
    if (!isSub) {
      // Matches FastAPI: parent LO must include the required level key with a
      // JSON null value. Sending any enum value causes 422.
      return outcome.copyWith(level: null, parentLearningOutcomeId: null);
    }

    return outcome.copyWith(
      level: outcome.backendSafeLevel,
      parentLearningOutcomeId: outcome.parentLearningOutcomeId,
    );
  }

  Future<LearningOutcome?> _findExistingTitleConflict({
    required int courseId,
    required LearningOutcome outcome,
    bool forceNetwork = false,
    CancelToken? cancelToken,
  }) async {
    final candidateTitle = _norm(outcome.title);
    if (candidateTitle.isEmpty) return null;

    var existing = <LearningOutcome>[];
    if (!forceNetwork) {
      existing = LearningOutcomesCache.load(courseId: courseId);
    }

    if (existing.isEmpty || forceNetwork) {
      try {
        existing = (await _fetchOutcomesFromNetwork(
          courseId: courseId,
          cancelToken: cancelToken,
        ))
            .outcomes;
      } catch (error) {
        if (_isCancelled(error)) rethrow;
        if (existing.isEmpty) return null;
      }
    }

    for (final item in existing) {
      if (_norm(item.title) == candidateTitle) return item;
    }

    return null;
  }

  bool _isSameBackendSlot(LearningOutcome existing, LearningOutcome attempted) {
    if (existing.parentLearningOutcomeId != attempted.parentLearningOutcomeId) {
      return false;
    }

    if (attempted.parentLearningOutcomeId == null) return true;

    return existing.backendSafeLevel == attempted.backendSafeLevel;
  }

  Future<void> _mergeSavedIntoCache({
    required int courseId,
    required LearningOutcome saved,
  }) async {
    final current = LearningOutcomesCache.load(courseId: courseId);
    final withoutDuplicate = current.where((item) => item.id != saved.id).toList();
    LearningOutcomesCache.save(
      courseId: courseId,
      outcomes: assignLearningOutcomeCodes([...withoutDuplicate, saved]),
    );
  }

  String _createKey({
    required int courseId,
    required LearningOutcome outcome,
    List<int>? topicIds,
  }) {
    final topics = [...?topicIds]..sort();
    return [
      courseId,
      _norm(outcome.title),
      outcome.parentLearningOutcomeId ?? 'parent',
      outcome.parentLearningOutcomeId == null ? 'null' : outcome.backendSafeLevel,
      topics.join(','),
    ].join('|');
  }

  String _norm(String value) => value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  // ─── GET SINGLE ───────────────────────────────────────────────────────────
  Future<LearningOutcome> getOutcome({
    required int courseId,
    required int outcomeId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.getLearningOutcome(courseId, outcomeId),
      cancelToken: cancelToken,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return LearningOutcome.fromJson(data);
    throw const FormatException('Invalid response from GET learning-outcome/{id}');
  }

  // ─── UPDATE ───────────────────────────────────────────────────────────────
  Future<LearningOutcome> updateOutcome({
    required int courseId,
    required int outcomeId,
    required LearningOutcome outcome,
    List<int>? topicIds,
    CancelToken? cancelToken,
  }) async {
    final normalized = outcome.parentLearningOutcomeId == null
        ? outcome.copyWith(level: null)
        : outcome.copyWith(level: outcome.backendSafeLevel);

    final res = await _client.patch<Map<String, dynamic>>(
      Endpoints.updateLearningOutcome(courseId, outcomeId),
      data: normalized.toUpdateJson(topicIds: topicIds),
      cancelToken: cancelToken,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return LearningOutcome.fromJson(data);
    throw const FormatException('Invalid response from PATCH learning-outcome/{id}/update');
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────
  Future<void> deleteOutcome({
    required int courseId,
    required int outcomeId,
    CancelToken? cancelToken,
  }) async {
    await _client.delete<void>(
      Endpoints.deleteLearningOutcome(courseId, outcomeId),
      cancelToken: cancelToken,
    );
  }
}
