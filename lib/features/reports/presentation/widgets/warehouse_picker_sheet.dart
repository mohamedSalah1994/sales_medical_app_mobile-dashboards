import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/reports/domain/entities/erp_warehouse.dart';
import 'package:sales_medical_app_mobile/features/reports/presentation/cubit/stock_availability_cubit.dart';
import 'package:sales_medical_app_mobile/features/reports/presentation/cubit/stock_availability_state.dart';

/// Bottom-sheet warehouse picker for admin / supervisor users.
///
/// Loads /api/Erp/warehouses paginated (20 per page) and supports server
/// search + scroll pagination. Returns the selected [ErpWarehouse] (or null
/// if the user dismisses the sheet).
Future<ErpWarehouse?> showWarehousePickerSheet(
  BuildContext context, {
  required StockAvailabilityCubit cubit,
}) {
  return showModalBottomSheet<ErpWarehouse>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => BlocProvider.value(
      value: cubit,
      child: const _WarehousePickerSheet(),
    ),
  );
}

class _WarehousePickerSheet extends StatefulWidget {
  const _WarehousePickerSheet();

  @override
  State<_WarehousePickerSheet> createState() => _WarehousePickerSheetState();
}

class _WarehousePickerSheetState extends State<_WarehousePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StockAvailabilityCubit>().loadWarehouses();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (!pos.hasViewportDimension || !pos.hasContentDimensions) return;
    if (pos.pixels >= pos.maxScrollExtent - 120) {
      context.read<StockAvailabilityCubit>().loadMoreWarehouses();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<StockAvailabilityCubit>().loadWarehouses(search: value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (sheetContext, draggableController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
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
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select warehouse',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by name or code…',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: BlocBuilder<StockAvailabilityCubit,
                    StockAvailabilityState>(
                  buildWhen: (p, c) =>
                      p.warehouses != c.warehouses ||
                      p.isLoadingWarehouses != c.isLoadingWarehouses ||
                      p.isLoadingMoreWarehouses != c.isLoadingMoreWarehouses ||
                      p.warehousesError != c.warehousesError ||
                      p.warehousesHasMore != c.warehousesHasMore,
                  builder: (context, state) {
                    if (state.isLoadingWarehouses && state.warehouses.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (state.warehousesError != null &&
                        state.warehouses.isEmpty) {
                      return _ErrorBlock(
                        message: state.warehousesError!,
                        onRetry: () => context
                            .read<StockAvailabilityCubit>()
                            .loadWarehouses(
                              search: _searchController.text.trim(),
                            ),
                      );
                    }
                    if (state.warehouses.isEmpty) {
                      return const _EmptyBlock(
                        message: 'No warehouses found.',
                      );
                    }
                    final showFooter =
                        state.warehousesHasMore || state.isLoadingMoreWarehouses;
                    return ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                      itemCount: state.warehouses.length + (showFooter ? 1 : 0),
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, index) {
                        if (index == state.warehouses.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: state.isLoadingMoreWarehouses
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const SizedBox(height: 24),
                            ),
                          );
                        }
                        final w = state.warehouses[index];
                        final isSelected =
                            state.selectedWarehouseCode == w.code;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            child: const Icon(
                              Icons.warehouse_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            w.name.isEmpty ? w.code : w.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            w.code,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                )
                              : const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textSecondary,
                                ),
                          onTap: () => Navigator.of(context).pop<ErpWarehouse>(w),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
