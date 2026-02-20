enum AppFailureType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  unknown,
}

class AppFailure {
  final AppFailureType type;

  /// User-friendly message (safe to show).
  final String message;

  /// Optional debug info (logs only; never show in production UI).
  final String? debugMessage;

  final int? statusCode;

  /// Optional machine-readable code (e.g. TOKEN_EXPIRED)
  final String? code;

  const AppFailure({
    required this.type,
    required this.message,
    this.debugMessage,
    this.statusCode,
    this.code,
  });

  bool get isAuthIssue => type == AppFailureType.unauthorized || type == AppFailureType.forbidden;
  bool get isNetworkLike => type == AppFailureType.network || type == AppFailureType.timeout;

  AppFailure copyWith({
    AppFailureType? type,
    String? message,
    String? debugMessage,
    int? statusCode,
    String? code,
  }) {
    return AppFailure(
      type: type ?? this.type,
      message: message ?? this.message,
      debugMessage: debugMessage ?? this.debugMessage,
      statusCode: statusCode ?? this.statusCode,
      code: code ?? this.code,
    );
  }
}
