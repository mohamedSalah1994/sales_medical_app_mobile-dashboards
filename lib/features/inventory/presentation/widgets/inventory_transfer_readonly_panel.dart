import 'package:flutter/material.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/inventory_transfer_models.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/widgets/inventory_transfer_document_header.dart';

/// Header + lines table for a fetched transfer (list page inline result or reuse).
class InventoryTransferReadonlyPanel extends StatelessWidget {
  const InventoryTransferReadonlyPanel({
    super.key,
    required this.doc,
    this.onClear,
  });

  final InventoryTransferDocModel doc;
  final VoidCallback? onClear;

  static String _fmtNum(num? n) {
    if (n == null) return '—';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const header = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
    const txt = TextStyle(fontSize: 11);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onClear != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 18),
              label: Text(l10n.inventorySearchClearResult),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        InventoryTransferDocumentHeader(doc: doc),
        const SizedBox(height: 12),
        Text(
          l10n.details,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
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
                    _PanelHeaderCell('#', style: header),
                    _PanelHeaderCell('itemCode', style: header),
                    _PanelHeaderCell('itemName', style: header),
                    _PanelHeaderCell(l10n.inventoryColItemUnit, style: header),
                    _PanelHeaderCell(l10n.inventoryColOnHand, style: header),
                    _PanelHeaderCell(l10n.inventoryColQty, style: header),
                    _PanelHeaderCell(l10n.inventoryColUom, style: header),
                  ],
                ),
                ...doc.lines.asMap().entries.map((e) {
                  final line = e.value;
                  final lineNo = line.lineNum ?? e.key + 1;
                  return TableRow(
                    children: [
                      _PanelBodyCell(Text('$lineNo', style: txt)),
                      _PanelBodyCell(Text(line.itemCode, style: txt)),
                      _PanelBodyCell(Text(line.itemName ?? '—', style: txt)),
                      const _PanelBodyCell(Text('—', style: txt)),
                      const _PanelBodyCell(Text('—', style: txt)),
                      _PanelBodyCell(Text(_fmtNum(line.quantity), style: txt)),
                      _PanelBodyCell(
                        Text(
                          (line.uoMCode != null &&
                                  line.uoMCode!.trim().isNotEmpty)
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
        ),
      ],
    );
  }
}

class _PanelHeaderCell extends StatelessWidget {
  const _PanelHeaderCell(this.text, {required this.style});

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

class _PanelBodyCell extends StatelessWidget {
  const _PanelBodyCell(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: child,
    );
  }
}
