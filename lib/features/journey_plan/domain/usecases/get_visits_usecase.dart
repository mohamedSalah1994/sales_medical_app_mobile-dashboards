import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/visits_response_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class GetVisitsParams {
  final String? userId;
  final String? customerId;
  final String? customerCode;
  final String? supervisorId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? status;
  final bool standaloneOnly;
  final int pageNumber;
  final int pageSize;

  GetVisitsParams({
    this.userId,
    this.customerId,
    this.customerCode,
    this.supervisorId,
    this.startDate,
    this.endDate,
    this.status,
    this.standaloneOnly = false,
    this.pageNumber = 1,
    this.pageSize = 20,
  });
}

class GetVisitsUseCase
    implements UseCase<VisitsResponseModel, GetVisitsParams> {
  GetVisitsUseCase({required this.repository});

  final JourneyPlanRepository repository;

  @override
  Future<VisitsResponseModel> call(GetVisitsParams params) async {
    return await repository.getVisits(
      userId: params.userId,
      customerId: params.customerId,
      customerCode: params.customerCode,
      supervisorId: params.supervisorId,
      startDate: params.startDate,
      endDate: params.endDate,
      status: params.status,
      standaloneOnly: params.standaloneOnly,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
    );
  }
}
