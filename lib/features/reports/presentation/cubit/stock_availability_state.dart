import 'package:equatable/equatable.dart';
import 'package:sales_medical_app_mobile/features/reports/domain/entities/erp_warehouse.dart';
import 'package:sales_medical_app_mobile/features/reports/domain/entities/stock_availability.dart';

class StockAvailabilityState extends Equatable {
  const StockAvailabilityState({
    this.selectedWarehouseCode,
    this.selectedWarehouseName,
    this.includeZeroOnHand = false,
    this.rows = const [],
    this.isLoading = false,
    this.errorMessage,
    this.warehouses = const [],
    this.isLoadingWarehouses = false,
    this.isLoadingMoreWarehouses = false,
    this.warehousesError,
    this.warehousesHasMore = true,
    this.warehousesSkip = 0,
    this.warehousesSearch = '',
  });

  final String? selectedWarehouseCode;
  final String? selectedWarehouseName;
  final bool includeZeroOnHand;
  final List<StockAvailability> rows;
  final bool isLoading;
  final String? errorMessage;

  final List<ErpWarehouse> warehouses;
  final bool isLoadingWarehouses;
  final bool isLoadingMoreWarehouses;
  final String? warehousesError;
  final bool warehousesHasMore;
  final int warehousesSkip;
  final String warehousesSearch;

  bool get hasSelectedWarehouse =>
      selectedWarehouseCode != null && selectedWarehouseCode!.isNotEmpty;

  StockAvailabilityState copyWith({
    String? selectedWarehouseCode,
    String? selectedWarehouseName,
    bool clearSelectedWarehouse = false,
    bool? includeZeroOnHand,
    List<StockAvailability>? rows,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<ErpWarehouse>? warehouses,
    bool? isLoadingWarehouses,
    bool? isLoadingMoreWarehouses,
    String? warehousesError,
    bool clearWarehousesError = false,
    bool? warehousesHasMore,
    int? warehousesSkip,
    String? warehousesSearch,
  }) {
    return StockAvailabilityState(
      selectedWarehouseCode: clearSelectedWarehouse
          ? null
          : (selectedWarehouseCode ?? this.selectedWarehouseCode),
      selectedWarehouseName: clearSelectedWarehouse
          ? null
          : (selectedWarehouseName ?? this.selectedWarehouseName),
      includeZeroOnHand: includeZeroOnHand ?? this.includeZeroOnHand,
      rows: rows ?? this.rows,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      warehouses: warehouses ?? this.warehouses,
      isLoadingWarehouses: isLoadingWarehouses ?? this.isLoadingWarehouses,
      isLoadingMoreWarehouses:
          isLoadingMoreWarehouses ?? this.isLoadingMoreWarehouses,
      warehousesError: clearWarehousesError
          ? null
          : (warehousesError ?? this.warehousesError),
      warehousesHasMore: warehousesHasMore ?? this.warehousesHasMore,
      warehousesSkip: warehousesSkip ?? this.warehousesSkip,
      warehousesSearch: warehousesSearch ?? this.warehousesSearch,
    );
  }

  @override
  List<Object?> get props => [
        selectedWarehouseCode,
        selectedWarehouseName,
        includeZeroOnHand,
        rows,
        isLoading,
        errorMessage,
        warehouses,
        isLoadingWarehouses,
        isLoadingMoreWarehouses,
        warehousesError,
        warehousesHasMore,
        warehousesSkip,
        warehousesSearch,
      ];
}
