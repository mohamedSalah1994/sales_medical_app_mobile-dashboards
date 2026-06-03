import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class PauseVisitUseCase implements UseCase<void, String> {
  PauseVisitUseCase({required this.repository});

  final JourneyPlanRepository repository;

  @override
  Future<void> call(String visitId) async {
    return await repository.pauseVisit(visitId);
  }
}
