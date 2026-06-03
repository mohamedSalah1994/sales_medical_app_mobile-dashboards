import 'package:flutter/material.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/reports/data/models/target_achievement_model.dart';
import 'package:sales_medical_app_mobile/features/reports/presentation/widgets/achievement_kpi_row.dart';

class TeamPerformanceTable extends StatelessWidget {
  const TeamPerformanceTable({
    super.key,
    required this.employees,
    required this.onTap,
  });

  final List<TargetAchievementEmployeeModel> employees;
  final void Function(TargetAchievementEmployeeModel employee) onTap;

  static const _palettes = [
    (bg: Color(0xFFE3F2FD), fg: Color(0xFF1565C0)),
    (bg: Color(0xFFE8F5E9), fg: Color(0xFF2E7D32)),
    (bg: Color(0xFFFFF3E0), fg: Color(0xFFE65100)),
    (bg: Color(0xFFF3E5F5), fg: Color(0xFF7B1FA2)),
    (bg: Color(0xFFE0F2F1), fg: Color(0xFF00695C)),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Team Performance',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              const Spacer(),
              Text(
                '${employees.length} members',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _Header(),
                const Divider(height: 1, color: AppColors.border),
                for (var i = 0; i < employees.length; i++) ...[
                  _EmployeeRow(
                    employee: employees[i],
                    index: i,
                    palette: _palettes[employees[i].fullName.hashCode.abs() %
                        _palettes.length],
                    onTap: () => onTap(employees[i]),
                  ),
                  if (i < employees.length - 1)
                    const Divider(height: 1, indent: 16, color: AppColors.border),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 40),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              'Name',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          _HeaderCell('Visit %'),
          _HeaderCell('Qty %'),
          _HeaderCell('Value %'),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({
    required this.employee,
    required this.index,
    required this.palette,
    required this.onTap,
  });

  final TargetAchievementEmployeeModel employee;
  final int index;
  final ({Color bg, Color fg}) palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.bg,
                shape: BoxShape.circle,
              ),
              child: Text(
                employee.initials.isNotEmpty ? employee.initials : '?',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: palette.fg,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.fullName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!employee.hasTarget)
                    Text(
                      'No target',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                ],
              ),
            ),
            _PctCell(employee.visitAchievementPct),
            _PctCell(employee.quantityAchievementPct),
            _PctCell(employee.valueAchievementPct),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PctCell extends StatelessWidget {
  const _PctCell(this.pct);

  final double pct;

  @override
  Widget build(BuildContext context) {
    final color = achievementColor(pct);
    return SizedBox(
      width: 52,
      child: Column(
        children: [
          Text(
            fmtPct(pct),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
