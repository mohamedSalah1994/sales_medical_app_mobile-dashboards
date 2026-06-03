/// One row from GET /api/MasterData/items/{itemCode}/batch-quantities
class ItemBatchQuantityModel {
  const ItemBatchQuantityModel({
    required this.batchNumber,
    required this.quantity,
  });

  final String batchNumber;
  final double quantity;

  factory ItemBatchQuantityModel.fromJson(Map<String, dynamic> json) {
    return ItemBatchQuantityModel(
      batchNumber: json['batchNumber']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
    );
  }
}
