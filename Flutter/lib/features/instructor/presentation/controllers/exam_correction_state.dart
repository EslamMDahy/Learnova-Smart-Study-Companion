import '../../data/exam_correction_models.dart';

class ExamCorrectionState {
  final List<ExamCorrectionUploadFile> files;
  final String language;
  final bool loading;
  final String? error;
  final ExamScanAnalyzeResponse? response;

  const ExamCorrectionState({
    this.files = const [],
    this.language = 'eng',
    this.loading = false,
    this.error,
    this.response,
  });

  bool get canAnalyze => files.isNotEmpty && !loading;

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
    bool clearError = false,
    bool clearResponse = false,
  }) {
    return ExamCorrectionState(
      files: files ?? this.files,
      language: language ?? this.language,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      response: clearResponse ? null : response ?? this.response,
    );
  }
}
