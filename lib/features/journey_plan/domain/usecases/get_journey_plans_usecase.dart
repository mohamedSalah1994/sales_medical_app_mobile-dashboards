import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/journey_plans_response_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class GetJourneyPlansParams {
  const GetJourneyPlansParams({
    this.userId,
    this.createdById,
    this.supervisorId,
    this.customerId,
    this.planType,
    this.startDate,
    this.endDate,
    this.pageNumber = 1,
    this.pageSize = 20,
  });

  final String? userId;
  final String? createdById;
  final String? supervisorId;
  final String? customerId;
  final int? planType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int pageNumber;
  final int pageSize;
}

class GetJourneyPlansUseCase {
  GetJourneyPlansUseCase({required this.repository});

  final JourneyPlanRepository repository;

  Future<JourneyPlansResponseModel> call(GetJourneyPlansParams params) async {
    try {
      return await repository.getJourneyPlans(
        userId: params.userId,
        createdById: params.createdById,
        supervisorId: params.supervisorId,
        customerId: params.customerId,
        planType: params.planType,
        startDate: params.startDate,
        endDate: params.endDate,
        pageNumber: params.pageNumber,
        pageSize: params.pageSize,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
}
