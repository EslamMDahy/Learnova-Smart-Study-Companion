import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_error_bus.dart';
import '../../../core/network/error_mapper.dart';
import '../../auth/data/auth_providers.dart';
import 'student_courses_api.dart';
import 'student_courses_models.dart';

final studentCoursesApiProvider = Provider<StudentCoursesApi>((ref) {
  return StudentCoursesApi(ref.watch(apiClientProvider));
});


final studentCourseContentProvider = FutureProvider.autoDispose
    .family<StudentCourseContent, int>((ref, courseId) async {
  final cancelToken = CancelToken();
  ref.onDispose(() => cancelToken.cancel());

  return ref.read(studentCoursesApiProvider).courseContent(
        courseId: courseId,
        cancelToken: cancelToken,
      );
});


class StudentMaterialTopicsArgs {
  final int courseId;
  final int moduleId;
  final int materialId;

  const StudentMaterialTopicsArgs({
    required this.courseId,
    required this.moduleId,
    required this.materialId,
  });

  @override
  bool operator ==(Object other) {
    return other is StudentMaterialTopicsArgs &&
        other.courseId == courseId &&
        other.moduleId == moduleId &&
        other.materialId == materialId;
  }

  @override
  int get hashCode => Object.hash(courseId, moduleId, materialId);
}

final studentMaterialTopicsProvider = FutureProvider.autoDispose
    .family<List<StudentCourseTopic>, StudentMaterialTopicsArgs>((ref, args) async {
  final cancelToken = CancelToken();
  ref.onDispose(() => cancelToken.cancel());

  return ref.read(studentCoursesApiProvider).listMaterialTopics(
        courseId: args.courseId,
        moduleId: args.moduleId,
        materialId: args.materialId,
        cancelToken: cancelToken,
      );
});

class StudentExamAttemptArgs {
  final int courseId;
  final int examId;

  const StudentExamAttemptArgs({
    required this.courseId,
    required this.examId,
  });

  @override
  bool operator ==(Object other) {
    return other is StudentExamAttemptArgs &&
        other.courseId == courseId &&
        other.examId == examId;
  }

  @override
  int get hashCode => Object.hash(courseId, examId);
}

final studentExamAttemptProvider = FutureProvider.autoDispose
    .family<StudentExamAttempt, StudentExamAttemptArgs>((ref, args) async {
  final cancelToken = CancelToken();
  ref.onDispose(() => cancelToken.cancel());

  return ref.read(studentCoursesApiProvider).startStudentExamAttempt(
        courseId: args.courseId,
        examId: args.examId,
        cancelToken: cancelToken,
      );
});


class StudentExamResultArgs {
  final int courseId;
  final int examId;

  const StudentExamResultArgs({
    required this.courseId,
    required this.examId,
  });

  @override
  bool operator ==(Object other) {
    return other is StudentExamResultArgs &&
        other.courseId == courseId &&
        other.examId == examId;
  }

  @override
  int get hashCode => Object.hash(courseId, examId);
}

final studentExamLatestResultProvider = FutureProvider.autoDispose
    .family<StudentExamLatestResult, StudentExamResultArgs>((ref, args) async {
  final cancelToken = CancelToken();
  ref.onDispose(() => cancelToken.cancel());

  return ref.read(studentCoursesApiProvider).latestStudentExamResult(
        courseId: args.courseId,
        examId: args.examId,
        cancelToken: cancelToken,
      );
});

final studentCoursesControllerProvider = StateNotifierProvider.autoDispose<
    StudentCoursesController, StudentCoursesState>((ref) {
  return StudentCoursesController(ref);
});

const _keep = Object();

class StudentCoursesState {
  final bool loadingEnrolled;
  final bool searching;
  final bool loadingSuggestions;
  final Set<int> enrollingCourseIds;
  final List<StudentCourse> enrolledCourses;
  final List<StudentCourse> publicCourses;
  final List<String> autocompleteSuggestions;
  final String query;
  final String autocompleteQuery;
  final int publicTotal;
  final String? enrolledError;
  final String? searchError;
  final String? autocompleteError;

