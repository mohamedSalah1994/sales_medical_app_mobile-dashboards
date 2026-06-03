import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/core/utils/odbc_card_type_label.dart';
import 'package:sales_medical_app_mobile/core/utils/van_sales.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_list_item_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_cubit.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_state.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/sales_order_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/erp_document_header_widgets.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/sales_orders_filter_bottom_sheet.dart';

/// List from GET /api/erp/sales-orders. Optional [visitId] scopes the query when set.
class SalesOrderListPage extends StatefulWidget {
  const SalesOrderListPage({super.key, this.showScaffold = true, this.visitId});

  final bool showScaffold;
  final String? visitId;

  @override
  State<SalesOrderListPage> createState() => _SalesOrderListPageState();
}

class _SalesOrderListPageState extends State<SalesOrderListPage> {
  final _docEntryController = TextEditingController();
  bool _showSearchBar = false;
  bool _isSearching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureCustomersForFilters();
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _docEntryController.dispose();
    super.dispose();
  }

  void _ensureCustomersForFilters() {
    final cubit = context.read<SalesOrderCubit>();
    if (cubit.state.customers.isEmpty && !cubit.state.isLoadingCustomers) {
      final sap =
          context
              .read<AuthCubit>()
              .state
              .loginResponse
              ?.user
              .sapSalesEmployeeCode;
      cubit.loadCustomers(salesEmployeeCode: sap);
    }
  }

  void _loadOrders() {
    final sap =
        context
            .read<AuthCubit>()
            .state
            .loginResponse
            ?.user
            .sapSalesEmployeeCode;
    context.read<SalesOrderCubit>().loadSalesOrdersList(
      visitId: widget.visitId,
      salesEmployeeCode: sap,
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => BlocProvider.value(
            value: context.read<SalesOrderCubit>(),
            child: BlocProvider.value(
              value: context.read<AuthCubit>(),
              child: SalesOrdersFilterBottomSheet(visitId: widget.visitId),
            ),
          ),
    );
  }

  void _openCreate() {
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder:
                (_) => BlocProvider.value(
                  value: context.read<SalesOrderCubit>(),
                  child: const SalesOrderPage(showScaffold: true),
                ),
          ),
        )
        .then((_) => _loadOrders());
  }

  void _openOrder(SalesOrderListItemModel order) {
    final docEntry = order.docEntry ?? order.docNum;
    if (docEntry == null) {
      if (order.appSalesOrderId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This order has no ERP document number yet. Open it from SAP when synced.',
            ),
          ),
        );
      }
      return;
    }
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder:
                (_) => BlocProvider.value(
                  value: context.read<SalesOrderCubit>(),
                  child: SalesOrderPage(
                    showScaffold: true,
                    initialDocEntry: docEntry,
                  ),
                ),
          ),
        )
        .then((_) => _loadOrders());
  }

  Future<void> _onSearchByDocEntry() async {
    final raw = _docEntryController.text.trim();
    final docEntry = int.tryParse(raw);
    if (docEntry == null) {
      setState(() => _searchError = 'Enter a valid Doc Entry (number)');
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final order = await context
          .read<SalesOrderCubit>()
          .getSalesOrderByDocEntry(docEntry);
      if (!mounted) return;
      setState(() => _isSearching = false);
      context.read<SalesOrderCubit>().loadOrderForEdit(order);
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder:
              (_) => BlocProvider.value(
                value: context.read<SalesOrderCubit>(),
                child: SalesOrderPage(
                  showScaffold: true,
                  initialDocEntry: docEntry,
                ),
              ),
        ),
      );
      if (mounted) _loadOrders();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Doc-entry search row (same pattern as [DeliveriesListPage]).
  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_showSearchBar) ...[
                Expanded(
                  child: TextField(
                    controller: _docEntryController,
                    decoration: const InputDecoration(
                      hintText: 'Doc Entry',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _onSearchByDocEntry(),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Search',
                  onPressed: _isSearching ? null : _onSearchByDocEntry,
                  icon:
                      _isSearching
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.arrow_forward),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed:
                      () => setState(() {
                        _showSearchBar = false;
                        _searchError = null;
                      }),
                ),
              ] else ...[
                const Spacer(),
                IconButton(
                  tooltip: 'Search by Doc Entry',
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() => _showSearchBar = true),
                ),
              ],
            ],
          ),
          if (_searchError != null && _showSearchBar) ...[
            const SizedBox(height: 6),
            Text(
              _searchError!,
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = BlocBuilder<SalesOrderCubit, SalesOrderState>(
      buildWhen:
          (p, c) =>
              p.ordersList != c.ordersList ||
              p.isLoadingOrdersList != c.isLoadingOrdersList ||
              p.ordersListError != c.ordersListError ||
              p.hasActiveOrdersFilters != c.hasActiveOrdersFilters,
      builder: (context, state) {
        Widget body;

        if (state.isLoadingOrdersList && state.ordersList.isEmpty) {
          body = const Center(child: CircularProgressIndicator());
        } else if (state.ordersListError != null && state.ordersList.isEmpty) {
          body = Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.ordersListError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.error, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _loadOrders,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        } else if (state.ordersList.isEmpty) {
          body = Center(
            child: Text(
              widget.visitId != null
                  ? 'No sales orders for this visit.'
                  : 'No sales orders.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          );
        } else {
          body = RefreshIndicator(
            onRefresh: () async => _loadOrders(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.ordersList.length,
              itemBuilder: (context, index) {
                final order = state.ordersList[index];
                return _OrderCard(order: order, onTap: () => _openOrder(order));
              },
            ),
          );
        }

        return Stack(
          children: [
            Positioned.fill(child: body),
            if (state.isLoadingOrdersList && state.ordersList.isNotEmpty)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x33000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_buildSearchRow(), Expanded(child: content)],
    );

    if (!widget.showScaffold) {
      return Scaffold(
        body: body,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreate,
          icon: const Icon(Icons.add),
          label: const Text('Create sales order'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.visitId != null ? 'Sales orders (visit)' : 'Sales orders',
        ),
        actions: [
          BlocBuilder<SalesOrderCubit, SalesOrderState>(
            buildWhen:
                (p, c) => p.hasActiveOrdersFilters != c.hasActiveOrdersFilters,
            builder: (context, state) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color:
                          state.hasActiveOrdersFilters
                              ? AppColors.primary
                              : AppColors.textSecondary,
                    ),
                    onPressed: _showFilterSheet,
                    tooltip: 'Filters',
                  ),
                  if (state.hasActiveOrdersFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Create sales order'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final SalesOrderListItemModel order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final docBadgeLabel = erpListCardPrimaryDocLabel(
      order.docNum,
      order.docEntry,
    );
    final id = order.appSalesOrderId;
    final statusLabel = erpDocumentStatusShortLabel(order.documentStatus);
    final saleTypeLabel = salesTypeLabel(order.uTrantjov);
    final isVanSales = isVanSalesYes(order.uTrantjov);
    final cardTypeLabel = () {
      final fromName = order.cardTypeName?.trim() ?? '';
      if (fromName.isNotEmpty) return fromName;
      return odbcCardTypeKindLabel(order.cardType);
    }();
    final isLead = order.cardType?.trim().toUpperCase() == 'L';
    final appIdBadgeText =
        id != null
            ? (id.length >= 8 ? '#${id.substring(0, 8)}…' : '#$id')
            : null;

    final docDate =
        order.docDate != null
            ? (() {
              final d = DateTime.tryParse(order.docDate!);
              return d != null ? DateFormat.yMMMd().format(d) : '—';
            }())
            : '—';
    final total =
        order.docTotal != null
            ? NumberFormat.currency(
              symbol: '',
              decimalDigits: 2,
            ).format(order.docTotal)
            : '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (docBadgeLabel != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              docBadgeLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ] else if (appIdBadgeText != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              appIdBadgeText,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'App',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  order.customerName ?? '—',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (order.distinctCustomerForeignName !=
                                    null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    order.distinctCustomerForeignName!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      height: 1.25,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ErpListDocumentStatusPill(label: statusLabel),
                      if (cardTypeLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _OrderCardTypeBadge(
                          label: cardTypeLabel,
                          isLead: isLead,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isVanSales
                                    ? AppColors.primary.withValues(alpha: 0.10)
                                    : AppColors.textSecondary.withValues(
                                      alpha: 0.10,
                                    ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  isVanSales
                                      ? AppColors.primary.withValues(
                                        alpha: 0.30,
                                      )
                                      : AppColors.textSecondary.withValues(
                                        alpha: 0.25,
                                      ),
                            ),
                          ),
                          child: Text(
                            saleTypeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color:
                                  isVanSales
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              docDate,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Total: $total',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (order.remarks != null &&
                  order.remarks!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  order.remarks!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Customer / Lead chip mirrored from the customers list cards.
class _OrderCardTypeBadge extends StatelessWidget {
  const _OrderCardTypeBadge({required this.label, required this.isLead});

  final String label;
  final bool isLead;

  @override
  Widget build(BuildContext context) {
    final color = isLead ? AppColors.warning : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
