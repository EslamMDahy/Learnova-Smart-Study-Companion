import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'student_courses_models.dart';
import 'student_courses_providers.dart';

class StudentExamHistoryData {
  final List<StudentCourse> courses;
  final List<StudentExamHistoryRow> rows;

  const StudentExamHistoryData({
    required this.courses,
    required this.rows,
  });

  int get totalAttempts => rows.length;

  int get pendingCount => rows.where((row) => row.isPending).length;

  int get retakeAvailableCount => rows.where((row) => row.canRetake).length;

  int get gradedCount => rows.where((row) => row.percentageScore != null).length;

  double? get averageScore {
    final graded = rows
        .map((row) => row.percentageScore)
        .whereType<double>()
        .toList(growable: false);
    if (graded.isEmpty) return null;
    final total = graded.fold<double>(0, (sum, score) => sum + score);
    return total / graded.length;
  }
}

class StudentExamHistoryRow {
  final StudentCourse course;
  final StudentCourseExam exam;
  final StudentExamAttemptSummary attempt;
  final int attemptsUsed;

  const StudentExamHistoryRow({
    required this.course,
    required this.exam,
    required this.attempt,
    required this.attemptsUsed,
  });

  int get courseId => course.id;
  int get examId => exam.id;
  int get attemptId => attempt.attemptId;

  DateTime? get displayDate => attempt.submittedAt ?? attempt.gradedAt ?? attempt.startedAt;

  Duration? get duration {
    final startedAt = attempt.startedAt;
    final submittedAt = attempt.submittedAt;
    if (startedAt == null || submittedAt == null) return null;
    final value = submittedAt.difference(startedAt);
    if (value.isNegative) return null;
    return value;
  }

  double? get percentageScore {
    if (attempt.percentageScore != null) return attempt.percentageScore;
    final earned = attempt.earnedScore;
    final total = attempt.totalScore;
    if (earned == null || total <= 0) return null;
    return (earned / total) * 100;
  }

  int get attemptsRemaining {
    final remaining = exam.maxAttempts - attemptsUsed;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isInProgress => attempt.isInProgress;

  bool get isPending {
    final status = attempt.status.trim().toLowerCase();
    return isInProgress ||
        status == 'pending' ||
        status == 'submitted' && percentageScore == null ||
        status == 'grading' ||
        status == 'grading_pending';
  }

  bool get isPassed => attempt.isPassed == true;

  bool get isFailed => attempt.isPassed == false;

  bool get canViewResult => attempt.hasResult && attemptId > 0;

  bool get canRetake => isFailed && exam.isAvailable && attemptsRemaining > 0;

  String get statusLabel {
    if (isInProgress) return 'In progress';
    if (isPending) return 'Pending';
    if (isPassed) return 'Passed';
    if (isFailed) return 'Failed';
    final raw = attempt.status.trim();
    if (raw.isEmpty) return 'Completed';
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }
}

final studentExamHistoryProvider = FutureProvider.autoDispose<StudentExamHistoryData>((ref) async {
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  final api = ref.read(studentCoursesApiProvider);
  final myCourses = await api.myCourses(cancelToken: cancelToken);
  final rows = <StudentExamHistoryRow>[];

  for (final course in myCourses.items) {
    if (course.id <= 0) continue;

    List<StudentCourseExam> exams;
    try {
      exams = await api.listStudentExams(
        courseId: course.id,
        cancelToken: cancelToken,
      );
    } catch (_) {
      // Keep the page usable if one course has a temporary exams failure.
      continue;
    }

    for (final exam in exams) {
      if (exam.id <= 0) continue;

      StudentExamAttemptsList attemptsPayload;
      try {
        attemptsPayload = await api.listStudentExamAttempts(
          courseId: course.id,
          examId: exam.id,
          cancelToken: cancelToken,
        );
      } catch (_) {
        continue;
      }

      for (final attempt in attemptsPayload.attempts) {
        rows.add(
          StudentExamHistoryRow(
            course: course,
            exam: exam,
            attempt: attempt,
            attemptsUsed: attemptsPayload.attempts.length,
          ),
        );
      }
    }
  }

  rows.sort((a, b) {
    final left = a.displayDate ?? DateTime.fromMillisecondsSinceEpoch(0);
    final right = b.displayDate ?? DateTime.fromMillisecondsSinceEpoch(0);
    return right.compareTo(left);
  });

  return StudentExamHistoryData(
    courses: myCourses.items,
    rows: rows,
  );
});
