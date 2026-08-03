import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:sales_medical_app_mobile/core/di/service_locator.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/create_delivery_request_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/item_batch_quantity_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_list_item_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_cubit.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/return_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/erp_document_header_widgets.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/helpers/register_visit_action_after_erp.dart';
import 'package:sales_medical_app_mobile/core/pdf/erp_document_pdf_factories.dart';
import 'package:sales_medical_app_mobile/core/pdf/erp_document_pdf_share.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/erp_cancel_document_dialog.dart';

class DeliveryFromSalesOrderPage extends StatefulWidget {
  /// Copy from sales order → loads via GET sales-order, editable delivery form.
  const DeliveryFromSalesOrderPage({
    super.key,
    required this.salesOrderDocEntry,
    this.visitId,
  }) : existingDeliveryDocEntry = null,
       prefetchedDelivery = null;

  /// View an existing delivery (e.g. from deliveries list) → loads via GET delivery, read-only.
  /// Pass [prefetchedDelivery] to skip a second request when data was already loaded (e.g. search).
  const DeliveryFromSalesOrderPage.viewExisting({
    super.key,
    required this.existingDeliveryDocEntry,
    this.prefetchedDelivery,
  }) : salesOrderDocEntry = null,
       visitId = null;

  final int? salesOrderDocEntry;
  final int? existingDeliveryDocEntry;

  /// When creating from a journey visit, sent on POST /api/erp/deliveries and used for visit actions.
  final String? visitId;

  /// When set with [viewExisting], [getDeliveryByDocEntry] is not called again.
  final SalesOrderListItemModel? prefetchedDelivery;

  bool get isViewExisting => existingDeliveryDocEntry != null;

  @override
  State<DeliveryFromSalesOrderPage> createState() =>
      _DeliveryFromSalesOrderPageState();
}

