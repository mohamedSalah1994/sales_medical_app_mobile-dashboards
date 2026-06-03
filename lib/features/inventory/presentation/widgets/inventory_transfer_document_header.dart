import 'package:flutter/material.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/core/utils/format_date.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/inventory_transfer_models.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/erp_document_header_widgets.dart';

/// View header for inventory transfer (no customer / total on API).
class InventoryTransferDocumentHeader extends StatelessWidget {
  const InventoryTransferDocumentHeader({super.key, required this.doc});

  final InventoryTransferDocModel doc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rawStatus = doc.documentStatus ?? '—';
    final statusLabel =
        rawStatus.startsWith('bost_') ? rawStatus.substring(5) : rawStatus;

    return ErpDocHeaderShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ErpDocNumTotalStatusRow(
            docNum: doc.docNum.toString(),
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
                ErpDocFieldRow(
                  label: l10n.inventoryFromWarehouse,
                  value: doc.fromWarehouse,
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                ErpDocFieldRow(
                  label: l10n.inventoryToWarehouse,
                  value: doc.toWarehouse,
                  maxLines: 2,
                ),
                if (doc.docDate != null) ...[
                  const SizedBox(height: 10),
                  ErpDocFieldRow(
                    label: l10n.inventoryDocumentDate,
                    value: formatIsoDateLocal(doc.docDate),
                    maxLines: 4,
                  ),
                ],
                if (doc.comments != null && doc.comments!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ErpDocFieldRow(
                    label: l10n.notesOptional,
                    value: doc.comments!.trim(),
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
