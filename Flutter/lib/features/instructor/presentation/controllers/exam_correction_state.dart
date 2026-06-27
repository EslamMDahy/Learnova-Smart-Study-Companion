import '../../data/courses_models.dart';
import '../../data/exam_correction_models.dart';
import '../../data/exam_models.dart';

class ExamCorrectionState {
  final List<ExamCorrectionUploadFile> files;
  final String language;
  final bool loading;
  final String? error;
  final ExamScanAnalyzeResponse? response;
  final List<MyCourseItem> courses;
  final List<ExamModel> exams;
  final int? selectedCourseId;
  final int? selectedExamId;
  final bool loadingCourses;
  final bool loadingExams;
  final String? contextError;

  const ExamCorrectionState({
    this.files = const [],
    this.language = 'eng',
    this.loading = false,
    this.error,
    this.response,
    this.courses = const [],
    this.exams = const [],
    this.selectedCourseId,
    this.selectedExamId,
    this.loadingCourses = false,
    this.loadingExams = false,
    this.contextError,
  });

  bool get hasExamTarget => selectedCourseId != null && selectedExamId != null;
  bool get canAnalyze => files.isNotEmpty && hasExamTarget && !loading && !loadingCourses && !loadingExams;

  MyCourseItem? get selectedCourse {
    final id = selectedCourseId;
    if (id == null) return null;
    for (final course in courses) {
      if (course.id == id) return course;
    }
    return null;
  }

  ExamModel? get selectedExam {
    final id = selectedExamId;
    if (id == null) return null;
    for (final exam in exams) {
      if (exam.id == id) return exam;
    }
    return null;
  }

  double effectivePointsFor(ExamScanAnswer answer) {
    return answer.pointsEarned ?? answer.aiScore ?? 0;
  }

  double get effectiveTotalScore {
    final scan = response;
    if (scan == null) return 0;
    return scan.answers.fold<double>(0, (sum, answer) => sum + effectivePointsFor(answer));
  }

  double? get effectivePercentage {
    final total = response?.gradePreview.totalScore ?? 0;
    if (total <= 0) return null;
    return (effectiveTotalScore / total) * 100;
  }

  ExamCorrectionState copyWith({
    List<ExamCorrectionUploadFile>? files,
    String? language,
    bool? loading,
    String? error,
    ExamScanAnalyzeResponse? response,
    List<MyCourseItem>? courses,
    List<ExamModel>? exams,
    int? selectedCourseId,
    int? selectedExamId,
    bool? loadingCourses,
    bool? loadingExams,
    String? contextError,
    bool clearError = false,
    bool clearResponse = false,
    bool clearSelectedCourse = false,
    bool clearSelectedExam = false,
    bool clearContextError = false,
  }) {
    return ExamCorrectionState(
      files: files ?? this.files,
      language: language ?? this.language,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      response: clearResponse ? null : response ?? this.response,
      courses: courses ?? this.courses,
      exams: exams ?? this.exams,
      selectedCourseId: clearSelectedCourse ? null : selectedCourseId ?? this.selectedCourseId,
      selectedExamId: clearSelectedExam ? null : selectedExamId ?? this.selectedExamId,
      loadingCourses: loadingCourses ?? this.loadingCourses,
      loadingExams: loadingExams ?? this.loadingExams,
      contextError: clearContextError ? null : contextError ?? this.contextError,
    );
  }
}
