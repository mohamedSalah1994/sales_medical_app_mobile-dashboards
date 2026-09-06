import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/core/utils/format_date.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_list_item_model.dart';

/// List card badge for saved ERP rows: prefer document number, then doc entry.
String? erpListCardPrimaryDocLabel(int? docNum, int? docEntry) {
  if (docNum != null) return '#$docNum';
  if (docEntry != null) return '#$docEntry';
  return null;
}

/// App bar title: `Title (docEntry)` with entry in bold.
class ErpDocHeaderAppBarTitle extends StatelessWidget {
  const ErpDocHeaderAppBarTitle({
    super.key,
    required this.title,
    this.docEntry,
  });

  final String title;
  final int? docEntry;

  @override
  Widget build(BuildContext context) {
    if (docEntry == null) {
      return Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      );
    }
    final de = docEntry!;
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        children: [
          TextSpan(text: title),
          const TextSpan(
            text: ' (',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(
            text: '$de',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const TextSpan(
            text: ')',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// White card shell used for ERP document headers.
class ErpDocHeaderShell extends StatelessWidget {
  const ErpDocHeaderShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// `Doc number` + `Total` (regular labels, bold values) + status pill on the right.
///
/// Sales-order / delivery flows show the total as a separate field under the
/// remarks/comments section, so they pass [showTotalInline] = false to keep
/// the header to `Doc number` + status pill only. Inventory/payment flows keep
/// the inline total (default).
class ErpDocNumTotalStatusRow extends StatelessWidget {
  const ErpDocNumTotalStatusRow({
    super.key,
    required this.docNum,
    required this.totalStr,
    required this.statusLabel,
    this.showTotalInline = true,
  });

  final String docNum;
  final String totalStr;
  final String statusLabel;
  final bool showTotalInline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.25,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  const TextSpan(text: 'Doc number '),
                  TextSpan(
                    text: docNum,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (showTotalInline) ...[
                    const TextSpan(text: '  ·  '),
                    const TextSpan(text: 'Total '),
                    TextSpan(
                      text: totalStr,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 112),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.28),
              ),
            ),
            child: Text(
              statusLabel,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ErpDocFieldRow extends StatelessWidget {
  const ErpDocFieldRow({
    super.key,
    required this.label,
    required this.value,
    this.maxLines = 1,
    this.fillColor,
  });

  final String label;
  final String value;
  final int maxLines;

  /// Override the default fill (`AppColors.surface`). Sales-order / delivery
  /// pages pass `Colors.white` for the Total field rendered under remarks so
  /// it visually matches the white-background remarks input.
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: fillColor ?? AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.25,
        ),
        maxLines: maxLines,
        softWrap: true,
        overflow: maxLines <= 1 ? TextOverflow.ellipsis : TextOverflow.clip,
      ),
    );
  }
}

class ErpDocDatesFieldRow extends StatelessWidget {
  const ErpDocDatesFieldRow({
    super.key,
    required this.docDate,
    required this.dueDate,
  });

  final String docDate;
  final String dueDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ErpDocFieldRow(label: 'Doc date', value: docDate, maxLines: 4),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ErpDocFieldRow(label: 'Due date', value: dueDate, maxLines: 4),
        ),
      ],
    );
  }
}

/// Read-only header for sales-order-shaped API documents (order / delivery / return).
///
/// Set [showTotalInHeader] = false (sales order / delivery) to keep the header
/// to `Doc number` + status only and surface the total in a dedicated field
/// (rendered by the page next to / under the remarks section).
class ErpSalesOrderListDocumentCard extends StatelessWidget {
  const ErpSalesOrderListDocumentCard({
    super.key,
    required this.order,
    this.extraFields = const [],
    this.showTotalInHeader = true,
    this.dueDateEditable = false,
    this.draftDueDate,
    this.onDueDateTap,
  });

  final SalesOrderListItemModel order;
  final List<Widget> extraFields;
  final bool showTotalInHeader;

  /// When true and [onDueDateTap] is set, due date is shown as a tappable field.
  final bool dueDateEditable;
  final DateTime? draftDueDate;
  final VoidCallback? onDueDateTap;

