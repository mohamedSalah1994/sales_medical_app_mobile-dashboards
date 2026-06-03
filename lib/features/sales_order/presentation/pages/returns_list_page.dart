import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_list_item_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_cubit.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_state.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/return_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/erp_document_header_widgets.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/returns_filter_bottom_sheet.dart';

/// Lists ERP returns (GET /api/erp/returns). Search uses GET /api/erp/returns/{docEntry}.
class ReturnsListPage extends StatefulWidget {
  const ReturnsListPage({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  State<ReturnsListPage> createState() => _ReturnsListPageState();
}

class _ReturnsListPageState extends State<ReturnsListPage> {
  final _docEntryController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showSearchBar = false;
  bool _isSearching = false;
  String? _searchError;

  late final VoidCallback _returnsScrollListener = _onReturnsScroll;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_returnsScrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_returnsScrollListener);
    _scrollController.dispose();
    _docEntryController.dispose();
    super.dispose();
  }

  void _onReturnsScroll() {
    if (!mounted) return;
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels < pos.maxScrollExtent - 160) return;

    final cubit = context.read<SalesOrderCubit>();
    final st = cubit.state;
    if (!st.returnsListHasMore ||
        st.isLoadingMoreReturnsList ||
        st.isLoadingReturnsList) {
      return;
    }
    final sapCode =
        context
            .read<AuthCubit>()
            .state
            .loginResponse
            ?.user
            .sapSalesEmployeeCode;
    cubit.loadReturnsList(salesEmployeeCode: sapCode, append: true);
  }

  void _load() {
    final sapCode =
        context
            .read<AuthCubit>()
            .state
            .loginResponse
            ?.user
            .sapSalesEmployeeCode;
    context.read<SalesOrderCubit>().loadReturnsList(salesEmployeeCode: sapCode);
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
      final order = await context.read<SalesOrderCubit>().getReturnByDocEntry(
        docEntry,
      );
      if (!mounted) return;
      setState(() => _isSearching = false);
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder:
              (_) => BlocProvider.value(
                value: context.read<SalesOrderCubit>(),
                child: ReturnPage.viewExisting(
                  returnDocEntry: docEntry,
                  prefetchedReturn: order,
                ),
              ),
        ),
      );
      if (mounted) _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _showReturnsFilterSheet() {
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

  void _openReturn(SalesOrderListItemModel order) {
    final docEntry = order.docEntry ?? order.docNum;
    if (docEntry == null) return;
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder:
                (_) => BlocProvider.value(
                  value: context.read<SalesOrderCubit>(),
                  child: ReturnPage.viewExisting(returnDocEntry: docEntry),
                ),
          ),
        )
        .then((_) => _load());
  }

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
    final l10n = AppLocalizations.of(context)!;

    final listBody = BlocBuilder<SalesOrderCubit, SalesOrderState>(
      buildWhen:
          (p, c) =>
              p.returnsList != c.returnsList ||
              p.isLoadingReturnsList != c.isLoadingReturnsList ||
              p.isLoadingMoreReturnsList != c.isLoadingMoreReturnsList ||
              p.returnsListHasMore != c.returnsListHasMore ||
              p.returnsListError != c.returnsListError,
      builder: (context, state) {
        if (state.isLoadingReturnsList && state.returnsList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.returnsListError != null && state.returnsList.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.returnsListError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.error, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (state.returnsList.isEmpty) {
          return Center(
            child: Text(
              l10n.noReturns,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          );
        }
        final list = state.returnsList;
        final footer = state.returnsListHasMore ? 1 : 0;
        return RefreshIndicator(
          onRefresh: () async => _load(),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: list.length + footer,
            itemBuilder: (context, index) {
              if (index >= list.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child:
                        state.isLoadingMoreReturnsList
                            ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const SizedBox.shrink(),
                  ),
                );
              }
              final order = list[index];
              return _ReturnListCard(
                order: order,
                onTap: () => _openReturn(order),
              );
            },
          ),
        );
      },
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_buildSearchRow(), Expanded(child: listBody)],
    );

    if (!widget.showScaffold) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.returns),
        actions: [
          BlocBuilder<SalesOrderCubit, SalesOrderState>(
            buildWhen:
                (p, c) =>
                    p.hasActiveReturnsFilters != c.hasActiveReturnsFilters,
            builder: (context, state) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Filters',
                    onPressed: _showReturnsFilterSheet,
                    icon: Icon(
                      Icons.filter_list,
                      color:
                          state.hasActiveReturnsFilters
                              ? AppColors.primary
                              : AppColors.textSecondary,
                    ),
                  ),
                  if (state.hasActiveReturnsFilters)
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
        ],
      ),
      body: content,
    );
  }
}

class _ReturnListCard extends StatelessWidget {
  const _ReturnListCard({required this.order, required this.onTap});

  final SalesOrderListItemModel order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final docBadgeLabel = erpListCardPrimaryDocLabel(order.docNum, order.docEntry);
    final statusLabel = erpDocumentStatusShortLabel(order.documentStatus);
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
                  ErpListDocumentStatusPill(label: statusLabel),
                ],
              ),
              const SizedBox(height: 8),
              Row(
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
                  const Spacer(),
                  Text(
                    'Total: $total',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (order.warehouseCode != null &&
                  order.warehouseCode!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.warehouse_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.warehouseCode!.trim(),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
