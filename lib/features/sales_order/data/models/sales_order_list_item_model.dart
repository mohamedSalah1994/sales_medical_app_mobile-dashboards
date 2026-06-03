/// One sales order from GET /api/erp/sales-orders (list or single doc).
class SalesOrderListItemModel {
  const SalesOrderListItemModel({
    this.docEntry,
    this.docNum,
    this.cardCode,
    this.customerName,
    this.customerForeignName,
    this.cardType,
    this.cardTypeName,
    this.docDate,
    this.docDueDate,
    this.docTotal,
    this.remarks,
    this.documentStatus,
    this.uTrantjov,
    this.warehouseCode,
    this.currency,
    this.lines = const [],
    this.appSalesOrderId,
  });

  /// Set when row comes from GET /api/Sales/orders (UUID). ERP detail uses [docEntry].
  final String? appSalesOrderId;

  final int? docEntry;
  final int? docNum;
  final String? cardCode;
  final String? customerName;

  /// ERP alternate name (`cardForeignName` / `foreignName` in API) when provided.
  final String? customerForeignName;

  /// ERP business partner type — `C` (Customer) or `L` (Lead). List endpoint only.
  final String? cardType;

  /// Server-formatted label for [cardType] (e.g. "Customer").
  final String? cardTypeName;
  final String? docDate;
  final String? docDueDate;
  final num? docTotal;
  final String? remarks;
  final String? documentStatus;

  /// ERP sale type flag (display only on list cards).
  final String? uTrantjov;
  final String? warehouseCode;

  /// Document currency code (e.g. "EGP"). Returned by GET single-doc.
  final String? currency;
  final List<SalesOrderListLineModel> lines;

