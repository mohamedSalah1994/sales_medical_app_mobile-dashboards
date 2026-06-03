import 'package:sales_medical_app_mobile/features/targets/domain/entities/target_breakdown.dart';
import 'package:sales_medical_app_mobile/features/targets/data/models/target_type_model.dart';
import 'package:sales_medical_app_mobile/features/targets/data/models/target_detail_model.dart';

class TargetBreakdownModel extends TargetBreakdown {
  const TargetBreakdownModel({
    required super.id,
    required super.targetTypeId,
    required super.targetType,
    required super.value,
    required super.achievedValue,
    required super.details,
    required super.detailsTotal,
    required super.remainingAmount,
    required super.canHaveDetails,
  });

  factory TargetBreakdownModel.fromJson(Map<String, dynamic> json) {
    return TargetBreakdownModel(
      id: json['id'] as String,
      targetTypeId: json['targetTypeId'] as String,
      targetType: TargetTypeModel.fromJson(
        json['targetType'] as Map<String, dynamic>,
      ),
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      achievedValue: (json['achievedValue'] as num?)?.toDouble() ?? 0.0,
      details: (json['details'] as List<dynamic>?)
              ?.map((e) => TargetDetailModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      detailsTotal: (json['detailsTotal'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      canHaveDetails: json['canHaveDetails'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetTypeId': targetTypeId,
      'targetType': (targetType as TargetTypeModel).toJson(),
      'value': value,
      'achievedValue': achievedValue,
      'details': details
          .map((detail) => (detail as TargetDetailModel).toJson())
          .toList(),
      'detailsTotal': detailsTotal,
      'remainingAmount': remainingAmount,
      'canHaveDetails': canHaveDetails,
    };
  }
}
