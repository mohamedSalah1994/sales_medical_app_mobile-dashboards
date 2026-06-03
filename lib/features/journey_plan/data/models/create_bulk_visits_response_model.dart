import 'package:sales_medical_app_mobile/features/journey_plan/data/models/journey_plan_model.dart';

class CreatedBulkVisitModel {
  final String visitId;
  final String stopId;
  final int sequenceNo;
  final String customerCode;
  final String customerName;

  const CreatedBulkVisitModel({
    required this.visitId,
    required this.stopId,
    required this.sequenceNo,
    required this.customerCode,
    required this.customerName,
  });

  factory CreatedBulkVisitModel.fromJson(Map<String, dynamic> json) {
    return CreatedBulkVisitModel(
      visitId: json['visitId'] as String? ?? '',
      stopId: json['stopId'] as String? ?? '',
      sequenceNo: json['sequenceNo'] as int? ?? 0,
      customerCode: json['customerCode'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
    );
  }
}

class CreateBulkVisitsResponseModel {
  final JourneyPlanModel journeyPlan;
  final List<CreatedBulkVisitModel> created;

  const CreateBulkVisitsResponseModel({
    required this.journeyPlan,
    required this.created,
  });

  factory CreateBulkVisitsResponseModel.fromJson(Map<String, dynamic> json) {
    return CreateBulkVisitsResponseModel(
      journeyPlan: JourneyPlanModel.fromJson(
        json['journeyPlan'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      created:
          (json['created'] as List<dynamic>?)
              ?.map(
                (item) =>
                    CreatedBulkVisitModel.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}
