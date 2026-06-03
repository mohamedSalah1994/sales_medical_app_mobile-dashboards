import 'package:sales_medical_app_mobile/features/journey_plan/data/models/visit_enum_json_codec.dart';

class CreateStopRequestModel {
  final String customerCode;
  final String customerName;
  final DateTime plannedDateTime;
  final int visitType;
  final String? supervisorId;
  final String? notes;
  final DateTime plannedTime;
  final int estimatedDurationMinutes;
  final String? googleMapsLink;

  CreateStopRequestModel({
    required this.customerCode,
    required this.customerName,
    required this.plannedDateTime,
    required this.visitType,
    this.supervisorId,
    this.notes,
    required this.plannedTime,
    required this.estimatedDurationMinutes,
    this.googleMapsLink,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerCode': customerCode,
      'customerName': customerName,
      'plannedDateTime': plannedDateTime.toIso8601String(),
      'visitType': visitTypeToApiValue(visitType),
      if (supervisorId != null && supervisorId!.isNotEmpty) 'supervisorId': supervisorId,
      if (googleMapsLink != null && googleMapsLink!.isNotEmpty) 'googleMapsLink': googleMapsLink,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'plannedTime': plannedTime.toIso8601String(),
      'estimatedDurationMinutes': estimatedDurationMinutes,
    };
  }
}
