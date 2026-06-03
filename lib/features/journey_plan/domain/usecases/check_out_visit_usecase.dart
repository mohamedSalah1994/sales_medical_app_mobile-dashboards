import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/check_out_visit_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class CheckOutVisitParams {
  final String visitId;
  final CheckOutVisitRequestModel request;

  CheckOutVisitParams({
    required this.visitId,
    required this.request,
  });
}

class CheckOutVisitUseCase implements UseCase<void, CheckOutVisitParams> {
  CheckOutVisitUseCase({required this.repository});

  final JourneyPlanRepository repository;

  @override
  Future<void> call(CheckOutVisitParams params) async {
    return await repository.checkOutVisit(params.visitId, params.request);
  }
}
