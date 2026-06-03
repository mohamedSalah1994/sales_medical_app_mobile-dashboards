import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:sales_medical_app_mobile/core/di/service_locator.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/create_delivery_request_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/create_return_from_delivery_request_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_list_item_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_cubit.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/erp_document_header_widgets.dart';
import 'package:sales_medical_app_mobile/core/pdf/erp_document_pdf_factories.dart';
import 'package:sales_medical_app_mobile/core/pdf/erp_document_pdf_share.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/helpers/register_visit_action_after_erp.dart';

/// Return document: create from delivery (POST …/from-delivery) or view existing
/// (GET /api/erp/returns/{docEntry}). Lines match API `lines[]` shape in the table.
class ReturnPage extends StatefulWidget {
  const ReturnPage.fromDelivery({
    super.key,
    required this.deliveryDocEntry,
    this.visitId,
  }) : returnDocEntry = null,
       prefetchedReturn = null;

  const ReturnPage.viewExisting({
    super.key,
    required this.returnDocEntry,
    this.prefetchedReturn,
  }) : deliveryDocEntry = null,
       visitId = null;

  final int? deliveryDocEntry;
  final int? returnDocEntry;

  /// When creating from a journey visit, sent on POST …/returns/from-delivery and for visit actions.
  final String? visitId;
  final SalesOrderListItemModel? prefetchedReturn;

  bool get isViewExisting => returnDocEntry != null;

  @override
  State<ReturnPage> createState() => _ReturnPageState();
}

