import 'package:sales_medical_app_mobile/core/cache/item_lookup_odbc_cache.dart';
import 'package:sales_medical_app_mobile/core/network/connectivity_service.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/datasources/sales_order_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/offline_item_lookup_exception.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/create_delivery_request_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/item_batch_quantity_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/create_return_from_delivery_request_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/create_sales_order_request_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/erp_customer_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/item_lookup_response_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_list_item_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_ready_for_delivery_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_response_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/vat_code_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/domain/repositories/sales_order_repository.dart';

class SalesOrderRepositoryImpl implements SalesOrderRepository {
  SalesOrderRepositoryImpl({
    required this.remoteDataSource,
    required this.connectivityService,
    required this.itemLookupCache,
  });

  final SalesOrderRemoteDataSource remoteDataSource;
  final ConnectivityService connectivityService;
  final ItemLookupOdbcCache itemLookupCache;

  static const String _itemLookupNamespace = 'so';

  @override
  Future<List<SalesOrderReadyForDeliveryModel>>
      getSalesOrdersReadyForDelivery() {
    return remoteDataSource.getSalesOrdersReadyForDelivery();
  }

  @override
  Future<List<SalesOrderReadyForDeliveryModel>>
      getDeliveriesReadyForReturn() {
    return remoteDataSource.getDeliveriesReadyForReturn();
  }

  @override
  Future<SalesOrderListItemModel> getSalesOrderByDocEntry(int docEntry) {
    return remoteDataSource.getSalesOrderByDocEntry(docEntry);
  }

  @override
  Future<SalesOrderListItemModel> getDeliveryByDocEntry(int docEntry) {
    return remoteDataSource.getDeliveryByDocEntry(docEntry);
  }

  @override
  Future<SalesOrderListItemModel> getReturnByDocEntry(int docEntry) {
    return remoteDataSource.getReturnByDocEntry(docEntry);
  }

  @override
  Future<List<ItemBatchQuantityModel>> getItemBatchQuantities({
    required String itemCode,
    String? warehouseCode,
  }) {
    return remoteDataSource.getItemBatchQuantities(
      itemCode: itemCode,
      warehouseCode: warehouseCode,
    );
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
  }) {
    return remoteDataSource.getSalesOrders(
      visitId: visitId,
      customerCode: customerCode,
      dateFrom: dateFrom,
      dateTo: dateTo,
      salesEmployeeCode: salesEmployeeCode,
      skip: skip,
      take: take,
    );
  }

  @override
  Future<SalesOrderResponseModel> patchSalesOrder(
    int docEntry,
    CreateSalesOrderRequestModel request,
  ) {
    return remoteDataSource.patchSalesOrder(docEntry, request);
  }

  @override
  Future<List<ErpCustomerModel>> getErpCustomers({
    String? search,
    int? salesEmployeeCode,
    int skip = 0,
    int take = 100,
  }) {
    return remoteDataSource.getErpCustomers(
      search: search,
      activeOnly: true,
      salesEmployeeCode: salesEmployeeCode,
      skip: skip,
      take: take,
    );
  }

  @override
  Future<ItemLookupResponseModel> getItemsLookup({
    String? code,
    String? customerCode,
    String? warehouseCode,
    int skip = 0,
    int take = kOdbcItemLookupTake,
  }) async {
    final online = await connectivityService.isOnline;
    if (!online) {
      final codeVal = code?.trim();
      if (codeVal == null || codeVal.isEmpty) {
        throw OfflineItemLookupCacheMiss('Item code is required');
      }
      final cached = await itemLookupCache.read(
        namespace: _itemLookupNamespace,
        code: codeVal,
        customerCode: customerCode,
        warehouseCode: warehouseCode,
        skip: skip,
        take: take,
      );
      if (cached == null) {
        throw OfflineItemLookupCacheMiss();
      }
      try {
        return ItemLookupResponseModel.fromOdbcAny(cached);
      } catch (_) {
        throw OfflineItemLookupCacheMiss(
          'Cached item data is invalid. Connect online and search again to refresh.',
        );
      }
    }

    return remoteDataSource.getItemsLookup(
      code: code,
      customerCode: customerCode,
      warehouseCode: warehouseCode,
      includeBatches: false,
      skip: skip,
      take: take,
    );
  }

  @override
  Future<List<VatCodeModel>> getVatCodes() {
    return remoteDataSource.getVatCodes();
  }

  @override
  Future<SalesOrderResponseModel> createSalesOrder(
    CreateSalesOrderRequestModel request,
  ) {
    return remoteDataSource.createSalesOrder(request);
  }

  @override
  Future<SalesOrderResponseModel> createDelivery(
    CreateDeliveryRequestModel request,
  ) {
    return remoteDataSource.createDelivery(request);
  }

  @override
  Future<List<SalesOrderListItemModel>> getDeliveries({
    String? customerCode,
    String? dateFrom,
    String? dateTo,
    int? salesEmployeeCode,
    int skip = 0,
    int take = 100,
  }) {
    return remoteDataSource.getDeliveries(
      customerCode: customerCode,
      dateFrom: dateFrom,
      dateTo: dateTo,
      salesEmployeeCode: salesEmployeeCode,
      skip: skip,
      take: take,
    );
  }

  @override
  Future<List<SalesOrderListItemModel>> getReturns({
    String? customerCode,
    String? dateFrom,
    String? dateTo,
    int? salesEmployeeCode,
    int skip = 0,
    int take = 100,
  }) {
    return remoteDataSource.getReturns(
      customerCode: customerCode,
      dateFrom: dateFrom,
      dateTo: dateTo,
      salesEmployeeCode: salesEmployeeCode,
      skip: skip,
      take: take,
    );
  }

  @override
  Future<SalesOrderResponseModel> createReturnFromDelivery(
    CreateReturnFromDeliveryRequestModel request,
  ) {
    return remoteDataSource.createReturnFromDelivery(request);
  }

  @override
  Future<SalesOrderResponseModel> cancelSalesOrder(int docEntry) {
    return remoteDataSource.cancelSalesOrder(docEntry);
  }

  @override
  Future<SalesOrderResponseModel> cancelDelivery(int docEntry) {
    return remoteDataSource.cancelDelivery(docEntry);
  }
}
