import 'dart:convert';

import 'package:sales_medical_app_mobile/core/network/api_service.dart';
import 'package:sales_medical_app_mobile/features/reports/data/models/erp_warehouse_model.dart';
import 'package:sales_medical_app_mobile/features/reports/data/models/stock_availability_model.dart';
import 'package:sales_medical_app_mobile/features/reports/data/models/target_achievement_model.dart';

abstract class ReportsRemoteDataSource {
  Future<List<StockAvailabilityModel>> getStockAvailability({
    required String warehouseCode,
    bool includeZeroOnHand = false,
  });

  Future<List<ErpWarehouseModel>> getErpWarehouses({
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

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  ReportsRemoteDataSourceImpl({required this.apiService});

  final ApiService apiService;

  @override
  Future<List<StockAvailabilityModel>> getStockAvailability({
    required String warehouseCode,
    bool includeZeroOnHand = false,
  }) async {
    final response = await apiService.get<dynamic>(
      '/api/Reports/stock-availability',
      queryParameters: <String, dynamic>{
        'warehouseCode': warehouseCode,
        'includeZeroOnHand': includeZeroOnHand,
      },
    );
    return _parseList(response.data)
        .map(StockAvailabilityModel.fromJson)
        .toList();
  }

  @override
  Future<List<ErpWarehouseModel>> getErpWarehouses({
    String? search,
    bool activeOnly = true,
    int skip = 0,
    int take = 20,
  }) async {
    final query = <String, dynamic>{
      'activeOnly': activeOnly,
      'skip': skip,
      'take': take,
    };
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final response = await apiService.get<dynamic>(
      '/api/Erp/warehouses',
      queryParameters: query,
    );
    return _parseList(response.data)
        .map(ErpWarehouseModel.fromJson)
        .toList();
  }

  @override
  Future<TargetAchievementModel> getTargetAchievement({
    required String userId,
    required String userType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = <String, dynamic>{
      'userId': userId.trim(),
      'userType': userType.trim(),
    };
    if (startDate != null) {
      query['startDate'] = startDate.toUtc().toIso8601String();
    }
    if (endDate != null) {
      query['endDate'] = endDate.toUtc().toIso8601String();
    }

    final response = await apiService.get<dynamic>(
      '/api/Reports/target-achievement',
      queryParameters: query,
    );

    dynamic data = response.data;
    if (data is String) {
      final t = data.trim();
      if (t.isEmpty) throw Exception('Invalid response format');
      data = jsonDecode(t);
    }
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return TargetAchievementModel.fromJson(data);
  }
}

/// The Reports endpoints declare `text/plain` content with a JSON body;
/// Dio sometimes returns a [String], sometimes a decoded [List].
List<Map<String, dynamic>> _parseList(dynamic data) {
  if (data == null) return const [];
  if (data is List) {
    return data
        .whereType<Object>()
        .map((e) {
          if (e is Map<String, dynamic>) return e;
          if (e is Map) return Map<String, dynamic>.from(e);
          return <String, dynamic>{};
        })
        .where((m) => m.isNotEmpty)
        .toList();
  }
  if (data is String) {
    final trimmed = data.trim();
    if (trimmed.isEmpty) return const [];
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) return _parseList(decoded);
    } catch (_) {}
  }
  return const [];
}
