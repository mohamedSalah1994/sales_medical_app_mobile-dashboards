import 'package:sales_medical_app_mobile/features/journey_plan/data/models/visit_enum_json_codec.dart';

class UpdateVisitRequestModel {
  final String? userId;
  final String? customerId;
  final DateTime? plannedDateTime;
  final int? visitType;
  final String? supervisorId;
  final String? googleMapsLink;
  final String? notes;
  final int? status;

  UpdateVisitRequestModel({
    this.userId,
    this.customerId,
    this.plannedDateTime,
    this.visitType,
    this.supervisorId,
    this.googleMapsLink,
    this.notes,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'userId': userId,
      if (customerId != null) 'customerId': customerId,
      if (plannedDateTime != null)
        'plannedDateTime': plannedDateTime!.toIso8601String(),
      if (visitType != null) 'visitType': visitTypeToApiValue(visitType!),
      if (supervisorId != null) 'supervisorId': supervisorId,
      if (googleMapsLink != null) 'googleMapsLink': googleMapsLink,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (status != null) 'status': visitStatusToApiValue(status!),
    };
  }
}
