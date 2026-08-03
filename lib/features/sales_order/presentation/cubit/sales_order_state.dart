import 'package:equatable/equatable.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/erp_customer_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/free_goods_option_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_line_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_list_item_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/vat_code_model.dart';

class SalesOrderState extends Equatable {
  const SalesOrderState({
    this.customers = const [],
    this.isLoadingCustomers = false,
    this.isLoadingMoreCustomers = false,
    this.customersHasMore = true,
    this.customersError,
    this.selectedCardCode,
    this.remarks,
    this.lines = const [],
    this.isLoadingLookup = false,
    this.lookupError,
    this.isSubmitting = false,
    this.submitError,
    this.lastDocumentNumber,
    this.lastDocumentId,
    this.lastSubmitWasUpdate = false,
    this.vatCodes = const [],
    this.isLoadingVatCodes = false,
    this.freeGoodsOptions = const [],
    this.isLoadingFreeGoods = false,
    this.editingDocNum,
    this.editingDocumentStatus,
    this.editingOrder,
    this.editingDocDueDate,
    this.searchResults = const [],
    this.isLoadingSearch = false,
    this.searchError,
    this.ordersList = const [],
    this.isLoadingOrdersList = false,
    this.ordersListError,
    this.deliveriesList = const [],
    this.isLoadingDeliveriesList = false,
    this.isLoadingMoreDeliveriesList = false,
    this.deliveriesListHasMore = true,
    this.deliveriesListError,
    this.deliveriesFilterCustomerCode,
    this.deliveriesFilterDateFrom,
    this.deliveriesFilterDateTo,
    this.returnsList = const [],
    this.isLoadingReturnsList = false,
    this.isLoadingMoreReturnsList = false,
    this.returnsListHasMore = true,
    this.returnsListError,
    this.returnsFilterCustomerCode,
    this.returnsFilterDateFrom,
    this.returnsFilterDateTo,
    this.ordersFilterCustomerCode,
    this.ordersFilterDateFrom,
    this.ordersFilterDateTo,
    this.visitId,
    this.initialCardCode,
    this.initialCustomerName,
  });

  final List<ErpCustomerModel> customers;
  final bool isLoadingCustomers;
  final bool isLoadingMoreCustomers;
  final bool customersHasMore;
  final String? customersError;
  final String? selectedCardCode;
  final String? remarks;
  final List<SalesOrderLineModel> lines;
  final bool isLoadingLookup;
  final String? lookupError;
  final bool isSubmitting;
  final String? submitError;
  final String? lastDocumentNumber;
  final String? lastDocumentId;
  final bool lastSubmitWasUpdate;
  final List<VatCodeModel> vatCodes;
  final bool isLoadingVatCodes;
  final List<FreeGoodsOptionModel> freeGoodsOptions;
  final bool isLoadingFreeGoods;
  final int? editingDocNum;
  final String? editingDocumentStatus;

  /// Snapshot from GET when editing; drives document header UI.
  final SalesOrderListItemModel? editingOrder;

  /// Due date while editing an open order; sent as `docDueDate` on PATCH.
  final DateTime? editingDocDueDate;
  final List<SalesOrderListItemModel> searchResults;
  final bool isLoadingSearch;
  final String? searchError;
  final List<SalesOrderListItemModel> ordersList;
  final bool isLoadingOrdersList;
  final String? ordersListError;
  final List<SalesOrderListItemModel> deliveriesList;
  final bool isLoadingDeliveriesList;
  final bool isLoadingMoreDeliveriesList;
  /// False once a page returned fewer items than the deliveries page size (10).
  final bool deliveriesListHasMore;
  final String? deliveriesListError;

  /// ERP `customerCode` query for GET /api/erp/deliveries (card code).
  final String? deliveriesFilterCustomerCode;
  final DateTime? deliveriesFilterDateFrom;
  final DateTime? deliveriesFilterDateTo;

  final List<SalesOrderListItemModel> returnsList;
  final bool isLoadingReturnsList;
  final bool isLoadingMoreReturnsList;
  final bool returnsListHasMore;
  final String? returnsListError;

  /// ERP filters for GET /api/erp/returns.
  final String? returnsFilterCustomerCode;
  final DateTime? returnsFilterDateFrom;
  final DateTime? returnsFilterDateTo;

  /// GET /api/erp/sales-orders filters (customer + date range).
  final String? ordersFilterCustomerCode;
  final DateTime? ordersFilterDateFrom;
  final DateTime? ordersFilterDateTo;

  bool get hasActiveDeliveriesFilters =>
      (deliveriesFilterCustomerCode != null &&
          deliveriesFilterCustomerCode!.trim().isNotEmpty) ||
      deliveriesFilterDateFrom != null ||
      deliveriesFilterDateTo != null;

  bool get hasActiveReturnsFilters =>
      (returnsFilterCustomerCode != null &&
          returnsFilterCustomerCode!.trim().isNotEmpty) ||
      returnsFilterDateFrom != null ||
      returnsFilterDateTo != null;

