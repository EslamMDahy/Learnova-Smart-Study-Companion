import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/utils/json_utils.dart';
import 'student_courses_models.dart';

class StudentCoursesApi {
  final ApiClient _client;

  const StudentCoursesApi(this._client);

  Future<StudentMyCoursesResponse> myCourses({CancelToken? cancelToken}) async {
    final res = await _client.get<Object?>(
      Endpoints.myCourses,
      cancelToken: cancelToken,
    );

    return StudentMyCoursesResponse.fromJson(
      requireJsonMap(res.data, 'Invalid response from /courses/my'),
    );
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

    final res = await _client.get<Object?>(
      path,
      cancelToken: cancelToken,
    );

    final data = res.data;
    final map = asJsonMap(data);
    if (map != null) return StudentCourseSearchResponse.fromJson(map);

    final list = asJsonList(data);
    if (list != null) {
      return StudentCourseSearchResponse.fromList(
        list,
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

    final res = await _client.get<Object?>(
      path,
      cancelToken: cancelToken,
    );

    final data = res.data;
    final map = asJsonMap(data);
    if (map != null) return StudentCourseAutocompleteResponse.fromJson(map);

    final list = asJsonList(data);
    if (list != null) return StudentCourseAutocompleteResponse.fromList(list);

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

    final res = await _client.post<Object?>(
      Endpoints.acceptCourseInvitation,
      data: {'token': normalizedToken},
      cancelToken: cancelToken,
    );

    return StudentCourseInviteAcceptResult.fromJson(
      requireJsonMap(
        res.data,
        'Invalid response from /courses/invitations/accept',
      ),
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

    final modulesResponse = await _client.get<Object?>(
      Endpoints.courseModules(courseId),
      cancelToken: cancelToken,
    );

    final modulesPayload = requireJsonMap(
      modulesResponse.data,
      'Invalid response from /courses/{id}/modules',
    );
    final rawModules = requireJsonList(
      modulesPayload['modules'],
      'Invalid modules payload',
    );

    final modules = jsonMapList(rawModules)
        .map(StudentCourseModule.fromJson)
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
    final res = await _client.get<Object?>(
      Endpoints.moduleMaterials(courseId, moduleId),
      cancelToken: cancelToken,
    );

    final data = requireJsonMap(
      res.data,
      'Invalid response from module materials',
    );
    final rawMaterials = requireJsonList(
      data['materials'],
      'Invalid module materials payload',
    );

    final materials = jsonMapList(rawMaterials)
        .map(StudentCourseMaterial.fromJson)
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
    final res = await _client.get<Object?>(
      Endpoints.materialTopics(courseId, moduleId, materialId),
      cancelToken: cancelToken,
    );

    final data = requireJsonMap(
      res.data,
      'Invalid response from material topics',
    );
    final rawTopics = requireJsonList(
      data['topics'],
      'Invalid material topics payload',
    );

    return jsonMapList(rawTopics)
        .map(StudentCourseTopic.fromJson)
        .where((topic) => topic.id > 0)
        .toList(growable: false);
  }

  Future<List<StudentCourseExam>> listStudentExams({
    required int courseId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Object?>(
      Endpoints.studentExams(courseId),
      cancelToken: cancelToken,
    );

    return StudentCourseExamListResponse.fromJson(
      requireJsonMap(
        res.data,
        'Invalid response from student exams endpoint',
      ),
    ).exams;
  }

  Future<StudentExamAttempt> startStudentExamAttempt({
    required int courseId,
    required int examId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.post<Object?>(
      Endpoints.startStudentExamAttempt(courseId, examId),
      cancelToken: cancelToken,
    );

    return StudentExamAttempt.fromJson(
      requireJsonMap(res.data, 'Invalid response from student exam attempt'),
    );
  }

  Future<StudentExamAttemptsList> listStudentExamAttempts({
    required int courseId,
    required int examId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Object?>(
      Endpoints.studentExamAttempts(courseId, examId),
      cancelToken: cancelToken,
    );

    return StudentExamAttemptsList.fromJson(
      requireJsonMap(res.data, 'Invalid response from student exam attempts'),
    );
  }

  Future<StudentExamLatestResult> studentExamAttemptResult({
    required int courseId,
    required int examId,
    required int attemptId,
    StudentExamAttemptSummary? summary,
    int attemptsUsed = 0,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Object?>(
      Endpoints.studentExamAttemptResult(courseId, examId, attemptId),
      cancelToken: cancelToken,
    );

    return StudentExamLatestResult.fromAttemptResult(
      requireJsonMap(res.data, 'Invalid response from student exam result'),
      courseId: courseId,
      summary: summary,
      attemptsUsed: attemptsUsed,
    );
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
    await _client.put<Object?>(
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
    final res = await _client.post<Object?>(
      Endpoints.submitStudentExam(courseId, examId, attemptId),
      data: {
        'answers': answers.map((answer) => answer.toJson()).toList(growable: false),
        if (timeSpentSeconds != null) 'time_spent_seconds': timeSpentSeconds,
      },
      cancelToken: cancelToken,
    );

    return StudentExamSubmitResult.fromJson(
      requireJsonMap(res.data, 'Invalid response from student exam submit'),
    );
  }

  Future<String?> materialDownloadUrl({
    required int courseId,
    required int moduleId,
    required int materialId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Object?>(
      Endpoints.materialDownloadUrl(courseId, moduleId, materialId),
      cancelToken: cancelToken,
    );

    final data = requireJsonMap(
      res.data,
      'Invalid response from material download URL',
    );
    final url = (data['download_url'] ?? data['url'] ?? '').toString().trim();
    return url.isEmpty ? null : url;
  }

  Future<StudentCourseEnrollmentResult> enroll({
    required int courseId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.post<Object?>(
      Endpoints.enrollCourse(courseId),
      cancelToken: cancelToken,
    );

    return StudentCourseEnrollmentResult.fromJson(
      requireJsonMap(res.data, 'Invalid response from /courses/{id}/enroll'),
    );
  }
}
