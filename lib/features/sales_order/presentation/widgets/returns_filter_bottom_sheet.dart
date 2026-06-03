import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_cubit.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_state.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/deliveries_customer_picker_sheet.dart';

/// Same UX as deliveries filters for GET /api/erp/returns.
class ReturnsFilterBottomSheet extends StatefulWidget {
  const ReturnsFilterBottomSheet({super.key});

  @override
  State<ReturnsFilterBottomSheet> createState() =>
      _ReturnsFilterBottomSheetState();
}

class _ReturnsFilterBottomSheetState extends State<ReturnsFilterBottomSheet> {
  bool _didInitDraft = false;
  String? _draftCustomerCode;
  DateTime? _draftDateFrom;
  DateTime? _draftDateTo;

  int? get _sapCode =>
      context.read<AuthCubit>().state.loginResponse?.user.sapSalesEmployeeCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitDraft) return;
    _didInitDraft = true;
    final s = context.read<SalesOrderCubit>().state;
    _draftCustomerCode = s.returnsFilterCustomerCode;
    _draftDateFrom = s.returnsFilterDateFrom;
    _draftDateTo = s.returnsFilterDateTo;
  }

  String _customerLabel(SalesOrderState s) {
    if (_draftCustomerCode == null || _draftCustomerCode!.isEmpty) {
      return 'All Customers';
    }
    final list = s.customers.where((c) => c.code == _draftCustomerCode).toList();
    if (list.isEmpty) {
      return _draftCustomerCode!;
    }
    final c = list.first;
    return '${c.name ?? c.code} (${c.code})';
  }

  Future<void> _openCustomerPicker() async {
    final code = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: context.read<SalesOrderCubit>(),
        child: BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: DeliveriesCustomerPickerSheet(selectedCode: _draftCustomerCode),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _draftCustomerCode = code);
  }

  Future<void> _apply() async {
    final cubit = context.read<SalesOrderCubit>();
    final sap = _sapCode;
    final code = _draftCustomerCode;
    final from = _draftDateFrom;
    final to = _draftDateTo;
    Navigator.of(context).pop();
    await cubit.applyReturnsFilters(
      salesEmployeeCode: sap,
      customerCode: code,
      dateFrom: from,
      dateTo: to,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: BlocProvider.value(
        value: context.read<SalesOrderCubit>(),
        child: BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: BlocBuilder<SalesOrderCubit, SalesOrderState>(
            builder: (context, state) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  minChildSize: 0.45,
                  maxChildSize: 0.92,
                  expand: false,
                  builder: (sheetContext, scrollController) {
                    return Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Text(
                                'Filters',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              const Spacer(),
                              if (state.hasActiveReturnsFilters)
                                TextButton.icon(
                                  onPressed: () async {
                                    await context
                                        .read<SalesOrderCubit>()
                                        .clearReturnsFilters(
                                          salesEmployeeCode: _sapCode,
                                        );
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  icon: const Icon(Icons.clear_all, size: 18),
                                  label: const Text('Clear All'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Filter by Customer',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Material(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: _openCustomerPicker,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.card,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.business,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _customerLabel(state),
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(
                                            Icons.keyboard_arrow_down,
                                            color: AppColors.textSecondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Filter by Period',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final selected = await showDatePicker(
                                            context: context,
                                            initialDate:
                                                _draftDateFrom ?? DateTime.now(),
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime(2100),
                                          );
                                          if (selected == null || !mounted) {
                                            return;
                                          }
                                          setState(() => _draftDateFrom = selected);
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
                                                      l10n.startDate,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            AppColors.textSecondary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _draftDateFrom != null
                                                          ? DateFormat(
                                                            'MMM dd, yyyy',
                                                          ).format(_draftDateFrom!)
                                                          : l10n.selectDate,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            _draftDateFrom != null
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
                                              if (_draftDateFrom != null)
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.close,
                                                    size: 18,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  onPressed:
                                                      () => setState(
                                                        () => _draftDateFrom = null,
                                                      ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final selected = await showDatePicker(
                                            context: context,
                                            initialDate:
                                                _draftDateTo ??
                                                _draftDateFrom ??
                                                DateTime.now(),
                                            firstDate:
                                                _draftDateFrom ?? DateTime(2020),
                                            lastDate: DateTime(2100),
                                          );
                                          if (selected == null || !mounted) {
                                            return;
                                          }
                                          setState(() => _draftDateTo = selected);
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
                                                      l10n.endDate,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            AppColors.textSecondary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _draftDateTo != null
                                                          ? DateFormat(
                                                            'MMM dd, yyyy',
                                                          ).format(_draftDateTo!)
                                                          : l10n.selectDate,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            _draftDateTo != null
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
                                              if (_draftDateTo != null)
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.close,
                                                    size: 18,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  onPressed:
                                                      () => setState(
                                                        () => _draftDateTo = null,
                                                      ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _apply,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Apply filters',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
