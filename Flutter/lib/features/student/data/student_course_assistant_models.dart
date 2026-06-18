DateTime _asDate(dynamic value) {
  if (value is DateTime) return value;
  final raw = (value ?? '').toString().trim();
  return DateTime.tryParse(raw) ?? DateTime.now();
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  final raw = (value ?? '').toString().trim().toLowerCase();
  return raw == 'true' || raw == '1' || raw == 'yes';
}

String _asString(dynamic value) => (value ?? '').toString().trim();

String _newMessageId(String prefix) {
  final micros = DateTime.now().microsecondsSinceEpoch;
  return '$prefix-$micros';
}

enum StudentAssistantMessageRole { user, assistant }

class StudentAssistantSource {
  final String title;
  final int? page;

  const StudentAssistantSource({
    required this.title,
    this.page,
  });

  factory StudentAssistantSource.fromJson(Map<String, dynamic> json) {
    return StudentAssistantSource(
      title: _asString(json['title']),
      page: _asNullableInt(json['page']),
    );
  }

  String get label {
    if (page == null) return title;
    return '$title · p.$page';
  }
}

class StudentAssistantMessage {
  final String id;
  final int? backendId;
  final int? sessionId;
  final StudentAssistantMessageRole role;
  final String content;
  final DateTime createdAt;
  final int? moduleId;
  final int? materialId;
  final List<StudentAssistantSource> sources;
  final bool isError;

  const StudentAssistantMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.backendId,
    this.sessionId,
    this.moduleId,
    this.materialId,
    this.sources = const [],
    this.isError = false,
  });

  bool get isUser => role == StudentAssistantMessageRole.user;

  factory StudentAssistantMessage.user({
    required String content,
    int? moduleId,
    int? materialId,
  }) {
    return StudentAssistantMessage(
      id: _newMessageId('user'),
      role: StudentAssistantMessageRole.user,
      content: content,
      createdAt: DateTime.now(),
      moduleId: moduleId,
      materialId: materialId,
    );
  }

  factory StudentAssistantMessage.assistant({
    required String content,
    int? backendId,
    int? sessionId,
    int? moduleId,
    int? materialId,
    List<StudentAssistantSource> sources = const [],
    bool isError = false,
  }) {
    return StudentAssistantMessage(
      id: _newMessageId(isError ? 'assistant-error' : 'assistant'),
      backendId: backendId,
      sessionId: sessionId,
      role: StudentAssistantMessageRole.assistant,
      content: content,
      createdAt: DateTime.now(),
      moduleId: moduleId,
      materialId: materialId,
      sources: sources,
      isError: isError,
    );
  }

  factory StudentAssistantMessage.fromBackend(
    StudentCourseAssistantMessageResponse response, {
    int? moduleId,
    int? materialId,
  }) {
    final role = response.messageType.toLowerCase() == 'user'
        ? StudentAssistantMessageRole.user
        : StudentAssistantMessageRole.assistant;

    return StudentAssistantMessage(
      id: _newMessageId(role == StudentAssistantMessageRole.user ? 'user' : 'assistant'),
      backendId: response.id,
      sessionId: response.sessionId,
      role: role,
      content: response.content,
      createdAt: response.createdAt,
      moduleId: moduleId,
      materialId: materialId,
      sources: response.sources,
    );
  }
}

class StudentCourseAssistantSessionResponse {
  final int id;
  final int? courseId;
  final String? sessionTitle;
  final bool isActive;
  final DateTime startedAt;
  final DateTime? lastMessageAt;

  const StudentCourseAssistantSessionResponse({
    required this.id,
    required this.courseId,
    required this.sessionTitle,
    required this.isActive,
    required this.startedAt,
    required this.lastMessageAt,
  });

  factory StudentCourseAssistantSessionResponse.fromJson(Map<String, dynamic> json) {
    final title = _asString(json['session_title']);
    final lastMessageRaw = json['last_message_at'];

    return StudentCourseAssistantSessionResponse(
      id: _asInt(json['id']),
      courseId: _asNullableInt(json['course_id']),
      sessionTitle: title.isEmpty ? null : title,
      isActive: _asBool(json['is_active']),
      startedAt: _asDate(json['started_at']),
      lastMessageAt: lastMessageRaw == null ? null : _asDate(lastMessageRaw),
    );
  }
}

class StudentCourseAssistantMessageResponse {
  final int id;
  final int sessionId;
  final String messageType;
  final String content;
  final List<StudentAssistantSource> sources;
  final DateTime createdAt;

  const StudentCourseAssistantMessageResponse({
    required this.id,
    required this.sessionId,
    required this.messageType,
    required this.content,
    required this.sources,
    required this.createdAt,
  });

  factory StudentCourseAssistantMessageResponse.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'];

