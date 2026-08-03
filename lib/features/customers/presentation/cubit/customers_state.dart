part of 'customers_cubit.dart';

class CustomersState {
  final List<Customer> customers;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  /// List / search / series / master-data errors (not create).
  final String? error;
  /// Create-customer failures only — must not block the customers list UI.
  final String? createError;
  final List<CustomerSeriesModel> series;
  final bool isLoadingSeries;
  final bool isCreating;
  final List<MasterDataOptionModel> masterDataOptions;
  final bool isLoadingMasterData;

  const CustomersState({
    this.customers = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
    this.createError,
    this.series = const [],
    this.isLoadingSeries = false,
    this.isCreating = false,
    this.masterDataOptions = const [],
    this.isLoadingMasterData = false,
  });

  CustomersState copyWith({
    List<Customer>? customers,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    bool clearError = false,
    String? createError,
    bool clearCreateError = false,
    List<CustomerSeriesModel>? series,
    bool? isLoadingSeries,
    bool? isCreating,
    List<MasterDataOptionModel>? masterDataOptions,
    bool? isLoadingMasterData,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: clearError ? null : (error ?? this.error),
      createError: clearCreateError ? null : (createError ?? this.createError),
      series: series ?? this.series,
      isLoadingSeries: isLoadingSeries ?? this.isLoadingSeries,
      isCreating: isCreating ?? this.isCreating,
      masterDataOptions: masterDataOptions ?? this.masterDataOptions,
      isLoadingMasterData: isLoadingMasterData ?? this.isLoadingMasterData,
    );
  }
}
