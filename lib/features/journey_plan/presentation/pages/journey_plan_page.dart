import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/di/service_locator.dart';
import 'package:sales_medical_app_mobile/core/network/api_service.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/core/utils/odbc_card_type_label.dart';
import 'package:sales_medical_app_mobile/core/utils/odbc_state_filter_options.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_state.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/widgets/step1_create_plan.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/widgets/step2_create_stops.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/widgets/journey_plans_list_widget.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/widgets/visits_list_widget.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/widgets/step_indicator_widget.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';

class JourneyPlanPage extends StatefulWidget {
  const JourneyPlanPage({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  State<JourneyPlanPage> createState() => _JourneyPlanPageState();
}

class _JourneyPlanPageState extends State<JourneyPlanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<JourneyPlanCubit>();
    final authState = context.read<AuthCubit>().state;
    final user = authState.loginResponse?.user;
    final isSalesRep = user?.role.toLowerCase() == 'salesrep';
    final isManager =
        user?.role.toLowerCase().trim() == 'manager' ||
        user?.role.toLowerCase().trim() == 'admin';

    // For SalesRep and Manager, always use tab index 0 and set tab length to 1
    final initialTabIndex =
        (isSalesRep || isManager) ? 0 : cubit.state.selectedTabIndex;
    final tabLength = (isSalesRep || isManager) ? 1 : 2;

    // Ensure cubit state is set to tab 0 for SalesRep and Manager
    if ((isSalesRep || isManager) && cubit.state.selectedTabIndex != 0) {
      cubit.setSelectedTab(0);
    }

    _tabController = TabController(
      length: tabLength,
      initialIndex: initialTabIndex,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);

    // Load data when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = cubit.state;
      final authState = context.read<AuthCubit>().state;
      final user = authState.loginResponse?.user;
      final isSupervisor = user?.role.toLowerCase() == 'supervisor';
      final isAdmin = user?.role.toLowerCase().trim() == 'admin';

      cubit.setLoggedInUserId(user?.id);

      if (isAdmin) {
        // For Admin: load supervisors first, don't load journey plans yet
        if (state.supervisors.isEmpty && !state.isLoadingSupervisors) {
          cubit.loadSupervisors();
        }
      } else if (isSupervisor && state.selectedTabIndex == 0) {
        // For supervisors, load visits if on tab 0
        if (!state.isLoadingVisits) {
          _loadJourneyPlansForCurrentTab();
        }
      } else {
        // Always load when page opens (if not already loading)
        if (!state.isLoadingJourneyPlans) {
          _loadJourneyPlansForCurrentTab();
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final cubit = context.read<JourneyPlanCubit>();
      final previousIndex = cubit.state.selectedTabIndex;
      cubit.setSelectedTab(_tabController.index);
      // Only reload if tab actually changed
      if (previousIndex != _tabController.index) {
        _loadJourneyPlansForCurrentTab();
      }
    }
  }

  void _loadJourneyPlansForCurrentTab() {
    final authState = context.read<AuthCubit>().state;
    final userId = authState.loginResponse?.user.id;
    final user = authState.loginResponse?.user;
    final isSalesRep = user?.role.toLowerCase() == 'salesrep';
    final isSupervisor = user?.role.toLowerCase() == 'supervisor';
    final isManager =
        user?.role.toLowerCase().trim() == 'manager' ||
        user?.role.toLowerCase().trim() == 'admin';

    if (userId == null) return;

    final cubit = context.read<JourneyPlanCubit>();
    final state = cubit.state;

    // For Admin: load JPs once a supervisor is selected
    if (user?.role.toLowerCase().trim() == 'admin') {
      if (state.filterSupervisorId != null) {
        if (state.filterUserId != null) {
          // Specific sales employee selected → load their JPs
          cubit.loadJourneyPlans(
            userId: state.filterUserId,
            customerId: state.filterCustomerId,
          );
        } else {
          // No sales employee selected → load ALL JPs under supervisor
          cubit.loadJourneyPlans(
            supervisorId: state.filterSupervisorId,
            customerId: state.filterCustomerId,
          );
        }
      }
      return;
    }
    // For Manager, load subordinate journey plans using supervisorId
    if (isManager) {
      final filterSupervisorId = state.filterSupervisorId ?? userId;
      cubit.loadJourneyPlans(
        supervisorId: filterSupervisorId,
        customerId: state.filterCustomerId,
      );
    }
    // For Supervisor, load visits in tab 0
    else if (isSupervisor && state.selectedTabIndex == 0) {
      // My Visits - use supervisorId, filter by status from state (defaults to 1 = Planned)
      cubit.loadVisits(supervisorId: userId, status: state.visitStatusFilter);
    } else if (isSalesRep || state.selectedTabIndex == 0) {
      // My Journeys - use userId
      cubit.loadJourneyPlans(
        userId: userId,
        customerId: state.filterCustomerId,
      );
    } else {
      // Assigned Journeys - use createdById
      cubit.loadJourneyPlans(
        createdById: userId,
        customerId: state.filterCustomerId,
      );
    }
  }

  Future<void> _onRefresh() async {
    _loadJourneyPlansForCurrentTab();
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<JourneyPlanCubit>(),
      child: _JourneyPlanView(
        tabController: _tabController,
        showScaffold: widget.showScaffold,
        onRefresh: _onRefresh,
      ),
    );
  }
}

