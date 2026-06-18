import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/log/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/browser_upload_client.dart';
import '../../../core/network/endpoints.dart';
import 'courses_models.dart';

class CoursesApi {
  final ApiClient _client;
  CoursesApi(this._client);

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

  /// Resolve one course from GET /courses/my.
  ///
  /// The uploaded backend does not expose GET /courses/{id}; using /courses/my
  /// prevents course-detail refreshes from hitting a guaranteed 404.
  Future<MyCourseItem> getCourseById(
    int id, {
    CancelToken? cancelToken,
  }) async {
    final response = await myCourses(cancelToken: cancelToken);
    for (final course in response.items) {
      if (course.id == id) return course;
    }
    throw StateError('Course not found in your courses. Reopen it from My Courses.');
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




  String _normalizeCoverContentType(String? contentType, String filename) {
    final raw = (contentType ?? '').trim().toLowerCase();
    if (raw == 'image/png') return 'image/png';
    if (raw == 'image/jpeg' || raw == 'image/jpg') return 'image/jpeg';

    final lowerName = filename.trim().toLowerCase();
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    throw ArgumentError('Course cover must be a PNG or JPG image.');
  }

  Future<Response<Map<String, dynamic>>> _postWithLegacyFallback({
    required String primaryPath,
    required String legacyPath,
    dynamic data,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _client.post<Map<String, dynamic>>(
        primaryPath,
        data: data,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
      return _client.post<Map<String, dynamic>>(
        legacyPath,
        data: data,
        cancelToken: cancelToken,
      );
    }
  }

  /// POST /courses/{courseId}/cover/initiate
  /// The uploaded backend also has a legacy doubled route
  /// /courses/courses/{courseId}/cover/initiate, so this method falls back to it.
  Future<CourseCoverUploadInitResponse> initiateCourseCoverUpload({
    required int courseId,
    required String contentType,
    required int fileSizeBytes,
    CancelToken? cancelToken,
  }) async {
    if (courseId <= 0) throw ArgumentError('Invalid course id.');
    if (fileSizeBytes <= 0) throw ArgumentError('Cover image is empty.');

    final res = await _postWithLegacyFallback(
      primaryPath: Endpoints.courseCoverInitiate(courseId),
      legacyPath: Endpoints.courseCoverInitiateLegacy(courseId),
      data: {
        'content_type': contentType,
        'file_size_bytes': fileSizeBytes,
      },
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      final parsed = CourseCoverUploadInitResponse.fromJson(data);
      if (parsed.uploadUrl.trim().isEmpty) {
        throw const FormatException('Course cover upload URL is missing.');
      }
      return parsed;
    }
    throw const FormatException('Invalid response from course cover initiate endpoint');
  }

  /// POST /courses/{courseId}/cover/confirm
  Future<CourseCoverConfirmResponse> confirmCourseCoverUpload({
    required int courseId,
    CancelToken? cancelToken,
  }) async {
    if (courseId <= 0) throw ArgumentError('Invalid course id.');

    final res = await _postWithLegacyFallback(
      primaryPath: Endpoints.courseCoverConfirm(courseId),
      legacyPath: Endpoints.courseCoverConfirmLegacy(courseId),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return CourseCoverConfirmResponse.fromJson(data);
    }
    throw const FormatException('Invalid response from course cover confirm endpoint');
  }

  /// Full cover upload flow:
  /// 1) Backend creates signed Supabase upload URL
  /// 2) Browser uploads bytes directly to Supabase
  /// 3) Backend confirms and returns public cover_url
  Future<CourseCoverConfirmResponse> uploadCourseCover({
    required int courseId,
    required List<int> bytes,
    required String? contentType,
    required String filename,
    CancelToken? cancelToken,
  }) async {
    if (bytes.isEmpty) throw ArgumentError('Cover image is empty.');

    final normalizedContentType = _normalizeCoverContentType(contentType, filename);
    final init = await initiateCourseCoverUpload(
      courseId: courseId,
      contentType: normalizedContentType,
      fileSizeBytes: bytes.length,
      cancelToken: cancelToken,
    );

    await uploadBinaryToSignedUrl(
      uploadUrl: init.uploadUrl,
      bodyBytes: Uint8List.fromList(bytes),
      contentType: normalizedContentType,
      headers: const {'x-upsert': 'true'},
    );

    return confirmCourseCoverUpload(
      courseId: courseId,
      cancelToken: cancelToken,
    );
  }

  /// Course update/archive/delete endpoints are not exposed by the backend
  /// currently uploaded for this project. Do not call guessed routes here.

  /// POST /courses/{courseId}/invitations/upload
  ///
  /// Backend expects multipart .xlsx file upload with form field name `file`.
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
      Endpoints.courseInvitationsUpload(courseId),
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
      Endpoints.courseInvitationsSend(courseId),
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
