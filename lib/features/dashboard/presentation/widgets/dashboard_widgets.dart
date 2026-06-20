import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/dashboard/data/models/dashboard_models.dart';

Color achievementColor(double pct) {
  if (pct >= 100) return AppColors.success;
  if (pct >= 70) return AppColors.warning;
  return AppColors.error;
}

class SparkLine extends StatelessWidget {
  const SparkLine({super.key, required this.points, this.height = 30, this.color, this.fill = true});
  final List<double> points;
  final double height;
  final Color? color;
  final bool fill;
  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return SizedBox(height: height);
    final isRtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final c = color ?? (points.last >= points.first ? AppColors.success : AppColors.error);
    return SizedBox(
      height: height,
      child: Transform.flip(
        flipX: isRtl,
        child: CustomPaint(painter: _SparkPainter(points, c, fill)),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.points, this.color, this.fill);
  final List<double> points;
  final Color color;
  final bool fill;
  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final maxV = points.reduce((a, b) => a > b ? a : b);
    final minV = points.reduce((a, b) => a < b ? a : b);
    final span = maxV - minV;
    final dx = size.width / (points.length - 1);
    double y(double v) =>
        span == 0 ? size.height / 2 : size.height - ((v - minV) / span) * size.height;
    final path = Path()..moveTo(0, y(points[0]));
    for (var i = 1; i < points.length; i++) {
      path.lineTo(i * dx, y(points[i]));
    }
    if (fill) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      final fp = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fp);
    }
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.points != points || old.color != color;
}

class ThresholdProgressBar extends StatelessWidget {
  const ThresholdProgressBar({super.key, required this.pct, this.height = 5});
  final double pct;
  final double height;
  @override
  Widget build(BuildContext context) {
    final c = achievementColor(pct);
    final clamped = (pct.clamp(0, 200) / 200).toDouble();
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(children: [
          Container(color: AppColors.border),
          FractionallySizedBox(
              widthFactor: clamped == 0 ? 0.0 : clamped, child: Container(color: c)),
        ]),
      ),
    );
  }
}

class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.label,
    required this.valueDisplay,
    this.deltaPct,
    this.deltaLabel,
    this.subtitle,
    this.iconColor,
    this.icon,
    this.spark,
    this.progressPct,
    this.background,
    this.compact = false,
  });

  final String label;
  final String valueDisplay;
  final double? deltaPct;
  final String? deltaLabel;
  final String? subtitle;
  final Color? iconColor;
  final IconData? icon;
  final List<double>? spark;
  final double? progressPct;
  final Color? background;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;
    final labelSize = compact ? 10.0 : 11.0;
    final valueSize = compact ? 15.0 : 18.0;
    final metaSize = compact ? 9.0 : 10.0;
    final iconSize = compact ? 12.0 : 14.0;
    final sparkHeight = compact ? 16.0 : 22.0;
    final pad = compact ? 8.0 : 10.0;

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: background ?? AppColors.card,
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            if (icon != null) ...[
              Container(
                padding: EdgeInsets.all(compact ? 4 : 5),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, size: iconSize, color: color),
              ),
              SizedBox(width: compact ? 4 : 6),
            ],
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  style: TextStyle(
                      fontSize: labelSize,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          SizedBox(height: compact ? 1 : 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(valueDisplay,
                maxLines: 1,
                style: TextStyle(fontSize: valueSize, fontWeight: FontWeight.w800)),
          ),
          if (subtitle != null)
            Text(subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: metaSize, color: AppColors.textSecondary)),
          if (deltaPct != null)
            Row(children: [
              Icon(deltaPct! >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: compact ? 10 : 11,
                  color: deltaPct! >= 0 ? AppColors.success : AppColors.error),
              Text('${deltaPct!.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: metaSize,
                      color: deltaPct! >= 0 ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 3),
              if (deltaLabel != null)
                Flexible(
                    child: Text(deltaLabel!,
                        maxLines: 1,
                        style: TextStyle(fontSize: metaSize, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis)),
            ]),
          if (spark != null && spark!.isNotEmpty) ...[
            SizedBox(height: compact ? 2 : 4),
            SparkLine(points: spark!, height: sparkHeight),
          ],
          if (progressPct != null) ...[
            SizedBox(height: compact ? 2 : 4),
            ThresholdProgressBar(pct: progressPct!, height: compact ? 4 : 5),
          ],
        ],
      ),
    );
  }
}

