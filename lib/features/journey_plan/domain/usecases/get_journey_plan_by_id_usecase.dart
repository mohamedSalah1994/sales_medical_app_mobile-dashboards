import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/journey_plan.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class GetJourneyPlanByIdUseCase {
  GetJourneyPlanByIdUseCase({required this.repository});

  final JourneyPlanRepository repository;

  Future<JourneyPlan> call(String journeyPlanId) async {
    return await repository.getJourneyPlanById(journeyPlanId);
  }
}
