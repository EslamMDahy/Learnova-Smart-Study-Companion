import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_error_bus.dart';
import '../../../../core/network/error_mapper.dart';

import '../../data/courses_models.dart';
import '../../data/courses_providers.dart';
import 'instructor_courses_state.dart';

final instructorCoursesControllerProvider =
    StateNotifierProvider.autoDispose<InstructorCoursesController, InstructorCoursesState>(
  InstructorCoursesController.new,
);

class InstructorCoursesController extends StateNotifier<InstructorCoursesState> {
  InstructorCoursesController(this._ref) : super(const InstructorCoursesState());

  final Ref _ref;
  CancelToken? _cancel;

  Future<void> load({bool force = false}) async {
    
    if (state.loading && !force) return;

    _cancel?.cancel();
    _cancel = CancelToken();

    state = state.copyWith(loading: true);

    try {
      final res = await _ref.read(coursesRepositoryProvider).myCourses(
        cancelToken: _cancel,
      );
      state = state.copyWith(loading: false, items: res.items);
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(_ref, failure);

      state = state.copyWith(
        loading: false,
        error: failure.message,
      );
    }
  }



  Future<MyCourseItem> updateCourse({
    required MyCourseItem course,
    required CourseUpdateRequest payload,
  }) async {
    _cancel?.cancel();
    _cancel = CancelToken();

    final previousItems = state.items;
    state = state.copyWith(loading: true);

    try {
      final updated = await _ref.read(coursesRepositoryProvider).updateCourse(
            courseId: course.id,
            payload: payload,
            cancelToken: _cancel,
          );

      state = state.copyWith(
        loading: false,
        items: previousItems
            .map((item) => item.id == updated.id ? updated : item)
            .toList(growable: false),
      );
      return updated;
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(_ref, failure);
      state = state.copyWith(
        loading: false,
        error: failure.message,
        items: previousItems,
      );
      rethrow;
    }
  }

  Future<MyCourseItem> publishCourse(MyCourseItem course) async {
    _cancel?.cancel();
    _cancel = CancelToken();

    final previousItems = state.items;
    state = state.copyWith(loading: true);

    try {
      final response = await _ref.read(coursesRepositoryProvider).publishCourse(
            courseId: course.id,
            cancelToken: _cancel,
          );

      final updated = course.copyWith(
        status: response.status.isEmpty ? 'published' : response.status,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        loading: false,
        items: previousItems
            .map((item) => item.id == updated.id ? updated : item)
            .toList(growable: false),
      );
      return updated;
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(_ref, failure);
      state = state.copyWith(
        loading: false,
        error: failure.message,
        items: previousItems,
      );
      rethrow;
    }
  }

  /// Creates a course and returns the typed backend response.
  ///
  /// NOTE: We do NOT call load() here automatically because the UI flow
  /// might need the created courseId first (e.g., to upload invitations),
  /// then refresh after finishing that flow.
  Future<CourseCreatedResponse> createCourse(CourseCreateRequest payload) async {
    _cancel?.cancel();
    _cancel = CancelToken();

    state = state.copyWith(loading: true);

    try {
      final created = await _ref
          .read(coursesRepositoryProvider)
          .createCourse(payload: payload, cancelToken: _cancel);

      // stop loading here; the caller will decide when to refresh
      state = state.copyWith(loading: false);
      return created;
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(_ref, failure);

      state = state.copyWith(
        loading: false,
        error: failure.message,
      );
      rethrow;
    }
  }


  Future<MyCourseItem> uploadCourseCover({
    required MyCourseItem course,
    required List<int> bytes,
    required String? contentType,
    required String filename,
    bool recoverExistingObjectOnDuplicate = false,
  }) async {
    _cancel?.cancel();
    _cancel = CancelToken();

    final previousItems = state.items;
    state = state.copyWith(loading: true);

    try {
      final result = await _ref.read(coursesRepositoryProvider).uploadCourseCover(
            courseId: course.id,
            bytes: Uint8List.fromList(bytes),
            contentType: contentType,
            filename: filename,
            recoverExistingObjectOnDuplicate: recoverExistingObjectOnDuplicate,
            cancelToken: _cancel,
          );

      final updated = course.copyWith(
        coverImageUrl: result.coverUrl,
        updatedAt: result.updatedAt ?? DateTime.now(),
      );

      state = state.copyWith(
        loading: false,
        items: previousItems
            .map((item) => item.id == updated.id ? updated : item)
            .toList(growable: false),
      );

      return updated;
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(_ref, failure);

      state = state.copyWith(
        loading: false,
        error: failure.message,
        items: previousItems,
      );
      rethrow;
    }
  }

  Future<CourseCoverConfirmResponse> uploadCourseCoverById({
    required int courseId,
    required List<int> bytes,
    required String? contentType,
    required String filename,
    bool recoverExistingObjectOnDuplicate = false,
  }) async {
    _cancel?.cancel();
    _cancel = CancelToken();

    try {
      return await _ref.read(coursesRepositoryProvider).uploadCourseCover(
            courseId: courseId,
            bytes: Uint8List.fromList(bytes),
            contentType: contentType,
            filename: filename,
            recoverExistingObjectOnDuplicate: recoverExistingObjectOnDuplicate,
            cancelToken: _cancel,
          );
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(_ref, failure);
      rethrow;
    }
  }

  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }
}
