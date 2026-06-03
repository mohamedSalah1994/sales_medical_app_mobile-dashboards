import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/update_stop_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/journey_plan.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class UpdateStopParams {
  final String journeyPlanId;
  final String stopId;
  final UpdateStopRequestModel request;

  UpdateStopParams({
    required this.journeyPlanId,
    required this.stopId,
    required this.request,
  });
}

class UpdateStopUseCase implements UseCase<JourneyPlan, UpdateStopParams> {
  UpdateStopUseCase({required this.repository});

  final JourneyPlanRepository repository;

  @override
  Future<JourneyPlan> call(UpdateStopParams params) async {
    return await repository.updateStop(
      params.journeyPlanId,
      params.stopId,
      params.request,
    );
  }
}
