class VisitAction {
  const VisitAction({
    required this.id,
    required this.actionCode,
    this.actionName,
    this.status,
    this.sapDocumentNumber,
    this.sapDocumentId,
    this.postedAt,
  });

  final String id;
  final String actionCode;
  final String? actionName;
  final int? status;
  final String? sapDocumentNumber;
  final String? sapDocumentId;
  final DateTime? postedAt;
}
