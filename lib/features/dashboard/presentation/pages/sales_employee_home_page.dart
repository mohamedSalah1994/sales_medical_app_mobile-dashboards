import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:sales_medical_app_mobile/core/network/api_service.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/dashboard/data/models/sales_employee_home_models.dart';
import 'package:sales_medical_app_mobile/features/dashboard/presentation/cubit/sales_employee_home_cubit.dart';
import 'package:sales_medical_app_mobile/features/dashboard/presentation/widgets/dashboard_widgets.dart';

/// Mobile sales-employee home — Greeting + 4 KPI tiles + Today's Journey hero card
/// + Performance Overview + Targets + Recent Activity + Today Summary.
class SalesEmployeeHomePage extends StatelessWidget {
  const SalesEmployeeHomePage({super.key, this.repName = 'Sales Rep'});
  final String repName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SalesEmployeeHomeCubit(DashboardRemoteDataSource(ApiService()))..load(),
      child: _Body(repName: repName),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.repName});
  final String repName;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesEmployeeHomeCubit, SalesEmployeeHomeState>(
      builder: (ctx, state) {
        final cubit = ctx.read<SalesEmployeeHomeCubit>();
        if (state.status == SalesEmployeeHomeStatus.loading && state.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == SalesEmployeeHomeStatus.error && state.data == null) {
          return _ErrorBlock(message: state.error ?? 'Failed to load', onRetry: cubit.refresh);
        }
        final data = state.data;
        if (data == null) return const SizedBox.shrink();
        final firstName = repName.split(' ').first;
        final dateLabel = DateFormat('MMM d, yyyy').format(data.period.from);

        return RefreshIndicator(
          onRefresh: cubit.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            children: [
              GreetingBanner(
                greeting: 'Good morning, $firstName!',
                subtitle: 'Have a productive day ahead',
                dateLabel: dateLabel,
              ),
              const SizedBox(height: 12),
              _TodayKpiStrip(data: data),
              const SizedBox(height: 12),
              _TodaysJourneyCard(data: data),
              const SizedBox(height: 12),
              _PerformanceOverview(data: data),
              const SizedBox(height: 12),
              _TargetsStrip(data: data.targets),
              const SizedBox(height: 12),
              _ActivityAndSummary(data: data),
            ],
          ),
        );
      },
    );
  }
}

class _TodayKpiStrip extends StatelessWidget {
  const _TodayKpiStrip({required this.data});
  final SalesEmployeeHome data;
  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      KpiTile(
        label: "Today's Visits",
        valueDisplay: '${data.todaysVisits.value} / ${data.todaysVisits.total ?? 0}',
        icon: Icons.route_outlined,
        iconColor: AppColors.primary,
        progressPct: data.todaysVisits.pct ?? 0,
        subtitle: 'Completed',
      ),
      KpiTile(
        label: "Today's Target",
        valueDisplay: '${DashFmt.compact(data.todaysTarget.value)} ${data.todaysTarget.currency}',
        icon: Icons.flag_outlined,
        iconColor: AppColors.success,
        progressPct: data.todaysTarget.relatedCount?.toDouble() ?? 0,
        subtitle: 'Target Amount',
      ),
      KpiTile(
        label: 'Collections',
        valueDisplay: '${DashFmt.compact(data.collections.value)} ${data.collections.currency}',
        icon: Icons.attach_money,
        iconColor: AppColors.warning,
        deltaPct: data.collections.deltaPct,
        deltaLabel: data.collections.deltaPeriodLabel,
      ),
      KpiTile(
        label: 'Orders',
        valueDisplay: '${data.orders.value}',
        icon: Icons.shopping_cart_outlined,
        iconColor: AppColors.accent,
        deltaPct: data.orders.deltaPct,
        deltaLabel: data.orders.deltaPeriodLabel,
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: tiles,
    );
  }
}

class _TodaysJourneyCard extends StatelessWidget {
  const _TodaysJourneyCard({required this.data});
  final SalesEmployeeHome data;
  @override
  Widget build(BuildContext context) {
    final j = data.todaysJourney;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.route_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          const Text("Today's Journey",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const Spacer(),
          Text(
              '${DateFormat('MMM d, yyyy').format(j.date)} · ${j.plannedStops} Planned Visits',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ProgressDonut(pct: j.completedPct),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Next Visit',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(j.nextVisit?.customerName ?? '—',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              if (j.nextVisit?.addressLine != null)
                Text(j.nextVisit!.addressLine!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              if (j.nextVisit?.distanceKm != null)
                Row(children: [
                  const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('${j.nextVisit!.distanceKm!.toStringAsFixed(1)} km away',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                ]),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () {/* navigate via external map intent */},
                icon: const Icon(Icons.navigation, size: 14),
                label: const Text('Navigate'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 30),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ]),
          ),
          if (j.nextVisit?.latitude != null && j.nextVisit?.longitude != null)
            SizedBox(
              width: 100,
              height: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(j.nextVisit!.latitude!, j.nextVisit!.longitude!),
                    zoom: 13,
                  ),
                  liteModeEnabled: true,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  markers: {
                    Marker(
                      markerId: const MarkerId('next'),
                      position: LatLng(j.nextVisit!.latitude!, j.nextVisit!.longitude!),
                    )
                  },
                ),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {/* deep link to journey plan active visit */},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Continue Journey'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {/* deep link to journey plan map view */},
              icon: const Icon(Icons.map_outlined, size: 16),
              label: const Text('View Route'),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _ProgressDonut extends StatelessWidget {
  const _ProgressDonut({required this.pct});
  final double pct;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: CircularProgressIndicator(
              value: (pct / 100).clamp(0, 1).toDouble(),
              strokeWidth: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(achievementColor(pct)),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${pct.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const Text('Completed',
                style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
          ]),
        ],
      ),
    );
  }
}

