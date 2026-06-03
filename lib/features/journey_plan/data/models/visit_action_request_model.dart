class VisitActionRequestModel {
  const VisitActionRequestModel({
    required this.actionCode,
    this.sapDocumentNumber,
    this.sapDocumentId,
  });

  final String actionCode;
  final String? sapDocumentNumber;
  final String? sapDocumentId;

  Map<String, dynamic> toJson() => {
        'actionCode': actionCode,
        if (sapDocumentNumber != null && sapDocumentNumber!.isNotEmpty)
          'sapDocumentNumber': sapDocumentNumber,
        if (sapDocumentId != null && sapDocumentId!.isNotEmpty)
          'sapDocumentId': sapDocumentId,
      };
}
