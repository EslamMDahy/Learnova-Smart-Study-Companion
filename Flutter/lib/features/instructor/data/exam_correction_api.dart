import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import 'exam_correction_models.dart';

class ExamCorrectionApi {
  final ApiClient _client;

  ExamCorrectionApi(this._client);

  Future<OcrHealthResponse> getOcrHealth({CancelToken? cancelToken}) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.ocrHealth,
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return OcrHealthResponse.fromJson(data);
    }
    throw const FormatException('Invalid response from OCR health endpoint.');
  }

  Future<ExamScanAnalyzeResponse> analyzeExamScan({
    required List<ExamCorrectionUploadFile> files,
    required String language,
    int? courseId,
    int? examId,
    CancelToken? cancelToken,
  }) async {
    if (files.isEmpty) {
      throw ArgumentError('Select one exam PDF.');
    }

    final form = FormData();
    for (final file in files) {
      form.files.add(
        MapEntry(
          'files',
          MultipartFile.fromBytes(
            file.bytes,
            filename: file.name.isNotEmpty ? file.name : 'exam.pdf',
          ),
        ),
      );
    }
    form.fields.add(MapEntry('lang', language));
    if (courseId != null) {
      form.fields.add(MapEntry('course_id', courseId.toString()));
    }
    if (examId != null) {
      form.fields.add(MapEntry('exam_id', examId.toString()));
    }

    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.examScanAnalyze,
      data: form,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(minutes: 10),
      ),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return ExamScanAnalyzeResponse.fromJson(data);
    }
    throw const FormatException('Invalid response from exam scan analyzer.');
  }


  Future<ExamScanAnalyzeResponse> getExamScanAttemptResult({
    required int attemptId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.examScanAttemptResult(attemptId),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return ExamScanAnalyzeResponse.fromJson(data);
    }
    throw const FormatException('Invalid response from exam scan result endpoint.');
  }

  Future<ExamScanSubmitResponse> submitExamScan({
    required ExamScanAnalyzeResponse scan,
    required int examId,
    int? studentUserId,
    Map<String, double> pointsOverrides = const {},
    Map<String, bool> correctnessOverrides = const {},
    String? teacherFeedback,
    CancelToken? cancelToken,
  }) async {
    final answers = scan.answers.where((answer) => answer.examQuestionId != null).toList(growable: false);
    final totalScore = answers.fold<double>(
      0,
      (sum, answer) => sum + (pointsOverrides[answer.reviewKey] ?? answer.pointsEarned ?? 0),
    );
    final percentage = scan.gradePreview.totalScore > 0 ? (totalScore / scan.gradePreview.totalScore) * 100 : null;
    final cleanFeedback = teacherFeedback?.trim();

    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.examScanSubmit,
      data: {
        'scan_id': scan.scanId,
        'exam_id': examId,
        if (studentUserId != null) 'student_id': studentUserId,
        'answers': answers
            .map(
              (answer) => answer.toSubmitJson(
                isCorrectOverride: correctnessOverrides[answer.reviewKey],
                pointsEarnedOverride: pointsOverrides[answer.reviewKey],
              ),
            )
            .toList(growable: false),
        'total_score': totalScore,
        'percentage_score': percentage,
        'teacher_feedback': cleanFeedback == null || cleanFeedback.isEmpty ? null : cleanFeedback,
      }..removeWhere((key, value) => value == null),
      options: Options(
        sendTimeout: const Duration(minutes: 1),
        receiveTimeout: const Duration(minutes: 2),
      ),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return ExamScanSubmitResponse.fromJson(data);
    }
    throw const FormatException('Invalid response from exam scan submit endpoint.');
  }
}
