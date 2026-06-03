import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';

Color achievementColor(double pct) {
  if (pct >= 100) return AppColors.success;
  if (pct >= 70) return AppColors.warning;
  return AppColors.error;
}

String fmtQty(double v) => NumberFormat('#,##0').format(v);
String fmtMoney(double v) => '${NumberFormat('#,##0.##').format(v)} EGP';
String fmtPct(double v) => '${NumberFormat('0.#').format(v)}%';

class AchievementKpiRow extends StatelessWidget {
  const AchievementKpiRow({
    super.key,
    required this.label,
    required this.target,
    required this.actual,
    required this.pct,
    this.isValue = false,
  });

  final String label;
  final double target;
  final double actual;
  final double pct;
  final bool isValue;

  @override
  Widget build(BuildContext context) {
    final color = achievementColor(pct);
    final pctClamped = (pct / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _MiniCard(
                  icon: Icons.track_changes_outlined,
                  iconColor: AppColors.accent,
                  label: 'Target',
                  value: isValue ? fmtMoney(target) : fmtQty(target),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniCard(
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.success,
                  label: 'Actual',
                  value: isValue ? fmtMoney(actual) : fmtQty(actual),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AchievementCard(
                  pct: pct,
                  color: color,
                  pctClamped: pctClamped,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.pct,
    required this.color,
    required this.pctClamped,
  });

  final double pct;
  final Color color;
  final double pctClamped;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.percent_rounded, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              'Achievement',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              fmtPct(pct),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pctClamped,
                minHeight: 4,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
