import 'package:sales_medical_app_mobile/features/sales_order/data/models/create_delivery_request_model.dart';

class CreateReturnFromDeliveryRequestModel {
  const CreateReturnFromDeliveryRequestModel({
    required this.deliveryDocEntry,
    required this.returnDate,
    this.remarks,
    this.reason,
    required this.lines,
    this.visitId,
    this.warehouseCode,
  });

  final int deliveryDocEntry;
  final DateTime returnDate;
  final String? remarks;
  final String? reason;
  final List<CreateReturnFromDeliveryLineModel> lines;

  /// When set, POST /api/erp/returns/from-delivery links the document to this visit.
  final String? visitId;

  /// Document warehouse from header / default.
  final String? warehouseCode;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'deliveryDocEntry': deliveryDocEntry,
      'returnDate': returnDate.toUtc().toIso8601String(),
      'remarks': remarks?.trim() ?? '',
      'reason': reason?.trim() ?? '',
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

class CreateReturnFromDeliveryLineModel {
  const CreateReturnFromDeliveryLineModel({
    required this.baseLine,
    required this.quantity,
    this.warehouseCode,
    this.batchNumbers,
  });

  final int baseLine;
  final num quantity;
  final String? warehouseCode;

  /// From delivery line batches; POST `lines[].batchNumbers`.
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
