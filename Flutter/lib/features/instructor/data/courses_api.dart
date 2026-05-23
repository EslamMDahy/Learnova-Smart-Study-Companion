import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/log/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import 'courses_models.dart';

class CoursesApi {
  final ApiClient _client;
  CoursesApi(this._client);

  MyCourseItem? _courseFromDynamic(dynamic raw) {
    if (raw is! Map) return null;
    final data = Map<String, dynamic>.from(raw);
    final nested = data['course'] ?? data['item'] ?? data['data'];
    bool hasCourseShape(Map<String, dynamic> value) {
      return value.containsKey('course_type') ||
          value.containsKey('visibility_level') ||
          value.containsKey('status') ||
          value.containsKey('created_at') ||
          value.containsKey('updated_at');
    }

    if (nested is Map) {
      final nestedData = Map<String, dynamic>.from(nested);
      if ((nestedData.containsKey('id') || nestedData.containsKey('title')) &&
          hasCourseShape(nestedData)) {
        return MyCourseItem.fromJson(nestedData);
      }
      return null;
    }
    final hasShape = data.containsKey('course_type') ||
        data.containsKey('visibility_level') ||
        data.containsKey('status') ||
        data.containsKey('created_at') ||
        data.containsKey('updated_at');
    if ((data.containsKey('id') || data.containsKey('title')) && hasShape) {
      return MyCourseItem.fromJson(data);
    }
    return null;
  }

  bool _canRetryCourseMutation(Object error) {
    if (error is! DioException) return false;
    final status = error.response?.statusCode;
    return status == 404 || status == 405;
  }

  /// GET /courses/my
  Future<MyCoursesResponse> myCourses({CancelToken? cancelToken}) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.myCourses,
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      AppLogger.log('GET ${Endpoints.myCourses} -> $data', level: LogLevel.debug);
      return MyCoursesResponse.fromJson(data);
    }
    throw const FormatException('Invalid response from /courses/my');
  }

  /// GET /courses/{id}
  ///
  /// Used to reload a single course after a browser refresh, so the
  /// details page is never dependent on the in-memory cache.
  Future<MyCourseItem> getCourseById(
    int id, {
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/courses/$id',
      cancelToken: cancelToken,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      AppLogger.log('GET /courses/$id -> $data', level: LogLevel.debug);
      return MyCourseItem.fromJson(data);
    }
    throw FormatException('Invalid response from GET /courses/$id');
  }

  /// POST /courses
  Future<CourseCreatedResponse> createCourse({
    required CourseCreateRequest payload,
    CancelToken? cancelToken,
  }) async {
    final title = payload.title.trim();
    if (title.isEmpty) {
      throw ArgumentError('Course title is required.');
    }

    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.createCourse,
      data: payload.toJson(),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return CourseCreatedResponse.fromJson(data);
    }
    throw const FormatException('Invalid response from POST /courses');
  }



  /// PATCH /courses/{id}/update
  ///
  /// The API client keeps fallbacks for deployments that expose REST-style
  /// /courses/{id} update routes instead.
  Future<MyCourseItem?> updateCourse({
    required int courseId,
    required CourseUpdateRequest payload,
    CancelToken? cancelToken,
  }) async {
    final body = payload.toJson();
    if (body.isEmpty) {
      throw ArgumentError('No course fields were changed.');
    }

    Future<MyCourseItem?> patch(String path) async {
      final res = await _client.patch<Map<String, dynamic>>(
        path,
        data: body,
        cancelToken: cancelToken,
      );
      return _courseFromDynamic(res.data);
    }

    Future<MyCourseItem?> put(String path) async {
      final res = await _client.put<Map<String, dynamic>>(
        path,
        data: body,
        cancelToken: cancelToken,
      );
      return _courseFromDynamic(res.data);
    }

    try {
      return await patch('/courses/$courseId/update');
    } catch (first) {
      if (!_canRetryCourseMutation(first)) rethrow;
      try {
        return await patch('/courses/$courseId');
      } catch (second) {
        if (!_canRetryCourseMutation(second)) rethrow;
        try {
          return await put('/courses/$courseId/update');
        } catch (third) {
          if (!_canRetryCourseMutation(third)) rethrow;
          return put('/courses/$courseId');
        }
      }
    }
  }

  Future<MyCourseItem?> archiveCourse({
    required int courseId,
    CancelToken? cancelToken,
  }) {
    return updateCourse(
      courseId: courseId,
      payload: const CourseUpdateRequest(status: 'archived'),
      cancelToken: cancelToken,
    );
  }

  /// DELETE /courses/{id}/delete
  ///
  /// Falls back to DELETE /courses/{id} for REST-style deployments.
  Future<void> deleteCourse({
    required int courseId,
    CancelToken? cancelToken,
  }) async {
    try {
      await _client.delete<void>(
        '/courses/$courseId/delete',
        cancelToken: cancelToken,
      );
    } catch (first) {
      if (!_canRetryCourseMutation(first)) rethrow;
      await _client.delete<void>(
        '/courses/$courseId',
        cancelToken: cancelToken,
      );
    }
  }


  /// POST /courses/{courseId}/invitations/upload
  ///
  /// Backend expects multipart file upload.
  Future<Map<String, dynamic>> uploadInvitationsFile({
    required String courseId,
    required Uint8List bytes,
    required String filename,
    CancelToken? cancelToken,
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError('File bytes are empty.');
    }

    final form = FormData.fromMap({
      // IMPORTANT: backend expects field name "file"
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename.isNotEmpty ? filename : 'invitations.xlsx',
      ),
    });

    final res = await _client.post<Map<String, dynamic>>(
      '/courses/$courseId/invitations/upload',
      data: form,
      options: Options(
        // Dio will set the correct boundary automatically
        contentType: 'multipart/form-data',
      ),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Invalid response from POST /courses/{id}/invitations/upload');
  }

  /// POST /courses/{courseId}/invitations/send
  Future<Map<String, dynamic>> sendInvitations({
    required String courseId,
    bool includeExpired = true,
    bool force = false,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/courses/$courseId/invitations/send',
      data: {
        'include_expired': includeExpired,
        'force': force,
      },
      cancelToken: cancelToken,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Invalid response from POST /courses/{id}/invitations/send');
  }

  /// POST /courses/invitations/accept
  /// Student uses this to accept an invitation by token (from email link).
  Future<Map<String, dynamic>> acceptInvitation({
    required String token,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.acceptCourseInvitation,
      data: {'token': token},
      cancelToken: cancelToken,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Invalid response from POST /courses/invitations/accept');
  }
}
