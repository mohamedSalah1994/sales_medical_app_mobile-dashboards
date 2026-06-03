import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/di/service_locator.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/inventory_exceptions.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/inventory_transfer_models.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/warehouse_odbc_model.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/cubit/inventory_state.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/widgets/inventory_product_pick_dialog.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/widgets/inventory_transfer_document_header.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/widgets/warehouse_searchable_sheet.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/item_lookup_response_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/erp_document_header_widgets.dart';
import 'package:sales_medical_app_mobile/core/pdf/erp_document_pdf_factories.dart';
import 'package:sales_medical_app_mobile/core/pdf/erp_document_pdf_share.dart';

/// Create a new stock transfer, or view an existing one by doc entry.
class InventoryTransferPage extends StatefulWidget {
  const InventoryTransferPage.create({super.key})
    : docEntry = null,
      prefetched = null;

  const InventoryTransferPage.viewExisting({
    super.key,
    required this.docEntry,
    this.prefetched,
  });

  final int? docEntry;
  final InventoryTransferDocModel? prefetched;

  bool get isViewMode => docEntry != null;

  @override
  State<InventoryTransferPage> createState() => _InventoryTransferPageState();
}

class _InventoryTransferPageState extends State<InventoryTransferPage> {
  final _commentsController = TextEditingController();
  final _itemSearchController = TextEditingController();
  DateTime _docDate = DateTime.now();
  WarehouseOdbcModel? _fromWarehouse;
  WarehouseOdbcModel? _toWarehouse;
  List<InventoryLineDraft> _lines = [];
  bool _loading = false;
  bool _submitting = false;
  String? _error;
  InventoryTransferDocModel? _viewDoc;

  bool _lookupLoading = false;
  String? _lookupError;
  bool _defaultFromWarehouseApplied = false;

