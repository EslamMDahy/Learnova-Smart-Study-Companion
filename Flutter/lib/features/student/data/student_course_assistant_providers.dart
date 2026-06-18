import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_error_bus.dart';
import '../../../core/network/error_mapper.dart';
import '../../auth/data/auth_providers.dart';
import 'student_course_assistant_api.dart';
import 'student_course_assistant_models.dart';

final studentCourseAssistantApiProvider = Provider<StudentCourseAssistantApi>((ref) {
  return StudentCourseAssistantApi(ref.watch(apiClientProvider));
});

final studentCourseAssistantControllerProvider = StateNotifierProvider.autoDispose
    .family<StudentCourseAssistantController, StudentCourseAssistantState, int>(
  (ref, courseId) => StudentCourseAssistantController(ref, courseId),
);

class StudentCourseAssistantController
    extends StateNotifier<StudentCourseAssistantState> {
  StudentCourseAssistantController(this._ref, this._courseId)
      : super(const StudentCourseAssistantState());

  final Ref _ref;
  final int _courseId;
  CancelToken? _sendCancel;

  Future<void> send({
    required String message,
    int? moduleId,
    int? materialId,
  }) async {
    final text = message.trim();
    if (text.isEmpty || state.sending) return;

    _sendCancel?.cancel();
    final cancelToken = CancelToken();
    _sendCancel = cancelToken;

    final currentSessionId = state.sessionId;
    final userMessage = StudentAssistantMessage.user(
      content: text,
      moduleId: moduleId,
      materialId: materialId,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      sending: true,
      error: null,
    );

    try {
      final api = _ref.read(studentCourseAssistantApiProvider);

      final int sessionId;
      final int userMessageId;

      if (currentSessionId == null || currentSessionId <= 0) {
        // First message: create_session stores the user message and returns
        // the new session id + the pending user message id.
        final created = await api.createSession(
          courseId: _courseId,
          message: text,
          cancelToken: cancelToken,
        );

        sessionId = created.session.id;
        userMessageId = created.message.id;

        // Keep the session immediately after create_session succeeds. Do not
        // wait for the stream response before the UI knows the session exists.
        state = state.copyWith(sessionId: sessionId);
      } else {
        // Follow-up messages must be sent to an existing session only.
        sessionId = currentSessionId;
        final sentMessage = await api.sendMessageToSession(
          courseId: _courseId,
          sessionId: sessionId,
          message: text,
          cancelToken: cancelToken,
        );
        userMessageId = sentMessage.id;
      }

      // Stream reads the assistant response for the already-saved user message.
      final backendMessage = await api.streamMessage(
        courseId: _courseId,
        sessionId: sessionId,
        messageId: userMessageId,
        cancelToken: cancelToken,
      );

      final answer = backendMessage.content.trim();
      final assistantMessage = StudentAssistantMessage.assistant(
        backendId: backendMessage.id,
        sessionId: backendMessage.sessionId,
        content:
            answer.isEmpty ? 'The assistant returned an empty answer.' : answer,
        moduleId: moduleId,
        materialId: materialId,
        sources: backendMessage.sources,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        sending: false,
        sessionId: sessionId,
        error: null,
      );
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) return;

      final failure = mapApiFailure(e);
      AppErrorReporter.report(_ref, failure);

      final formatMessage = e is FormatException ? e.message.trim() : '';
      final errorMessage = formatMessage.isNotEmpty
          ? formatMessage
          : failure.message.isEmpty
              ? 'Failed to send AI request.'
              : failure.message;

      final assistantMessage = StudentAssistantMessage.assistant(
        content: errorMessage,
        moduleId: moduleId,
        materialId: materialId,
        isError: true,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        sending: false,
        error: errorMessage,
      );
    }
  }

  void clear() {
    _sendCancel?.cancel();
    state = const StudentCourseAssistantState();
  }

  @override
  void dispose() {
    _sendCancel?.cancel();
    super.dispose();
  }
}
