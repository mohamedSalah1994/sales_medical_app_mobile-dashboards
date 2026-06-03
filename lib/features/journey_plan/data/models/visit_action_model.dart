import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit_action.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/visit_enum_json_codec.dart';

class VisitActionModel extends VisitAction {
  const VisitActionModel({
    required super.id,
    required super.actionCode,
    super.actionName,
    super.status,
    super.sapDocumentNumber,
    super.sapDocumentId,
    super.postedAt,
  });

  factory VisitActionModel.fromJson(Map<String, dynamic> json) {
    return VisitActionModel(
      id: json['id'] as String,
      actionCode: json['actionCode'] as String? ?? '',
      actionName: json['actionName'] as String?,
      status: visitActionStatusFromJson(json['status']),
      sapDocumentNumber: json['sapDocumentNumber'] as String?,
      sapDocumentId: json['sapDocumentId']?.toString(),
      postedAt: json['postedAt'] != null
          ? DateTime.tryParse(json['postedAt'] as String)
          : null,
    );
  }
}
