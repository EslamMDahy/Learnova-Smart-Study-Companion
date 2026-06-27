import 'dart:convert';

import '../../../core/storage/key_value_store.dart';
import '../../../core/storage/key_value_store_factory.dart';
import 'learning_outcomes_models.dart';

/// Persistent browser fallback for course learning outcomes.
///
/// The current backend can create parent LO rows with `level = null`, while the
/// list response model requires `level` to be a non-null string. When that
/// happens, GET /courses/{courseId}/learning-outcomes returns 500 before Flutter
/// receives any JSON. Keeping a local copy lets the UI continue to work after
/// successful create/update/delete calls.
class LearningOutcomesCache {
  LearningOutcomesCache._();

  static const _prefix = 'learnova_learning_outcomes_course_';
  static final KeyValueStore _local = createLocalStore();

  static String _key(int courseId) => '$_prefix$courseId';

  static List<LearningOutcome> load({required int courseId}) {
    if (courseId <= 0) return const <LearningOutcome>[];

    final raw = _local.getString(_key(courseId));
    if (raw == null || raw.trim().isEmpty) return const <LearningOutcome>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const <LearningOutcome>[];

      final cachedCourseId = _asInt(decoded['course_id']);
      if (cachedCourseId != 0 && cachedCourseId != courseId) {
        return const <LearningOutcome>[];
      }

      final rawOutcomes = decoded['learning_outcomes'];
      if (rawOutcomes is! List) return const <LearningOutcome>[];

      final outcomes = rawOutcomes
          .whereType<Map>()
          .map((item) => LearningOutcome.fromJson(Map<String, dynamic>.from(item)))
          .where((outcome) => outcome.id > 0 && outcome.title.trim().isNotEmpty)
          .toList(growable: false);

      return assignLearningOutcomeCodes(outcomes);
    } catch (_) {
      _local.remove(_key(courseId));
      return const <LearningOutcome>[];
    }
  }

  static void save({
    required int courseId,
    required List<LearningOutcome> outcomes,
  }) {
    if (courseId <= 0) return;

    final payload = <String, dynamic>{
      'course_id': courseId,
      'learning_outcomes': assignLearningOutcomeCodes(outcomes)
          .map((outcome) => outcome.copyWith(courseId: outcome.courseId ?? courseId).toJson())
          .toList(growable: false),
      'cached_at': DateTime.now().toUtc().toIso8601String(),
    };

    _local.setString(_key(courseId), jsonEncode(payload));
  }

  static void clear({required int courseId}) {
    if (courseId <= 0) return;
    _local.remove(_key(courseId));
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
