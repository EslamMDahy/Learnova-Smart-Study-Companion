// ─────────────────────────────────────────────────────────────────────────────
//  QuestionsApi — wires the batch-create endpoint to the Flutter layer.
//
//  Backend endpoint:
//    POST /courses/{course_id}/modules/{module_id}/materials/{material_id}/questions
//
//  Request body  → MaterialQuestionsBatchCreateRequest  (list of MCQ objects)
//  Response body → MaterialQuestionsBatchCreateResponse
// ─────────────────────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import 'question_models.dart';
import 'question_vocabulary.dart';

// ── Response models matching backend schema exactly ───────────────────────────

class QuestionCreatedItem {
  final int id;
  final String questionText;
  final String createdAt;

  const QuestionCreatedItem({
    required this.id,
    required this.questionText,
    required this.createdAt,
  });

  factory QuestionCreatedItem.fromJson(Map<String, dynamic> json) {
    return QuestionCreatedItem(
      id: (json['id'] as num).toInt(),
      questionText: (json['question_text'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class BatchCreateQuestionsResponse {
  final int courseId;
  final int moduleId;
  final int materialId;
  final int createdCount;
  final List<QuestionCreatedItem> questions;

  const BatchCreateQuestionsResponse({
    required this.courseId,
    required this.moduleId,
    required this.materialId,
    required this.createdCount,
    required this.questions,
  });

  factory BatchCreateQuestionsResponse.fromJson(Map<String, dynamic> json) {
    final raw = (json['questions'] as List?) ?? const [];
    return BatchCreateQuestionsResponse(
      courseId: (json['course_id'] as num).toInt(),
      moduleId: (json['module_id'] as num).toInt(),
      materialId: (json['material_id'] as num).toInt(),
      createdCount: (json['created_count'] as num?)?.toInt() ?? 0,
      questions: raw
          .whereType<Map>()
          .map((e) =>
              QuestionCreatedItem.fromJson(Map<String, dynamic>.from(e)),)
          .toList(),
    );
  }
}


class CourseQuestionsResponse {
  final int courseId;
  final List<QuestionModel> questions;

  const CourseQuestionsResponse({
    required this.courseId,
    required this.questions,
  });

  factory CourseQuestionsResponse.fromJson(
    Map<String, dynamic> json, {
    bool includeDetails = true,
  }) {
    final raw = (json['questions'] as List?) ?? const [];
    return CourseQuestionsResponse(
      courseId: (json['course_id'] as num?)?.toInt() ?? 0,
      questions: raw
          .whereType<Map>()
          .map((e) => QuestionModel.fromJson(
                Map<String, dynamic>.from(e),
                includeDetails: includeDetails,
              ))
          .toList(),
    );
  }
}

// ── Request model matching backend MCQ schema ─────────────────────────────────


class CreateQuestionOption {
  final String id;
  final String text;

  const CreateQuestionOption({required this.id, required this.text});

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
      };
}

class CreateQuestionPayload {
  final int topicId;
  final String questionText;
  final String type;
  final String difficulty;
  final String? explanation;
  final List<CreateQuestionOption>? options;
  final Object? expectedAnswer;
  final Object? gradingRubric;

  const CreateQuestionPayload({
    required this.topicId,
    required this.questionText,
    required this.type,
    required this.difficulty,
    this.explanation,
    this.options,
    this.expectedAnswer,
    this.gradingRubric,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'topic_id': topicId,
      'question_text': questionText,
      'type': type,
      'difficulty': difficulty,
    };
    if (explanation != null && explanation!.trim().isNotEmpty) {
      data['explanation'] = explanation!.trim();
    }
    if (options != null && options!.isNotEmpty) {
      data['options'] = options!.map((e) => e.toJson()).toList();
    }
    if (expectedAnswer != null) {
      data['expected_answer'] = expectedAnswer;
    }
    if (gradingRubric != null) {
      data['grading_rubric'] = gradingRubric;
    }
    return data;
  }
}


class UpdateQuestionPayload {
  final int? topicId;
  final String? questionText;
  final String? difficulty;
  final String? explanation;
  final List<CreateQuestionOption>? options;
  final Object? expectedAnswer;
  final Object? gradingRubric;
  final List<String>? tags;

  const UpdateQuestionPayload({
    this.topicId,
    this.questionText,
    this.difficulty,
    this.explanation,
    this.options,
    this.expectedAnswer,
    this.gradingRubric,
    this.tags,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (topicId != null) data['topic_id'] = topicId;
    if (questionText != null) data['question_text'] = questionText;
    if (difficulty != null) data['difficulty'] = difficulty;
    if (explanation != null) data['explanation'] = explanation;
    if (options != null) data['options'] = options!.map((e) => e.toJson()).toList();
    if (expectedAnswer != null) data['expected_answer'] = expectedAnswer;
    if (gradingRubric != null) data['grading_rubric'] = gradingRubric;
    if (tags != null) data['tags'] = tags;
    return data;
  }
}

// ─────────────────────────────────────────────────────────────────────────────



class AiQuestionGenerationConfig {
  final String type;
  final String difficulty;
  final int count;
  const AiQuestionGenerationConfig({required this.type, required this.difficulty, required this.count});
  Map<String,dynamic> toJson()=>{'type':type,'difficulty':difficulty,'count':count};
}
class AiQuestionGenerationTopic {
  final int topicId;
  final List<AiQuestionGenerationConfig> questionConfigs;
  const AiQuestionGenerationTopic({required this.topicId,required this.questionConfigs});
  Map<String,dynamic> toJson()=>{'topic_id':topicId,'question_configs':questionConfigs.map((e)=>e.toJson()).toList()};
}
class AiQuestionGenerationRequest {
  final List<AiQuestionGenerationTopic> topics;
  const AiQuestionGenerationRequest({required this.topics});
  Map<String,dynamic> toJson()=>{'topics':topics.map((e)=>e.toJson()).toList()};
}
class AiQuestionGenerationResponse {
  final String status;
  final bool aiProcessingStarted;
  final String? requestId;
  final String? message;
  const AiQuestionGenerationResponse({
    required this.status,
    required this.aiProcessingStarted,
    this.requestId,
    this.message,
  });
  factory AiQuestionGenerationResponse.fromJson(Map<String,dynamic> j)=>AiQuestionGenerationResponse(
    status:(j['status']??'').toString(),
    aiProcessingStarted:j['ai_processing_started']==true,
    requestId:j['request_id']?.toString(),
    message:j['message']?.toString(),
  );
}


class ExtractNativeQuestionsResponse {
  final String status;
  final bool aiProcessingStarted;
  final String message;

  const ExtractNativeQuestionsResponse({
    required this.status,
    required this.aiProcessingStarted,
    required this.message,
  });

  factory ExtractNativeQuestionsResponse.fromJson(Map<String, dynamic> json) {
    return ExtractNativeQuestionsResponse(
      status: (json['status'] ?? '').toString(),
      aiProcessingStarted: json['ai_processing_started'] == true,
      message: (json['message'] ?? '').toString(),
    );
  }
}

class QuestionsApi {
  final ApiClient _client;
  QuestionsApi(this._client);

  // Native question extraction is intentionally disabled for the material
  // upload flow. Uploaded materials should stop after topic extraction and
  // must not call /questions/extract-native or its SSE stream automatically.
  // Keep these API methods as safe no-ops so any older UI path or leftover
  // caller cannot accidentally trigger backend AI extraction.
  static const bool _nativeMaterialQuestionExtractionEnabled = false;

  Future<AiQuestionGenerationResponse> generateQuestions({
    required int courseId,
    required AiQuestionGenerationRequest payload,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.post<Map<String,dynamic>>(
      Endpoints.aiGenerateQuestions(courseId),
      data: payload.toJson(),
      cancelToken: cancelToken,
    );
    return AiQuestionGenerationResponse.fromJson(
      Map<String,dynamic>.from(res.data ?? const {}),
    );
  }



  Future<SseEvent> waitForQuestionGeneration({
    required int courseId,
    CancelToken? cancelToken,
  }) {
    return _client.waitForSseEvent(
      Endpoints.aiQuestionGenerationStream(courseId),
      cancelToken: cancelToken,
      receiveTimeout: const Duration(minutes: 8),
    );
  }

  Future<ExtractNativeQuestionsResponse> extractNativeQuestionsFromMaterial({
    required int courseId,
    required int materialId,
    CancelToken? cancelToken,
  }) async {
    if (!_nativeMaterialQuestionExtractionEnabled) {
      return const ExtractNativeQuestionsResponse(
        status: 'disabled',
        aiProcessingStarted: false,
        message: 'Native question extraction is disabled after material upload.',
      );
    }

    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.extractNativeMaterialQuestions(courseId, materialId),
      data: const <String, dynamic>{},
      cancelToken: cancelToken,
    );
    return ExtractNativeQuestionsResponse.fromJson(
      Map<String, dynamic>.from(res.data ?? const <String, dynamic>{}),
    );
  }

  Future<SseEvent> waitForNativeQuestionExtraction({
    required int courseId,
    required int materialId,
    CancelToken? cancelToken,
  }) {
    if (!_nativeMaterialQuestionExtractionEnabled) {
      return Future<SseEvent>.value(
        const SseEvent(
          event: 'disabled',
          data: 'Native question extraction is disabled after material upload.',
          jsonData: <String, dynamic>{
            'status': 'disabled',
            'message': 'Native question extraction is disabled after material upload.',
          },
        ),
      );
    }

    return _client.waitForSseEvent(
      Endpoints.extractNativeMaterialQuestionsStream(courseId, materialId),
      cancelToken: cancelToken,
      receiveTimeout: const Duration(minutes: 8),
    );
  }



  Future<CourseQuestionsResponse> getCourseQuestions({
    required int courseId,
    CancelToken? cancelToken,
    bool summaryOnly = false,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.courseQuestions(courseId),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return CourseQuestionsResponse.fromJson(
        data,
        includeDetails: !summaryOnly,
      );
    }
    throw const FormatException('Invalid response from GET /courses/{id}/questions');
  }

  Future<CourseQuestionsResponse> getModuleQuestions({
    required int courseId,
    required int moduleId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.moduleQuestions(courseId, moduleId),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return CourseQuestionsResponse.fromJson(data);
    }
    throw const FormatException('Invalid response from GET /courses/{id}/modules/{moduleId}/questions');
  }

  Future<CourseQuestionsResponse> getMaterialQuestions({
    required int courseId,
    required int moduleId,
    required int materialId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.materialQuestions(courseId, moduleId, materialId),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return CourseQuestionsResponse.fromJson(data);
    }
    throw const FormatException('Invalid response from GET /courses/{id}/modules/{moduleId}/materials/{materialId}/questions');
  }

  Future<CourseQuestionsResponse> getTopicQuestions({
    required int courseId,
    required int moduleId,
    required int materialId,
    required int topicId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.topicQuestions(courseId, moduleId, materialId, topicId),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return CourseQuestionsResponse.fromJson(data);
    }
    throw const FormatException('Invalid response from GET /courses/{id}/modules/{moduleId}/materials/{materialId}/topics/{topicId}/questions');
  }



  Future<QuestionModel> getQuestion({
    required int courseId,
    required int questionId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.courseQuestion(courseId, questionId),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return QuestionModel.fromJson(data);
    }
    throw const FormatException('Invalid response from GET /courses/{id}/questions/{questionId}');
  }

  Future<QuestionModel> createQuestion({
    required int courseId,
    required CreateQuestionPayload payload,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.courseQuestions(courseId),
      data: payload.toJson(),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return QuestionModel.fromJson(data);
    }
    throw const FormatException('Invalid response from POST /courses/{id}/questions');
  }


  Future<QuestionModel> updateQuestion({
    required int courseId,
    required int questionId,
    required UpdateQuestionPayload payload,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.patch<Map<String, dynamic>>(
      Endpoints.updateCourseQuestion(courseId, questionId),
      data: payload.toJson(),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return QuestionModel.fromJson(data);
    }
    throw const FormatException('Invalid response from PATCH /courses/{id}/questions/{questionId}/update');
  }

  /// Compatibility helper for controller/UI flows that still pass a QuestionModel.
  Future<QuestionModel> createQuestionFromModel({
    required int courseId,
    required QuestionModel question,
    CancelToken? cancelToken,
  }) async {
    final payload = buildCreatePayloadFromQuestion(question);
    if (payload == null) {
      throw ArgumentError(
        'Question is not compatible with the backend create-question contract. '
        'Make sure it has a topicId and valid type-specific answer data.',
      );
    }

    return createQuestion(
      courseId: courseId,
      payload: payload,
      cancelToken: cancelToken,
    );
  }

  /// Creates questions using the currently implemented backend contract:
  /// `POST /courses/{courseId}/questions`.
  ///
  /// The older material-scoped batch endpoint is not implemented in the backend,
  /// so this method now submits the compatible questions one by one and returns
  /// a batch-shaped response for the existing Flutter flow.
  Future<BatchCreateQuestionsResponse> batchCreateQuestions({
    required int courseId,
    required int moduleId,
    required int materialId,
    required List<QuestionModel> questions,
    CancelToken? cancelToken,
  }) async {
    final compatibleQuestions = questions
        .where((q) => q.topicId != null)
        .where((q) => {
              QuestionType.multipleChoice,
              QuestionType.multiSelect,
              QuestionType.trueFalse,
              QuestionType.shortAnswer,
              QuestionType.essay,
            }.contains(q.type),)
        .toList();

    if (compatibleQuestions.isEmpty) {
      throw ArgumentError(
        'No valid backend-supported questions with topicId to submit to the backend.',
      );
    }

    final createdItems = <QuestionCreatedItem>[];

    for (final question in compatibleQuestions) {
      final payload = _buildCreatePayload(question);
      if (payload == null) continue;

      final created = await createQuestion(
        courseId: courseId,
        payload: payload,
        cancelToken: cancelToken,
      );

      createdItems.add(
        QuestionCreatedItem(
          id: created.remoteId ?? int.tryParse(created.id) ?? 0,
          questionText: created.text,
          createdAt: created.createdAt.toIso8601String(),
        ),
      );
    }

    return BatchCreateQuestionsResponse(
      courseId: courseId,
      moduleId: moduleId,
      materialId: materialId,
      createdCount: createdItems.length,
      questions: createdItems,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  CreateQuestionPayload? buildCreatePayloadFromQuestion(QuestionModel q) {
    final topicId = q.topicId;
    if (topicId == null) return null;

    if (q.type == QuestionType.multipleChoice || q.type == QuestionType.multiSelect) {
      if (q.options.length < 2) return null;
      final ids = List.generate(q.options.length, (i) => i.toString());
      final options = List.generate(q.options.length, (i) {
        return CreateQuestionOption(id: ids[i], text: q.options[i].text);
      });
      final correctIds = <String>[];
      for (var i = 0; i < q.options.length; i++) {
        final option = q.options[i];
        if (option.isCorrect || option.id == q.correctOptionId) {
          correctIds.add(ids[i]);
        }
      }
      if (correctIds.isEmpty) correctIds.add(ids.first);

      return CreateQuestionPayload(
        topicId: topicId,
        questionText: q.text,
        type: q.type.backendValue,
        difficulty: q.difficulty.backendValue,
        explanation: q.explanation,
        options: options,
        expectedAnswer: q.type == QuestionType.multiSelect ? correctIds : correctIds.first,
      );
    }

    if (q.type == QuestionType.trueFalse) {
      return CreateQuestionPayload(
        topicId: topicId,
        questionText: q.text,
        type: q.type.backendValue,
        difficulty: q.difficulty.backendValue,
        explanation: q.explanation,
        expectedAnswer: (q.correctBool ?? false).toString(),
      );
    }

    if (q.type == QuestionType.shortAnswer || q.type == QuestionType.essay) {
      final answer = q.sampleAnswer ?? q.expectedAnswer;
      return CreateQuestionPayload(
        topicId: topicId,
        questionText: q.text,
        type: q.type.backendValue,
        difficulty: q.difficulty.backendValue,
        explanation: q.explanation,
        expectedAnswer: answer,
      );
    }

    return null;
  }

  CreateQuestionPayload? _buildCreatePayload(QuestionModel q) =>
      buildCreatePayloadFromQuestion(q);

}