class _JourneyPlanView extends StatelessWidget {
  const _JourneyPlanView({
    required this.tabController,
    required this.showScaffold,
    this.onRefresh,
  });

  final TabController tabController;
  final bool showScaffold;
  final Future<void> Function()? onRefresh;

  void _showFilterDialog(
    BuildContext context,
    JourneyPlanState state,
    List<MapEntry<String, String>> userList,
  ) {
    final cubit = context.read<JourneyPlanCubit>();
    final authState = context.read<AuthCubit>().state;
    final user = authState.loginResponse?.user;
    final isAdmin = user?.role.toLowerCase().trim() == 'admin';

    // Load supervisors for admin if not already loaded
    if (isAdmin && state.supervisors.isEmpty && !state.isLoadingSupervisors) {
      cubit.loadSupervisors();
    }

    final authCubit = context.read<AuthCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (dialogContext) => BlocProvider.value(
            value: cubit,
            child: BlocProvider.value(
              value: authCubit,
              child: _FilterBottomSheet(state: state, userList: userList),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JourneyPlanCubit, JourneyPlanState>(
      listenWhen:
          (prev, curr) =>
              prev.showCreateForm != curr.showCreateForm && curr.showCreateForm,
      listener: (listenerContext, state) {
        // If showScaffold is false and showCreateForm becomes true, navigate
        if (!showScaffold && state.showCreateForm) {
          // Capture the cubit from the listener context before navigating
          final cubit = listenerContext.read<JourneyPlanCubit>();
          Future.microtask(() {
            if (listenerContext.mounted) {
              Navigator.of(listenerContext).push(
                MaterialPageRoute(
                  builder:
                      (routeContext) => BlocProvider.value(
                        value: cubit,
                        child: const JourneyPlanPage(showScaffold: true),
                      ),
                  fullscreenDialog: false,
                ),
              );
            }
          });
        }
      },
      child: BlocListener<JourneyPlanCubit, JourneyPlanState>(
        listenWhen: (prev, curr) => prev.isSyncing && !curr.isSyncing,
        listener: (context, state) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Data synced successfully'),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
          builder: (context, state) {
            // Show create form if showCreateForm is true
            if (state.showCreateForm) {
              // If showScaffold is false, show loading while navigating
              if (!showScaffold) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // If showScaffold is true, show the Scaffold directly
              return WillPopScope(
                onWillPop: () async {
                  context.read<JourneyPlanCubit>().hideCreateForm();
                  return true;
                },
                child: Scaffold(
                  backgroundColor: AppColors.surface,
                  appBar: AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        context.read<JourneyPlanCubit>().hideCreateForm();
                        // If we navigated here, pop the route
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    title: Text(
                      state.isViewOnly
                          ? 'View Journey Plan'
                          : (state.isEditing
                              ? 'Edit Journey Plan'
                              : 'Create Journey Plan'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  body: Column(
                    children: [
                      // Step Indicator
                      const StepIndicatorWidget(),
                      // Content
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.1, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOut,
                                ),
                              ),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child:
                              state.currentStep == 1
                                  ? const Step1CreatePlan(
                                    key: ValueKey('step1'),
                                  )
                                  : const Step2CreateStops(
                                    key: ValueKey('step2'),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Extract unique users from journey plans
            final uniqueUsers = <String, String>{};
            for (final plan in state.journeyPlans) {
              if (plan.userId.isNotEmpty && plan.userName.isNotEmpty) {
                uniqueUsers[plan.userId] = plan.userName;
              }
            }
            final userList = uniqueUsers.entries.toList();

            // Check if user is SalesRep, Supervisor, Manager, or Admin
            final authState = context.read<AuthCubit>().state;
            final user = authState.loginResponse?.user;
            final isSalesRep = user?.role.toLowerCase() == 'salesrep';
            final isSupervisor = user?.role.toLowerCase() == 'supervisor';
            final isManager =
                user?.role.toLowerCase() == 'manager' ||
                user?.role.toLowerCase() == 'admin';

            // Build the content
            final content = Column(
              children: [
                // Tabs (hidden for SalesRep and Manager/Admin - they only have 1 tab)
                if (!isSalesRep && !isManager)
                  BlocListener<JourneyPlanCubit, JourneyPlanState>(
                    listenWhen:
                        (prev, curr) =>
                            prev.selectedTabIndex != curr.selectedTabIndex,
                    listener: (context, state) {
                      if (tabController.index != state.selectedTabIndex) {
                        tabController.animateTo(state.selectedTabIndex);
                      }
                    },
                    child: Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                        tabs: [
                          Tab(
                            text:
                                isSupervisor
                                    ? AppLocalizations.of(
                                      context,
                                    )!.myJourneyPlans
                                    : AppLocalizations.of(
                                      context,
                                    )!.myJourneyPlans,
                          ),
                          Tab(
                            text:
                                AppLocalizations.of(context)!.journeyPlansList,
                          ),
                        ],
                      ),
                    ),
                  ),
                // Data syncing banner (when back online and syncing pending actions)
                if (state.isSyncing)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: AppColors.primary.withValues(alpha: 0.12),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Data syncing…',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Offline / pending sync banner (when not syncing)
                if (!state.isSyncing &&
                    (state.isOffline || state.pendingSyncCount > 0))
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color:
                        state.pendingSyncCount > 0
                            ? AppColors.warning.withValues(alpha: 0.15)
                            : AppColors.textSecondary.withValues(alpha: 0.15),
                    child: Row(
                      children: [
                        Icon(
                          state.isOffline ? Icons.cloud_off : Icons.sync,
                          size: 18,
                          color:
                              state.pendingSyncCount > 0
                                  ? AppColors.warning
                                  : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.isOffline
                                ? 'Offline — showing cached data. Visit actions will sync when back online.'
                                : '${state.pendingSyncCount} action(s) will sync when online.',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  state.pendingSyncCount > 0
                                      ? AppColors.warning
                                      : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Journey Plans List or Visits List (for supervisors)
                Expanded(
                  child:
                      isSupervisor && state.selectedTabIndex == 0
                          ? VisitsListWidget(state: state, onRefresh: onRefresh)
                          : JourneyPlansListWidget(
                            state: state,
                            onRefresh: onRefresh,
                          ),
                ),
              ],
            );

            // If showScaffold is false, return just the content (for use in HomeContent)
            if (!showScaffold) {
              return content;
            }

            // Otherwise, wrap in Scaffold with AppBar (standalone use)
            return Scaffold(
              backgroundColor: AppColors.surface,
              appBar: AppBar(
                title: Text(
                  'Journey Plans',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                backgroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                actions: [
                  // Filter Icon Button
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.filter_list,
                          color:
                              state.hasActiveFilters
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                        ),
                        onPressed: () {
                          _showFilterDialog(context, state, userList);
                        },
                        tooltip: 'Filters',
                      ),
                      if (state.hasActiveFilters)
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
                  ),
                ],
              ),
              body: content,
              floatingActionButton:
                  !isManager
                      ? FloatingActionButton.extended(
                        onPressed:
                            state.isOffline
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
                            state.isOffline
                                ? 'Create journey plan requires an internet connection'
                                : null,
                      )
                      : null,
            );
          },
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet({required this.state, required this.userList});

  final JourneyPlanState state;
  final List<MapEntry<String, String>> userList;

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  final TextEditingController _customerSearchController =
      TextEditingController();
  Timer? _customerSearchDebounce;
  String? _selectedCustomerStateCode;
  List<OdbcStateFilterOption> _customerStateOptions = const [];

  void _onCustomerSearchChanged(String value) {
    _customerSearchDebounce?.cancel();
    _customerSearchDebounce = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      context.read<JourneyPlanCubit>().loadCustomers(
        search: value.trim().isEmpty ? null : value.trim(),
        stateFilter: _selectedCustomerStateCode,
      );
    });
  }

  Future<void> _loadCustomerStateOptions() async {
    final options = await loadOdbcStateFilterOptions(sl<ApiService>());
    if (!mounted) return;
    setState(() {
      _customerStateOptions = options;
    });
  }

  @override
  void initState() {
    super.initState();
    _customerSearchController.addListener(() {
      _onCustomerSearchChanged(_customerSearchController.text);
    });

    // Load supervisors for admin when filter dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authState = context.read<AuthCubit>().state;
        final user = authState.loginResponse?.user;
        final isAdmin = user?.role.toLowerCase().trim() == 'admin';
        final cubit = context.read<JourneyPlanCubit>();
        final state = cubit.state;

        if (isAdmin &&
            state.supervisors.isEmpty &&
            !state.isLoadingSupervisors) {
          cubit.loadSupervisors();
        }

        if (state.customers.isEmpty && !state.isLoadingCustomers) {
          cubit.loadCustomers(
            stateFilter: _selectedCustomerStateCode,
          );
        }
      }
    });
    unawaited(_loadCustomerStateOptions());
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
        child: BlocProvider.value(
          value: context.read<AuthCubit>(),
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
                                  final cubit =
                                      builderContext.read<JourneyPlanCubit>();
                                  final authState =
                                      builderContext.read<AuthCubit>().state;
                                  final isAdmin =
                                      authState.loginResponse?.user.role
                                          .toLowerCase()
                                          .trim() ==
                                      'admin';
                                  if (isAdmin) {
                                    cubit.clearSupervisorSelection();
                                    Navigator.of(builderContext).pop();
                                  } else {
                                    setState(() {
                                      _selectedCustomerStateCode = null;
                                      _customerSearchController.clear();
                                    });
                                    cubit.clearFilters();
                                    cubit.loadCustomers();
                                    cubit.applyFilters();
                                  }
                                },
                                icon: const Icon(Icons.clear_all, size: 18),
                                label: Text(
                                  AppLocalizations.of(context)!.clearAll,
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed:
                                  () => Navigator.of(builderContext).pop(),
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
                              // User / Sales employee Filter
                              if (builderContext
                                      .read<AuthCubit>()
                                      .state
                                      .loginResponse
                                      ?.user
                                      .role
                                      .toLowerCase()
                                      .trim() ==
                                  'admin')
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    state.filterSupervisorId != null
                                        ? () {
                                          final sup =
                                              state.supervisors
                                                  .where(
                                                    (s) =>
                                                        s.id ==
                                                        state
                                                            .filterSupervisorId,
                                                  )
                                                  .toList();
                                          return 'Sales Employees of ${sup.isEmpty ? 'Supervisor' : sup.first.fullName}';
                                        }()
                                        : 'Sales Employees of selected supervisor',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
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
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: state.filterUserId,
                                  decoration: InputDecoration(
                                    hintText:
                                        AppLocalizations.of(
                                          context,
                                        )!.selectUserHint,
                                    prefixIcon: Icon(
                                      Icons.person,
                                      color: AppColors.textSecondary,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: null,
                                      child: Text(
                                        AppLocalizations.of(context)!.allUsers,
                                      ),
                                    ),
                                    ...widget.userList.map(
                                      (user) => DropdownMenuItem<String>(
                                        value: user.key,
                                        child: Text(user.value),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    builderContext
                                        .read<JourneyPlanCubit>()
                                        .setFilters(
                                          userId: value,
                                          supervisorId:
                                              state.filterSupervisorId,
                                          customerId: state.filterCustomerId,
                                          startDate: state.filterStartDate,
                                          endDate: state.filterEndDate,
                                        );
                                    builderContext
                                        .read<JourneyPlanCubit>()
                                        .applyFilters();
                                  },
                                ),
                              ),
                              // Supervisor Filter removed - Admin uses 3-level card navigation
                              const SizedBox(height: 24),
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
                                        _customerSearchController
                                                .text
                                                .isNotEmpty
                                            ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                _customerSearchController
                                                    .clear();
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
                              if (_customerStateOptions.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: DropdownButtonFormField<String?>(
                                    value: _selectedCustomerStateCode,
                                    decoration: InputDecoration(
                                      hintText: 'All states',
                                      prefixIcon: Icon(
                                        Icons.map_outlined,
                                        color: AppColors.textSecondary,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                    ),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('All states'),
                                      ),
                                      ..._customerStateOptions.map(
                                        (s) => DropdownMenuItem<String?>(
                                          value: s.code,
                                          child: Text(s.name),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCustomerStateCode = value;
                                      });
                                      builderContext
                                          .read<JourneyPlanCubit>()
                                          .loadCustomers(
                                            search:
                                                _customerSearchController
                                                        .text
                                                        .trim()
                                                        .isEmpty
                                                    ? null
                                                    : _customerSearchController
                                                        .text
                                                        .trim(),
                                            stateFilter:
                                                _selectedCustomerStateCode,
                                          );
                                    },
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Builder(
                                builder: (_) {
                                  final selectedExists =
                                      state.filterCustomerId == null ||
                                      state.customers.any(
                                        (customer) =>
                                            customer.id ==
                                            state.filterCustomerId,
                                      );

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.card,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
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
                                          (
                                            customer,
                                          ) => DropdownMenuItem<String?>(
                                            value: customer.id,
                                            child: Text(
                                              () {
                                                final kind =
                                                    odbcCardTypeKindLabel(
                                                      customer.cardType,
                                                    );
                                                return kind.isEmpty
                                                    ? customer
                                                        .displayLabelWithCode
                                                    : '${customer.displayLabelWithCode} · $kind';
                                              }(),
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
                                                      userId:
                                                          state.filterUserId,
                                                      supervisorId:
                                                          state
                                                              .filterSupervisorId,
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
                                        final selectedDate =
                                            await showDatePicker(
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
                                                supervisorId:
                                                    state.filterSupervisorId,
                                                customerId:
                                                    state.filterCustomerId,
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.startDate,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          AppColors
                                                              .textSecondary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    state.filterStartDate !=
                                                            null
                                                        ? DateFormat(
                                                          'MMM dd, yyyy',
                                                        ).format(
                                                          state
                                                              .filterStartDate!,
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
                                                      fontWeight:
                                                          FontWeight.w500,
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
                                                        supervisorId:
                                                            state
                                                                .filterSupervisorId,
                                                        customerId:
                                                            state
                                                                .filterCustomerId,
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
                                        final selectedDate =
                                            await showDatePicker(
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
                                                supervisorId:
                                                    state.filterSupervisorId,
                                                customerId:
                                                    state.filterCustomerId,
                                                startDate:
                                                    state.filterStartDate,
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.endDate,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          AppColors
                                                              .textSecondary,
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
                                                      fontWeight:
                                                          FontWeight.w500,
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
                                                        supervisorId:
                                                            state
                                                                .filterSupervisorId,
                                                        customerId:
                                                            state
                                                                .filterCustomerId,
                                                        startDate:
                                                            state
                                                                .filterStartDate,
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
      ),
    );
  }
}

