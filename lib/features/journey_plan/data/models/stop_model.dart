import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/stop.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/visit_model.dart';

class StopModel extends Stop {
  const StopModel({
    required super.id,
    required super.visitId,
    required super.sequenceNo,
    required super.plannedTime,
    required super.estimatedDurationMinutes,
    required super.visit,
  });

  factory StopModel.fromJson(Map<String, dynamic> json) {
    final estimatedDuration =
        (json['estimatedDurationMinutes'] as num?)?.toInt() ?? 30;
    return StopModel(
      id: json['id'] as String,
      visitId: json['visitId'] as String,
      sequenceNo: json['sequenceNo'] as int,
      plannedTime: DateTime.parse(json['plannedTime'] as String),
      estimatedDurationMinutes: estimatedDuration,
      visit: json['visit'] != null
          ? VisitModel.fromJson(json['visit'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visitId': visitId,
      'sequenceNo': sequenceNo,
      'plannedTime': plannedTime.toIso8601String(),
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'visit': visit != null ? (visit as VisitModel).toJson() : null,
    };
  }
}
