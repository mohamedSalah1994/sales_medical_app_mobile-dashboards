import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class DeleteJourneyPlanUseCase implements UseCase<void, String> {
  DeleteJourneyPlanUseCase({required this.repository});

  final JourneyPlanRepository repository;

  @override
  Future<void> call(String params) async {
    return await repository.deleteJourneyPlan(params);
  }
}