  factory SalesOrderListItemModel.fromJson(Map<String, dynamic> json) {
    final linesRaw = json['lines'];
    final linesList =
        linesRaw is List
            ? (linesRaw)
                .where((e) => e is Map<String, dynamic>)
                .map(
                  (e) => SalesOrderListLineModel.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList()
            : <SalesOrderListLineModel>[];
    return SalesOrderListItemModel(
      docEntry: json['docEntry'] as int?,
      docNum: json['docNum'] as int?,
      cardCode: json['cardCode'] as String?,
      customerName: json['customerName'] as String?,
      customerForeignName: _optionalStringFromJson(
        json['customerForeignName'] ??
            json['cardForeignName'] ??
            json['foreignName'],
      ),
      cardType: _optionalStringFromJson(json['cardType']),
      cardTypeName: _optionalStringFromJson(json['cardTypeName']),
      docDate: json['docDate'] as String?,
      docDueDate: json['docDueDate'] as String?,
      docTotal: (json['docTotal'] as num?)?.toDouble(),
      remarks: json['remarks'] as String?,
      documentStatus: json['documentStatus'] as String?,
      uTrantjov: json['uTrantjov'] as String?,
      warehouseCode: json['warehouseCode'] as String?,
      currency: _optionalStringFromJson(json['currency']),
      lines: linesList,
      appSalesOrderId: json['appSalesOrderId'] as String?,
    );
  }

  /// Row from GET /api/Sales/orders
  factory SalesOrderListItemModel.fromSalesApiItem(Map<String, dynamic> json) {
    final linesRaw = json['lines'];
    final linesList =
        linesRaw is List
            ? linesRaw
                .where((e) => e is Map<String, dynamic>)
                .map(
                  (e) => SalesOrderListLineModel.fromSalesApiLine(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList()
            : <SalesOrderListLineModel>[];
    final code = json['customerCode'] as String?;
    return SalesOrderListItemModel(
      appSalesOrderId: json['id'] as String?,
      cardCode: code,
      customerName: code,
      docDate: json['orderDate'] as String?,
      docTotal: (json['totalAmount'] as num?)?.toDouble(),
      remarks: json['remarks'] as String?,
      lines: linesList,
    );
  }
}

String? _optionalStringFromJson(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

extension SalesOrderListItemModelCustomerDisplay on SalesOrderListItemModel {
  /// Foreign name for UI when it differs from [customerName].
  String? get distinctCustomerForeignName {
    final raw = customerForeignName?.trim() ?? '';
    if (raw.isEmpty) return null;
    final name = customerName?.trim() ?? '';
    if (raw == name) return null;
    return raw;
  }
}

/// One `{ batchNumber, quantity }` on a delivery/return line from GET ERP documents.
class ErpLineBatchNumber {
  const ErpLineBatchNumber({required this.batchNumber, required this.quantity});

  final String batchNumber;
  final double quantity;

  factory ErpLineBatchNumber.fromJson(Map<String, dynamic> json) {
    return ErpLineBatchNumber(
      batchNumber: json['batchNumber']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
    );
  }
}

List<ErpLineBatchNumber>? _parseLineBatchNumbers(dynamic raw) {
  if (raw is! List || raw.isEmpty) return null;
  final out = <ErpLineBatchNumber>[];
  for (final e in raw) {
    if (e is Map<String, dynamic>) {
      out.add(ErpLineBatchNumber.fromJson(e));
    }
  }
  return out.isEmpty ? null : out;
}

class SalesOrderListLineModel {
  const SalesOrderListLineModel({
    this.itemCode,
    this.itemName,
    this.barcode,
    this.quantity,
    this.unitOfMeasure,
    this.unitPrice,
    this.currency,
    this.vatPercent,
    this.vat,
    this.lineTotal,
    this.vatGroup,
    this.lineNumber,
    this.lineStatus,
    this.remainingOpenQuantity,
    this.warehouseCode,
    this.onHand,
    this.tracksBatches = false,
    this.batchNumbers,
  });

  final String? itemCode;
  final String? itemName;
  final String? barcode;
  final num? quantity;
  final String? unitOfMeasure;
  final num? unitPrice;

  /// ERP currency code on the line (e.g. "EGP"); display next to unit price.
  final String? currency;
  final num? vatPercent;
  final num? vat;
  final num? lineTotal;
  final String? vatGroup;
  final int? lineNumber;
  final String? lineStatus;
  final num? remainingOpenQuantity;
  final String? warehouseCode;

  /// Optional stock/on-hand from ERP when provided (e.g. some document lines).
  final num? onHand;

  /// When true, delivery must allocate quantities per batch (see batch-quantities API).
  final bool tracksBatches;

  /// From GET delivery/return lines when ERP sends `batchNumbers`.
  final List<ErpLineBatchNumber>? batchNumbers;

  factory SalesOrderListLineModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderListLineModel(
      itemCode: json['itemCode'] as String?,
      itemName: json['itemName'] as String?,
      barcode: json['barcode'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unitOfMeasure: json['unitOfMeasure'] as String?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      currency: _optionalStringFromJson(json['currency']),
      vatPercent: (json['vatPercent'] as num?)?.toDouble(),
      vat: (json['vat'] as num?)?.toDouble(),
      lineTotal: (json['lineTotal'] as num?)?.toDouble(),
      vatGroup: json['vatGroup'] as String?,
      lineNumber: json['lineNumber'] as int?,
      lineStatus: json['lineStatus'] as String?,
      remainingOpenQuantity:
          (json['remainingOpenQuantity'] as num?)?.toDouble(),
      warehouseCode: json['warehouseCode'] as String?,
      onHand: json['onHand'] as num?,
      tracksBatches: _parseBool(json['tracksBatches']) ?? false,
      batchNumbers: _parseLineBatchNumbers(json['batchNumbers']),
    );
  }

  static bool? _parseBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase().trim();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return null;
  }

  factory SalesOrderListLineModel.fromSalesApiLine(Map<String, dynamic> json) {
    final code = json['productCode'] as String?;
    return SalesOrderListLineModel(
      itemCode: code,
      itemName: code,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      lineTotal: (json['lineTotal'] as num?)?.toDouble(),
      batchNumbers: _parseLineBatchNumbers(json['batchNumbers']),
    );
  }
}

extension SalesOrderListLineModelErp on SalesOrderListLineModel {
  /// Line is open in ERP — included when copying to delivery / return.
  bool get isLineStatusOpen => (lineStatus ?? '').trim() == 'bost_Open';

  bool get hasBatchNumbers => batchNumbers != null && batchNumbers!.isNotEmpty;
}
