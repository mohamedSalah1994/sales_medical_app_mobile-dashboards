class SalesOrderResponseModel {
  const SalesOrderResponseModel({
    required this.success,
    this.documentNumber,
    this.documentId,
    this.errorCode,
    this.errorMessage,
    this.metadata,
  });

  final bool success;
  final String? documentNumber;
  final String? documentId;
  final String? errorCode;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  factory SalesOrderResponseModel.fromJson(Map<String, dynamic> json) {
    final docNum = json['documentNumber'];
    final docId = json['documentId'];
    final successRaw = json['success'];
    final success =
        successRaw is bool
            ? successRaw
            : successRaw is String
            ? successRaw.toLowerCase() == 'true'
            : false;
    return SalesOrderResponseModel(
      success: success,
      documentNumber: docNum?.toString(),
      documentId: docId?.toString(),
      errorCode: json['errorCode']?.toString(),
      errorMessage: json['errorMessage']?.toString(),
      metadata:
          json['metadata'] is Map
              ? Map<String, dynamic>.from(json['metadata'] as Map)
              : null,
    );
  }
}
