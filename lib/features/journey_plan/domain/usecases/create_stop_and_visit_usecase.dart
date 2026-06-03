import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/create_stop_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/journey_plan.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class CreateStopAndVisitParams {
  final String journeyPlanId;
  final CreateStopRequestModel request;

  CreateStopAndVisitParams({
    required this.journeyPlanId,
    required this.request,
  });
}

class CreateStopAndVisitUseCase
    implements UseCase<JourneyPlan, CreateStopAndVisitParams> {
  CreateStopAndVisitUseCase({required this.repository});

  final JourneyPlanRepository repository;

  @override
  Future<JourneyPlan> call(CreateStopAndVisitParams params) async {
    return await repository.createStopAndVisit(
      params.journeyPlanId,
      params.request,
    );
  }
}
