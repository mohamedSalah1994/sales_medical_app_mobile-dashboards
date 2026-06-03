import 'dart:convert';

import 'package:sales_medical_app_mobile/core/network/api_service.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/inventory_exceptions.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/inventory_counting_models.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/inventory_transfer_models.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/warehouse_odbc_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/item_lookup_response_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_response_model.dart';

/// ERP may return `application/json` or `text/plain` with a JSON string body.
Map<String, dynamic>? _parseErpResponseMap(dynamic data) {
  if (data == null) return null;
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is String) {
    final t = data.trim();
    if (t.isEmpty) return null;
    try {
      final decoded = jsonDecode(t);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  return null;
}

abstract class InventoryRemoteDataSource {
  Future<List<WarehouseOdbcModel>> getWarehousesOdbc();

  Future<ItemLookupResponseModel> getItemsLookupOdbc({
    required String q,
    String? warehouseCode,
    bool includeBatches = false,
    bool includeUoms = true,
    String? customerCode,
    int skip = 0,
    int take = kOdbcItemLookupTake,
  });

  Future<InventoryTransferDocModel> getInventoryTransferByDocEntry(
    int docEntry,
  );

  Future<SalesOrderResponseModel> createInventoryTransfer(
    CreateInventoryTransferRequestModel request,
  );

  Future<InventoryCountingDocModel> getInventoryCountingByDocEntry(
    int docEntry,
  );

  /// `GET /api/erp/inventory-countings` — list of inventory counting documents
  /// scoped to optional date range, warehouse, and paging window.
  Future<List<InventoryCountingDocModel>> getInventoryCountings({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? warehouseCode,
    int skip = 0,
    int take = 10,
  });

  Future<SalesOrderResponseModel> createInventoryCounting(
    CreateInventoryCountingRequestModel request,
  );
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  InventoryRemoteDataSourceImpl({required this.apiService});

  final ApiService apiService;

  @override
  Future<List<WarehouseOdbcModel>> getWarehousesOdbc() async {
    final response = await apiService.get<dynamic>(
      '/api/MasterData/warehouses/odbc',
    );
    final data = response.data;
    if (data is! List) {
      throw Exception('Invalid warehouses response');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(WarehouseOdbcModel.fromJson)
        .toList();
  }

  @override
  Future<ItemLookupResponseModel> getItemsLookupOdbc({
    required String q,
    String? warehouseCode,
    bool includeBatches = false,
    bool includeUoms = true,
    String? customerCode,
    int skip = 0,
    int take = kOdbcItemLookupTake,
  }) async {
    final queryParameters = <String, dynamic>{
      'q': q,
      'take': take,
      'skip': skip,
      'includeBatches': includeBatches,
      'includeUoms': includeUoms,
    };
    if (warehouseCode != null && warehouseCode.isNotEmpty) {
      queryParameters['warehouseCode'] = warehouseCode;
    }
    if (customerCode != null && customerCode.isNotEmpty) {
      queryParameters['customerCode'] = customerCode;
    }

    final response = await apiService.get<dynamic>(
      '/api/MasterData/items/lookup-odbc',
      queryParameters: queryParameters,
    );
    final data = response.data;
    return ItemLookupResponseModel.fromOdbcAny(data);
  }

  @override
  Future<InventoryTransferDocModel> getInventoryTransferByDocEntry(
    int docEntry,
  ) async {
    try {
      final response = await apiService.get<dynamic>(
        '/api/erp/inventory-transfer-requests/$docEntry',
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const InventoryDocumentNotFoundException();
      }
      // 200 with error payload (e.g. InternalServerError + message)
      if (data['error'] != null) {
        throw const InventoryDocumentNotFoundException();
      }
      return InventoryTransferDocModel.fromJson(data);
    } on InventoryDocumentNotFoundException {
      rethrow;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '').toLowerCase();
      if (msg.contains('internalservererror') ||
          msg.contains('internal error') ||
          msg.contains('not found')) {
        throw const InventoryDocumentNotFoundException();
      }
      rethrow;
    }
  }

  @override
  Future<SalesOrderResponseModel> createInventoryTransfer(
    CreateInventoryTransferRequestModel request,
  ) async {
    final response = await apiService.post<dynamic>(
      '/api/erp/inventory-transfer-requests',
      data: request.toJson(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid create inventory response');
    }
    return SalesOrderResponseModel.fromJson(data);
  }

  @override
  Future<InventoryCountingDocModel> getInventoryCountingByDocEntry(
    int docEntry,
  ) async {
    try {
      final response = await apiService.get<dynamic>(
        '/api/erp/inventory-countings/$docEntry',
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const InventoryDocumentNotFoundException();
      }
      if (data['error'] != null) {
        throw const InventoryDocumentNotFoundException();
      }
      return InventoryCountingDocModel.fromJson(data);
    } on InventoryDocumentNotFoundException {
      rethrow;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '').toLowerCase();
      if (msg.contains('internalservererror') ||
          msg.contains('internal error') ||
          msg.contains('not found')) {
        throw const InventoryDocumentNotFoundException();
      }
      rethrow;
    }
  }

  @override
  Future<List<InventoryCountingDocModel>> getInventoryCountings({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? warehouseCode,
    int skip = 0,
    int take = 10,
  }) async {
    final queryParameters = <String, dynamic>{'skip': skip, 'take': take};
    if (dateFrom != null) {
      queryParameters['dateFrom'] = dateFrom.toUtc().toIso8601String();
    }
    if (dateTo != null) {
      queryParameters['dateTo'] = dateTo.toUtc().toIso8601String();
    }
    final wh = warehouseCode?.trim();
    if (wh != null && wh.isNotEmpty) {
      queryParameters['warehouseCode'] = wh;
    }

    final response = await apiService.get<dynamic>(
      '/api/erp/inventory-countings',
      queryParameters: queryParameters,
    );

    final data = response.data;
    if (data is! List) {
      throw Exception('Invalid inventory countings list response');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(InventoryCountingDocModel.fromJson)
        .toList();
  }

  @override
  Future<SalesOrderResponseModel> createInventoryCounting(
    CreateInventoryCountingRequestModel request,
  ) async {
    final response = await apiService.post<dynamic>(
      '/api/erp/inventory-countings',
      data: request.toJson(),
    );
    final map = _parseErpResponseMap(response.data);
    if (map == null) {
      throw Exception('Invalid create inventory counting response');
    }
    return SalesOrderResponseModel.fromJson(map);
  }
}
