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
    return name.toLowerCase().endsWith('.pdf');
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
  final double? processingTimeSeconds;
  final int? attemptId;
  final String? attemptStatus;
  final bool aiGradingRequested;
  final String? aiRequestId;
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
    required this.processingTimeSeconds,
    required this.attemptId,
    required this.attemptStatus,
    required this.aiGradingRequested,
    required this.aiRequestId,
    required this.warnings,
  });

  bool get isOcrPreviewOnly {
    final version = exam.templateVersion.toLowerCase();
    final type = (exam.examType ?? '').toLowerCase();
    return version == 'ocr_only' || type == 'ocr_only' || gradePreview.totalScore <= 0;
  }

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
      processingTimeSeconds: _nullableDouble(json['processing_time_seconds']),
      attemptId: _nullableInt(json['attempt_id']),
      attemptStatus: json['attempt_status']?.toString(),
      aiGradingRequested: json['ai_grading_requested'] == true,
      aiRequestId: json['ai_request_id']?.toString(),
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
  final String? ocrText;
  final double? ocrConfidence;
  final int? wordCount;
  final List<String> warnings;

  const ExamScanPage({
    required this.pageNumber,
    required this.filename,
    required this.alignmentStatus,
    required this.alignmentConfidence,
    required this.qrDetected,
    required this.bubbleCount,
    required this.ocrText,
    required this.ocrConfidence,
    required this.wordCount,
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
      ocrText: json['ocr_text']?.toString(),
      ocrConfidence: _nullableDouble(json['ocr_confidence']),
      wordCount: _nullableInt(json['word_count']),
      warnings: ((json['warnings'] as List?) ?? const []).map((item) => item.toString()).toList(growable: false),
    );
  }
}

class ExamScanAnswer {
  final int? examQuestionId;
  final int questionNumber;
  final String type;
  final String? questionText;
  final List<Map<String, dynamic>> options;
  final String? correctAnswer;
  final dynamic expectedAnswer;
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
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.expectedAnswer,
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

  String get normalizedType => _normaliseQuestionType(type);
  bool get hasAiGrade => aiStatus == 'completed' || status == 'ai_graded' || aiScore != null;
  bool get isAiPending => aiStatus == 'pending' || aiStatus == 'sent';
  bool get shouldShowAiFeedback =>
      aiFeedback?.trim().isNotEmpty == true &&
      aiStatus != null &&
      aiStatus != 'skipped';
  bool get isWritten => normalizedType == 'essay' || normalizedType == 'short_answer';
  bool get isObjective => normalizedType == 'multiple_choice' || normalizedType == 'multi_select' || normalizedType == 'true_false';
  bool get needsReview => status == 'needs_review' || isAiPending || confidence < 45 || (isWritten && pointsEarned == null && !hasAiGrade);
  String get reviewKey => examQuestionId != null ? 'eq_$examQuestionId' : 'q_${questionNumber}_$normalizedType';
  String get typeLabel => _questionTypeLabel(normalizedType);

  String get displayQuestion => questionText?.trim().isNotEmpty == true ? questionText!.trim() : 'Question $questionNumber';

  List<int> get normalizedSelectedOptionIndices => _normaliseDetectedOptionIndices(this);
  List<int> get normalizedCorrectOptionIndices => _normaliseExpectedOptionIndices(expectedAnswer, normalizedType, options);

  String get displayCorrectAnswer {
    final fromExpected = _formatOptionIndices(normalizedCorrectOptionIndices, normalizedType, options);
    if (fromExpected.isNotEmpty) return fromExpected;
    final direct = correctAnswer?.trim();
    return direct == null || direct.isEmpty ? '—' : direct;
  }

  String get displayAnswer {
    if (isWritten) {
      final text = (answerText ?? '').trim();
      return text.isEmpty ? 'Not extracted from scan' : text;
    }
    final fromSelection = _formatOptionIndices(normalizedSelectedOptionIndices, normalizedType, options);
    if (fromSelection.isNotEmpty) return fromSelection;
    if (detectedAnswers.isNotEmpty) return detectedAnswers.join(', ');
    final direct = detectedAnswer?.trim();
    return direct == null || direct.isEmpty ? 'Not detected' : direct;
  }

  bool isOptionSelected(int index) => normalizedSelectedOptionIndices.contains(index);
  bool isOptionCorrect(int index) => normalizedCorrectOptionIndices.contains(index);

