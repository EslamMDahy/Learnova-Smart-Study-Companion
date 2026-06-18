import '../../data/exam_correction_models.dart';

class ExamCorrectionState {
  final List<ExamCorrectionUploadFile> files;
  final String language;
  final String examIdText;
  final String courseIdText;
  final String submitExamIdText;
  final String submitStudentIdText;
  final String teacherFeedback;
  final int studentIdDigits;
  final bool loading;
  final bool submitting;
  final bool healthLoading;
  final String? error;
  final String? submitMessage;
  final String? healthError;
  final OcrHealthResponse? health;
  final ExamScanAnalyzeResponse? response;
  final Map<String, double> pointsOverrides;
  final Map<String, bool> correctnessOverrides;

  const ExamCorrectionState({
    this.files = const [],
    this.language = 'eng',
    this.examIdText = '',
    this.courseIdText = '',
    this.submitExamIdText = '',
    this.submitStudentIdText = '',
    this.teacherFeedback = '',
    this.studentIdDigits = 6,
    this.loading = false,
    this.submitting = false,
    this.healthLoading = false,
    this.error,
    this.submitMessage,
    this.healthError,
    this.health,
    this.response,
    this.pointsOverrides = const {},
    this.correctnessOverrides = const {},
  });

  int? get overrideSubmitExamId => _optionalPositiveInt(submitExamIdText);
  int? get overrideSubmitStudentUserId => _optionalPositiveInt(submitStudentIdText);
  int? get resolvedExamId => response?.exam.examId ?? overrideSubmitExamId;
  int? get resolvedStudentUserId => response?.student.userId ?? overrideSubmitStudentUserId;

  bool get canAnalyze => files.isNotEmpty && !loading && !submitting;
  bool get canSubmit {
    final scan = response;
    return scan != null &&
        !loading &&
        !submitting &&
        resolvedExamId != null &&
        resolvedStudentUserId != null &&
        scan.answers.any((answer) => answer.examQuestionId != null);
  }

  double effectivePointsFor(ExamScanAnswer answer) {
    return pointsOverrides[answer.reviewKey] ?? answer.pointsEarned ?? 0;
  }

  bool? effectiveCorrectnessFor(ExamScanAnswer answer) {
    return correctnessOverrides[answer.reviewKey] ?? answer.isCorrect;
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
    String? examIdText,
    String? courseIdText,
    String? submitExamIdText,
    String? submitStudentIdText,
    String? teacherFeedback,
    int? studentIdDigits,
    bool? loading,
    bool? submitting,
    bool? healthLoading,
    String? error,
    String? submitMessage,
    String? healthError,
    OcrHealthResponse? health,
    ExamScanAnalyzeResponse? response,
    Map<String, double>? pointsOverrides,
    Map<String, bool>? correctnessOverrides,
    bool clearError = false,
    bool clearSubmitMessage = false,
    bool clearHealthError = false,
    bool clearHealth = false,
    bool clearResponse = false,
    bool clearReviewOverrides = false,
  }) {
    return ExamCorrectionState(
      files: files ?? this.files,
      language: language ?? this.language,
      examIdText: examIdText ?? this.examIdText,
      courseIdText: courseIdText ?? this.courseIdText,
      submitExamIdText: submitExamIdText ?? this.submitExamIdText,
      submitStudentIdText: submitStudentIdText ?? this.submitStudentIdText,
      teacherFeedback: teacherFeedback ?? this.teacherFeedback,
      studentIdDigits: studentIdDigits ?? this.studentIdDigits,
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      healthLoading: healthLoading ?? this.healthLoading,
      error: clearError ? null : error ?? this.error,
      submitMessage: clearSubmitMessage ? null : submitMessage ?? this.submitMessage,
      healthError: clearHealthError ? null : healthError ?? this.healthError,
      health: clearHealth ? null : health ?? this.health,
      response: clearResponse ? null : response ?? this.response,
      pointsOverrides: clearReviewOverrides ? const {} : pointsOverrides ?? this.pointsOverrides,
      correctnessOverrides: clearReviewOverrides ? const {} : correctnessOverrides ?? this.correctnessOverrides,
    );
  }

  static int? _optionalPositiveInt(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }
}
