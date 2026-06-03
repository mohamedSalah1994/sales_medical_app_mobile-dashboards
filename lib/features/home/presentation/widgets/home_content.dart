import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/core/constants/customer_odbc_scope.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/core/widgets/app_logo.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/journey_plan.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_state.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/pages/journey_plan_page.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/widgets/standalone_visit_sheet.dart';
import 'package:sales_medical_app_mobile/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_cubit.dart';
import 'package:sales_medical_app_mobile/features/customers/presentation/pages/customers_list_page.dart';
import 'package:sales_medical_app_mobile/features/field_staff/presentation/cubit/team_locations_cubit.dart';
import 'package:sales_medical_app_mobile/features/field_staff/presentation/pages/team_locations_map_page.dart';
import 'package:sales_medical_app_mobile/features/settings/presentation/widgets/language_selector.dart';
import 'package:sales_medical_app_mobile/features/targets/presentation/cubit/targets_cubit.dart';
import 'package:sales_medical_app_mobile/features/targets/presentation/cubit/targets_state.dart';
import 'package:sales_medical_app_mobile/features/targets/presentation/pages/targets_page.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/pages/inventory_counting_list_page.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/pages/inventory_list_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/deliveries_list_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/incoming_payment_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/returns_list_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/sales_order_list_page.dart';
import 'package:sales_medical_app_mobile/features/dashboard/presentation/pages/dashboard_landing_page.dart';
import 'package:sales_medical_app_mobile/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:sales_medical_app_mobile/features/wallet/presentation/widgets/wallet_card.dart';
import 'package:sales_medical_app_mobile/features/reports/presentation/pages/reports_landing_page.dart';
import 'package:sales_medical_app_mobile/features/reports/presentation/pages/target_achievement_page.dart';
// Surveys temporarily hidden
// import 'package:sales_medical_app_mobile/features/surveys/presentation/pages/surveys_page.dart';

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
    // When selectedIndex changes, load data for the new tab
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDataForTab(widget.selectedIndex);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Load data for initial tab after a short delay to ensure user ID is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _loadDataForTab(widget.selectedIndex, forceRefresh: true);
        }
      });
    });
  }

  void _loadDataForTab(int tabIndex, {bool forceRefresh = false}) {
    if (tabIndex != 0 &&
        tabIndex != 2 &&
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
        tabIndex != 13 &&
        tabIndex != 14) {
      return;
    }

    final authState = context.read<AuthCubit>().state;
    final userId = authState.loginResponse?.user.id;

    if (userId == null) {
      // If user not logged in yet, wait a bit and try again (up to 5 retries)
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && widget.selectedIndex == tabIndex) {
          _loadDataForTab(tabIndex, forceRefresh: forceRefresh);
        }
      });
      return;
    }

    switch (tabIndex) {
      case 0: // Home - Load both journeys and targets
        final journeyCubit = context.read<JourneyPlanCubit>();
        final targetsCubit = context.read<TargetsCubit>();
        final journeyState = journeyCubit.state;
        final targetsState = targetsCubit.state;
        final authState = context.read<AuthCubit>().state;
        final user = authState.loginResponse?.user;
        final isSalesRep = user?.role.toLowerCase() == 'salesrep';

        if (forceRefresh || !journeyState.isLoadingJourneyPlans) {
          journeyCubit.loadJourneyPlans(userId: userId);
        }
        final isSupervisor = user?.role.toLowerCase() == 'supervisor';
        if (isSupervisor && (forceRefresh || !journeyState.isLoadingVisits)) {
          journeyCubit.loadVisits(supervisorId: userId);
        }
        if (forceRefresh || !targetsState.isLoadingTargets) {
          // For SalesRep, send userId; for others, send createdById
          if (isSalesRep) {
            targetsCubit.loadTargets(userId: userId);
          } else {
            targetsCubit.loadTargets(createdById: userId);
          }
        }
        // Sales-employee wallet (account/project balance) for sales reps only.
        if (isSalesRep) {
          final walletCubit = context.read<WalletCubit>();
          if (forceRefresh || !walletCubit.state.isLoading) {
            walletCubit.loadWallet();
          }
        }
        break;
      case 2: // Journey Plans
        final cubit = context.read<JourneyPlanCubit>();
        final state = cubit.state;

        // Always load when tab is selected (if not already loading or force refresh)
        if (forceRefresh || !state.isLoadingJourneyPlans) {
          if (state.selectedTabIndex == 0) {
            cubit.loadJourneyPlans(userId: userId);
          } else {
            cubit.loadJourneyPlans(createdById: userId);
          }
        }
        break;
      case 3: // Targets
        final cubit = context.read<TargetsCubit>();
        final state = cubit.state;
        final authState = context.read<AuthCubit>().state;
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
      case 4: // Standalone Visit - load visits and customers once
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
      case 5: // Customers - load list and series (for create form)
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
      case 6: // Sales Order - customers for filters, VAT for create, orders list
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
      case 7: // Deliveries - ERP customers for filters + list
        final salesOrderCubit = context.read<SalesOrderCubit>();
        salesOrderCubit.loadCustomers(
          salesEmployeeCode: authState.loginResponse?.user.sapSalesEmployeeCode,
        );
        salesOrderCubit.loadDeliveriesList(
          salesEmployeeCode: authState.loginResponse?.user.sapSalesEmployeeCode,
        );
        break;
      case 8: // Returns
        final returnsCubit = context.read<SalesOrderCubit>();
        returnsCubit.loadCustomers(
          salesEmployeeCode: authState.loginResponse?.user.sapSalesEmployeeCode,
        );
        returnsCubit.loadReturnsList(
          salesEmployeeCode: authState.loginResponse?.user.sapSalesEmployeeCode,
        );
        break;
      case 9: // Inventory — ODBC warehouses for create / search
        context.read<InventoryCubit>().loadWarehouses();
        break;
      case 10: // Inventory counting — warehouses + list scoped to default warehouse
        final inventoryCubit = context.read<InventoryCubit>();
        inventoryCubit.loadWarehouses();
        final wh = authState.loginResponse?.user.defaultWarehouseCode?.trim();
        inventoryCubit.loadCountings(
          warehouseCode: (wh == null || wh.isEmpty) ? null : wh,
          skip: 0,
          take: 20,
        );
        break;
      case 11: // Supervisor team map — field staff last known locations
        context.read<TeamLocationsCubit>().fetchTeamLocations();
        break;
      case 12:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Also listen to auth state changes to reload when user logs in
    return BlocListener<AuthCubit, AuthState>(
      listenWhen:
          (prev, curr) =>
              prev.loginResponse?.user.id != curr.loginResponse?.user.id &&
              curr.loginResponse?.user.id != null,
      listener: (context, authState) {
        // When auth state changes (user logs in), force load data for current tab
        // Use addPostFrameCallback to ensure widget tree is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadDataForTab(widget.selectedIndex, forceRefresh: true);
          }
        });
      },
      child: _buildContent(),
    );
  }

  Future<void> _onRefreshDashboard() async {
    _loadDataForTab(0, forceRefresh: true);
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Widget _buildContent() {
    switch (widget.selectedIndex) {
      case 0:
        return _DashboardView(
          onTabChanged: widget.onTabChanged,
          onRefresh: _onRefreshDashboard,
        );
      case 1:
        return _SettingsView();
      case 2:
        return BlocListener<AuthCubit, AuthState>(
          listenWhen:
              (prev, curr) =>
                  prev.loginResponse?.user.id != curr.loginResponse?.user.id &&
                  curr.loginResponse?.user.id != null,
          listener: (context, authState) {
            // When user logs in and we're on Journey Plans tab, load data
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
          return _DashboardView(
            onTabChanged: widget.onTabChanged,
            onRefresh: _onRefreshDashboard,
          );
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
          return _DashboardView(
            onTabChanged: widget.onTabChanged,
            onRefresh: _onRefreshDashboard,
          );
        }
        return const TeamLocationsMapPage();
      case 12:
        return const IncomingPaymentPage(showScaffold: false);
      case 13:
        return const ReportsLandingPage();
      case 14:
        // New role-aware dashboard (Area Manager / Sales Employee Home).
        return const MobileDashboardLandingPage();
      default:
        return _DashboardView(onRefresh: _onRefreshDashboard);
    }
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({this.onTabChanged, this.onRefresh});

  final ValueChanged<int>? onTabChanged;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
        builder: (context, journeyState) {
          return BlocBuilder<TargetsCubit, TargetsState>(
            builder: (context, targetsState) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isTablet = screenWidth >= 600;
              final isDesktop = screenWidth >= 1024;

              return RefreshIndicator(
                onRefresh: () async {
                  if (onRefresh != null) await onRefresh!();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        isDesktop
                            ? 32
                            : isTablet
                            ? 24
                            : 16,
                    vertical: isDesktop ? 24 : 16,
                  ),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 1400 : double.infinity,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome Header
                          _WelcomeHeader(
                            isTablet: isTablet,
                            isDesktop: isDesktop,
                          ),
                          // Sales-employee wallet (account/project balance)
                          // is only meaningful for sales reps.
                          Builder(
                            builder: (context) {
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
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: EdgeInsets.only(
                                  top: isDesktop ? 24 : 16,
                                ),
                                child: WalletCard(
                                  isTablet: isTablet,
                                  isDesktop: isDesktop,
                                ),
                              );
                            },
                          ),
                          SizedBox(height: isDesktop ? 24 : 16),
                          // Quick Actions (small, above Today's Journeys)
                          _QuickActionsSection(
                            isTablet: isTablet,
                            isDesktop: isDesktop,
                            onTabChanged: onTabChanged,
                            compact: true,
                          ),
                          SizedBox(height: isDesktop ? 24 : 16),
                          // Today's journey (sales) / Out journey (supervisor) card
                          _TodayJourneyCard(
                            journeyState: journeyState,
                            onTabChanged: onTabChanged,
                            isTablet: isTablet,
                            isDesktop: isDesktop,
                          ),
                          SizedBox(height: isDesktop ? 32 : 24),
                          // Statistics Cards
                          _StatisticsCards(
                            journeyState: journeyState,
                            targetsState: targetsState,
                            isTablet: isTablet,
                            isDesktop: isDesktop,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.isTablet, required this.isDesktop});

  final bool isTablet;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final userName = authState.loginResponse?.user.fullName ?? 'User';
        final firstName = userName.split(' ').first;

        return Container(
          padding: EdgeInsets.all(
            isDesktop
                ? 18
                : isTablet
                ? 16
                : 14,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(isDesktop ? 14 : 12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: isDesktop ? 10 : 8,
                offset: Offset(0, isDesktop ? 4 : 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isDesktop
                      ? 12
                      : isTablet
                      ? 10
                      : 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isDesktop ? 10 : 8),
                ),
                child: AppLogo(
                  height:
                      isDesktop
                          ? 44
                          : isTablet
                          ? 40
                          : 36,
                  width:
                      isDesktop
                          ? 44
                          : isTablet
                          ? 40
                          : 36,
                  fallbackIconColor: Colors.white,
                ),
              ),
              SizedBox(
                width:
                    isDesktop
                        ? 14
                        : isTablet
                        ? 12
                        : 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.welcomeBackUser(firstName),
                      style: TextStyle(
                        fontSize:
                            isDesktop
                                ? 20
                                : isTablet
                                ? 18
                                : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 4 : 3),
                    Text(
                      AppLocalizations.of(context)!.heresYourOverview,
                      style: TextStyle(
                        fontSize:
                            isDesktop
                                ? 13
                                : isTablet
                                ? 12
                                : 11,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TodayJourneyCard extends StatelessWidget {
  const _TodayJourneyCard({
    required this.journeyState,
    required this.onTabChanged,
    required this.isTablet,
    required this.isDesktop,
  });

  final JourneyPlanState journeyState;
  final ValueChanged<int>? onTabChanged;
  final bool isTablet;
  final bool isDesktop;

  static bool _isDateInRange(DateTime date, DateTime start, DateTime end) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return (d.isAtSameMomentAs(s) || d.isAfter(s)) &&
        (d.isAtSameMomentAs(e) || d.isBefore(e));
  }

  static bool _isPlannedDateToday(Visit visit) {
    final t = DateTime(
      visit.plannedDateTime.year,
      visit.plannedDateTime.month,
      visit.plannedDateTime.day,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return t.isAtSameMomentAs(today);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.loginResponse?.user;
    final role = user?.role.toLowerCase() ?? '';
    final isSalesRep = role == 'salesrep';
    final isSupervisor = role == 'supervisor';

    if (!isSalesRep && !isSupervisor) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (isSalesRep) {
      final todayPlans =
          journeyState.journeyPlans
              .where(
                (JourneyPlan plan) =>
                    _isDateInRange(today, plan.startDate, plan.endDate),
              )
              .toList();
      final plan = todayPlans.isNotEmpty ? todayPlans.first : null;
      final title = "Today's journey";
      final subtitle =
          plan != null
              ? '${plan.userName.isNotEmpty ? plan.userName : 'My plan'} • ${DateFormat('MMM d').format(plan.startDate)} – ${DateFormat('MMM d').format(plan.endDate)}'
              : 'No journey for today';
      final visitCount = plan?.stops.length ?? 0;

      return _TodayJourneyCardContent(
        title: title,
        subtitle: subtitle,
        detail: plan != null && visitCount > 0 ? '$visitCount visit(s)' : null,
        isLoading: journeyState.isLoadingJourneyPlans,
        isTablet: isTablet,
        isDesktop: isDesktop,
        onTap: () => onTabChanged?.call(2),
      );
    }

    final todayVisits = journeyState.visits.where(_isPlannedDateToday).toList();
    final title = 'Out journey';
    final subtitle =
        todayVisits.isNotEmpty
            ? '${todayVisits.length} visit(s) assigned for today'
            : 'No assigned visits for today';
    final detail =
        todayVisits.isNotEmpty
            ? todayVisits.map((v) => v.customerName).take(2).join(', ')
            : null;

    return _TodayJourneyCardContent(
      title: title,
      subtitle: subtitle,
      detail:
          detail != null && detail.length > 40
              ? '${detail.substring(0, 40)}…'
              : detail,
      isLoading: journeyState.isLoadingVisits,
      isTablet: isTablet,
      isDesktop: isDesktop,
      onTap: () => onTabChanged?.call(2),
    );
  }
}

class _TodayJourneyCardContent extends StatelessWidget {
  const _TodayJourneyCardContent({
    required this.title,
    required this.subtitle,
    this.detail,
    required this.isLoading,
    required this.isTablet,
    required this.isDesktop,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String? detail;
  final bool isLoading;
  final bool isTablet;
  final bool isDesktop;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            isDesktop
                ? 20
                : isTablet
                ? 18
                : 16,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child:
              isLoading
                  ? Row(
                    children: [
                      SizedBox(
                        width: isDesktop ? 24 : 20,
                        height: isDesktop ? 24 : 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: isDesktop ? 16 : 12),
                      Expanded(
                        child: Text(
                          'Loading…',
                          style: TextStyle(
                            fontSize: isTablet ? 15 : 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  )
                  : Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isDesktop ? 12 : 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.route,
                          color: AppColors.primary,
                          size: isDesktop ? 28 : 24,
                        ),
                      ),
                      SizedBox(width: isDesktop ? 16 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize:
                                    isDesktop
                                        ? 18
                                        : isTablet
                                        ? 17
                                        : 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: isTablet ? 13 : 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (detail != null && detail!.isNotEmpty) ...[
                              SizedBox(height: 2),
                              Text(
                                detail!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}

class _StatisticsCards extends StatelessWidget {
  const _StatisticsCards({
    required this.journeyState,
    required this.targetsState,
    required this.isTablet,
    required this.isDesktop,
  });

  final JourneyPlanState journeyState;
  final TargetsState targetsState;
  final bool isTablet;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    // Calculate journey statistics
    final totalJourneys = journeyState.journeyPlans.length;
    final upcomingJourneys =
        journeyState.journeyPlans.where((plan) {
          final now = DateTime.now();
          return plan.startDate.isAfter(now) ||
              (plan.startDate.isBefore(now) && plan.endDate.isAfter(now));
        }).length;
    final approvedJourneys =
        journeyState.journeyPlans.where((plan) => plan.isApproved).length;
    final totalStops = journeyState.journeyPlans.fold<int>(
      0,
      (sum, plan) => sum + plan.stops.length,
    );

    // Calculate target statistics
    final totalTargets = targetsState.targets.length;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activeTargets =
        targetsState.targets.where((target) {
          final startDate = DateTime(
            target.startDate.year,
            target.startDate.month,
            target.startDate.day,
          );
          final endDate = DateTime(
            target.endDate.year,
            target.endDate.month,
            target.endDate.day,
          );
          return today.isAfter(startDate.subtract(const Duration(days: 1))) &&
              today.isBefore(endDate.add(const Duration(days: 1)));
        }).length;

    double averageProgress = 0.0;
    if (targetsState.targets.isNotEmpty) {
      double totalProgress = 0.0;
      for (final target in targetsState.targets) {
        final totalValue = target.breakdowns.fold<double>(
          0.0,
          (sum, breakdown) => sum + breakdown.value,
        );
        final totalAchieved = target.breakdowns.fold<double>(0.0, (
          sum,
          breakdown,
        ) {
          // For visits, always use achievedValue - visits are always considered complete
          // Visits should always be considered as completed regardless of details status
          return sum + breakdown.achievedValue;
        });
        if (totalValue > 0) {
          totalProgress += (totalAchieved / totalValue) * 100;
        }
      }
      averageProgress = totalProgress / targetsState.targets.length;
    }

    final crossAxisCount =
        isDesktop
            ? 4
            : isTablet
            ? 3
            : 2;
    final childAspectRatio =
        isDesktop
            ? 1.8
            : isTablet
            ? 1.6
            : 1.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Journey Statistics
        Text(
          AppLocalizations.of(context)!.journeyPlans,
          style: TextStyle(
            fontSize:
                isDesktop
                    ? 24
                    : isTablet
                    ? 20
                    : 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing:
              isDesktop
                  ? 16
                  : isTablet
                  ? 14
                  : 12,
          crossAxisSpacing:
              isDesktop
                  ? 16
                  : isTablet
                  ? 14
                  : 12,
          childAspectRatio: childAspectRatio,
          children: [
            _StatCard(
              title: AppLocalizations.of(context)!.totalJourneys,
              value: totalJourneys.toString(),
              icon: Icons.route,
              color: AppColors.primary,
              isLoading: journeyState.isLoadingJourneyPlans,
              isTablet: isTablet,
              isDesktop: isDesktop,
            ),
            _StatCard(
              title: AppLocalizations.of(context)!.upcoming,
              value: upcomingJourneys.toString(),
              icon: Icons.upcoming,
              color: AppColors.warning,
              isLoading: journeyState.isLoadingJourneyPlans,
            ),
            _StatCard(
              title: AppLocalizations.of(context)!.approved,
              value: approvedJourneys.toString(),
              icon: Icons.check_circle,
              color: AppColors.success,
              isLoading: journeyState.isLoadingJourneyPlans,
            ),
            _StatCard(
              title: AppLocalizations.of(context)!.totalStops,
              value: totalStops.toString(),
              icon: Icons.location_on,
              color: AppColors.accent,
              isLoading: journeyState.isLoadingJourneyPlans,
            ),
          ],
        ),
        SizedBox(height: isDesktop ? 32 : 24),
        // Target Statistics
        Text(
          AppLocalizations.of(context)!.targets,
          style: TextStyle(
            fontSize:
                isDesktop
                    ? 24
                    : isTablet
                    ? 20
                    : 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing:
              isDesktop
                  ? 16
                  : isTablet
                  ? 14
                  : 12,
          crossAxisSpacing:
              isDesktop
                  ? 16
                  : isTablet
                  ? 14
                  : 12,
          childAspectRatio: childAspectRatio,
          children: [
            _StatCard(
              title: AppLocalizations.of(context)!.totalTargets,
              value: totalTargets.toString(),
              icon: Icons.track_changes,
              color: AppColors.primary,
              isLoading: targetsState.isLoadingTargets,
            ),
            _StatCard(
              title: AppLocalizations.of(context)!.active,
              value: activeTargets.toString(),
              icon: Icons.trending_up,
              color: AppColors.success,
              isLoading: targetsState.isLoadingTargets,
            ),
            _StatCard(
              title: AppLocalizations.of(context)!.avgProgress,
              value: '${averageProgress.toStringAsFixed(1)}%',
              icon: Icons.analytics,
              color: AppColors.warning,
              isLoading: targetsState.isLoadingTargets,
            ),
            _StatCard(
              title: AppLocalizations.of(context)!.inactive,
              value: (totalTargets - activeTargets).toString(),
              icon: Icons.pause_circle,
              color: AppColors.textSecondary,
              isLoading: targetsState.isLoadingTargets,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isLoading = false,
    this.isTablet = false,
    this.isDesktop = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final bool isTablet;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final iconSize =
        isDesktop
            ? 22.0
            : isTablet
            ? 20.0
            : 18.0;
    final valueFontSize =
        isDesktop
            ? 34.0
            : isTablet
            ? 30.0
            : 26.0;
    final titleFontSize =
        isDesktop
            ? 12.0
            : isTablet
            ? 11.0
            : 10.0;
    final padding =
        isDesktop
            ? 18.0
            : isTablet
            ? 16.0
            : 14.0;
    final borderRadius =
        isDesktop
            ? 20.0
            : isTablet
            ? 18.0
            : 16.0;

    return Card(
      elevation: isDesktop ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius.toDouble()),
        side: BorderSide(
          color: color.withValues(alpha: 0.2),
          width: isDesktop ? 2 : 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius.toDouble()),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
              Colors.white,
            ],
          ),
          boxShadow:
              isDesktop
                  ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        padding: EdgeInsets.all(padding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side: Icon and Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: EdgeInsets.all(
                      isDesktop
                          ? 8
                          : isTablet
                          ? 7
                          : 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(isDesktop ? 10 : 8),
                    ),
                    child: Icon(icon, color: color, size: iconSize.toDouble()),
                  ),
                  SizedBox(
                    height:
                        isDesktop
                            ? 10
                            : isTablet
                            ? 8
                            : 6,
                  ),
                  // Title
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: titleFontSize.toDouble(),
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width:
                  isDesktop
                      ? 12
                      : isTablet
                      ? 10
                      : 8,
            ),
            // Right side: Number/Value
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading)
                    SizedBox(
                      width: isDesktop ? 18 : 16,
                      height: isDesktop ? 18 : 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  else
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: valueFontSize.toDouble(),
                        fontWeight: FontWeight.bold,
                        color: color,
                        height: 1.0,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({
    required this.isTablet,
    required this.isDesktop,
    this.onTabChanged,
    this.compact = false,
  });

  final bool isTablet;
  final bool isDesktop;
  final ValueChanged<int>? onTabChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final role =
        context
            .read<AuthCubit>()
            .state
            .loginResponse
            ?.user
            .role
            .toLowerCase() ??
        '';
    final isSalesRep = role == 'salesrep';
    final double cardWidth = compact ? 100 : 130;
    final spacing = compact ? 6.0 : (isDesktop ? 12.0 : 10.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActions,
          style: TextStyle(
            fontSize:
                compact
                    ? (isDesktop
                        ? 14
                        : isTablet
                        ? 13
                        : 12)
                    : (isDesktop
                        ? 24
                        : isTablet
                        ? 20
                        : 18),
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: compact ? 0.5 : null,
          ),
        ),
        SizedBox(height: compact ? 8 : (isDesktop ? 16 : 12)),
        SizedBox(
          height: compact ? 78 : (isDesktop ? 110 : 95),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              SizedBox(
                width: cardWidth,
                child: BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
                  buildWhen: (prev, curr) => prev.isOffline != curr.isOffline,
                  builder: (context, jpState) {
                    return Opacity(
                      opacity: jpState.isOffline ? 0.5 : 1,
                      child: _QuickActionCard(
                        title: l10n.journeyPlans,
                        icon: Icons.add_road,
                        color: AppColors.primary,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                        compact: compact,
                        onTap:
                            jpState.isOffline
                                ? null
                                : () {
                                  if (onTabChanged != null) onTabChanged!(2);
                                },
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _QuickActionCard(
                  title: l10n.standaloneVisits,
                  icon: Icons.person_pin_circle_outlined,
                  color: AppColors.primary,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                  compact: compact,
                  onTap: () {
                    if (onTabChanged != null) onTabChanged!(4);
                  },
                ),
              ),
              if (isSalesRep) ...[
                SizedBox(width: spacing),
                SizedBox(
                  width: cardWidth,
                  child: _QuickActionCard(
                    title: l10n.customers,
                    icon: Icons.people_outline,
                    color: AppColors.accent,
                    isTablet: isTablet,
                    isDesktop: isDesktop,
                    compact: compact,
                    onTap: () {
                      if (onTabChanged != null) onTabChanged!(5);
                    },
                  ),
                ),
              ],
              SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _QuickActionCard(
                  title: l10n.targets,
                  icon: Icons.track_changes,
                  color: AppColors.success,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                  compact: compact,
                  onTap: () {
                    if (onTabChanged != null) onTabChanged!(3);
                  },
                ),
              ),
              SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _QuickActionCard(
                  title: l10n.salesOrders,
                  icon: Icons.shopping_cart_outlined,
                  color: AppColors.primary,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                  compact: compact,
                  onTap: () {
                    if (onTabChanged != null) onTabChanged!(6);
                  },
                ),
              ),
              SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _QuickActionCard(
                  title: l10n.deliveries,
                  icon: Icons.local_shipping_outlined,
                  color: AppColors.accent,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                  compact: compact,
                  onTap: () {
                    if (onTabChanged != null) onTabChanged!(7);
                  },
                ),
              ),
              SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _QuickActionCard(
                  title: l10n.returns,
                  icon: Icons.assignment_return_outlined,
                  color: AppColors.success,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                  compact: compact,
                  onTap: () {
                    if (onTabChanged != null) onTabChanged!(8);
                  },
                ),
              ),
              SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _QuickActionCard(
                  title: 'Incoming payment',
                  icon: Icons.payments_outlined,
                  color: AppColors.success,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                  compact: compact,
                  onTap: () {
                    if (onTabChanged != null) onTabChanged!(12);
                  },
                ),
              ),
              SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _QuickActionCard(
                  title: l10n.inventory,
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.warning,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                  compact: compact,
                  onTap: () {
                    if (onTabChanged != null) onTabChanged!(9);
                  },
                ),
              ),
              SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _QuickActionCard(
                  title: l10n.inventoryCounting,
                  icon: Icons.fact_check_outlined,
                  color: AppColors.warning,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                  compact: compact,
                  onTap: () {
                    if (onTabChanged != null) onTabChanged!(10);
                  },
                ),
              ),
              SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _QuickActionCard(
                  title: 'Reports',
                  icon: Icons.assessment_outlined,
                  color: AppColors.accent,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                  compact: compact,
                  onTap: () {
                    if (onTabChanged != null) onTabChanged!(13);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
    this.isTablet = false,
    this.isDesktop = false,
    this.compact = false,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isTablet;
  final bool isDesktop;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize =
        compact
            ? (isDesktop
                ? 18.0
                : isTablet
                ? 16.0
                : 14.0)
            : (isDesktop
                ? 32.0
                : isTablet
                ? 28.0
                : 24.0);
    final borderRadius =
        compact
            ? 8.0
            : (isDesktop
                ? 16.0
                : isTablet
                ? 14.0
                : 12.0);
    final padding =
        compact
            ? 8.0
            : (isDesktop
                ? 20.0
                : isTablet
                ? 16.0
                : 14.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: compact ? 1 : (isDesktop ? 2 : 1.5),
            ),
            color: color.withValues(alpha: 0.06),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(icon, color: color, size: iconSize),
              SizedBox(height: compact ? 4 : (isDesktop ? 12 : 10)),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize:
                      compact
                          ? 10
                          : (isDesktop
                              ? 14
                              : isTablet
                              ? 12
                              : 11),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
