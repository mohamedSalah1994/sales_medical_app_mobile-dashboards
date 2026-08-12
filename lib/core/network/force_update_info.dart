/// Payload when the API rejects the client for version policy (HTTP 426 / CLIENT_VERSION_*).
class ForceUpdateInfo {
  const ForceUpdateInfo({
    required this.message,
    this.minVersion,
    this.clientVersion,
    this.errorCode,
  });

  final String message;
  final String? minVersion;
  final String? clientVersion;
  final String? errorCode;

  factory ForceUpdateInfo.fromResponseData(dynamic data, {String? fallbackMessage}) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final message =
          (map['message'] as String?)?.trim().isNotEmpty == true
              ? (map['message'] as String).trim()
              : (fallbackMessage ??
                  'This app version is no longer supported. Please update.');
      return ForceUpdateInfo(
        message: message,
        minVersion: map['minVersion']?.toString(),
        clientVersion: map['clientVersion']?.toString(),
        errorCode: map['error']?.toString(),
      );
    }
    return ForceUpdateInfo(
      message:
          fallbackMessage ??
          'This app version is no longer supported. Please update.',
    );
  }
}
