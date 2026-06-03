import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/supervisor_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class GetSupervisorsUseCase {
  GetSupervisorsUseCase({required this.repository});

  final JourneyPlanRepository repository;

  Future<List<SupervisorModel>> call() async {
    try {
      return await repository.getSupervisors();
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
}