  factory ExamScanAnswer.fromJson(Map<String, dynamic> json) {
    return ExamScanAnswer(
      examQuestionId: _nullableInt(json['exam_question_id']),
      questionNumber: _asInt(json['question_number']),
      type: (json['type'] ?? '').toString(),
      questionText: json['question_text']?.toString(),
      options: ((json['options'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(growable: false),
      correctAnswer: json['correct_answer']?.toString(),
      expectedAnswer: json['expected_answer'],
      detectedAnswer: json['detected_answer']?.toString(),
      detectedAnswers: ((json['detected_answers'] as List?) ?? const []).map((item) => item.toString()).toList(growable: false),
      selectedOptionIndex: _nullableInt(json['selected_option_index']),
      selectedOptionIndices: (json['selected_option_indices'] as List?)?.map(_asInt).toList(growable: false),
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
  final double? percentageScore;
  final int gradedQuestions;
  final int correctCount;
  final int incorrectCount;
  final int unansweredCount;
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
    required this.percentageScore,
    required this.gradedQuestions,
    required this.correctCount,
    required this.incorrectCount,
    required this.unansweredCount,
    required this.autoGradableQuestions,
    required this.detectedQuestions,
    required this.writtenQuestions,
    required this.needsReview,
    required this.aiReady,
    required this.aiGraded,
    required this.aiPending,
  });

  factory ExamScanGradePreview.fromJson(Map<String, dynamic> json) {
    final score = _asDouble(json['score_so_far']);
    final total = _asDouble(json['total_score']);

    return ExamScanGradePreview(
      scoreSoFar: score,
      totalScore: total,
      percentageScore: _nullableDouble(json['percentage_score']) ?? (total > 0 ? (score / total) * 100 : null),
      gradedQuestions: _asInt(json['graded_questions']),
      correctCount: _asInt(json['correct_count']),
      incorrectCount: _asInt(json['incorrect_count']),
      unansweredCount: _asInt(json['unanswered_count']),
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

String _normaliseQuestionType(String value) {
  final text = value.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
  return switch (text) {
    'mcq' || 'single_choice' || 'choice' => 'multiple_choice',
    'multi_choice' || 'multiple_select' || 'checkbox' => 'multi_select',
    'tf' || 'truefalse' || 'true_or_false' => 'true_false',
    'written' || 'text' || 'free_text' => 'essay',
    _ => text,
  };
}

String _questionTypeLabel(String type) {
  return switch (type) {
    'multiple_choice' => 'Multiple choice',
    'multi_select' => 'Multi select',
    'true_false' => 'True / False',
    'short_answer' => 'Short answer',
    'essay' => 'Essay',
    _ => type.replaceAll('_', ' ').trim().isEmpty ? 'Question' : type.replaceAll('_', ' '),
  };
}

List<int> _normaliseDetectedOptionIndices(ExamScanAnswer answer) {
  final type = answer.normalizedType;
  final indices = <int>[];
  void add(dynamic value) {
    final index = _optionIndexFromValue(value, type, answer.options);
    if (index != null && !indices.contains(index)) indices.add(index);
  }

  for (final value in answer.detectedAnswers) {
    add(value);
  }
  final many = answer.selectedOptionIndices;
  if (many != null) {
    for (final value in many) {
      add(value);
    }
  }
  add(answer.detectedAnswer);
  add(answer.selectedOptionIndex);
  indices.sort();
  return indices;
}

List<int> _normaliseExpectedOptionIndices(dynamic raw, String type, List<Map<String, dynamic>> options) {
  final values = <dynamic>[];

  void collect(dynamic value) {
    if (value == null) return;
    if (value is Map) {
      final map = value.cast<dynamic, dynamic>();
      for (final key in const [
        'answers',
        'correct_answers',
        'correct_option_indices',
        'correct_option_ids',
        'selected_option_indices',
      ]) {
        final nested = map[key];
        if (nested != null) {
          collect(nested);
          return;
        }
      }
      for (final key in const [
        'answer',
        'correct_answer',
        'expected_answer',
        'correct_option_index',
        'selected_option_index',
        'option_index',
        'value',
      ]) {
        final nested = map[key];
        if (nested != null) {
          collect(nested);
          return;
        }
      }
      return;
    }
    if (value is Iterable && value is! String) {
      for (final item in value) {
        collect(item);
      }
      return;
    }
    values.add(value);
  }

  collect(raw);
  final indices = <int>[];
  for (final value in values) {
    final index = _optionIndexFromValue(value, type, options);
    if (index != null && !indices.contains(index)) indices.add(index);
  }
  indices.sort();
  return indices;
}

int? _optionIndexFromValue(dynamic value, String type, List<Map<String, dynamic>> options) {
  if (value == null) return null;
  if (value is bool) {
    if (type == 'true_false') return value ? 0 : 1;
    return null;
  }
  if (value is int) return value >= 0 ? value : null;
  if (value is num) return value.toInt() >= 0 ? value.toInt() : null;

  final text = value.toString().trim();
  if (text.isEmpty) return null;
  final lower = text.toLowerCase();
  if (type == 'true_false') {
    if (lower == 'true' || lower == 't' || lower == 'yes') return 0;
    if (lower == 'false' || lower == 'f' || lower == 'no') return 1;
  }
  final asInt = int.tryParse(text);
  if (asInt != null && asInt >= 0) return asInt;
  if (text.length == 1) {
    final code = text.toUpperCase().codeUnitAt(0);
    if (code >= 65 && code <= 90) return code - 65;
  }

  for (var i = 0; i < options.length; i++) {
    final option = options[i];
    final label = option['label']?.toString().trim().toLowerCase();
    final optionText = option['text']?.toString().trim().toLowerCase();
    final valueText = option['value']?.toString().trim().toLowerCase();
    if (lower == label || lower == optionText || lower == valueText) return i;
  }
  return null;
}

String _formatOptionIndices(List<int> indices, String type, List<Map<String, dynamic>> options) {
  if (indices.isEmpty) return '';
  return indices.map((index) => _formatOptionIndex(index, type, options)).where((item) => item.trim().isNotEmpty).join(', ');
}

String _formatOptionIndex(int index, String type, List<Map<String, dynamic>> options) {
  if (type == 'true_false') return index == 0 ? 'True' : 'False';
  final label = _optionLabel(index, options);
  final text = index >= 0 && index < options.length ? (options[index]['text']?.toString().trim() ?? '') : '';
  return text.isEmpty ? label : '$label. $text';
}

String _optionLabel(int index, List<Map<String, dynamic>> options) {
  if (index >= 0 && index < options.length) {
    final label = options[index]['label']?.toString().trim();
    if (label != null && label.isNotEmpty) return label;
  }
  return index >= 0 && index < 26 ? String.fromCharCode(65 + index) : '${index + 1}';
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
