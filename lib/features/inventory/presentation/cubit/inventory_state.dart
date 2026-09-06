import 'package:sales_medical_app_mobile/features/inventory/data/models/inventory_counting_models.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/warehouse_odbc_model.dart';

class InventoryState {
  const InventoryState({
    this.warehouses = const [],
    this.isLoadingWarehouses = false,
    this.warehousesError,
    this.isSubmitting = false,
    this.submitError,
    this.countings = const [],
    this.isLoadingCountings = false,
    this.isLoadingMoreCountings = false,
    this.countingsHasMore = true,
    this.countingsError,
    this.countingsWarehouseCode,
  });

  final List<WarehouseOdbcModel> warehouses;
  final bool isLoadingWarehouses;
  final String? warehousesError;
  final bool isSubmitting;
  final String? submitError;

  /// Latest list of inventory counting documents from `GET /api/erp/inventory-countings`.
  final List<InventoryCountingDocModel> countings;
  final bool isLoadingCountings;
  final bool isLoadingMoreCountings;
  final bool countingsHasMore;
  final String? countingsError;

  /// Warehouse code used for the current [countings] load, so the list page can
  /// detect when to refresh after the default warehouse becomes available.
  final String? countingsWarehouseCode;

  InventoryState copyWith({
    List<WarehouseOdbcModel>? warehouses,
    bool? isLoadingWarehouses,
    String? warehousesError,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
    bool clearWarehousesError = false,
    List<InventoryCountingDocModel>? countings,
    bool? isLoadingCountings,
    bool? isLoadingMoreCountings,
    bool? countingsHasMore,
    String? countingsError,
    bool clearCountingsError = false,
    String? countingsWarehouseCode,
    bool clearCountingsWarehouseCode = false,
  }) {
    return InventoryState(
      warehouses: warehouses ?? this.warehouses,
      isLoadingWarehouses: isLoadingWarehouses ?? this.isLoadingWarehouses,
      warehousesError:
          clearWarehousesError
              ? null
              : (warehousesError ?? this.warehousesError),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      countings: countings ?? this.countings,
      isLoadingCountings: isLoadingCountings ?? this.isLoadingCountings,
      isLoadingMoreCountings:
          isLoadingMoreCountings ?? this.isLoadingMoreCountings,
      countingsHasMore: countingsHasMore ?? this.countingsHasMore,
      countingsError:
          clearCountingsError ? null : (countingsError ?? this.countingsError),
      countingsWarehouseCode:
          clearCountingsWarehouseCode
              ? null
              : (countingsWarehouseCode ?? this.countingsWarehouseCode),
    );
  }
}
