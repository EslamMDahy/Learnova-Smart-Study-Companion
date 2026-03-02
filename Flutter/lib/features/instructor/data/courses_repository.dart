import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'courses_api.dart';
import 'courses_models.dart';

class CoursesRepository {
  final CoursesApi _api;
  CoursesRepository(this._api);

  Future<MyCoursesResponse> myCourses({CancelToken? cancelToken}) =>
      _api.myCourses(cancelToken: cancelToken);

  Future<Map<String, dynamic>> createCourse({
    required CourseCreateRequest payload,
    CancelToken? cancelToken,
  }) =>
      _api.createCourse(payload: payload, cancelToken: cancelToken);

  /// Upload invitations Excel/CSV file
  /// -> POST /courses/{id}/invitations/upload
  Future<Map<String, dynamic>> uploadInvitationsFile({
    required String courseId,
    required Uint8List bytes,
    required String filename,
    CancelToken? cancelToken,
  }) =>
      _api.uploadInvitationsFile(
        courseId: courseId,
        bytes: bytes,
        filename: filename,
        cancelToken: cancelToken,
      );

  /// Send invitations after upload
  /// -> POST /courses/{id}/invitations/send
  Future<Map<String, dynamic>> sendInvitations({
    required String courseId,
    bool includeExpired = true,
    bool force = false,
    CancelToken? cancelToken,
  }) =>
      _api.sendInvitations(
        courseId: courseId,
        includeExpired: includeExpired,
        force: force,
        cancelToken: cancelToken,
      );
}
