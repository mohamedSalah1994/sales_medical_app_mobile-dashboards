import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/journey_plan.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class CreateJourneyPlanUseCase implements UseCase<JourneyPlan, JourneyPlan> {
  CreateJourneyPlanUseCase({required this.repository});

  final JourneyPlanRepository repository;

  @override
  Future<JourneyPlan> call(JourneyPlan params) async {
    return await repository.createJourneyPlan(params);
  }
}
