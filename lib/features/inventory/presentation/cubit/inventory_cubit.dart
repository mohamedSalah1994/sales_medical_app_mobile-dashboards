import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/inventory_counting_models.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/inventory_transfer_models.dart';
import 'package:sales_medical_app_mobile/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/cubit/inventory_state.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/item_lookup_response_model.dart'
    show ItemLookupResponseModel, kOdbcItemLookupTake;
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_response_model.dart';

class InventoryCubit extends Cubit<InventoryState> {
  InventoryCubit({required InventoryRepository repository})
    : _repository = repository,
      super(const InventoryState());

  final InventoryRepository _repository;

  static const int kCountingsPageSize = 20;

  Future<void> loadWarehouses() async {
    emit(state.copyWith(isLoadingWarehouses: true, clearWarehousesError: true));
    try {
      final list = await _repository.getWarehousesOdbc();
      emit(state.copyWith(warehouses: list, isLoadingWarehouses: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingWarehouses: false,
          warehousesError: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<ItemLookupResponseModel> lookupItemOdbc(
    String q, {
    String? warehouseCode,
    String? customerCode,
    int skip = 0,
    int take = kOdbcItemLookupTake,
    bool includeUoms = true,
  }) {
    return _repository.getItemsLookupOdbc(
      q: q,
      warehouseCode: warehouseCode,
      customerCode: customerCode,
      includeUoms: includeUoms,
      skip: skip,
      take: take,
    );
  }

  Future<InventoryTransferDocModel> getTransferByDocEntry(int docEntry) {
    return _repository.getInventoryTransferByDocEntry(docEntry);
  }

  Future<SalesOrderResponseModel> createTransfer(
    CreateInventoryTransferRequestModel request,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearSubmitError: true));
    try {
      final result = await _repository.createInventoryTransfer(request);
      emit(state.copyWith(isSubmitting: false));
      return result;
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          submitError: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      rethrow;
    }
  }

  Future<InventoryCountingDocModel> getCountingByDocEntry(int docEntry) {
    return _repository.getInventoryCountingByDocEntry(docEntry);
  }

  /// Loads `GET /api/erp/inventory-countings` for the given window. Stores the
  /// result in [InventoryState.countings] for the list page to render as cards.
  /// [append]: next page (`skip` = current list length), `take` = [kCountingsPageSize].
  Future<void> loadCountings({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? warehouseCode,
    bool append = false,
  }) async {
    final wh = warehouseCode?.trim();

    if (append) {
      if (!state.countingsHasMore ||
          state.isLoadingMoreCountings ||
          state.isLoadingCountings) {
        return;
      }
      emit(state.copyWith(isLoadingMoreCountings: true));
    } else {
      emit(
        state.copyWith(
          isLoadingCountings: true,
          clearCountingsError: true,
          countingsHasMore: true,
          countingsWarehouseCode: wh,
          clearCountingsWarehouseCode: wh == null || wh.isEmpty,
        ),
      );
    }

    final skip = append ? state.countings.length : 0;

    try {
      final list = await _repository.getInventoryCountings(
        dateFrom: dateFrom,
        dateTo: dateTo,
        warehouseCode: wh,
        skip: skip,
        take: kCountingsPageSize,
      );
      final hasMore = list.length == kCountingsPageSize;
      final merged = append ? [...state.countings, ...list] : list;
      emit(
        state.copyWith(
          countings: merged,
          isLoadingCountings: false,
          isLoadingMoreCountings: false,
          countingsHasMore: hasMore,
        ),
      );
    } catch (e) {
      if (append) {
        emit(state.copyWith(isLoadingMoreCountings: false));
      } else {
        emit(
          state.copyWith(
            isLoadingCountings: false,
            countingsError: e.toString().replaceFirst('Exception: ', ''),
          ),
        );
      }
    }
  }

  Future<SalesOrderResponseModel> createCounting(
    CreateInventoryCountingRequestModel request,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearSubmitError: true));
    try {
      final result = await _repository.createInventoryCounting(request);
      emit(state.copyWith(isSubmitting: false));
      return result;
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          submitError: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      rethrow;
    }
  }
}
