import 'package:dio/dio.dart';
import 'package:sales_medical_app_mobile/core/network/api_service.dart';
import 'package:sales_medical_app_mobile/features/dashboard/data/models/dashboard_models.dart';
import 'package:sales_medical_app_mobile/features/dashboard/data/models/sales_employee_home_models.dart';
import 'package:intl/intl.dart';

/// HTTP layer for /api/dashboard/*. One method per surface; force-refresh sends Cache-Control: no-cache.
class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._api);
  final ApiService _api;

  static final _dateFmt = DateFormat('yyyy-MM-dd');

  Future<SalesManagerDashboard> getSalesManager({
    DateTime? from,
    DateTime? to,
    String? areaCode,
    String? supervisorId,
    String? repId,
    bool forceRefresh = false,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/api/dashboard/sales-manager',
      queryParameters: {
        if (from != null) 'from': _dateFmt.format(from),
        if (to != null) 'to': _dateFmt.format(to),
        if (areaCode != null) 'areaCode': areaCode,
        if (supervisorId != null) 'supervisorId': supervisorId,
        if (repId != null) 'repId': repId,
      },
      options: forceRefresh ? _noCacheOptions() : null,
    );
    return SalesManagerDashboard.fromJson(res.data!);
  }

  Future<AreaManagerDashboard> getAreaManager({
    DateTime? date,
    String? areaCode,
    String? teamId,
    bool forceRefresh = false,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/api/dashboard/area-manager',
      queryParameters: {
        if (date != null) 'date': _dateFmt.format(date),
        if (areaCode != null) 'areaCode': areaCode,
        if (teamId != null) 'teamId': teamId,
      },
      options: forceRefresh ? _noCacheOptions() : null,
    );
    return AreaManagerDashboard.fromJson(res.data!);
  }

  Future<SalesEmployeeHome> getSalesEmployeeHome({
    DateTime? date,
    String? userId,
    bool forceRefresh = false,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/api/dashboard/sales-employee/home',
      queryParameters: {
        if (date != null) 'date': _dateFmt.format(date),
        if (userId != null) 'userId': userId,
      },
      options: forceRefresh ? _noCacheOptions() : null,
    );
    return SalesEmployeeHome.fromJson(res.data!);
  }

  Future<List<LiveRep>> getTeamLive({String? areaCode}) async {
    final res = await _api.get<List<dynamic>>(
      '/api/dashboard/team-live',
      queryParameters: {if (areaCode != null) 'areaCode': areaCode},
    );
    return (res.data ?? const [])
        .map((e) => LiveRep.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AlertItem>> getAlerts({String? scope, int take = 8}) async {
    final res = await _api.get<List<dynamic>>(
      '/api/dashboard/alerts',
      queryParameters: {
        if (scope != null) 'scope': scope,
        'take': take,
      },
    );
    return (res.data ?? const [])
        .map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Options _noCacheOptions() => Options(headers: {'Cache-Control': 'no-cache'});
}
