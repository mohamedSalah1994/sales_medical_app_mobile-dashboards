import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/core/constants/customer_odbc_scope.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/pages/journey_plan_page.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/widgets/standalone_visit_sheet.dart';
import 'package:sales_medical_app_mobile/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_cubit.dart';
import 'package:sales_medical_app_mobile/features/customers/presentation/pages/customers_list_page.dart';
import 'package:sales_medical_app_mobile/features/field_staff/presentation/cubit/team_locations_cubit.dart';
import 'package:sales_medical_app_mobile/features/field_staff/presentation/pages/team_locations_map_page.dart';
import 'package:sales_medical_app_mobile/features/settings/presentation/widgets/language_selector.dart';
import 'package:sales_medical_app_mobile/features/targets/presentation/cubit/targets_cubit.dart';
import 'package:sales_medical_app_mobile/features/targets/presentation/pages/targets_page.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/pages/inventory_counting_list_page.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/pages/inventory_list_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/deliveries_list_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/incoming_payment_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/returns_list_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/sales_order_list_page.dart';
import 'package:sales_medical_app_mobile/features/dashboard/presentation/pages/dashboard_landing_page.dart';
import 'package:sales_medical_app_mobile/features/reports/presentation/pages/reports_landing_page.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({
    super.key,
    required this.selectedIndex,
    this.onTabChanged,
  });

  final int selectedIndex;
  final ValueChanged<int>? onTabChanged;

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  @override
  void didUpdateWidget(HomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDataForTab(widget.selectedIndex);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _loadDataForTab(widget.selectedIndex, forceRefresh: true);
        }
      });
    });
  }

  void _loadDataForTab(int tabIndex, {bool forceRefresh = false}) {
    if (tabIndex != 2 &&
        tabIndex != 3 &&
        tabIndex != 4 &&
        tabIndex != 5 &&
        tabIndex != 6 &&
        tabIndex != 7 &&
        tabIndex != 8 &&
        tabIndex != 9 &&
        tabIndex != 10 &&
        tabIndex != 11 &&
        tabIndex != 12 &&
        tabIndex != 13) {
      return;
    }

    final authState = context.read<AuthCubit>().state;
    final userId = authState.loginResponse?.user.id;

    if (userId == null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && widget.selectedIndex == tabIndex) {
          _loadDataForTab(tabIndex, forceRefresh: forceRefresh);
        }
      });
      return;
    }

    switch (tabIndex) {
      case 2:
        final cubit = context.read<JourneyPlanCubit>();
        final state = cubit.state;
        if (forceRefresh || !state.isLoadingJourneyPlans) {
          if (state.selectedTabIndex == 0) {
            cubit.loadJourneyPlans(userId: userId);
          } else {
            cubit.loadJourneyPlans(createdById: userId);
          }
        }
        break;
      case 3:
        final cubit = context.read<TargetsCubit>();
        final state = cubit.state;
        final user = authState.loginResponse?.user;
        final isSalesRep = user?.role.toLowerCase() == 'salesrep';
        if (forceRefresh || !state.isLoadingTargets) {
          if (isSalesRep) {
            cubit.loadTargets(userId: userId);
          } else {
            cubit.loadTargets(createdById: userId);
          }
        }
        break;
      case 4:
        final journeyCubit = context.read<JourneyPlanCubit>();
        final standaloneTabIndex = journeyCubit.state.standaloneVisitsTabIndex;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        DateTime? startDate;
        DateTime? endDate;
        if (standaloneTabIndex == 0) {
          endDate = today;
        } else if (standaloneTabIndex == 1) {
          startDate = today;
        } else {
          startDate = today.add(const Duration(days: 1));
        }
        journeyCubit.loadVisits(
          userId: userId,
          startDate: startDate,
          endDate: endDate,
          status: null,
          standaloneOnly: true,
          applyStatusFilterFromState: false,
          pageNumber: 1,
          pageSize: 20,
        );
        journeyCubit.loadCustomers();
        break;
      case 5:
        final customersCubit = context.read<CustomersCubit>();
        final user = authState.loginResponse?.user;
        customersCubit.loadSeries();
        customersCubit.getCustomers(
          salesEmployeeCode: user?.sapSalesEmployeeCode,
          pageNumber: 1,
          pageSize: 10,
          append: false,
          scope: CustomerOdbcScope.all,
        );
        break;
      case 6:
        final salesOrderCubit = context.read<SalesOrderCubit>();
        salesOrderCubit.loadCustomers(
          salesEmployeeCode: authState.loginResponse?.user.sapSalesEmployeeCode,
        );
        salesOrderCubit.loadVatCodes();
        salesOrderCubit.loadSalesOrdersList(
          visitId: null,
          salesEmployeeCode: authState.loginResponse?.user.sapSalesEmployeeCode,
        );
        break;
      case 7:
        final salesOrderCubit = context.read<SalesOrderCubit>();
        salesOrderCubit.loadCustomers(
          salesEmployeeCode: authState.loginResponse?.user.sapSalesEmployeeCode,
        );
        salesOrderCubit.loadDeliveriesList(
          salesEmployeeCode: authState.loginResponse?.user.sapSalesEmployeeCode,
        );
        break;
      case 8:
        final returnsCubit = context.read<SalesOrderCubit>();
        returnsCubit.loadCustomers(
          salesEmployeeCode: authState.loginResponse?.user.sapSalesEmployeeCode,
        );
        returnsCubit.loadReturnsList(
          salesEmployeeCode: authState.loginResponse?.user.sapSalesEmployeeCode,
        );
        break;
      case 9:
        context.read<InventoryCubit>().loadWarehouses();
        break;
      case 10:
        final inventoryCubit = context.read<InventoryCubit>();
        inventoryCubit.loadWarehouses();
        final wh = authState.loginResponse?.user.defaultWarehouseCode?.trim();
        inventoryCubit.loadCountings(
          warehouseCode: (wh == null || wh.isEmpty) ? null : wh,
          skip: 0,
          take: 20,
        );
        break;
      case 11:
        context.read<TeamLocationsCubit>().fetchTeamLocations();
        break;
      case 12:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen:
          (prev, curr) =>
              prev.loginResponse?.user.id != curr.loginResponse?.user.id &&
              curr.loginResponse?.user.id != null,
      listener: (context, authState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadDataForTab(widget.selectedIndex, forceRefresh: true);
          }
        });
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (widget.selectedIndex) {
      case 0:
        return const MobileDashboardLandingPage();
      case 1:
        return _SettingsView();
      case 2:
        return BlocListener<AuthCubit, AuthState>(
          listenWhen:
              (prev, curr) =>
                  prev.loginResponse?.user.id != curr.loginResponse?.user.id &&
                  curr.loginResponse?.user.id != null,
          listener: (context, authState) {
            if (widget.selectedIndex == 2) {
              _loadDataForTab(2, forceRefresh: true);
            }
          },
          child: const JourneyPlanPage(showScaffold: false),
        );
      case 3:
        return BlocListener<AuthCubit, AuthState>(
          listenWhen:
              (prev, curr) =>
                  prev.loginResponse?.user.id != curr.loginResponse?.user.id &&
                  curr.loginResponse?.user.id != null,
          listener: (context, authState) {
            if (widget.selectedIndex == 3) {
              _loadDataForTab(3, forceRefresh: true);
            }
          },
          child: const TargetsPage(showScaffold: false),
        );
      case 4:
        return const StandaloneVisitPage();
      case 5:
        final role =
            context
                .read<AuthCubit>()
                .state
                .loginResponse
                ?.user
                .role
                .toLowerCase() ??
            '';
        if (role != 'salesrep') {
          return const MobileDashboardLandingPage();
        }
        return const CustomersListPage(showScaffold: false);
      case 6:
        return const SalesOrderListPage(showScaffold: false);
      case 7:
        return const DeliveriesListPage(showScaffold: false);
      case 8:
        return const ReturnsListPage(showScaffold: false);
      case 9:
        return const InventoryListPage(showScaffold: false);
      case 10:
        return const InventoryCountingListPage(showScaffold: false);
      case 11:
        final role =
            context
                .read<AuthCubit>()
                .state
                .loginResponse
                ?.user
                .role
                .toLowerCase() ??
            '';
        if (role != 'supervisor') {
          return const MobileDashboardLandingPage();
        }
        return const TeamLocationsMapPage();
      case 12:
        return const IncomingPaymentPage(showScaffold: false);
      case 13:
        return const ReportsLandingPage();
      default:
        return const MobileDashboardLandingPage();
    }
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: AppColors.surface,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width < 600 ? 16 : 32,
          vertical: MediaQuery.of(context).size.width < 600 ? 16 : 32,
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.border, width: 1),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width < 600 ? 16 : 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.language,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.selectLanguage,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const LanguageSelector(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
