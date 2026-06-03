import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/create_visit_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class CreateVisitUseCase implements UseCase<Visit, CreateVisitRequestModel> {
  CreateVisitUseCase({required this.repository});

  final JourneyPlanRepository repository;

  @override
  Future<Visit> call(CreateVisitRequestModel params) async {
    return await repository.createVisit(params);
  }
}
