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
  final String message;      // user-friendly
  final String? debugMessage; // optional
  final int? statusCode;

  const AppFailure({
    required this.type,
    required this.message,
    this.debugMessage,
    this.statusCode,
  });
}
