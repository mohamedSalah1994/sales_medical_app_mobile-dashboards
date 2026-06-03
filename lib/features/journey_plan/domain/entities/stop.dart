import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit.dart';

class Stop {
  final String id;
  final String visitId;
  final int sequenceNo;
  final DateTime plannedTime;
  final int estimatedDurationMinutes;
  final Visit? visit;

  const Stop({
    required this.id,
    required this.visitId,
    required this.sequenceNo,
    required this.plannedTime,
    required this.estimatedDurationMinutes,
    required this.visit,
  });
}
