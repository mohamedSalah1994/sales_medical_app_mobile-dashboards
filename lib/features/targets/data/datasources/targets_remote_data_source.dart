import 'package:sales_medical_app_mobile/core/network/api_service.dart';
import 'package:sales_medical_app_mobile/features/targets/data/models/targets_response_model.dart';

abstract class TargetsRemoteDataSource {
  Future<TargetsResponseModel> getTargets({
    String? userId,
    String? createdById,
    int? periodType,
    DateTime? startDate,
    DateTime? endDate,
    int pageNumber = 1,
    int pageSize = 20,
  });
}

class TargetsRemoteDataSourceImpl implements TargetsRemoteDataSource {
  TargetsRemoteDataSourceImpl({required this.apiService});

  final ApiService apiService;

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
    final queryParams = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };

    if (userId != null && userId.isNotEmpty) {
      queryParams['userId'] = userId;
    }
    if (createdById != null && createdById.isNotEmpty) {
      queryParams['createdById'] = createdById;
    }
    if (periodType != null) {
      queryParams['periodType'] = periodType;
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    final response = await apiService.get(
      '/api/Targets',
      queryParameters: queryParams,
    );

    return TargetsResponseModel.fromJson(response.data as Map<String, dynamic>);
  }
}
