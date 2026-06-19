import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import 'student_courses_models.dart';

class StudentCoursesApi {
  final ApiClient _client;

  const StudentCoursesApi(this._client);

  Future<StudentMyCoursesResponse> myCourses({CancelToken? cancelToken}) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.myCourses,
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return StudentMyCoursesResponse.fromJson(data);
    }

    throw const FormatException('Invalid response from /courses/my');
  }

  Future<StudentCourseSearchResponse> searchPublicCourses({
    required String query,
    int limit = 20,
    int offset = 0,
    CancelToken? cancelToken,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return const StudentCourseSearchResponse(
        total: 0,
        limit: 20,
        offset: 0,
        results: [],
      );
    }

    final safeLimit = limit.clamp(1, 50).toInt();
    final safeOffset = offset < 0 ? 0 : offset;

    // Backend contract:
    // GET /courses/search?q=<keyword>&limit=<1..50>&offset=<0..n>
    final path = Uri(
      path: Endpoints.courseSearch,
      queryParameters: {
        'q': normalizedQuery,
        'limit': safeLimit.toString(),
        'offset': safeOffset.toString(),
      },
    ).toString();

    final res = await _client.get<dynamic>(
      path,
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return StudentCourseSearchResponse.fromJson(data);
    }
    if (data is Map) {
      return StudentCourseSearchResponse.fromJson(
        Map<String, dynamic>.from(data),
      );
    }
    if (data is List) {
      return StudentCourseSearchResponse.fromList(
        data,
        limit: safeLimit,
        offset: safeOffset,
      );
    }

    throw const FormatException('Invalid response from /courses/search');
  }

  Future<StudentCourseAutocompleteResponse> autocompletePublicCourses({
    required String query,
    CancelToken? cancelToken,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return const StudentCourseAutocompleteResponse(suggestions: []);
    }

    final path = Uri(
      path: Endpoints.courseSearchAutocomplete,
      queryParameters: {'q': normalizedQuery},
    ).toString();

    final res = await _client.get<dynamic>(
      path,
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return StudentCourseAutocompleteResponse.fromJson(data);
    }
    if (data is Map) {
      return StudentCourseAutocompleteResponse.fromJson(
        Map<String, dynamic>.from(data),
      );
    }
    if (data is List) {
      return StudentCourseAutocompleteResponse.fromList(data);
    }

    throw const FormatException(
      'Invalid response from /courses/search/autocomplete',
    );
  }

  Future<StudentCourseInviteAcceptResult> acceptCourseInvitation({
    required String token,
    CancelToken? cancelToken,
  }) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      throw const FormatException('Invitation token is required');
    }

    final res = await _client.post<dynamic>(
      Endpoints.acceptCourseInvitation,
      data: {'token': normalizedToken},
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return StudentCourseInviteAcceptResult.fromJson(data);
    }
    if (data is Map) {
      return StudentCourseInviteAcceptResult.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    throw const FormatException(
      'Invalid response from /courses/invitations/accept',
    );
  }


  Future<StudentCourseContent> courseContent({
    required int courseId,
    CancelToken? cancelToken,
  }) async {
    if (courseId <= 0) {
      throw const FormatException('A valid course id is required');
    }

    final myCoursesResponse = await myCourses(cancelToken: cancelToken);
    StudentCourse? selectedCourse;
    for (final course in myCoursesResponse.items) {
      if (course.id == courseId) {
        selectedCourse = course;
        break;
      }
    }

    final modulesResponse = await _client.get<Map<String, dynamic>>(
      Endpoints.courseModules(courseId),
      cancelToken: cancelToken,
    );

    final modulesPayload = modulesResponse.data;
    if (modulesPayload is! Map<String, dynamic>) {
      throw const FormatException('Invalid response from /courses/{id}/modules');
    }

    final rawModules = modulesPayload['modules'];
    if (rawModules is! List) {
      throw const FormatException('Invalid modules payload');
    }

    final modules = rawModules
        .whereType<Map>()
        .map((item) => StudentCourseModule.fromJson(Map<String, dynamic>.from(item)))
        .where((module) => module.id > 0)
        .toList(growable: false);

    final modulesWithMaterials = await Future.wait(
      modules.map((module) async {
        final materials = await _listModuleMaterials(
          courseId: courseId,
          moduleId: module.id,
          cancelToken: cancelToken,
        );
        return module.copyWith(materials: materials);
      }),
    );

    var exams = const <StudentCourseExam>[];
    try {
      exams = await listStudentExams(
        courseId: courseId,
        cancelToken: cancelToken,
      );
    } catch (_) {
      // Materials should still render even if the student-exam endpoint fails.
      exams = const <StudentCourseExam>[];
    }

    return StudentCourseContent(
      course: selectedCourse,
      modules: modulesWithMaterials,
      exams: exams,
    );
  }

  Future<List<StudentCourseMaterial>> _listModuleMaterials({
    required int courseId,
    required int moduleId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.moduleMaterials(courseId, moduleId),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid response from module materials');
    }

    final rawMaterials = data['materials'];
    if (rawMaterials is! List) {
      throw const FormatException('Invalid module materials payload');
    }

    final materials = rawMaterials
        .whereType<Map>()
        .map((item) => StudentCourseMaterial.fromJson(Map<String, dynamic>.from(item)))
        .where((material) => material.id > 0)
        .toList(growable: false);

    // Do not fetch topics for every material while opening the course.
    // Topics are loaded lazily for the selected/opened material only from
    // studentMaterialTopicsProvider.
    return materials;
  }

  Future<List<StudentCourseTopic>> listMaterialTopics({
    required int courseId,
    required int moduleId,
    required int materialId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.materialTopics(courseId, moduleId, materialId),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid response from material topics');
    }

    final rawTopics = data['topics'];
    if (rawTopics is! List) {
      throw const FormatException('Invalid material topics payload');
    }

    return rawTopics
        .whereType<Map>()
        .map((item) => StudentCourseTopic.fromJson(Map<String, dynamic>.from(item)))
        .where((topic) => topic.id > 0)
        .toList(growable: false);
  }

  Future<List<StudentCourseExam>> listStudentExams({
    required int courseId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.studentExams(courseId),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return StudentCourseExamListResponse.fromJson(data).exams;
    }

    throw const FormatException('Invalid response from student exams endpoint');
  }

  Future<StudentExamAttempt> startStudentExamAttempt({
    required int courseId,
    required int examId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.startStudentExamAttempt(courseId, examId),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return StudentExamAttempt.fromJson(data);
    }

    throw const FormatException('Invalid response from student exam attempt');
  }


  Future<StudentExamAttemptsList> listStudentExamAttempts({
    required int courseId,
    required int examId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.studentExamAttempts(courseId, examId),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return StudentExamAttemptsList.fromJson(data);
    }

    throw const FormatException('Invalid response from student exam attempts');
  }

  Future<StudentExamLatestResult> studentExamAttemptResult({
    required int courseId,
    required int examId,
    required int attemptId,
    StudentExamAttemptSummary? summary,
    int attemptsUsed = 0,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.studentExamAttemptResult(courseId, examId, attemptId),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return StudentExamLatestResult.fromAttemptResult(
        Map<String, dynamic>.from(data),
        courseId: courseId,
        summary: summary,
        attemptsUsed: attemptsUsed,
      );
    }

    throw const FormatException('Invalid response from student exam result');
  }

  Future<StudentExamLatestResult> latestStudentExamResult({
    required int courseId,
    required int examId,
    CancelToken? cancelToken,
  }) async {
    final attemptsPayload = await listStudentExamAttempts(
      courseId: courseId,
      examId: examId,
      cancelToken: cancelToken,
    );

    final completedAttempts = attemptsPayload.attempts
        .where((attempt) => attempt.hasResult)
        .toList(growable: false)
      ..sort((a, b) => b.attemptNumber.compareTo(a.attemptNumber));

    if (completedAttempts.isEmpty) {
      final inProgressAttempts = attemptsPayload.attempts
          .where((attempt) => attempt.isInProgress)
          .toList(growable: false)
        ..sort((a, b) => b.attemptNumber.compareTo(a.attemptNumber));
      return StudentExamLatestResult.noAttempt(
        courseId: courseId,
        examId: examId,
        attemptsUsed: attemptsPayload.attempts.length,
        canStart: true,
        inProgressAttemptId: inProgressAttempts.isEmpty
            ? null
            : inProgressAttempts.first.attemptId,
      );
    }

    final latest = completedAttempts.first;
    return studentExamAttemptResult(
      courseId: courseId,
      examId: examId,
      attemptId: latest.attemptId,
      summary: latest,
      attemptsUsed: attemptsPayload.attempts.length,
      cancelToken: cancelToken,
    );
  }

  Future<void> saveStudentExamAnswer({
    required int courseId,
    required int examId,
    required int attemptId,
    required StudentExamAnswerDraft answer,
    CancelToken? cancelToken,
  }) async {
    await _client.put<Map<String, dynamic>>(
      Endpoints.submitStudentExamAnswer(courseId, examId, attemptId),
      data: answer.toJson(),
      options: Options(
        extra: const <String, dynamic>{'silent': true},
      ),
      cancelToken: cancelToken,
    );
  }

  Future<StudentExamSubmitResult> submitStudentExam({
    required int courseId,
    required int examId,
    required int attemptId,
    required List<StudentExamAnswerDraft> answers,
    int? timeSpentSeconds,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.submitStudentExam(courseId, examId, attemptId),
      data: {
        'answers': answers.map((answer) => answer.toJson()).toList(growable: false),
        if (timeSpentSeconds != null) 'time_spent_seconds': timeSpentSeconds,
      },
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return StudentExamSubmitResult.fromJson(data);
    }

    throw const FormatException('Invalid response from student exam submit');
  }

  Future<String?> materialDownloadUrl({
    required int courseId,
    required int moduleId,
    required int materialId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.materialDownloadUrl(courseId, moduleId, materialId),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      final url = (data['download_url'] ?? data['url'] ?? '').toString().trim();
      return url.isEmpty ? null : url;
    }

    throw const FormatException('Invalid response from material download URL');
  }

  Future<StudentCourseEnrollmentResult> enroll({
    required int courseId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.enrollCourse(courseId),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return StudentCourseEnrollmentResult.fromJson(data);
    }

    throw const FormatException('Invalid response from /courses/{id}/enroll');
  }
}
