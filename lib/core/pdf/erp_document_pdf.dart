import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Text safe for built-in PDF fonts (Helvetica): avoids Unicode punctuation
/// that often renders as blank (e.g. U+2014 em dash used in the app UI).
String erpPdfSafeText(String? value) {
  if (value == null) return '';
  return value
      .replaceAll('\u2014', '-') // em dash
      .replaceAll('\u2013', '-') // en dash
      .replaceAll('\u00A0', ' '); // nbsp
}

/// One label / value pair rendered as a screen-style outlined field on the PDF.
class ErpPdfField {
  const ErpPdfField({required this.label, required this.value});

  final String label;
  final String value;
}

/// Column metadata for the lines table on the PDF (mirrors the on-screen
/// `Table` columns in each transaction page). [flex] is used to weight column
/// widths via `pw.Table.fromTextArray` width spec.
class ErpPdfColumn {
  const ErpPdfColumn({required this.label, this.flex = 1, this.alignment});

  final String label;
  final int flex;
  final pw.Alignment? alignment;
}

/// Builds a screen-styled PDF document for an ERP transaction (sales order,
/// delivery, return, inventory transfer / counting, incoming payment).
///
/// Visual language mirrors the in-app cards:
/// - White card "header" with `Doc number XXXX` (bold) and a status pill on
///   the right (red brand tint, matching `AppColors.primary`).
/// - Outlined label/value field rows for the customer / warehouse / dates /
///   etc. (light grey fill + bordered, like `ErpDocFieldRow`).
/// - Lines table (zebra header, ruled body) — same column order the screen
///   uses.
/// - Remarks/comments block + Total field shown beneath, matching the new
///   on-screen layout.
///
/// Use [shareErpDocumentPdf] to share/print the produced bytes.
class ErpDocumentPdfBuilder {
  ErpDocumentPdfBuilder({
    required this.title,
    required this.docNum,
    this.docEntry,
    this.statusLabel,
    this.headerFields = const [],
    this.linesColumns = const [],
    this.linesRows = const [],
    this.linesSectionTitle = 'Lines',
    this.remarks,
    this.alwaysShowRemarksRow = false,
    this.remarksPdfLabel = 'Remarks (Optional)',
    this.totalLabel,
    this.totalValue,
    this.footerNote,
  });

  /// Title rendered top-left (e.g. "Sales Order", "Delivery", "Inventory transfer").
  final String title;
  final String? docNum;
  final int? docEntry;

  /// Optional short status (e.g. `Open`, `Close`). Rendered as a red brand pill.
  final String? statusLabel;

  /// Header label/value rows mirroring the screen header card.
  final List<ErpPdfField> headerFields;

  final List<ErpPdfColumn> linesColumns;
  final List<List<String>> linesRows;

  /// Heading above the lines table (e.g. `Order Lines` on sales order screen).
  final String linesSectionTitle;

  /// Multi-line remarks/comments shown under the lines table.
  final String? remarks;

  /// When true, always render the remarks row (uses [remarksPdfLabel]).
  final bool alwaysShowRemarksRow;

  /// Label for the remarks block (sales order uses optional wording; payment uses `Remarks`).
  final String remarksPdfLabel;

  /// Total label + value shown directly below remarks (e.g. "Total"). Provide
  /// [totalLabel] to enable the row.
  final String? totalLabel;
  final String? totalValue;

  /// Optional small line printed at the very bottom (e.g. generated date).
  final String? footerNote;

  // Brand palette (mirrors core/theme/app_colors.dart so the PDF matches the
  // app chrome). Kept in sync manually — these values are the authoritative
  // brand red / surface tones.
  static const PdfColor _brand = PdfColor.fromInt(0xFFC41C20);
  static const PdfColor _border = PdfColor.fromInt(0xFFE4E4E7);
  static const PdfColor _surface = PdfColor.fromInt(0xFFF4F4F5);
  static const PdfColor _textPrimary = PdfColor.fromInt(0xFF18181B);
  static const PdfColor _textSecondary = PdfColor.fromInt(0xFF71717A);
  static const PdfColor _zebraHeader = PdfColor.fromInt(0xFFF8FAFC);

