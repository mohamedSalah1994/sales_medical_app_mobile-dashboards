import 'package:sales_medical_app_mobile/features/targets/domain/entities/target_breakdown.dart';

class Target {
  final String id;
  final String userId;
  final String userName;
  final int periodType;
  final DateTime startDate;
  final DateTime endDate;
  final List<TargetBreakdown> breakdowns;
  final DateTime createdAt;
  final String createdBy;

  const Target({
    required this.id,
    required this.userId,
    required this.userName,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.breakdowns,
    required this.createdAt,
    required this.createdBy,
  });
}
