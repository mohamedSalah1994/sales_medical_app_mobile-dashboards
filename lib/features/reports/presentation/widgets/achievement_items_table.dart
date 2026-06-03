import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/reports/data/models/target_achievement_model.dart';
import 'package:sales_medical_app_mobile/features/reports/presentation/widgets/achievement_kpi_row.dart';

class AchievementItemsTable extends StatelessWidget {
  const AchievementItemsTable({super.key, required this.items});

  final List<TargetAchievementItemModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No item breakdown available',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Item Breakdown',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              const Spacer(),
              _legend(),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in items) _ItemRow(item: item),
          _TotalRow(items: items),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _legend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(AppColors.success),
        const SizedBox(width: 3),
        const Text('≥100%', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        _dot(AppColors.warning),
        const SizedBox(width: 3),
        const Text('70–99%', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        _dot(AppColors.error),
        const SizedBox(width: 3),
        const Text('<70%', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _dot(Color c) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final TargetAchievementItemModel item;

  @override
  Widget build(BuildContext context) {
    final qtyColor = achievementColor(item.quantityPct);
    final valColor = achievementColor(item.valuePct);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.itemName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.itemCode,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${fmtQty(item.actualQuantity)} / ${fmtQty(item.targetQuantity)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: qtyColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fmtPct(item.quantityPct),
                          style: TextStyle(
                            color: qtyColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (item.quantityPct / 100).clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(qtyColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Value (EGP)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${NumberFormat('#,##0').format(item.actualValue)} / ${NumberFormat('#,##0').format(item.targetValue)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: valColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fmtPct(item.valuePct),
                          style: TextStyle(
                            color: valColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (item.valuePct / 100).clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(valColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.items});

  final List<TargetAchievementItemModel> items;

  @override
  Widget build(BuildContext context) {
    final totalTargetQty = items.fold(0.0, (s, e) => s + e.targetQuantity);
    final totalActualQty = items.fold(0.0, (s, e) => s + e.actualQuantity);
    final totalTargetVal = items.fold(0.0, (s, e) => s + e.targetValue);
    final totalActualVal = items.fold(0.0, (s, e) => s + e.actualValue);
    final qtyPct = totalTargetQty > 0
        ? (totalActualQty / totalTargetQty * 100).clamp(0, 9999).toDouble()
        : 0.0;
    final valPct = totalTargetVal > 0
        ? (totalActualVal / totalTargetVal * 100).clamp(0, 9999).toDouble()
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(
            'TOTAL',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.error,
                ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Qty: ${fmtPct(qtyPct)}',
                style: TextStyle(
                  color: achievementColor(qtyPct),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Text(
                'Val: ${fmtPct(valPct)}',
                style: TextStyle(
                  color: achievementColor(valPct),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
