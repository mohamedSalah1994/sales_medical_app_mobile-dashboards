import 'package:sales_medical_app_mobile/core/network/api_error_message.dart';
import 'package:sales_medical_app_mobile/core/network/api_http_exception.dart';

/// Thrown when POST `/api/Erp/customers` rejects because the phone already
/// belongs to another customer, and the client may retry with
/// `confirmDuplicatePhone: true`.
class DuplicateCustomerPhoneException implements Exception {
  const DuplicateCustomerPhoneException({
    required this.message,
    this.existingUserName,
  });

  /// Full API message (typically includes the existing customer name).
  final String message;

  /// Existing customer/user name when the API provides it separately.
  final String? existingUserName;

  String get displayMessage {
    final name = existingUserName?.trim();
    if (name != null && name.isNotEmpty && !message.contains(name)) {
      return '$message\n$name';
    }
    return message;
  }

  @override
  String toString() => message;

  /// True when [error] looks like a duplicate-phone conflict from create customer.
  static bool isDuplicatePhoneError(Object error) {
    final msg = (userVisibleApiErrorMessage(error) ?? error.toString())
        .toLowerCase();
    if (msg.trim().isEmpty) return false;

    final mentionsPhone =
        msg.contains('phone') ||
        msg.contains('هاتف') ||
        msg.contains('موبايل') ||
        msg.contains('تليفون') ||
        msg.contains('telephone') ||
        msg.contains('mobile');
    final mentionsDuplicate =
        msg.contains('duplicate') ||
        msg.contains('already') ||
        msg.contains('exist') ||
        msg.contains('used') ||
        msg.contains('has a user') ||
        msg.contains('has user') ||
        msg.contains('مكرر') ||
        msg.contains('موجود') ||
        msg.contains('مستخدم') ||
        msg.contains('مسجل') ||
        msg.contains('سبق');

    if (mentionsPhone && mentionsDuplicate) return true;

    // Some APIs only say the phone belongs to a customer/user.
    if (mentionsPhone &&
        (msg.contains('customer') ||
            msg.contains('user') ||
            msg.contains('عميل') ||
            msg.contains('مستخدم'))) {
      return true;
    }

    if (error is ApiHttpException && error.statusCode == 409) {
      return mentionsPhone || mentionsDuplicate;
    }
    return false;
  }

  static DuplicateCustomerPhoneException fromError(Object error) {
    final message =
        userVisibleApiErrorMessage(error) ??
        error.toString().replaceFirst('Exception: ', '').trim();
    return DuplicateCustomerPhoneException(
      message: message.isEmpty
          ? 'This phone number is already used by another customer.'
          : message,
      existingUserName: _extractExistingUserName(message),
    );
  }

  static String? _extractExistingUserName(String message) {
    // Common patterns: "... customer: NAME", "... user NAME", "... by NAME"
    final patterns = <RegExp>[
      RegExp(r'customer[:\s]+(.+)$', caseSensitive: false),
      RegExp(r'user[:\s]+(.+)$', caseSensitive: false),
      RegExp(r'by[:\s]+(.+)$', caseSensitive: false),
      RegExp(r'عميل[:\s]+(.+)$'),
      RegExp(r'مستخدم[:\s]+(.+)$'),
    ];
    for (final re in patterns) {
      final m = re.firstMatch(message.trim());
      final name = m?.group(1)?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return null;
  }
}
