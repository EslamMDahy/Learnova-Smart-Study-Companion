class ApiException implements Exception {
  final String message;
  final int? statusCode;

  /// Optional app-level code (useful for UI decisions)
  /// e.g. UNAUTHORIZED, VALIDATION_ERROR, SERVER_ERROR
  final String? code;

  const ApiException(
    this.message, {
    this.statusCode,
    this.code,
  });

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidation => statusCode == 422;

  @override
  String toString() {
    final sc = statusCode == null ? '' : 'statusCode: $statusCode, ';
    final c = code == null ? '' : 'code: $code, ';
    return 'ApiException(${c}${sc}message: $message)';
  }
}
