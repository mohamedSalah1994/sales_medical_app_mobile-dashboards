/// Thrown by [ApiService] when the server responds with a non-success status.
/// Carries [statusCode] so callers can map 404/500 to user-facing copy.
class ApiHttpException implements Exception {
  ApiHttpException({
    required this.statusCode,
    required this.message,
    this.isUnauthorized = false,
  });

  final int statusCode;
  final String message;

  /// True for a 401 on an authenticated request. The app silently logs the
  /// user out and returns to login, so no error message should be shown.
  final bool isUnauthorized;

  @override
  String toString() => message;
}