class _ReturnPageState extends State<ReturnPage> {
  final _remarksController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime _returnDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  SalesOrderListItemModel? _order;
  List<_ReturnLineRow> _rows = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final id = widget.visitId;
      if (widget.deliveryDocEntry != null && id != null && id.isNotEmpty) {
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
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    if (widget.isViewExisting && widget.prefetchedReturn != null) {
      final order = widget.prefetchedReturn!;
      if (!mounted) return;
      setState(() {
        for (final row in _rows) {
          row.controller.dispose();
        }
        _order = order;
        _rows = const [];
        _remarksController.text = order.remarks ?? '';
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
        order = await cubit.getReturnByDocEntry(widget.returnDocEntry!);
      } else {
        order = await cubit.getDeliveryByDocEntry(widget.deliveryDocEntry!);
      }
      final rows =
          widget.isViewExisting
              ? <_ReturnLineRow>[]
              : _buildRowsFromDelivery(order);
      if (!mounted) return;
      setState(() {
        for (final row in _rows) {
          row.controller.dispose();
        }
        _order = order;
        _rows = rows;
        _remarksController.text = order.remarks ?? '';
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

  /// When [quantity] > [remainingOpenQuantity], treat line qty as open qty for UI/caps.
  static double _displayedDeliveredQty(SalesOrderListLineModel line) {
    final q = (line.quantity ?? 0).toDouble();
    final rem = line.remainingOpenQuantity?.toDouble();
    if (rem == null) return q < 0 ? 0 : q;
    if (q > rem) return rem < 0 ? 0 : rem;
    return q < 0 ? 0 : q;
  }

  /// Max return qty: never above [remainingOpenQuantity] when set; never above [quantity].
  static double _maxReturnableQty(SalesOrderListLineModel line) {
    final qty = (line.quantity ?? 0).toDouble();
    if (qty <= 0) return 0;
    final rem = line.remainingOpenQuantity?.toDouble();
    if (rem == null) return qty;
    final openCapped = rem > qty ? qty : rem;
    return openCapped < 0 ? 0 : openCapped;
  }

  List<_ReturnLineRow> _buildRowsFromDelivery(SalesOrderListItemModel order) {
    final rows = <_ReturnLineRow>[];
    for (var i = 0; i < order.lines.length; i++) {
      final line = order.lines[i];
      if (!line.isLineStatusOpen) continue;
      final baseLine = line.lineNumber ?? i;
      final maxQty = _maxReturnableQty(line);
      const defaultQty = 0.0;
      rows.add(
        _ReturnLineRow(
          line: line,
          baseLine: baseLine,
          quantity: defaultQty,
          maxQuantity: maxQty,
          controller: TextEditingController(text: defaultQty.toString()),
          returnBatchNumbers: null,
        ),
      );
    }
    return rows;
  }

  Future<void> _submitReturn() async {
    if (_order == null || widget.deliveryDocEntry == null) return;
    if (_rows.isEmpty) return;
    final validRows = _rows.where((r) => r.quantity > 0).toList();
    if (validRows.isEmpty) {
      showDialog<void>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Return'),
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
      if (!r.line.hasBatchNumbers) continue;
      final list = r.returnBatchNumbers;
      if (list == null || list.isEmpty) {
        showDialog<void>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Return'),
                content: Text(
                  'Line ${r.baseLine} (${r.line.itemCode ?? ''}) has batches on the delivery. '
                  'Use the Batches column to enter return quantities per batch.',
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
      final qty = r.quantity > r.maxQuantity ? r.maxQuantity : r.quantity;
      final sum = list.fold<double>(0, (a, e) => a + e.quantity.toDouble());
      if (sum > r.maxQuantity + 1e-6) {
        showDialog<void>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Return'),
                content: Text(
                  'Line ${r.baseLine}: total batch quantity ($sum) cannot exceed '
                  'the maximum returnable quantity (${r.maxQuantity}).',
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
      if ((sum - qty).abs() > 1e-5) {
        showDialog<void>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Return'),
                content: Text(
                  'Line ${r.baseLine}: return quantity (${qty.toString()}) must match '
                  'the sum of batch quantities (${sum.toString()}). Adjust the line or set batches again.',
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

      final visitId = context.read<SalesOrderCubit>().state.visitId?.trim();
      final request = CreateReturnFromDeliveryRequestModel(
        deliveryDocEntry: widget.deliveryDocEntry!,
        returnDate: _returnDate,
        remarks:
            _remarksController.text.trim().isEmpty
                ? _order!.remarks
                : _remarksController.text.trim(),
        reason:
            _reasonController.text.trim().isEmpty
                ? null
                : _reasonController.text.trim(),
        warehouseCode: headerWh,
        lines:
            validRows.map((r) {
              final lw = r.line.warehouseCode?.trim();
              final lineWh = (lw != null && lw.isNotEmpty) ? lw : whDefault;
              final qty =
                  r.quantity > r.maxQuantity ? r.maxQuantity : r.quantity;
              return CreateReturnFromDeliveryLineModel(
                baseLine: r.baseLine,
                quantity: qty,
                warehouseCode: lineWh,
                batchNumbers:
                    r.line.hasBatchNumbers &&
                            (r.returnBatchNumbers?.isNotEmpty ?? false)
                        ? r.returnBatchNumbers
                        : null,
              );
            }).toList(),
        visitId: (visitId != null && visitId.isNotEmpty) ? visitId : null,
      );
      final response = await context
          .read<SalesOrderCubit>()
          .createReturnFromDelivery(request);
      if (!mounted) return;
      if (!response.success) {
        setState(() => _isSubmitting = false);
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Return'),
                content: Text(
                  response.errorMessage ?? 'Failed to create return',
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
      final cubit = context.read<SalesOrderCubit>();
      var newDocEntry = int.tryParse(response.documentId ?? '');
      newDocEntry ??= int.tryParse(response.documentNumber ?? '');
      setState(() => _isSubmitting = false);
      final parts = <String>['Return created successfully.'];
      final docNum = response.documentNumber;
      if (docNum != null && docNum.isNotEmpty) {
        parts.add('Document number: $docNum');
      }
      final docId = response.documentId;
      if (docId != null && docId.isNotEmpty) {
        parts.add('Doc Entry: $docId');
      }
      if (!mounted) return;
      if (newDocEntry != null) {
        showDialog<void>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Return'),
                content: Text(parts.join(' ')),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder:
                              (_) => BlocProvider.value(
                                value: cubit,
                                child: ReturnPage.viewExisting(
                                  returnDocEntry: newDocEntry,
                                ),
                              ),
                        ),
                      );
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      } else {
        showDialog<void>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Return'),
                content: const Text(
                  'Return saved. Could not open document (missing doc entry).',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showDialog<void>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Return'),
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

  Future<void> _pickReturnDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _returnDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) return;
    setState(() {
      _returnDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
    });
  }

  static String _formatDateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  int? get _appBarDocEntry =>
      _order?.docEntry ?? widget.returnDocEntry ?? widget.deliveryDocEntry;

  Widget _headerCard(SalesOrderListItemModel order, {required bool viewOnly}) {
    return ErpSalesOrderListDocumentCard(
      order: order,
      extraFields:
          viewOnly
              ? const <Widget>[]
              : <Widget>[
                ErpDocFieldRow(
                  label: 'Delivery doc entry',
                  value: '${widget.deliveryDocEntry ?? '—'}',
                  maxLines: 1,
                ),
                ErpDocHeaderDatePickerField(
                  label: 'Return date',
                  onTap: _pickReturnDate,
                  valueText: _formatDateOnly(_returnDate),
                ),
              ],
    );
  }

  /// Table for GET /api/erp/returns/{docEntry} — columns match `lines[]` fields.
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
            for (var i = 0; i < 12; i++) i: const IntrinsicColumnWidth(),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                const _HeaderCell('#', style: header),
                const _HeaderCell('itemCode', style: header),
                const _HeaderCell('itemName', style: header),
                const _HeaderCell('Qty', style: header),
                const _HeaderCell('UoM', style: header),
                const _HeaderCell('Unit price', style: header),
                const _HeaderCell('Line total', style: header),
                const _HeaderCell('VAT grp.', style: header),
                const _HeaderCell('Warehouse', style: header),
                _HeaderCell(l10n.inventoryColOnHand, style: header),
                const _HeaderCell('Batches', style: header),
                const _HeaderCell('Status', style: header),
              ],
            ),
            ...order.lines.asMap().entries.map((e) {
              final line = e.value;
              final lineNo = line.lineNumber ?? e.key;
              final rawLs = line.lineStatus ?? '-';
              final lineStatus =
                  rawLs.startsWith('bost_') ? rawLs.substring(5) : rawLs;
              return TableRow(
                children: [
                  _BodyCell(Text('$lineNo', style: txt)),
                  _BodyCell(Text(line.itemCode ?? '—', style: txt)),
                  _BodyCell(Text(line.itemName ?? '—', style: txt)),
                  _BodyCell(Text(_fmtNum(line.quantity), style: txt)),
                  _BodyCell(Text(line.unitOfMeasure ?? '-', style: txt)),
                  _BodyCell(Text(_fmtNum(line.unitPrice), style: txt)),
                  _BodyCell(Text(_fmtNum(line.lineTotal), style: txt)),
                  _BodyCell(Text(line.vatGroup ?? '—', style: txt)),
                  _BodyCell(
                    Text(
                      (line.warehouseCode != null &&
                              line.warehouseCode!.trim().isNotEmpty)
                          ? line.warehouseCode!.trim()
                          : '—',
                      style: txt,
                    ),
                  ),
                  _BodyCell(
                    Text(
                      line.onHand != null ? line.onHand.toString() : '—',
                      style: txt,
                    ),
                  ),
                  _BodyCell(_buildReadOnlyBatchCell(line, txt)),
                  _BodyCell(Text(lineStatus, style: txt)),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  static String _batchSummaryReadOnly(SalesOrderListLineModel line) {
    final b = line.batchNumbers;
    if (b == null || b.isEmpty) return '—';
    return '${b.length}';
  }

  Widget _buildReadOnlyBatchCell(SalesOrderListLineModel line, TextStyle txt) {
    final b = line.batchNumbers;
    if (b == null || b.isEmpty) {
      return Text(_batchSummaryReadOnly(line), style: txt);
    }
    return InkWell(
      onTap: () => _showReturnBatchDetailsDialog(line),
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

  Future<void> _showReturnBatchDetailsDialog(
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
                      _returnBatchDialogHeaderCell('Batch'),
                      _returnBatchDialogHeaderCell('Qty'),
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

  static String _fmtNum(num? n) {
    if (n == null) return '—';
    return n.toString();
  }

  /// Editing return from delivery — same line keys where applicable.
  Widget _linesTableEditable(AppLocalizations l10n) {
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
                const _HeaderCell('#', style: header),
                const _HeaderCell('itemCode', style: header),
                const _HeaderCell('itemName', style: header),
                const _HeaderCell('Qty', style: header),
                const _HeaderCell('Return qty', style: header),
                const _HeaderCell('UoM', style: header),
                _HeaderCell(l10n.inventoryColOnHand, style: header),
                const _HeaderCell('Warehouse', style: header),
                const _HeaderCell('Batches', style: header),
              ],
            ),
            ...List.generate(_rows.length, (i) {
              final row = _rows[i];
              final shownQty = _displayedDeliveredQty(row.line);
              return TableRow(
                children: [
                  _BodyCell(Text('${row.baseLine}', style: txt)),
                  _BodyCell(Text(row.line.itemCode ?? '—', style: txt)),
                  _BodyCell(Text(row.line.itemName ?? '—', style: txt)),
                  _BodyCell(Text(_fmtNum(shownQty), style: txt)),
                  _BodyCell(
                    TextFormField(
                      controller: row.controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: txt,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        border: const OutlineInputBorder(),
                        hintText:
                            row.maxQuantity > 0
                                ? 'max ${_fmtNum(row.maxQuantity)}'
                                : null,
                        hintStyle: txt.copyWith(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onChanged: (v) {
                        final q = double.tryParse(v);
                        if (q == null || q < 0) return;
                        final cap = row.maxQuantity;
                        final safeQty = q > cap ? cap : q;
                        setState(() {
                          _rows[i] = row.copyWith(
                            quantity: safeQty,
                            returnBatchNumbersSpec:
                                row.line.hasBatchNumbers
                                    ? _ReturnBatchNumbersCopy.clear
                                    : _ReturnBatchNumbersCopy.inherit,
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
                  _BodyCell(
                    Text(
                      row.line.onHand != null
                          ? row.line.onHand.toString()
                          : '—',
                      style: txt,
                    ),
                  ),
                  _BodyCell(
                    Text(_returnWarehouseLabelForLine(row.line), style: txt),
                  ),
                  _BodyCell(
                    row.line.hasBatchNumbers
                        ? TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 0,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _openReturnBatchDialog(i),
                          child: Text(
                            _returnBatchButtonLabel(row),
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

  String _returnWarehouseLabelForLine(SalesOrderListLineModel line) {
    final lw = line.warehouseCode?.trim();
    if (lw != null && lw.isNotEmpty) return lw;
    final ow = _order?.warehouseCode?.trim();
    if (ow != null && ow.isNotEmpty) return ow;
    return '—';
  }

  String _returnBatchButtonLabel(_ReturnLineRow row) {
    if (!row.line.hasBatchNumbers) return '—';
    final list = row.returnBatchNumbers;
    if (list == null || list.isEmpty) return 'Set';
    final n = list.where((e) => e.quantity > 0).length;
    if (n == 0) return 'Set';
    return '$n batches';
  }

  String _returnQuantityFieldText(double q) {
    if (q == 0) return '0';
    if (q == q.roundToDouble()) return q.toInt().toString();
    return q.toString();
  }

  Future<void> _openReturnBatchDialog(int rowIndex) async {
    final row = _rows[rowIndex];
    final delivered = row.line.batchNumbers;
    if (delivered == null || delivered.isEmpty) return;

    if (row.maxQuantity <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing returnable on this line')),
      );
      return;
    }

    final initial = row.returnBatchNumbers;
    final result = await showDialog<List<DeliveryBatchQuantityEntry>?>(
      context: context,
      builder:
          (ctx) => _ReturnBatchEditorDialog(
            deliveredBatches: delivered,
            maxLineTotal: row.maxQuantity,
            initialAllocations: initial,
          ),
    );

    if (!mounted || result == null) return;

    final entries = result;
    final sum = entries.fold<double>(0, (a, e) => a + e.quantity.toDouble());

    setState(() {
      _rows[rowIndex] = row.copyWith(
        returnBatchNumbersSpec: _ReturnBatchNumbersCopy.replace,
        returnBatchNumbers:
            entries.isEmpty
                ? null
                : List<DeliveryBatchQuantityEntry>.from(entries),
        quantity: sum,
      );
      _rows[rowIndex].controller.text = _returnQuantityFieldText(sum);
      _rows[rowIndex].controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _rows[rowIndex].controller.text.length),
      );
    });
  }

  Widget _linesSection({required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lines',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

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
                    _headerCard(_order!, viewOnly: widget.isViewExisting),
                    const SizedBox(height: 16),
                    if (widget.isViewExisting)
                      _linesSection(child: _linesTableReadOnly(_order!, l10n))
                    else
                      _linesSection(child: _linesTableEditable(l10n)),
                    const SizedBox(height: 12),
                    if (widget.isViewExisting)
                      _remarksReadOnly(_order!)
                    else ...[
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Reason',
                          border: OutlineInputBorder(),
                        ),
                        minLines: 1,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _remarksController,
                        decoration: const InputDecoration(
                          labelText: 'Remarks',
                          border: OutlineInputBorder(),
                        ),
                        minLines: 1,
                        maxLines: 2,
                      ),
                    ],
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
              title: 'Return',
              docEntry: _appBarDocEntry,
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          floatingActionButton: _isLoading
              ? null
              : Builder(
                  builder: (_) {
                    final saveFab = widget.isViewExisting
                        ? null
                        : FloatingActionButton.extended(
                            heroTag: 'return-main-fab',
                            onPressed: _isSubmitting ? null : _submitReturn,
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            icon: _isSubmitting
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

                    final pdfFab = _order != null
                        ? FloatingActionButton.extended(
                            heroTag: 'return-pdf-fab',
                            tooltip: 'Export PDF',
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            elevation: 3,
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    shareErpDocumentPdf(
                                      context,
                                      builder: buildSalesOrderShapedPdf(
                                        title: 'Return',
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
      ),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}

enum _ReturnBatchNumbersCopy { inherit, clear, replace }

class _ReturnLineRow {
  const _ReturnLineRow({
    required this.line,
    required this.baseLine,
    required this.quantity,
    required this.maxQuantity,
    required this.controller,
    this.returnBatchNumbers,
  });

  final SalesOrderListLineModel line;
  final int baseLine;
  final double quantity;
  final double maxQuantity;
  final TextEditingController controller;

  /// Per-batch return quantities when the delivery line includes `batchNumbers`.
  final List<DeliveryBatchQuantityEntry>? returnBatchNumbers;

  _ReturnLineRow copyWith({
    double? quantity,
    TextEditingController? controller,
    _ReturnBatchNumbersCopy returnBatchNumbersSpec =
        _ReturnBatchNumbersCopy.inherit,
    List<DeliveryBatchQuantityEntry>? returnBatchNumbers,
  }) {
    final List<DeliveryBatchQuantityEntry>? nextBatches =
        switch (returnBatchNumbersSpec) {
          _ReturnBatchNumbersCopy.inherit => this.returnBatchNumbers,
          _ReturnBatchNumbersCopy.clear => null,
          _ReturnBatchNumbersCopy.replace => returnBatchNumbers,
        };
    return _ReturnLineRow(
      line: line,
      baseLine: baseLine,
      quantity: quantity ?? this.quantity,
      maxQuantity: maxQuantity,
      controller: controller ?? this.controller,
      returnBatchNumbers: nextBatches,
    );
  }
}

class _ReturnBatchEditorDialog extends StatefulWidget {
  const _ReturnBatchEditorDialog({
    required this.deliveredBatches,
    required this.maxLineTotal,
    this.initialAllocations,
  });

  final List<ErpLineBatchNumber> deliveredBatches;
  final double maxLineTotal;
  final List<DeliveryBatchQuantityEntry>? initialAllocations;

  @override
  State<_ReturnBatchEditorDialog> createState() =>
      _ReturnBatchEditorDialogState();
}

class _ReturnBatchEditorDialogState extends State<_ReturnBatchEditorDialog> {
  late final List<TextEditingController> _qtyControllers;

  @override
  void initState() {
    super.initState();
    final initial = <String, double>{};
    for (final e in widget.initialAllocations ?? const []) {
      initial[e.batchNumber] = e.quantity.toDouble();
    }
    _qtyControllers = [
      for (final b in widget.deliveredBatches)
        TextEditingController(
          text: _textForInitial(initial[b.batchNumber] ?? 0),
        ),
    ];
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
    for (var i = 0; i < widget.deliveredBatches.length; i++) {
      final raw = _qtyControllers[i].text.trim().replaceAll(',', '.');
      if (raw.isEmpty) continue;
      final v = double.tryParse(raw);
      if (v == null || v < 0) {
        _showValidation('Enter valid numbers for batch quantities.');
        return;
      }
      final avail = widget.deliveredBatches[i].quantity;
      if (v > avail + 1e-9) {
        _showValidation(
          'Quantity for batch "${widget.deliveredBatches[i].batchNumber}" cannot exceed '
          'delivered in this batch ($avail).',
        );
        return;
      }
      sum += v;
      if (v > 0) {
        out.add(
          DeliveryBatchQuantityEntry(
            batchNumber: widget.deliveredBatches[i].batchNumber,
            quantity: v,
          ),
        );
      }
    }
    if (sum > widget.maxLineTotal + 1e-9) {
      _showValidation(
        'Total batch quantity (${sum.toString()}) cannot exceed the maximum '
        'returnable quantity for this line (${widget.maxLineTotal.toString()}).',
      );
      return;
    }
    Navigator.of(context).pop<List<DeliveryBatchQuantityEntry>>(out);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Return batches'),
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
                  _returnBatchDialogHeaderCell('Batch'),
                  _returnBatchDialogHeaderCell('Delivered'),
                  _returnBatchDialogHeaderCell('Return qty'),
                ],
              ),
              ...List.generate(widget.deliveredBatches.length, (i) {
                final b = widget.deliveredBatches[i];
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
        TextButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

Widget _returnBatchDialogHeaderCell(String text) {
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
