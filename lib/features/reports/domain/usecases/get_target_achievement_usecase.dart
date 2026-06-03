import 'package:sales_medical_app_mobile/features/reports/data/models/target_achievement_model.dart';
import 'package:sales_medical_app_mobile/features/reports/domain/repositories/reports_repository.dart';

class GetTargetAchievementParams {
  const GetTargetAchievementParams({
    required this.userId,
    required this.userType,
    this.startDate,
    this.endDate,
  });

  final String userId;
  final String userType;
  final DateTime? startDate;
  final DateTime? endDate;
}

class GetTargetAchievementUseCase {
  GetTargetAchievementUseCase({required this.repository});

  final ReportsRepository repository;

  Future<TargetAchievementModel> call(GetTargetAchievementParams p) {
    return repository.getTargetAchievement(
      userId: p.userId,
      userType: p.userType,
      startDate: p.startDate,
      endDate: p.endDate,
    );
  }
}
