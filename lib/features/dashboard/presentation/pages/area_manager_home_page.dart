import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:sales_medical_app_mobile/core/network/api_service.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/dashboard/data/models/dashboard_models.dart';
import 'package:sales_medical_app_mobile/features/dashboard/presentation/cubit/area_manager_home_cubit.dart';
import 'package:sales_medical_app_mobile/features/dashboard/presentation/widgets/dashboard_widgets.dart';

/// Mobile supervisor home — "Area Manager". Vertical scroll, RTL-safe.
class AreaManagerHomePage extends StatelessWidget {
  const AreaManagerHomePage({super.key, this.supervisorFullName = 'Supervisor'});
  final String supervisorFullName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AreaManagerHomeCubit(DashboardRemoteDataSource(ApiService()))..load(),
      child: _Body(supervisorFullName: supervisorFullName),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.supervisorFullName});
  final String supervisorFullName;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AreaManagerHomeCubit, AreaManagerHomeState>(
      builder: (ctx, state) {
        final cubit = ctx.read<AreaManagerHomeCubit>();
        if (state.status == AreaManagerHomeStatus.loading && state.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == AreaManagerHomeStatus.error && state.data == null) {
          return _ErrorBlock(message: state.error ?? 'Failed to load', onRetry: cubit.refresh);
        }
        final data = state.data;
        if (data == null) return const SizedBox.shrink();
        final firstName = supervisorFullName.split(' ').first;
        final dateLabel = DateFormat('MMM d, yyyy').format(data.period.from);

        return RefreshIndicator(
          onRefresh: cubit.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            children: [
              GreetingBanner(
                greeting: 'Good morning, $firstName!',
                subtitle: "Here's your team overview for today",
                dateLabel: dateLabel,
              ),
              const SizedBox(height: 12),
              _KpiStrip(data: data),
              const SizedBox(height: 12),
              _MapAndAchievementRow(data: data),
              const SizedBox(height: 12),
              _VisitsOverviewAndTopReps(data: data),
              const SizedBox(height: 12),
              _AlertsAndCollections(data: data),
              const SizedBox(height: 12),
              _ActivityAndHeatmap(data: data),
            ],
          ),
        );
      },
    );
  }
}

class _KpiStrip extends StatelessWidget {
  const _KpiStrip({required this.data});
  final AreaManagerDashboard data;
  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      KpiTile(
        compact: true,
        label: 'Active Reps',
        valueDisplay: '${data.activeReps.value}${data.activeReps.total != null ? ' / ${data.activeReps.total}' : ''}',
        icon: Icons.fact_check_outlined,
        iconColor: AppColors.primary,
        subtitle: 'Online Now',
      ),
      KpiTile(
        compact: true,
        label: 'Team Achievement',
        valueDisplay: '${data.teamAchievement.pct.toStringAsFixed(0)}%',
        icon: Icons.bar_chart_rounded,
        iconColor: AppColors.success,
        progressPct: data.teamAchievement.pct,
        subtitle: 'vs Target',
      ),
      KpiTile(
        compact: true,
        label: 'Planned Visits',
        valueDisplay: '${data.plannedVisits.value} / ${data.completedVisits.value + data.missedVisits.value + data.plannedVisits.value}',
        icon: Icons.event_outlined,
        iconColor: AppColors.warning,
        subtitle: 'Today',
        progressPct: data.completedVisits.pct,
      ),
      KpiTile(
        compact: true,
        label: 'Completed Visits',
        valueDisplay: '${data.completedVisits.value} / ${data.plannedVisits.value}',
        icon: Icons.check_circle_outline,
        iconColor: AppColors.accent,
        subtitle: 'Today',
        progressPct: data.completedVisits.pct,
      ),
      KpiTile(
        compact: true,
        label: 'Collections Today',
        valueDisplay: '${DashFmt.compact(data.collectionsToday.value)} ${data.collectionsToday.currency}',
        icon: Icons.account_balance_wallet_outlined,
        iconColor: AppColors.success,
        deltaPct: data.collectionsToday.deltaPct,
        deltaLabel: data.collectionsToday.deltaPeriodLabel,
      ),
      KpiTile(
        compact: true,
        label: 'Orders Today',
        valueDisplay: '${data.ordersToday.relatedCount ?? 0}',
        icon: Icons.shopping_cart_outlined,
        iconColor: AppColors.primary,
        subtitle: '${DashFmt.compact(data.ordersToday.value)} ${data.ordersToday.currency}',
      ),
    ];
    return DashboardMetricGrid(
      crossAxisCount: 3,
      heightFactor: 0.92,
      minTileHeight: 108,
      children: tiles,
    );
  }
}

class _MapAndAchievementRow extends StatelessWidget {
  const _MapAndAchievementRow({required this.data});
  final AreaManagerDashboard data;
  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: SectionCard(
            title: 'Team Live Tracking',
            action: const Icon(Icons.open_in_full, size: 16, color: AppColors.textSecondary),
            child: SizedBox(height: 160, child: _TeamLiveMap(reps: data.teamLive)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SectionCard(
            title: 'Team Achievement',
            child: _AchievementDonut(data: data.visitAchievement),
          ),
        ),
      ]),
    );
  }
}

