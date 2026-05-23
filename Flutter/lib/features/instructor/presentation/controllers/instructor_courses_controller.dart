import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_error_bus.dart';
import '../../../../core/network/error_mapper.dart';

import '../../data/courses_models.dart';
import '../../data/courses_providers.dart';
import 'instructor_courses_state.dart';

final instructorCoursesControllerProvider =
    StateNotifierProvider.autoDispose<InstructorCoursesController, InstructorCoursesState>(
  (ref) => InstructorCoursesController(ref),
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
        enrichMissingModuleCounts: true,
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


  MyCourseItem _fallbackUpdatedCourse(
    MyCourseItem course,
    CourseUpdateRequest payload,
  ) {
    return course.copyWith(
      title: payload.title?.trim().isNotEmpty == true
          ? payload.title!.trim()
          : course.title,
      courseCode: payload.courseCode?.trim().isNotEmpty == true
          ? payload.courseCode!.trim()
          : course.courseCode,
      category: payload.category?.trim().isNotEmpty == true
          ? payload.category!.trim()
          : course.category,
      courseType: payload.courseType != null
          ? payload.courseType!.trim()
          : course.courseType,
      isPublic: payload.isPublic,
      visibilityLevel: payload.visibilityLevel != null
          ? payload.visibilityLevel!.trim()
          : course.visibilityLevel,
      status: payload.status != null ? payload.status!.trim() : course.status,
      updatedAt: DateTime.now(),
    );
  }

  void _replaceCourse(MyCourseItem updated) {
    state = state.copyWith(
      items: state.items
          .map((course) => course.id == updated.id ? updated : course)
          .toList(growable: false),
      error: null,
    );
  }

  Future<MyCourseItem> updateCourse(
    MyCourseItem course,
    CourseUpdateRequest payload,
  ) async {
    try {
      final updated = await _ref.read(coursesRepositoryProvider).updateCourse(
            courseId: course.id,
            payload: payload,
          );

      final next = updated ?? _fallbackUpdatedCourse(course, payload);
      _replaceCourse(next);
      return next;
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(_ref, failure);
      state = state.copyWith(error: failure.message);
      rethrow;
    }
  }

  Future<MyCourseItem> archiveCourse(MyCourseItem course) {
    return updateCourse(
      course,
      const CourseUpdateRequest(status: 'archived'),
    );
  }

  Future<void> deleteCourse(MyCourseItem course) async {
    try {
      await _ref.read(coursesRepositoryProvider).deleteCourse(courseId: course.id);
      state = state.copyWith(
        items: state.items
            .where((item) => item.id != course.id)
            .toList(growable: false),
        error: null,
      );
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(_ref, failure);
      state = state.copyWith(error: failure.message);
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

  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }
}