  /// Status chip: light tint of brand red (~8% on white), matching mobile.
  static const PdfColor _statusPillBg = PdfColor(253 / 255, 242 / 255, 242 / 255);
  static const PdfColor _statusPillBorder =
      PdfColor(214 / 255, 164 / 255, 166 / 255);

  Future<Uint8List> build() async {
    final logo = await loadAppLogo();
    final pdf = pw.Document();

    // Use pdf package default fonts (Helvetica) — avoids the `printing` plugin,
    // which requires native registration and caused MissingPluginException for
    // sharePdf on some installs.
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(20, 24, 20, 24),
        header: (context) => _buildPageHeader(context, logo: logo),
        footer: (context) => _buildPageFooter(context),
        build: (context) {
          return [
            _buildHeaderCard(),
            pw.SizedBox(height: 12),
            if (linesColumns.isNotEmpty) ...[
              _buildSectionLabel(linesSectionTitle),
              pw.SizedBox(height: 6),
              _buildLinesTable(),
              pw.SizedBox(height: 12),
            ],
            if (alwaysShowRemarksRow ||
                (remarks != null && remarks!.trim().isNotEmpty) ||
                (totalLabel != null && totalValue != null)) ...[
              _buildBottomFields(),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ---------- Page chrome ----------

  pw.Widget _buildPageHeader(pw.Context context, {pw.MemoryImage? logo}) {
    if (context.pageNumber == 1) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _border, width: 1)),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: _brand,
                ),
              ),
            ),
            if (logo != null)
              pw.Image(
                logo,
                height: 40,
                fit: pw.BoxFit.contain,
              ),
          ],
        ),
      );
    }
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Text(
              '$title - page ${context.pageNumber}/${context.pagesCount}',
              style: pw.TextStyle(
                fontSize: 10,
                color: _textSecondary,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          if (logo != null)
            pw.Image(
              logo,
              height: 22,
              fit: pw.BoxFit.contain,
            ),
        ],
      ),
    );
  }

  pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        footerNote != null && footerNote!.isNotEmpty
            ? '${footerNote!}  |  page ${context.pageNumber}/${context.pagesCount}'
            : 'page ${context.pageNumber}/${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: _textSecondary),
      ),
    );
  }

  // ---------- Header card ----------

  pw.Widget _buildHeaderCard() {
    final docNumText = docNum?.trim().isNotEmpty == true ? docNum! : '-';
    final entryLabel =
        docEntry != null ? ' (Doc entry $docEntry)' : '';

    final statusText = erpPdfSafeText(statusLabel?.trim());
    final showPill = statusText.isNotEmpty;

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _border, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(
                  child: pw.RichText(
                    text: pw.TextSpan(
                      style: const pw.TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        color: _textPrimary,
                      ),
                      children: [
                        const pw.TextSpan(text: 'Doc number '),
                        pw.TextSpan(
                          text: docNumText,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        if (entryLabel.isNotEmpty)
                          pw.TextSpan(
                            text: entryLabel,
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (showPill) ...[
                  pw.SizedBox(width: 8),
                  _buildStatusPill(statusText),
                ],
              ],
            ),
          ),
          if (headerFields.isNotEmpty) ...[
            pw.Container(height: 1, color: _border),
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: _buildHeaderFieldGrid(),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildStatusPill(String label) {
    return pw.Container(
      constraints: const pw.BoxConstraints(maxWidth: 120),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: pw.BoxDecoration(
        color: _statusPillBg,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _statusPillBorder, width: 0.5),
      ),
      child: pw.Text(
        label,
        textAlign: pw.TextAlign.center,
        maxLines: 2,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: _brand,
          height: 1.15,
        ),
      ),
    );
  }

  pw.Widget _buildHeaderFieldGrid() {
    // Two columns on each row (mirrors the 'Doc date' / 'Due date' pair on
    // screen). Single full-width row when an odd field exists.
    final rows = <pw.Widget>[];
    for (var i = 0; i < headerFields.length; i += 2) {
      final left = headerFields[i];
      final right = i + 1 < headerFields.length ? headerFields[i + 1] : null;
      rows.add(
        pw.Padding(
          padding: pw.EdgeInsets.only(top: i == 0 ? 0 : 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _buildFieldRow(left)),
              if (right != null) ...[
                pw.SizedBox(width: 8),
                pw.Expanded(child: _buildFieldRow(right)),
              ],
            ],
          ),
        ),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  pw.Widget _buildFieldRow(ErpPdfField field, {PdfColor? fillColor}) {
    final display =
        field.value.isEmpty ? '-' : erpPdfSafeText(field.value);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: fillColor ?? _surface,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _border, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            erpPdfSafeText(field.label),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.normal,
              color: _textSecondary,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            display,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: _textPrimary,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Lines table ----------

  pw.Widget _buildLinesTable() {
    final totalFlex = linesColumns.fold<int>(0, (a, c) => a + c.flex);
    final widths = <int, pw.TableColumnWidth>{
      for (var i = 0; i < linesColumns.length; i++)
        i: pw.FlexColumnWidth(linesColumns[i].flex.toDouble() / totalFlex),
    };

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: widths,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _zebraHeader),
          children: [
            for (final c in linesColumns)
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  erpPdfSafeText(c.label),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _textPrimary,
                  ),
                  textAlign: _textAlignFor(c.alignment),
                ),
              ),
          ],
        ),
        for (final row in linesRows)
          pw.TableRow(
            children: [
              for (var i = 0; i < linesColumns.length; i++)
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    erpPdfSafeText(i < row.length ? row[i] : ''),
                    style: const pw.TextStyle(fontSize: 10, color: _textPrimary),
                    textAlign: _textAlignFor(linesColumns[i].alignment),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  pw.TextAlign _textAlignFor(pw.Alignment? a) {
    if (a == pw.Alignment.centerRight ||
        a == pw.Alignment.topRight ||
        a == pw.Alignment.bottomRight) {
      return pw.TextAlign.right;
    }
    if (a == pw.Alignment.center ||
        a == pw.Alignment.topCenter ||
        a == pw.Alignment.bottomCenter) {
      return pw.TextAlign.center;
    }
    return pw.TextAlign.left;
  }

  // ---------- Bottom (remarks + total) ----------

  pw.Widget _buildBottomFields() {
    final widgets = <pw.Widget>[];
    final rem = remarks?.trim();
    if (alwaysShowRemarksRow ||
        (rem != null && rem.isNotEmpty)) {
      final value = (rem != null && rem.isNotEmpty)
          ? erpPdfSafeText(rem)
          : '-';
      widgets.add(
        _buildFieldRow(
          ErpPdfField(
            label: remarksPdfLabel,
            value: value,
          ),
          fillColor: PdfColors.white,
        ),
      );
    }
    if (totalLabel != null && totalValue != null) {
      if (widgets.isNotEmpty) widgets.add(pw.SizedBox(height: 8));
      widgets.add(
        _buildFieldRow(
          ErpPdfField(
            label: erpPdfSafeText(totalLabel!),
            value: erpPdfSafeText(totalValue!),
          ),
          fillColor: PdfColors.white,
        ),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  pw.Widget _buildSectionLabel(String label) {
    return pw.Text(
      erpPdfSafeText(label),
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: _textPrimary,
      ),
    );
  }
}

/// Loads the bundled DKT logo for PDF headers (`assets/images/DKT_Logo.png`).
Future<pw.MemoryImage?> loadAppLogo() async {
  try {
    final bytes = await rootBundle.load('assets/images/DKT_Logo.png');
    return pw.MemoryImage(bytes.buffer.asUint8List());
  } catch (_) {
    return null;
  }
}
