/// A typed exception the app throws for every API failure.
/// Screens can pattern-match on `kind` to decide what to show.
class ApiException implements Exception {
  const ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.fieldErrors,
    this.minutesRemaining,
  });

  final ApiErrorKind kind;

  /// Already-localised, human-readable message (safe to show).
  final String message;

  final int? statusCode;

  /// Per-field validation errors from the backend, if any.
  final Map<String, String>? fieldErrors;

  /// For lockouts only.
  final int? minutesRemaining;

  @override
  String toString() => 'ApiException($kind, $message)';
}

enum ApiErrorKind {
  network,        // offline, DNS, timeout
  badRequest,     // 400
  unauthorized,   // 401
  forbidden,      // 403
  notFound,       // 404
  conflict,       // 409
  tooMany,        // 429
  server,         // 500+
  unknown,
}