import 'package:sales_medical_app_mobile/features/sales_order/data/models/item_lookup_response_model.dart';

class SalesOrderLineModel {
  const SalesOrderLineModel({
    this.barcode,
    this.itemCode,
    this.itemName,
    required this.quantity,
    required this.unitPrice,
    this.unitOfMeasure,
    this.unitOfMeasureEntry,
    this.vatGroup,
    this.uoMs,
    this.warehouseCode,
    this.onHand,
    this.currency,
  });

  final String? barcode;
  final String? itemCode;
  final String? itemName;
  final num quantity;
  final num unitPrice;

  /// Display value (uoMCode); used for dropdown selection.
  final String? unitOfMeasure;

  /// Value sent in POST as unitOfMeasure (uoMEntry from lookup).
  final int? unitOfMeasureEntry;
  final String? vatGroup;

  /// UoM options from item lookup (for dropdown); not sent in POST.
  final List<ItemUoMModel>? uoMs;

  /// ERP warehouse; defaults from logged-in user when creating/updating if blank.
  final String? warehouseCode;

  /// From ODBC lookup for default warehouse; display-only (not sent on POST/PATCH).
  final num? onHand;

  /// ERP currency code (display-only, e.g. "EGP"). Not sent on POST/PATCH.
  final String? currency;

  /// POST `/api/erp/sales-orders` line shape.
  Map<String, dynamic> toJsonForPost() {
    final uomValue =
        unitOfMeasureEntry != null
            ? unitOfMeasureEntry.toString()
            : (unitOfMeasure ?? '');
    return {
      'barcode': barcode ?? '',
      'itemCode': itemCode ?? '',
      'itemName': itemName ?? '',
      'quantity': quantity,
      'unitPrice': unitPrice,
      'unitOfMeasure': uomValue,
      'vatGroup': vatGroup ?? '',
      'warehouseCode': warehouseCode ?? '',
    };
  }

  /// PATCH `/api/erp/sales-orders/{docEntry}` line shape.
  Map<String, dynamic> toJsonForPatch() {
    final uomValue =
        unitOfMeasureEntry != null
            ? unitOfMeasureEntry.toString()
            : (unitOfMeasure ?? '');
    return {
      'barcode': barcode ?? '',
      'itemCode': itemCode ?? '',
      'quantity': quantity,
      'unitOfMeasure': uomValue,
      'vatGroup': vatGroup ?? '',
      'warehouseCode': warehouseCode ?? '',
    };
  }
}
