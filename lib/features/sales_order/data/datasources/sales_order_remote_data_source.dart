import 'package:sales_medical_app_mobile/core/cache/item_lookup_odbc_cache.dart';
import 'package:sales_medical_app_mobile/core/network/api_http_exception.dart';
import 'package:sales_medical_app_mobile/core/network/api_service.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/create_delivery_request_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/item_batch_quantity_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/create_return_from_delivery_request_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/create_sales_order_request_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/erp_customer_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/free_goods_option_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/item_lookup_response_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_list_item_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_ready_for_delivery_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_response_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/vat_code_model.dart';

abstract class SalesOrderRemoteDataSource {
  /// GET /api/erp/sales-orders/{docEntry} - fetch a single order by doc entry.
  Future<SalesOrderListItemModel> getSalesOrderByDocEntry(int docEntry);

  /// GET /api/erp/deliveries/{docEntry} - fetch a single delivery by doc entry.
  Future<SalesOrderListItemModel> getDeliveryByDocEntry(int docEntry);

  /// GET /api/erp/returns/{docEntry}
  Future<SalesOrderListItemModel> getReturnByDocEntry(int docEntry);

  /// GET /api/MasterData/items/{itemCode}/batch-quantities
  Future<List<ItemBatchQuantityModel>> getItemBatchQuantities({
    required String itemCode,
    String? warehouseCode,
  });

  /// GET /api/erp/sales-orders/ready-for-delivery
  Future<List<SalesOrderReadyForDeliveryModel>> getSalesOrdersReadyForDelivery();

  /// GET /api/erp/deliveries/ready-for-return
  Future<List<SalesOrderReadyForDeliveryModel>> getDeliveriesReadyForReturn();

  /// GET /api/erp/sales-orders (skip/take paging; optional filters).
  Future<List<SalesOrderListItemModel>> getSalesOrders({
    String? visitId,
    String? customerCode,
    String? dateFrom,
    String? dateTo,
    int? salesEmployeeCode,
    int skip = 0,
    int take = 20,
  });

  /// PATCH /api/erp/sales-orders/{docEntry}
  Future<SalesOrderResponseModel> patchSalesOrder(
    int docEntry,
    CreateSalesOrderRequestModel request,
  );
  Future<List<ErpCustomerModel>> getErpCustomers({
    String? search,
    String? city,
    bool? activeOnly,
    int? salesEmployeeCode,
    int skip = 0,
    int take = 100,
  });

  /// ODBC item lookup (`q`, `take`, `skip`, includeBatches, optional customerCode / warehouseCode).
  Future<ItemLookupResponseModel> getItemsLookup({
    String? code,
    String? customerCode,
    String? warehouseCode,
    bool includeBatches = false,
    int skip = 0,
    int take = kOdbcItemLookupTake,
  });
  Future<List<VatCodeModel>> getVatCodes();

  /// GET /api/erp/sales-orders/getFreeGoodsList
  Future<List<FreeGoodsOptionModel>> getFreeGoodsList();

  Future<SalesOrderResponseModel> createSalesOrder(
    CreateSalesOrderRequestModel request,
  );
  Future<SalesOrderResponseModel> createDelivery(
    CreateDeliveryRequestModel request,
  );

  /// GET /api/erp/deliveries — list deliveries (filters optional).
  Future<List<SalesOrderListItemModel>> getDeliveries({
    String? customerCode,
    String? dateFrom,
    String? dateTo,
    int? salesEmployeeCode,
    int skip = 0,
    int take = 100,
  });

  /// GET /api/erp/returns
  Future<List<SalesOrderListItemModel>> getReturns({
    String? customerCode,
    String? dateFrom,
    String? dateTo,
    int? salesEmployeeCode,
    int skip = 0,
    int take = 100,
  });

  Future<SalesOrderResponseModel> createReturnFromDelivery(
    CreateReturnFromDeliveryRequestModel request,
  );

  /// POST /api/erp/sales-orders/{docEntry}/cancel
  Future<SalesOrderResponseModel> cancelSalesOrder(int docEntry);

