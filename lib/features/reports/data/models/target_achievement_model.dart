class TargetAchievementModel {
  const TargetAchievementModel({
    required this.hasTarget,
    required this.summary,
    required this.items,
    required this.employees,
  });

  final bool hasTarget;
  final TargetAchievementSummaryModel summary;
  final List<TargetAchievementItemModel> items;
  final List<TargetAchievementEmployeeModel> employees;

  factory TargetAchievementModel.fromJson(Map<String, dynamic> json) {
    return TargetAchievementModel(
      hasTarget: json['hasTarget'] as bool? ?? false,
      summary: json['summary'] is Map<String, dynamic>
          ? TargetAchievementSummaryModel.fromJson(
              json['summary'] as Map<String, dynamic>,
            )
          : const TargetAchievementSummaryModel(),
      items: (json['items'] as List<dynamic>?)
              ?.map(
                (e) => TargetAchievementItemModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      employees: (json['employees'] as List<dynamic>?)
              ?.map(
                (e) => TargetAchievementEmployeeModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
    );
  }
}

class TargetAchievementSummaryModel {
  const TargetAchievementSummaryModel({
    this.targetQuantity = 0,
    this.actualQuantity = 0,
    this.quantityAchievementPct = 0,
    this.targetValue = 0,
    this.actualValue = 0,
    this.valueAchievementPct = 0,
    this.plannedVisits = 0,
    this.actualVisits = 0,
    this.visitAchievementPct = 0,
    this.missedVisits = 0,
  });

  final double targetQuantity;
  final double actualQuantity;
  final double quantityAchievementPct;
  final double targetValue;
  final double actualValue;
  final double valueAchievementPct;
  final int plannedVisits;
  final int actualVisits;
  final double visitAchievementPct;
  final int missedVisits;

  factory TargetAchievementSummaryModel.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) {
      if (v == null) return 0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    int i(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return TargetAchievementSummaryModel(
      targetQuantity: d(json['targetQuantity']),
      actualQuantity: d(json['actualQuantity']),
      quantityAchievementPct: d(json['quantityAchievementPct']),
      targetValue: d(json['targetValue']),
      actualValue: d(json['actualValue']),
      valueAchievementPct: d(json['valueAchievementPct']),
      plannedVisits: i(json['plannedVisits']),
      actualVisits: i(json['actualVisits']),
      visitAchievementPct: d(json['visitAchievementPct']),
      missedVisits: i(json['missedVisits']),
    );
  }
}

class TargetAchievementItemModel {
  const TargetAchievementItemModel({
    required this.itemCode,
    required this.itemName,
    required this.targetQuantity,
    required this.targetValue,
    required this.actualQuantity,
    required this.actualValue,
    required this.quantityPct,
    required this.valuePct,
  });

  final String itemCode;
  final String itemName;
  final double targetQuantity;
  final double targetValue;
  final double actualQuantity;
  final double actualValue;
  final double quantityPct;
  final double valuePct;

  factory TargetAchievementItemModel.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) {
      if (v == null) return 0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return TargetAchievementItemModel(
      itemCode: json['itemCode']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      targetQuantity: d(json['targetQuantity']),
      targetValue: d(json['targetValue']),
      actualQuantity: d(json['actualQuantity']),
      actualValue: d(json['actualValue']),
      quantityPct: d(json['quantityPct']),
      valuePct: d(json['valuePct']),
    );
  }
}

class TargetAchievementEmployeeModel {
  const TargetAchievementEmployeeModel({
    required this.userId,
    required this.fullName,
    required this.initials,
    required this.hasTarget,
    required this.visitAchievementPct,
    required this.quantityAchievementPct,
    required this.valueAchievementPct,
  });

  final String userId;
  final String fullName;
  final String initials;
  final bool hasTarget;
  final double visitAchievementPct;
  final double quantityAchievementPct;
  final double valueAchievementPct;

  factory TargetAchievementEmployeeModel.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) {
      if (v == null) return 0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return TargetAchievementEmployeeModel(
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      initials: json['initials']?.toString() ?? '',
      hasTarget: json['hasTarget'] as bool? ?? false,
      visitAchievementPct: d(json['visitAchievementPct']),
      quantityAchievementPct: d(json['quantityAchievementPct']),
      valueAchievementPct: d(json['valueAchievementPct']),
    );
  }
}
