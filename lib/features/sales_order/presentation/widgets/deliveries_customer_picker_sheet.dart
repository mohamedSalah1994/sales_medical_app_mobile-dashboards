import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/core/utils/odbc_card_type_label.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_cubit.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_state.dart';

/// Searchable ERP customer list; returns selected card [code] or `null` for "All Customers".
class DeliveriesCustomerPickerSheet extends StatefulWidget {
  const DeliveriesCustomerPickerSheet({super.key, this.selectedCode});

  final String? selectedCode;

  @override
  State<DeliveriesCustomerPickerSheet> createState() =>
      _DeliveriesCustomerPickerSheetState();
}

class _DeliveriesCustomerPickerSheetState
    extends State<DeliveriesCustomerPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<SalesOrderCubit>();
      if (cubit.state.customers.isEmpty && !cubit.state.isLoadingCustomers) {
        final sap =
            context.read<AuthCubit>().state.loginResponse?.user.sapSalesEmployeeCode;
        cubit.loadCustomers(salesEmployeeCode: sap);
      }
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      final sap =
          context.read<AuthCubit>().state.loginResponse?.user.sapSalesEmployeeCode;
      context.read<SalesOrderCubit>().loadCustomers(
        salesEmployeeCode: sap,
        search:
            _searchController.text.trim().isEmpty
                ? null
                : _searchController.text.trim(),
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
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
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Select customer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or code',
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<SalesOrderCubit, SalesOrderState>(
                  buildWhen: (p, c) =>
                      p.customers != c.customers ||
                      p.isLoadingCustomers != c.isLoadingCustomers ||
                      p.isLoadingMoreCustomers != c.isLoadingMoreCustomers ||
                      p.customersHasMore != c.customersHasMore ||
                      p.customersError != c.customersError,
                  builder: (context, state) {
                    if (state.isLoadingCustomers && state.customers.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      );
                    }
                    final sap =
                        context.read<AuthCubit>().state.loginResponse?.user.sapSalesEmployeeCode;
                    final footer = state.customersHasMore ? 1 : 0;
                    return NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.extentAfter > 160) return false;
                        final cubit = context.read<SalesOrderCubit>();
                        final st = cubit.state;
                        if (!st.customersHasMore ||
                            st.isLoadingMoreCustomers ||
                            st.isLoadingCustomers) {
                          return false;
                        }
                        cubit.loadCustomers(
                          salesEmployeeCode: sap,
                          search:
                              _searchController.text.trim().isEmpty
                                  ? null
                                  : _searchController.text.trim(),
                          append: true,
                        );
                        return false;
                      },
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.layers_outlined,
                              color:
                                  widget.selectedCode == null
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                            ),
                            title: const Text('All Customers'),
                            selected: widget.selectedCode == null,
                            onTap: () => Navigator.of(context).pop<String?>(null),
                          ),
                          const Divider(height: 1),
                          ...state.customers.map(
                            (c) {
                              final selected = widget.selectedCode == c.code;
                              final primary = (c.name?.trim().isNotEmpty == true
                                      ? c.name!.trim()
                                      : c.code)
                                  .trim();
                              final foreign = c.foreignName?.trim() ?? '';
                              final showForeign =
                                  foreign.isNotEmpty && foreign != primary;
                              final kind = odbcCardTypeKindLabel(c.cardType);
                              final showKind = kind.isNotEmpty;
                              return ListTile(
                                leading: Icon(
                                  Icons.business,
                                  color:
                                      selected
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                ),
                                title: Text(
                                  '$primary (${c.code})',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle:
                                    (showKind || showForeign)
                                        ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (showKind)
                                              Text(
                                                kind,
                                                maxLines: 1,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.9),
                                                ),
                                              ),
                                            if (showForeign)
                                              Text(
                                                foreign,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                          ],
                                        )
                                        : null,
                                isThreeLine: showForeign || showKind,
                                selected: selected,
                                onTap: () => Navigator.of(context).pop<String?>(c.code),
                              );
                            },
                          ),
                          if (footer == 1)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child:
                                    state.isLoadingMoreCustomers
                                        ? const SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary,
                                          ),
                                        )
                                        : const SizedBox.shrink(),
                              ),
                            ),
                          if (state.customersError != null)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                state.customersError!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
