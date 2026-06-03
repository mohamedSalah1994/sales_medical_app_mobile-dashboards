import 'package:flutter/material.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/reports/presentation/widgets/achievement_kpi_row.dart';

class VisitKpiRow extends StatelessWidget {
  const VisitKpiRow({
    super.key,
    required this.planned,
    required this.actual,
    required this.pct,
    required this.missed,
  });

  final int planned;
  final int actual;
  final double pct;
  final int missed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visits',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _VisitCard(
                  icon: Icons.event_outlined,
                  iconColor: AppColors.accent,
                  label: 'Planned',
                  value: '$planned',
                ),
                const SizedBox(width: 8),
                _VisitCard(
                  icon: Icons.event_available_outlined,
                  iconColor: AppColors.success,
                  label: 'Actual',
                  value: '$actual',
                ),
                const SizedBox(width: 8),
                _VisitCard(
                  icon: Icons.percent_rounded,
                  iconColor: achievementColor(pct),
                  label: 'Achievement',
                  value: fmtPct(pct),
                  valueColor: achievementColor(pct),
                ),
                const SizedBox(width: 8),
                _VisitCard(
                  icon: Icons.event_busy_outlined,
                  iconColor: AppColors.error,
                  label: 'Missed',
                  value: '$missed',
                  valueColor: AppColors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: DecoratedBox(
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
                      fontWeight: FontWeight.w800,
                      color: valueColor ?? AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
