import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/pdf/erp_document_pdf.dart';
import 'package:sales_medical_app_mobile/core/utils/format_date.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/inventory_counting_models.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/inventory_transfer_models.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_list_item_model.dart';

/// Map a `bost_*` ERP document status to a short label (e.g. `Open`).
String _shortDocStatus(String? raw) {
  if (raw == null || raw.isEmpty) return '-';
  final s = raw.startsWith('bost_') ? raw.substring(5) : raw;
  return erpPdfSafeText(s);
}

String _formatNum(num? value) {
  if (value == null) return '-';
  return NumberFormat.decimalPattern().format(value);
}

String _trimmedOrDash(String? value) {
  final t = value?.trim() ?? '';
  return t.isEmpty ? '-' : erpPdfSafeText(t);
}

/// Standard line columns for sales order / delivery / return PDFs.
const List<ErpPdfColumn> _salesLinesColumns = [
  ErpPdfColumn(label: 'Line', flex: 5),
  ErpPdfColumn(label: 'Item', flex: 26),
  ErpPdfColumn(label: 'Qty', flex: 8),
  ErpPdfColumn(label: 'UoM', flex: 7),
  ErpPdfColumn(label: 'Unit price', flex: 12),
  ErpPdfColumn(label: 'Line total', flex: 12),
  ErpPdfColumn(label: 'Whse', flex: 8),
  ErpPdfColumn(label: 'Status', flex: 8),
];

List<List<String>> _salesLinesRows(List<SalesOrderListLineModel> lines) {
  return lines.asMap().entries.map((entry) {
    final i = entry.key;
    final line = entry.value;
    final lineNum = (line.lineNumber ?? i).toString();
    final itemTitle = [
      line.itemCode ?? '',
      line.itemName ?? '',
    ].where((p) => p.trim().isNotEmpty).join(' - ');
    return [
      lineNum,
      itemTitle.isEmpty ? '-' : erpPdfSafeText(itemTitle),
      _formatNum(line.quantity),
      line.unitOfMeasure?.trim().isNotEmpty == true ? line.unitOfMeasure!.trim() : '—',
      _formatNum(line.unitPrice),
      _formatNum(line.lineTotal),
      _trimmedOrDash(line.warehouseCode),
      _shortDocStatus(line.lineStatus),
    ];
  }).toList();
}

/// PDF builder for `SalesOrderListItemModel`-shaped documents (sales order,
/// delivery, return). Pass a [title] like `Sales Order`, `Delivery`, `Return`.
///
/// [remarksOverride] / [documentStatusOverride] should reflect the current form /
/// cubit state so the PDF matches the screen (ERP model alone can be stale).
ErpDocumentPdfBuilder buildSalesOrderShapedPdf({
  required String title,
  required SalesOrderListItemModel order,
  String? remarksOverride,
  String? documentStatusOverride,
}) {
  final mergedRemarks = () {
    final o = remarksOverride?.trim();
    if (o != null && o.isNotEmpty) return o;
    return order.remarks?.trim();
  }();

  final mergedStatus = documentStatusOverride ?? order.documentStatus;

  final headerFields = <ErpPdfField>[
    ErpPdfField(
      label: 'Customer',
      value: _trimmedOrDash(order.customerName),
    ),
    ErpPdfField(
      label: 'Card code',
      value: _trimmedOrDash(order.cardCode),
    ),
    if (order.distinctCustomerForeignName != null)
      ErpPdfField(
        label: 'Foreign name',
        value: erpPdfSafeText(order.distinctCustomerForeignName!),
      ),
    if (order.warehouseCode != null && order.warehouseCode!.trim().isNotEmpty)
      ErpPdfField(
        label: 'Warehouse',
        value: erpPdfSafeText(order.warehouseCode!.trim()),
      ),
    ErpPdfField(
      label: 'Doc date',
      value: erpPdfSafeText(formatIsoDateLocal(order.docDate)),
    ),
    ErpPdfField(
      label: 'Due date',
      value: erpPdfSafeText(formatIsoDateLocal(order.docDueDate)),
    ),
  ];

  return ErpDocumentPdfBuilder(
    title: title,
    docNum: order.docNum?.toString(),
    docEntry: order.docEntry,
    statusLabel: _shortDocStatus(mergedStatus),
    headerFields: headerFields,
    linesColumns: _salesLinesColumns,
    linesRows: _salesLinesRows(order.lines),
    linesSectionTitle: 'Order Lines',
    remarks: mergedRemarks,
    alwaysShowRemarksRow: true,
    totalLabel: 'Total',
    totalValue: _formatNum(order.docTotal),
    footerNote: '$title #${order.docNum ?? order.docEntry ?? ''}',
  );
}

