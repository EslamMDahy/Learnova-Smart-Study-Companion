import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import 'student_course_assistant_models.dart';

class StudentCourseAssistantApi {
  final ApiClient _client;

  const StudentCourseAssistantApi(this._client);

  /// Creates a new AI-chat session with the first user message only.
  ///
  /// Backend:
  /// POST /courses/{courseId}/ai-chat/sessions
  /// body: { "content": "..." }
  /// returns: { session, message } where message is the saved pending user message.
  Future<StudentCourseAssistantCreateSessionResponse> createSession({
    required int courseId,
    required String message,
    CancelToken? cancelToken,
  }) async {
    _validateCourseId(courseId);
    final data = _messagePayload(message);

    final res = await _client.post<dynamic>(
      Endpoints.aiChatSessions(courseId),
      data: data,
      cancelToken: cancelToken,
    );

    return StudentCourseAssistantCreateSessionResponse.fromJson(
      _responseMap(res.data, 'Invalid create session response'),
    );
  }

  /// Lists the current user's saved AI-chat sessions for this course.
  ///
  /// Backend:
  /// GET /courses/{courseId}/ai-chat/sessions
  Future<StudentCourseAssistantSessionListResponse> listSessions({
    required int courseId,
    CancelToken? cancelToken,
  }) async {
    _validateCourseId(courseId);

    final res = await _client.get<dynamic>(
      Endpoints.aiChatSessions(courseId),
      cancelToken: cancelToken,
    );

    return StudentCourseAssistantSessionListResponse.fromJson(
      _responseMap(res.data, 'Invalid session list response'),
    );
  }

  /// Fetches one AI-chat session with its completed messages.
  ///
  /// Backend:
  /// GET /courses/{courseId}/ai-chat/sessions/{sessionId}
  Future<StudentCourseAssistantSessionDetailsResponse> getSession({
    required int courseId,
    required int sessionId,
    CancelToken? cancelToken,
  }) async {
    _validateCourseId(courseId);
    _validateSessionId(sessionId);

    final res = await _client.get<dynamic>(
      Endpoints.aiChatSession(courseId, sessionId),
      cancelToken: cancelToken,
    );

    return StudentCourseAssistantSessionDetailsResponse.fromJson(
      _responseMap(res.data, 'Invalid session response'),
    );
  }

  /// Sends a new user message inside an existing session only.
  ///
  /// Backend:
  /// POST /courses/{courseId}/ai-chat/sessions/{sessionId}/messages
  /// body: { "content": "..." }
  /// returns the saved pending user message. The assistant answer is read from
  /// [streamMessage] using the returned message id.
  Future<StudentCourseAssistantMessageResponse> sendMessageToSession({
    required int courseId,
    required int sessionId,
    required String message,
    CancelToken? cancelToken,
  }) async {
    _validateCourseId(courseId);
    _validateSessionId(sessionId);
    final data = _messagePayload(message);

    final res = await _client.post<dynamic>(
      Endpoints.aiChatSessionMessages(courseId, sessionId),
      data: data,
      cancelToken: cancelToken,
    );

    return StudentCourseAssistantMessageResponse.fromJson(
      _responseMap(res.data, 'Invalid send message response'),
    );
  }

  /// Streams/reads the assistant response for an already saved user message.
  ///
  /// This endpoint must be called after either [createSession] or
  /// [sendMessageToSession], using the user message id returned by the backend.
  Future<StudentCourseAssistantMessageResponse> streamMessage({
    required int courseId,
    required int sessionId,
    required int messageId,
    CancelToken? cancelToken,
  }) async {
    _validateCourseId(courseId);
    _validateSessionId(sessionId);
    if (messageId <= 0) {
      throw const FormatException('A valid message id is required');
    }

    final res = await _client.get<ResponseBody>(
      Endpoints.aiChatMessageStream(courseId, sessionId, messageId),
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(minutes: 2),
        headers: const {'Accept': 'text/event-stream'},
        extra: const {'silent': true},
      ),
      cancelToken: cancelToken,
    );

    final body = res.data;
    if (body == null) {
      throw const FormatException('Empty AI response stream');
    }

    return _readAssistantMessageFromSse(body);
  }

  void _validateCourseId(int courseId) {
    if (courseId <= 0) {
      throw const FormatException('A valid course id is required');
    }
  }

  void _validateSessionId(int sessionId) {
    if (sessionId <= 0) {
      throw const FormatException('A valid session id is required');
    }
  }

  Map<String, dynamic> _messagePayload(String message) {
    final content = message.trim();
    if (content.isEmpty) {
      throw const FormatException('Message content is required');
    }
    return {
      'content': content.length <= 2000 ? content : content.substring(0, 2000),
    };
  }

  Map<String, dynamic> _responseMap(dynamic data, String message) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw FormatException(message);
  }

  Future<StudentCourseAssistantMessageResponse> _readAssistantMessageFromSse(
    ResponseBody body,
  ) async {
    var buffer = '';

    await for (final chunk in utf8.decoder.bind(body.stream)) {
      buffer += chunk.replaceAll('\r\n', '\n');

      while (true) {
        final eventEnd = buffer.indexOf('\n\n');
        if (eventEnd < 0) break;

        final rawEvent = buffer.substring(0, eventEnd);
        buffer = buffer.substring(eventEnd + 2);

        final message = _parseSseEvent(rawEvent);
        if (message != null) return message;
      }
    }

    final tail = buffer.trim();
    if (tail.isNotEmpty) {
      final message = _parseSseEvent(tail);
      if (message != null) return message;
    }

    throw const FormatException('AI response stream closed without an answer');
  }

  StudentCourseAssistantMessageResponse? _parseSseEvent(String rawEvent) {
    var eventName = 'message';
    final dataLines = <String>[];

    for (final line in rawEvent.split('\n')) {
      final trimmed = line.trimRight();
      if (trimmed.isEmpty || trimmed.startsWith(':')) continue;

      if (trimmed.startsWith('event:')) {
        eventName = trimmed.substring(6).trim();
        continue;
      }

      if (trimmed.startsWith('data:')) {
        var data = trimmed.substring(5);
        if (data.startsWith(' ')) data = data.substring(1);
        dataLines.add(data);
      }
    }

    if (dataLines.isEmpty) return null;

    final rawData = dataLines.join('\n').trim();
    if (rawData.isEmpty) return null;

    final decoded = jsonDecode(rawData);

    if (eventName == 'message') {
      if (decoded is Map<String, dynamic>) {
        return StudentCourseAssistantMessageResponse.fromJson(decoded);
      }
      if (decoded is Map) {
        return StudentCourseAssistantMessageResponse.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
      throw const FormatException('Invalid AI message event');
    }

    if (eventName == 'timeout' || eventName == 'error') {
      if (decoded is Map) {
        final detail = decoded['detail']?.toString().trim();
        throw FormatException(
          detail == null || detail.isEmpty ? 'AI response failed' : detail,
        );
      }
      throw const FormatException('AI response failed');
    }

    return null;
  }
}