  const StudentCoursesState({
    this.loadingEnrolled = false,
    this.searching = false,
    this.loadingSuggestions = false,
    this.enrollingCourseIds = const {},
    this.enrolledCourses = const [],
    this.publicCourses = const [],
    this.autocompleteSuggestions = const [],
    this.query = '',
    this.autocompleteQuery = '',
    this.publicTotal = 0,
    this.enrolledError,
    this.searchError,
    this.autocompleteError,
  });

  bool get isInitialLoading => loadingEnrolled && enrolledCourses.isEmpty;

  bool isEnrolling(int courseId) => enrollingCourseIds.contains(courseId);

  StudentCoursesState copyWith({
    bool? loadingEnrolled,
    bool? searching,
    bool? loadingSuggestions,
    Set<int>? enrollingCourseIds,
    List<StudentCourse>? enrolledCourses,
    List<StudentCourse>? publicCourses,
    List<String>? autocompleteSuggestions,
    String? query,
    String? autocompleteQuery,
    int? publicTotal,
    Object? enrolledError = _keep,
    Object? searchError = _keep,
    Object? autocompleteError = _keep,
  }) {
    return StudentCoursesState(
      loadingEnrolled: loadingEnrolled ?? this.loadingEnrolled,
      searching: searching ?? this.searching,
      loadingSuggestions: loadingSuggestions ?? this.loadingSuggestions,
      enrollingCourseIds: enrollingCourseIds ?? this.enrollingCourseIds,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      publicCourses: publicCourses ?? this.publicCourses,
      autocompleteSuggestions:
          autocompleteSuggestions ?? this.autocompleteSuggestions,
      query: query ?? this.query,
      autocompleteQuery: autocompleteQuery ?? this.autocompleteQuery,
      publicTotal: publicTotal ?? this.publicTotal,
      enrolledError: identical(enrolledError, _keep)
          ? this.enrolledError
          : enrolledError as String?,
      searchError:
          identical(searchError, _keep) ? this.searchError : searchError as String?,
      autocompleteError: identical(autocompleteError, _keep)
          ? this.autocompleteError
          : autocompleteError as String?,
    );
  }
}

class StudentCoursesController extends StateNotifier<StudentCoursesState> {
  StudentCoursesController(this._ref) : super(const StudentCoursesState());

  final Ref _ref;
  CancelToken? _loadCancel;
  CancelToken? _searchCancel;
  CancelToken? _autocompleteCancel;
  CancelToken? _enrollCancel;

  Future<void> loadEnrolled({bool force = false}) async {
    if (state.loadingEnrolled && !force) return;

    _loadCancel?.cancel();
    _loadCancel = CancelToken();

    state = state.copyWith(
      loadingEnrolled: true,
      enrolledError: null,
    );

    try {
      final res = await _ref.read(studentCoursesApiProvider).myCourses(
            cancelToken: _loadCancel,
          );

      state = state.copyWith(
        loadingEnrolled: false,
        enrolledCourses: res.items,
        publicCourses: _excludeEnrolled(state.publicCourses, res.items),
        enrolledError: null,
      );
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(_ref, failure);
      state = state.copyWith(
        loadingEnrolled: false,
        enrolledError: failure.message,
      );
    }
  }

