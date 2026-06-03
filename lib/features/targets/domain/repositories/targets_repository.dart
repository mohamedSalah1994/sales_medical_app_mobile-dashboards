import 'package:sales_medical_app_mobile/features/targets/data/models/targets_response_model.dart';

abstract class TargetsRepository {
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
