import 'dart:typed_data';

class ExamCorrectionUploadFile {
  final String name;
  final String mimeType;
  final int sizeBytes;
  final Uint8List bytes;

  const ExamCorrectionUploadFile({
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    required this.bytes,
  });

  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return 'FILE';
    return name.substring(dot + 1).toUpperCase();
  }

  String get displaySize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1048576) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / 1048576).toStringAsFixed(1)} MB';
  }

  bool get isSupported {
    final lower = name.toLowerCase();
    return lower.endsWith('.pdf') ||
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.tif') ||
        lower.endsWith('.tiff') ||
        lower.endsWith('.bmp');
  }
}

class OcrHealthResponse {
  final bool available;
  final String engine;
  final String? version;
  final List<String> languages;
  final String? detail;

  const OcrHealthResponse({
    required this.available,
    required this.engine,
    required this.version,
    required this.languages,
    required this.detail,
  });

  factory OcrHealthResponse.fromJson(Map<String, dynamic> json) {
    return OcrHealthResponse(
      available: json['available'] == true,
      engine: (json['engine'] ?? 'tesseract').toString(),
      version: json['version']?.toString(),
      languages: ((json['languages'] as List?) ?? const []).map((item) => item.toString()).toList(growable: false),
      detail: json['detail']?.toString(),
    );
  }
}

class ExamScanAnalyzeResponse {
  final String scanId;
  final String status;
  final String language;
  final ExamScanExam exam;
  final ExamScanStudent student;
  final List<ExamScanPage> pages;
  final List<ExamScanAnswer> answers;
  final ExamScanGradePreview gradePreview;
  final List<String> warnings;

  const ExamScanAnalyzeResponse({
    required this.scanId,
    required this.status,
    required this.language,
    required this.exam,
    required this.student,
    required this.pages,
    required this.answers,
    required this.gradePreview,
    required this.warnings,
  });

