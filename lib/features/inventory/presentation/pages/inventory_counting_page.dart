import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/di/service_locator.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/inventory_exceptions.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/inventory_counting_models.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/inventory_transfer_models.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/warehouse_odbc_model.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/cubit/inventory_state.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/widgets/inventory_counting_document_header.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/widgets/inventory_product_pick_dialog.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/item_lookup_response_model.dart'
    show
        ItemLookupResponseModel,
        ItemLookupRowBundle,
        ItemUoMModel,
        kOdbcItemLookupTake;
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/erp_document_header_widgets.dart';
import 'package:sales_medical_app_mobile/core/pdf/erp_document_pdf_factories.dart';
import 'package:sales_medical_app_mobile/core/pdf/erp_document_pdf_share.dart';

class InventoryCountingPage extends StatefulWidget {
  const InventoryCountingPage.create({super.key})
    : docEntry = null,
      prefetched = null;

  const InventoryCountingPage.viewExisting({
    super.key,
    required this.docEntry,
    this.prefetched,
  });

  final int? docEntry;
  final InventoryCountingDocModel? prefetched;

  bool get isViewMode => docEntry != null;

  @override
  State<InventoryCountingPage> createState() => _InventoryCountingPageState();
}

class _InventoryCountingPageState extends State<InventoryCountingPage> {
  final _remarksController = TextEditingController();
  final _itemSearchController = TextEditingController();
  DateTime _countDate = DateTime.now();
  WarehouseOdbcModel? _warehouse;
  List<InventoryLineDraft> _lines = [];
  bool _loading = false;
  bool _submitting = false;
  String? _error;
  InventoryCountingDocModel? _viewDoc;

