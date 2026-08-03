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
    this.uFree,
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

  /// Free goods code from GET `/api/erp/sales-orders/getFreeGoodsList`; POST/PATCH as `U_FREE`.
  final String? uFree;

  /// Line amount used for Free-based header totals (`qty * unitPrice`).
  num get lineAmount => quantity * unitPrice;

  /// Whether this line counts toward `U_NET_DUE` (`U_FREE` = `N`).
  bool get isUFreeNo => (uFree ?? '').trim().toUpperCase() == 'N';

  /// Whether this line counts toward `U_TOT_BONUS` (any other non-empty `U_FREE`).
  bool get isUFreeOther {
    final code = (uFree ?? '').trim();
    return code.isNotEmpty && code.toUpperCase() != 'N';
  }

  SalesOrderLineModel copyWith({
    String? barcode,
    String? itemCode,
    String? itemName,
    num? quantity,
    num? unitPrice,
    String? unitOfMeasure,
    int? unitOfMeasureEntry,
    String? vatGroup,
    List<ItemUoMModel>? uoMs,
    String? warehouseCode,
    num? onHand,
    String? currency,
    String? uFree,
    bool clearUFree = false,
    bool clearVatGroup = false,
  }) {
    return SalesOrderLineModel(
      barcode: barcode ?? this.barcode,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      unitOfMeasureEntry: unitOfMeasureEntry ?? this.unitOfMeasureEntry,
      vatGroup: clearVatGroup ? null : (vatGroup ?? this.vatGroup),
      uoMs: uoMs ?? this.uoMs,
      warehouseCode: warehouseCode ?? this.warehouseCode,
      onHand: onHand ?? this.onHand,
      currency: currency ?? this.currency,
      uFree: clearUFree ? null : (uFree ?? this.uFree),
    );
  }

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
      'U_FREE': uFree ?? '',
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
      'U_FREE': uFree ?? '',
    };
  }
}

/// Header totals derived from Free (`U_FREE`) on lines.
/// - [uNetDue] → `U_NET_DUE` (lines with `U_FREE` = `N`)
/// - [uTotBonus] → `U_TOT_BONUS` (lines with any other non-empty `U_FREE`)
({num uNetDue, num uTotBonus}) salesOrderFreeTotals(
  Iterable<SalesOrderLineModel> lines,
) {
  num uNetDue = 0;
  num uTotBonus = 0;
  for (final line in lines) {
    if (line.isUFreeNo) {
      uNetDue += line.lineAmount;
    } else if (line.isUFreeOther) {
      uTotBonus += line.lineAmount;
    }
  }
  return (uNetDue: uNetDue, uTotBonus: uTotBonus);
}