class _DeliveryFromSalesOrderPageState
    extends State<DeliveryFromSalesOrderPage> {
  final _remarksController = TextEditingController();
  final _docEntrySearchController = TextEditingController();
  DateTime _deliveryDate = DateTime.now();
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isLoadingSearch = false;
  bool _showSearchBar = false;
  String? _error;
  String? _searchError;
  SalesOrderListItemModel? _order;
  List<_DeliveryLineRow> _rows = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final id = widget.visitId;
      if (!widget.isViewExisting && id != null && id.isNotEmpty) {
        context.read<SalesOrderCubit>().setVisitId(id);
      }
    });
    _loadOrder();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.controller.dispose();
    }
    _remarksController.dispose();
    _docEntrySearchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    if (widget.isViewExisting && widget.prefetchedDelivery != null) {
      final order = widget.prefetchedDelivery!;
      final rows = <_DeliveryLineRow>[];
      if (!mounted) return;
      setState(() {
        for (final row in _rows) {
          row.controller.dispose();
        }
        _order = order;
        _rows = rows;
        _remarksController.text = order.remarks ?? '';
        _deliveryDate = DateTime.now();
        _isLoading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final cubit = context.read<SalesOrderCubit>();
      final SalesOrderListItemModel order;
      if (widget.isViewExisting) {
        order = await cubit.getDeliveryByDocEntry(
          widget.existingDeliveryDocEntry!,
        );
      } else {
        order = await cubit.getSalesOrderByDocEntry(widget.salesOrderDocEntry!);
      }
      final rows =
          widget.isViewExisting ? <_DeliveryLineRow>[] : _buildRows(order);
      if (!mounted) return;
      setState(() {
        for (final row in _rows) {
          row.controller.dispose();
        }
        _order = order;
        _rows = rows;
        _remarksController.text = order.remarks ?? '';
        _deliveryDate = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _submitCopyToDelivery() async {
    if (_order == null || _rows.isEmpty) return;
    final validRows = _rows.where((r) => r.quantity > 0).toList();
    if (validRows.isEmpty) {
      showDialog<void>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Delivery'),
              content: const Text(
                'Please enter quantity > 0 for at least one line',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    for (final r in validRows) {
      if (!r.line.tracksBatches) continue;
      final maxOpen =
          (r.line.remainingOpenQuantity ?? r.line.quantity ?? 0).toDouble();
      final list = r.batchNumbers;
      if (list == null || list.isEmpty) {
        showDialog<void>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Delivery'),
                content: Text(
                  'Line ${r.baseLine} (${r.line.itemCode ?? ''}) tracks batches. '
                  'Use the Batches column to enter quantities per batch.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
        return;
      }
      final sum = list.fold<double>(0, (a, e) => a + e.quantity.toDouble());
      if (sum > maxOpen + 1e-6) {
        showDialog<void>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Delivery'),
                content: Text(
                  'Line ${r.baseLine}: total batch quantity ($sum) cannot exceed '
                  'open quantity ($maxOpen).',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
        return;
      }
      if ((sum - r.quantity).abs() > 1e-5) {
        showDialog<void>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Delivery'),
                content: Text(
                  'Line ${r.baseLine}: delivery quantity (${r.quantity}) must match '
                  'the sum of batch quantities ($sum). Adjust the line qty or set batches again.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final defaultWh =
          await sl<AuthRepository>().getStoredDefaultWarehouseCode();
      if (!mounted) return;
      final whDefault =
          (defaultWh != null && defaultWh.trim().isNotEmpty)
              ? defaultWh.trim()
              : null;
      final orderWh = _order!.warehouseCode?.trim();
      final headerWh =
          (orderWh != null && orderWh.isNotEmpty) ? orderWh : whDefault;

      final lines =
          validRows.map((r) {
            final lw = r.line.warehouseCode?.trim();
            final lineWh = (lw != null && lw.isNotEmpty) ? lw : whDefault;
            return CreateDeliveryLineModel(
              baseLine: r.baseLine,
              quantity: r.quantity,
              warehouseCode: lineWh,
              batchNumbers:
                  r.line.tracksBatches && (r.batchNumbers?.isNotEmpty ?? false)
                      ? r.batchNumbers
                      : null,
            );
          }).toList();

      final visitId = context.read<SalesOrderCubit>().state.visitId?.trim();
      final request = CreateDeliveryRequestModel(
        salesOrderDocEntry: _order!.docEntry ?? widget.salesOrderDocEntry!,
        deliveryDate: _deliveryDate,
        remarks:
            _remarksController.text.trim().isEmpty
                ? _order!.remarks
                : _remarksController.text.trim(),
        warehouseCode: headerWh,
        lines: lines,
        visitId: (visitId != null && visitId.isNotEmpty) ? visitId : null,
      );
      final response = await context.read<SalesOrderCubit>().createDelivery(
        request,
      );
      if (!mounted) return;
      if (!response.success) {
        setState(() => _isSubmitting = false);
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Delivery'),
                content: Text(
                  response.errorMessage ?? 'Failed to create delivery',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
        return;
      }
      final vid = visitId;
      if (vid != null && vid.isNotEmpty) {
        await registerVisitActionIfInJourneyContext(context, visitId: vid);
      }
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final parts = <String>['Delivery created successfully.'];
      final docNum = response.documentNumber;
      if (docNum != null && docNum.isNotEmpty) {
        parts.add('Document number: $docNum');
      }
      final docId = response.documentId;
      if (docId != null && docId.isNotEmpty) {
        parts.add('Doc Entry: $docId');
      }
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Delivery'),
              content: Text(parts.join(' ')),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showDialog<void>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Delivery'),
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  /// POST /api/erp/deliveries/{docEntry}/cancel for the loaded delivery doc.
  /// Pops back to the previous screen on success so the list refresh re-fetches.
  Future<void> _cancelDelivery() async {
    final docEntry = widget.existingDeliveryDocEntry ?? _order?.docEntry;
    if (docEntry == null) return;
    final cubit = context.read<SalesOrderCubit>();
    setState(() => _isSubmitting = true);
    final result = await showErpCancelDocumentDialog(
      context,
      documentLabel: 'Delivery',
      docNumberLabel: _order?.docNum?.toString(),
      action: () => cubit.cancelDeliveryByDocEntry(docEntry),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (result?.success == true) {
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  List<_DeliveryLineRow> _buildRows(SalesOrderListItemModel order) {
    final rows = <_DeliveryLineRow>[];
    for (var i = 0; i < order.lines.length; i++) {
      final line = order.lines[i];
      if (!line.isLineStatusOpen) continue;
      final baseLine = line.lineNumber ?? i;
      const defaultQty = 0.0;
      rows.add(
        _DeliveryLineRow(
          line: line,
          baseLine: baseLine,
          quantity: defaultQty,
          controller: TextEditingController(text: defaultQty.toString()),
        ),
      );
    }
    return rows;
  }

  Future<void> _onSearchDelivery() async {
    final raw = _docEntrySearchController.text.trim();
    final docEntry = int.tryParse(raw);
    if (docEntry == null) {
      setState(() => _searchError = 'Enter a valid Doc Entry (number)');
      return;
    }

    setState(() {
      _isLoadingSearch = true;
      _searchError = null;
    });
    try {
      final order = await context.read<SalesOrderCubit>().getDeliveryByDocEntry(
        docEntry,
      );
      if (!mounted) return;
      setState(() {
        for (final row in _rows) {
          row.controller.dispose();
        }
        _order = order;
        _rows = _buildRows(order);
        _remarksController.text = order.remarks ?? '';
        _isLoadingSearch = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSearch = false;
        _searchError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int? get _appBarDocEntry =>
      _order?.docEntry ??
      widget.existingDeliveryDocEntry ??
      widget.salesOrderDocEntry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final body =
        _error != null && !_isLoading
            ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
              ),
            )
            : _order == null && !_isLoading
            ? const SizedBox.shrink()
            : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_order != null) ...[
                    if (!widget.isViewExisting && _showSearchBar) ...[
                      _buildSearchBar(),
                      const SizedBox(height: 10),
                    ],
                    _headerCard(_order!, viewOnly: widget.isViewExisting),
                    const SizedBox(height: 12),
                    if (widget.isViewExisting)
                      _linesTableReadOnly(_order!, l10n)
                    else
                      _linesTable(l10n),
                    const SizedBox(height: 12),
                    if (widget.isViewExisting)
                      _remarksReadOnly(_order!)
                    else
                      TextFormField(
                        controller: _remarksController,
                        decoration: const InputDecoration(
                          labelText: 'Remarks',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        minLines: 1,
                        maxLines: 2,
                      ),
                    const SizedBox(height: 10),
                    ErpDocFieldRow(
                      label: 'Total',
                      value: erpDocumentTotalLabel(_order!.docTotal),
                      fillColor: Colors.white,
                    ),
                    SizedBox(height: widget.isViewExisting ? 24 : 90),
                  ],
                ],
              ),
            );

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: ErpDocHeaderAppBarTitle(
              title: 'Delivery',
              docEntry: _appBarDocEntry,
            ),
            actions: [
              if (widget.isViewExisting &&
                  widget.existingDeliveryDocEntry != null &&
                  _order != null &&
                  (_order!.documentStatus ?? '').trim() != 'bost_Close')
                TextButton.icon(
                  onPressed: () {
                    final de = widget.existingDeliveryDocEntry!;
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder:
                            (_) => BlocProvider.value(
                              value: context.read<SalesOrderCubit>(),
                              child: ReturnPage.fromDelivery(
                                deliveryDocEntry: de,
                              ),
                            ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.copy_all,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'Copy To',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (widget.isViewExisting &&
                  widget.existingDeliveryDocEntry != null &&
                  _order != null &&
                  (_order!.documentStatus ?? '').trim() == 'bost_Open')
                TextButton.icon(
                  onPressed: _isSubmitting ? null : _cancelDelivery,
                  icon: const Icon(
                    Icons.cancel_outlined,
                    size: 18,
                    color: AppColors.error,
                  ),
                  label: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (!widget.isViewExisting)
                IconButton(
                  icon: const Icon(Icons.search, size: 20),
                  onPressed: () {
                    setState(() {
                      _showSearchBar = !_showSearchBar;
                      if (!_showSearchBar) _searchError = null;
                    });
                  },
                ),
            ],
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          floatingActionButton:
              _isLoading
                  ? null
                  : Builder(
                    builder: (_) {
                      final saveFab =
                          widget.isViewExisting
                              ? null
                              : FloatingActionButton.extended(
                                heroTag: 'delivery-main-fab',
                                onPressed:
                                    _isSubmitting
                                        ? null
                                        : _submitCopyToDelivery,
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                icon:
                                    _isSubmitting
                                        ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Icon(Icons.save),
                                label: const Text('Save'),
                              );

                      final pdfFab =
                          _order != null
                              ? FloatingActionButton.extended(
                                heroTag: 'delivery-pdf-fab',
                                tooltip: 'Export PDF',
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                elevation: 3,
                                onPressed:
                                    _isSubmitting
                                        ? null
                                        : () {
                                          shareErpDocumentPdf(
                                            context,
                                            builder: buildSalesOrderShapedPdf(
                                              title: 'Delivery',
                                              order: _order!,
                                              remarksOverride:
                                                  _remarksController.text,
                                              documentStatusOverride:
                                                  _order!.documentStatus,
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
          body: _isLoading ? const SizedBox.expand() : body,
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ),
        if (_isSubmitting)
          Positioned.fill(
            child: Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _remarksReadOnly(SalesOrderListItemModel order) {
    final text =
        order.remarks?.trim().isEmpty == true ? '—' : (order.remarks ?? '—');
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Remarks',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _headerCard(SalesOrderListItemModel order, {required bool viewOnly}) {
    return ErpSalesOrderListDocumentCard(
      order: order,
      showTotalInHeader: false,
      extraFields:
          viewOnly
              ? const <Widget>[]
              : <Widget>[
                ErpDocHeaderDatePickerField(
                  label: 'Delivery date',
                  onTap: _pickDeliveryDate,
                  valueText: _formatDateTime(_deliveryDate),
                ),
              ],
    );
  }

  Widget _linesTableReadOnly(
    SalesOrderListItemModel order,
    AppLocalizations l10n,
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
            for (var i = 0; i < 11; i++) i: const IntrinsicColumnWidth(),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                const _HeaderCell('Line', style: header),
                const _HeaderCell('Item', style: header),
                const _HeaderCell('Barcode', style: header),
                const _HeaderCell('Qty', style: header),
                const _HeaderCell('Unit price', style: header),
                const _HeaderCell('Line total', style: header),
                const _HeaderCell('UoM', style: header),
                _HeaderCell(l10n.inventoryColOnHand, style: header),
                const _HeaderCell('Warehouse', style: header),
                const _HeaderCell('Status', style: header),
                const _HeaderCell('Batches', style: header),
              ],
            ),
            ...order.lines.asMap().entries.map((e) {
              final line = e.value;
              final baseLine = line.lineNumber ?? e.key;
              final rawLs = line.lineStatus ?? '-';
              final lineStatus =
                  rawLs.startsWith('bost_') ? rawLs.substring(5) : rawLs;
              return TableRow(
                children: [
                  _BodyCell(Text('$baseLine', style: txt)),
                  _BodyCell(
                    Text(
                      '${line.itemCode ?? '-'} - ${line.itemName ?? '-'}',
                      style: txt,
                    ),
                  ),
                  _BodyCell(Text(line.barcode ?? '-', style: txt)),
                  _BodyCell(Text((line.quantity ?? 0).toString(), style: txt)),
                  _BodyCell(Text((line.unitPrice ?? 0).toString(), style: txt)),
                  _BodyCell(Text((line.lineTotal ?? 0).toString(), style: txt)),
                  _BodyCell(Text(line.unitOfMeasure ?? '-', style: txt)),
                  _BodyCell(
                    Text(
                      line.onHand != null ? line.onHand.toString() : '—',
                      style: txt,
                    ),
                  ),
                  _BodyCell(
                    Text(
                      (line.warehouseCode != null &&
                              line.warehouseCode!.trim().isNotEmpty)
                          ? line.warehouseCode!.trim()
                          : '-',
                      style: txt,
                    ),
                  ),
                  _BodyCell(Text(lineStatus, style: txt)),
                  _BodyCell(_buildReadOnlyBatchCell(line, txt)),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _deliveryBatchesCellText(SalesOrderListLineModel line) {
    final b = line.batchNumbers;
    if (b != null && b.isNotEmpty) return '${b.length}';
    if (line.tracksBatches) return '0';
    return '—';
  }

  Widget _buildReadOnlyBatchCell(SalesOrderListLineModel line, TextStyle txt) {
    final b = line.batchNumbers;
    if (b == null || b.isEmpty) {
      return Text(_deliveryBatchesCellText(line), style: txt);
    }
    return InkWell(
      onTap: () => _showDeliveryBatchDetailsDialog(line),
      child: Text(
        '${b.length}',
        style: txt.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Future<void> _showDeliveryBatchDetailsDialog(
    SalesOrderListLineModel line,
  ) async {
    final b = line.batchNumbers;
    if (b == null || b.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Batch details'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder.all(color: AppColors.border),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade100),
                    children: [
                      _batchDialogHeaderCell('Batch'),
                      _batchDialogHeaderCell('Qty'),
                    ],
                  ),
                  ...b.map(
                    (e) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            e.batchNumber,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '${e.quantity}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _linesTable(AppLocalizations l10n) {
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
            for (var i = 0; i < 9; i++) i: const IntrinsicColumnWidth(),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                const _HeaderCell('BaseLine', style: header),
                const _HeaderCell('Item', style: header),
                const _HeaderCell('Barcode', style: header),
                const _HeaderCell('Open Qty', style: header),
                _HeaderCell(l10n.inventoryColOnHand, style: header),
                const _HeaderCell('Qty', style: header),
                const _HeaderCell('UoM', style: header),
                _HeaderCell('Warehouse', style: header),
                const _HeaderCell('Batches', style: header),
              ],
            ),
            ...List.generate(_rows.length, (i) {
              final row = _rows[i];
              final openQty =
                  (row.line.remainingOpenQuantity ?? row.line.quantity ?? 0)
                      .toDouble();
              return TableRow(
                children: [
                  _BodyCell(Text('${row.baseLine}', style: txt)),
                  _BodyCell(
                    Text(
                      '${row.line.itemCode ?? '-'} - ${row.line.itemName ?? '-'}',
                      style: txt,
                    ),
                  ),
                  _BodyCell(Text(row.line.barcode ?? '-', style: txt)),
                  _BodyCell(Text(openQty.toStringAsFixed(2), style: txt)),
                  _BodyCell(
                    Text(
                      row.line.onHand != null
                          ? row.line.onHand.toString()
                          : '—',
                      style: txt,
                    ),
                  ),
                  _BodyCell(
                    TextFormField(
                      controller: row.controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: txt,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        final q = double.tryParse(v);
                        if (q == null || q < 0) return;
                        final maxQty =
                            (row.line.remainingOpenQuantity ??
                                    row.line.quantity ??
                                    0)
                                .toDouble();
                        final safeQty = q > maxQty ? maxQty : q;
                        setState(() {
                          _rows[i] = row.copyWith(
                            quantity: safeQty,
                            batchNumbersSpec:
                                row.line.tracksBatches
                                    ? _BatchNumbersCopy.clear
                                    : _BatchNumbersCopy.inherit,
                          );
                          if (safeQty != q) {
                            _rows[i].controller.text = safeQty.toString();
                            _rows[i]
                                .controller
                                .selection = TextSelection.fromPosition(
                              TextPosition(
                                offset: _rows[i].controller.text.length,
                              ),
                            );
                          }
                        });
                      },
                    ),
                  ),
                  _BodyCell(Text(row.line.unitOfMeasure ?? '-', style: txt)),
                  _BodyCell(Text(_warehouseLabelForLine(row.line), style: txt)),
                  _BodyCell(
                    row.line.tracksBatches
                        ? TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 0,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _openBatchDialog(i),
                          child: Text(
                            _batchButtonLabel(row),
                            style: txt.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        : Text('—', style: txt),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _warehouseLabelForLine(SalesOrderListLineModel line) {
    final lw = line.warehouseCode?.trim();
    if (lw != null && lw.isNotEmpty) return lw;
    final ow = _order?.warehouseCode?.trim();
    if (ow != null && ow.isNotEmpty) return ow;
    return '-';
  }

  Future<String?> _warehouseCodeForBatchRequest(
    SalesOrderListLineModel line,
  ) async {
    final lw = line.warehouseCode?.trim();
    if (lw != null && lw.isNotEmpty) return lw;
    final ow = _order?.warehouseCode?.trim();
    if (ow != null && ow.isNotEmpty) return ow;
    final defaultWh =
        await sl<AuthRepository>().getStoredDefaultWarehouseCode();
    final d = defaultWh?.trim();
    if (d != null && d.isNotEmpty) return d;
    return null;
  }

  String _batchButtonLabel(_DeliveryLineRow row) {
    if (!row.line.tracksBatches) return '—';
    final list = row.batchNumbers;
    if (list == null || list.isEmpty) return 'Set';
    final n = list.where((e) => e.quantity > 0).length;
    if (n == 0) return 'Set';
    return '$n batches';
  }

  String _quantityFieldText(double q) {
    if (q == 0) return '0';
    if (q == q.roundToDouble()) return q.toInt().toString();
    return q.toString();
  }

  Future<void> _openBatchDialog(int rowIndex) async {
    final row = _rows[rowIndex];
    if (!row.line.tracksBatches) return;
    final code = row.line.itemCode?.trim();
    if (code == null || code.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item code is missing for this line')),
      );
      return;
    }

    final maxTotal =
        (row.line.remainingOpenQuantity ?? row.line.quantity ?? 0).toDouble();
    if (maxTotal <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No open quantity for this line')),
      );
      return;
    }

    final wh = await _warehouseCodeForBatchRequest(row.line);
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const AlertDialog(
            content: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Expanded(child: Text('Loading batches…')),
              ],
            ),
          ),
    );

    final cubit = context.read<SalesOrderCubit>();
    List<ItemBatchQuantityModel> batches;
    try {
      batches = await cubit.getItemBatchQuantities(
        itemCode: code,
        warehouseCode: wh,
      );
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      return;
    }

    if (mounted) Navigator.of(context).pop();

    if (!mounted) return;
    if (batches.isEmpty) {
      await showDialog<void>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Batches'),
              content: const Text(
                'No batch quantities were returned for this item and warehouse.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    final result = await showDialog<List<DeliveryBatchQuantityEntry>?>(
      context: context,
      builder:
          (ctx) => _BatchQuantitiesEditorDialog(
            batches: batches,
            maxTotal: maxTotal,
            initialAllocations: row.batchNumbers,
          ),
    );

    if (!mounted || result == null) return;

    final entries = result;
    final sum = entries.fold<double>(0, (a, e) => a + e.quantity.toDouble());

    setState(() {
      _rows[rowIndex] = row.copyWith(
        batchNumbersSpec: _BatchNumbersCopy.replace,
        batchNumbers:
            entries.isEmpty
                ? null
                : List<DeliveryBatchQuantityEntry>.from(entries),
        quantity: sum,
      );
      _rows[rowIndex].controller.text = _quantityFieldText(sum);
      _rows[rowIndex].controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _rows[rowIndex].controller.text.length),
      );
    });
  }

  Future<void> _pickDeliveryDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deliveryDate),
    );
    if (!mounted) return;
    final time = pickedTime ?? TimeOfDay.fromDateTime(_deliveryDate);
    setState(() {
      _deliveryDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatDateTime(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm';
  }

  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _docEntrySearchController,
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
                  onSubmitted: (_) => _onSearchDelivery(),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 40,
                width: 40,
                child: IconButton(
                  onPressed: _isLoadingSearch ? null : _onSearchDelivery,
                  icon:
                      _isLoadingSearch
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.search),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _showSearchBar = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
        ),
        if (_searchError != null) ...[
          const SizedBox(height: 6),
          Text(
            _searchError!,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

enum _BatchNumbersCopy { inherit, clear, replace }

class _DeliveryLineRow {
  const _DeliveryLineRow({
    required this.line,
    required this.baseLine,
    required this.quantity,
    required this.controller,
    this.batchNumbers,
  });

  final SalesOrderListLineModel line;
  final int baseLine;
  final double quantity;
  final TextEditingController controller;

  /// When [line.tracksBatches], filled from the batch dialog and sent on POST.
  final List<DeliveryBatchQuantityEntry>? batchNumbers;

  _DeliveryLineRow copyWith({
    double? quantity,
    TextEditingController? controller,
    _BatchNumbersCopy batchNumbersSpec = _BatchNumbersCopy.inherit,
    List<DeliveryBatchQuantityEntry>? batchNumbers,
  }) {
    final List<DeliveryBatchQuantityEntry>? nextBatches =
        switch (batchNumbersSpec) {
          _BatchNumbersCopy.inherit => this.batchNumbers,
          _BatchNumbersCopy.clear => null,
          _BatchNumbersCopy.replace => batchNumbers,
        };
    return _DeliveryLineRow(
      line: line,
      baseLine: baseLine,
      quantity: quantity ?? this.quantity,
      controller: controller ?? this.controller,
      batchNumbers: nextBatches,
    );
  }
}

class _BatchQuantitiesEditorDialog extends StatefulWidget {
  const _BatchQuantitiesEditorDialog({
    required this.batches,
    required this.maxTotal,
    this.initialAllocations,
  });

  final List<ItemBatchQuantityModel> batches;
  final double maxTotal;
  final List<DeliveryBatchQuantityEntry>? initialAllocations;

  @override
  State<_BatchQuantitiesEditorDialog> createState() =>
      _BatchQuantitiesEditorDialogState();
}

class _BatchQuantitiesEditorDialogState
    extends State<_BatchQuantitiesEditorDialog> {
  late final List<TextEditingController> _qtyControllers;

  @override
  void initState() {
    super.initState();
    final initial = <String, double>{};
    for (final e in widget.initialAllocations ?? const []) {
      initial[e.batchNumber] = e.quantity.toDouble();
    }
    _qtyControllers = [
      for (final b in widget.batches)
        TextEditingController(
          text: _textForInitial(initial[b.batchNumber] ?? 0),
        ),
    ];

    final hasAnyInitial = initial.values.any((v) => v > 0);
    if (!hasAnyInitial) {
      _distributeOpenQuantity();
    }
  }

  /// Distributes [widget.maxTotal] across batch fields without calling
  /// setState — safe to invoke from initState.
  void _distributeOpenQuantity() {
    var remaining = widget.maxTotal;
    for (var i = 0; i < widget.batches.length; i++) {
      final avail = widget.batches[i].quantity;
      final apply =
          remaining <= 0 ? 0.0 : (remaining >= avail ? avail : remaining);
      _qtyControllers[i].text = apply > 0 ? _textForInitial(apply) : '';
      remaining -= apply;
    }
  }

  static String _textForInitial(double q) {
    if (q <= 0) return '';
    if (q == q.roundToDouble()) return q.toInt().toString();
    return q.toString();
  }

  @override
  void dispose() {
    for (final c in _qtyControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _showValidation(String message) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _submit() {
    final out = <DeliveryBatchQuantityEntry>[];
    var sum = 0.0;
    for (var i = 0; i < widget.batches.length; i++) {
      final raw = _qtyControllers[i].text.trim().replaceAll(',', '.');
      if (raw.isEmpty) continue;
      final v = double.tryParse(raw);
      if (v == null || v < 0) {
        _showValidation('Enter valid numbers for batch quantities.');
        return;
      }
      final avail = widget.batches[i].quantity;
      if (v > avail + 1e-9) {
        _showValidation(
          'Quantity for batch "${widget.batches[i].batchNumber}" cannot exceed '
          'available ($avail).',
        );
        return;
      }
      sum += v;
      if (v > 0) {
        out.add(
          DeliveryBatchQuantityEntry(
            batchNumber: widget.batches[i].batchNumber,
            quantity: v,
          ),
        );
      }
    }
    if (sum > widget.maxTotal + 1e-9) {
      _showValidation(
        'Total batch quantity (${sum.toString()}) cannot exceed open quantity '
        '(${widget.maxTotal.toString()}).',
      );
      return;
    }
    Navigator.of(context).pop<List<DeliveryBatchQuantityEntry>>(out);
  }

  /// Auto-fills batch quantity fields with the line's open quantity,
  /// distributing first → last and capping each at the batch's available qty.
  void _setOpenQuantity() {
    _distributeOpenQuantity();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final openQtyLabel = _textForInitial(widget.maxTotal);
    return AlertDialog(
      title: Text(
        openQtyLabel.isEmpty ? 'Batches' : 'Batches (open qty: $openQtyLabel)',
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Table(
            border: TableBorder.all(color: AppColors.border),
            columnWidths: const {
              0: FlexColumnWidth(2.2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: [
                  _batchDialogHeaderCell('Batch'),
                  _batchDialogHeaderCell('Available'),
                  _batchDialogHeaderCell('Qty'),
                ],
              ),
              ...List.generate(widget.batches.length, (i) {
                final b = widget.batches[i];
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        b.batchNumber,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        b.quantity.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: TextField(
                        controller: _qtyControllers[i],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _setOpenQuantity, child: const Text('Set')),
        TextButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

Widget _batchDialogHeaderCell(String text) {
  return Padding(
    padding: const EdgeInsets.all(8),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
    ),
  );
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {required this.style});

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

class _BodyCell extends StatelessWidget {
  const _BodyCell(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: child,
    );
  }
}
