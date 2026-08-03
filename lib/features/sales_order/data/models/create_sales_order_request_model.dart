import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_line_model.dart';

class CreateSalesOrderRequestModel {
  const CreateSalesOrderRequestModel({
    required this.cardCode,
    this.remarks,
    required this.lines,
    this.visitId,
    this.warehouseCode,
    this.docDueDate,
    this.uNetDue,
    this.uTotBonus,
  });

  final String cardCode;
  final String? remarks;
  final List<SalesOrderLineModel> lines;

  /// When creating from a visit, set to visit id; otherwise omit from JSON (do not send `""`).
  final String? visitId;

  /// Header warehouse; typically the logged-in user's default warehouse.
  final String? warehouseCode;

  /// PATCH only: document due date (ISO 8601 in JSON).
  final DateTime? docDueDate;

  /// Optional override for `U_NET_DUE`. When null, computed from lines (`U_FREE` = `N`).
  final num? uNetDue;

  /// Optional override for `U_TOT_BONUS`. When null, computed from lines (other `U_FREE`).
  final num? uTotBonus;

  ({num uNetDue, num uTotBonus}) get _resolvedFreeTotals {
    final computed = salesOrderFreeTotals(lines);
    return (
      uNetDue: uNetDue ?? computed.uNetDue,
      uTotBonus: uTotBonus ?? computed.uTotBonus,
    );
  }

  /// POST `/api/erp/sales-orders`
  Map<String, dynamic> toJsonForPost() {
    final totals = _resolvedFreeTotals;
    final map = <String, dynamic>{
      'cardCode': cardCode.isNotEmpty ? cardCode : '',
      'remarks': remarks?.trim() ?? '',
      'lines': lines.map((e) => e.toJsonForPost()).toList(),
      'warehouseCode': warehouseCode?.trim() ?? '',
      'U_NET_DUE': totals.uNetDue,
      'U_TOT_BONUS': totals.uTotBonus,
    };
    final v = visitId?.trim();
    if (v != null && v.isNotEmpty) {
      map['visitId'] = v;
    }
    return map;
  }

  /// PATCH `/api/erp/sales-orders/{docEntry}` (no visitId).
  Map<String, dynamic> toJsonForPatch() {
    final totals = _resolvedFreeTotals;
    final map = <String, dynamic>{
      'cardCode': cardCode.isNotEmpty ? cardCode : '',
      'remarks': remarks?.trim() ?? '',
      'lines': lines.map((e) => e.toJsonForPatch()).toList(),
      'warehouseCode': warehouseCode?.trim() ?? '',
      'U_NET_DUE': totals.uNetDue,
      'U_TOT_BONUS': totals.uTotBonus,
    };
    if (docDueDate != null) {
      map['docDueDate'] = docDueDate!.toUtc().toIso8601String();
    }
    return map;
  }
}
