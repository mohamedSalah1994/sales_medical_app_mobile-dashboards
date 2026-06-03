import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/start_visit_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class StartVisitParams {
  final String visitId;
  final StartVisitRequestModel request;

  StartVisitParams({
    required this.visitId,
    required this.request,
  });
}

class StartVisitUseCase implements UseCase<void, StartVisitParams> {
  StartVisitUseCase({required this.repository});

  final JourneyPlanRepository repository;

  @override
  Future<void> call(StartVisitParams params) async {
    return await repository.startVisit(params.visitId, params.request);
  }
}
