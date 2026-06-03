/// Returns a message safe to show in UI.
/// - Network/connection issues → fixed copy.
/// - API/business errors (short, readable) → shown as-is (after stripping `Exception:` wrappers).
/// - Stack traces / unknown blobs → generic fallback.
String userFriendlyErrorMessage(String? rawMessage) {
  if (rawMessage == null || rawMessage.isEmpty) {
    return 'Something went wrong. Please try again.';
  }

  var msg = rawMessage.trim();
  // Repository uses `throw ServerFailure(message: e.toString())` → "Exception: <api text>"
  while (msg.startsWith('Exception: ')) {
    msg = msg.substring('Exception: '.length).trim();
  }
  if (msg.startsWith('FormatException: ')) {
    msg = msg.substring('FormatException: '.length).trim();
  }

  final lower = msg.toLowerCase();

  // Specific backend defect: VisitDto has two C# properties (`UserName` and
  // `Username`) that serialize to the same JSON name. ASP.NET throws while
  // building the response, so any endpoint returning a VisitDto fails with 400.
  // Surface a clear, user-friendly message — there is no client-side workaround.
  if (lower.contains('collides with another property') ||
      lower.contains('visitdto.username')) {
    return 'Server temporarily cannot return visit data. Please contact support.';
  }

  final isConnectionError = lower.contains('socket') ||
      lower.contains('connection') ||
      lower.contains('network') ||
      lower.contains('timeout') ||
      lower.contains('failed host') ||
      lower.contains('connection refused') ||
      lower.contains('connection reset') ||
      lower.contains('no internet') ||
      lower.contains('internet') ||
      lower.contains('connection timed out') ||
      lower.contains('handshake') ||
      lower.contains('unable to resolve host');
  if (isConnectionError) {
    return 'Please check your internet connection and try again.';
  }

  final looksLikeStackTrace = msg.contains('\n') ||
      msg.contains('.dart:') ||
      msg.contains('    at ') ||
      msg.length > 600;
  if (!looksLikeStackTrace && msg.isNotEmpty) {
    return msg;
  }
  return 'Something went wrong. Please try again.';
}

/// True when [rawMessage] matches the backend response-serialization defect
/// where `VisitDto.username` collides with another property. Used so callers
/// can fall back to cached visit data instead of showing an empty list.
bool isVisitDtoCollisionError(String? rawMessage) {
  if (rawMessage == null) return false;
  final lower = rawMessage.toLowerCase();
  return lower.contains('collides with another property') ||
      lower.contains('visitdto.username');
}
