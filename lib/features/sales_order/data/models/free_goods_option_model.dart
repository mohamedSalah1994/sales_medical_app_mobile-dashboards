/// Option from GET `/api/erp/sales-orders/getFreeGoodsList`.
class FreeGoodsOptionModel {
  const FreeGoodsOptionModel({
    required this.code,
    this.name,
  });

  final String code;
  final String? name;

  factory FreeGoodsOptionModel.fromJson(Map<String, dynamic> json) {
    return FreeGoodsOptionModel(
      code: json['code'] as String? ?? '',
      name: json['name'] as String?,
    );
  }
}