  @override
  void initState() {
    super.initState();
    if (widget.isViewMode) {
      _loadView();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        context.read<InventoryCubit>().loadWarehouses();
        await Future<void>.delayed(Duration.zero);
        if (!mounted || widget.isViewMode) return;
        final st = context.read<InventoryCubit>().state;
        if (!st.isLoadingWarehouses && st.warehouses.isNotEmpty) {
          await _tryApplyDefaultFromWarehouse(st.warehouses);
        }
      });
    }
  }

  Future<void> _tryApplyDefaultFromWarehouse(
    List<WarehouseOdbcModel> warehouses,
  ) async {
    if (widget.isViewMode || _defaultFromWarehouseApplied) return;
    if (warehouses.isEmpty) return;
    _defaultFromWarehouseApplied = true;

    var code =
        context
            .read<AuthCubit>()
            .state
            .loginResponse
            ?.user
            .defaultWarehouseCode
            ?.trim();
    if (code == null || code.isEmpty) {
      code = await sl<AuthRepository>().getStoredDefaultWarehouseCode();
    }
    if (code == null || code.isEmpty) return;
    final resolvedCode = code;

    WarehouseOdbcModel? match;
    final lower = resolvedCode.toLowerCase();
    for (final w in warehouses) {
      if (w.code.toLowerCase() == lower) {
        match = w;
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _fromWarehouse =
          match ?? WarehouseOdbcModel(code: resolvedCode, name: null);
    });
  }

  @override
  void dispose() {
    _commentsController.dispose();
    _itemSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadView() async {
    if (widget.prefetched != null) {
      setState(() {
        _viewDoc = widget.prefetched;
        _loading = false;
        _commentsController.text = widget.prefetched!.comments ?? '';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doc = await context.read<InventoryCubit>().getTransferByDocEntry(
        widget.docEntry!,
      );
      if (!mounted) return;
      setState(() {
        _viewDoc = doc;
        _commentsController.text = doc.comments ?? '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      if (e is InventoryDocumentNotFoundException) {
        setState(() {
          _loading = false;
          _error = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.inventoryDocNotFound),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _pickWarehouse(bool isFrom) async {
    final cubit = context.read<InventoryCubit>();
    if (cubit.state.warehouses.isEmpty && !cubit.state.isLoadingWarehouses) {
      await cubit.loadWarehouses();
    }
    if (!mounted) return;
    final list = cubit.state.warehouses;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cubit.state.warehousesError ?? 'No warehouses loaded'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final picked = await showWarehouseSearchableSheet(
      context,
      warehouses: list,
      title: isFrom ? l10n.inventoryFromWarehouse : l10n.inventoryToWarehouse,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          _fromWarehouse = picked;
        } else {
          _toWarehouse = picked;
        }
      });
    }
  }

  Future<void> _pickDocDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _docDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _docDate = picked);
    }
  }

  Future<void> _runItemLookup() async {
    if (widget.isViewMode) return;
    final q = _itemSearchController.text.trim();
    if (q.isEmpty) return;
    if (_fromWarehouse == null) {
      setState(
        () =>
            _lookupError =
                AppLocalizations.of(context)!.inventorySelectFromWarehouseFirst,
      );
      return;
    }
    setState(() {
      _lookupLoading = true;
      _lookupError = null;
    });
    try {
      final lookup = await context.read<InventoryCubit>().lookupItemOdbc(
        q,
        warehouseCode: _fromWarehouse!.code,
      );
      if (!mounted) return;
      setState(() => _lookupLoading = false);
      await _applyLookup(lookup);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lookupLoading = false;
        _lookupError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _applyLookup(ItemLookupResponseModel lookup) async {
    final lineBundles = lookup.expandedLinePickBundles();
    if (lineBundles.isEmpty) {
      setState(
        () => _lookupError = AppLocalizations.of(context)!.inventoryNoItemFound,
      );
      return;
    }

    ItemLookupRowBundle? row;
    if (lineBundles.length == 1) {
      row = lineBundles.first;
    } else {
      final q = _itemSearchController.text.trim();
      final rawRowCount = lookup.rawMatchCountForPagination();
      row = await showItemLookupRowPickDialog(
        context,
        query: q,
        initialRows: lineBundles,
        initialRawRowCount: rawRowCount,
        initialHasMore: rawRowCount >= kOdbcItemLookupTake,
        fetchPage: (searchQuery, skip) async {
          try {
            return await context.read<InventoryCubit>().lookupItemOdbc(
              searchQuery,
              warehouseCode: _fromWarehouse!.code,
              skip: skip,
            );
          } catch (_) {
            return null;
          }
        },
      );
    }
    if (!mounted || row == null) return;

    final draft = InventoryLineDraft.fromProductAndUoMs(row.product, row.uoMs);
    _tryAddDraft(draft);
  }

  void _tryAddDraft(InventoryLineDraft draft) {
    final exists = _lines.any((l) => l.itemCode == draft.itemCode);
    if (exists) {
      setState(
        () =>
            _lookupError =
                AppLocalizations.of(context)!.inventoryItemAlreadyAdded,
      );
      return;
    }
    setState(() {
      _lines = [..._lines, draft];
      _itemSearchController.clear();
      _lookupError = null;
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_fromWarehouse == null || _toWarehouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.inventorySelectBothWarehouses),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_fromWarehouse!.code == _toWarehouse!.code) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.inventoryWarehousesMustDiffer),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.inventoryAddAtLeastOneLine),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    for (final line in _lines) {
      if (line.resolvedUoMEntry == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.inventorySelectUomForLine(line.itemCode)),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (line.quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.inventoryQuantityMustBePositive),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final request = CreateInventoryTransferRequestModel(
      docDate: _docDate,
      fromWarehouse: _fromWarehouse!.code,
      toWarehouse: _toWarehouse!.code,
      comments:
          _commentsController.text.trim().isEmpty
              ? null
              : _commentsController.text.trim(),
      stockTransferLines:
          _lines
              .map(
                (l) => StockTransferLineRequestModel(
                  itemCode: l.itemCode,
                  quantity: l.quantity,
                  uoMEntry: l.resolvedUoMEntry!,
                ),
              )
              .toList(),
    );

    setState(() => _submitting = true);
    try {
      final response = await context.read<InventoryCubit>().createTransfer(
        request,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      if (!response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.errorMessage ?? l10n.inventoryCreateFailed),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      // API returns ERP doc key as documentId — show that as doc entry in the message.
      final docEntryLabel =
          response.documentId ?? response.documentNumber ?? '—';
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: Text(
              l10n.inventoryTransferSuccessTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            content: Text(
              l10n.inventoryCreated(docEntryLabel),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.ok),
              ),
            ],
          );
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  static String _fmtNum(num? n) {
    if (n == null) return '—';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat.yMMMd().format(_docDate);

    if (_loading && widget.isViewMode) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text(l10n.inventory),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null && widget.isViewMode && _viewDoc == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text(l10n.inventory),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: _loadView, child: Text(l10n.cancel)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: ErpDocHeaderAppBarTitle(
          title:
              widget.isViewMode ? l10n.inventory : l10n.inventoryCreateTransfer,
          docEntry:
              widget.isViewMode
                  ? (_viewDoc?.docEntry ?? widget.docEntry)
                  : null,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: _loading
          ? null
          : Builder(
              builder: (_) {
                final saveFab = !widget.isViewMode
                    ? FloatingActionButton.extended(
                        heroTag: 'inv-transfer-main-fab',
                        onPressed: _submitting ? null : _submit,
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save, size: 20),
                        label: Text(
                          l10n.save,
                          style: const TextStyle(fontSize: 13),
                        ),
                      )
                    : null;

                final pdfFab =
                    (widget.isViewMode && _viewDoc != null)
                    ? FloatingActionButton.extended(
                        heroTag: 'inv-transfer-pdf-fab',
                        tooltip: 'Export PDF',
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 3,
                        onPressed: () {
                          shareErpDocumentPdf(
                            context,
                            builder: buildInventoryTransferPdf(
                              doc: _viewDoc!,
                              title: l10n.inventory,
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 20,
                        ),
                        label: const Text(
                          'Export',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : null;

                if (saveFab == null && pdfFab == null) {
                  return const SizedBox.shrink();
                }
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pdfFab != null) ...[
                      pdfFab,
                      const SizedBox(width: 12),
                    ],
                    if (saveFab != null) saveFab,
                  ],
                );
              },
            ),
      body: BlocListener<InventoryCubit, InventoryState>(
        listenWhen:
            (prev, curr) =>
                !widget.isViewMode &&
                !curr.isLoadingWarehouses &&
                curr.warehouses.isNotEmpty,
        listener: (context, state) {
          _tryApplyDefaultFromWarehouse(state.warehouses);
        },
        child: BlocBuilder<InventoryCubit, InventoryState>(
          builder: (context, invState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.isViewMode) ...[
                    _createHeaderCard(context, l10n, dateStr, invState),
                    const SizedBox(height: 12),
                    Text(
                      l10n.inventoryAddItems,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _itemSearchController,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: l10n.inventorySearchItemHint,
                              border: const OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                            onSubmitted: (_) => _runItemLookup(),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Search',
                          onPressed: _lookupLoading ? null : _runItemLookup,
                          icon:
                              _lookupLoading
                                  ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.search),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (_lookupError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _lookupError!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ] else if (_viewDoc != null) ...[
                    InventoryTransferDocumentHeader(doc: _viewDoc!),
                    const SizedBox(height: 12),
                  ],
                  _linesSectionTitle(
                    widget.isViewMode ? l10n.details : l10n.inventoryLines,
                  ),
                  const SizedBox(height: 6),
                  if (widget.isViewMode && _viewDoc != null)
                    _linesTableReadOnly(l10n, _viewDoc!)
                  else
                    _linesTableEditable(context, l10n),
                  const SizedBox(height: 12),
                  if (widget.isViewMode && _viewDoc != null)
                    _commentsReadOnly(l10n)
                  else ...[
                    TextFormField(
                      controller: _commentsController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: l10n.notesOptional,
                        labelStyle: const TextStyle(fontSize: 12),
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                      minLines: 2,
                      maxLines: 4,
                    ),
                  ],
                  SizedBox(height: widget.isViewMode ? 24 : 88),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _createHeaderCard(
    BuildContext context,
    AppLocalizations l10n,
    String dateStr,
    InventoryState invState,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _pickDocDate,
            borderRadius: BorderRadius.circular(6),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.inventoryDocumentDate,
                labelStyle: const TextStyle(fontSize: 12),
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              child: Text(dateStr, style: const TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _pickWarehouse(true),
            borderRadius: BorderRadius.circular(6),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.inventoryFromWarehouse,
                labelStyle: const TextStyle(fontSize: 12),
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              child: Text(
                _fromWarehouse?.displayLabel ?? l10n.inventorySelectWarehouse,
                style: const TextStyle(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _pickWarehouse(false),
            borderRadius: BorderRadius.circular(6),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.inventoryToWarehouse,
                labelStyle: const TextStyle(fontSize: 12),
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              child: Text(
                _toWarehouse?.displayLabel ?? l10n.inventorySelectWarehouse,
                style: const TextStyle(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (invState.isLoadingWarehouses)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _linesSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _commentsReadOnly(AppLocalizations l10n) {
    final text =
        _commentsController.text.trim().isEmpty
            ? '—'
            : _commentsController.text.trim();
    return InputDecorator(
      decoration: InputDecoration(
        labelText: l10n.notesOptional,
        labelStyle: const TextStyle(fontSize: 12),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _linesTableReadOnly(
    AppLocalizations l10n,
    InventoryTransferDocModel doc,
  ) {
    const header = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
    const txt = TextStyle(fontSize: 11);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          border: TableBorder.all(color: AppColors.border),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: {
            for (var i = 0; i < 7; i++) i: const IntrinsicColumnWidth(),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                _InvHeaderCell('#', style: header),
                _InvHeaderCell('itemCode', style: header),
                _InvHeaderCell('itemName', style: header),
                _InvHeaderCell(l10n.inventoryColItemUnit, style: header),
                _InvHeaderCell(l10n.inventoryColOnHand, style: header),
                _InvHeaderCell(l10n.inventoryColQty, style: header),
                _InvHeaderCell(l10n.inventoryColUom, style: header),
              ],
            ),
            ...doc.lines.asMap().entries.map((e) {
              final line = e.value;
              final lineNo = line.lineNum ?? e.key + 1;
              return TableRow(
                children: [
                  _InvBodyCell(Text('$lineNo', style: txt)),
                  _InvBodyCell(Text(line.itemCode, style: txt)),
                  _InvBodyCell(Text(line.itemName ?? '—', style: txt)),
                  const _InvBodyCell(Text('—', style: txt)),
                  const _InvBodyCell(Text('—', style: txt)),
                  _InvBodyCell(Text(_fmtNum(line.quantity), style: txt)),
                  _InvBodyCell(
                    Text(
                      (line.uoMCode != null && line.uoMCode!.trim().isNotEmpty)
                          ? line.uoMCode!.trim()
                          : '${line.uoMEntry ?? '—'}',
                      style: txt,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _linesTableEditable(BuildContext context, AppLocalizations l10n) {
    const header = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
    const txt = TextStyle(fontSize: 11, color: AppColors.textPrimary);
    if (_lines.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          l10n.inventoryNoLinesYet,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          border: TableBorder.all(color: AppColors.border),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: {
            for (var i = 0; i < 8; i++) i: const IntrinsicColumnWidth(),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                _InvHeaderCell('#', style: header),
                _InvHeaderCell('itemCode', style: header),
                _InvHeaderCell('itemName', style: header),
                _InvHeaderCell(l10n.inventoryColItemUnit, style: header),
                _InvHeaderCell(l10n.inventoryColOnHand, style: header),
                _InvHeaderCell(l10n.inventoryColQty, style: header),
                _InvHeaderCell(l10n.inventoryColUom, style: header),
                _InvHeaderCell('', style: header),
              ],
            ),
            ...List.generate(_lines.length, (i) {
              final line = _lines[i];
              final rows = line.uoMsForDropdown;
              String? dropValue;
              if (rows.isNotEmpty) {
                final e = line.effectiveUoMCode;
                dropValue =
                    (e != null && rows.any((u) => u.uoMCode == e))
                        ? e
                        : rows.first.uoMCode;
              }

              return TableRow(
                children: [
                  _InvBodyCell(Text('${i + 1}', style: txt)),
                  _InvBodyCell(Text(line.itemCode, style: txt)),
                  _InvBodyCell(
                    Text(line.itemName, style: txt, softWrap: true),
                  ),
                  _InvBodyCell(
                    Text(
                      (line.baseUnitOfMeasure != null &&
                              line.baseUnitOfMeasure!.trim().isNotEmpty)
                          ? line.baseUnitOfMeasure!.trim()
                          : '—',
                      style: txt,
                    ),
                  ),
                  _InvBodyCell(
                    Text(line.onHand?.toString() ?? '—', style: txt),
                  ),
                  _InvBodyCell(
                    _QtyEditCell(
                      key: ValueKey('qty-$i-${line.itemCode}'),
                      quantity: line.quantity,
                      onChanged: (v) {
                        setState(() {
                          final l = _lines[i];
                          _lines = List<InventoryLineDraft>.from(_lines);
                          _lines[i] = l.copyWith(quantity: v);
                        });
                      },
                    ),
                  ),
                  _InvBodyCell(
                    rows.isEmpty
                        ? Text(l10n.inventoryNoUom, style: txt)
                        : DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: dropValue,
                              isDense: true,
                              isExpanded: true,
                              style: txt,
                              selectedItemBuilder: (context) {
                                return rows
                                    .map(
                                      (u) => Text(
                                        u.uoMCode,
                                        style: txt,
                                        softWrap: true,
                                      ),
                                    )
                                    .toList();
                              },
                              items:
                                  rows
                                      .map(
                                        (u) => DropdownMenuItem<String>(
                                          value: u.uoMCode,
                                          child: Text(
                                            u.uoMCode,
                                            style: txt,
                                            softWrap: true,
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (code) {
                                if (code == null) return;
                                ItemUoMModel? u;
                                for (final x in line.uoMs) {
                                  if (x.uoMCode == code) {
                                    u = x;
                                    break;
                                  }
                                }
                                final match = u ?? line.uoMs.first;
                                setState(() {
                                  final l = _lines[i];
                                  _lines = List<InventoryLineDraft>.from(
                                    _lines,
                                  );
                                  _lines[i] = l.copyWith(
                                    uoMCode: code,
                                    uoMEntry: match.uoMEntry,
                                  );
                                });
                              },
                            ),
                          ),
                  ),
                  _InvBodyCell(
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _lines = List<InventoryLineDraft>.from(_lines)
                            ..removeAt(i);
                        });
                      },
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _InvHeaderCell extends StatelessWidget {
  const _InvHeaderCell(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(text, style: style, softWrap: true),
    );
  }
}

class _InvBodyCell extends StatelessWidget {
  const _InvBodyCell(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: child,
    );
  }
}

class _QtyEditCell extends StatefulWidget {
  const _QtyEditCell({
    super.key,
    required this.quantity,
    required this.onChanged,
  });

  final num quantity;
  final ValueChanged<num> onChanged;

  @override
  State<_QtyEditCell> createState() => _QtyEditCellState();
}

class _QtyEditCellState extends State<_QtyEditCell> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.quantity.toString());
  }

  @override
  void didUpdateWidget(covariant _QtyEditCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity &&
        _controller.text != widget.quantity.toString()) {
      _controller.text = widget.quantity.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const txt = TextStyle(fontSize: 11);
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: txt,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        border: OutlineInputBorder(),
      ),
      onChanged: (s) {
        final v = num.tryParse(s.trim());
        if (v != null) widget.onChanged(v);
      },
    );
  }
}
