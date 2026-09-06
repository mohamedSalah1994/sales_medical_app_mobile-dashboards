import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/core/utils/odbc_card_type_label.dart';
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
  final _scrollController = ScrollController();
  bool _showSearchBar = false;
  bool _isSearching = false;
  String? _searchError;

  late final VoidCallback _ordersScrollListener = _onOrdersScroll;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_ordersScrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureCustomersForFilters();
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_ordersScrollListener);
    _scrollController.dispose();
    _docEntryController.dispose();
    super.dispose();
  }

  void _onOrdersScroll() {
    if (!mounted) return;
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final max = pos.maxScrollExtent;
    if (max <= 0) return;
    if (pos.pixels < max - 160) return;

    final cubit = context.read<SalesOrderCubit>();
    final st = cubit.state;
    if (!st.ordersListHasMore ||
        st.isLoadingMoreOrdersList ||
        st.isLoadingOrdersList) {
      return;
    }
    final sap =
        context
            .read<AuthCubit>()
            .state
            .loginResponse
            ?.user
            .sapSalesEmployeeCode;
    cubit.loadSalesOrdersList(
      visitId: widget.visitId,
      salesEmployeeCode: sap,
      append: true,
    );
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
              p.isLoadingMoreOrdersList != c.isLoadingMoreOrdersList ||
              p.ordersListHasMore != c.ordersListHasMore ||
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
          final list = state.ordersList;
          final footer = state.ordersListHasMore ? 1 : 0;
          body = RefreshIndicator(
            onRefresh: () async => _loadOrders(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: list.length + footer,
              itemBuilder: (context, index) {
                if (index >= list.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child:
                          state.isLoadingMoreOrdersList
                              ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const SizedBox.shrink(),
                    ),
                  );
                }
                final order = list[index];
                return _OrderCard(order: order, onTap: () => _openOrder(order));
              },
            ),
          );
        }

        return body;
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
    final jovi = (order.uJovi ?? '').trim();
    final uSt = (order.uSt ?? '').trim();

    return ErpDocumentListCard(
      onTap: onTap,
      docBadgeLabel: docBadgeLabel,
      appIdBadgeText: docBadgeLabel == null ? appIdBadgeText : null,
      showAppIdHint: docBadgeLabel == null && appIdBadgeText != null,
      title: order.customerName ?? '—',
      subtitle: order.distinctCustomerForeignName,
      statusLabel: statusLabel,
      trailingBadges:
          cardTypeLabel.isNotEmpty
              ? [
                ErpListCardTypeBadge(label: cardTypeLabel, isLead: isLead),
              ]
              : const [],
      metaLeading: [
        ErpListMetaChip(
          label: 'Ship No.: ${jovi.isNotEmpty ? jovi : '—'}',
        ),
        ErpListMetaChip(
          label: 'Ship Status: ${uSt.isNotEmpty ? uSt : '—'}',
        ),
      ],
      dateLabel: docDate,
      totalLabel: 'Total: $total',
      remarks: order.remarks,
    );
  }
}

