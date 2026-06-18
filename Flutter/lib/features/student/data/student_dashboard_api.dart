import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import 'student_dashboard_models.dart';

class StudentDashboardApi {
  final ApiClient _client;

  const StudentDashboardApi(this._client);

  Future<StudentDashboardData> loadDashboard({CancelToken? cancelToken}) async {
    final courses = await _loadMyCourses(cancelToken: cancelToken);
    final exams = <StudentDashboardExam>[];
    var failedLoads = 0;

    for (final course in courses) {
      try {
        exams.addAll(
          await _loadCourseExams(course, cancelToken: cancelToken),
        );
      } catch (_) {
        // Some courses can be pending/suspended or the backend can reject an
        // empty exam window. Dashboard should still render the enrolled courses.
        failedLoads++;
      }
    }

    return StudentDashboardData(
      courses: courses,
      exams: exams,
      failedExamCourseLoads: failedLoads,
    );
  }

  Future<List<StudentDashboardCourse>> _loadMyCourses({
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.myCourses,
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data == null) {
      throw const FormatException('Invalid response from /courses/my');
    }

    final rawItems = data['items'];
    if (rawItems is! List) {
      throw const FormatException('Invalid courses payload');
    }

    return rawItems
        .whereType<Map>()
        .map((item) => StudentDashboardCourse.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((course) => course.id > 0)
        .toList();
  }

  Future<List<StudentDashboardExam>> _loadCourseExams(
    StudentDashboardCourse course, {
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.studentExams(course.id),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data == null) {
      throw const FormatException('Invalid response from student exams endpoint');
    }

    final rawItems = data['exams'];
    if (rawItems is! List) return const [];

    return rawItems
        .whereType<Map>()
        .map((item) => StudentDashboardExam.fromJson(
              Map<String, dynamic>.from(item),
              course: course,
            ))
        .where((exam) => exam.id > 0)
        .toList();
  }
}
