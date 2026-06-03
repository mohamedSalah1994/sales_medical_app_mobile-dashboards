part of 'customers_cubit.dart';

class CustomersState {
  final List<Customer> customers;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;
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
      error: error ?? this.error,
      series: series ?? this.series,
      isLoadingSeries: isLoadingSeries ?? this.isLoadingSeries,
      isCreating: isCreating ?? this.isCreating,
      masterDataOptions: masterDataOptions ?? this.masterDataOptions,
      isLoadingMasterData: isLoadingMasterData ?? this.isLoadingMasterData,
    );
  }
}
