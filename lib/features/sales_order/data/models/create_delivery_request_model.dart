class CreateDeliveryRequestModel {
  const CreateDeliveryRequestModel({
    required this.salesOrderDocEntry,
    required this.deliveryDate,
    this.remarks,
    required this.lines,
    this.warehouseCode,
    this.visitId,
  });

  final int salesOrderDocEntry;
  final DateTime deliveryDate;
  final String? remarks;
  final List<CreateDeliveryLineModel> lines;

  /// Document warehouse; typically default warehouse or order header.
  final String? warehouseCode;

  /// When set, POST /api/erp/deliveries links the document to this visit.
  final String? visitId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'salesOrderDocEntry': salesOrderDocEntry,
      'deliveryDate': deliveryDate.toUtc().toIso8601String(),
      'remarks': remarks?.trim() ?? '',
      'warehouseCode': warehouseCode?.trim() ?? '',
      'lines': lines.map((e) => e.toJson()).toList(),
    };
    final v = visitId?.trim();
    if (v != null && v.isNotEmpty) {
      map['visitId'] = v;
    }
    return map;
  }
}

class CreateDeliveryLineModel {
  const CreateDeliveryLineModel({
    required this.baseLine,
    required this.quantity,
    this.warehouseCode,
    this.batchNumbers,
  });

  final int baseLine;
  final num quantity;
  final String? warehouseCode;

  /// Per-batch quantities when the sales order line has `tracksBatches` (POST `lines[].batchNumbers`).
  final List<DeliveryBatchQuantityEntry>? batchNumbers;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'baseLine': baseLine,
      'quantity': quantity,
      'warehouseCode': warehouseCode?.trim() ?? '',
    };
    final b = batchNumbers;
    if (b != null && b.isNotEmpty) {
      m['batchNumbers'] = b.map((e) => e.toJson()).toList();
    }
    return m;
  }
}

class DeliveryBatchQuantityEntry {
  const DeliveryBatchQuantityEntry({
    required this.batchNumber,
    required this.quantity,
  });

  final String batchNumber;
  final num quantity;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'batchNumber': batchNumber,
    'quantity': quantity,
  };
}