  /// POST /api/erp/deliveries/{docEntry}/cancel
  Future<SalesOrderResponseModel> cancelDelivery(int docEntry);
}

class SalesOrderRemoteDataSourceImpl implements SalesOrderRemoteDataSource {
  SalesOrderRemoteDataSourceImpl({
    required this.apiService,
    required this.itemLookupCache,
  });

  final ApiService apiService;
  final ItemLookupOdbcCache itemLookupCache;

  static const String _itemLookupNamespace = 'so';

  @override
  Future<List<ErpCustomerModel>> getErpCustomers({
    String? search,
    String? city,
    bool? activeOnly,
    int? salesEmployeeCode,
    int skip = 0,
    int take = 100,
  }) async {
    final queryParams = <String, dynamic>{
      'activeOnly': activeOnly ?? true,
      'skip': skip,
      'take': take,
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (salesEmployeeCode != null) {
      queryParams['salesEmployeeCode'] = salesEmployeeCode;
    }

    final response = await apiService.get(
      '/api/Erp/customers',
      queryParameters: queryParams,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load customers');
    }

    final raw = response.data;
    List<dynamic> list = <dynamic>[];
    if (raw is List) {
      list = raw;
    } else if (raw is Map<String, dynamic> && raw.containsKey('items')) {
      list = raw['items'] as List<dynamic>? ?? [];
    }

    return list
        .where((e) => e is Map<String, dynamic>)
        .map((e) => ErpCustomerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ItemLookupResponseModel> getItemsLookup({
    String? code,
    String? customerCode,
    String? warehouseCode,
    bool includeBatches = false,
    int skip = 0,
    int take = kOdbcItemLookupTake,
  }) async {
    final codeVal = code?.trim();
    if (codeVal == null || codeVal.isEmpty) {
      throw Exception('Item code is required');
    }
    final queryParams = <String, dynamic>{
      'q': codeVal,
      'take': take,
      'skip': skip,
      'includeBatches': includeBatches,
    };
    if (customerCode != null && customerCode.isNotEmpty) {
      queryParams['customerCode'] = customerCode;
    }
    if (warehouseCode != null && warehouseCode.isNotEmpty) {
      queryParams['warehouseCode'] = warehouseCode;
    }

    final response = await apiService.get(
      '/api/MasterData/items/lookup-odbc',
      queryParameters: queryParams,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to lookup item');
    }

    final data = response.data;
    final model = ItemLookupResponseModel.fromOdbcAny(data);
    if (model.expandedLinePickBundles().isNotEmpty) {
      await itemLookupCache.write(
        namespace: _itemLookupNamespace,
        code: codeVal,
        customerCode: customerCode,
        warehouseCode: warehouseCode,
        skip: skip,
        take: take,
        rawBody: data,
      );
    }
    return model;
  }

  @override
  Future<List<VatCodeModel>> getVatCodes() async {
    final response = await apiService.get('/api/MasterData/vat-codes');
    if (response.statusCode != 200) {
      throw Exception('Failed to load VAT codes');
    }
    final raw = response.data;
    final list = raw is List ? raw : <dynamic>[];
    return list
        .where((e) => e is Map<String, dynamic>)
        .map((e) => VatCodeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<FreeGoodsOptionModel>> getFreeGoodsList() async {
    final response = await apiService.get(
      '/api/erp/sales-orders/getFreeGoodsList',
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load free goods list');
    }
    final raw = response.data;
    final list = raw is List ? raw : <dynamic>[];
    return list
        .whereType<Map>()
        .map(
          (e) => FreeGoodsOptionModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  static const String _documentNotFoundMessage = 'Document not found';

  @override
  Future<SalesOrderListItemModel> getSalesOrderByDocEntry(int docEntry) async {
    try {
      final response = await apiService.get('/api/erp/sales-orders/$docEntry');

      if (response.statusCode != 200) {
        throw Exception('Failed to load sales order');
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid sales order response');
      }
      return SalesOrderListItemModel.fromJson(data);
    } on ApiHttpException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 500) {
        throw Exception(_documentNotFoundMessage);
      }
      rethrow;
    }
  }

  @override
  Future<SalesOrderListItemModel> getDeliveryByDocEntry(int docEntry) async {
    try {
      final response = await apiService.get('/api/erp/deliveries/$docEntry');

      if (response.statusCode != 200) {
        throw Exception('Failed to load delivery');
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid delivery response');
      }
      return SalesOrderListItemModel.fromJson(data);
    } on ApiHttpException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 500) {
        throw Exception(_documentNotFoundMessage);
      }
      rethrow;
    }
  }

  @override
  Future<SalesOrderListItemModel> getReturnByDocEntry(int docEntry) async {
    try {
      final response = await apiService.get('/api/erp/returns/$docEntry');

      if (response.statusCode != 200) {
        throw Exception('Failed to load return');
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid return response');
      }
      return SalesOrderListItemModel.fromJson(data);
    } on ApiHttpException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 500) {
        throw Exception(_documentNotFoundMessage);
      }
      rethrow;
    }
  }

  @override
  Future<List<ItemBatchQuantityModel>> getItemBatchQuantities({
    required String itemCode,
    String? warehouseCode,
  }) async {
    final encoded = Uri.encodeComponent(itemCode.trim());
    final query = <String, dynamic>{};
    final wh = warehouseCode?.trim();
    if (wh != null && wh.isNotEmpty) {
      query['warehouseCode'] = wh;
    }
    final response = await apiService.get(
      '/api/MasterData/items/$encoded/batch-quantities',
      queryParameters: query.isEmpty ? null : query,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load batch quantities');
    }

    final raw = response.data;
    final list = raw is List ? raw : <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ItemBatchQuantityModel.fromJson)
        .toList();
  }

