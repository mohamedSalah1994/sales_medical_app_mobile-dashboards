import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/journey_plan.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class UpdateJourneyPlanUseCase {
  UpdateJourneyPlanUseCase({required this.repository});

  final JourneyPlanRepository repository;

  Future<JourneyPlan> call(String journeyPlanId, JourneyPlan journeyPlan) async {
    return await repository.updateJourneyPlan(journeyPlanId, journeyPlan);
  }
}
