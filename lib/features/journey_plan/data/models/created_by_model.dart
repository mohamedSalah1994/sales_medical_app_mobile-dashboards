import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/created_by.dart';

class CreatedByModel extends CreatedBy {
  const CreatedByModel({
    required super.id,
    required super.fullName,
    required super.username,
  });

  factory CreatedByModel.fromJson(Map<String, dynamic> json) {
    return CreatedByModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? '',
      username: json['username'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'username': username,
    };
  }
}
