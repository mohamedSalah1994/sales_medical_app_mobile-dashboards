import 'package:sales_medical_app_mobile/features/targets/domain/entities/target_detail.dart';

class TargetDetailModel extends TargetDetail {
  const TargetDetailModel({
    required super.id,
    required super.productCode,
    required super.itemName,
    required super.value,
    required super.achievedValue,
    required super.sequenceNo,
  });

  factory TargetDetailModel.fromJson(Map<String, dynamic> json) {
    return TargetDetailModel(
      id: json['id'] as String,
      productCode: json['productCode'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      achievedValue: (json['achievedValue'] as num?)?.toDouble() ?? 0.0,
      sequenceNo: json['sequenceNo'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productCode': productCode,
      'itemName': itemName,
      'value': value,
      'achievedValue': achievedValue,
      'sequenceNo': sequenceNo,
    };
  }
}
