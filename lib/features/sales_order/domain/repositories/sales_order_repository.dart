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

abstract class SalesOrderRepository {
  /// GET /api/erp/sales-orders/ready-for-delivery
  Future<List<SalesOrderReadyForDeliveryModel>> getSalesOrdersReadyForDelivery();

  /// GET /api/erp/deliveries/ready-for-return
  Future<List<SalesOrderReadyForDeliveryModel>> getDeliveriesReadyForReturn();

  Future<SalesOrderListItemModel> getSalesOrderByDocEntry(int docEntry);
  Future<SalesOrderListItemModel> getDeliveryByDocEntry(int docEntry);
  Future<SalesOrderListItemModel> getReturnByDocEntry(int docEntry);

  /// GET /api/MasterData/items/{itemCode}/batch-quantities
  Future<List<ItemBatchQuantityModel>> getItemBatchQuantities({
    required String itemCode,
    String? warehouseCode,
  });

  /// GET /api/erp/sales-orders
  Future<List<SalesOrderListItemModel>> getSalesOrders({
    String? visitId,
    String? customerCode,
    String? dateFrom,
    String? dateTo,
    int? salesEmployeeCode,
    int skip = 0,
    int take = 20,
  });
  Future<SalesOrderResponseModel> patchSalesOrder(
    int docEntry,
    CreateSalesOrderRequestModel request,
  );
  Future<List<ErpCustomerModel>> getErpCustomers({
    String? search,
    int? salesEmployeeCode,
    int skip = 0,
    int take = 100,
  });
  Future<ItemLookupResponseModel> getItemsLookup({
    String? code,
    String? customerCode,
    String? warehouseCode,
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

  Future<List<SalesOrderListItemModel>> getDeliveries({
    String? customerCode,
    String? dateFrom,
    String? dateTo,
    int? salesEmployeeCode,
    int skip = 0,
    int take = 100,
  });

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
