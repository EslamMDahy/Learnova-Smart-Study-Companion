import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_error_bus.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/storage/key_value_store.dart';
import '../../../core/storage/key_value_store_factory.dart';
import '../../../core/storage/user_storage.dart';
import '../../auth/data/auth_providers.dart';
import 'student_course_assistant_api.dart';
import 'student_course_assistant_models.dart';

final studentCourseAssistantApiProvider = Provider<StudentCourseAssistantApi>((ref) {
  return StudentCourseAssistantApi(ref.watch(apiClientProvider));
});

final studentCourseAssistantControllerProvider = StateNotifierProvider.autoDispose
    .family<StudentCourseAssistantController, StudentCourseAssistantState, int>(
  StudentCourseAssistantController.new,
);

class StudentCourseAssistantController
    extends StateNotifier<StudentCourseAssistantState> {
  StudentCourseAssistantController(this._ref, this._courseId)
      : super(const StudentCourseAssistantState()) {
    unawaited(_restoreLatestSession());
  }

  static const String _newChatSentinel = '__new_chat__';
  static final KeyValueStore _localStore = createLocalStore();

  final Ref _ref;
  final int _courseId;
  CancelToken? _sendCancel;
  CancelToken? _historyCancel;

  String get _activeSessionStorageKey {
    final userId = UserStorage.userId?.trim();
    final userScope = userId == null || userId.isEmpty ? 'anonymous' : userId;
    return 'learnova.student.ai_chat.$userScope.course.$_courseId.active_session';
  }

  String get _conversationStorageKey {
    final userId = UserStorage.userId?.trim();
    final userScope = userId == null || userId.isEmpty ? 'anonymous' : userId;
    return 'learnova.student.ai_chat.$userScope.course.$_courseId.cached_conversation';
  }

  Future<void> _restoreLatestSession() async {
    if (state.messages.isNotEmpty || state.sending) return;

    _historyCancel?.cancel();
    final cancelToken = CancelToken();
    _historyCancel = cancelToken;

    state = state.copyWith(loadingHistory: true, error: null);

    try {
      final cached = _cachedConversation();
      final storedSessionId = _storedSessionId();

      // Restore real cached messages first. A stale "new chat" marker from an
      // older tab/session must not hide a valid local conversation and force the
      // next send to create a brand-new backend session.
      if (cached != null && cached.messages.isNotEmpty) {
        if (!mounted || cancelToken.isCancelled) return;
        final restoredSessionId =
            _validSessionId(cached.sessionId) ?? storedSessionId;
        if (restoredSessionId != null) {
          _storeSessionId(restoredSessionId);
          _cacheConversation(
            messages: cached.messages,
            sessionId: restoredSessionId,
          );
        }
        state = state.copyWith(
          messages: cached.messages,
          sessionId: restoredSessionId,
          sending: false,
          loadingHistory: false,
          error: null,
        );
        return;
      }

      if (_hasExplicitNewChat()) {
        if (!mounted || cancelToken.isCancelled) return;
        state = state.copyWith(loadingHistory: false, error: null);
        return;
      }

      final backendSessionId = _validSessionId(storedSessionId) ??
          await _latestBackendSessionId(cancelToken);

      if (!mounted || cancelToken.isCancelled) return;

      if (backendSessionId == null) {
        state = state.copyWith(
          sending: false,
          loadingHistory: false,
          error: null,
        );
        return;
      }

      _storeSessionId(backendSessionId);

      try {
        final session = await _ref
            .read(studentCourseAssistantApiProvider)
            .getSession(
              courseId: _courseId,
              sessionId: backendSessionId,
              cancelToken: cancelToken,
            );

        if (!mounted || cancelToken.isCancelled) return;

        final restoredMessages = session.messages
            .map(StudentAssistantMessage.fromBackend)
            .where((message) => message.content.trim().isNotEmpty)
            .toList(growable: false);

        if (restoredMessages.isNotEmpty) {
          _cacheConversation(
            messages: restoredMessages,
            sessionId: backendSessionId,
          );
        }

        state = state.copyWith(
          messages: restoredMessages,
          sessionId: backendSessionId,
          sending: false,
          loadingHistory: false,
          error: null,
        );
      } catch (_) {
        // Backend history restore is a nice-to-have. If an old row still has a
        // bad shape, keep the session id so the next send can continue the
        // conversation instead of creating a duplicate session.
        if (!mounted || cancelToken.isCancelled) return;
        state = state.copyWith(
          sessionId: backendSessionId,
          sending: false,
          loadingHistory: false,
          error: null,
        );
      }
    } catch (_) {
      if (!mounted || cancelToken.isCancelled) return;
      state = state.copyWith(loadingHistory: false, error: null);
    }
  }

  Future<void> send({
    required String message,
    int? moduleId,
    int? materialId,
  }) async {
    final text = message.trim();
    if (text.isEmpty || state.isBusy) return;

    _historyCancel?.cancel();
    _sendCancel?.cancel();
    final cancelToken = CancelToken();
    _sendCancel = cancelToken;

    final hadConversationBeforeSend = state.messages.isNotEmpty;
    final currentSessionId = _validSessionId(state.sessionId) ??
        _validSessionId(_lastSessionIdFromMessages(state.messages)) ??
        _cachedConversation()?.sessionId ??
        _storedSessionId();
    final userMessage = StudentAssistantMessage.user(
      content: text,
      moduleId: moduleId,
      materialId: materialId,
    );

    final optimisticMessages = [...state.messages, userMessage];

    state = state.copyWith(
      messages: optimisticMessages,
      sending: true,
      loadingHistory: false,
      error: null,
    );
    _cacheConversation(
      messages: optimisticMessages,
      sessionId: currentSessionId,
    );

    try {
      final api = _ref.read(studentCourseAssistantApiProvider);

      final int sessionId;
      final int userMessageId;

      var resolvedSessionId = _validSessionId(currentSessionId);

      // If the local cache contains messages but missed the top-level session
      // id, recover from the safe list endpoint instead of creating a new
      // session. We deliberately do not call GET /sessions/{id}; that endpoint
      // can still fail on old rows with sources stored as {}.
      if (resolvedSessionId == null &&
          (!_hasExplicitNewChat() || hadConversationBeforeSend)) {
        resolvedSessionId = await _latestBackendSessionId(cancelToken);
        if (resolvedSessionId != null) {
          _storeSessionId(resolvedSessionId);
          _cacheConversation(
            messages: state.messages,
            sessionId: resolvedSessionId,
          );
          if (mounted && !cancelToken.isCancelled) {
            state = state.copyWith(sessionId: resolvedSessionId);
          }
        }
      }

      if (resolvedSessionId == null) {
        // First message in an explicit new chat: create_session stores the user
        // message and returns the new session id + the pending user message id.
        final created = await api.createSession(
          courseId: _courseId,
          message: text,
          cancelToken: cancelToken,
        );

        sessionId = created.session.id;
        userMessageId = created.message.id;

        // Keep the session immediately after create_session succeeds. Do not
        // wait for the stream response before the UI knows the session exists.
        _storeSessionId(sessionId);
        _cacheConversation(messages: state.messages, sessionId: sessionId);
        state = state.copyWith(sessionId: sessionId);
      } else {
        // Follow-up messages must be sent to an existing session only.
        sessionId = resolvedSessionId;
        _storeSessionId(sessionId);
        _cacheConversation(messages: state.messages, sessionId: sessionId);
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

      _storeSessionId(sessionId);
      final completedMessages = [...state.messages, assistantMessage];
      _cacheConversation(messages: completedMessages, sessionId: sessionId);

      state = state.copyWith(
        messages: completedMessages,
        sending: false,
        loadingHistory: false,
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

      final failedMessages = [...state.messages, assistantMessage];
      _cacheConversation(
        messages: failedMessages,
        sessionId: state.sessionId ?? currentSessionId,
      );

      state = state.copyWith(
        messages: failedMessages,
        sending: false,
        loadingHistory: false,
        error: errorMessage,
      );
    }
  }

  Future<int?> _latestBackendSessionId(CancelToken cancelToken) async {
    try {
      final sessions = await _ref
          .read(studentCourseAssistantApiProvider)
          .listSessions(
            courseId: _courseId,
            cancelToken: cancelToken,
          );
      if (cancelToken.isCancelled) return null;

      for (final session in sessions.sessions) {
        final id = _validSessionId(session.id);
        if (id != null) return id;
      }
    } catch (_) {
      // Sending must not fail just because session discovery failed. If there
      // is no recoverable session id, the normal create-session path below will
      // still run and surface the real backend error if needed.
    }
    return null;
  }

  int? _lastSessionIdFromMessages(List<StudentAssistantMessage> messages) {
    for (final message in messages.reversed) {
      final id = _validSessionId(message.sessionId);
      if (id != null) return id;
    }
    return null;
  }

  int? _validSessionId(int? value) {
    if (value == null || value <= 0) return null;
    return value;
  }

  void clear() {
    _historyCancel?.cancel();
    _sendCancel?.cancel();
    _clearCachedConversation();
    _storeExplicitNewChat();
    state = const StudentCourseAssistantState();
  }

  _CachedAssistantConversation? _cachedConversation() {
    final raw = _localStore.getString(_conversationStorageKey)?.trim();
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final rawMessages = map['messages'];
      final messages = rawMessages is List
          ? rawMessages
              .whereType<Map>()
              .map((item) => StudentAssistantMessage.fromCache(
                    Map<String, dynamic>.from(item),
                  ))
              .where((message) => message.content.trim().isNotEmpty)
              .toList(growable: false)
          : const <StudentAssistantMessage>[];
      final cachedSessionId = map['session_id'] is int
          ? map['session_id'] as int
          : int.tryParse((map['session_id'] ?? '').toString());
      final sessionId = _validSessionId(cachedSessionId) ??
          _validSessionId(_lastSessionIdFromMessages(messages)) ??
          _storedSessionId();

      if (messages.isEmpty && sessionId == null) {
        return null;
      }

      return _CachedAssistantConversation(
        sessionId: sessionId,
        messages: messages,
      );
    } catch (_) {
      _clearCachedConversation();
      return null;
    }
  }

  void _cacheConversation({
    required List<StudentAssistantMessage> messages,
    int? sessionId,
  }) {
    final effectiveSessionId = _validSessionId(sessionId) ??
        _validSessionId(state.sessionId) ??
        _validSessionId(_lastSessionIdFromMessages(messages)) ??
        _storedSessionId();

    if (messages.isEmpty && effectiveSessionId == null) {
      _clearCachedConversation();
      return;
    }

    final payload = {
      'session_id': effectiveSessionId,
      'course_id': _courseId,
      'updated_at': DateTime.now().toIso8601String(),
      'messages': messages
          .map((message) => message.toCacheJson())
          .toList(growable: false),
    };
    _localStore.setString(_conversationStorageKey, jsonEncode(payload));
  }

  void _clearCachedConversation() {
    _localStore.remove(_conversationStorageKey);
  }

  int? _storedSessionId() {
    final raw = _localStore.getString(_activeSessionStorageKey)?.trim();
    if (raw == null || raw.isEmpty || raw == _newChatSentinel) return null;
    final id = int.tryParse(raw);
    return id == null || id <= 0 ? null : id;
  }

  bool _hasExplicitNewChat() {
    return _localStore.getString(_activeSessionStorageKey)?.trim() ==
        _newChatSentinel;
  }

  void _storeSessionId(int sessionId) {
    if (sessionId <= 0) return;
    _localStore.setString(_activeSessionStorageKey, sessionId.toString());
  }

  void _storeExplicitNewChat() {
    _localStore.setString(_activeSessionStorageKey, _newChatSentinel);
  }

  @override
  void dispose() {
    _historyCancel?.cancel();
    _sendCancel?.cancel();
    super.dispose();
  }
}

class _CachedAssistantConversation {
  final int? sessionId;
  final List<StudentAssistantMessage> messages;

  const _CachedAssistantConversation({
    required this.sessionId,
    required this.messages,
  });
}