/// Fixed-height KPI grid that adapts tile height to screen width.
class DashboardMetricGrid extends StatelessWidget {
  const DashboardMetricGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.heightFactor = 0.82,
    this.minTileHeight = 96,
  });

  final List<Widget> children;
  final int crossAxisCount;
  final double heightFactor;
  final double minTileHeight;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    const horizontalPad = 12.0;
    const spacing = 8.0;
    final cellWidth =
        (width - horizontalPad * 2 - spacing * (crossAxisCount - 1)) /
        crossAxisCount;
    final tileHeight = (cellWidth * heightFactor).clamp(minTileHeight, 140.0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        mainAxisExtent: tileHeight,
      ),
      itemBuilder: (_, index) => children[index],
    );
  }
}

abstract final class DashboardButtons {
  static const double actionHeight = 34;

  static ButtonStyle compactFilled(Color background) => ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        minimumSize: const Size(0, actionHeight),
        fixedSize: const Size.fromHeight(actionHeight),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      );

  static final ButtonStyle compactOutlined = OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
    minimumSize: const Size(0, actionHeight),
    fixedSize: const Size.fromHeight(actionHeight),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
  );
}

/// Full-width dashboard action button with a fixed height so paired buttons match.
class DashboardActionButton extends StatelessWidget {
  const DashboardActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
    this.filledColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;
  final Color? filledColor;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 14);
    final labelWidget = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);

    return SizedBox(
      height: DashboardButtons.actionHeight,
      width: double.infinity,
      child:
          filled
              ? ElevatedButton.icon(
                onPressed: onPressed,
                style: DashboardButtons.compactFilled(
                  filledColor ?? AppColors.primary,
                ),
                icon: iconWidget,
                label: labelWidget,
              )
              : OutlinedButton.icon(
                onPressed: onPressed,
                style: DashboardButtons.compactOutlined,
                icon: iconWidget,
                label: labelWidget,
              ),
    );
  }
}

class DashFmt {
  DashFmt._();
  static final _money = NumberFormat('#,##0.00');
  static final _int = NumberFormat('#,##0');
  static final _time = DateFormat('hh:mm a');
  static String money(double v) => _money.format(v);
  static String compact(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  static String integer(int v) => _int.format(v);
  static String time(DateTime d) => _time.format(d.toLocal());
}

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.initials, this.size = 32, this.color});
  final String initials;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      alignment: Alignment.center,
      child: Text(initials,
          style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: size * 0.42)),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, this.action, required this.child});
  final String title;
  final Widget? action;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
            if (action != null) action!,
          ]),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

Widget alertSeverityIcon(DashboardAlertSeverity s) {
  switch (s) {
    case DashboardAlertSeverity.error:
      return const Icon(Icons.error_outline, size: 18, color: AppColors.error);
    case DashboardAlertSeverity.warning:
      return const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warning);
    case DashboardAlertSeverity.info:
      return const Icon(Icons.info_outline, size: 18, color: AppColors.accent);
  }
}

IconData activityIcon(ActivityKind k) {
  switch (k) {
    case ActivityKind.orderCreated:
      return Icons.shopping_cart_outlined;
    case ActivityKind.collectionAdded:
      return Icons.attach_money;
    case ActivityKind.visitCompleted:
      return Icons.check_circle_outline;
    case ActivityKind.surveySubmitted:
      return Icons.assignment_outlined;
    case ActivityKind.returnCreated:
      return Icons.assignment_return_outlined;
  }
}

class GreetingBanner extends StatelessWidget {
  const GreetingBanner({
    super.key,
    required this.greeting,
    required this.subtitle,
    required this.dateLabel,
  });
  final String greeting;
  final String subtitle;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('dkt',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 10)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Flexible(
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 10),
              const SizedBox(width: 4),
              Flexible(
                child: Text(dateLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ]),
          ),
          ),
        ],
      ),
    );
  }
}