  bool _lookupLoading = false;
  String? _lookupError;
  bool _defaultWarehouseApplied = false;
  bool _warehouseLocked = false;

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
          await _tryApplyDefaultWarehouse(st.warehouses);
        }
      });
    }
  }

  Future<void> _tryApplyDefaultWarehouse(
    List<WarehouseOdbcModel> warehouses,
  ) async {
    if (widget.isViewMode || _defaultWarehouseApplied) return;
    if (warehouses.isEmpty) return;
    _defaultWarehouseApplied = true;

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
      _warehouse = match ?? WarehouseOdbcModel(code: resolvedCode, name: null);
      _warehouseLocked = true;
    });
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _itemSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadView() async {
    if (widget.prefetched != null) {
      setState(() {
        _viewDoc = widget.prefetched;
        _loading = false;
        _remarksController.text = widget.prefetched!.remarks ?? '';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doc = await context.read<InventoryCubit>().getCountingByDocEntry(
        widget.docEntry!,
      );
      if (!mounted) return;
      setState(() {
        _viewDoc = doc;
        _remarksController.text = doc.remarks ?? '';
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

  Future<void> _pickCountDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _countDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _countDate = picked);
    }
  }

  Future<void> _runItemLookup() async {
    if (widget.isViewMode) return;
    final q = _itemSearchController.text.trim();
    if (q.isEmpty) return;
    if (_warehouse == null) {
      setState(
        () =>
            _lookupError =
                AppLocalizations.of(
                  context,
                )!.inventoryCountingNoDefaultWarehouse,
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
        warehouseCode: _warehouse!.code,
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
              warehouseCode: _warehouse!.code,
              skip: skip,
            );
          } catch (_) {
            return null;
          }
        },
      );
    }
    if (!mounted || row == null) return;

    final draft = InventoryLineDraft.fromProductAndUoMs(
      row.product,
      row.uoMs,
    ).copyWith(quantity: 0);
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

  static String _varianceLabel(num counted, num? onHand) {
    if (onHand == null) return '—';
    final v = counted - onHand;
    if (v == 0) return '0';
    if (v > 0) return '+$v';
    return v.toString();
  }

  Future<void> _showCountingCreateErrorDialog(String message) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final msg =
        message.trim().isEmpty
            ? l10n.inventoryCountingCreateFailed
            : message.trim();
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            l10n.inventoryCountingCreateFailed,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              msg,
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                color: AppColors.textPrimary,
              ),
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
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_warehouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.inventoryCountingNoDefaultWarehouse),
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
      final uom = line.effectiveUoMCode?.trim();
      if (uom == null || uom.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.inventorySelectUomForLine(line.itemCode)),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (line.quantity < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.inventoryCountedQtyNonNegative),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final wh = _warehouse!.code;
    final request = CreateInventoryCountingRequestModel(
      countDate: _countDate,
      remarks:
          _remarksController.text.trim().isEmpty
              ? null
              : _remarksController.text.trim(),
      inventoryCountingLines:
          _lines
              .map(
                (l) => InventoryCountingLineRequestModel(
                  itemCode: l.itemCode,
                  warehouseCode: wh,
                  countedQuantity: l.quantity,
                  uoMCode: l.effectiveUoMCode!.trim(),
                ),
              )
              .toList(),
    );

    setState(() => _submitting = true);
    try {
      final response = await context.read<InventoryCubit>().createCounting(
        request,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      if (!response.success) {
        await _showCountingCreateErrorDialog(
          response.errorMessage ?? l10n.inventoryCountingCreateFailed,
        );
        return;
      }
      final docEntryLabel =
          response.documentId ?? response.documentNumber ?? '—';
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: Text(
              l10n.inventoryCountingSuccessTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            content: Text(
              l10n.inventoryCountingCreated(docEntryLabel),
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
      await _showCountingCreateErrorDialog(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat.yMMMd().format(_countDate);

    if (_loading && widget.isViewMode) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text(l10n.inventoryCounting),
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
          title: Text(l10n.inventoryCounting),
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
              widget.isViewMode
                  ? l10n.inventoryCounting
                  : l10n.inventoryCountingNew,
          docEntry:
              widget.isViewMode
                  ? (_viewDoc?.documentEntry ?? widget.docEntry)
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
                        heroTag: 'inv-counting-main-fab',
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
                        heroTag: 'inv-counting-pdf-fab',
                        tooltip: 'Export PDF',
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 3,
                        onPressed: () {
                          shareErpDocumentPdf(
                            context,
                            builder: buildInventoryCountingPdf(
                              doc: _viewDoc!,
                              title: l10n.inventoryCounting,
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
          _tryApplyDefaultWarehouse(state.warehouses);
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
                              contentPadding: const EdgeInsets.symmetric(
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
                    InventoryCountingDocumentHeader(doc: _viewDoc!),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    widget.isViewMode ? l10n.details : l10n.inventoryLines,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (widget.isViewMode && _viewDoc != null)
                    _linesTableReadOnly(l10n, _viewDoc!)
                  else
                    _linesTableEditable(context, l10n),
                  const SizedBox(height: 12),
                  if (widget.isViewMode && _viewDoc != null)
                    _remarksReadOnly(l10n)
                  else ...[
                    TextFormField(
                      controller: _remarksController,
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
            onTap: _pickCountDate,
            borderRadius: BorderRadius.circular(6),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.inventoryCountDate,
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
          InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.inventoryColWarehouse,
              labelStyle: const TextStyle(fontSize: 12),
              border: const OutlineInputBorder(),
              isDense: true,
              filled: _warehouseLocked,
              fillColor:
                  _warehouseLocked
                      ? AppColors.textSecondary.withValues(alpha: 0.06)
                      : null,
              suffixIcon:
                  _warehouseLocked
                      ? const Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: AppColors.textSecondary,
                      )
                      : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
            child: Text(
              _warehouse?.displayLabel ?? l10n.inventorySelectWarehouse,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

  Widget _remarksReadOnly(AppLocalizations l10n) {
    final text =
        _remarksController.text.trim().isEmpty
            ? '—'
            : _remarksController.text.trim();
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
    InventoryCountingDocModel doc,
  ) {
    const header = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
    const txt = TextStyle(fontSize: 11);

    String fmtVar(num? v) {
      if (v == null) return '—';
      if (v == 0) return '0';
      if (v > 0) return '+$v';
      return v.toString();
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
            for (var i = 0; i < 7; i++) i: const IntrinsicColumnWidth(),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                _CntHeaderCell('#', style: header),
                _CntHeaderCell('itemCode', style: header),
                _CntHeaderCell('itemName', style: header),
                _CntHeaderCell(l10n.inventoryColWarehouse, style: header),
                _CntHeaderCell(l10n.inventoryColUom, style: header),
                _CntHeaderCell(l10n.inventoryColCountedQty, style: header),
                _CntHeaderCell(l10n.inventoryColVariance, style: header),
              ],
            ),
            ...doc.lines.asMap().entries.map((e) {
              final line = e.value;
              final lineNo = line.lineNumber ?? e.key + 1;
              final counted = line.countedQuantity;
              final varFromApi = line.variance;
              return TableRow(
                children: [
                  _CntBodyCell(Text('$lineNo', style: txt)),
                  _CntBodyCell(Text(line.itemCode, style: txt)),
                  _CntBodyCell(Text(line.itemName ?? '—', style: txt)),
                  _CntBodyCell(Text(line.warehouseCode, style: txt)),
                  _CntBodyCell(
                    Text(
                      (line.uoMCode != null && line.uoMCode!.trim().isNotEmpty)
                          ? line.uoMCode!.trim()
                          : '—',
                      style: txt,
                    ),
                  ),
                  _CntBodyCell(Text(counted?.toString() ?? '—', style: txt)),
                  _CntBodyCell(Text(fmtVar(varFromApi), style: txt)),
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
                _CntHeaderCell('#', style: header),
                _CntHeaderCell('itemCode', style: header),
                _CntHeaderCell('itemName', style: header),
                _CntHeaderCell(l10n.inventoryColWarehouse, style: header),
                _CntHeaderCell(l10n.inventoryColVariance, style: header),
                _CntHeaderCell(l10n.inventoryColCountedQty, style: header),
                _CntHeaderCell(l10n.inventoryColUom, style: header),
                _CntHeaderCell('', style: header),
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
                  _CntBodyCell(Text('${i + 1}', style: txt)),
                  _CntBodyCell(Text(line.itemCode, style: txt)),
                  _CntBodyCell(
                    Text(line.itemName, style: txt, softWrap: true),
                  ),
                  _CntBodyCell(Text(_warehouse?.code ?? '—', style: txt)),
                  _CntBodyCell(
                    Text(
                      _varianceLabel(line.quantity, line.onHand),
                      style: txt,
                    ),
                  ),
                  _CntBodyCell(
                    _CountQtyEditCell(
                      key: ValueKey('cnt-$i-${line.itemCode}'),
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
                  _CntBodyCell(
                    rows.isEmpty
                        ? _UomCodeTextFieldCell(
                          key: ValueKey('uom-txt-$i-${line.itemCode}'),
                          hintText: l10n.inventoryColUom,
                          initialCode:
                              (line.uoMCode?.trim().isNotEmpty == true
                                      ? line.uoMCode
                                      : line.baseUnitOfMeasure)
                                  ?.trim() ??
                              '',
                          onChanged: (code) {
                            setState(() {
                              final l = _lines[i];
                              _lines = List<InventoryLineDraft>.from(_lines);
                              _lines[i] = l.copyWith(uoMCode: code);
                            });
                          },
                        )
                        : Material(
                          color: Colors.transparent,
                          child: SizedBox(
                            width: 112,
                            child: DropdownButtonHideUnderline(
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
                                          overflow: TextOverflow.ellipsis,
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
                                              overflow: TextOverflow.ellipsis,
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
                        ),
                  ),
                  _CntBodyCell(
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

/// UoM when ODBC returned no UoM rows — free-text code (POST uses [uoMCode] only).
class _UomCodeTextFieldCell extends StatefulWidget {
  const _UomCodeTextFieldCell({
    super.key,
    required this.initialCode,
    required this.onChanged,
    required this.hintText,
  });

  final String initialCode;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  State<_UomCodeTextFieldCell> createState() => _UomCodeTextFieldCellState();
}

class _UomCodeTextFieldCellState extends State<_UomCodeTextFieldCell> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCode);
  }

  @override
  void didUpdateWidget(covariant _UomCodeTextFieldCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCode != widget.initialCode &&
        widget.initialCode != _controller.text) {
      _controller.text = widget.initialCode;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const txt = TextStyle(fontSize: 11, color: AppColors.textPrimary);
    return SizedBox(
      width: 112,
      child: TextField(
        controller: _controller,
        style: txt,
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hintText,
          hintStyle: txt.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 6,
          ),
          border: const OutlineInputBorder(),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

class _CntHeaderCell extends StatelessWidget {
  const _CntHeaderCell(this.text, {required this.style});

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

class _CntBodyCell extends StatelessWidget {
  const _CntBodyCell(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: child,
    );
  }
}

class _CountQtyEditCell extends StatefulWidget {
  const _CountQtyEditCell({
    super.key,
    required this.quantity,
    required this.onChanged,
  });

  final num quantity;
  final ValueChanged<num> onChanged;

  @override
  State<_CountQtyEditCell> createState() => _CountQtyEditCellState();
}

class _CountQtyEditCellState extends State<_CountQtyEditCell> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.quantity.toString());
  }

  @override
  void didUpdateWidget(covariant _CountQtyEditCell oldWidget) {
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
