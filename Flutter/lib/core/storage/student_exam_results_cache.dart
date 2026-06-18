import 'dart:convert';

import '../../features/student/data/student_courses_models.dart';
import 'key_value_store.dart';
import 'key_value_store_factory.dart';

/// Frontend-side cache for student exam summaries returned by the existing
/// backend submit endpoint.
///
/// The backend currently exposes:
/// - list published exams
/// - start/continue an attempt
/// - submit an attempt and receive the score summary
///
/// It does not expose a "latest result" endpoint. This cache keeps the latest
/// submitted result in the browser so the course exam overview can show the
/// last known result without calling a non-existing backend route.
class StudentExamResultsCache {
  StudentExamResultsCache._();

  static const _prefix = 'learnova_student_exam_result_';
  static final KeyValueStore _local = createLocalStore();

  static String _key({required int courseId, required int examId}) =>
      '$_prefix${courseId}_$examId';

  static StudentExamLatestResult? loadLatest({
    required int courseId,
    required int examId,
  }) {
    if (courseId <= 0 || examId <= 0) return null;

    final key = _key(courseId: courseId, examId: examId);
    final raw = _local.getString(key);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final json = Map<String, dynamic>.from(decoded);

      final cachedCourseId = _asInt(json['course_id']);
      final cachedExamId = _asInt(json['exam_id']);
      if (cachedCourseId != courseId || cachedExamId != examId) {
        return null;
      }

      return StudentExamLatestResult.fromJson(json);
    } catch (_) {
      _local.remove(key);
      return null;
    }
  }

  static void saveSubmittedResult({
    required int courseId,
    required StudentExamAttempt attempt,
    required StudentExamSubmitResult result,
    required int timeSpentSeconds,
    required int answeredCount,
  }) {
    if (courseId <= 0 || attempt.examId <= 0) return;

    final totalQuestions = attempt.totalQuestions > 0
        ? attempt.totalQuestions
        : attempt.questions.length;
    final sanitizedAnswered = answeredCount.clamp(0, totalQuestions).toInt();
    final unanswered = result.unansweredCount ??
        (totalQuestions - sanitizedAnswered).clamp(0, totalQuestions).toInt();
    final correct = result.correctCount ?? 0;
    final incorrect = result.incorrectCount ?? 0;
    final hasGradeSummary = result.percentageScore != null ||
        result.totalScore != null ||
        result.correctCount != null ||
        result.incorrectCount != null ||
        result.isPassed != null;
    final normalizedStatus = result.status.trim().toLowerCase();
    final gradingPending = normalizedStatus.contains('grading') ||
        normalizedStatus.contains('pending') ||
        (!hasGradeSummary &&
            normalizedStatus != 'graded' &&
            normalizedStatus != 'completed');

    final payload = <String, dynamic>{
      'course_id': courseId,
      'exam_id': attempt.examId,
      'title': attempt.title,
      'exam_type': attempt.examType,
      'has_attempt': true,
      'attempt_id': result.attemptId,
      'attempt_number': attempt.attemptNumber,
      'status': result.status,
      'started_at': attempt.startedAt?.toUtc().toIso8601String(),
      'submitted_at': result.submittedAt?.toUtc().toIso8601String() ??
          DateTime.now().toUtc().toIso8601String(),
      'time_spent_seconds': timeSpentSeconds,
      'score_earned': result.totalScore ?? 0,
      'total_score': attempt.totalScore,
      'percentage_score': result.percentageScore,
      'is_passed': result.isPassed,
      'grading_pending': gradingPending,
      'total_questions': totalQuestions,
      'correct_count': correct,
      'incorrect_count': incorrect,
      'unanswered_count': unanswered,
      'attempts_used': attempt.attemptNumber,
      'attempts_remaining': 0,
      'can_start': false,
      'questions': const <Map<String, dynamic>>[],
      'cached_at': DateTime.now().toUtc().toIso8601String(),
    }..removeWhere((_, value) => value == null);

    _local.setString(
      _key(courseId: courseId, examId: attempt.examId),
      jsonEncode(payload),
    );
  }

  static void clear({required int courseId, required int examId}) {
    if (courseId <= 0 || examId <= 0) return;
    _local.remove(_key(courseId: courseId, examId: examId));
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
