/// Summary row from GET `/api/erp/sales-orders/ready-for-delivery` or
/// GET `/api/erp/deliveries/ready-for-return` (same JSON shape).
class SalesOrderReadyForDeliveryModel {
  const SalesOrderReadyForDeliveryModel({
    this.docEntry,
    this.docNum,
    this.cardCode,
    this.cardName,
    this.docTotal,
  });

  final int? docEntry;
  final int? docNum;
  final String? cardCode;
  final String? cardName;
  final num? docTotal;

  factory SalesOrderReadyForDeliveryModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderReadyForDeliveryModel(
      docEntry: json['docEntry'] as int?,
      docNum: json['docNum'] as int?,
      cardCode: json['cardCode'] as String?,
      cardName: json['cardName'] as String?,
      docTotal: json['docTotal'] as num?,
    );
  }
}
