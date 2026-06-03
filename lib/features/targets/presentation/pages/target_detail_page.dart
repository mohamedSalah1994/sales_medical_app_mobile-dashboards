import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/targets/domain/entities/target.dart';
import 'package:sales_medical_app_mobile/features/targets/domain/entities/target_breakdown.dart';

class TargetDetailPage extends StatelessWidget {
  const TargetDetailPage({super.key, required this.target});

  final Target target;

  String _getPeriodTypeName(int periodType) {
    switch (periodType) {
      case 1:
        return 'Day';
      case 2:
        return 'Week';
      case 3:
        return 'Month';
      case 4:
        return 'Quarter';
      case 5:
        return 'Year';
      default:
        return 'Unknown';
    }
  }

  IconData _getPeriodTypeIcon(int periodType) {
    switch (periodType) {
      case 1:
        return Icons.today_outlined;
      case 2:
        return Icons.date_range_outlined;
      case 3:
        return Icons.calendar_month_outlined;
      case 4:
        return Icons.view_module_outlined;
      case 5:
        return Icons.event_note_outlined;
      default:
        return Icons.calendar_today;
    }
  }

  // Helper method to check if a breakdown is visit-related
  bool _isVisitBreakdown(TargetBreakdown breakdown) {
    final name = breakdown.targetType.name.toLowerCase();
    final code = breakdown.targetType.code.toLowerCase();
    return name.contains('visit') || code.contains('visit');
  }

  // Helper method to get effective achieved value for a breakdown
  // For visits, always use achievedValue - visits are always considered complete
  double _getEffectiveAchievedValue(TargetBreakdown breakdown) {
    if (_isVisitBreakdown(breakdown)) {
      // For visits, always use achievedValue regardless of details status
      // Visits should always be considered as completed
      return breakdown.achievedValue;
    }
    return breakdown.achievedValue;
  }

  @override
  Widget build(BuildContext context) {
    final totalValue = target.breakdowns.fold<double>(
      0.0,
      (double sum, TargetBreakdown breakdown) => sum + breakdown.value,
    );
    final totalAchieved = target.breakdowns.fold<double>(
      0.0,
      (double sum, TargetBreakdown breakdown) => 
          sum + _getEffectiveAchievedValue(breakdown),
    );
    final progress = totalValue > 0 ? totalAchieved / totalValue : 0.0;
    final progressPercent = (progress * 100).toStringAsFixed(1);
    final cardColor = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Target Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: cardColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cardColor.withValues(alpha: 0.05),
                      cardColor.withValues(alpha: 0.02),
                      Colors.white,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cardColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getPeriodTypeIcon(target.periodType),
                              color: cardColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (target.userName.isNotEmpty)
                                  Text(
                                    target.userName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_getPeriodTypeName(target.periodType)} Target',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Date Range
                      Row(
                        children: [
                          Expanded(
                            child: _DetailInfoItem(
                              icon: Icons.calendar_today_outlined,
                              label: 'Start Date',
                              value: DateFormat('MMM dd, yyyy').format(target.startDate),
                              iconColor: cardColor,
                            ),
                          ),
                          Container(width: 1, height: 40, color: AppColors.border),
                          Expanded(
                            child: _DetailInfoItem(
                              icon: Icons.event_outlined,
                              label: 'End Date',
                              value: DateFormat('MMM dd, yyyy').format(target.endDate),
                              iconColor: cardColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Progress
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: cardColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Overall Progress',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '$progressPercent%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: cardColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                backgroundColor: cardColor.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Achieved: ${totalAchieved.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  'Target: ${totalValue.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Breakdowns Section
            Text(
              'Breakdowns (${target.breakdowns.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 12),
            // Breakdowns List
            ...target.breakdowns.map((breakdown) {
              return _BreakdownCard(
                breakdown: breakdown,
                cardColor: cardColor,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DetailInfoItem extends StatelessWidget {
  const _DetailInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor ?? AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.breakdown,
    required this.cardColor,
  });

  final TargetBreakdown breakdown;
  final Color cardColor;

  // Helper method to check if a breakdown is visit-related
  bool _isVisitBreakdown(TargetBreakdown breakdown) {
    final name = breakdown.targetType.name.toLowerCase();
    final code = breakdown.targetType.code.toLowerCase();
    return name.contains('visit') || code.contains('visit');
  }

  // Helper method to get effective achieved value for a breakdown
  // For visits, always use achievedValue - visits are always considered complete
  double _getEffectiveAchievedValue(TargetBreakdown breakdown) {
    if (_isVisitBreakdown(breakdown)) {
      // For visits, always use achievedValue regardless of details status
      // Visits should always be considered as completed
      return breakdown.achievedValue;
    }
    return breakdown.achievedValue;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAchievedValue = _getEffectiveAchievedValue(breakdown);
    final progress = breakdown.value > 0
        ? effectiveAchievedValue / breakdown.value
        : 0.0;
    final progressPercent = (progress * 100).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: cardColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breakdown Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.category_outlined,
                      color: cardColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          breakdown.targetType.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (breakdown.targetType.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            breakdown.targetType.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: cardColor.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              // Progress Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Achieved: ${_getEffectiveAchievedValue(breakdown).toStringAsFixed(0)} / ${breakdown.value.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$progressPercent%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: cardColor,
                    ),
                  ),
                ],
              ),
              // Details Section (if available)
              if (breakdown.details.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: cardColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.list_outlined,
                            size: 16,
                            color: cardColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Details (${breakdown.details.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...breakdown.details.map((detail) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      detail.itemName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (detail.productCode.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Code: ${detail.productCode}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${detail.achievedValue.toStringAsFixed(0)} / ${detail.value.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${((detail.value > 0 ? detail.achievedValue / detail.value : 0) * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
