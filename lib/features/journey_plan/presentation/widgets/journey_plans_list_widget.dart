import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/journey_plan.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_state.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/widgets/filter_buttons_widget.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/widgets/journey_plan_card.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/widgets/sales_employee_filter_widget.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/widgets/supervisor_selector_widget.dart';

class JourneyPlansListWidget extends StatelessWidget {
  const JourneyPlansListWidget({
    super.key,
    required this.state,
    this.onRefresh,
  });

  final JourneyPlanState state;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final user = authState.loginResponse?.user;
    final isSalesRep = user?.role.toLowerCase() == 'salesrep';
    final isAdmin = user?.role.toLowerCase().trim() == 'admin';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // For Admin: show supervisor selector if no supervisor chosen yet
    if (isAdmin && state.filterSupervisorId == null) {
      return SupervisorSelectorWidget(state: state);
    }

    // Find selected supervisor name for header display (Admin only)
    final supervisorName =
        isAdmin
            ? (state.supervisors
                    .where((s) => s.id == state.filterSupervisorId)
                    .map((s) => s.fullName)
                    .firstOrNull ??
                'Supervisor')
            : '';

    // When a sales employee is selected, show their name in journey plans title; otherwise supervisor's
    final selectedSalesList =
        state.subordinates.where((s) => s.id == state.filterUserId).toList();
    final journeyPlansTitleName =
        selectedSalesList.isNotEmpty
            ? selectedSalesList.first.fullName
            : supervisorName;
    final journeyPlansTitle = "$journeyPlansTitleName's journey plans";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show supervisor header + sales employee filter for Admin
        if (isAdmin && state.filterSupervisorId != null) ...[
          _SupervisorHeader(
            supervisorName: supervisorName,
            onClear: () {
              context.read<JourneyPlanCubit>().clearSupervisorSelection();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _SectionLabel(title: 'Sales Employees of $supervisorName'),
                const SizedBox(height: 6),
                SalesEmployeeFilterWidget(state: state),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SectionLabel(title: journeyPlansTitle),
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Current/Future Filter Buttons (only for Sales Employee)
        if (isSalesRep)
          _PlanViewFilters(
            pastSelected: state.planViewFilter == 'past',
            currentSelected: state.planViewFilter == 'current',
            futureSelected: state.planViewFilter == 'future',
            onPastTap: () {
              context.read<JourneyPlanCubit>().setPlanViewFilter('past');
            },
            onCurrentTap: () {
              context.read<JourneyPlanCubit>().setPlanViewFilter('current');
            },
            onFutureTap: () {
              context.read<JourneyPlanCubit>().setPlanViewFilter('future');
            },
          ),
        // Journey Plans List
        Expanded(
          child: _JourneyPlansListContent(
            state: state,
            isSalesRep: isSalesRep,
            today: today,
            onRefresh: onRefresh,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        title,
        textAlign: TextAlign.start,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SupervisorHeader extends StatelessWidget {
  const _SupervisorHeader({
    required this.supervisorName,
    required this.onClear,
    required this.child,
  });

  final String supervisorName;
  final VoidCallback onClear;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.15)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Viewing supervisor',
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 10,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.supervisor_account,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  supervisorName,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Change'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _PlanViewFilters extends StatelessWidget {
  const _PlanViewFilters({
    required this.pastSelected,
    required this.currentSelected,
    required this.futureSelected,
    required this.onPastTap,
    required this.onCurrentTap,
    required this.onFutureTap,
  });

  final bool pastSelected;
  final bool currentSelected;
  final bool futureSelected;
  final VoidCallback onPastTap;
  final VoidCallback onCurrentTap;
  final VoidCallback onFutureTap;

  static const _btnPadding = EdgeInsets.symmetric(vertical: 10, horizontal: 6);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: PlanViewFilterButton(
              label: 'Past',
              isSelected: pastSelected,
              onTap: onPastTap,
              fontSize: 12,
              padding: _btnPadding,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: PlanViewFilterButton(
              label: 'Current',
              isSelected: currentSelected,
              onTap: onCurrentTap,
              fontSize: 12,
              padding: _btnPadding,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: PlanViewFilterButton(
              label: 'Future',
              isSelected: futureSelected,
              onTap: onFutureTap,
              fontSize: 12,
              padding: _btnPadding,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyPlansListContent extends StatelessWidget {
  const _JourneyPlansListContent({
    required this.state,
    required this.isSalesRep,
    required this.today,
    this.onRefresh,
  });

  final JourneyPlanState state;
  final bool isSalesRep;
  final DateTime today;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingJourneyPlans && state.journeyPlans.isEmpty) {
      return _wrapWithRefresh(
        const Center(child: CircularProgressIndicator()),
        context,
      );
    }

    if (state.journeyPlansErrorMessage != null && state.journeyPlans.isEmpty) {
      return _wrapWithRefresh(
        _ErrorState(message: state.journeyPlansErrorMessage!),
        context,
      );
    }

    // Filter plans based on view filter (for Sales Employee)
    List<JourneyPlan> filteredPlans = state.journeyPlans;

    if (isSalesRep) {
      if (state.planViewFilter == 'past') {
        filteredPlans =
            state.journeyPlans.where((plan) {
              final endDate = DateTime(
                plan.endDate.year,
                plan.endDate.month,
                plan.endDate.day,
              );
              return endDate.isBefore(today);
            }).toList();
      } else if (state.planViewFilter == 'current') {
        filteredPlans =
            state.journeyPlans.where((plan) {
              final startDate = DateTime(
                plan.startDate.year,
                plan.startDate.month,
                plan.startDate.day,
              );
              final endDate = DateTime(
                plan.endDate.year,
                plan.endDate.month,
                plan.endDate.day,
              );

              return (startDate.isBefore(today) ||
                      startDate.isAtSameMomentAs(today)) &&
                  (endDate.isAfter(today) || endDate.isAtSameMomentAs(today));
            }).toList();
      } else if (state.planViewFilter == 'future') {
        filteredPlans =
            state.journeyPlans.where((plan) {
              final startDate = DateTime(
                plan.startDate.year,
                plan.startDate.month,
                plan.startDate.day,
              );
              return startDate.isAfter(today);
            }).toList();
      }
    }

    if (filteredPlans.isEmpty) {
      return _wrapWithRefresh(
        _EmptyState(
          isSalesRep: isSalesRep,
          planViewFilter: state.planViewFilter,
        ),
        context,
      );
    }

    // Sort journey plans by start date - newest first
    final sortedPlans = List.from(filteredPlans)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    return RefreshIndicator(
      onRefresh: () async {
        if (onRefresh != null) await onRefresh!();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: sortedPlans.length,
        itemBuilder: (context, index) {
          final plan = sortedPlans[index];
          return JourneyPlanCard(plan: plan);
        },
      ),
    );
  }

  Widget _wrapWithRefresh(Widget child, BuildContext context) {
    if (onRefresh == null) return child;
    return RefreshIndicator(
      onRefresh: () async {
        if (onRefresh != null) await onRefresh!();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.5,
          child: child,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: AppColors.error, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isSalesRep,
    required this.planViewFilter,
  });

  final bool isSalesRep;
  final String? planViewFilter;

  @override
  Widget build(BuildContext context) {
    final isFuture = planViewFilter == 'future';
    final isPast = planViewFilter == 'past';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              isSalesRep && isFuture
                  ? 'No future plans found'
                  : isSalesRep && isPast
                  ? 'No past plans found'
                  : 'No journey plans found',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              isSalesRep && isFuture
                  ? 'Create a new journey plan'
                  : isSalesRep && isPast
                  ? 'Plans whose end date has passed appear here'
                  : 'Create your first journey plan',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
