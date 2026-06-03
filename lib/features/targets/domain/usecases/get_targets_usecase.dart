import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/features/targets/data/models/targets_response_model.dart';
import 'package:sales_medical_app_mobile/features/targets/domain/repositories/targets_repository.dart';

class GetTargetsParams {
  const GetTargetsParams({
    this.userId,
    this.createdById,
    this.periodType,
    this.startDate,
    this.endDate,
    this.pageNumber = 1,
    this.pageSize = 20,
  });

  final String? userId;
  final String? createdById;
  final int? periodType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int pageNumber;
  final int pageSize;
}

class GetTargetsUseCase {
  GetTargetsUseCase({required this.repository});

  final TargetsRepository repository;

  Future<TargetsResponseModel> call(GetTargetsParams params) async {
    try {
      return await repository.getTargets(
        userId: params.userId,
        createdById: params.createdById,
        periodType: params.periodType,
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
