/// Response from GET `/api/auth/client-version` (no auth, no version header).
class ClientVersionPolicyModel {
  const ClientVersionPolicyModel({
    required this.enforce,
    required this.minVersion,
    this.headerName = 'X-App-Version',
  });

  final bool enforce;
  final String minVersion;
  final String headerName;

  factory ClientVersionPolicyModel.fromJson(Map<String, dynamic> json) {
    return ClientVersionPolicyModel(
      enforce: json['enforce'] == true,
      minVersion: (json['minVersion'] ?? '').toString().trim(),
      headerName:
          (json['headerName'] as String?)?.trim().isNotEmpty == true
              ? (json['headerName'] as String).trim()
              : 'X-App-Version',
    );
  }
}
