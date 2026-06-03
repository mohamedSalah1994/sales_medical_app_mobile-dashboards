import 'package:sales_medical_app_mobile/features/inventory/data/datasources/inventory_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/inventory_counting_models.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/inventory_transfer_models.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/warehouse_odbc_model.dart';
import 'package:sales_medical_app_mobile/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/item_lookup_response_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_response_model.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  InventoryRepositoryImpl({required this.remoteDataSource});

  final InventoryRemoteDataSource remoteDataSource;

  @override
  Future<List<WarehouseOdbcModel>> getWarehousesOdbc() =>
      remoteDataSource.getWarehousesOdbc();

  @override
  Future<ItemLookupResponseModel> getItemsLookupOdbc({
    required String q,
    String? warehouseCode,
    bool includeBatches = false,
    bool includeUoms = true,
    String? customerCode,
    int skip = 0,
    int take = kOdbcItemLookupTake,
  }) => remoteDataSource.getItemsLookupOdbc(
    q: q,
    warehouseCode: warehouseCode,
    includeBatches: includeBatches,
    includeUoms: includeUoms,
    customerCode: customerCode,
    skip: skip,
    take: take,
  );

  @override
  Future<InventoryTransferDocModel> getInventoryTransferByDocEntry(
    int docEntry,
  ) => remoteDataSource.getInventoryTransferByDocEntry(docEntry);

  @override
  Future<SalesOrderResponseModel> createInventoryTransfer(
    CreateInventoryTransferRequestModel request,
  ) => remoteDataSource.createInventoryTransfer(request);

  @override
  Future<InventoryCountingDocModel> getInventoryCountingByDocEntry(
    int docEntry,
  ) => remoteDataSource.getInventoryCountingByDocEntry(docEntry);

  @override
  Future<List<InventoryCountingDocModel>> getInventoryCountings({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? warehouseCode,
    int skip = 0,
    int take = 10,
  }) => remoteDataSource.getInventoryCountings(
    dateFrom: dateFrom,
    dateTo: dateTo,
    warehouseCode: warehouseCode,
    skip: skip,
    take: take,
  );

  @override
  Future<SalesOrderResponseModel> createInventoryCounting(
    CreateInventoryCountingRequestModel request,
  ) => remoteDataSource.createInventoryCounting(request);
}