  @override
  Future<List<SalesOrderReadyForDeliveryModel>>
      getSalesOrdersReadyForDelivery() async {
    final response = await apiService.get(
      '/api/erp/sales-orders/ready-for-delivery',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load orders ready for delivery');
    }

    final raw = response.data;
    final list = raw is List ? raw : <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(SalesOrderReadyForDeliveryModel.fromJson)
        .toList();
  }

  @override
  Future<List<SalesOrderReadyForDeliveryModel>>
      getDeliveriesReadyForReturn() async {
    final response = await apiService.get(
      '/api/erp/deliveries/ready-for-return',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load deliveries ready for return');
    }

    final raw = response.data;
    final list = raw is List ? raw : <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(SalesOrderReadyForDeliveryModel.fromJson)
        .toList();
  }

  @override
  Future<List<SalesOrderListItemModel>> getSalesOrders({
    String? visitId,
    String? customerCode,
    String? dateFrom,
    String? dateTo,
    int? salesEmployeeCode,
    int skip = 0,
    int take = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'skip': skip,
      'take': take,
    };
    if (visitId != null && visitId.isNotEmpty) {
      queryParams['visitId'] = visitId;
    }
    if (customerCode != null && customerCode.isNotEmpty) {
      queryParams['customerCode'] = customerCode;
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      queryParams['dateFrom'] = dateFrom;
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      queryParams['dateTo'] = dateTo;
    }
    if (salesEmployeeCode != null) {
      queryParams['salesEmployeeCode'] = salesEmployeeCode;
    }

    final response = await apiService.get(
      '/api/erp/sales-orders',
      queryParameters: queryParams,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load sales orders');
    }

    final raw = response.data;
    List<dynamic> list = <dynamic>[];
    if (raw is List) {
      list = raw;
    } else if (raw is Map<String, dynamic> && raw['items'] is List) {
      list = raw['items'] as List<dynamic>;
    }
    return list
        .where((e) => e is Map<String, dynamic>)
        .map((e) => SalesOrderListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SalesOrderResponseModel> patchSalesOrder(
    int docEntry,
    CreateSalesOrderRequestModel request,
  ) async {
    final body = request.toJsonForPatch();
    final response = await apiService.patch(
      '/api/erp/sales-orders/$docEntry',
      data: body,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to update sales order');
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return const SalesOrderResponseModel(success: false);
    }
    if (data.containsKey('docEntry') || data.containsKey('docNum')) {
      return SalesOrderResponseModel(
        success: true,
        documentNumber: data['docNum']?.toString(),
        documentId: data['docEntry']?.toString(),
      );
    }
    return SalesOrderResponseModel.fromJson(data);
  }

  @override
  Future<SalesOrderResponseModel> createSalesOrder(
    CreateSalesOrderRequestModel request,
  ) async {
    final response = await apiService.post(
      '/api/erp/sales-orders',
      data: request.toJsonForPost(),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create sales order');
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return const SalesOrderResponseModel(success: false);
    }
    return SalesOrderResponseModel.fromJson(data);
  }

  @override
  Future<List<SalesOrderListItemModel>> getDeliveries({
    String? customerCode,
    String? dateFrom,
    String? dateTo,
    int? salesEmployeeCode,
    int skip = 0,
    int take = 100,
  }) async {
    final queryParams = <String, dynamic>{
      'skip': skip,
      'take': take,
    };
    if (customerCode != null && customerCode.isNotEmpty) {
      queryParams['customerCode'] = customerCode;
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      queryParams['dateFrom'] = dateFrom;
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      queryParams['dateTo'] = dateTo;
    }
    if (salesEmployeeCode != null) {
      queryParams['salesEmployeeCode'] = salesEmployeeCode;
    }

    final response = await apiService.get(
      '/api/erp/deliveries',
      queryParameters: queryParams,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load deliveries');
    }

    final raw = response.data;
    final list = raw is List ? raw : <dynamic>[];
    return list
        .where((e) => e is Map<String, dynamic>)
        .map((e) => SalesOrderListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SalesOrderResponseModel> createDelivery(
    CreateDeliveryRequestModel request,
  ) async {
    final response = await apiService.post(
      '/api/erp/deliveries',
      data: request.toJson(),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create delivery');
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return const SalesOrderResponseModel(success: false);
    }
    return SalesOrderResponseModel.fromJson(data);
  }

  @override
  Future<List<SalesOrderListItemModel>> getReturns({
    String? customerCode,
    String? dateFrom,
    String? dateTo,
    int? salesEmployeeCode,
    int skip = 0,
    int take = 100,
  }) async {
    final queryParams = <String, dynamic>{
      'skip': skip,
      'take': take,
    };
    if (customerCode != null && customerCode.isNotEmpty) {
      queryParams['customerCode'] = customerCode;
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      queryParams['dateFrom'] = dateFrom;
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      queryParams['dateTo'] = dateTo;
    }
    if (salesEmployeeCode != null) {
      queryParams['salesEmployeeCode'] = salesEmployeeCode;
    }

    final response = await apiService.get(
      '/api/erp/returns',
      queryParameters: queryParams,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load returns');
    }

    final raw = response.data;
    final list = raw is List ? raw : <dynamic>[];
    return list
        .where((e) => e is Map<String, dynamic>)
        .map((e) => SalesOrderListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SalesOrderResponseModel> createReturnFromDelivery(
    CreateReturnFromDeliveryRequestModel request,
  ) async {
    final response = await apiService.post(
      '/api/erp/returns/from-delivery',
      data: request.toJson(),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create return');
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return const SalesOrderResponseModel(success: false);
    }
    return SalesOrderResponseModel.fromJson(data);
  }

  @override
  Future<SalesOrderResponseModel> cancelSalesOrder(int docEntry) {
    return _cancelDocument('/api/erp/sales-orders/$docEntry/cancel');
  }

  @override
  Future<SalesOrderResponseModel> cancelDelivery(int docEntry) {
    return _cancelDocument('/api/erp/deliveries/$docEntry/cancel');
  }

  /// Shared cancel POST handler. The endpoint returns a `success` envelope; we
  /// surface the API's `errorMessage` to callers so the UI can show it
  /// verbatim instead of a generic exception message.
  Future<SalesOrderResponseModel> _cancelDocument(String path) async {
    final response = await apiService.post(path);

    final data = response.data;
    SalesOrderResponseModel parsed;
    if (data is Map<String, dynamic>) {
      parsed = SalesOrderResponseModel.fromJson(data);
    } else {
      parsed = SalesOrderResponseModel(
        success:
            response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300,
      );
    }
    return parsed;
  }
}
