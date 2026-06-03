import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/subordinates_response_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class GetSubordinatesUseCase {
  GetSubordinatesUseCase({required this.repository});

  final JourneyPlanRepository repository;

  Future<SubordinatesResponseModel> call(String userId) async {
    try {
      return await repository.getSubordinates(userId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
}