class _VisitsOverviewAndTopReps extends StatelessWidget {
  const _VisitsOverviewAndTopReps({required this.data});
  final AreaManagerDashboard data;
  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
        child: SectionCard(
          title: 'Visits Overview',
          child: Column(children: [
            Row(children: [
              _miniStat('Completed', data.completedVisits.value, AppColors.success),
              const SizedBox(width: 6),
              _miniStat('In Progress',
                  data.visitAchievement.inProgress, AppColors.accent),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              _miniStat('Missed', data.missedVisits.value, AppColors.error),
              const SizedBox(width: 6),
              _miniStat('Planned', data.plannedVisits.value, AppColors.warning),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Text('${data.visitAchievement.completedPct.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text('Visit Achievement',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary))),
            ]),
            const SizedBox(height: 4),
            ThresholdProgressBar(pct: data.visitAchievement.completedPct),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: SectionCard(
          title: 'Top Performing Reps',
          child: Column(
            children: [
              for (final r in data.topReps.take(5))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    InitialsAvatar(initials: r.initials, size: 22),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(r.fullName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis)),
                    Text('${r.achievementPct.toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: achievementColor(r.achievementPct))),
                  ]),
                ),
              if (data.topReps.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No data',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    ]),
    );
  }

  Widget _miniStat(String label, int value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$value',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
              Text(label,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
}

class _AlertsAndCollections extends StatelessWidget {
  const _AlertsAndCollections({required this.data});
  final AreaManagerDashboard data;
  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
        child: SectionCard(
          title: 'Alerts & Notifications',
          child: Column(children: [
            if (data.alerts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No alerts',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
            for (final a in data.alerts.take(4))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  alertSeverityIcon(a.severity),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(a.message,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis)),
                  Text(DashFmt.time(a.timestamp),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ]),
              ),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: SectionCard(
          title: 'Team Collections (${data.collectionOverview.currency})',
          child: Column(children: [
            Row(children: [
              const Expanded(
                  child: Text('Collected Today',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary))),
              Text(DashFmt.compact(data.collectionsToday.value),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Expanded(
                  child: Text('Outstanding',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary))),
              Text(DashFmt.compact(data.collectionOverview.outstanding),
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.error)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Expanded(
                  child: Text('Collection Rate',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary))),
              Text('${data.collectionOverview.collectionRatePct.toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ]),
          ]),
        ),
      ),
    ]),
    );
  }
}

class _ActivityAndHeatmap extends StatelessWidget {
  const _ActivityAndHeatmap({required this.data});
  final AreaManagerDashboard data;
  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
        child: SectionCard(
          title: 'Recent Team Activity',
          child: Column(children: [
            if (data.dailyActivity.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No activity',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
            for (final a in data.dailyActivity.take(4))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(activityIcon(a.kind), size: 12, color: AppColors.accent),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text('${a.action} by ${a.whoFullName}',
                          style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                  Text(DashFmt.time(a.timestamp),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ]),
              ),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: SectionCard(
          title: 'Area Coverage',
          child: SizedBox(height: 160, child: _HeatmapView(points: data.visitHeatmap)),
        ),
      ),
    ]),
    );
  }
}

class _TeamLiveMap extends StatelessWidget {
  const _TeamLiveMap({required this.reps});
  final List<LiveRep> reps;
  @override
  Widget build(BuildContext context) {
    final positioned = reps.where((r) => r.latitude != null && r.longitude != null).toList();
    final center = positioned.isNotEmpty
        ? LatLng(positioned.first.latitude!, positioned.first.longitude!)
        : const LatLng(30.0444, 31.2357);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: center, zoom: positioned.isEmpty ? 6 : 11),
        liteModeEnabled: true,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        markers: {
          for (final r in positioned)
            Marker(
              markerId: MarkerId(r.userId),
              position: LatLng(r.latitude!, r.longitude!),
            ),
        },
      ),
    );
  }
}

class _AchievementDonut extends StatelessWidget {
  const _AchievementDonut({required this.data});
  final VisitAchievementBreakdown data;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Stack(alignment: Alignment.center, children: [
        PieChart(PieChartData(
          centerSpaceRadius: 40,
          sectionsSpace: 2,
          sections: [
            if (data.completed > 0)
              PieChartSectionData(
                  value: data.completed.toDouble(),
                  color: AppColors.success,
                  radius: 14,
                  showTitle: false),
            if (data.inProgress > 0)
              PieChartSectionData(
                  value: data.inProgress.toDouble(),
                  color: AppColors.accent,
                  radius: 14,
                  showTitle: false),
            if (data.planned > 0)
              PieChartSectionData(
                  value: data.planned.toDouble(),
                  color: AppColors.warning,
                  radius: 14,
                  showTitle: false),
            if (data.missed > 0)
              PieChartSectionData(
                  value: data.missed.toDouble(),
                  color: AppColors.error,
                  radius: 14,
                  showTitle: false),
            if (data.total == 0)
              PieChartSectionData(
                  value: 1, color: AppColors.border, radius: 14, showTitle: false),
          ],
        )),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${data.completedPct.toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const Text('Achieved',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ]),
    );
  }
}

class _HeatmapView extends StatelessWidget {
  const _HeatmapView({required this.points});
  final List<VisitHeatmapPoint> points;
  @override
  Widget build(BuildContext context) {
    final center = points.isNotEmpty
        ? LatLng(points.first.latitude, points.first.longitude)
        : const LatLng(30.0444, 31.2357);
    final maxWeight = points.fold<int>(1, (a, b) => b.weight > a ? b.weight : a);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: center, zoom: points.isEmpty ? 6 : 12),
        liteModeEnabled: true,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        circles: {
          for (final p in points)
            Circle(
              circleId: CircleId('${p.latitude}_${p.longitude}'),
              center: LatLng(p.latitude, p.longitude),
              radius: 80 + (p.weight / maxWeight) * 120,
              fillColor: AppColors.error.withValues(alpha: 0.35),
              strokeColor: AppColors.error,
              strokeWidth: 1,
            ),
        },
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      ),
    );
  }
}
