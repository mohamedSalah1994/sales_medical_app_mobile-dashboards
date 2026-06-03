import 'package:sales_medical_app_mobile/features/inventory/data/models/inventory_counting_models.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/inventory_transfer_models.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/warehouse_odbc_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/item_lookup_response_model.dart'
    show ItemLookupResponseModel, kOdbcItemLookupTake;
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_response_model.dart';

abstract class InventoryRepository {
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
