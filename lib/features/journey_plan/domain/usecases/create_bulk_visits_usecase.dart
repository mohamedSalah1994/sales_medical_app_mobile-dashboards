import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/create_bulk_visits_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/create_bulk_visits_response_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class CreateBulkVisitsParams {
  final String journeyPlanId;
  final CreateBulkVisitsRequestModel request;

  CreateBulkVisitsParams({
    required this.journeyPlanId,
    required this.request,
  });
}

class CreateBulkVisitsUseCase
    implements UseCase<CreateBulkVisitsResponseModel, CreateBulkVisitsParams> {
  CreateBulkVisitsUseCase({required this.repository});

  final JourneyPlanRepository repository;

  @override
  Future<CreateBulkVisitsResponseModel> call(CreateBulkVisitsParams params) async {
    return await repository.createBulkVisits(
      params.journeyPlanId,
      params.request,
    );
  }
}
