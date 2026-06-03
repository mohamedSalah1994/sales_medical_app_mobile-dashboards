import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/di/service_locator.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/reports/data/models/target_achievement_model.dart';
import 'package:sales_medical_app_mobile/features/reports/presentation/cubit/target_achievement_cubit.dart';
import 'package:sales_medical_app_mobile/features/reports/presentation/widgets/achievement_items_table.dart';
import 'package:sales_medical_app_mobile/features/reports/presentation/widgets/achievement_kpi_row.dart';
import 'package:sales_medical_app_mobile/features/reports/presentation/widgets/team_performance_table.dart';
import 'package:sales_medical_app_mobile/features/reports/presentation/widgets/visit_kpi_row.dart';

class TargetAchievementPage extends StatelessWidget {
  const TargetAchievementPage({super.key, this.filterEmployee});

  final TargetAchievementEmployeeModel? filterEmployee;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TargetAchievementCubit>(
      create: (_) => sl<TargetAchievementCubit>(),
      child: _TargetAchievementView(filterEmployee: filterEmployee),
    );
  }
}

class _TargetAchievementView extends StatefulWidget {
  const _TargetAchievementView({this.filterEmployee});

  final TargetAchievementEmployeeModel? filterEmployee;

  @override
  State<_TargetAchievementView> createState() => _TargetAchievementViewState();
}

class _TargetAchievementViewState extends State<_TargetAchievementView> {
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadReport();
    });
  }

  String get _role {
    return context
            .read<AuthCubit>()
            .state
            .loginResponse
            ?.user
            .role
            .toLowerCase() ??
        'salesrep';
  }

  String get _userId {
    return context.read<AuthCubit>().state.loginResponse?.user.id ?? '';
  }

  void _loadReport() {
    final cubit = context.read<TargetAchievementCubit>();
    cubit.loadReport(
      userId: _userId,
      role: _role,
      filterEmployeeId: widget.filterEmployee?.userId,
    );
  }

  void _applyFilters(DateTime start, DateTime end, String? employeeId, String? employeeName) {
    final cubit = context.read<TargetAchievementCubit>();
    cubit.applyFiltersBatch(
      start: start,
      end: end,
      employeeId: employeeId,
      employeeName: employeeName,
    );
    cubit.loadReport(
      userId: _userId,
      role: _role,
      filterEmployeeId: employeeId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSalesRep = _role == 'salesrep';
    final isDrillDown = widget.filterEmployee != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDrillDown
                  ? widget.filterEmployee!.fullName
                  : 'Target Achievement',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (isDrillDown)
              const Text(
                'Sales employee view',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              )
            else if (!isSalesRep)
              const Text(
                'Supervisor view',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
          ],
        ),
        leading: Navigator.of(context).canPop()
            ? const BackButton(color: AppColors.textPrimary)
            : null,
        actions: [
          BlocBuilder<TargetAchievementCubit, TargetAchievementState>(
            builder: (context, state) {
              return TextButton.icon(
                onPressed: () => _showFilterSheet(context, state),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(
                  '${_fmtDate(state.startDate)} – ${_fmtDate(state.endDate)}',
                  style: const TextStyle(fontSize: 11),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<TargetAchievementCubit, TargetAchievementState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null && state.report == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loadReport,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state.report == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final report = state.report!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!report.hasTarget)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.warning,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'No target set for this period',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                AchievementKpiRow(
                  label: 'Quantity',
                  target: report.summary.targetQuantity,
                  actual: report.summary.actualQuantity,
                  pct: report.summary.quantityAchievementPct,
                ),
                AchievementKpiRow(
                  label: 'Value',
                  target: report.summary.targetValue,
                  actual: report.summary.actualValue,
                  pct: report.summary.valueAchievementPct,
                  isValue: true,
                ),
                VisitKpiRow(
                  planned: report.summary.plannedVisits,
                  actual: report.summary.actualVisits,
                  pct: report.summary.visitAchievementPct,
                  missed: report.summary.missedVisits,
                ),
                const SizedBox(height: 8),
                if (report.employees.isNotEmpty && !isDrillDown)
                  TeamPerformanceTable(
                    employees: report.employees,
                    onTap: (emp) => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TargetAchievementPage(
                          filterEmployee: emp,
                        ),
                      ),
                    ),
                  ),
                if (report.items.isNotEmpty)
                  AchievementItemsTable(items: report.items),
              ],
            ),
          );
        },
      ),
    );
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    return DateFormat('dd/MM').format(d);
  }

  Future<void> _showFilterSheet(
    BuildContext context,
    TargetAchievementState state,
  ) async {
    final result = await showModalBottomSheet<({
      DateTime start,
      DateTime end,
      String? employeeId,
      String? employeeName
    })>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        initialStart: state.startDate,
        initialEnd: state.endDate,
        isSupervisor: _role == 'supervisor' && widget.filterEmployee == null,
        selectedEmployeeId: state.selectedEmployeeId,
        selectedEmployeeName: state.selectedEmployeeName,
      ),
    );
    if (result != null && mounted) {
      _applyFilters(
        result.start,
        result.end,
        result.employeeId,
        result.employeeName,
      );
    }
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    this.initialStart,
    this.initialEnd,
    this.isSupervisor = false,
    this.selectedEmployeeId,
    this.selectedEmployeeName,
  });

  final DateTime? initialStart;
  final DateTime? initialEnd;
  final bool isSupervisor;
  final String? selectedEmployeeId;
  final String? selectedEmployeeName;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = widget.initialStart ?? DateTime(now.year, now.month, 1);
    _end = widget.initialEnd ?? now;
  }

  Future<void> _pickDate({
    required bool isStart,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = DateTime(picked.year, picked.month, picked.day);
        } else {
          _end = DateTime(picked.year, picked.month, picked.day);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
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
          const SizedBox(height: 16),
          const Text(
            'Filter Period',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DateTile(
                  label: 'Start date',
                  date: _start,
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateTile(
                  label: 'End date',
                  date: _end,
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final now = DateTime.now();
                    Navigator.of(context).pop((
                      start: DateTime(now.year, now.month, 1),
                      end: now,
                      employeeId: null,
                      employeeName: null,
                    ));
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop((
                      start: _start,
                      end: _end,
                      employeeId: widget.selectedEmployeeId,
                      employeeName: widget.selectedEmployeeName,
                    ));
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy').format(date),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