    return StudentCourseAssistantMessageResponse(
      id: _asInt(json['id']),
      sessionId: _asInt(json['session_id']),
      messageType: _asString(json['message_type']).isEmpty
          ? _asString(json['role'])
          : _asString(json['message_type']),
      content: _asString(json['content'] ?? json['message'] ?? json['answer']),
      sources: rawSources is List
          ? rawSources
              .whereType<Map>()
              .map((item) => StudentAssistantSource.fromJson(Map<String, dynamic>.from(item)))
              .where((item) => item.title.isNotEmpty)
              .toList(growable: false)
          : const [],
      createdAt: _asDate(json['created_at']),
    );
  }
}

class StudentCourseAssistantCreateSessionResponse {
  final StudentCourseAssistantSessionResponse session;
  final StudentCourseAssistantMessageResponse message;

  const StudentCourseAssistantCreateSessionResponse({
    required this.session,
    required this.message,
  });

  factory StudentCourseAssistantCreateSessionResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawSession = json['session'];
    final rawMessage = json['message'];

    if (rawSession is! Map || rawMessage is! Map) {
      throw const FormatException('Invalid create session response');
    }

    return StudentCourseAssistantCreateSessionResponse(
      session: StudentCourseAssistantSessionResponse.fromJson(
        Map<String, dynamic>.from(rawSession),
      ),
      message: StudentCourseAssistantMessageResponse.fromJson(
        Map<String, dynamic>.from(rawMessage),
      ),
    );
  }
}

class StudentCourseAssistantSessionListResponse {
  final int courseId;
  final int total;
  final List<StudentCourseAssistantSessionResponse> sessions;

  const StudentCourseAssistantSessionListResponse({
    required this.courseId,
    required this.total,
    required this.sessions,
  });

  factory StudentCourseAssistantSessionListResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawSessions = json['sessions'];
    final sessions = rawSessions is List
        ? rawSessions
            .whereType<Map>()
            .map((item) => StudentCourseAssistantSessionResponse.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false)
        : const <StudentCourseAssistantSessionResponse>[];

    return StudentCourseAssistantSessionListResponse(
      courseId: _asInt(json['course_id']),
      total: _asInt(json['total']),
      sessions: sessions,
    );
  }
}

class StudentCourseAssistantSessionDetailsResponse {
  final int id;
  final int? courseId;
  final String contextType;
  final String? sessionTitle;
  final bool isActive;
  final DateTime startedAt;
  final DateTime? lastMessageAt;
  final List<StudentCourseAssistantMessageResponse> messages;

  const StudentCourseAssistantSessionDetailsResponse({
    required this.id,
    required this.courseId,
    required this.contextType,
    required this.sessionTitle,
    required this.isActive,
    required this.startedAt,
    required this.lastMessageAt,
    required this.messages,
  });

  factory StudentCourseAssistantSessionDetailsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final title = _asString(json['session_title']);
    final rawMessages = json['messages'];
    final lastMessageRaw = json['last_message_at'];

    return StudentCourseAssistantSessionDetailsResponse(
      id: _asInt(json['id']),
      courseId: _asNullableInt(json['course_id']),
      contextType: _asString(json['context_type']).isEmpty
          ? 'course'
          : _asString(json['context_type']),
      sessionTitle: title.isEmpty ? null : title,
      isActive: _asBool(json['is_active']),
      startedAt: _asDate(json['started_at']),
      lastMessageAt: lastMessageRaw == null ? null : _asDate(lastMessageRaw),
      messages: rawMessages is List
          ? rawMessages
              .whereType<Map>()
              .map((item) => StudentCourseAssistantMessageResponse.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false)
          : const [],
    );
  }
}

class StudentCourseAssistantState {
  final List<StudentAssistantMessage> messages;
  final bool sending;
  final int? sessionId;
  final String? error;

  const StudentCourseAssistantState({
    this.messages = const [],
    this.sending = false,
    this.sessionId,
    this.error,
  });

  bool get hasConversation => messages.isNotEmpty;
  bool get hasBackendSession => sessionId != null && sessionId! > 0;

  StudentCourseAssistantState copyWith({
    List<StudentAssistantMessage>? messages,
    bool? sending,
    Object? sessionId = _keepSessionId,
    Object? error = _keepError,
  }) {
    return StudentCourseAssistantState(
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
      sessionId: identical(sessionId, _keepSessionId)
          ? this.sessionId
          : sessionId as int?,
      error: identical(error, _keepError) ? this.error : error as String?,
    );
  }
}

const _keepSessionId = Object();
const _keepError = Object();

class StudentCourseAssistantHistoryItem {
  final int? id;
  final String role;
  final String content;
  final DateTime createdAt;

  const StudentCourseAssistantHistoryItem({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory StudentCourseAssistantHistoryItem.fromJson(Map<String, dynamic> json) {
    return StudentCourseAssistantHistoryItem(
      id: _asNullableInt(json['id']),
      role: _asString(json['message_type'] ?? json['role']).isEmpty
          ? 'assistant'
          : _asString(json['message_type'] ?? json['role']),
      content: _asString(json['content'] ?? json['message'] ?? json['text']),
      createdAt: _asDate(json['created_at']),
    );
  }
}
