import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/created_by.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/stop.dart';

class JourneyPlan {
  final String id;
  final String userId;
  final String userName;
  final String createdByUserId; // Keep for backward compatibility
  final String createdByUserName; // Keep for backward compatibility
  final CreatedBy? createdBy; // New object structure
  final int planType;
  final DateTime startDate;
  final DateTime endDate;
  final String notes;
  final bool isApproved;
  final DateTime? approvedAt;
  final List<Stop> stops;
  final DateTime createdAt;

  const JourneyPlan({
    required this.id,
    required this.userId,
    required this.userName,
    required this.createdByUserId,
    required this.createdByUserName,
    this.createdBy,
    required this.planType,
    required this.startDate,
    required this.endDate,
    required this.notes,
    required this.isApproved,
    this.approvedAt,
    required this.stops,
    required this.createdAt,
  });
}
