import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/update_visit_supervisor_and_type_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class UpdateVisitSupervisorAndTypeParams {
  final String visitId;
  final UpdateVisitSupervisorAndTypeRequestModel request;

  UpdateVisitSupervisorAndTypeParams({
    required this.visitId,
    required this.request,
  });
}

class UpdateVisitSupervisorAndTypeUseCase
    implements UseCase<void, UpdateVisitSupervisorAndTypeParams> {
  UpdateVisitSupervisorAndTypeUseCase({required this.repository});

  final JourneyPlanRepository repository;

  @override
  Future<void> call(UpdateVisitSupervisorAndTypeParams params) async {
    return await repository.updateVisitSupervisorAndType(
      params.visitId,
      params.request,
    );
  }
}
