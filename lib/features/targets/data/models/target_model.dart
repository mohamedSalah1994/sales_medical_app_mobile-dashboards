import 'package:sales_medical_app_mobile/features/targets/domain/entities/target.dart';
import 'package:sales_medical_app_mobile/features/targets/data/models/target_breakdown_model.dart';

class TargetModel extends Target {
  const TargetModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.periodType,
    required super.startDate,
    required super.endDate,
    required super.breakdowns,
    required super.createdAt,
    required super.createdBy,
  });

  factory TargetModel.fromJson(Map<String, dynamic> json) {
    return TargetModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String? ?? '',
      periodType: _parsePeriodType(json['periodType']),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      breakdowns:
          (json['breakdowns'] as List<dynamic>?)
              ?.map(
                (e) => TargetBreakdownModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String? ?? '',
    );
  }

  /// Accepts API values as either int (1..5) or string ("Day"/"Week"/...).
  /// Returns 0 when the value cannot be resolved.
  static int _parsePeriodType(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final parsed = int.tryParse(raw.trim());
      if (parsed != null) return parsed;
      switch (raw.trim().toLowerCase()) {
        case 'day':
        case 'daily':
          return 1;
        case 'week':
        case 'weekly':
          return 2;
        case 'month':
        case 'monthly':
          return 3;
        case 'quarter':
        case 'quarterly':
          return 4;
        case 'year':
        case 'yearly':
        case 'annual':
        case 'annually':
          return 5;
      }
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'periodType': periodType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'breakdowns':
          breakdowns
              .map((breakdown) => (breakdown as TargetBreakdownModel).toJson())
              .toList(),
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }
}