class _PerformanceOverview extends StatelessWidget {
  const _PerformanceOverview({required this.data});
  final SalesEmployeeHome data;
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Performance Overview',
      action: const Text('View All',
          style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.5,
        children: [
          KpiTile(
            label: data.sales7Day.label,
            valueDisplay: DashFmt.compact(data.sales7Day.value),
            deltaPct: data.sales7Day.deltaPct,
            deltaLabel: data.sales7Day.deltaPeriodLabel,
            spark: data.sales7Day.sparkPoints,
            iconColor: AppColors.success,
            icon: Icons.trending_up,
          ),
          KpiTile(
            label: data.collections7Day.label,
            valueDisplay: DashFmt.compact(data.collections7Day.value),
            deltaPct: data.collections7Day.deltaPct,
            deltaLabel: data.collections7Day.deltaPeriodLabel,
            spark: data.collections7Day.sparkPoints,
            iconColor: Colors.deepPurple,
            icon: Icons.account_balance_wallet_outlined,
          ),
          KpiTile(
            label: data.returnsPct7Day.label,
            valueDisplay: '${data.returnsPct7Day.value.toStringAsFixed(2)}%',
            deltaPct: data.returnsPct7Day.deltaPct,
            deltaLabel: data.returnsPct7Day.deltaPeriodLabel,
            spark: data.returnsPct7Day.sparkPoints,
            iconColor: AppColors.accent,
            icon: Icons.assignment_return_outlined,
          ),
          KpiTile(
            label: data.orders7Day.label,
            valueDisplay: '${data.orders7Day.value.toInt()}',
            deltaPct: data.orders7Day.deltaPct,
            deltaLabel: data.orders7Day.deltaPeriodLabel,
            spark: data.orders7Day.sparkPoints,
            iconColor: AppColors.warning,
            icon: Icons.shopping_cart_outlined,
          ),
        ],
      ),
    );
  }
}

class _TargetsStrip extends StatelessWidget {
  const _TargetsStrip({required this.data});
  final TargetsSummary data;
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Targets',
      action: const Text('View All',
          style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
      child: Row(children: [
        _tile('Total Targets', '${data.totalTargets}', AppColors.primary, Icons.flag_outlined),
        const SizedBox(width: 8),
        _tile('Active Targets', '${data.activeTargets}', AppColors.success, Icons.trending_up),
        const SizedBox(width: 8),
        _tile('Avg Progress', '${data.avgProgressPct.toStringAsFixed(1)}%', AppColors.warning, Icons.bar_chart_rounded),
      ]),
    );
  }

  Widget _tile(String label, String value, Color c, IconData icon) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 14, color: c),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c)),
            ],
          ),
        ),
      );
}

class _ActivityAndSummary extends StatelessWidget {
  const _ActivityAndSummary({required this.data});
  final SalesEmployeeHome data;
  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
        child: SectionCard(
          title: 'Recent Activity',
          action: const Text('View All',
              style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
          child: Column(children: [
            if (data.recentActivity.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No recent activity',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
            for (final a in data.recentActivity.take(4))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(activityIcon(a.kind), size: 12, color: AppColors.success),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.action,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                    if (a.target != null)
                      Text(a.target!,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis),
                  ])),
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
          title: 'Today Summary',
          child: Column(children: [
            _row('Distance Travelled', '${data.todaySummary.distanceKm.toStringAsFixed(1)} km'),
            _row('Time on Visit', _fmtDuration(data.todaySummary.timeOnVisit)),
            _row('Avg Visit Time', _fmtDuration(data.todaySummary.averageVisitTime)),
            _row('Customers Visited', '${data.todaySummary.customersVisited}'),
          ]),
        ),
      ),
    ]),
    );
  }

  Widget _row(String label, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      );

  String _fmtDuration(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '$h:${m.toString().padLeft(2, '0')} hrs';
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
