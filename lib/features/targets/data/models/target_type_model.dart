import 'package:sales_medical_app_mobile/features/targets/domain/entities/target_type.dart';

class TargetTypeModel extends TargetType {
  const TargetTypeModel({
    required super.id,
    required super.name,
    required super.code,
    required super.description,
    required super.isActive,
    required super.canHaveDetails,
    required super.displayOrder,
  });

  factory TargetTypeModel.fromJson(Map<String, dynamic> json) {
    return TargetTypeModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      canHaveDetails: json['canHaveDetails'] as bool? ?? false,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'isActive': isActive,
      'canHaveDetails': canHaveDetails,
      'displayOrder': displayOrder,
    };
  }
}
