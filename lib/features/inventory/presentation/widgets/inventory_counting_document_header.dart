import 'package:flutter/material.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/core/utils/format_date.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/inventory_counting_models.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/erp_document_header_widgets.dart';

/// ERP counting status e.g. `cdsOpen` → `Open`, `cdsClose` → `Close`.
String inventoryCountingStatusLabel(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '—';
  final s = raw.trim();
  final lower = s.toLowerCase();
  if (lower.startsWith('cds') && s.length > 3) {
    final rest = s.substring(3);
    if (rest.isEmpty) return s;
    return '${rest[0].toUpperCase()}${rest.substring(1).toLowerCase()}';
  }
  if (s.startsWith('bost_')) return s.substring(5);
  return s;
}

class InventoryCountingDocumentHeader extends StatelessWidget {
  const InventoryCountingDocumentHeader({super.key, required this.doc});

  final InventoryCountingDocModel doc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusLabel = inventoryCountingStatusLabel(doc.documentStatus);

    final wh =
        doc.lines.isEmpty
            ? '—'
            : doc.lines.map((l) => l.warehouseCode).toSet().length == 1
            ? doc.lines.first.warehouseCode
            : doc.lines.map((l) => l.warehouseCode).join(', ');

    return ErpDocHeaderShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ErpDocNumTotalStatusRow(
            docNum: doc.documentNumber.toString(),
            totalStr: '—',
            statusLabel: statusLabel,
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (doc.countDate != null &&
                    doc.countDate!.trim().isNotEmpty) ...[
                  ErpDocFieldRow(
                    label: l10n.inventoryCountDate,
                    value: formatIsoDateLocal(doc.countDate),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 10),
                ],
                ErpDocFieldRow(
                  label: l10n.inventoryColWarehouse,
                  value: wh,
                  maxLines: 2,
                ),
                if (doc.remarks != null && doc.remarks!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ErpDocFieldRow(
                    label: l10n.notesOptional,
                    value: doc.remarks!.trim(),
                    maxLines: 4,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