/// PDF builder for an inventory transfer document. Mirrors the on-screen
/// `InventoryTransferDocumentHeader` (from / to warehouse, doc date) and the
/// transfer lines table.
ErpDocumentPdfBuilder buildInventoryTransferPdf({
  required InventoryTransferDocModel doc,
  String title = 'Inventory transfer',
}) {
  final headerFields = <ErpPdfField>[
    ErpPdfField(label: 'From warehouse', value: _trimmedOrDash(doc.fromWarehouse)),
    ErpPdfField(label: 'To warehouse', value: _trimmedOrDash(doc.toWarehouse)),
    ErpPdfField(label: 'Doc date', value: formatIsoDateLocal(doc.docDate)),
  ];

  const columns = [
    ErpPdfColumn(label: 'Line', flex: 5),
    ErpPdfColumn(label: 'Item', flex: 38),
    ErpPdfColumn(label: 'Qty', flex: 10),
    ErpPdfColumn(label: 'UoM', flex: 10),
  ];

  final rows = doc.lines.asMap().entries.map((e) {
    final i = e.key;
    final line = e.value;
    final lineNum = (line.lineNum ?? i).toString();
    final itemTitle = [
      line.itemCode,
      line.itemName ?? '',
    ].where((p) => p.trim().isNotEmpty).join(' - ');
    return [
      lineNum,
      itemTitle.isEmpty ? '-' : erpPdfSafeText(itemTitle),
      _formatNum(line.quantity),
      _trimmedOrDash(line.uoMCode),
    ];
  }).toList();

  return ErpDocumentPdfBuilder(
    title: title,
    docNum: doc.docNum.toString(),
    docEntry: doc.docEntry,
    statusLabel: _shortDocStatus(doc.documentStatus),
    headerFields: headerFields,
    linesColumns: columns,
    linesRows: rows,
    remarks: doc.comments?.trim(),
    alwaysShowRemarksRow: true,
    remarksPdfLabel: 'Notes (Optional)',
    footerNote: '$title #${doc.docNum}',
  );
}

/// PDF builder for an inventory counting document. Mirrors the on-screen
/// `InventoryCountingDocumentHeader` (count date + remarks) and the counting
/// lines table (warehouse, counted qty, variance).
ErpDocumentPdfBuilder buildInventoryCountingPdf({
  required InventoryCountingDocModel doc,
  String title = 'Inventory counting',
}) {
  final headerFields = <ErpPdfField>[
    ErpPdfField(label: 'Count date', value: formatIsoDateLocal(doc.countDate)),
  ];

  const columns = [
    ErpPdfColumn(label: 'Line', flex: 5),
    ErpPdfColumn(label: 'Item', flex: 32),
    ErpPdfColumn(label: 'Whse', flex: 10),
    ErpPdfColumn(label: 'Counted', flex: 10),
    ErpPdfColumn(label: 'UoM', flex: 8),
    ErpPdfColumn(label: 'Variance', flex: 10),
  ];

  final rows = doc.lines.asMap().entries.map((e) {
    final i = e.key;
    final line = e.value;
    final lineNum = (line.lineNumber ?? i).toString();
    final itemTitle = [
      line.itemCode,
      line.itemName ?? '',
    ].where((p) => p.trim().isNotEmpty).join(' - ');
    return [
      lineNum,
      itemTitle.isEmpty ? '-' : erpPdfSafeText(itemTitle),
      _trimmedOrDash(line.warehouseCode),
      _formatNum(line.countedQuantity),
      _trimmedOrDash(line.uoMCode),
      _formatNum(line.variance),
    ];
  }).toList();

  return ErpDocumentPdfBuilder(
    title: title,
    docNum: doc.documentNumber.toString(),
    docEntry: doc.documentEntry,
    statusLabel: _shortDocStatus(doc.documentStatus),
    headerFields: headerFields,
    linesColumns: columns,
    linesRows: rows,
    remarks: doc.remarks?.trim(),
    alwaysShowRemarksRow: true,
    remarksPdfLabel: 'Remarks',
    footerNote: '$title #${doc.documentNumber}',
  );
}
