import 'package:sales_medical_app_mobile/features/journey_plan/data/models/visit_enum_json_codec.dart';

/// Request body for POST /api/Visits (standalone visit).
class CreateVisitRequestModel {
  final String userId;
  final String customerCode;
  final String customerName;
  final DateTime plannedDateTime;
  final int visitType;
  final String? supervisorId;
  final String? googleMapsLink;
  final String? notes;

  CreateVisitRequestModel({
    required this.userId,
    required this.customerCode,
    required this.customerName,
    required this.plannedDateTime,
    required this.visitType,
    this.supervisorId,
    this.googleMapsLink,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'customerCode': customerCode,
      'customerName': customerName,
      'plannedDateTime': plannedDateTime.toIso8601String(),
      'visitType': visitTypeToApiValue(visitType),
      if (supervisorId != null && supervisorId!.isNotEmpty) 'supervisorId': supervisorId,
      if (googleMapsLink != null && googleMapsLink!.isNotEmpty) 'googleMapsLink': googleMapsLink,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}
