/// Dashboard DTOs mirroring `MAK_MedicalSalesAPI/src/DKT.SalesForce.API/DTOs/Dashboard/*`.
/// Hand-written JSON converters — keeps the build light (no codegen dependency).

class DateRange {
  final DateTime from;
  final DateTime to;
  const DateRange({required this.from, required this.to});
  factory DateRange.fromJson(Map<String, dynamic> j) => DateRange(
        from: DateTime.parse(j['from'] as String),
        to: DateTime.parse(j['to'] as String),
      );
}

class KpiCount {
  final String label;
  final int value;
  final int? total;
  final double? deltaPct;
  final String? deltaPeriodLabel;
  final double? pct;
  const KpiCount({
    required this.label,
    required this.value,
    this.total,
    this.deltaPct,
    this.deltaPeriodLabel,
    this.pct,
  });
  factory KpiCount.fromJson(Map<String, dynamic> j) => KpiCount(
        label: j['label'] as String? ?? '',
        value: (j['value'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt(),
        deltaPct: (j['deltaPct'] as num?)?.toDouble(),
        deltaPeriodLabel: j['deltaPeriodLabel'] as String?,
        pct: (j['pct'] as num?)?.toDouble(),
      );
}

class KpiAmount {
  final String label;
  final double value;
  final String currency;
  final double? deltaPct;
  final String? deltaPeriodLabel;
  final int? relatedCount;
  final String? relatedCountLabel;
  const KpiAmount({
    required this.label,
    required this.value,
    this.currency = 'EGP',
    this.deltaPct,
    this.deltaPeriodLabel,
    this.relatedCount,
    this.relatedCountLabel,
  });
  factory KpiAmount.fromJson(Map<String, dynamic> j) => KpiAmount(
        label: j['label'] as String? ?? '',
        value: (j['value'] as num?)?.toDouble() ?? 0,
        currency: j['currency'] as String? ?? 'EGP',
        deltaPct: (j['deltaPct'] as num?)?.toDouble(),
        deltaPeriodLabel: j['deltaPeriodLabel'] as String?,
        relatedCount: (j['relatedCount'] as num?)?.toInt(),
        relatedCountLabel: j['relatedCountLabel'] as String?,
      );
}

class KpiPercent {
  final String label;
  final double pct;
  final double? deltaPct;
  final String? deltaPeriodLabel;
  const KpiPercent({
    required this.label,
    required this.pct,
    this.deltaPct,
    this.deltaPeriodLabel,
  });
  factory KpiPercent.fromJson(Map<String, dynamic> j) => KpiPercent(
        label: j['label'] as String? ?? '',
        pct: (j['pct'] as num?)?.toDouble() ?? 0,
        deltaPct: (j['deltaPct'] as num?)?.toDouble(),
        deltaPeriodLabel: j['deltaPeriodLabel'] as String?,
      );
}

class KpiWithSpark {
  final String label;
  final double value;
  final String? currency;
  final double? deltaPct;
  final String? deltaPeriodLabel;
  final List<double> sparkPoints;
  const KpiWithSpark({
    required this.label,
    required this.value,
    this.currency,
    this.deltaPct,
    this.deltaPeriodLabel,
    this.sparkPoints = const [],
  });
  factory KpiWithSpark.fromJson(Map<String, dynamic> j) => KpiWithSpark(
        label: j['label'] as String? ?? '',
        value: (j['value'] as num?)?.toDouble() ?? 0,
        currency: j['currency'] as String?,
        deltaPct: (j['deltaPct'] as num?)?.toDouble(),
        deltaPeriodLabel: j['deltaPeriodLabel'] as String?,
        sparkPoints: ((j['sparkPoints'] as List?) ?? const [])
            .map((e) => (e as num).toDouble())
            .toList(),
      );
}

class NamedSeries {
  final String name;
  final List<double> points;
  const NamedSeries({required this.name, required this.points});
  factory NamedSeries.fromJson(Map<String, dynamic> j) => NamedSeries(
        name: j['name'] as String? ?? '',
        points: ((j['points'] as List?) ?? const [])
            .map((e) => (e as num).toDouble())
            .toList(),
      );
}

class SparkSeries {
  final List<String> labels;
  final List<NamedSeries> series;
  const SparkSeries({required this.labels, required this.series});
  factory SparkSeries.fromJson(Map<String, dynamic> j) => SparkSeries(
        labels: ((j['labels'] as List?) ?? const []).map((e) => e as String).toList(),
        series: ((j['series'] as List?) ?? const [])
            .map((e) => NamedSeries.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AreaBreakdown {
  final String areaName;
  final String? areaCode;
  final double value;
  final double sharePct;
  const AreaBreakdown({
    required this.areaName,
    this.areaCode,
    required this.value,
    required this.sharePct,
  });
  factory AreaBreakdown.fromJson(Map<String, dynamic> j) => AreaBreakdown(
        areaName: j['areaName'] as String? ?? '',
        areaCode: j['areaCode'] as String?,
        value: (j['value'] as num?)?.toDouble() ?? 0,
        sharePct: (j['sharePct'] as num?)?.toDouble() ?? 0,
      );
}

class TargetVsActualPoint {
  final String label;
  final double target;
  final double actual;
  final double achievementPct;
  const TargetVsActualPoint({
    required this.label,
    required this.target,
    required this.actual,
    required this.achievementPct,
  });
  factory TargetVsActualPoint.fromJson(Map<String, dynamic> j) => TargetVsActualPoint(
        label: j['label'] as String? ?? '',
        target: (j['target'] as num?)?.toDouble() ?? 0,
        actual: (j['actual'] as num?)?.toDouble() ?? 0,
        achievementPct: (j['achievementPct'] as num?)?.toDouble() ?? 0,
      );
}

class VisitAchievementBreakdown {
  final int completed;
  final int inProgress;
  final int planned;
  final int missed;
  final int total;
  final double completedPct;
  const VisitAchievementBreakdown({
    required this.completed,
    required this.inProgress,
    required this.planned,
    required this.missed,
    required this.total,
    required this.completedPct,
  });
  factory VisitAchievementBreakdown.fromJson(Map<String, dynamic> j) =>
      VisitAchievementBreakdown(
        completed: (j['completed'] as num?)?.toInt() ?? 0,
        inProgress: (j['inProgress'] as num?)?.toInt() ?? 0,
        planned: (j['planned'] as num?)?.toInt() ?? 0,
        missed: (j['missed'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt() ?? 0,
        completedPct: (j['completedPct'] as num?)?.toDouble() ?? 0,
      );
}

class VisitStatusByRep {
  final String userId;
  final String fullName;
  final String initials;
  final int planned;
  final int completed;
  final int missed;
  final double achievementPct;
  const VisitStatusByRep({
    required this.userId,
    required this.fullName,
    required this.initials,
    required this.planned,
    required this.completed,
    required this.missed,
    required this.achievementPct,
  });
  factory VisitStatusByRep.fromJson(Map<String, dynamic> j) => VisitStatusByRep(
        userId: j['userId'] as String? ?? '',
        fullName: j['fullName'] as String? ?? '',
        initials: j['initials'] as String? ?? '',
        planned: (j['planned'] as num?)?.toInt() ?? 0,
        completed: (j['completed'] as num?)?.toInt() ?? 0,
        missed: (j['missed'] as num?)?.toInt() ?? 0,
        achievementPct: (j['achievementPct'] as num?)?.toDouble() ?? 0,
      );
}

class VisitsOverview {
  final int completed;
  final int planned;
  final int missed;
  final int cancelled;
  final double completedPct;
  final double plannedPct;
  final double missedPct;
  final double cancelledPct;
  const VisitsOverview({
    required this.completed,
    required this.planned,
    required this.missed,
    required this.cancelled,
    required this.completedPct,
    required this.plannedPct,
    required this.missedPct,
    required this.cancelledPct,
  });
  factory VisitsOverview.fromJson(Map<String, dynamic> j) => VisitsOverview(
        completed: (j['completed'] as num?)?.toInt() ?? 0,
        planned: (j['planned'] as num?)?.toInt() ?? 0,
        missed: (j['missed'] as num?)?.toInt() ?? 0,
        cancelled: (j['cancelled'] as num?)?.toInt() ?? 0,
        completedPct: (j['completedPct'] as num?)?.toDouble() ?? 0,
        plannedPct: (j['plannedPct'] as num?)?.toDouble() ?? 0,
        missedPct: (j['missedPct'] as num?)?.toDouble() ?? 0,
        cancelledPct: (j['cancelledPct'] as num?)?.toDouble() ?? 0,
      );
}

class CollectionOverview {
  final double totalDue;
  final double collected;
  final double outstanding;
  final double overdue;
  final double collectionRatePct;
  final String currency;
  const CollectionOverview({
    required this.totalDue,
    required this.collected,
    required this.outstanding,
    required this.overdue,
    required this.collectionRatePct,
    this.currency = 'EGP',
  });
  factory CollectionOverview.fromJson(Map<String, dynamic> j) => CollectionOverview(
        totalDue: (j['totalDue'] as num?)?.toDouble() ?? 0,
        collected: (j['collected'] as num?)?.toDouble() ?? 0,
        outstanding: (j['outstanding'] as num?)?.toDouble() ?? 0,
        overdue: (j['overdue'] as num?)?.toDouble() ?? 0,
        collectionRatePct: (j['collectionRatePct'] as num?)?.toDouble() ?? 0,
        currency: j['currency'] as String? ?? 'EGP',
      );
}

class TodayPlanSummary {
  final int plannedVisits;
  final int completed;
  final int remaining;
  final double dailyTarget;
  final double achieved;
  final String currency;
  final double achievementPct;
  const TodayPlanSummary({
    required this.plannedVisits,
    required this.completed,
    required this.remaining,
    required this.dailyTarget,
    required this.achieved,
    this.currency = 'EGP',
    required this.achievementPct,
  });
  factory TodayPlanSummary.fromJson(Map<String, dynamic> j) => TodayPlanSummary(
        plannedVisits: (j['plannedVisits'] as num?)?.toInt() ?? 0,
        completed: (j['completed'] as num?)?.toInt() ?? 0,
        remaining: (j['remaining'] as num?)?.toInt() ?? 0,
        dailyTarget: (j['dailyTarget'] as num?)?.toDouble() ?? 0,
        achieved: (j['achieved'] as num?)?.toDouble() ?? 0,
        currency: j['currency'] as String? ?? 'EGP',
        achievementPct: (j['achievementPct'] as num?)?.toDouble() ?? 0,
      );
}

class TopPerformer {
  final int rank;
  final String userId;
  final String fullName;
  final String initials;
  final double primaryValue;
  final String primaryLabel;
  final double secondaryValue;
  final String secondaryLabel;
  final double achievementPct;
  const TopPerformer({
    required this.rank,
    required this.userId,
    required this.fullName,
    required this.initials,
    required this.primaryValue,
    required this.primaryLabel,
    required this.secondaryValue,
    required this.secondaryLabel,
    required this.achievementPct,
  });
  factory TopPerformer.fromJson(Map<String, dynamic> j) => TopPerformer(
        rank: (j['rank'] as num?)?.toInt() ?? 0,
        userId: j['userId'] as String? ?? '',
        fullName: j['fullName'] as String? ?? '',
        initials: j['initials'] as String? ?? '',
        primaryValue: (j['primaryValue'] as num?)?.toDouble() ?? 0,
        primaryLabel: j['primaryLabel'] as String? ?? '',
        secondaryValue: (j['secondaryValue'] as num?)?.toDouble() ?? 0,
        secondaryLabel: j['secondaryLabel'] as String? ?? '',
        achievementPct: (j['achievementPct'] as num?)?.toDouble() ?? 0,
      );
}

enum DashboardAlertSeverity { info, warning, error }
enum DashboardAlertType {
  missedVisit,
  noGps,
  lateCheckIn,
  overdueCollection,
  orderPendingApproval,
  highOutstanding,
  newSurveySubmitted,
}

class AlertItem {
  final String id;
  final DashboardAlertSeverity severity;
  final DashboardAlertType type;
  final String message;
  final String? subtitle;
  final DateTime timestamp;
  final String? deepLink;
  const AlertItem({
    required this.id,
    required this.severity,
    required this.type,
    required this.message,
    this.subtitle,
    required this.timestamp,
    this.deepLink,
  });
  factory AlertItem.fromJson(Map<String, dynamic> j) => AlertItem(
        id: j['id'] as String? ?? '',
        severity: _parseEnum<DashboardAlertSeverity>(
            j['severity'], DashboardAlertSeverity.values, DashboardAlertSeverity.info),
        type: _parseEnum<DashboardAlertType>(
            j['type'], DashboardAlertType.values, DashboardAlertType.missedVisit),
        message: j['message'] as String? ?? '',
        subtitle: j['subtitle'] as String?,
        timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
        deepLink: j['deepLink'] as String?,
      );
}

enum ActivityKind {
  orderCreated,
  collectionAdded,
  visitCompleted,
  surveySubmitted,
  returnCreated,
}

class ActivityItem {
  final String id;
  final ActivityKind kind;
  final String whoUserId;
  final String whoFullName;
  final String whoInitials;
  final String action;
  final String? target;
  final double? amount;
  final String? currency;
  final DateTime timestamp;
  final String? deepLink;
  const ActivityItem({
    required this.id,
    required this.kind,
    required this.whoUserId,
    required this.whoFullName,
    required this.whoInitials,
    required this.action,
    this.target,
    this.amount,
    this.currency,
    required this.timestamp,
    this.deepLink,
  });
  factory ActivityItem.fromJson(Map<String, dynamic> j) => ActivityItem(
        id: j['id'] as String? ?? '',
        kind: _parseEnum<ActivityKind>(
            j['kind'], ActivityKind.values, ActivityKind.orderCreated),
        whoUserId: j['whoUserId'] as String? ?? '',
        whoFullName: j['whoFullName'] as String? ?? '',
        whoInitials: j['whoInitials'] as String? ?? '',
        action: j['action'] as String? ?? '',
        target: j['target'] as String?,
        amount: (j['amount'] as num?)?.toDouble(),
        currency: j['currency'] as String?,
        timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
        deepLink: j['deepLink'] as String?,
      );
}

enum LiveRepStatus { offline, online, onVisit, onBreak }

class LiveRep {
  final String userId;
  final String fullName;
  final String initials;
  final LiveRepStatus status;
  final double? latitude;
  final double? longitude;
  final DateTime? lastReportedAt;
  final String? areaCode;
  const LiveRep({
    required this.userId,
    required this.fullName,
    required this.initials,
    required this.status,
    this.latitude,
    this.longitude,
    this.lastReportedAt,
    this.areaCode,
  });
  factory LiveRep.fromJson(Map<String, dynamic> j) => LiveRep(
        userId: j['userId'] as String? ?? '',
        fullName: j['fullName'] as String? ?? '',
        initials: j['initials'] as String? ?? '',
        status: _parseEnum<LiveRepStatus>(
            j['status'], LiveRepStatus.values, LiveRepStatus.offline),
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        lastReportedAt: j['lastReportedAt'] != null
            ? DateTime.tryParse(j['lastReportedAt'] as String)
            : null,
        areaCode: j['areaCode'] as String?,
      );
}

class VisitHeatmapPoint {
  final double latitude;
  final double longitude;
  final int weight;
  const VisitHeatmapPoint({
    required this.latitude,
    required this.longitude,
    required this.weight,
  });
  factory VisitHeatmapPoint.fromJson(Map<String, dynamic> j) => VisitHeatmapPoint(
        latitude: (j['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (j['longitude'] as num?)?.toDouble() ?? 0,
        weight: (j['weight'] as num?)?.toInt() ?? 0,
      );
}

class SalesManagerDashboard {
  final DateRange period;
  final KpiWithSpark totalSales;
  final KpiWithSpark totalCollections;
  final KpiWithSpark achievementPct;
  final KpiWithSpark totalVisits;
  final KpiCount activeReps;
  final KpiWithSpark openBalance;
  final KpiWithSpark returnsPct;
  final SparkSeries salesTrend;
  final List<AreaBreakdown> salesByArea;
  final List<TargetVsActualPoint> targetVsActualByArea;
  final List<TopPerformer> topSupervisors;
  final List<TopPerformer> topReps;
  final CollectionOverview collectionOverview;
  final VisitsOverview visitsOverview;
  final List<LiveRep> liveReps;
  final List<AlertItem> alerts;
  final DateTime generatedAt;
  const SalesManagerDashboard({
    required this.period,
    required this.totalSales,
    required this.totalCollections,
    required this.achievementPct,
    required this.totalVisits,
    required this.activeReps,
    required this.openBalance,
    required this.returnsPct,
    required this.salesTrend,
    required this.salesByArea,
    required this.targetVsActualByArea,
    required this.topSupervisors,
    required this.topReps,
    required this.collectionOverview,
    required this.visitsOverview,
    required this.liveReps,
    required this.alerts,
    required this.generatedAt,
  });
  factory SalesManagerDashboard.fromJson(Map<String, dynamic> j) => SalesManagerDashboard(
        period: DateRange.fromJson(j['period'] as Map<String, dynamic>),
        totalSales: KpiWithSpark.fromJson(j['totalSales'] as Map<String, dynamic>),
        totalCollections:
            KpiWithSpark.fromJson(j['totalCollections'] as Map<String, dynamic>),
        achievementPct:
            KpiWithSpark.fromJson(j['achievementPct'] as Map<String, dynamic>),
        totalVisits: KpiWithSpark.fromJson(j['totalVisits'] as Map<String, dynamic>),
        activeReps: KpiCount.fromJson(j['activeReps'] as Map<String, dynamic>),
        openBalance: KpiWithSpark.fromJson(j['openBalance'] as Map<String, dynamic>),
        returnsPct: KpiWithSpark.fromJson(j['returnsPct'] as Map<String, dynamic>),
        salesTrend: SparkSeries.fromJson(j['salesTrend'] as Map<String, dynamic>),
        salesByArea: ((j['salesByArea'] as List?) ?? const [])
            .map((e) => AreaBreakdown.fromJson(e as Map<String, dynamic>))
            .toList(),
        targetVsActualByArea: ((j['targetVsActualByArea'] as List?) ?? const [])
            .map((e) => TargetVsActualPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        topSupervisors: ((j['topSupervisors'] as List?) ?? const [])
            .map((e) => TopPerformer.fromJson(e as Map<String, dynamic>))
            .toList(),
        topReps: ((j['topReps'] as List?) ?? const [])
            .map((e) => TopPerformer.fromJson(e as Map<String, dynamic>))
            .toList(),
        collectionOverview:
            CollectionOverview.fromJson(j['collectionOverview'] as Map<String, dynamic>),
        visitsOverview:
            VisitsOverview.fromJson(j['visitsOverview'] as Map<String, dynamic>),
        liveReps: ((j['liveReps'] as List?) ?? const [])
            .map((e) => LiveRep.fromJson(e as Map<String, dynamic>))
            .toList(),
        alerts: ((j['alerts'] as List?) ?? const [])
            .map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        generatedAt:
            DateTime.tryParse(j['generatedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class AreaManagerDashboard {
  final DateRange period;
  final String? areaCode;
  final String? areaName;
  final KpiCount plannedVisits;
  final KpiCount completedVisits;
  final KpiCount missedVisits;
  final KpiPercent teamAchievement;
  final KpiAmount ordersToday;
  final KpiAmount collectionsToday;
  final KpiCount activeReps;
  final List<LiveRep> teamLive;
  final VisitAchievementBreakdown visitAchievement;
  final List<TopPerformer> topReps;
  final List<VisitStatusByRep> visitsStatusByRep;
  final SparkSeries ordersTrend;
  final List<AlertItem> alerts;
  final List<ActivityItem> dailyActivity;
  final List<VisitHeatmapPoint> visitHeatmap;
  final CollectionOverview collectionOverview;
  final TodayPlanSummary todayPlanSummary;
  final DateTime generatedAt;
  const AreaManagerDashboard({
    required this.period,
    this.areaCode,
    this.areaName,
    required this.plannedVisits,
    required this.completedVisits,
    required this.missedVisits,
    required this.teamAchievement,
    required this.ordersToday,
    required this.collectionsToday,
    required this.activeReps,
    required this.teamLive,
    required this.visitAchievement,
    required this.topReps,
    required this.visitsStatusByRep,
    required this.ordersTrend,
    required this.alerts,
    required this.dailyActivity,
    required this.visitHeatmap,
    required this.collectionOverview,
    required this.todayPlanSummary,
    required this.generatedAt,
  });
  factory AreaManagerDashboard.fromJson(Map<String, dynamic> j) => AreaManagerDashboard(
        period: DateRange.fromJson(j['period'] as Map<String, dynamic>),
        areaCode: j['areaCode'] as String?,
        areaName: j['areaName'] as String?,
        plannedVisits: KpiCount.fromJson(j['plannedVisits'] as Map<String, dynamic>),
        completedVisits: KpiCount.fromJson(j['completedVisits'] as Map<String, dynamic>),
        missedVisits: KpiCount.fromJson(j['missedVisits'] as Map<String, dynamic>),
        teamAchievement:
            KpiPercent.fromJson(j['teamAchievement'] as Map<String, dynamic>),
        ordersToday: KpiAmount.fromJson(j['ordersToday'] as Map<String, dynamic>),
        collectionsToday:
            KpiAmount.fromJson(j['collectionsToday'] as Map<String, dynamic>),
        activeReps: KpiCount.fromJson(j['activeReps'] as Map<String, dynamic>),
        teamLive: ((j['teamLive'] as List?) ?? const [])
            .map((e) => LiveRep.fromJson(e as Map<String, dynamic>))
            .toList(),
        visitAchievement: VisitAchievementBreakdown.fromJson(
            j['visitAchievement'] as Map<String, dynamic>),
        topReps: ((j['topReps'] as List?) ?? const [])
            .map((e) => TopPerformer.fromJson(e as Map<String, dynamic>))
            .toList(),
        visitsStatusByRep: ((j['visitsStatusByRep'] as List?) ?? const [])
            .map((e) => VisitStatusByRep.fromJson(e as Map<String, dynamic>))
            .toList(),
        ordersTrend: SparkSeries.fromJson(j['ordersTrend'] as Map<String, dynamic>),
        alerts: ((j['alerts'] as List?) ?? const [])
            .map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        dailyActivity: ((j['dailyActivity'] as List?) ?? const [])
            .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        visitHeatmap: ((j['visitHeatmap'] as List?) ?? const [])
            .map((e) => VisitHeatmapPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        collectionOverview:
            CollectionOverview.fromJson(j['collectionOverview'] as Map<String, dynamic>),
        todayPlanSummary:
            TodayPlanSummary.fromJson(j['todayPlanSummary'] as Map<String, dynamic>),
        generatedAt:
            DateTime.tryParse(j['generatedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

T _parseEnum<T extends Enum>(dynamic raw, List<T> values, T fallback) {
  if (raw == null) return fallback;
  if (raw is int && raw >= 0 && raw < values.length) return values[raw];
  if (raw is String) {
    final match = values.firstWhere(
      (v) => v.name.toLowerCase() == raw.toLowerCase(),
      orElse: () => fallback,
    );
    return match;
  }
  return fallback;
}