  bool get hasActiveOrdersFilters =>
      (ordersFilterCustomerCode != null &&
          ordersFilterCustomerCode!.trim().isNotEmpty) ||
      ordersFilterDateFrom != null ||
      ordersFilterDateTo != null;

  /// When set, create request sends this visitId; when null, sends empty.
  final String? visitId;

  /// When set (e.g. from visit), customer is pre-selected and locked.
  final String? initialCardCode;
  final String? initialCustomerName;

  SalesOrderState copyWith({
    List<ErpCustomerModel>? customers,
    bool? isLoadingCustomers,
    bool? isLoadingMoreCustomers,
    bool? customersHasMore,
    String? customersError,
    String? selectedCardCode,
    String? remarks,
    List<SalesOrderLineModel>? lines,
    bool? isLoadingLookup,
    String? lookupError,
    bool? isSubmitting,
    String? submitError,
    String? lastDocumentNumber,
    String? lastDocumentId,
    bool? lastSubmitWasUpdate,
    List<VatCodeModel>? vatCodes,
    bool? isLoadingVatCodes,
    List<FreeGoodsOptionModel>? freeGoodsOptions,
    bool? isLoadingFreeGoods,
    int? editingDocNum,
    String? editingDocumentStatus,
    SalesOrderListItemModel? editingOrder,
    DateTime? editingDocDueDate,
    List<SalesOrderListItemModel>? searchResults,
    bool? isLoadingSearch,
    String? searchError,
    List<SalesOrderListItemModel>? ordersList,
    bool? isLoadingOrdersList,
    String? ordersListError,
    List<SalesOrderListItemModel>? deliveriesList,
    bool? isLoadingDeliveriesList,
    bool? isLoadingMoreDeliveriesList,
    bool? deliveriesListHasMore,
    String? deliveriesListError,
    String? deliveriesFilterCustomerCode,
    DateTime? deliveriesFilterDateFrom,
    DateTime? deliveriesFilterDateTo,
    List<SalesOrderListItemModel>? returnsList,
    bool? isLoadingReturnsList,
    bool? isLoadingMoreReturnsList,
    bool? returnsListHasMore,
    String? returnsListError,
    String? returnsFilterCustomerCode,
    DateTime? returnsFilterDateFrom,
    DateTime? returnsFilterDateTo,
    String? ordersFilterCustomerCode,
    DateTime? ordersFilterDateFrom,
    DateTime? ordersFilterDateTo,
    String? visitId,
    String? initialCardCode,
    String? initialCustomerName,
    bool clearEditingDocNum = false,
    bool clearFormData = false,
    bool clearSubmitError = false,
    bool clearInitialCustomer = false,
    bool clearVisitId = false,
    bool clearDeliveriesFilters = false,
    bool updateDeliveriesFilters = false,
    bool clearReturnsFilters = false,
    bool updateReturnsFilters = false,
    bool clearOrdersFilters = false,
    bool updateOrdersFilters = false,
  }) {
    return SalesOrderState(
      customers: customers ?? this.customers,
      isLoadingCustomers: isLoadingCustomers ?? this.isLoadingCustomers,
      isLoadingMoreCustomers:
          isLoadingMoreCustomers ?? this.isLoadingMoreCustomers,
      customersHasMore: customersHasMore ?? this.customersHasMore,
      customersError: customersError ?? this.customersError,
      selectedCardCode:
          clearFormData ? null : (selectedCardCode ?? this.selectedCardCode),
      remarks: clearFormData ? null : (remarks ?? this.remarks),
      lines: clearFormData ? const [] : (lines ?? this.lines),
      isLoadingLookup: isLoadingLookup ?? this.isLoadingLookup,
      lookupError: lookupError ?? this.lookupError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      lastDocumentNumber: lastDocumentNumber ?? this.lastDocumentNumber,
      lastDocumentId: lastDocumentId ?? this.lastDocumentId,
      lastSubmitWasUpdate: lastSubmitWasUpdate ?? this.lastSubmitWasUpdate,
      vatCodes: vatCodes ?? this.vatCodes,
      isLoadingVatCodes: isLoadingVatCodes ?? this.isLoadingVatCodes,
      freeGoodsOptions: freeGoodsOptions ?? this.freeGoodsOptions,
      isLoadingFreeGoods: isLoadingFreeGoods ?? this.isLoadingFreeGoods,
      editingDocNum:
          clearEditingDocNum ? null : (editingDocNum ?? this.editingDocNum),
      editingDocumentStatus:
          clearEditingDocNum
              ? null
              : (editingDocumentStatus ?? this.editingDocumentStatus),
      editingOrder:
          clearEditingDocNum ? null : (editingOrder ?? this.editingOrder),
      editingDocDueDate:
          clearEditingDocNum
              ? null
              : (editingDocDueDate ?? this.editingDocDueDate),
      searchResults: searchResults ?? this.searchResults,
      isLoadingSearch: isLoadingSearch ?? this.isLoadingSearch,
      searchError: searchError ?? this.searchError,
      ordersList: ordersList ?? this.ordersList,
      isLoadingOrdersList: isLoadingOrdersList ?? this.isLoadingOrdersList,
      ordersListError: ordersListError ?? this.ordersListError,
      deliveriesList: deliveriesList ?? this.deliveriesList,
      isLoadingDeliveriesList:
          isLoadingDeliveriesList ?? this.isLoadingDeliveriesList,
      isLoadingMoreDeliveriesList:
          isLoadingMoreDeliveriesList ?? this.isLoadingMoreDeliveriesList,
      deliveriesListHasMore:
          deliveriesListHasMore ?? this.deliveriesListHasMore,
      deliveriesListError: deliveriesListError ?? this.deliveriesListError,
      deliveriesFilterCustomerCode:
          clearDeliveriesFilters
              ? null
              : updateDeliveriesFilters
              ? deliveriesFilterCustomerCode
              : (deliveriesFilterCustomerCode ??
                  this.deliveriesFilterCustomerCode),
      deliveriesFilterDateFrom:
          clearDeliveriesFilters
              ? null
              : updateDeliveriesFilters
              ? deliveriesFilterDateFrom
              : (deliveriesFilterDateFrom ?? this.deliveriesFilterDateFrom),
      deliveriesFilterDateTo:
          clearDeliveriesFilters
              ? null
              : updateDeliveriesFilters
              ? deliveriesFilterDateTo
              : (deliveriesFilterDateTo ?? this.deliveriesFilterDateTo),
      returnsList: returnsList ?? this.returnsList,
      isLoadingReturnsList: isLoadingReturnsList ?? this.isLoadingReturnsList,
      isLoadingMoreReturnsList:
          isLoadingMoreReturnsList ?? this.isLoadingMoreReturnsList,
      returnsListHasMore: returnsListHasMore ?? this.returnsListHasMore,
      returnsListError: returnsListError ?? this.returnsListError,
      returnsFilterCustomerCode:
          clearReturnsFilters
              ? null
              : updateReturnsFilters
              ? returnsFilterCustomerCode
              : (returnsFilterCustomerCode ?? this.returnsFilterCustomerCode),
      returnsFilterDateFrom:
          clearReturnsFilters
              ? null
              : updateReturnsFilters
              ? returnsFilterDateFrom
              : (returnsFilterDateFrom ?? this.returnsFilterDateFrom),
      returnsFilterDateTo:
          clearReturnsFilters
              ? null
              : updateReturnsFilters
              ? returnsFilterDateTo
              : (returnsFilterDateTo ?? this.returnsFilterDateTo),
      ordersFilterCustomerCode:
          clearOrdersFilters
              ? null
              : updateOrdersFilters
              ? ordersFilterCustomerCode
              : (ordersFilterCustomerCode ?? this.ordersFilterCustomerCode),
      ordersFilterDateFrom:
          clearOrdersFilters
              ? null
              : updateOrdersFilters
              ? ordersFilterDateFrom
              : (ordersFilterDateFrom ?? this.ordersFilterDateFrom),
      ordersFilterDateTo:
          clearOrdersFilters
              ? null
              : updateOrdersFilters
              ? ordersFilterDateTo
              : (ordersFilterDateTo ?? this.ordersFilterDateTo),
      visitId: clearVisitId ? null : (visitId ?? this.visitId),
      initialCardCode:
          clearInitialCustomer
              ? null
              : (initialCardCode ?? this.initialCardCode),
      initialCustomerName:
          clearInitialCustomer
              ? null
              : (initialCustomerName ?? this.initialCustomerName),
    );
  }

