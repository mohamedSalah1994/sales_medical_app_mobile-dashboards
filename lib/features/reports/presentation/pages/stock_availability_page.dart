import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/di/service_locator.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/reports/domain/entities/stock_availability.dart';
import 'package:sales_medical_app_mobile/features/reports/presentation/cubit/stock_availability_cubit.dart';
import 'package:sales_medical_app_mobile/features/reports/presentation/cubit/stock_availability_state.dart';
import 'package:sales_medical_app_mobile/features/reports/presentation/widgets/warehouse_picker_sheet.dart';

/// `Reports → Stock availability`.
///
/// - Sales reps: report is loaded automatically using their default warehouse.
/// - Admin / supervisor: tap the warehouse selector to open a paginated picker
///   sourced from `/api/Erp/warehouses`. Once a warehouse is chosen the report
///   refreshes.
class StockAvailabilityPage extends StatelessWidget {
  const StockAvailabilityPage({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StockAvailabilityCubit>(
      create: (_) => sl<StockAvailabilityCubit>(),
      child: _StockAvailabilityView(showScaffold: showScaffold),
    );
  }
}

class _StockAvailabilityView extends StatefulWidget {
  const _StockAvailabilityView({required this.showScaffold});

  final bool showScaffold;

  @override
  State<_StockAvailabilityView> createState() => _StockAvailabilityViewState();
}

class _StockAvailabilityViewState extends State<_StockAvailabilityView> {
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeAutoLoadForSalesRep();
    });
  }

  bool _isSalesRep() {
    final role = context
            .read<AuthCubit>()
            .state
            .loginResponse
            ?.user
            .role
            .toLowerCase() ??
        '';
    return role == 'salesrep';
  }

  void _maybeAutoLoadForSalesRep() {
    if (!_isSalesRep()) return;
    final user = context.read<AuthCubit>().state.loginResponse?.user;
    final warehouseCode = user?.defaultWarehouseCode;
    if (warehouseCode != null && warehouseCode.isNotEmpty) {
      context
          .read<StockAvailabilityCubit>()
          .initialiseForSalesRep(warehouseCode);
    }
  }

  Future<void> _pickWarehouse() async {
    final cubit = context.read<StockAvailabilityCubit>();
    final picked = await showWarehousePickerSheet(context, cubit: cubit);
    if (picked != null) {
      cubit.selectWarehouse(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSalesRep = _isSalesRep();
    final body = BlocBuilder<StockAvailabilityCubit, StockAvailabilityState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              state: state,
              showWarehousePicker: !isSalesRep,
              onTapPickWarehouse: _pickWarehouse,
              onToggleZeroOnHand: (v) =>
                  context.read<StockAvailabilityCubit>().toggleIncludeZeroOnHand(v),
              onRefresh: () =>
                  context.read<StockAvailabilityCubit>().loadStockAvailability(),
            ),
            Expanded(child: _Body(state: state, onRetry: () {
              context.read<StockAvailabilityCubit>().loadStockAvailability();
            })),
          ],
        );
      },
    );

    if (!widget.showScaffold) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock availability'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: body,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.state,
    required this.showWarehousePicker,
    required this.onTapPickWarehouse,
    required this.onToggleZeroOnHand,
    required this.onRefresh,
  });

  final StockAvailabilityState state;
  final bool showWarehousePicker;
  final VoidCallback onTapPickWarehouse;
  final ValueChanged<bool> onToggleZeroOnHand;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final hasWarehouse = state.hasSelectedWarehouse;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: showWarehousePicker ? onTapPickWarehouse : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warehouse_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  showWarehousePicker
                                      ? 'Warehouse'
                                      : 'My warehouse',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasWarehouse
                                      ? (state.selectedWarehouseName != null &&
                                              state.selectedWarehouseName!
                                                  .isNotEmpty
                                          ? '${state.selectedWarehouseCode} — ${state.selectedWarehouseName}'
                                          : state.selectedWarehouseCode!)
                                      : (showWarehousePicker
                                          ? 'Tap to select warehouse'
                                          : 'No default warehouse on profile'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: hasWarehouse
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (showWarehousePicker)
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: AppColors.textSecondary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: hasWarehouse ? onRefresh : null,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Switch.adaptive(
                value: state.includeZeroOnHand,
                onChanged: onToggleZeroOnHand,
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Include items with zero on hand',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (state.rows.isNotEmpty)
                Text(
                  '${state.rows.length} item(s)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.state, required this.onRetry});

  final StockAvailabilityState state;
  final VoidCallback onRetry;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value.trim().toLowerCase());
  }

  List<StockAvailability> _filtered(List<StockAvailability> all) {
    if (_query.isEmpty) return all;
    return all
        .where(
          (r) =>
              r.itemCode.toLowerCase().contains(_query) ||
              r.itemName.toLowerCase().contains(_query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (!state.hasSelectedWarehouse) {
      return const _Placeholder(
        icon: Icons.warehouse_outlined,
        title: 'Select a warehouse',
        message:
            'Choose a warehouse to view its current stock availability report.',
      );
    }
    if (state.isLoading && state.rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.rows.isEmpty) {
      return _ErrorView(message: state.errorMessage!, onRetry: widget.onRetry);
    }
    if (state.rows.isEmpty) {
      return const _Placeholder(
        icon: Icons.inbox_outlined,
        title: 'No stock data',
        message:
            'No stock availability rows for the selected warehouse with the current filters.',
      );
    }

    final filtered = _filtered(state.rows);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by item code or name…',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear',
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
        if (filtered.isEmpty)
          const Expanded(
            child: _Placeholder(
              icon: Icons.search_off,
              title: 'No matches',
              message: 'No items match your search.',
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => widget.onRetry(),
              child: _StockTable(rows: filtered),
            ),
          ),
      ],
    );
  }
}

/// Renders the data table so that vertical scrolling happens inside the table
/// while a single horizontal scrollbar sits at the **bottom of the screen**
/// (regardless of how many rows are visible).
class _StockTable extends StatefulWidget {
  const _StockTable({required this.rows});

  final List<StockAvailability> rows;

  @override
  State<_StockTable> createState() => _StockTableState();
}

class _StockTableState extends State<_StockTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.rows;

    final table = DataTable(
      headingTextStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        fontSize: 13,
      ),
      dataTextStyle: const TextStyle(
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      headingRowColor:
          WidgetStateProperty.resolveWith((_) => AppColors.surface),
      columnSpacing: 24,
      columns: const [
        DataColumn(label: Text('Item code')),
        DataColumn(label: Text('Item name')),
        DataColumn(label: Text('Warehouse')),
        DataColumn(label: Text('On hand'), numeric: true),
        DataColumn(label: Text('Committed'), numeric: true),
        DataColumn(label: Text('On order'), numeric: true),
        DataColumn(label: Text('Available'), numeric: true),
      ],
      rows: rows
          .map(
            (r) => DataRow(
              cells: [
                DataCell(Text(r.itemCode)),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      r.itemName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(r.warehouseCode)),
                DataCell(Text(_fmt(r.onHand))),
                DataCell(Text(_fmt(r.committed))),
                DataCell(Text(_fmt(r.onOrder))),
                DataCell(
                  Text(
                    _fmt(r.available),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: r.available > 0
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                controller: _verticalController,
                scrollDirection: Axis.vertical,
                child: table,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final NumberFormat _qtyFormat = NumberFormat('#,##0.##');

String _fmt(double v) => _qtyFormat.format(v);

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
                color: AppColors.error, size: 56),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
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

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
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
              icon,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
