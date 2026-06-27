import 'dart:math' as math;

import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import 'learning_outcomes_cache.dart';
import 'learning_outcomes_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LearningOutcomesApi
//
//  Wires all 5 LO endpoints:
//    GET    /courses/{course_id}/learning-outcomes              → list
//    POST   /courses/{course_id}/learning-outcomes              → create
//    GET    /courses/{course_id}/learning-outcomes/{id}         → get single
//    PATCH  /courses/{course_id}/learning-outcomes/{id}/update  → update
//    DELETE /courses/{course_id}/learning-outcomes/{id}/delete  → delete
// ─────────────────────────────────────────────────────────────────────────────

class LearningOutcomesApi {
  final ApiClient _client;
  LearningOutcomesApi(this._client);

  // ─── LIST ─────────────────────────────────────────────────────────────────
  Future<LearningOutcomeListResponse> listOutcomes({
    required int courseId,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await _client.get<Map<String, dynamic>>(
        Endpoints.learningOutcomes(courseId),
        cancelToken: cancelToken,
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid response from GET learning-outcomes');
      }

      final parsed = LearningOutcomeListResponse.fromJson(data);
      final hydrated = await _hydrateListItemsIfNeeded(
        courseId: courseId,
        parsed: parsed,
        cancelToken: cancelToken,
      );
      LearningOutcomesCache.save(courseId: courseId, outcomes: hydrated.outcomes);
      return hydrated;
    } catch (error) {
      if (_isCancelled(error)) rethrow;

      final cached = LearningOutcomesCache.load(courseId: courseId);
      if (cached.isNotEmpty) {
        return LearningOutcomeListResponse(courseId: courseId, outcomes: cached);
      }

      // Backend-only inconsistency fallback:
      // list can 500 because parent rows have level=null, but GET by id accepts
      // Optional level and returns parent_learning_outcome_id. With no backend
      // changes available, recover existing rows by probing individual ids.
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

  Future<LearningOutcomeListResponse> _hydrateListItemsIfNeeded({
    required int courseId,
    required LearningOutcomeListResponse parsed,
    CancelToken? cancelToken,
  }) async {
    // The uploaded backend list query does not include
    // parent_learning_outcome_id. When rows have level values, hydrate details
    // best-effort so the UI can rebuild parent → difficulty → criterion lanes.
    final needsHydration = parsed.outcomes.any(
      (outcome) => outcome.level != null && outcome.parentLearningOutcomeId == null,
    );
    if (!needsHydration || parsed.outcomes.isEmpty) return parsed;

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

      // Once we found rows for this course, keep probing a little further for
      // siblings/criteria, then stop to avoid hammering the backend.
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

  // ─── CREATE ───────────────────────────────────────────────────────────────
  Future<LearningOutcome> createOutcome({
    required int courseId,
    required LearningOutcome outcome,
    List<int>? topicIds,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.learningOutcomes(courseId),
      data: outcome.toCreateJson(topicIds: topicIds),
      cancelToken: cancelToken,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return LearningOutcome.fromJson(data);
    throw const FormatException('Invalid response from POST learning-outcomes');
  }

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
    final res = await _client.patch<Map<String, dynamic>>(
      Endpoints.updateLearningOutcome(courseId, outcomeId),
      data: outcome.toUpdateJson(topicIds: topicIds),
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
