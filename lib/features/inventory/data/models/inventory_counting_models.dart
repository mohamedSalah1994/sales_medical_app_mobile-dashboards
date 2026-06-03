/// GET `/api/erp/inventory-countings/{documentEntry}`
class InventoryCountingDocModel {
  const InventoryCountingDocModel({
    required this.documentEntry,
    required this.documentNumber,
    this.countDate,
    this.remarks,
    this.documentStatus,
    required this.lines,
  });

  final int documentEntry;
  final int documentNumber;
  final String? countDate;
  final String? remarks;
  final String? documentStatus;
  final List<InventoryCountingLineModel> lines;

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }

  factory InventoryCountingDocModel.fromJson(Map<String, dynamic> json) {
    final linesRaw = json['lines'];
    final lines =
        linesRaw is List
            ? linesRaw
                .whereType<Map<String, dynamic>>()
                .map(InventoryCountingLineModel.fromJson)
                .toList()
            : <InventoryCountingLineModel>[];

    return InventoryCountingDocModel(
      documentEntry: _parseInt(json['documentEntry']),
      documentNumber: _parseInt(json['documentNumber']),
      countDate: json['countDate'] as String?,
      remarks: json['remarks'] as String?,
      documentStatus: json['documentStatus'] as String?,
      lines: lines,
    );
  }
}

class InventoryCountingLineModel {
  const InventoryCountingLineModel({
    this.lineNumber,
    required this.itemCode,
    this.itemName,
    required this.warehouseCode,
    this.countedQuantity,
    this.uoMCode,
    this.variance,
  });

  final int? lineNumber;
  final String itemCode;
  final String? itemName;
  final String warehouseCode;
  final num? countedQuantity;
  final String? uoMCode;
  final num? variance;

  factory InventoryCountingLineModel.fromJson(Map<String, dynamic> json) {
    return InventoryCountingLineModel(
      lineNumber: (json['lineNumber'] as num?)?.toInt(),
      itemCode: (json['itemCode'] as String? ?? '').toString(),
      itemName: json['itemName'] as String?,
      warehouseCode: (json['warehouseCode'] as String? ?? '').toString(),
      countedQuantity: json['countedQuantity'] as num?,
      uoMCode: json['uoMCode'] as String?,
      variance: json['variance'] as num?,
    );
  }
}

/// POST `/api/erp/inventory-countings`
class CreateInventoryCountingRequestModel {
  const CreateInventoryCountingRequestModel({
    required this.countDate,
    this.remarks,
    required this.inventoryCountingLines,
  });

  final DateTime countDate;
  final String? remarks;
  final List<InventoryCountingLineRequestModel> inventoryCountingLines;

  Map<String, dynamic> toJson() {
    return {
      'countDate': countDate.toUtc().toIso8601String(),
      'remarks': remarks ?? '',
      'inventoryCountingLines':
          inventoryCountingLines.map((e) => e.toJson()).toList(),
    };
  }
}

class InventoryCountingLineRequestModel {
  const InventoryCountingLineRequestModel({
    required this.itemCode,
    required this.warehouseCode,
    required this.countedQuantity,
    required this.uoMCode,
  });

  final String itemCode;
  final String warehouseCode;
  final num countedQuantity;
  final String uoMCode;

  Map<String, dynamic> toJson() {
    return {
      'itemCode': itemCode,
      'warehouseCode': warehouseCode,
      'countedQuantity': countedQuantity,
      'uoMCode': uoMCode,
    };
  }
}
