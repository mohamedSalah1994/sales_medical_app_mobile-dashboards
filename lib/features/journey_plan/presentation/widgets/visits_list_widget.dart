import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_state.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/pages/visit_actions_page.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/widgets/filter_buttons_widget.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/widgets/stop_visit_card.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_cubit.dart';
import 'package:sales_medical_app_mobile/features/surveys/presentation/pages/visit_survey_list_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/delivery_from_sales_order_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/return_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/incoming_payment_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/sales_order_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/ready_for_delivery_picker_sheet.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/ready_for_return_picker_sheet.dart';

class VisitsListWidget extends StatelessWidget {
  const VisitsListWidget({super.key, required this.state, this.onRefresh});

  final JourneyPlanState state;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final userId = authState.loginResponse?.user.id;

    return Column(
      children: [
        // Status Filter Buttons
        _StatusFilters(
          notStartedSelected: state.visitStatusFilter == 1,
          completedSelected: state.visitStatusFilter == 3,
          onNotStartedTap: () {
            if (userId != null) {
              context.read<JourneyPlanCubit>().setVisitStatusFilter(
                1,
                supervisorId: userId,
              );
            }
          },
          onCompletedTap: () {
            if (userId != null) {
              context.read<JourneyPlanCubit>().setVisitStatusFilter(
                3,
                supervisorId: userId,
              );
            }
          },
        ),
        // Visits List
        Expanded(child: _VisitsListContent(state: state, onRefresh: onRefresh)),
      ],
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({
    required this.notStartedSelected,
    required this.completedSelected,
    required this.onNotStartedTap,
    required this.onCompletedTap,
  });

  final bool notStartedSelected;
  final bool completedSelected;
  final VoidCallback onNotStartedTap;
  final VoidCallback onCompletedTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: StatusFilterButton(
              label: AppLocalizations.of(context)!.notStarted,
              isSelected: notStartedSelected,
              onTap: onNotStartedTap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatusFilterButton(
              label: AppLocalizations.of(context)!.completed,
              isSelected: completedSelected,
              onTap: onCompletedTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitsListContent extends StatelessWidget {
  const _VisitsListContent({required this.state, this.onRefresh});

  final JourneyPlanState state;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingVisits && state.visits.isEmpty) {
      return _wrapWithRefresh(
        context,
        const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.visitsErrorMessage != null) {
      return _wrapWithRefresh(
        context,
        _ErrorState(message: state.visitsErrorMessage!),
      );
    }

    if (state.visits.isEmpty) {
      return _wrapWithRefresh(context, _EmptyState());
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (onRefresh != null) await onRefresh!();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: state.visits.length,
        itemBuilder: (context, index) {
          final visit = state.visits[index];
          final salesOrderCubit = context.read<SalesOrderCubit>();
          return StopVisitCard(
            visit: visit,
            durationMinutes: null,
            showEditIcon: false,
            showActionsButton: true,
            showActionsMenu: true,
            onViewActions: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder:
                      (_) => BlocProvider.value(
                        value: salesOrderCubit,
                        child: VisitActionsPage(visit: visit),
                      ),
                ),
              ).then((_) async {
                if (onRefresh != null) await onRefresh!();
              });
            },
            onCreateSalesOrder: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder:
                      (_) => BlocProvider.value(
                        value: salesOrderCubit,
                        child: SalesOrderPage(
                          visitId: visit.id,
                          initialCardCode: visit.customerCode ?? visit.customerId,
                          initialCustomerName: visit.customerName,
                        ),
                      ),
                ),
              ).then((_) async {
                if (onRefresh != null) await onRefresh!();
              });
            },
            onCreateDelivery: () async {
              final docEntry = await showReadyForDeliveryPicker(
                context,
                salesOrderCubit,
                customerCardCode: visit.erpCustomerCardOrId,
              );
              if (docEntry == null || !context.mounted) return;
              await Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider.value(
                    value: salesOrderCubit,
                    child: DeliveryFromSalesOrderPage(
                      salesOrderDocEntry: docEntry,
                      visitId: visit.id,
                    ),
                  ),
                ),
              );
              if (onRefresh != null) await onRefresh!();
            },
            onCreateReturn: () async {
              final docEntry = await showReadyForReturnPicker(
                context,
                salesOrderCubit,
                customerCardCode: visit.erpCustomerCardOrId,
              );
              if (docEntry == null || !context.mounted) return;
              await Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider.value(
                    value: salesOrderCubit,
                    child: ReturnPage.fromDelivery(
                      deliveryDocEntry: docEntry,
                      visitId: visit.id,
                    ),
                  ),
                ),
              );
              if (onRefresh != null) await onRefresh!();
            },
            onCreateIncomingPayment: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder:
                      (_) => IncomingPaymentCreatePage(
                        visitId: visit.id,
                        initialCardCode:
                            visit.customerCode ?? visit.customerId,
                        initialCustomerName: visit.customerName,
                      ),
                ),
              ).then((_) async {
                if (onRefresh != null) await onRefresh!();
              });
            },
            onSurvey: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => VisitSurveyListPage(visitId: visit.id),
                ),
              ).then((_) async {
                if (onRefresh != null) await onRefresh!();
              });
            },
          );
        },
      ),
    );
  }

  Widget _wrapWithRefresh(BuildContext context, Widget child) {
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
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noVisitsFound,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