  @override
  Widget build(BuildContext context) {
    final rawStatus = order.documentStatus ?? '—';
    final statusLabel =
        rawStatus.startsWith('bost_') ? rawStatus.substring(5) : rawStatus;
    final totalStr =
        order.docTotal != null
            ? NumberFormat.decimalPattern().format(order.docTotal)
            : '—';
    final cardCode =
        (order.cardCode != null && order.cardCode!.trim().isNotEmpty)
            ? order.cardCode!.trim()
            : '—';
    final customerName =
        (order.customerName != null && order.customerName!.trim().isNotEmpty)
            ? order.customerName!.trim()
            : '—';

    return ErpDocHeaderShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ErpDocNumTotalStatusRow(
            docNum: order.docNum?.toString() ?? '—',
            totalStr: totalStr,
            statusLabel: statusLabel,
            showTotalInline: showTotalInHeader,
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ErpDocFieldRow(
                  label: 'Customer',
                  value: customerName,
                  maxLines: 3,
                ),
                if (order.distinctCustomerForeignName != null) ...[
                  const SizedBox(height: 10),
                  ErpDocFieldRow(
                    label: 'Foreign name',
                    value: order.distinctCustomerForeignName!,
                    maxLines: 3,
                  ),
                ],
                const SizedBox(height: 10),
                ErpDocFieldRow(
                  label: 'Card code',
                  value: cardCode,
                  maxLines: 3,
                ),
                if (order.warehouseCode != null &&
                    order.warehouseCode!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ErpDocFieldRow(
                    label: 'Warehouse',
                    value: order.warehouseCode!.trim(),
                    maxLines: 3,
                  ),
                ],
                const SizedBox(height: 10),
                if (dueDateEditable && onDueDateTap != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ErpDocFieldRow(
                          label: 'Doc date',
                          value: formatIsoDateLocal(order.docDate),
                          maxLines: 4,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ErpDocHeaderDatePickerField(
                          label: 'Due date',
                          valueText:
                              draftDueDate != null
                                  ? DateFormat.yMMMd().format(
                                    draftDueDate!.toLocal(),
                                  )
                                  : formatIsoDateLocal(order.docDueDate),
                          onTap: onDueDateTap!,
                        ),
                      ),
                    ],
                  ),
                ] else
                  ErpDocDatesFieldRow(
                    docDate: formatIsoDateLocal(order.docDate),
                    dueDate: formatIsoDateLocal(order.docDueDate),
                  ),
                for (final w in extraFields) ...[const SizedBox(height: 10), w],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable date/time row inside an outlined field (e.g. delivery date).
class ErpDocHeaderDatePickerField extends StatelessWidget {
  const ErpDocHeaderDatePickerField({
    super.key,
    required this.label,
    required this.onTap,
    required this.valueText,
  });

  final String label;
  final VoidCallback onTap;
  final String valueText;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.28),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        isDense: true,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: AppColors.primary.withValues(alpha: 0.95),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    valueText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.edit_calendar_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Format a SalesOrderListItemModel-style document total for display.
///
/// Returns the localized decimal pattern (e.g. `1,234.56`) or `—` when the
/// underlying value is null. Used by sales order / delivery pages to render
/// the total as a field under the remarks section.
String erpDocumentTotalLabel(num? docTotal) {
  if (docTotal == null) return '—';
  return NumberFormat.decimalPattern().format(docTotal);
}

/// Short label for ERP `documentStatus` (e.g. `bost_Open` → `Open`).
String erpDocumentStatusShortLabel(String? documentStatus) {
  if (documentStatus == null || documentStatus.isEmpty) return '—';
  return documentStatus.startsWith('bost_')
      ? documentStatus.substring(5)
      : documentStatus;
}

/// List-card status chip — **Open** / **Close** colors only; card chrome unchanged.
class ErpListDocumentStatusPill extends StatelessWidget {
  const ErpListDocumentStatusPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final key = label.toLowerCase().trim();
    final isOpen = key == 'open';
    final isClose = key == 'close';

    late Color bg;
    late Color borderColor;
    late Color fg;

