import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/item_lookup_response_model.dart';

/// Idle time before the dialog search triggers ODBC `lookup-odbc` again.
const Duration kItemLookupSearchDebounce = Duration(milliseconds: 400);

/// ODBC multi-match picker: search bar calls `lookup-odbc` after [kItemLookupSearchDebounce] idle; scroll loads more (`skip` / `take`).
Future<ItemLookupRowBundle?> showItemLookupRowPickDialog(
  BuildContext context, {
  required String query,
  required List<ItemLookupRowBundle> initialRows,

  /// `lookup.rows.length` from the response that produced [initialRows] (unexpanded).
  required int initialRawRowCount,

  /// Whether the server likely has another page (`initialRawRowCount >= take`).
  required bool initialHasMore,
  required Future<ItemLookupResponseModel?> Function(String query, int skip)
  fetchPage,
  int take = kOdbcItemLookupTake,
}) {
  return showDialog<ItemLookupRowBundle>(
    context: context,
    builder:
        (ctx) => _ItemLookupRowPickDialog(
          query: query,
          initialRows: initialRows,
          initialRawRowCount: initialRawRowCount,
          initialHasMore: initialHasMore,
          fetchPage: fetchPage,
          take: take,
        ),
  );
}

class _ItemLookupRowPickDialog extends StatefulWidget {
  const _ItemLookupRowPickDialog({
    required this.query,
    required this.initialRows,
    required this.initialRawRowCount,
    required this.initialHasMore,
    required this.fetchPage,
    required this.take,
  });

  final String query;
  final List<ItemLookupRowBundle> initialRows;
  final int initialRawRowCount;
  final bool initialHasMore;
  final Future<ItemLookupResponseModel?> Function(String query, int skip)
  fetchPage;
  final int take;

  @override
  State<_ItemLookupRowPickDialog> createState() =>
      _ItemLookupRowPickDialogState();
}

class _ItemLookupRowPickDialogState extends State<_ItemLookupRowPickDialog> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounceTimer;

  late List<ItemLookupRowBundle> _initialSnapshot;
  late List<ItemLookupRowBundle> _rows;
  bool _loadingMore = false;
  bool _loadingSearch = false;
  late bool _hasMore;

  /// Next `skip` for `lookup-odbc` (raw ODBC rows, not expanded warehouse lines).
  late int _rawSkipNext;

  @override
  void initState() {
    super.initState();
    _initialSnapshot = List<ItemLookupRowBundle>.from(widget.initialRows);
    _rows = List<ItemLookupRowBundle>.from(widget.initialRows);
    _dedupeRows();
    _rawSkipNext = widget.initialRawRowCount;
    _hasMore = widget.initialHasMore;
    _searchController.addListener(_onSearchTextChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(kItemLookupSearchDebounce, () {
      if (!mounted) return;
      _applyDebouncedSearch();
    });
  }

  Future<void> _applyDebouncedSearch() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) {
      setState(() {
        _rows = List<ItemLookupRowBundle>.from(_initialSnapshot);
        _dedupeRows();
        _rawSkipNext = widget.initialRawRowCount;
        _hasMore = widget.initialHasMore;
        _loadingSearch = false;
      });
      return;
    }

    setState(() => _loadingSearch = true);
    try {
      final next = await widget.fetchPage(q, 0);
      if (!mounted) return;
      setState(() => _loadingSearch = false);
      if (next == null) {
        setState(() {
          _rows = [];
          _hasMore = false;
        });
        return;
      }
      final rawLen = next.rawMatchCountForPagination();
      final list = next.expandedLinePickBundles();
      setState(() {
        _rows = List<ItemLookupRowBundle>.from(list);
        _dedupeRows();
        _rawSkipNext = rawLen;
        _hasMore = rawLen >= widget.take;
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingSearch = false;
        _rows = [];
        _hasMore = false;
      });
    }
  }

  void _dedupeRows() {
    final seen = <String>{};
    _rows =
        _rows.where((r) {
          final w = r.product.onHandWarehouseCode?.trim() ?? '';
          final key = '${r.product.code}|$w';
          if (seen.contains(key)) return false;
          seen.add(key);
          return true;
        }).toList();
  }

  Future<void> _onScroll() async {
    if (!_hasMore || _loadingMore || _loadingSearch) return;
    final pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 120) return;

    final typed = _searchController.text.trim();
    final queryForPage = typed.isEmpty ? widget.query.trim() : typed;
    if (queryForPage.isEmpty) return;

    setState(() => _loadingMore = true);
    try {
      final next = await widget.fetchPage(queryForPage, _rawSkipNext);
      if (!mounted) return;
      setState(() => _loadingMore = false);
      if (next == null) {
        setState(() => _hasMore = false);
        return;
      }
      final rawLen = next.rawMatchCountForPagination();
      final more = next.expandedLinePickBundles();
      if (more.isEmpty || rawLen == 0) {
        setState(() => _hasMore = false);
        return;
      }
      setState(() {
        _rows.addAll(more);
        _dedupeRows();
        _rawSkipNext += rawLen;
        _hasMore = rawLen >= widget.take;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _hasMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        l10n.inventoryPickItemTitle,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      content: SizedBox(
        width: double.maxFinite,
        height: (MediaQuery.of(context).size.height * 0.5).clamp(280.0, 420.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: l10n.inventoryPickItemSearchHint,
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  _loadingSearch
                      ? const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                      : _rows.isEmpty
                      ? Center(
                        child: Text(
                          l10n.inventoryNoItemFound,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                      : ListView.builder(
                        controller: _scrollController,
                        itemCount: _rows.length + (_loadingMore ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i >= _rows.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }
                          final row = _rows[i];
                          final p = row.product;
                          final title =
                              (p.name != null && p.name!.isNotEmpty)
                                  ? p.name!
                                  : p.code;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (i > 0) const Divider(height: 1),
                              ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 0,
                                ),
                                title: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  [
                                    p.code,
                                    if (p.onHandWarehouseCode != null &&
                                        p.onHandWarehouseCode!
                                            .trim()
                                            .isNotEmpty)
                                      p.onHandWarehouseCode!.trim(),
                                    if (p.onHand != null)
                                      '${l10n.inventoryColOnHand}: ${p.onHand}',
                                  ].join(' · '),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                onTap: () => Navigator.of(context).pop(row),
                              ),
                            ],
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