  factory ExamScanAnalyzeResponse.fromJson(Map<String, dynamic> json) {
    return ExamScanAnalyzeResponse(
      scanId: (json['scan_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      language: (json['language'] ?? '').toString(),
      exam: ExamScanExam.fromJson((json['exam'] as Map?)?.cast<String, dynamic>() ?? const {}),
      student: ExamScanStudent.fromJson((json['student'] as Map?)?.cast<String, dynamic>() ?? const {}),
      pages: ((json['pages'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => ExamScanPage.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
      answers: ((json['answers'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => ExamScanAnswer.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
      gradePreview: ExamScanGradePreview.fromJson((json['grade_preview'] as Map?)?.cast<String, dynamic>() ?? const {}),
      warnings: ((json['warnings'] as List?) ?? const []).map((item) => item.toString()).toList(growable: false),
    );
  }
}

class ExamScanExam {
  final int? examId;
  final int? courseId;
  final String? title;
  final String? examType;
  final String templateVersion;

  const ExamScanExam({this.examId, this.courseId, this.title, this.examType, required this.templateVersion});

  factory ExamScanExam.fromJson(Map<String, dynamic> json) {
    return ExamScanExam(
      examId: _nullableInt(json['exam_id']),
      courseId: _nullableInt(json['course_id']),
      title: json['title']?.toString(),
      examType: json['exam_type']?.toString(),
      templateVersion: (json['template_version'] ?? 'v1').toString(),
    );
  }
}

class ExamScanStudent {
  final String? studentId;
  final int? userId;
  final String? name;
  final String source;
  final double confidence;
  final List<Map<String, dynamic>> digits;

  const ExamScanStudent({
    this.studentId,
    this.userId,
    this.name,
    required this.source,
    required this.confidence,
    required this.digits,
  });

  factory ExamScanStudent.fromJson(Map<String, dynamic> json) {
    return ExamScanStudent(
      studentId: json['student_id']?.toString(),
      userId: _nullableInt(json['user_id']),
      name: json['name']?.toString(),
      source: (json['source'] ?? 'id_bubbles').toString(),
      confidence: _asDouble(json['confidence']),
      digits: ((json['digits'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(growable: false),
    );
  }
}

class ExamScanPage {
  final int pageNumber;
  final String filename;
  final String alignmentStatus;
  final double alignmentConfidence;
  final bool qrDetected;
  final int bubbleCount;
  final List<String> warnings;

  const ExamScanPage({
    required this.pageNumber,
    required this.filename,
    required this.alignmentStatus,
    required this.alignmentConfidence,
    required this.qrDetected,
    required this.bubbleCount,
    required this.warnings,
  });

  factory ExamScanPage.fromJson(Map<String, dynamic> json) {
    return ExamScanPage(
      pageNumber: _asInt(json['page_number']),
      filename: (json['filename'] ?? '').toString(),
      alignmentStatus: (json['alignment_status'] ?? '').toString(),
      alignmentConfidence: _asDouble(json['alignment_confidence']),
      qrDetected: json['qr_detected'] == true,
      bubbleCount: _asInt(json['bubble_count']),
      warnings: ((json['warnings'] as List?) ?? const []).map((item) => item.toString()).toList(growable: false),
    );
  }
}

class ExamScanAnswer {
  final int? examQuestionId;
  final int questionNumber;
  final String type;
  final String? detectedAnswer;
  final List<String> detectedAnswers;
  final int? selectedOptionIndex;
  final List<int>? selectedOptionIndices;
  final String? answerText;
  final double confidence;
  final String status;
  final bool? isCorrect;
  final double? pointsEarned;
  final double? maxScore;
  final List<Map<String, dynamic>> regions;
  final Map<String, dynamic>? answerRegion;
  final Map<String, dynamic>? aiGradingPayload;
  final double? aiScore;
  final String? aiStatus;
  final String? aiFeedback;
  final String? aiRequestId;

  const ExamScanAnswer({
    required this.examQuestionId,
    required this.questionNumber,
    required this.type,
    required this.detectedAnswer,
    required this.detectedAnswers,
    required this.selectedOptionIndex,
    required this.selectedOptionIndices,
    required this.answerText,
    required this.confidence,
    required this.status,
    required this.isCorrect,
    required this.pointsEarned,
    required this.maxScore,
    required this.regions,
    required this.answerRegion,
    required this.aiGradingPayload,
    required this.aiScore,
    required this.aiStatus,
    required this.aiFeedback,
    required this.aiRequestId,
  });

  bool get hasAiGrade => aiStatus == 'completed' || status == 'ai_graded' || aiScore != null;
  bool get isAiPending => aiStatus == 'pending' || aiStatus == 'sent';
  bool get needsReview => status == 'needs_review' || isAiPending || confidence < 45 || (isWritten && pointsEarned == null && !hasAiGrade);
  bool get isWritten => type == 'essay' || type == 'short_answer';
  String get reviewKey => examQuestionId != null ? 'eq_$examQuestionId' : 'q_${questionNumber}_$type';
  String get typeLabel => type.replaceAll('_', ' ');

  String get displayAnswer {
    if (isWritten) return (answerText ?? '').trim().isEmpty ? 'No text extracted' : answerText!.trim();
    if (detectedAnswers.isNotEmpty) return detectedAnswers.join(', ');
    return detectedAnswer ?? '—';
  }

  factory ExamScanAnswer.fromJson(Map<String, dynamic> json) {
    return ExamScanAnswer(
      examQuestionId: _nullableInt(json['exam_question_id']),
      questionNumber: _asInt(json['question_number']),
      type: (json['type'] ?? '').toString(),
      detectedAnswer: json['detected_answer']?.toString(),
      detectedAnswers: ((json['detected_answers'] as List?) ?? const []).map((item) => item.toString()).toList(growable: false),
      selectedOptionIndex: _nullableInt(json['selected_option_index']),
      selectedOptionIndices: (json['selected_option_indices'] as List?)?.map((item) => _asInt(item)).toList(growable: false),
      answerText: json['answer_text']?.toString(),
      confidence: _asDouble(json['confidence']),
      status: (json['status'] ?? '').toString(),
      isCorrect: json['is_correct'] is bool ? json['is_correct'] as bool : null,
      pointsEarned: _nullableDouble(json['points_earned']),
      maxScore: _nullableDouble(json['max_score']),
      regions: ((json['regions'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(growable: false),
      answerRegion: (json['answer_region'] as Map?)?.cast<String, dynamic>(),
      aiGradingPayload: (json['ai_grading_payload'] as Map?)?.cast<String, dynamic>(),
      aiScore: _nullableDouble(json['ai_score']),
      aiStatus: json['ai_status']?.toString(),
      aiFeedback: json['ai_feedback']?.toString(),
      aiRequestId: json['ai_request_id']?.toString(),
    );
  }

  Map<String, dynamic> toSubmitJson({
    bool? isCorrectOverride,
    double? pointsEarnedOverride,
    String? teacherFeedback,
  }) {
    final effectiveCorrect = isCorrectOverride ?? isCorrect;
    final effectivePoints = pointsEarnedOverride ?? pointsEarned;
    final feedback = teacherFeedback?.trim();

    final aiGraded = isWritten && hasAiGrade && effectivePoints != null;
    return {
      'exam_question_id': examQuestionId,
      'type': type,
      'selected_option_index': selectedOptionIndex,
      'selected_option_indices': selectedOptionIndices,
      'answer_text': answerText,
      'is_correct': effectiveCorrect,
      'points_earned': effectivePoints,
      'auto_graded': (!isWritten && effectiveCorrect != null) || aiGraded,
      'teacher_feedback': feedback == null || feedback.isEmpty ? aiFeedback : feedback,
    }..removeWhere((key, value) => value == null);
  }
}

class ExamScanGradePreview {
  final double scoreSoFar;
  final double totalScore;
  final int autoGradableQuestions;
  final int detectedQuestions;
  final int writtenQuestions;
  final int needsReview;
  final int aiReady;
  final int aiGraded;
  final int aiPending;

  const ExamScanGradePreview({
    required this.scoreSoFar,
    required this.totalScore,
    required this.autoGradableQuestions,
    required this.detectedQuestions,
    required this.writtenQuestions,
    required this.needsReview,
    required this.aiReady,
    required this.aiGraded,
    required this.aiPending,
  });

  factory ExamScanGradePreview.fromJson(Map<String, dynamic> json) {
    return ExamScanGradePreview(
      scoreSoFar: _asDouble(json['score_so_far']),
      totalScore: _asDouble(json['total_score']),
      autoGradableQuestions: _asInt(json['auto_gradable_questions']),
      detectedQuestions: _asInt(json['detected_questions']),
      writtenQuestions: _asInt(json['written_questions']),
      needsReview: _asInt(json['needs_review']),
      aiReady: _asInt(json['ai_ready']),
      aiGraded: _asInt(json['ai_graded']),
      aiPending: _asInt(json['ai_pending']),
    );
  }
}

class ExamScanSubmitResponse {
  final int attemptId;
  final int examId;
  final int studentId;
  final int answerCount;
  final String status;
  final bool aiGradingRequested;
  final String? aiRequestId;
  final String? aiError;

  const ExamScanSubmitResponse({
    required this.attemptId,
    required this.examId,
    required this.studentId,
    required this.answerCount,
    required this.status,
    required this.aiGradingRequested,
    required this.aiRequestId,
    required this.aiError,
  });

  factory ExamScanSubmitResponse.fromJson(Map<String, dynamic> json) {
    return ExamScanSubmitResponse(
      attemptId: _asInt(json['attempt_id']),
      examId: _asInt(json['exam_id']),
      studentId: _asInt(json['student_id']),
      answerCount: _asInt(json['answer_count']),
      status: (json['status'] ?? '').toString(),
      aiGradingRequested: json['ai_grading_requested'] == true,
      aiRequestId: json['ai_request_id']?.toString(),
      aiError: json['ai_error']?.toString(),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  final parsed = _asInt(value);
  return parsed == 0 && value.toString() != '0' ? null : parsed;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _nullableDouble(dynamic value) {
  if (value == null) return null;
  return _asDouble(value);
}
