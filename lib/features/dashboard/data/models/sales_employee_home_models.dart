/// Sales-Employee Home DTO + sub-DTOs (matching the backend SalesEmployeeHomeDto).
/// Lives next to dashboard_models.dart so the mobile feature folder is self-contained.

import 'package:sales_medical_app_mobile/features/dashboard/data/models/dashboard_models.dart';

class NextVisit {
  final String visitId;
  final String customerCode;
  final String customerName;
  final String? addressLine;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final String? googleMapsLink;
  const NextVisit({
    required this.visitId,
    required this.customerCode,
    required this.customerName,
    this.addressLine,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.googleMapsLink,
  });
  factory NextVisit.fromJson(Map<String, dynamic> j) => NextVisit(
        visitId: j['visitId'] as String? ?? '',
        customerCode: j['customerCode'] as String? ?? '',
        customerName: j['customerName'] as String? ?? '',
        addressLine: j['addressLine'] as String?,
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        distanceKm: (j['distanceKm'] as num?)?.toDouble(),
        googleMapsLink: j['googleMapsLink'] as String?,
      );
}

class TodaysJourney {
  final String? journeyPlanId;
  final DateTime date;
  final int plannedStops;
  final int completedStops;
  final double completedPct;
  final NextVisit? nextVisit;
  const TodaysJourney({
    this.journeyPlanId,
    required this.date,
    required this.plannedStops,
    required this.completedStops,
    required this.completedPct,
    this.nextVisit,
  });
  factory TodaysJourney.fromJson(Map<String, dynamic> j) => TodaysJourney(
        journeyPlanId: j['journeyPlanId'] as String?,
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        plannedStops: (j['plannedStops'] as num?)?.toInt() ?? 0,
        completedStops: (j['completedStops'] as num?)?.toInt() ?? 0,
        completedPct: (j['completedPct'] as num?)?.toDouble() ?? 0,
        nextVisit: j['nextVisit'] != null
            ? NextVisit.fromJson(j['nextVisit'] as Map<String, dynamic>)
            : null,
      );
}

class TargetsSummary {
  final int totalTargets;
  final int activeTargets;
  final double avgProgressPct;
  final double achievedPct;
  const TargetsSummary({
    required this.totalTargets,
    required this.activeTargets,
    required this.avgProgressPct,
    required this.achievedPct,
  });
  factory TargetsSummary.fromJson(Map<String, dynamic> j) => TargetsSummary(
        totalTargets: (j['totalTargets'] as num?)?.toInt() ?? 0,
        activeTargets: (j['activeTargets'] as num?)?.toInt() ?? 0,
        avgProgressPct: (j['avgProgressPct'] as num?)?.toDouble() ?? 0,
        achievedPct: (j['achievedPct'] as num?)?.toDouble() ?? 0,
      );
}

class TodaySummary {
  final double distanceKm;
  final Duration timeOnVisit;
  final Duration averageVisitTime;
  final int customersVisited;
  const TodaySummary({
    required this.distanceKm,
    required this.timeOnVisit,
    required this.averageVisitTime,
    required this.customersVisited,
  });
  factory TodaySummary.fromJson(Map<String, dynamic> j) => TodaySummary(
        distanceKm: (j['distanceKm'] as num?)?.toDouble() ?? 0,
        timeOnVisit: _parseDuration(j['timeOnVisit']),
        averageVisitTime: _parseDuration(j['averageVisitTime']),
        customersVisited: (j['customersVisited'] as num?)?.toInt() ?? 0,
      );
}

class SalesEmployeeHome {
  final DateRange period;
  final KpiCount todaysVisits;
  final KpiAmount todaysTarget;
  final KpiAmount collections;
  final KpiCount orders;
  final TodaysJourney todaysJourney;
  final KpiWithSpark sales7Day;
  final KpiWithSpark collections7Day;
  final KpiWithSpark returnsPct7Day;
  final KpiWithSpark orders7Day;
  final TargetsSummary targets;
  final List<ActivityItem> recentActivity;
  final TodaySummary todaySummary;
  final DateTime generatedAt;
  const SalesEmployeeHome({
    required this.period,
    required this.todaysVisits,
    required this.todaysTarget,
    required this.collections,
    required this.orders,
    required this.todaysJourney,
    required this.sales7Day,
    required this.collections7Day,
    required this.returnsPct7Day,
    required this.orders7Day,
    required this.targets,
    required this.recentActivity,
    required this.todaySummary,
    required this.generatedAt,
  });
  factory SalesEmployeeHome.fromJson(Map<String, dynamic> j) => SalesEmployeeHome(
        period: DateRange.fromJson(j['period'] as Map<String, dynamic>),
        todaysVisits: KpiCount.fromJson(j['todaysVisits'] as Map<String, dynamic>),
        todaysTarget: KpiAmount.fromJson(j['todaysTarget'] as Map<String, dynamic>),
        collections: KpiAmount.fromJson(j['collections'] as Map<String, dynamic>),
        orders: KpiCount.fromJson(j['orders'] as Map<String, dynamic>),
        todaysJourney: TodaysJourney.fromJson(j['todaysJourney'] as Map<String, dynamic>),
        sales7Day: KpiWithSpark.fromJson(j['sales7Day'] as Map<String, dynamic>),
        collections7Day: KpiWithSpark.fromJson(j['collections7Day'] as Map<String, dynamic>),
        returnsPct7Day: KpiWithSpark.fromJson(j['returnsPct7Day'] as Map<String, dynamic>),
        orders7Day: KpiWithSpark.fromJson(j['orders7Day'] as Map<String, dynamic>),
        targets: TargetsSummary.fromJson(j['targets'] as Map<String, dynamic>),
        recentActivity: ((j['recentActivity'] as List?) ?? const [])
            .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        todaySummary: TodaySummary.fromJson(j['todaySummary'] as Map<String, dynamic>),
        generatedAt:
            DateTime.tryParse(j['generatedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

Duration _parseDuration(dynamic raw) {
  if (raw is String) {
    // Server emits TimeSpan as "hh:mm:ss" or "d.hh:mm:ss". Best-effort parse.
    final s = raw;
    final parts = s.split(':');
    if (parts.length == 3) {
      var hours = parts[0];
      int days = 0;
      if (hours.contains('.')) {
        final dh = hours.split('.');
        days = int.tryParse(dh[0]) ?? 0;
        hours = dh[1];
      }
      final h = int.tryParse(hours) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final sec = double.tryParse(parts[2]) ?? 0;
      return Duration(
        days: days,
        hours: h,
        minutes: m,
        seconds: sec.floor(),
      );
    }
    final n = int.tryParse(s);
    if (n != null) return Duration(milliseconds: n);
  }
  if (raw is num) {
    return Duration(milliseconds: raw.toInt());
  }
  return Duration.zero;
}
