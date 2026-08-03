import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/journey_plan.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/utils/visit_execution_status.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/widgets/info_item_widget.dart';

class JourneyPlanCard extends StatelessWidget {
  const JourneyPlanCard({super.key, required this.plan});

  final JourneyPlan plan;

  void _onTap(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final currentUserId = authState.loginResponse?.user.id;
    final user = authState.loginResponse?.user;
    final isManagerOrAdmin =
        user?.role.toLowerCase().trim() == 'manager' ||
        user?.role.toLowerCase().trim() == 'admin';

    context.read<JourneyPlanCubit>().loadJourneyPlanForEdit(
      plan.id,
      currentUserId: currentUserId,
      isSupervisor:
          isManagerOrAdmin, // Manager/Admin should view in read-only mode
    );
  }

  bool get _hasAssignedVisit {
    return plan.stops.any(
      (stop) =>
          stop.visit != null &&
          stop.visit!.supervisorId != null &&
          stop.visit!.supervisorId!.isNotEmpty,
    );
  }

  String? _executionStatusLabel({
    required Map<String, int> endedVisitElapsedSeconds,
    required Map<String, int> pausedVisitElapsedSeconds,
    required Map<String, int> pauseStartTimestampMs,
  }) => VisitExecutionStatus.journeyPlanExecutionStatusLabel(
    plan,
    endedVisitElapsedSeconds: endedVisitElapsedSeconds,
    pausedVisitElapsedSeconds: pausedVisitElapsedSeconds,
    pauseStartTimestampMs: pauseStartTimestampMs,
  );

  String? _visitExecutionSummaryLabel({
    required Map<String, int> endedVisitElapsedSeconds,
    required Map<String, int> pausedVisitElapsedSeconds,
    required Map<String, int> pauseStartTimestampMs,
  }) {
    var ended = 0;
    var inProgress = 0;
    var planned = 0;
    var paused = 0;
    var cancelled = 0;
    for (final s in plan.stops) {
      final v = s.visit;
      if (v == null) continue;
      VisitExecutionStatus.countForJourneyPlanSummary(
        v,
        onPlanned: () => planned++,
        onInProgress: () => inProgress++,
        onPaused: () => paused++,
        onEnded: () => ended++,
        onCancelled: () => cancelled++,
        endedVisitElapsedSeconds: endedVisitElapsedSeconds,
        pausedVisitElapsedSeconds: pausedVisitElapsedSeconds,
        pauseStartTimestampMs: pauseStartTimestampMs,
      );
    }
    if (ended + inProgress + planned + paused + cancelled == 0) {
      return null;
    }
    final parts = <String>[];
    if (ended > 0) parts.add('$ended completed');
    if (inProgress > 0) parts.add('$inProgress in progress');
    if (paused > 0) parts.add('$paused paused');
    if (planned > 0) parts.add('$planned planned');
    if (cancelled > 0) parts.add('$cancelled cancelled');
    return parts.join(' · ');
  }

  String _getPlanTypeName(BuildContext context, int planType) {
    final l10n = AppLocalizations.of(context);
    switch (planType) {
      case 1:
        return l10n?.day ?? 'Day';
      case 2:
        return l10n?.week ?? 'Week';
      case 3:
        return l10n?.month ?? 'Month';
      case 4:
        return l10n?.quarter ?? 'Quarter';
      case 5:
        return l10n?.year ?? 'Year';
      default:
        return 'Unknown';
    }
  }

