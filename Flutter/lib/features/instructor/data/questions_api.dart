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

  factory CourseQuestionsResponse.fromJson(Map<String, dynamic> json) {
    final raw = (json['questions'] as List?) ?? const [];
    return CourseQuestionsResponse(
      courseId: (json['course_id'] as num?)?.toInt() ?? 0,
      questions: raw
          .whereType<Map>()
          .map((e) => QuestionModel.fromJson(Map<String, dynamic>.from(e)))
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


class _MCQChoice {
  final String id;   // numeric option id as string: "0", "1", "2", ...
  final String text;

  const _MCQChoice({required this.id, required this.text});

  Map<String, dynamic> toJson() => {'id': id, 'text': text};
}

class _MCQOptions {
  final List<_MCQChoice> choices;
  const _MCQOptions({required this.choices});
  Map<String, dynamic> toJson() => {
        'choices': choices.map((c) => c.toJson()).toList(),
      };
}

class _QuestionMCQCreate {
  final String questionText;
  final _MCQOptions options;
  final String expectedAnswer; // numeric choice id as string, e.g. "1"
  final String? explanation;
  final String? difficulty; // "easy"|"medium"|"hard"|null

  const _QuestionMCQCreate({
    required this.questionText,
    required this.options,
    required this.expectedAnswer,
    this.explanation,
    this.difficulty,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'question_text': questionText,
      'options': options.toJson(),
      'expected_answer': expectedAnswer,
    };
    if (explanation != null && explanation!.isNotEmpty) {
      m['explanation'] = explanation;
    }
    if (difficulty != null) m['difficulty'] = difficulty;
    return m;
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

class AiQuestionGenerationStatusResponse {
  final String requestId;
  final String status;
  final bool aiProcessingStarted;
  final bool callbackReceived;
  final bool completed;
  final bool failed;
  final bool expired;
  final int insertedCount;
  final List<int> questionIds;
  final String? message;
  final String? errorMessage;

  const AiQuestionGenerationStatusResponse({
    required this.requestId,
    required this.status,
    required this.aiProcessingStarted,
    required this.callbackReceived,
    required this.completed,
    required this.failed,
    required this.expired,
    required this.insertedCount,
    required this.questionIds,
    this.message,
    this.errorMessage,
  });

  factory AiQuestionGenerationStatusResponse.fromJson(Map<String,dynamic> j) {
    final rawIds = (j['question_ids'] as List?) ?? const <dynamic>[];
    return AiQuestionGenerationStatusResponse(
      requestId: (j['request_id'] ?? '').toString(),
      status: (j['status'] ?? '').toString(),
      aiProcessingStarted: j['ai_processing_started'] == true,
      callbackReceived: j['callback_received'] == true,
      completed: j['completed'] == true,
      failed: j['failed'] == true,
      expired: j['expired'] == true,
      insertedCount: (j['inserted_count'] as num?)?.toInt() ?? 0,
      questionIds: rawIds
          .map((dynamic value) => value is num ? value.toInt() : int.tryParse(value.toString()))
          .whereType<int>()
          .toList(),
      message: j['message']?.toString(),
      errorMessage: j['error_message']?.toString(),
    );
  }
}

class QuestionsApi {
  final ApiClient _client;
  QuestionsApi(this._client);

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

  Future<AiQuestionGenerationStatusResponse> getAiGenerationStatus({
    required int courseId,
    required String requestId,
    bool waitForCallback = false,
    int timeoutSeconds = 600,
    CancelToken? cancelToken,
  }) async {
    final int safeTimeoutSeconds = timeoutSeconds.clamp(1, 900).toInt();
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.aiGenerateQuestionsStatus(courseId, requestId),
      queryParameters: waitForCallback
          ? <String, dynamic>{
              'wait': true,
              'timeout_seconds': safeTimeoutSeconds,
            }
          : null,
      options: waitForCallback
          ? Options(
              receiveTimeout: Duration(seconds: safeTimeoutSeconds + 30),
              sendTimeout: const Duration(seconds: 30),
              extra: const <String, dynamic>{'silent': true},
            )
          : null,
      cancelToken: cancelToken,
    );
    return AiQuestionGenerationStatusResponse.fromJson(
      Map<String, dynamic>.from(res.data ?? const {}),
    );
  }



  Future<CourseQuestionsResponse> getCourseQuestions({
    required int courseId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.courseQuestions(courseId),
      cancelToken: cancelToken,
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return CourseQuestionsResponse.fromJson(data);
    }
    throw const FormatException('Invalid response from GET /courses/{id}/questions');
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

  _QuestionMCQCreate? _buildMCQPayload(QuestionModel q) {
    if (q.options.isEmpty) return null;

    // Map options to backend numeric ids because exam grading compares
    // selected_option_index against expected_answer as strings.
    final choiceIds = List.generate(q.options.length, (i) => i.toString());

    final choices = List.generate(q.options.length, (i) {
      return _MCQChoice(id: choiceIds[i], text: q.options[i].text);
    });

    // Map the correct option id from app format to backend numeric id.
    // App may store correctOptionId like "opt_0", "0", "A" etc.
    String expectedAnswer = '0'; // fallback
    if (q.correctOptionId != null) {
      // Try to extract the index suffix from "opt_N"
      final suffix = q.correctOptionId!.replaceAll(RegExp(r'[^0-9]'), '');
      final idx = int.tryParse(suffix);
      if (idx != null && idx >= 0 && idx < choiceIds.length) {
        expectedAnswer = choiceIds[idx];
      } else {
        final normalizedId = q.correctOptionId!.trim().toUpperCase();
        if (normalizedId.isNotEmpty) {
          final letterIndex = normalizedId.codeUnitAt(0) - 'A'.codeUnitAt(0);
          if (letterIndex >= 0 && letterIndex < choiceIds.length) {
            expectedAnswer = choiceIds[letterIndex];
          }
        }
      }
    }

    final difficultyStr = q.difficulty.backendValue;

    return _QuestionMCQCreate(
      questionText: q.text,
      options: _MCQOptions(choices: choices),
      expectedAnswer: expectedAnswer,
      explanation: q.explanation,
      difficulty: difficultyStr,
    );
  }
}
