import 'package:sales_medical_app_mobile/core/network/api_http_exception.dart';

/// User-visible error text derived from any caught error, or `null` when a 401
/// is being handled by the global silent logout (no message should be shown).
String? userVisibleApiErrorMessage(Object error) {
  if (error is ApiHttpException) {
    if (error.isUnauthorized) return null;
    final msg = error.message.trim();
    return msg.isEmpty ? 'Something went wrong. Please try again.' : msg;
  }
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  if (text.isEmpty || text == 'null') {
    return 'Something went wrong. Please try again.';
  }
  return text;
}
