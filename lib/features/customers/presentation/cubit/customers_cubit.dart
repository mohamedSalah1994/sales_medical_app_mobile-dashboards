import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/core/constants/customer_odbc_scope.dart';
import 'package:sales_medical_app_mobile/features/customers/data/models/create_erp_customer_request_model.dart';
import 'package:sales_medical_app_mobile/features/customers/data/models/customer_series_model.dart';
import 'package:sales_medical_app_mobile/features/customers/data/models/master_data_option_model.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/entities/customer.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/usecases/create_erp_customer_usecase.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/usecases/get_customer_series_usecase.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/usecases/get_customers_usecase.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/usecases/get_master_data_options_usecase.dart';

part 'customers_state.dart';

class CustomersCubit extends Cubit<CustomersState> {
  CustomersCubit({
    this.getCustomersUseCase,
    required this.getCustomerSeriesUseCase,
    required this.createErpCustomerUseCase,
    required this.getMasterDataOptionsUseCase,
  }) : super(const CustomersState());

  final GetCustomersUseCase? getCustomersUseCase;
  final GetCustomerSeriesUseCase getCustomerSeriesUseCase;
  final CreateErpCustomerUseCase createErpCustomerUseCase;
  final GetMasterDataOptionsUseCase getMasterDataOptionsUseCase;

  static const int defaultPageSize = 10;

  /// [append] false: replace list (initial/refresh/search). true: append next page.
  Future<void> getCustomers({
    String? search,
    String? name,
    String? foreignName,
    String? forienName,
    String? area,
    String? zone,
    String? stateFilter,
    String? city,
    String? region,
    bool? activeOnly,
    int? salesEmployeeCode,
    int pageNumber = 1,
    int pageSize = defaultPageSize,
    bool append = false,
    int scope = CustomerOdbcScope.all,
  }) async {
    final useCase = getCustomersUseCase;
    if (useCase == null) return;
    if (append) {
      if (state.isLoadingMore || !state.hasMore) return;
      emit(state.copyWith(isLoadingMore: true, error: null));
    } else {
      emit(state.copyWith(isLoading: true, error: null));
    }
    try {
      final customers = await useCase(
        search: search,
        name: name,
        foreignName: foreignName,
        forienName: forienName,
        area: area,
        zone: zone,
        stateFilter: stateFilter,
        city: city,
        region: region,
        activeOnly: activeOnly,
        salesEmployeeCode: salesEmployeeCode,
        pageNumber: pageNumber,
        pageSize: pageSize,
        scope: scope,
      );
      if (isClosed) return;
      final hasMore = customers.length >= pageSize;
      if (append) {
        emit(state.copyWith(
          customers: [...state.customers, ...customers],
          isLoadingMore: false,
          hasMore: hasMore,
          currentPage: pageNumber,
          error: null,
        ));
      } else {
        emit(state.copyWith(
          customers: customers,
          isLoading: false,
          hasMore: hasMore,
          currentPage: pageNumber,
          error: null,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        if (append) {
          emit(state.copyWith(isLoadingMore: false, error: e.toString()));
        } else {
          emit(state.copyWith(isLoading: false, error: e.toString()));
        }
      }
    }
  }

  Future<void> loadSeries() async {
    emit(state.copyWith(isLoadingSeries: true, error: null));
    try {
      final list = await getCustomerSeriesUseCase();
      if (!isClosed) emit(state.copyWith(series: list, isLoadingSeries: false, error: null));
    } catch (e) {
      if (!isClosed) emit(state.copyWith(isLoadingSeries: false, error: e.toString()));
    }
  }

  Future<void> loadMasterDataOptions({
    required MasterDataSection section,
    String? parentTerritoryId,
  }) async {
    emit(state.copyWith(isLoadingMasterData: true, error: null));
    try {
      final list = await getMasterDataOptionsUseCase(
        section: section,
        parentTerritoryId: parentTerritoryId,
      );
      if (!isClosed) {
        emit(state.copyWith(
          masterDataOptions: list,
          isLoadingMasterData: false,
          error: null,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(isLoadingMasterData: false, error: e.toString()));
      }
    }
  }

  /// Returns the created customer data (e.g. {code, name}) on success, null on failure.
  Future<Map<String, dynamic>?> createCustomer(CreateErpCustomerRequestModel body) async {
    emit(state.copyWith(isCreating: true, error: null));
    try {
      final created = await createErpCustomerUseCase(body);
      if (!isClosed) emit(state.copyWith(isCreating: false, error: null));
      return created;
    } catch (e) {
      if (!isClosed) emit(state.copyWith(isCreating: false, error: e.toString()));
      return null;
    }
  }

  void clearError() {
    emit(state.copyWith(error: null));
  }
}