    if (isOpen) {
      bg = AppColors.success.withValues(alpha: 0.14);
      borderColor = AppColors.success.withValues(alpha: 0.5);
      fg = AppColors.success;
    } else if (isClose) {
      bg = AppColors.textSecondary.withValues(alpha: 0.10);
      borderColor = AppColors.textSecondary.withValues(alpha: 0.4);
      fg = AppColors.textSecondary;
    } else {
      bg = AppColors.surface;
      borderColor = AppColors.border;
      fg = AppColors.textPrimary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 10,
          color: fg,
          letterSpacing: 0.15,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Compact doc-number badge for ERP list cards (`#107`).
class ErpListDocNumberBadge extends StatelessWidget {
  const ErpListDocNumberBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          fontSize: 11,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Customer / Lead type chip for compact list cards.
class ErpListCardTypeBadge extends StatelessWidget {
  const ErpListCardTypeBadge({
    super.key,
    required this.label,
    required this.isLead,
  });

  final String label;
  final bool isLead;

  @override
  Widget build(BuildContext context) {
    final color = isLead ? AppColors.warning : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.15,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Outlined meta chip (e.g. Jovi) for compact ERP list cards.
class ErpListMetaChip extends StatelessWidget {
  const ErpListMetaChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Shared compact shell for sales-order / delivery / return / counting list cards.
class ErpDocumentListCard extends StatelessWidget {
  const ErpDocumentListCard({
    super.key,
    required this.onTap,
    this.docBadgeLabel,
    this.appIdBadgeText,
    this.showAppIdHint = false,
    this.docBesideLabel,
    required this.title,
    this.subtitle,
    this.statusLabel,
    this.trailingBadges = const [],
    this.metaLeading = const [],
    this.dateLabel,
    this.totalLabel,
    this.remarks,
    this.extraFooter,
  });

  final VoidCallback onTap;
  final String? docBadgeLabel;
  final String? appIdBadgeText;
  final bool showAppIdHint;
  /// Shown immediately beside the doc number (e.g. sales-order `U_ST`).
  final String? docBesideLabel;
  final String title;
  final String? subtitle;
  final String? statusLabel;
  final List<Widget> trailingBadges;
  final List<Widget> metaLeading;
  final String? dateLabel;
  final String? totalLabel;
  final String? remarks;
  final Widget? extraFooter;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width < 360;
    final titleSize = isNarrow ? 11.5 : 12.0;
    final metaSize = isNarrow ? 10.5 : 11.0;
    final gap = isNarrow ? 4.0 : 6.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 10 : 12,
            vertical: isNarrow ? 8 : 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doc # left — status / type flags flush right
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (docBadgeLabel != null)
                            ErpListDocNumberBadge(label: docBadgeLabel!)
                          else if (appIdBadgeText != null) ...[
                            ErpListDocNumberBadge(label: appIdBadgeText!),
                            if (showAppIdHint)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  'App',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                          ],
                          if (docBesideLabel != null &&
                              docBesideLabel!.trim().isNotEmpty)
                            ErpListMetaChip(label: docBesideLabel!.trim()),
                        ],
                      ),
                    ),
                  ),
                  if ((statusLabel != null && statusLabel!.isNotEmpty) ||
                      trailingBadges.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 4,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (statusLabel != null && statusLabel!.isNotEmpty)
                          ErpListDocumentStatusPill(label: statusLabel!),
                        ...trailingBadges,
                      ],
                    ),
                  ],
                ],
              ),
              SizedBox(height: gap),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: titleSize,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: metaSize,
                    color: AppColors.textSecondary,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (metaLeading.isNotEmpty ||
                  dateLabel != null ||
                  totalLabel != null) ...[
                SizedBox(height: gap),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ...metaLeading,
                          if (dateLabel != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dateLabel!,
                                  style: TextStyle(
                                    fontSize: metaSize,
                                    color: AppColors.textSecondary,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (totalLabel != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        totalLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: metaSize,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (extraFooter != null) ...[
                SizedBox(height: gap),
                extraFooter!,
              ],
              if (remarks != null && remarks!.trim().isNotEmpty) ...[
                SizedBox(height: gap),
                Text(
                  remarks!,
                  style: TextStyle(
                    fontSize: metaSize - 0.5,
                    color: AppColors.textSecondary,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
