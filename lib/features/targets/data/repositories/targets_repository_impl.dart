import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/features/targets/data/datasources/targets_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/targets/data/models/targets_response_model.dart';
import 'package:sales_medical_app_mobile/features/targets/domain/repositories/targets_repository.dart';

class TargetsRepositoryImpl implements TargetsRepository {
  TargetsRepositoryImpl({required this.remoteDataSource});

  final TargetsRemoteDataSource remoteDataSource;

  @override
  Future<TargetsResponseModel> getTargets({
    String? userId,
    String? createdById,
    int? periodType,
    DateTime? startDate,
    DateTime? endDate,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      return await remoteDataSource.getTargets(
        userId: userId,
        createdById: createdById,
        periodType: periodType,
        startDate: startDate,
        endDate: endDate,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
}
