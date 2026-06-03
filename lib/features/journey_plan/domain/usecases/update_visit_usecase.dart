import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/update_visit_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class UpdateVisitParams {
  final String visitId;
  final UpdateVisitRequestModel request;

  UpdateVisitParams({
    required this.visitId,
    required this.request,
  });
}

class UpdateVisitUseCase implements UseCase<void, UpdateVisitParams> {
  UpdateVisitUseCase({required this.repository});

  final JourneyPlanRepository repository;

  @override
  Future<void> call(UpdateVisitParams params) async {
    return await repository.updateVisit(params.visitId, params.request);
  }
}
