import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/check_in_visit_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class CheckInVisitParams {
  final String visitId;
  final CheckInVisitRequestModel request;

  CheckInVisitParams({
    required this.visitId,
    required this.request,
  });
}

class CheckInVisitUseCase implements UseCase<void, CheckInVisitParams> {
  CheckInVisitUseCase({required this.repository});

  final JourneyPlanRepository repository;

  @override
  Future<void> call(CheckInVisitParams params) async {
    return await repository.checkInVisit(params.visitId, params.request);
  }
}
