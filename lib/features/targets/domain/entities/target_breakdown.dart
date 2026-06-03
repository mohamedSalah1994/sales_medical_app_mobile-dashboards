import 'package:sales_medical_app_mobile/features/targets/domain/entities/target_type.dart';
import 'package:sales_medical_app_mobile/features/targets/domain/entities/target_detail.dart';

class TargetBreakdown {
  final String id;
  final String targetTypeId;
  final TargetType targetType;
  final double value;
  final double achievedValue;
  final List<TargetDetail> details;
  final double detailsTotal;
  final double remainingAmount;
  final bool canHaveDetails;

  const TargetBreakdown({
    required this.id,
    required this.targetTypeId,
    required this.targetType,
    required this.value,
    required this.achievedValue,
    required this.details,
    required this.detailsTotal,
    required this.remainingAmount,
    required this.canHaveDetails,
  });
}
