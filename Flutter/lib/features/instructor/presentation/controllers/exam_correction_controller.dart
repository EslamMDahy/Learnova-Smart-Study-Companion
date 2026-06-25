import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/error_mapper.dart';
import '../../../../core/utils/browser_file_picker.dart';
import '../../data/exam_correction_models.dart';
import '../../data/exam_correction_providers.dart';
import 'exam_correction_state.dart';

final examCorrectionControllerProvider = StateNotifierProvider.autoDispose<
    ExamCorrectionController, ExamCorrectionState>(
  (ref) => ExamCorrectionController(ref),
);

class ExamCorrectionController extends StateNotifier<ExamCorrectionState> {
  ExamCorrectionController(this._ref) : super(const ExamCorrectionState());

  static const int _maxFileBytes = 30 * 1024 * 1024;

  final Ref _ref;
  CancelToken? _cancel;
  Timer? _pollTimer;

  Future<void> pickFiles() async {
    final picked = await pickBrowserFiles(
      acceptedExtensions: const ['.pdf'],
      multiple: false,
    );

    if (picked.isEmpty) return;

    final file = picked.first;
    final upload = ExamCorrectionUploadFile(
      name: file.name,
      mimeType: file.mimeType,
      sizeBytes: file.sizeBytes,
      bytes: file.bytes,
    );

    String? error;
    if (!upload.isSupported) {
      error = '${file.name}: only PDF files are supported';
    } else if (upload.sizeBytes > _maxFileBytes) {
      error = '${file.name}: file is larger than 30 MB';
    }

    state = state.copyWith(
      files: error == null ? List.unmodifiable([upload]) : const [],
      error: error,
      clearError: error == null,
      clearResponse: true,
    );
  }

  void removeFile(int index) {
    if (index < 0 || index >= state.files.length) return;
    state = state.copyWith(
      files: const [],
      clearError: true,
      clearResponse: true,
    );
  }

  void clearFiles() {
    _cancel?.cancel();
    state = state.copyWith(
      files: const [],
      loading: false,
      clearError: true,
      clearResponse: true,
    );
  }

  Future<void> analyzeScan() async {
    if (!state.canAnalyze) return;

    _cancel?.cancel();
    _cancel = CancelToken();
    state = state.copyWith(
      loading: true,
      clearError: true,
      clearResponse: true,
    );

    try {
      final response = await _ref.read(examCorrectionApiProvider).analyzeExamScan(
            files: state.files,
            language: state.language,
            cancelToken: _cancel,
          );
      state = state.copyWith(loading: false, response: response, clearError: true);
      _startPollingAttemptResult(response);
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      final failure = mapApiFailure(e);
      state = state.copyWith(
        loading: false,
        error: _friendlyOcrMessage(failure.message),
      );
    }
  }


  void _startPollingAttemptResult(ExamScanAnalyzeResponse response) {
    _pollTimer?.cancel();
    final attemptId = response.attemptId;
    if (attemptId == null || !response.aiGradingRequested) return;

    var ticks = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      ticks += 1;
      if (ticks > 20) {
        timer.cancel();
        return;
      }
      try {
        final updated = await _ref.read(examCorrectionApiProvider).getExamScanAttemptResult(
              attemptId: attemptId,
            );
        state = state.copyWith(response: updated, clearError: true);
        final status = updated.status.toLowerCase();
        final pending = updated.gradePreview.aiPending > 0;
        if (status == 'graded' || !pending) {
          timer.cancel();
        }
      } catch (_) {
        // Keep the extracted OCR result visible; polling failures should not hide it.
      }
    });
  }

  String _friendlyOcrMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('tesseract')) {
      return 'OCR engine unavailable on the backend: Tesseract is not installed or not available in PATH.';
    }
    if (lower.contains('service unavailable') || lower.contains('503')) {
      return 'OCR service is unavailable right now. Please try again after the backend OCR service is ready.';
    }
    return message;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cancel?.cancel();
    super.dispose();
  }
}
