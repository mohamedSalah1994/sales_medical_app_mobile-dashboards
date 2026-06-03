import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/journey_plan.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/created_by_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/stop_model.dart';

/// Maps API plan type values (string enum or legacy int) to app [planType] 1–5.
int journeyPlanTypeFromJson(dynamic value) {
  if (value == null) return 1;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
    switch (value.trim().toLowerCase()) {
      case 'day':
        return 1;
      case 'week':
        return 2;
      case 'month':
        return 3;
      case 'quarter':
        return 4;
      case 'year':
        return 5;
    }
  }
  return 1;
}

/// Serializes [planType] for API requests (string enum).
String journeyPlanTypeToApiValue(int planType) {
  switch (planType) {
    case 1:
      return 'Day';
    case 2:
      return 'Week';
    case 3:
      return 'Month';
    case 4:
      return 'Quarter';
    case 5:
      return 'Year';
    default:
      return 'Day';
  }
}

class JourneyPlanModel extends JourneyPlan {
  const JourneyPlanModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.createdByUserId,
    required super.createdByUserName,
    super.createdBy,
    required super.planType,
    required super.startDate,
    required super.endDate,
    required super.notes,
    required super.isApproved,
    super.approvedAt,
    required super.stops,
    required super.createdAt,
  });

  factory JourneyPlanModel.fromJson(Map<String, dynamic> json) {
    // Handle both old format (createdByUserId/createdByUserName) and new format (createdBy object)
    String createdByUserId;
    String createdByUserName;
    CreatedByModel? createdBy;

    if (json['createdBy'] != null) {
      // New format with createdBy object
      createdBy = CreatedByModel.fromJson(json['createdBy'] as Map<String, dynamic>);
      createdByUserId = createdBy.id;
      createdByUserName = createdBy.fullName;
    } else {
      // Old format with createdByUserId/createdByUserName
      createdByUserId = json['createdByUserId'] as String? ?? '';
      createdByUserName = json['createdByUserName'] as String? ?? '';
    }

    return JourneyPlanModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String? ?? '',
      createdByUserId: createdByUserId,
      createdByUserName: createdByUserName,
      createdBy: createdBy,
      planType: journeyPlanTypeFromJson(json['planType']),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      notes: json['notes'] as String? ?? '',
      isApproved: json['isApproved'] as bool? ?? false,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      stops: (json['stops'] as List<dynamic>?)
              ?.map((e) => StopModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// First moment of the day (00:00:00.000) for API request.
  static DateTime _startOfDay(DateTime d) {
    return DateTime(d.year, d.month, d.day, 0, 0, 0, 0);
  }

  /// Last moment of the day (23:59:59.999) for API request.
  static DateTime _endOfDay(DateTime d) {
    return DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'createdByUserId': createdByUserId,
      'createdByUserName': createdByUserName,
      'planType': journeyPlanTypeToApiValue(planType),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'notes': notes,
      'isApproved': isApproved,
      'approvedAt': approvedAt?.toIso8601String(),
      'stops': stops.map((stop) => (stop as StopModel).toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'userId': userId,
      'planType': journeyPlanTypeToApiValue(planType),
      'startDate': _startOfDay(startDate).toIso8601String(),
      'endDate': _endOfDay(endDate).toIso8601String(),
      'notes': notes,
      'stops': [],
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'userId': userId,
      'planType': journeyPlanTypeToApiValue(planType),
      'startDate': _startOfDay(startDate).toIso8601String(),
      'endDate': _endOfDay(endDate).toIso8601String(),
      'notes': notes,
      'stops': stops.map((stop) {
        return {
          'visitId': stop.visitId,
          'sequenceNo': stop.sequenceNo,
          'plannedTime': stop.plannedTime.toIso8601String(),
          'estimatedDurationMinutes': stop.estimatedDurationMinutes,
        };
      }).toList(),
    };
  }
}
