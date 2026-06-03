import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/features/reports/data/datasources/reports_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/reports/data/models/target_achievement_model.dart';
import 'package:sales_medical_app_mobile/features/reports/domain/entities/erp_warehouse.dart';
import 'package:sales_medical_app_mobile/features/reports/domain/entities/stock_availability.dart';
import 'package:sales_medical_app_mobile/features/reports/domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl({required this.remoteDataSource});

  final ReportsRemoteDataSource remoteDataSource;

  @override
  Future<List<StockAvailability>> getStockAvailability({
    required String warehouseCode,
    bool includeZeroOnHand = false,
  }) async {
    try {
      return await remoteDataSource.getStockAvailability(
        warehouseCode: warehouseCode,
        includeZeroOnHand: includeZeroOnHand,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Future<List<ErpWarehouse>> getErpWarehouses({
    String? search,
    bool activeOnly = true,
    int skip = 0,
    int take = 20,
  }) async {
    try {
      return await remoteDataSource.getErpWarehouses(
        search: search,
        activeOnly: activeOnly,
        skip: skip,
        take: take,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Future<TargetAchievementModel> getTargetAchievement({
    required String userId,
    required String userType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await remoteDataSource.getTargetAchievement(
        userId: userId,
        userType: userType,
        startDate: startDate,
        endDate: endDate,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