  IconData _getPlanTypeIcon(int planType) {
    switch (planType) {
      case 1:
        return Icons.today_outlined;
      case 2:
        return Icons.date_range_outlined;
      case 3:
        return Icons.calendar_month_outlined;
      case 4:
        return Icons.view_module_outlined;
      case 5:
        return Icons.event_note_outlined;
      default:
        return Icons.calendar_today;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final user = authState.loginResponse?.user;
    final isSalesRep = user?.role.toLowerCase() == 'salesrep';
    final cardAccent = AppColors.primary;
    final timing = context.watch<JourneyPlanCubit>().state;
    final visitSummary = _visitExecutionSummaryLabel(
      endedVisitElapsedSeconds: timing.endedVisitElapsedSeconds,
      pausedVisitElapsedSeconds: timing.pausedVisitElapsedSeconds,
      pauseStartTimestampMs: timing.pauseStartTimestampMs,
    );
    final executionStatusLabel = _executionStatusLabel(
      endedVisitElapsedSeconds: timing.endedVisitElapsedSeconds,
      pausedVisitElapsedSeconds: timing.pausedVisitElapsedSeconds,
      pauseStartTimestampMs: timing.pauseStartTimestampMs,
    );

    return InkWell(
      onTap: () => _onTap(context),
      borderRadius: BorderRadius.circular(16),
      child: Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: cardAccent.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cardAccent.withValues(alpha: 0.08),
                  cardAccent.withValues(alpha: 0.03),
                  Colors.white,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BadgesRow(
                    plan: plan,
                    isSalesRep: isSalesRep,
                    hasAssignedVisit: _hasAssignedVisit,
                    executionStatusLabel: executionStatusLabel,
                    visitSummaryLabel: visitSummary,
                    getPlanTypeName: _getPlanTypeName,
                    getPlanTypeIcon: _getPlanTypeIcon,
                  ),
                  const SizedBox(height: 12),
                  _ContentRow(plan: plan, accentColor: cardAccent),
                  const SizedBox(height: 12),
                  _Divider(accentColor: cardAccent),
                  const SizedBox(height: 10),
                  _DateRangeRow(plan: plan, accentColor: cardAccent),
                  if (plan.stops.isNotEmpty)
                    _StopsInfo(plan: plan, accentColor: cardAccent),
                  if (plan.notes.isNotEmpty) _NotesInfo(plan: plan),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

class _BadgesRow extends StatelessWidget {
  const _BadgesRow({
    required this.plan,
    required this.isSalesRep,
    required this.hasAssignedVisit,
    this.executionStatusLabel,
    this.visitSummaryLabel,
    required this.getPlanTypeName,
    required this.getPlanTypeIcon,
  });

  final JourneyPlan plan;
  final bool isSalesRep;
  final bool hasAssignedVisit;
  final String? executionStatusLabel;
  final String? visitSummaryLabel;
  final String Function(BuildContext, int) getPlanTypeName;
  final IconData Function(int) getPlanTypeIcon;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _PlanTypeBadge(
          plan: plan,
          getPlanTypeName: getPlanTypeName,
          getPlanTypeIcon: getPlanTypeIcon,
        ),
        if (isSalesRep && hasAssignedVisit) _AssignedBadge(),
        if (executionStatusLabel == 'Completed')
          const _ExecutionStatusBadge.completed(),
        if (executionStatusLabel == 'Incompleted')
          const _ExecutionStatusBadge.incompleted(),
        if (executionStatusLabel == 'In Progress')
          const _ExecutionStatusBadge.inProgress(),
        if (visitSummaryLabel != null && visitSummaryLabel!.isNotEmpty)
          _VisitSummaryBadge(label: visitSummaryLabel!),
      ],
    );
  }
}

class _VisitSummaryBadge extends StatelessWidget {
  const _VisitSummaryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTypeBadge extends StatelessWidget {
  const _PlanTypeBadge({
    required this.plan,
    required this.getPlanTypeName,
    required this.getPlanTypeIcon,
  });

  final JourneyPlan plan;
  final String Function(BuildContext, int) getPlanTypeName;
  final IconData Function(int) getPlanTypeIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(getPlanTypeIcon(plan.planType), color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            getPlanTypeName(context, plan.planType),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExecutionStatusBadge extends StatelessWidget {
  const _ExecutionStatusBadge._({
    required this.label,
    required this.color,
    required this.icon,
  });

  const _ExecutionStatusBadge.completed()
    : this._(
        label: 'Completed',
        color: AppColors.success,
        icon: Icons.check_circle,
      );

  const _ExecutionStatusBadge.inProgress()
    : this._(
        label: 'In Progress',
        color: AppColors.warning,
        icon: Icons.play_circle_outline,
      );

  const _ExecutionStatusBadge.incompleted()
    : this._(
        label: 'Incompleted',
        color: AppColors.error,
        icon: Icons.error_outline,
      );

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.supervisor_account, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          const Text(
            'Assigned',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentRow extends StatelessWidget {
  const _ContentRow({required this.plan, required this.accentColor});

  final JourneyPlan plan;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.route, color: accentColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plan.userName.isNotEmpty)
                Text(
                  plan.userName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor.withValues(alpha: 0.25), Colors.transparent],
        ),
      ),
    );
  }
}

class _DateRangeRow extends StatelessWidget {
  const _DateRangeRow({required this.plan, required this.accentColor});

  final JourneyPlan plan;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InfoItemWidget(
            icon: Icons.calendar_today_outlined,
            label: AppLocalizations.of(context)!.startDate,
            value: DateFormat('MMM dd, yyyy').format(plan.startDate),
            iconColor: accentColor,
          ),
        ),
        Container(width: 1, height: 40, color: AppColors.border),
        Expanded(
          child: InfoItemWidget(
            icon: Icons.event_outlined,
            label: AppLocalizations.of(context)!.endDate,
            value: DateFormat('MMM dd, yyyy').format(plan.endDate),
            iconColor: accentColor,
          ),
        ),
      ],
    );
  }
}

class _StopsInfo extends StatelessWidget {
  const _StopsInfo({required this.plan, required this.accentColor});

  final JourneyPlan plan;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accentColor.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.location_on, color: accentColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.visitsCount(plan.stops.length),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotesInfo extends StatelessWidget {
  const _NotesInfo({required this.plan});

  final JourneyPlan plan;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.note_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  plan.notes,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
