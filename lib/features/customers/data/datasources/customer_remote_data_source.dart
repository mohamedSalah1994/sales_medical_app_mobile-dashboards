import 'dart:convert';

import 'package:sales_medical_app_mobile/core/constants/customer_odbc_scope.dart';
import 'package:sales_medical_app_mobile/core/utils/odbc_customers_master_data_query.dart';
import 'package:sales_medical_app_mobile/features/customers/data/models/create_erp_customer_request_model.dart';
import 'package:sales_medical_app_mobile/features/customers/data/models/customer_series_model.dart';
import 'package:sales_medical_app_mobile/features/customers/data/models/duplicate_customer_phone_exception.dart';
import 'package:sales_medical_app_mobile/features/customers/data/models/master_data_option_model.dart';

abstract class CustomerRemoteDataSource {
  Future<Map<String, dynamic>> getCustomers({
    String? search,
    String? name,
    String? foreignName,
    String? forienName,
    String? area,
    String? zone,
    String? stateFilter,
    String? city,
    String? region,
    bool? activeOnly,
    int? salesEmployeeCode,
    int pageNumber = 1,
    int pageSize = 10,
    int scope = CustomerOdbcScope.all,
  });
  Future<List<CustomerSeriesModel>> getCustomerSeries();
  Future<Map<String, dynamic>> createCustomer(
    CreateErpCustomerRequestModel body,
  );
  Future<List<MasterDataOptionModel>> getAreas();
  Future<List<MasterDataOptionModel>> getAreaUdtZones(String area);
  Future<List<MasterDataOptionModel>> getAreaUdtStates(String zone);
  Future<List<MasterDataOptionModel>> getAreaUdtCities(String state);
  Future<List<MasterDataOptionModel>> getAreaUdtRegions(String city);
  Future<List<MasterDataOptionModel>> getCustomerTypes();
}

List<dynamic> _extractJsonList(dynamic raw) {
  if (raw is List<dynamic>) return raw;
  if (raw is Map<String, dynamic>) {
    if (raw['value'] is List) return raw['value'] as List<dynamic>;
    if (raw['items'] is List) return raw['items'] as List<dynamic>;
    if (raw['data'] is List) return raw['data'] as List<dynamic>;
  }
  return <dynamic>[];
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  CustomerRemoteDataSourceImpl({required this.apiService});

  final dynamic apiService;

  Future<List<MasterDataOptionModel>> _getCodeNameList(String path) async {
    final response = await apiService.get(path);
    if (response.statusCode != 200) {
      throw Exception('Failed to load master data');
    }
    final list = _extractJsonList(response.data);
    return list
        .whereType<Map<String, dynamic>>()
        .map(MasterDataOptionModel.fromJson)
        .toList();
  }

  Future<List<MasterDataOptionModel>> _getAreaUdtStringList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await apiService.get(
      path,
      queryParameters: queryParameters,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load area master data');
    }
    final list = _extractJsonList(response.data);
    return list
        .map((e) {
          if (e is String) {
            return MasterDataOptionModel.fromPlainString(e);
          }
          if (e is Map<String, dynamic>) {
            return MasterDataOptionModel.fromJson(e);
          }
          return MasterDataOptionModel.fromPlainString(e.toString());
        })
        .where((m) => m.name.isNotEmpty)
        .toList();
  }

  @override
  Future<List<CustomerSeriesModel>> getCustomerSeries() async {
    final response = await apiService.get('/api/Erp/customers/series');
    if (response.statusCode != 200)
      throw Exception('Failed to get customer series');
    final raw = response.data;
    final list = _extractJsonList(raw);
    return list
        .whereType<Map<String, dynamic>>()
        .map(CustomerSeriesModel.fromJson)
        .toList();
  }

  @override
  Future<Map<String, dynamic>> createCustomer(
    CreateErpCustomerRequestModel body,
  ) async {
    try {
      final response = await apiService.post(
        '/api/Erp/customers',
        data: body.toJson(),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create customer');
      }
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is List && data.isNotEmpty) {
        final first = data.first;
        if (first is Map<String, dynamic>) return first;
      }
      return <String, dynamic>{};
    } catch (e) {
      if (DuplicateCustomerPhoneException.isDuplicatePhoneError(e)) {
        throw DuplicateCustomerPhoneException.fromError(e);
      }
      rethrow;
    }
  }

  @override
  Future<List<MasterDataOptionModel>> getAreas() =>
      _getAreaUdtStringList('/api/MasterData/area-udt/areas');

  @override
  Future<List<MasterDataOptionModel>> getAreaUdtZones(String area) {
    final a = area.trim();
    if (a.isEmpty) return Future.value(const []);
    return _getAreaUdtStringList(
      '/api/MasterData/area-udt/zones',
      queryParameters: <String, dynamic>{'area': a},
    );
  }

  @override
  Future<List<MasterDataOptionModel>> getAreaUdtStates(String zone) {
    final z = zone.trim();
    if (z.isEmpty) return Future.value(const []);
    return _getAreaUdtStringList(
      '/api/MasterData/area-udt/states',
      queryParameters: <String, dynamic>{'zone': z},
    );
  }

  @override
  Future<List<MasterDataOptionModel>> getAreaUdtCities(String state) {
    final s = state.trim();
    if (s.isEmpty) return Future.value(const []);
    return _getAreaUdtStringList(
      '/api/MasterData/area-udt/cities',
      queryParameters: <String, dynamic>{'state': s},
    );
  }

  @override
  Future<List<MasterDataOptionModel>> getAreaUdtRegions(String city) {
    final c = city.trim();
    if (c.isEmpty) return Future.value(const []);
    return _getAreaUdtStringList(
      '/api/MasterData/area-udt/regions',
      queryParameters: <String, dynamic>{'city': c},
    );
  }

  @override
  Future<List<MasterDataOptionModel>> getCustomerTypes() =>
      _getCodeNameList('/api/MasterData/customer-types');

  @override
  Future<Map<String, dynamic>> getCustomers({
    String? search,
    String? name,
    String? foreignName,
    String? forienName,
    String? area,
    String? zone,
    String? stateFilter,
    String? city,
    String? region,
    bool? activeOnly,
    int? salesEmployeeCode,
    int pageNumber = 1,
    int pageSize = 10,
    int scope = CustomerOdbcScope.all,
  }) async {
    final queryParameters = buildOdbcCustomersMasterDataQuery(
      skip: (pageNumber - 1) * pageSize,
      take: pageSize,
      scope: scope,
      activeOnly: activeOnly,
      search: search,
      name: name,
      foreignName: foreignName,
      forienName: forienName,
      area: area,
      zone: zone,
      state: stateFilter,
      city: city,
      region: region,
      salesEmpCode: salesEmployeeCode,
    );

    final response = await apiService.get(
      '/api/MasterData/customers/odbc',
      queryParameters: queryParameters,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get customers');
    }

    return <String, dynamic>{
      'items': _parseOdbcCustomersResponseBody(response.data),
    };
  }
}

/// ODBC may return a JSON array (`text/plain` or `application/json`) or `{ items: [] }`.
List<dynamic> _parseOdbcCustomersResponseBody(dynamic rawData) {
  if (rawData is List) return rawData;
  if (rawData is String) {
    final text = rawData.trim();
    if (text.isEmpty) return const [];
    final decoded = jsonDecode(text);
    if (decoded is List) return decoded;
    if (decoded is Map) {
      final items = decoded['items'];
      if (items is List) return items;
    }
    return const [];
  }
  if (rawData is Map) {
    final items = rawData['items'];
    if (items is List) return items;
  }
  return const [];
}
