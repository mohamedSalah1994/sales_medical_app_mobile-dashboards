import 'package:sales_medical_app_mobile/features/reports/data/models/target_achievement_model.dart';
import 'package:sales_medical_app_mobile/features/reports/domain/entities/erp_warehouse.dart';
import 'package:sales_medical_app_mobile/features/reports/domain/entities/stock_availability.dart';

abstract class ReportsRepository {
  /// GET /api/Reports/stock-availability — current on-hand / available quantities
  /// for a single warehouse. Sales reps always pass their default warehouse;
  /// admins / supervisors pick one via the warehouses dialog.
  Future<List<StockAvailability>> getStockAvailability({
    required String warehouseCode,
    bool includeZeroOnHand = false,
  });

  /// GET /api/Erp/warehouses — paginated warehouse list for the picker shown
  /// to admin / supervisor users.
  Future<List<ErpWarehouse>> getErpWarehouses({
    String? search,
    bool activeOnly = true,
    int skip = 0,
    int take = 20,
  });

  Future<TargetAchievementModel> getTargetAchievement({
    required String userId,
    required String userType,
    DateTime? startDate,
    DateTime? endDate,
  });
}