  Future<void> searchPublic(String rawQuery, {bool force = false}) async {
    final query = rawQuery.trim();

    if (query.isEmpty) {
      _searchCancel?.cancel();
      state = state.copyWith(
        searching: false,
        query: '',
        publicCourses: const [],
        autocompleteSuggestions: const [],
        autocompleteQuery: '',
        publicTotal: 0,
        searchError: null,
        autocompleteError: null,
      );
      return;
    }

    if (state.searching && !force && query == state.query) return;

    _searchCancel?.cancel();
    _searchCancel = CancelToken();

    state = state.copyWith(
      searching: true,
      query: query,
      autocompleteSuggestions: const [],
      autocompleteQuery: '',
      searchError: null,
      autocompleteError: null,
    );

    try {
      final res = await _ref.read(studentCoursesApiProvider).searchPublicCourses(
            query: query,
            limit: 20,
            cancelToken: _searchCancel,
          );

      state = state.copyWith(
        searching: false,
        publicCourses: _excludeEnrolled(res.results, state.enrolledCourses),
        publicTotal: res.total,
        searchError: null,
      );
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(_ref, failure);
      state = state.copyWith(
        searching: false,
        publicCourses: const [],
        publicTotal: 0,
        searchError: failure.message,
      );
    }
  }

  Future<void> autocompletePublic(String rawQuery) async {
    final query = rawQuery.trim();

    if (query.isEmpty) {
      _autocompleteCancel?.cancel();
      state = state.copyWith(
        loadingSuggestions: false,
        autocompleteSuggestions: const [],
        autocompleteQuery: '',
        autocompleteError: null,
      );
      return;
    }

    _autocompleteCancel?.cancel();
    _autocompleteCancel = CancelToken();

    state = state.copyWith(
      loadingSuggestions: true,
      autocompleteQuery: query,
      autocompleteError: null,
    );

    try {
      final res =
          await _ref.read(studentCoursesApiProvider).autocompletePublicCourses(
                query: query,
                cancelToken: _autocompleteCancel,
              );

      state = state.copyWith(
        loadingSuggestions: false,
        autocompleteSuggestions: res.suggestions,
        autocompleteQuery: query,
        autocompleteError: null,
      );
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) return;

      final failure = mapApiFailure(e);
      state = state.copyWith(
        loadingSuggestions: false,
        autocompleteSuggestions: const [],
        autocompleteQuery: query,
        autocompleteError: failure.message,
      );
    }
  }

  Future<StudentCourseEnrollmentResult> enroll(StudentCourse course) async {
    if (state.enrollingCourseIds.contains(course.id)) {
      throw StateError('Enrollment is already in progress.');
    }

    final updatedIds = {...state.enrollingCourseIds, course.id};
    state = state.copyWith(enrollingCourseIds: updatedIds);

    _enrollCancel?.cancel();
    _enrollCancel = CancelToken();

    try {
      final result = await _ref.read(studentCoursesApiProvider).enroll(
            courseId: course.id,
            cancelToken: _enrollCancel,
          );

      final enrolledCourse = course.copyWith(
        source: StudentCourseSource.enrolled,
        enrollmentStatus: result.status,
      );

      state = state.copyWith(
        enrollingCourseIds: _withoutCourseId(state.enrollingCourseIds, course.id),
        enrolledCourses: _prependUnique(enrolledCourse, state.enrolledCourses),
        publicCourses:
            state.publicCourses.where((item) => item.id != course.id).toList(),
      );

      return result;
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(_ref, failure);
      state = state.copyWith(
        enrollingCourseIds: _withoutCourseId(state.enrollingCourseIds, course.id),
        searchError: failure.message,
      );
      rethrow;
    }
  }

  List<StudentCourse> _excludeEnrolled(
    List<StudentCourse> publicCourses,
    List<StudentCourse> enrolledCourses,
  ) {
    final enrolledIds = enrolledCourses.map((course) => course.id).toSet();
    return publicCourses
        .where((course) => !enrolledIds.contains(course.id))
        .toList(growable: false);
  }

  Set<int> _withoutCourseId(Set<int> ids, int courseId) {
    final updated = {...ids};
    updated.remove(courseId);
    return updated;
  }

  List<StudentCourse> _prependUnique(
    StudentCourse course,
    List<StudentCourse> current,
  ) {
    return [
      course,
      ...current.where((item) => item.id != course.id),
    ];
  }

  @override
  void dispose() {
    _loadCancel?.cancel();
    _searchCancel?.cancel();
    _autocompleteCancel?.cancel();
    _enrollCancel?.cancel();
    super.dispose();
  }
}
