import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:sales_medical_app_mobile/core/di/service_locator.dart';
import 'package:sales_medical_app_mobile/core/field_staff/field_staff_location_tracker.dart';
import 'package:sales_medical_app_mobile/features/field_staff/data/field_staff_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/field_staff/presentation/cubit/team_locations_cubit.dart';
import 'package:sales_medical_app_mobile/core/localization/language_cubit.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/home/presentation/widgets/mobile_drawer.dart';
import 'package:sales_medical_app_mobile/features/home/presentation/widgets/home_content.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/widgets/standalone_visit_sheet.dart';
import 'package:sales_medical_app_mobile/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:sales_medical_app_mobile/features/targets/presentation/cubit/targets_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_state.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/widgets/journey_plan_user_filter_field.dart';
import 'package:sales_medical_app_mobile/features/targets/presentation/cubit/targets_state.dart';
import 'package:sales_medical_app_mobile/features/surveys/presentation/cubit/surveys_cubit.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_cubit.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_state.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/deliveries_filter_bottom_sheet.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/sales_orders_filter_bottom_sheet.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/returns_filter_bottom_sheet.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/incoming_payment_page.dart';
import 'package:sales_medical_app_mobile/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<LanguageCubit>()),
        BlocProvider.value(value: context.read<JourneyPlanCubit>()),
        BlocProvider(create: (_) => sl<TargetsCubit>()),
        BlocProvider(create: (_) => sl<SurveysCubit>()),
        BlocProvider(create: (_) => sl<CustomersCubit>()),
        BlocProvider(create: (_) => sl<SalesOrderCubit>()),
        BlocProvider(create: (_) => sl<InventoryCubit>()),
        BlocProvider(create: (_) => sl<WalletCubit>()),
        BlocProvider(
          create: (_) => TeamLocationsCubit(
            remoteDataSource: sl<FieldStaffRemoteDataSource>(),
          ),
        ),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Load initial data when home page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      if (mounted) {
        sl<FieldStaffLocationTracker>().attach(context.read<AuthCubit>());
      }
    });
  }

  void _loadInitialData({int retryCount = 0}) {
    final authState = context.read<AuthCubit>().state;
    final userId = authState.loginResponse?.user.id;

    if (userId != null) {
      // Load both journey plans and targets on initial load
      final journeyCubit = context.read<JourneyPlanCubit>();
      final targetsCubit = context.read<TargetsCubit>();
      final authState = context.read<AuthCubit>().state;
      final user = authState.loginResponse?.user;
      final isSalesRep = user?.role.toLowerCase() == 'salesrep';
      final isSupervisor = user?.role.toLowerCase() == 'supervisor';
      journeyCubit.loadJourneyPlans(userId: userId);
      if (isSupervisor) {
        journeyCubit.loadVisits(supervisorId: userId);
      }
      // For SalesRep, send userId; for others, send createdById
      if (isSalesRep) {
        targetsCubit.loadTargets(userId: userId);
        context.read<WalletCubit>().loadWallet();
      } else {
        targetsCubit.loadTargets(createdById: userId);
      }
    } else if (retryCount < 5) {
      // Retry after a short delay if user ID is not available yet
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _loadInitialData(retryCount: retryCount + 1);
        }
      });
    }
  }

  void _onItemTapped(int index) {
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
    final isSupervisor = role == 'supervisor';
    // Customers tab: SalesRep and Supervisor
    if (index == 5 && !isSalesRep && !isSupervisor) {
      index = 0;
    }
    // Team map is supervisor-only
    if (index == 11 && !isSupervisor) {
      index = 0;
    }
    setState(() {
      _selectedIndex = index;
    });
    // Close drawer if open
    _scaffoldKey.currentState?.closeDrawer();

    // Load data for the selected tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataForTab(index);
    });
  }

  void _loadDataForTab(int tabIndex) {
    final authState = context.read<AuthCubit>().state;
    final userId = authState.loginResponse?.user.id;

    if (userId == null) return;

    switch (tabIndex) {
      case 2: // Journey Plans
        final cubit = context.read<JourneyPlanCubit>();
        cubit.loadJourneyPlans(userId: userId);
        break;
      case 3: // Targets
        final cubit = context.read<TargetsCubit>();
        final authState = context.read<AuthCubit>().state;
        final user = authState.loginResponse?.user;
        final isSalesRep = user?.role.toLowerCase() == 'salesrep';
        if (isSalesRep) {
          cubit.loadTargets(userId: userId);
        } else {
          cubit.loadTargets(createdById: userId);
        }
        break;
      case 4: // Standalone Visit - load customers for the form
        context.read<JourneyPlanCubit>().loadCustomers();
        break;
      case 11:
        context.read<TeamLocationsCubit>().fetchTeamLocations();
        break;
      case 12:
        break;
    }
  }

  void _showJourneyPlanFilterDialog(
    BuildContext context,
    JourneyPlanState state,
  ) {
    final cubit = context.read<JourneyPlanCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (dialogContext) => BlocProvider.value(
            value: cubit,
            child: _JourneyPlanFilterBottomSheet(state: state),
          ),
    );
  }

  void _showTargetsFilterDialog(BuildContext context, TargetsState state) {
    final cubit = context.read<TargetsCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (dialogContext) => BlocProvider.value(
            value: cubit,
            child: _TargetsFilterBottomSheet(state: state),
          ),
    );
  }

  void _showDeliveriesFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => BlocProvider.value(
            value: context.read<SalesOrderCubit>(),
            child: BlocProvider.value(
              value: context.read<AuthCubit>(),
              child: const DeliveriesFilterBottomSheet(),
            ),
          ),
    );
  }

  void _showSalesOrdersFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => BlocProvider.value(
            value: context.read<SalesOrderCubit>(),
            child: BlocProvider.value(
              value: context.read<AuthCubit>(),
              child: const SalesOrdersFilterBottomSheet(visitId: null),
            ),
          ),
    );
  }

  void _showReturnsFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => BlocProvider.value(
            value: context.read<SalesOrderCubit>(),
            child: BlocProvider.value(
              value: context.read<AuthCubit>(),
              child: const ReturnsFilterBottomSheet(),
            ),
          ),
    );
  }

  void _showIncomingPaymentFilterSheet(BuildContext context) {
    final current = IncomingPaymentFilterBridge.notifier.value;
    final customerController = TextEditingController(text: current.customerCode);
    DateTime? tempFrom = current.dateFrom;
    DateTime? tempTo = current.dateTo;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              Future<void> pickFrom() async {
                final picked = await showDatePicker(
                  context: sheetContext,
                  initialDate: tempFrom ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked == null) return;
                setSheetState(() => tempFrom = picked);
              }

              Future<void> pickTo() async {
                final picked = await showDatePicker(
                  context: sheetContext,
                  initialDate: tempTo ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked == null) return;
                setSheetState(() => tempTo = picked);
              }

              return SingleChildScrollView(
                child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Filters',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: customerController,
                      decoration: InputDecoration(
                        hintText: 'Customer code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: pickFrom,
                            icon: const Icon(Icons.date_range),
                            label: Text(
                              tempFrom == null
                                  ? 'Date from'
                                  : DateFormat('yyyy-MM-dd').format(tempFrom!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: pickTo,
                            icon: const Icon(Icons.event),
                            label: Text(
                              tempTo == null
                                  ? 'Date to'
                                  : DateFormat('yyyy-MM-dd').format(tempTo!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              IncomingPaymentFilterBridge.apply(
                                customerCode: '',
                                dateFrom: null,
                                dateTo: null,
                              );
                              Navigator.of(sheetContext).pop();
                            },
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              IncomingPaymentFilterBridge.apply(
                                customerCode: customerController.text.trim(),
                                dateFrom: tempFrom,
                                dateTo: tempTo,
                              );
                              Navigator.of(sheetContext).pop();
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return BlocListener<AuthCubit, AuthState>(
      listenWhen:
          (prev, curr) =>
              prev.loginResponse?.user.id != curr.loginResponse?.user.id &&
              curr.loginResponse?.user.id != null,
      listener: (context, authState) {
        // When user logs in, load both journey plans and targets
        // Use addPostFrameCallback to ensure widget tree is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final userId = authState.loginResponse?.user.id;
          if (userId != null && mounted) {
            final journeyCubit = context.read<JourneyPlanCubit>();
            final targetsCubit = context.read<TargetsCubit>();
            final user = authState.loginResponse?.user;
            final isSalesRep = user?.role.toLowerCase() == 'salesrep';
            journeyCubit.loadJourneyPlans(userId: userId);
            // For SalesRep, send userId; for others, send createdById
            if (isSalesRep) {
              targetsCubit.loadTargets(userId: userId);
              context.read<WalletCubit>().loadWallet();
            } else {
              targetsCubit.loadTargets(createdById: userId);
            }
          }
        });
      },
      child: BlocListener<JourneyPlanCubit, JourneyPlanState>(
        listenWhen:
            (prev, curr) =>
                prev.pendingHomeTabIndex != curr.pendingHomeTabIndex,
        listener: (context, state) {
          final idx = state.pendingHomeTabIndex;
          if (idx != null) {
            _onItemTapped(idx);
            context.read<JourneyPlanCubit>().clearPendingHomeTab();
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          appBar: _buildResponsiveAppBar(context, isSmallScreen),
          drawer: MobileDrawer(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          ),
          body: Container(
            color: AppColors.surface,
            child: HomeContent(
              selectedIndex: _selectedIndex,
              onTabChanged: _onItemTapped,
            ),
          ),
          floatingActionButton:
              _selectedIndex == 2
                  ? BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
                    buildWhen:
                        (prev, curr) => prev.isOffline != curr.isOffline,
                    builder: (context, jpState) {
                      return FloatingActionButton.extended(
                        onPressed:
                            jpState.isOffline
                                ? null
                                : () {
                                  context
                                      .read<JourneyPlanCubit>()
                                      .showCreateForm();
                                },
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        icon: const Icon(Icons.add),
                        label: Text(
                          AppLocalizations.of(context)!.createJourneyPlan,
                        ),
                        elevation: 4,
                        tooltip:
                            jpState.isOffline
                                ? 'Create journey plan requires an internet connection'
                                : null,
                      );
                    },
                  )
                  : _selectedIndex == 4
                  ? FloatingActionButton.extended(
                    onPressed: () => showStandaloneVisitSheet(context),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.add),
                    label: Text(
                      AppLocalizations.of(context)!.createStandaloneVisit,
                    ),
                    elevation: 4,
                  )
                  : null,
          bottomNavigationBar: _buildBottomNavigationBar(context),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildResponsiveAppBar(
    BuildContext context,
    bool isSmallScreen,
  ) {
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
    final isSupervisor = role == 'supervisor';
    final pageTitle =
        _selectedIndex == 0
            ? l10n.dashboard
            : _selectedIndex == 1
            ? l10n.settings
            : _selectedIndex == 2
            ? l10n.journeyPlans
            : _selectedIndex == 3
            ? l10n.targets
            : _selectedIndex == 4
            ? l10n.standaloneVisit
            : (_selectedIndex == 5 && (isSalesRep || isSupervisor))
            ? l10n.customers
            : _selectedIndex == 6
            ? l10n.salesOrder
            : _selectedIndex == 7
            ? l10n.deliveries
            : _selectedIndex == 8
            ? l10n.returns
            : _selectedIndex == 9
            ? l10n.inventory
            : _selectedIndex == 10
            ? l10n.inventoryCounting
            : _selectedIndex == 11
            ? l10n.teamMapTitle
            : _selectedIndex == 12
            ? 'Incoming payment'
            : _selectedIndex == 13
            ? 'Reports'
            : l10n.dashboard;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        tooltip: 'Menu',
      ),
      backgroundColor: AppColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              pageTitle,
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      actions: [
        // Filter button for Journey Plans
        if (_selectedIndex == 2)
          BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
            builder: (context, journeyState) {
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color:
                          journeyState.hasActiveFilters
                              ? AppColors.primary
                              : AppColors.textSecondary,
                    ),
                    onPressed: () {
                      _showJourneyPlanFilterDialog(context, journeyState);
                    },
                    tooltip: 'Filters',
                  ),
                  if (journeyState.hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        // Filter button for Targets
        if (_selectedIndex == 3)
          BlocBuilder<TargetsCubit, TargetsState>(
            builder: (context, targetsState) {
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color:
                          targetsState.hasActiveFilters
                              ? AppColors.primary
                              : AppColors.textSecondary,
                    ),
                    onPressed: () {
                      _showTargetsFilterDialog(context, targetsState);
                    },
                    tooltip: 'Filters',
                  ),
                  if (targetsState.hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        if (_selectedIndex == 6)
          BlocBuilder<SalesOrderCubit, SalesOrderState>(
            builder: (context, salesOrderState) {
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color:
                          salesOrderState.hasActiveOrdersFilters
                              ? AppColors.primary
                              : AppColors.textSecondary,
                    ),
                    onPressed: () => _showSalesOrdersFilterSheet(context),
                    tooltip: 'Filters',
                  ),
                  if (salesOrderState.hasActiveOrdersFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        if (_selectedIndex == 7)
          BlocBuilder<SalesOrderCubit, SalesOrderState>(
            builder: (context, salesOrderState) {
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color:
                          salesOrderState.hasActiveDeliveriesFilters
                              ? AppColors.primary
                              : AppColors.textSecondary,
                    ),
                    onPressed: () => _showDeliveriesFilterSheet(context),
                    tooltip: 'Filters',
                  ),
                  if (salesOrderState.hasActiveDeliveriesFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        if (_selectedIndex == 8)
          BlocBuilder<SalesOrderCubit, SalesOrderState>(
            builder: (context, salesOrderState) {
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color:
                          salesOrderState.hasActiveReturnsFilters
                              ? AppColors.primary
                              : AppColors.textSecondary,
                    ),
                    onPressed: () => _showReturnsFilterSheet(context),
                    tooltip: 'Filters',
                  ),
                  if (salesOrderState.hasActiveReturnsFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        if (_selectedIndex == 12)
          ValueListenableBuilder<IncomingPaymentFilters>(
            valueListenable: IncomingPaymentFilterBridge.notifier,
            builder: (context, filters, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color:
                          filters.hasActive
                              ? AppColors.primary
                              : AppColors.textSecondary,
                    ),
                    onPressed: () => _showIncomingPaymentFilterSheet(context),
                    tooltip: 'Filters',
                  ),
                  if (filters.hasActive)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final user = state.loginResponse?.user;
            if (user == null) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.only(right: isSmallScreen ? 8 : 16),
              child: _buildUserMenuButton(context, user, isSmallScreen),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUserMenuButton(BuildContext context, user, bool isSmallScreen) {
    final fullName = user.fullName ?? user.email ?? 'User';
    final firstLetter = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';

    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSmallScreen) ...[
              Icon(
                Icons.notifications_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
            ],
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Text(
                firstLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return [
          PopupMenuItem<String>(
            value: 'notifications',
            child: Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Notifications',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'profile',
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.profile,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, size: 20, color: AppColors.error),
                const SizedBox(width: 12),
                Text(
                  l10n.logout,
                  style: TextStyle(color: AppColors.error, fontSize: 14),
                ),
              ],
            ),
          ),
        ];
      },
      onSelected: (value) {
        if (value == 'logout') {
          context.read<AuthCubit>().logout();
          if (context.mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        } else if (value == 'profile') {
          // Navigate to profile page
        } else if (value == 'notifications') {
          // Navigate to notifications page
        }
      },
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final List<_NavItem> navItems = [
      _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: AppLocalizations.of(context)!.dashboard,
        index: 0,
      ),
      _NavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        label: AppLocalizations.of(context)!.settings,
        index: 1,
      ),
      _NavItem(
        icon: Icons.route_outlined,
        activeIcon: Icons.route,
        label: AppLocalizations.of(context)!.journeyPlan,
        index: 2,
      ),
      _NavItem(
        icon: Icons.track_changes_outlined,
        activeIcon: Icons.track_changes,
        label: AppLocalizations.of(context)!.targets,
        index: 3,
      ),
    ];

    return BottomNavigationBar(
      currentIndex: _selectedIndex > 3 ? 0 : _selectedIndex,
      onTap: (index) {
        _onItemTapped(navItems[index].index);
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      backgroundColor: Colors.white,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items:
          navItems.map((item) {
            final isSelected = _selectedIndex == item.index;
            return BottomNavigationBarItem(
              icon: Icon(isSelected ? item.activeIcon : item.icon),
              label: item.label,
            );
          }).toList(),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
  });
}

class _JourneyPlanFilterBottomSheet extends StatefulWidget {
  const _JourneyPlanFilterBottomSheet({required this.state});

  final JourneyPlanState state;

  @override
  State<_JourneyPlanFilterBottomSheet> createState() =>
      _JourneyPlanFilterBottomSheetState();
}

class _JourneyPlanFilterBottomSheetState
    extends State<_JourneyPlanFilterBottomSheet> {
  final TextEditingController _customerSearchController =
      TextEditingController();
  Timer? _customerSearchDebounce;

  @override
  void initState() {
    super.initState();
    _customerSearchController.addListener(_onCustomerSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<JourneyPlanCubit>();
      final state = cubit.state;
      final auth = context.read<AuthCubit>().state.loginResponse?.user;

      if (state.customers.isEmpty && !state.isLoadingCustomers) {
        cubit.loadCustomers();
      }

      final ownerId = resolveSubordinatesOwnerId(
        loggedInUserId: auth?.id,
        role: auth?.role,
        filterSupervisorId: state.filterSupervisorId,
      );
      if (ownerId != null && showJourneyPlanUserFilterForRole(auth?.role)) {
        cubit.loadSubordinates(ownerId);
      }
    });
  }

  void _onCustomerSearchChanged() {
    _customerSearchDebounce?.cancel();
    _customerSearchDebounce = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      final value = _customerSearchController.text.trim();
      context.read<JourneyPlanCubit>().loadCustomers(
        search: value.isEmpty ? null : value,
      );
    });
  }

  @override
  void dispose() {
    _customerSearchDebounce?.cancel();
    _customerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: BlocProvider.value(
        value: context.read<JourneyPlanCubit>(),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (sheetContext, scrollController) {
            return BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
              builder: (builderContext, state) {
                return Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Text(
                            'Filters',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (state.hasActiveFilters)
                            TextButton.icon(
                              onPressed: () {
                                builderContext
                                    .read<JourneyPlanCubit>()
                                    .clearFilters();
                                builderContext
                                    .read<JourneyPlanCubit>()
                                    .applyFilters();
                              },
                              icon: const Icon(Icons.clear_all, size: 18),
                              label: const Text('Clear All'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(builderContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    // Filter Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Filter
                            if (showJourneyPlanUserFilterForRole(
                              builderContext
                                  .read<AuthCubit>()
                                  .state
                                  .loginResponse
                                  ?.user
                                  .role,
                            )) ...[
                              Text(
                                'Filter by User',
                                style: Theme.of(
                                  context,
                                ).textTheme.labelLarge?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              JourneyPlanUserFilterField(
                                state: state,
                                onUserSelected: (userId) {
                                  builderContext
                                      .read<JourneyPlanCubit>()
                                      .setFilters(
                                        userId: userId,
                                        supervisorId: state.filterSupervisorId,
                                        customerId: state.filterCustomerId,
                                        startDate: state.filterStartDate,
                                        endDate: state.filterEndDate,
                                      );
                                  builderContext
                                      .read<JourneyPlanCubit>()
                                      .applyFilters();
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                            // Customer Filter
                            Text(
                              'Filter by Customer',
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: TextField(
                                controller: _customerSearchController,
                                decoration: InputDecoration(
                                  hintText: 'Search by name or code',
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: AppColors.textSecondary,
                                  ),
                                  suffixIcon:
                                      _customerSearchController.text.isNotEmpty
                                          ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              _customerSearchController.clear();
                                            },
                                          )
                                          : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (_) {
                                final selectedExists =
                                    state.filterCustomerId == null ||
                                    state.customers.any(
                                      (customer) =>
                                          customer.id == state.filterCustomerId,
                                    );

                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: DropdownButtonFormField<String?>(
                                    value:
                                        selectedExists
                                            ? state.filterCustomerId
                                            : null,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      hintText:
                                          state.isLoadingCustomers
                                              ? 'Loading customers...'
                                              : 'All Customers',
                                      filled: true,
                                      fillColor: AppColors.card,
                                      prefixIcon: Icon(
                                        Icons.business,
                                        color: AppColors.textSecondary,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                    ),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('All Customers'),
                                      ),
                                      ...state.customers.map(
                                        (customer) => DropdownMenuItem<String?>(
                                          value: customer.id,
                                          child: Text(
                                            customer.displayLabelWithCode,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged:
                                        state.isLoadingCustomers
                                            ? null
                                            : (value) {
                                              builderContext
                                                  .read<JourneyPlanCubit>()
                                                  .setFilters(
                                                    userId: state.filterUserId,
                                                    customerId: value,
                                                    clearCustomerId:
                                                        value == null,
                                                    startDate:
                                                        state.filterStartDate,
                                                    endDate:
                                                        state.filterEndDate,
                                                  );
                                              builderContext
                                                  .read<JourneyPlanCubit>()
                                                  .applyFilters();
                                            },
                                  ),
                                );
                              },
                            ),
                            if (state.customersErrorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                state.customersErrorMessage!,
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            // Period Filter
                            Text(
                              'Filter by Period',
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Start Date
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final selectedDate = await showDatePicker(
                                        context: builderContext,
                                        initialDate:
                                            state.filterStartDate ??
                                            DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (selectedDate != null && mounted) {
                                        builderContext
                                            .read<JourneyPlanCubit>()
                                            .setFilters(
                                              userId: state.filterUserId,
                                              startDate: selectedDate,
                                              endDate: state.filterEndDate,
                                            );
                                        builderContext
                                            .read<JourneyPlanCubit>()
                                            .applyFilters();
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: AppColors.textSecondary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Start Date',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  state.filterStartDate != null
                                                      ? DateFormat(
                                                        'MMM dd, yyyy',
                                                      ).format(
                                                        state.filterStartDate!,
                                                      )
                                                      : 'Select date',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        state.filterStartDate !=
                                                                null
                                                            ? AppColors
                                                                .textPrimary
                                                            : AppColors
                                                                .textSecondary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (state.filterStartDate != null)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                size: 18,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed: () {
                                                builderContext
                                                    .read<JourneyPlanCubit>()
                                                    .setFilters(
                                                      userId:
                                                          state.filterUserId,
                                                      startDate: null,
                                                      endDate:
                                                          state.filterEndDate,
                                                    );
                                                builderContext
                                                    .read<JourneyPlanCubit>()
                                                    .applyFilters();
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // End Date
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final selectedDate = await showDatePicker(
                                        context: builderContext,
                                        initialDate:
                                            state.filterEndDate ??
                                            (state.filterStartDate ??
                                                DateTime.now()),
                                        firstDate:
                                            state.filterStartDate ??
                                            DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (selectedDate != null && mounted) {
                                        builderContext
                                            .read<JourneyPlanCubit>()
                                            .setFilters(
                                              userId: state.filterUserId,
                                              startDate: state.filterStartDate,
                                              endDate: selectedDate,
                                            );
                                        builderContext
                                            .read<JourneyPlanCubit>()
                                            .applyFilters();
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.event,
                                            color: AppColors.textSecondary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'End Date',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  state.filterEndDate != null
                                                      ? DateFormat(
                                                        'MMM dd, yyyy',
                                                      ).format(
                                                        state.filterEndDate!,
                                                      )
                                                      : 'Select date',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        state.filterEndDate !=
                                                                null
                                                            ? AppColors
                                                                .textPrimary
                                                            : AppColors
                                                                .textSecondary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (state.filterEndDate != null)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                size: 18,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed: () {
                                                builderContext
                                                    .read<JourneyPlanCubit>()
                                                    .setFilters(
                                                      userId:
                                                          state.filterUserId,
                                                      startDate:
                                                          state.filterStartDate,
                                                      endDate: null,
                                                    );
                                                builderContext
                                                    .read<JourneyPlanCubit>()
                                                    .applyFilters();
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Apply Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(builderContext).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Apply Filters',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TargetsFilterBottomSheet extends StatefulWidget {
  const _TargetsFilterBottomSheet({required this.state});

  final TargetsState state;

  @override
  State<_TargetsFilterBottomSheet> createState() =>
      _TargetsFilterBottomSheetState();
}

class _TargetsFilterBottomSheetState extends State<_TargetsFilterBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: BlocProvider.value(
        value: context.read<TargetsCubit>(),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (sheetContext, scrollController) {
            return BlocBuilder<TargetsCubit, TargetsState>(
              builder: (builderContext, state) {
                return Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Text(
                            'Filters',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (state.hasActiveFilters)
                            TextButton.icon(
                              onPressed: () {
                                builderContext
                                    .read<TargetsCubit>()
                                    .clearFilters();
                                builderContext
                                    .read<TargetsCubit>()
                                    .applyFilters();
                              },
                              icon: const Icon(Icons.clear_all, size: 18),
                              label: const Text('Clear All'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(builderContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    // Filter Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Period Type Filter
                            Text(
                              'Filter by Period Type',
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: DropdownButtonFormField<int>(
                                value: state.filterPeriodType,
                                decoration: InputDecoration(
                                  hintText: 'Select period type...',
                                  prefixIcon: Icon(
                                    Icons.calendar_today,
                                    color: AppColors.textSecondary,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<int>(
                                    value: null,
                                    child: Text('All Periods'),
                                  ),
                                  const DropdownMenuItem<int>(
                                    value: 1,
                                    child: Text('Day'),
                                  ),
                                  const DropdownMenuItem<int>(
                                    value: 2,
                                    child: Text('Week'),
                                  ),
                                  const DropdownMenuItem<int>(
                                    value: 3,
                                    child: Text('Month'),
                                  ),
                                  const DropdownMenuItem<int>(
                                    value: 4,
                                    child: Text('Quarter'),
                                  ),
                                  const DropdownMenuItem<int>(
                                    value: 5,
                                    child: Text('Year'),
                                  ),
                                ],
                                onChanged: (value) {
                                  builderContext
                                      .read<TargetsCubit>()
                                      .setFilters(
                                        userId: state.filterUserId,
                                        createdById: state.filterCreatedById,
                                        periodType: value,
                                        startDate: state.filterStartDate,
                                        endDate: state.filterEndDate,
                                      );
                                  builderContext
                                      .read<TargetsCubit>()
                                      .applyFilters();
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Date Range Filter
                            Text(
                              'Filter by Date Range',
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Start Date
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final selectedDate = await showDatePicker(
                                        context: builderContext,
                                        initialDate:
                                            state.filterStartDate ??
                                            DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (selectedDate != null && mounted) {
                                        builderContext
                                            .read<TargetsCubit>()
                                            .setFilters(
                                              userId: state.filterUserId,
                                              createdById:
                                                  state.filterCreatedById,
                                              periodType:
                                                  state.filterPeriodType,
                                              startDate: selectedDate,
                                              endDate: state.filterEndDate,
                                            );
                                        builderContext
                                            .read<TargetsCubit>()
                                            .applyFilters();
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: AppColors.textSecondary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Start Date',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  state.filterStartDate != null
                                                      ? DateFormat(
                                                        'MMM dd, yyyy',
                                                      ).format(
                                                        state.filterStartDate!,
                                                      )
                                                      : 'Select date',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        state.filterStartDate !=
                                                                null
                                                            ? AppColors
                                                                .textPrimary
                                                            : AppColors
                                                                .textSecondary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (state.filterStartDate != null)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                size: 18,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed: () {
                                                builderContext
                                                    .read<TargetsCubit>()
                                                    .setFilters(
                                                      userId:
                                                          state.filterUserId,
                                                      createdById:
                                                          state
                                                              .filterCreatedById,
                                                      periodType:
                                                          state
                                                              .filterPeriodType,
                                                      startDate: null,
                                                      endDate:
                                                          state.filterEndDate,
                                                    );
                                                builderContext
                                                    .read<TargetsCubit>()
                                                    .applyFilters();
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // End Date
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final selectedDate = await showDatePicker(
                                        context: builderContext,
                                        initialDate:
                                            state.filterEndDate ??
                                            (state.filterStartDate ??
                                                DateTime.now()),
                                        firstDate:
                                            state.filterStartDate ??
                                            DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (selectedDate != null && mounted) {
                                        builderContext
                                            .read<TargetsCubit>()
                                            .setFilters(
                                              userId: state.filterUserId,
                                              createdById:
                                                  state.filterCreatedById,
                                              periodType:
                                                  state.filterPeriodType,
                                              startDate: state.filterStartDate,
                                              endDate: selectedDate,
                                            );
                                        builderContext
                                            .read<TargetsCubit>()
                                            .applyFilters();
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.event,
                                            color: AppColors.textSecondary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'End Date',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  state.filterEndDate != null
                                                      ? DateFormat(
                                                        'MMM dd, yyyy',
                                                      ).format(
                                                        state.filterEndDate!,
                                                      )
                                                      : 'Select date',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        state.filterEndDate !=
                                                                null
                                                            ? AppColors
                                                                .textPrimary
                                                            : AppColors
                                                                .textSecondary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (state.filterEndDate != null)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                size: 18,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed: () {
                                                builderContext
                                                    .read<TargetsCubit>()
                                                    .setFilters(
                                                      userId:
                                                          state.filterUserId,
                                                      createdById:
                                                          state
                                                              .filterCreatedById,
                                                      periodType:
                                                          state
                                                              .filterPeriodType,
                                                      startDate:
                                                          state.filterStartDate,
                                                      endDate: null,
                                                    );
                                                builderContext
                                                    .read<TargetsCubit>()
                                                    .applyFilters();
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Apply Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(builderContext).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Apply Filters',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