  @override
  List<Object?> get props => [
    customers,
    isLoadingCustomers,
    isLoadingMoreCustomers,
    customersHasMore,
    customersError,
    selectedCardCode,
    remarks,
    lines,
    isLoadingLookup,
    lookupError,
    isSubmitting,
    submitError,
    lastDocumentNumber,
    lastDocumentId,
    lastSubmitWasUpdate,
    vatCodes,
    isLoadingVatCodes,
    freeGoodsOptions,
    isLoadingFreeGoods,
    editingDocNum,
    editingDocumentStatus,
    editingOrder,
    editingDocDueDate,
    searchResults,
    isLoadingSearch,
    searchError,
    ordersList,
    isLoadingOrdersList,
    ordersListError,
    deliveriesList,
    isLoadingDeliveriesList,
    isLoadingMoreDeliveriesList,
    deliveriesListHasMore,
    deliveriesListError,
    deliveriesFilterCustomerCode,
    deliveriesFilterDateFrom,
    deliveriesFilterDateTo,
    returnsList,
    isLoadingReturnsList,
    isLoadingMoreReturnsList,
    returnsListHasMore,
    returnsListError,
    returnsFilterCustomerCode,
    returnsFilterDateFrom,
    returnsFilterDateTo,
    ordersFilterCustomerCode,
    ordersFilterDateFrom,
    ordersFilterDateTo,
    visitId,
    initialCardCode,
    initialCustomerName,
  ];
}
