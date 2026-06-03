import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/targets/domain/entities/target.dart';
import 'package:sales_medical_app_mobile/features/targets/presentation/cubit/targets_cubit.dart';
import 'package:sales_medical_app_mobile/features/targets/presentation/cubit/targets_state.dart';
import 'package:sales_medical_app_mobile/features/targets/presentation/pages/target_detail_page.dart';

class TargetsPage extends StatefulWidget {
  const TargetsPage({super.key, this.showScaffold = false});

  final bool showScaffold;

  @override
  State<TargetsPage> createState() => _TargetsPageState();
}

class _TargetsPageState extends State<TargetsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<TargetsCubit>();
    final authState = context.read<AuthCubit>().state;
    final user = authState.loginResponse?.user;
    final isSalesRep = user?.role.toLowerCase() == 'salesrep';

    // For SalesRep, always use tab index 0 (My Targets) and set tab length to 1
    final initialTabIndex = isSalesRep ? 0 : cubit.state.selectedTabIndex;
    final tabLength = isSalesRep ? 1 : 2;

    // Ensure cubit state is set to tab 0 for SalesRep
    if (isSalesRep && cubit.state.selectedTabIndex != 0) {
      cubit.setSelectedTab(0);
    }

    _tabController = TabController(
      length: tabLength,
      initialIndex: initialTabIndex,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);

    // Load targets when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!cubit.state.isLoadingTargets) {
        _loadTargetsForCurrentTab();
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
      final cubit = context.read<TargetsCubit>();
      final previousIndex = cubit.state.selectedTabIndex;
      cubit.setSelectedTab(_tabController.index);
      // Only reload if tab actually changed
      if (previousIndex != _tabController.index) {
        _loadTargetsForCurrentTab();
      }
    }
  }

  void _loadTargetsForCurrentTab() {
    final authState = context.read<AuthCubit>().state;
    final userId = authState.loginResponse?.user.id;

    if (userId == null) return;

    final cubit = context.read<TargetsCubit>();
    final state = cubit.state;

    if (state.selectedTabIndex == 0) {
      // My Targets - own targets (filter by assignee = me)
      cubit.loadTargets(userId: userId);
    } else {
      // Target list - subordinates' targets (targets I created for my team)
      cubit.loadTargets(createdById: userId);
    }
  }

  void _showFilterDialog(BuildContext context, TargetsState state) {
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

  Future<void> _onRefresh() async {
    _loadTargetsForCurrentTab();
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Widget _buildTargetsList(TargetsState state) {
    if (state.isLoadingTargets && state.targets.isEmpty) {
      return _wrapWithRefresh(const Center(child: CircularProgressIndicator()));
    } else if (state.targetsErrorMessage != null) {
      return _wrapWithRefresh(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  state.targetsErrorMessage!,
                  style: TextStyle(color: AppColors.error, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    } else if (state.targets.isEmpty) {
      return _wrapWithRefresh(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.track_changes,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No targets found',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(10),
          itemCount: state.targets.length,
          itemBuilder: (context, index) {
            final target = state.targets[index];
            return _TargetCard(target: target);
          },
        ),
      );
    }
  }

  Widget _wrapWithRefresh(Widget child) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<AuthCubit, AuthState>(
      listenWhen:
          (prev, curr) =>
              prev.loginResponse?.user.id != curr.loginResponse?.user.id,
      listener: (context, authState) {
        final userId = authState.loginResponse?.user.id;
        if (userId != null) {
          _loadTargetsForCurrentTab();
        }
      },
      child: BlocBuilder<TargetsCubit, TargetsState>(
        builder: (context, state) {
          // Check if user is SalesRep
          final authState = context.read<AuthCubit>().state;
          final user = authState.loginResponse?.user;
          final isSalesRep = user?.role.toLowerCase() == 'salesrep';

          // Build the content
          final content = Column(
            children: [
              // Tabs (hidden for SalesRep)
              if (!isSalesRep)
                BlocListener<TargetsCubit, TargetsState>(
                  listenWhen:
                      (prev, curr) =>
                          prev.selectedTabIndex != curr.selectedTabIndex,
                  listener: (context, state) {
                    if (_tabController.index != state.selectedTabIndex) {
                      _tabController.animateTo(state.selectedTabIndex);
                    }
                  },
                  child: Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                      tabs: [
                        Tab(text: l10n.myTargets),
                        Tab(text: l10n.targetsList),
                      ],
                    ),
                  ),
                ),
              // Targets List
              Expanded(child: _buildTargetsList(state)),
            ],
          );

          // If showScaffold is false, return just the content (for use in HomeContent)
          if (!widget.showScaffold) {
            return content;
          }

          // Otherwise, wrap in Scaffold with AppBar (standalone use)
          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppBar(
              title: Text(
                'Targets',
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
                        _showFilterDialog(context, state);
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
          );
        },
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.target});

  final Target target;

  String _getPeriodTypeName(int periodType) {
    switch (periodType) {
      case 1:
        return 'Day';
      case 2:
        return 'Week';
      case 3:
        return 'Month';
      case 4:
        return 'Quarter';
      case 5:
        return 'Year';
      default:
        return 'Unknown';
    }
  }

  IconData _getPeriodTypeIcon(int periodType) {
    switch (periodType) {
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

  void _onTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => TargetDetailPage(target: target)),
    );
  }

  bool get _isActive {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
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
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = AppColors.primary;
    final statusColor = _isActive ? AppColors.success : AppColors.textSecondary;
    final statusText = _isActive ? 'Active' : 'InActive';

    return InkWell(
      onTap: () => _onTap(context),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: progressColor.withValues(alpha: 0.3),
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
                progressColor.withValues(alpha: 0.05),
                progressColor.withValues(alpha: 0.02),
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: progressColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getPeriodTypeIcon(target.periodType),
                        color: progressColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (target.userName.isNotEmpty)
                            Text(
                              target.userName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Status Badge (Active/InActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isActive
                                ? Icons.check_circle
                                : Icons.cancel_outlined,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Period Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: progressColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: progressColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.track_changes,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getPeriodTypeName(target.periodType),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Divider
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        progressColor.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Date Range
                Row(
                  children: [
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.calendar_today_outlined,
                        label: 'Start Date',
                        value: DateFormat(
                          'MMM dd, yyyy',
                        ).format(target.startDate),
                        iconColor: progressColor,
                      ),
                    ),
                    Container(width: 1, height: 30, color: AppColors.border),
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.event_outlined,
                        label: 'End Date',
                        value: DateFormat(
                          'MMM dd, yyyy',
                        ).format(target.endDate),
                        iconColor: progressColor,
                      ),
                    ),
                  ],
                ),
                if (target.breakdowns.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: progressColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: progressColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.list,
                            color: progressColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${target.breakdowns.length} ${target.breakdowns.length == 1 ? 'Breakdown' : 'Breakdowns'}',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor ?? AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
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
  final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
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
