import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/features/reports/domain/entities/erp_warehouse.dart';
import 'package:sales_medical_app_mobile/features/reports/domain/repositories/reports_repository.dart';
import 'package:sales_medical_app_mobile/features/reports/presentation/cubit/stock_availability_state.dart';

class StockAvailabilityCubit extends Cubit<StockAvailabilityState> {
  StockAvailabilityCubit({required ReportsRepository repository})
      : _repository = repository,
        super(const StockAvailabilityState());

  final ReportsRepository _repository;

  static const int _warehousesPageSize = 20;

  /// Pre-fills the warehouse for sales reps and immediately fetches the report.
  void initialiseForSalesRep(String warehouseCode, {String? warehouseName}) {
    if (warehouseCode.isEmpty) return;
    emit(state.copyWith(
      selectedWarehouseCode: warehouseCode,
      selectedWarehouseName: warehouseName,
    ));
    loadStockAvailability();
  }

  void selectWarehouse(ErpWarehouse warehouse) {
    emit(state.copyWith(
      selectedWarehouseCode: warehouse.code,
      selectedWarehouseName: warehouse.name,
    ));
    loadStockAvailability();
  }

  void toggleIncludeZeroOnHand(bool value) {
    if (state.includeZeroOnHand == value) return;
    emit(state.copyWith(includeZeroOnHand: value));
    if (state.hasSelectedWarehouse) {
      loadStockAvailability();
    }
  }

  Future<void> loadStockAvailability() async {
    final code = state.selectedWarehouseCode;
    if (code == null || code.isEmpty) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final rows = await _repository.getStockAvailability(
        warehouseCode: code,
        includeZeroOnHand: state.includeZeroOnHand,
      );
      if (isClosed) return;
      emit(state.copyWith(rows: rows, isLoading: false, clearError: true));
    } on Failure catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> loadWarehouses({String search = ''}) async {
    emit(state.copyWith(
      isLoadingWarehouses: true,
      clearWarehousesError: true,
      warehouses: const [],
      warehousesSkip: 0,
      warehousesHasMore: true,
      warehousesSearch: search,
    ));
    try {
      final list = await _repository.getErpWarehouses(
        search: search,
        skip: 0,
        take: _warehousesPageSize,
      );
      if (isClosed) return;
      emit(state.copyWith(
        warehouses: list,
        isLoadingWarehouses: false,
        warehousesSkip: list.length,
        warehousesHasMore: list.length >= _warehousesPageSize,
      ));
    } on Failure catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoadingWarehouses: false,
        warehousesError: e.message,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoadingWarehouses: false,
        warehousesError: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> loadMoreWarehouses() async {
    if (state.isLoadingWarehouses ||
        state.isLoadingMoreWarehouses ||
        !state.warehousesHasMore) {
      return;
    }
    emit(state.copyWith(
      isLoadingMoreWarehouses: true,
      clearWarehousesError: true,
    ));
    try {
      final list = await _repository.getErpWarehouses(
        search: state.warehousesSearch,
        skip: state.warehousesSkip,
        take: _warehousesPageSize,
      );
      if (isClosed) return;
      final merged = <ErpWarehouse>[...state.warehouses, ...list];
      emit(state.copyWith(
        warehouses: merged,
        isLoadingMoreWarehouses: false,
        warehousesSkip: merged.length,
        warehousesHasMore: list.length >= _warehousesPageSize,
      ));
    } on Failure catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoadingMoreWarehouses: false,
        warehousesError: e.message,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoadingMoreWarehouses: false,
        warehousesError: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
