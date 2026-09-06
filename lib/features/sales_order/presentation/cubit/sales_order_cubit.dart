import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/core/constants/customer_odbc_scope.dart';
import 'package:sales_medical_app_mobile/core/utils/format_date.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/entities/customer.dart'
    as odbc_customer;
import 'package:sales_medical_app_mobile/features/customers/domain/usecases/get_customers_usecase.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/offline_item_lookup_exception.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/create_delivery_request_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/create_return_from_delivery_request_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/create_sales_order_request_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/item_batch_quantity_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/item_lookup_response_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_line_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_list_item_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/erp_customer_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_ready_for_delivery_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_response_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/domain/repositories/sales_order_repository.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_state.dart';

class SalesOrderCubit extends Cubit<SalesOrderState> {
  SalesOrderCubit({
    required this.repository,
    required this.authRepository,
    required this.getOdbcCustomersUseCase,
  }) : super(const SalesOrderState());

  /// Page size for GET `/api/erp/deliveries` (skip increments on scroll).
  static const int kOrdersPageSize = 20;

  static const int kDeliveriesPageSize = 20;

  /// Page size for GET `/api/erp/returns` (skip increments on scroll).
  static const int kReturnsPageSize = 20;

  /// Page size for GET `/api/MasterData/customers/odbc` (pageNumber increments on scroll).
  static const int kOdbcCustomersPageSize = 20;

  final SalesOrderRepository repository;
  final AuthRepository authRepository;
  final GetCustomersUseCase getOdbcCustomersUseCase;

  /// Ignores outdated GET /sales-orders/{docEntry} responses when switching docs quickly.
  int _salesOrderSearchRequestId = 0;

  /// Last search sent to ODBC customers (null = no search filter).
  String? _lastOdbcCustomersSearch;

  void _emitIfOpen(SalesOrderState nextState) {
    if (!isClosed) emit(nextState);
  }

  /// GET `/api/erp/sales-orders/ready-for-delivery` (e.g. visit “Create delivery” picker).
  /// When [customerCardCode] is set (visit customer), only rows with matching [SalesOrderReadyForDeliveryModel.cardCode] are returned.
  Future<List<SalesOrderReadyForDeliveryModel>>
  loadSalesOrdersReadyForDelivery({String? customerCardCode}) async {
    final all = await repository.getSalesOrdersReadyForDelivery();
    return _restrictReadyRowsToCustomer(all, customerCardCode);
  }

  /// GET `/api/erp/deliveries/ready-for-return` (e.g. visit “Create return” picker).
  /// When [customerCardCode] is set, only deliveries for that ERP card code are returned.
  Future<List<SalesOrderReadyForDeliveryModel>> loadDeliveriesReadyForReturn({
    String? customerCardCode,
  }) async {
    final all = await repository.getDeliveriesReadyForReturn();
    return _restrictReadyRowsToCustomer(all, customerCardCode);
  }

  List<SalesOrderReadyForDeliveryModel> _restrictReadyRowsToCustomer(
    List<SalesOrderReadyForDeliveryModel> rows,
    String? customerCardCode,
  ) {
    final key = customerCardCode?.trim().toLowerCase();
    if (key == null || key.isEmpty) return rows;
    return rows
        .where((e) => (e.cardCode ?? '').trim().toLowerCase() == key)
        .toList();
  }

  Future<void> loadCustomers({
    int? salesEmployeeCode,
    String? search,
    bool append = false,
  }) async {
    final normSearch = _normalizeOdbcCustomerSearch(search);
    if (append) {
      if (!state.customersHasMore ||
          state.isLoadingMoreCustomers ||
          state.isLoadingCustomers) {
        return;
      }
      _emitIfOpen(
        state.copyWith(isLoadingMoreCustomers: true, customersError: null),
      );
    } else {
      _lastOdbcCustomersSearch = normSearch;
      _emitIfOpen(
        state.copyWith(
          isLoadingCustomers: true,
          isLoadingMoreCustomers: false,
          customersError: null,
          customersHasMore: true,
        ),
      );
    }

    final skip = append ? state.customers.length : 0;
    final searchForApi = append ? _lastOdbcCustomersSearch : normSearch;
    final pageNumber = (skip ~/ kOdbcCustomersPageSize) + 1;

    try {
      final odbcList = await getOdbcCustomersUseCase(
        search: searchForApi,
        salesEmployeeCode: salesEmployeeCode,
        pageNumber: pageNumber,
        pageSize: kOdbcCustomersPageSize,
        activeOnly: true,
        scope: CustomerOdbcScope.all,
      );
      final list = odbcList.map(_odbcCustomerToErp).toList();
      final hasMore = list.length == kOdbcCustomersPageSize;
      final merged = append ? [...state.customers, ...list] : list;
      final nextState = state.copyWith(
        customers: merged,
        isLoadingCustomers: false,
        isLoadingMoreCustomers: false,
        customersHasMore: hasMore,
        customersError: null,
      );
      if (state.initialCardCode != null &&
          state.initialCardCode!.trim().isNotEmpty) {
        _emitIfOpen(
          nextState.copyWith(selectedCardCode: state.initialCardCode!.trim()),
        );
      } else {
        _emitIfOpen(nextState);
      }
    } catch (e) {
      if (append) {
        _emitIfOpen(state.copyWith(isLoadingMoreCustomers: false));
      } else {
        _emitIfOpen(
          state.copyWith(
            isLoadingCustomers: false,
            customersError: e.toString().replaceFirst('Exception: ', ''),
          ),
        );
      }
    }
  }

  ErpCustomerModel _odbcCustomerToErp(odbc_customer.Customer c) {
    return ErpCustomerModel(
      code: c.customerCode,
      name: c.name,
      foreignName: c.foreignName.isNotEmpty ? c.foreignName : null,
      address: c.address,
      city: c.city,
      phone: c.phone,
      email: c.email,
      balance: c.balance,
      cardType: c.cardType,
    );
  }

  String? _normalizeOdbcCustomerSearch(String? search) {
    final t = search?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  void selectCustomer(String? cardCode) {
    emit(state.copyWith(selectedCardCode: cardCode));
  }

  void setRemarks(String? value) {
    emit(state.copyWith(remarks: value));
  }

  /// Set when opening the page from a visit (standalone or journey). Create request will send this; null = empty.
  void setVisitId(String? visitId) {
    emit(state.copyWith(visitId: visitId));
  }

  /// Set when opening from a visit so customer is pre-selected and locked. Call before loadCustomers.
  void setInitialCustomer(String? cardCode, String? customerName) {
    emit(
      state.copyWith(
        initialCardCode: cardCode,
        initialCustomerName: customerName,
      ),
    );
  }

  /// GET `/api/MasterData/items/lookup-odbc` with paging (`take` = [kOdbcItemLookupTake]).
  /// When [skip] is 0, shows loading and emits error if no matches (unless [silent]).
  Future<ItemLookupResponseModel?> loadItemLookupOdbc(
    String? code, {
    int skip = 0,
    int take = kOdbcItemLookupTake,
    bool silent = false,
  }) async {
    final effectiveCode = code?.trim();
    if (effectiveCode == null || effectiveCode.isEmpty) {
      if (!silent) {
        emit(state.copyWith(lookupError: 'Enter item code'));
      }
      return null;
    }

    if (skip == 0 && !silent) {
      emit(state.copyWith(isLoadingLookup: true, lookupError: null));
    }

    try {
      final customerCode =
          state.selectedCardCode?.trim().isEmpty == true
              ? null
              : state.selectedCardCode?.trim();
      final wh = await authRepository.getStoredDefaultWarehouseCode();
      final warehouseCode =
          (wh != null && wh.trim().isNotEmpty) ? wh.trim() : null;
      final response = await repository.getItemsLookup(
        code: effectiveCode,
        customerCode: customerCode,
        warehouseCode: warehouseCode,
        skip: skip,
        take: take,
      );

      if (skip == 0) {
        if (!silent) {
          emit(state.copyWith(isLoadingLookup: false, lookupError: null));
          if (response.expandedLinePickBundles().isEmpty) {
            emit(state.copyWith(lookupError: 'Item not found'));
            return null;
          }
        } else {
          if (response.expandedLinePickBundles().isEmpty) {
            return null;
          }
        }
      }
      return response;
    } catch (e) {
      if (skip == 0 && !silent) {
        final msg =
            e is OfflineItemLookupCacheMiss ? e.message : 'Item not found';
        emit(state.copyWith(isLoadingLookup: false, lookupError: msg));
      }
      return null;
    }
  }

  /// Builds a line from a lookup row (per-item uoMs / price).
  ItemLookupResult itemLookupResultFromRow(ItemLookupRowBundle row) {
    return itemLookupResultFromProduct(
      row.product,
      ItemLookupResponseModel(
        product: row.product,
        uoMs: row.uoMs,
        price: row.price,
      ),
    );
  }

  /// Builds an order line from ODBC lookup after a single product is chosen.
  ItemLookupResult itemLookupResultFromProduct(
    ItemProductModel product,
    ItemLookupResponseModel response,
  ) {
    final row = response.rowForProductCode(product.code);
    final price = product.defaultPrice ?? row?.price ?? response.price ?? 0;
    final uom =
        product.unitOfMeasure?.trim().isNotEmpty == true
            ? product.unitOfMeasure!
            : 'unit';

    List<ItemUoMModel>? effectiveUoMs = row?.uoMs ?? response.uoMs;
    if (effectiveUoMs != null && effectiveUoMs.isNotEmpty) {
      final hasProductUom = effectiveUoMs.any((u) => u.uoMCode == uom);
      if (!hasProductUom) {
        effectiveUoMs = [
          ItemUoMModel(uoMEntry: null, uoMCode: uom, name: null),
          ...effectiveUoMs,
        ];
      }
    }

    int? uoMEntry;
    if (effectiveUoMs != null) {
      final match = effectiveUoMs.where((u) => u.uoMCode == uom).toList();
      if (match.isNotEmpty) uoMEntry = match.first.uoMEntry;
    }

    return ItemLookupResult(
      barcode: product.barcode,
      itemCode: product.code,
      itemName: product.name ?? product.code,
      quantity: 0,
      unitPrice: price.toDouble(),
      unitOfMeasure: uom,
      unitOfMeasureEntry: uoMEntry,
      vatGroup: null,
      uoMs: effectiveUoMs,
      onHand: product.onHand,
    );
  }

  void addLine(SalesOrderLineModel line) {
    final hasFree = (line.uFree ?? '').trim().isNotEmpty;
    final toAdd =
        hasFree ? line : line.copyWith(uFree: defaultFreeGoodsCode());
    emit(state.copyWith(lines: [...state.lines, toAdd]));
  }

  /// Default Free (`U_FREE`) code: `N` (No) from the loaded free-goods list when present.
  String defaultFreeGoodsCode() {
    for (final o in state.freeGoodsOptions) {
      final code = o.code.trim();
      if (code.toUpperCase() == 'N') return code;
    }
    return 'N';
  }

  void removeLineAt(int index) {
    if (index < 0 || index >= state.lines.length) return;
    final newLines = List<SalesOrderLineModel>.from(state.lines)
      ..removeAt(index);
    emit(state.copyWith(lines: newLines));
  }

  void updateLineQuantity(int index, num quantity) {
    if (index < 0 || index >= state.lines.length) return;
    final newLines = List<SalesOrderLineModel>.from(state.lines)
      ..[index] = state.lines[index].copyWith(quantity: quantity);
    emit(state.copyWith(lines: newLines));
  }

  void updateLineVatGroup(int index, String? vatGroup) {
    if (index < 0 || index >= state.lines.length) return;
    final newLines = List<SalesOrderLineModel>.from(state.lines)
      ..[index] = state.lines[index].copyWith(
        vatGroup: vatGroup,
        clearVatGroup: vatGroup == null,
      );
    emit(state.copyWith(lines: newLines));
  }

  void updateLineFreeGoods(int index, String? uFree) {
    if (index < 0 || index >= state.lines.length) return;
    final newLines = List<SalesOrderLineModel>.from(state.lines)
      ..[index] = state.lines[index].copyWith(
        uFree: uFree,
        clearUFree: uFree == null,
      );
    emit(state.copyWith(lines: newLines));
  }

  void updateLineUnitOfMeasure(int index, String? uoMCode) {
    if (index < 0 || index >= state.lines.length) return;
    final line = state.lines[index];
    final code = uoMCode ?? line.unitOfMeasure;
    int? entry = line.unitOfMeasureEntry;
    if (code != null && line.uoMs != null) {
      final match = line.uoMs!.where((u) => u.uoMCode == code).toList();
      if (match.isNotEmpty) entry = match.first.uoMEntry;
    }
    final newLines = List<SalesOrderLineModel>.from(state.lines)
      ..[index] = line.copyWith(
        unitOfMeasure: code ?? line.unitOfMeasure,
        unitOfMeasureEntry: entry,
      );
    emit(state.copyWith(lines: newLines));
  }

  void updateLineUnitPrice(int index, num unitPrice) {
    if (index < 0 || index >= state.lines.length) return;
    final newLines = List<SalesOrderLineModel>.from(state.lines)
      ..[index] = state.lines[index].copyWith(unitPrice: unitPrice);
    emit(state.copyWith(lines: newLines));
  }

  Future<void> loadVatCodes() async {
    _emitIfOpen(state.copyWith(isLoadingVatCodes: true));
    try {
      final list = await repository.getVatCodes();
      _emitIfOpen(state.copyWith(vatCodes: list, isLoadingVatCodes: false));
    } catch (_) {
      _emitIfOpen(state.copyWith(isLoadingVatCodes: false));
    }
  }

  Future<void> loadFreeGoodsList() async {
    _emitIfOpen(state.copyWith(isLoadingFreeGoods: true));
    try {
      final list = await repository.getFreeGoodsList();
      String defaultCode = 'N';
      for (final o in list) {
        final code = o.code.trim();
        if (code.toUpperCase() == 'N') {
          defaultCode = code;
          break;
        }
      }
      final patchedLines =
          state.lines
              .map(
                (l) =>
                    (l.uFree ?? '').trim().isEmpty
                        ? l.copyWith(uFree: defaultCode)
                        : l,
              )
              .toList();
      _emitIfOpen(
        state.copyWith(
          freeGoodsOptions: list,
          lines: patchedLines,
          isLoadingFreeGoods: false,
        ),
      );
    } catch (_) {
      _emitIfOpen(state.copyWith(isLoadingFreeGoods: false));
    }
  }

  /// POST /api/erp/sales-orders/{docEntry}/cancel for the currently edited
  /// order. Returns the parsed envelope so the page can show success/error in
  /// a popup. On success the editing state is cleared and the list cache is
  /// invalidated so a re-open fetches fresh data.
  Future<SalesOrderResponseModel> cancelEditingSalesOrder() async {
    final docEntry = state.editingDocNum;
    if (docEntry == null) {
      return const SalesOrderResponseModel(
        success: false,
        errorMessage: 'No sales order is being edited.',
      );
    }
    emit(state.copyWith(isSubmitting: true, clearSubmitError: true));
    try {
      final response = await repository.cancelSalesOrder(docEntry);
      if (response.success) {
        emit(
          state.copyWith(
            isSubmitting: false,
            lines: const [],
            remarks: null,
            clearEditingDocNum: true,
            ordersList: const [],
          ),
        );
      } else {
        emit(
          state.copyWith(
            isSubmitting: false,
            submitError: response.errorMessage,
          ),
        );
      }
      return response;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(isSubmitting: false, submitError: msg));
      return SalesOrderResponseModel(success: false, errorMessage: msg);
    }
  }

  Future<bool> submitOrder() async {
    final cardCode = state.selectedCardCode?.trim();
    if (cardCode == null || cardCode.isEmpty) {
      emit(state.copyWith(submitError: 'Please select a customer'));
      return false;
    }
    if (state.lines.isEmpty) {
      emit(state.copyWith(submitError: 'Please add at least one item'));
      return false;
    }
    emit(state.copyWith(isSubmitting: true, submitError: null));

    try {
      final defaultWh = await authRepository.getStoredDefaultWarehouseCode();
      final whTrim = defaultWh?.trim();
      final whForRequest =
          (whTrim != null && whTrim.isNotEmpty) ? whTrim : null;

      final linesWithWarehouse =
          state.lines.map((l) {
            final lineWh = l.warehouseCode?.trim();
            final effective =
                (lineWh != null && lineWh.isNotEmpty) ? lineWh : whForRequest;
            return l.copyWith(warehouseCode: effective);
          }).toList();

      final wasUpdate = state.editingDocNum != null;
      final request = CreateSalesOrderRequestModel(
        cardCode: cardCode,
        remarks: state.remarks?.trim().isEmpty == true ? null : state.remarks,
        lines: linesWithWarehouse,
        visitId: state.visitId?.trim().isEmpty == true ? null : state.visitId,
        warehouseCode: whForRequest,
        docDueDate: wasUpdate ? state.editingDocDueDate : null,
      );

      final SalesOrderResponseModel response;
      if (wasUpdate) {
        response = await repository.patchSalesOrder(
          state.editingDocNum!,
          request,
        );
      } else {
        response = await repository.createSalesOrder(request);
      }

      emit(
        state.copyWith(
          isSubmitting: false,
          submitError:
              response.success ? null : (response.errorMessage ?? 'Failed'),
          clearSubmitError: response.success,
          lastDocumentNumber: response.documentNumber,
          lastDocumentId: response.documentId,
          lastSubmitWasUpdate: response.success ? wasUpdate : false,
        ),
      );

      if (response.success) {
        emit(
          state.copyWith(lines: [], remarks: null, clearEditingDocNum: true),
        );
      }

      return response.success;
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          submitError: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }

  void clearSubmitError() {
    emit(state.copyWith(clearSubmitError: true));
  }

  /// Load sales orders from GET /api/erp/sales-orders (uses [state] order filters).
  /// [append]: next page (`skip` = current list length), `take` = [kOrdersPageSize].
  Future<void> loadSalesOrdersList({
    String? visitId,
    int? salesEmployeeCode,
    bool append = false,
  }) async {
    final cc = state.ordersFilterCustomerCode?.trim();
    final customerCode = (cc != null && cc.isNotEmpty) ? cc : null;
    final dateFrom = _ordersDateFromIso(state.ordersFilterDateFrom);
    final dateTo = _ordersDateToIso(state.ordersFilterDateTo);

    if (append) {
      if (!state.ordersListHasMore ||
          state.isLoadingMoreOrdersList ||
          state.isLoadingOrdersList) {
        return;
      }
      emit(state.copyWith(isLoadingMoreOrdersList: true));
    } else {
      emit(
        state.copyWith(
          isLoadingOrdersList: true,
          ordersListError: null,
          ordersListHasMore: true,
        ),
      );
    }

    final skip = append ? state.ordersList.length : 0;

    try {
      final list = await repository.getSalesOrders(
        visitId: visitId,
        customerCode: customerCode,
        dateFrom: dateFrom,
        dateTo: dateTo,
        salesEmployeeCode: salesEmployeeCode,
        skip: skip,
        take: kOrdersPageSize,
      );
      final hasMore = list.length == kOrdersPageSize;
      final merged = append ? [...state.ordersList, ...list] : list;
      emit(
        state.copyWith(
          ordersList: merged,
          isLoadingOrdersList: false,
          isLoadingMoreOrdersList: false,
          ordersListHasMore: hasMore,
          ordersListError: null,
        ),
      );
    } catch (e) {
      if (append) {
        emit(state.copyWith(isLoadingMoreOrdersList: false));
      } else {
        emit(
          state.copyWith(
            isLoadingOrdersList: false,
            ordersListError: e.toString().replaceFirst('Exception: ', ''),
          ),
        );
      }
    }
  }

  static String? _ordersDateFromIso(DateTime? d) {
    if (d == null) return null;
    final start = DateTime(d.year, d.month, d.day);
    return start.toUtc().toIso8601String();
  }

  static String? _ordersDateToIso(DateTime? d) {
    if (d == null) return null;
    final end = DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
    return end.toUtc().toIso8601String();
  }

  /// Sets order list filters and reloads GET /api/erp/sales-orders.
  Future<void> applyOrdersFilters({
    required String? visitId,
    int? salesEmployeeCode,
    String? customerCode,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    emit(
      state.copyWith(
        updateOrdersFilters: true,
        ordersFilterCustomerCode: customerCode,
        ordersFilterDateFrom: dateFrom,
        ordersFilterDateTo: dateTo,
      ),
    );
    await loadSalesOrdersList(
      visitId: visitId,
      salesEmployeeCode: salesEmployeeCode,
    );
  }

  Future<void> clearOrdersFilters({
    required String? visitId,
    int? salesEmployeeCode,
  }) async {
    emit(state.copyWith(clearOrdersFilters: true));
    await loadSalesOrdersList(
      visitId: visitId,
      salesEmployeeCode: salesEmployeeCode,
    );
  }

  static String? _deliveriesDateFromIso(DateTime? d) {
    if (d == null) return null;
    final start = DateTime(d.year, d.month, d.day);
    return start.toUtc().toIso8601String();
  }

  static String? _deliveriesDateToIso(DateTime? d) {
    if (d == null) return null;
    final end = DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
    return end.toUtc().toIso8601String();
  }

  /// Load deliveries from GET /api/erp/deliveries (uses [state] delivery filters).
  /// [append]: next page (`skip` = current list length), `take` = [kDeliveriesPageSize].
  Future<void> loadDeliveriesList({
    int? salesEmployeeCode,
    bool append = false,
  }) async {
    final cc = state.deliveriesFilterCustomerCode?.trim();
    final customerCode = (cc != null && cc.isNotEmpty) ? cc : null;
    final dateFrom = _deliveriesDateFromIso(state.deliveriesFilterDateFrom);
    final dateTo = _deliveriesDateToIso(state.deliveriesFilterDateTo);

    if (append) {
      if (!state.deliveriesListHasMore ||
          state.isLoadingMoreDeliveriesList ||
          state.isLoadingDeliveriesList) {
        return;
      }
      emit(state.copyWith(isLoadingMoreDeliveriesList: true));
    } else {
      emit(
        state.copyWith(
          isLoadingDeliveriesList: true,
          deliveriesListError: null,
          deliveriesListHasMore: true,
        ),
      );
    }

    final skip = append ? state.deliveriesList.length : 0;

    try {
      final list = await repository.getDeliveries(
        salesEmployeeCode: salesEmployeeCode,
        customerCode: customerCode,
        dateFrom: dateFrom,
        dateTo: dateTo,
        skip: skip,
        take: kDeliveriesPageSize,
      );
      final hasMore = list.length == kDeliveriesPageSize;
      final merged = append ? [...state.deliveriesList, ...list] : list;
      emit(
        state.copyWith(
          deliveriesList: merged,
          isLoadingDeliveriesList: false,
          isLoadingMoreDeliveriesList: false,
          deliveriesListHasMore: hasMore,
          deliveriesListError: null,
        ),
      );
    } catch (e) {
      if (append) {
        emit(state.copyWith(isLoadingMoreDeliveriesList: false));
      } else {
        emit(
          state.copyWith(
            isLoadingDeliveriesList: false,
            deliveriesListError: e.toString().replaceFirst('Exception: ', ''),
          ),
        );
      }
    }
  }

  /// Sets delivery list filters and reloads. Pass null to clear a date or customer.
  Future<void> applyDeliveriesFilters({
    required int? salesEmployeeCode,
    String? customerCode,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    emit(
      state.copyWith(
        updateDeliveriesFilters: true,
        deliveriesFilterCustomerCode: customerCode,
        deliveriesFilterDateFrom: dateFrom,
        deliveriesFilterDateTo: dateTo,
      ),
    );
    await loadDeliveriesList(salesEmployeeCode: salesEmployeeCode);
  }

  Future<void> clearDeliveriesFilters({required int? salesEmployeeCode}) async {
    emit(state.copyWith(clearDeliveriesFilters: true));
    await loadDeliveriesList(salesEmployeeCode: salesEmployeeCode);
  }

  /// Load returns from GET /api/erp/returns (uses [state] return filters).
  /// [append]: next page (`skip` = current list length), `take` = [kReturnsPageSize].
  Future<void> loadReturnsList({
    int? salesEmployeeCode,
    bool append = false,
  }) async {
    final cc = state.returnsFilterCustomerCode?.trim();
    final customerCode = (cc != null && cc.isNotEmpty) ? cc : null;
    final dateFrom = _deliveriesDateFromIso(state.returnsFilterDateFrom);
    final dateTo = _deliveriesDateToIso(state.returnsFilterDateTo);

    if (append) {
      if (!state.returnsListHasMore ||
          state.isLoadingMoreReturnsList ||
          state.isLoadingReturnsList) {
        return;
      }
      emit(state.copyWith(isLoadingMoreReturnsList: true));
    } else {
      emit(
        state.copyWith(
          isLoadingReturnsList: true,
          returnsListError: null,
          returnsListHasMore: true,
        ),
      );
    }

    final skip = append ? state.returnsList.length : 0;

    try {
      final list = await repository.getReturns(
        salesEmployeeCode: salesEmployeeCode,
        customerCode: customerCode,
        dateFrom: dateFrom,
        dateTo: dateTo,
        skip: skip,
        take: kReturnsPageSize,
      );
      final hasMore = list.length == kReturnsPageSize;
      final merged = append ? [...state.returnsList, ...list] : list;
      emit(
        state.copyWith(
          returnsList: merged,
          isLoadingReturnsList: false,
          isLoadingMoreReturnsList: false,
          returnsListHasMore: hasMore,
          returnsListError: null,
        ),
      );
    } catch (e) {
      if (append) {
        emit(state.copyWith(isLoadingMoreReturnsList: false));
      } else {
        emit(
          state.copyWith(
            isLoadingReturnsList: false,
            returnsListError: e.toString().replaceFirst('Exception: ', ''),
          ),
        );
      }
    }
  }

  Future<void> applyReturnsFilters({
    required int? salesEmployeeCode,
    String? customerCode,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    emit(
      state.copyWith(
        updateReturnsFilters: true,
        returnsFilterCustomerCode: customerCode,
        returnsFilterDateFrom: dateFrom,
        returnsFilterDateTo: dateTo,
      ),
    );
    await loadReturnsList(salesEmployeeCode: salesEmployeeCode);
  }

  Future<void> clearReturnsFilters({required int? salesEmployeeCode}) async {
    emit(state.copyWith(clearReturnsFilters: true));
    await loadReturnsList(salesEmployeeCode: salesEmployeeCode);
  }

  Future<SalesOrderListItemModel> getReturnByDocEntry(int docEntry) {
    return repository.getReturnByDocEntry(docEntry);
  }

  Future<SalesOrderResponseModel> createReturnFromDelivery(
    CreateReturnFromDeliveryRequestModel request,
  ) {
    final fromRequest = request.visitId?.trim();
    final fromState = state.visitId?.trim();
    final visitIdForPost =
        (fromRequest != null && fromRequest.isNotEmpty)
            ? fromRequest
            : (fromState != null && fromState.isNotEmpty ? fromState : null);
    final effective =
        visitIdForPost == null
            ? request
            : CreateReturnFromDeliveryRequestModel(
              deliveryDocEntry: request.deliveryDocEntry,
              returnDate: request.returnDate,
              remarks: request.remarks,
              reason: request.reason,
              lines: request.lines,
              visitId: visitIdForPost,
              warehouseCode: request.warehouseCode,
            );
    return repository.createReturnFromDelivery(effective);
  }

  void searchSalesOrdersWithError(String message) {
    emit(state.copyWith(searchError: message));
  }

  Future<void> searchSalesOrders({required int docEntry}) async {
    final requestId = ++_salesOrderSearchRequestId;
    // Drop previous doc lines immediately so Qty fields cannot mount with stale values.
    emit(
      state.copyWith(
        isLoadingSearch: true,
        searchError: null,
        clearFormData: true,
        clearEditingDocNum: true,
      ),
    );
    try {
      final order = await repository.getSalesOrderByDocEntry(docEntry);
      if (requestId != _salesOrderSearchRequestId) return;
      loadOrderForEdit(order);
      emit(state.copyWith(isLoadingSearch: false));
    } catch (e) {
      if (requestId != _salesOrderSearchRequestId) return;
      emit(
        state.copyWith(
          isLoadingSearch: false,
          searchError: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<SalesOrderListItemModel> getSalesOrderByDocEntry(int docEntry) {
    return repository.getSalesOrderByDocEntry(docEntry);
  }

  Future<SalesOrderListItemModel> getDeliveryByDocEntry(int docEntry) {
    return repository.getDeliveryByDocEntry(docEntry);
  }

  /// POST /api/erp/deliveries/{docEntry}/cancel — used by the delivery view
  /// page when status is `bost_Open`.
  Future<SalesOrderResponseModel> cancelDeliveryByDocEntry(int docEntry) {
    return repository.cancelDelivery(docEntry);
  }

  Future<List<ItemBatchQuantityModel>> getItemBatchQuantities({
    required String itemCode,
    String? warehouseCode,
  }) {
    return repository.getItemBatchQuantities(
      itemCode: itemCode,
      warehouseCode: warehouseCode,
    );
  }

  Future<SalesOrderResponseModel> createDelivery(
    CreateDeliveryRequestModel request,
  ) {
    final fromRequest = request.visitId?.trim();
    final fromState = state.visitId?.trim();
    final visitIdForPost =
        (fromRequest != null && fromRequest.isNotEmpty)
            ? fromRequest
            : (fromState != null && fromState.isNotEmpty ? fromState : null);
    final effective =
        visitIdForPost == null
            ? request
            : CreateDeliveryRequestModel(
              salesOrderDocEntry: request.salesOrderDocEntry,
              deliveryDate: request.deliveryDate,
              remarks: request.remarks,
              lines: request.lines,
              warehouseCode: request.warehouseCode,
              visitId: visitIdForPost,
            );
    return repository.createDelivery(effective);
  }

  void loadOrderForEdit(SalesOrderListItemModel order) {
    final docEntry = order.docEntry ?? order.docNum;
    if (docEntry == null) return;
    final lines =
        order.lines
            .map(
              (l) => SalesOrderLineModel(
                barcode: l.barcode,
                itemCode: l.itemCode,
                itemName: l.itemName,
                quantity: l.quantity ?? 0,
                unitPrice: l.unitPrice ?? 0,
                unitOfMeasure: l.unitOfMeasure,
                unitOfMeasureEntry: null,
                vatGroup: l.vatGroup,
                uoMs: null,
                warehouseCode: l.warehouseCode,
                onHand: null,
                currency: l.currency ?? order.currency,
                uFree: l.uFree,
              ),
            )
            .toList();
    emit(
      state.copyWith(
        selectedCardCode: order.cardCode,
        remarks: order.remarks,
        lines: lines,
        editingDocNum: docEntry,
        editingDocumentStatus: order.documentStatus,
        editingOrder: order,
        editingDocDueDate: parseIsoDateTime(order.docDueDate),
        searchResults: [],
        searchError: null,
      ),
    );
  }

  void setEditingDocDueDate(DateTime? value) {
    emit(state.copyWith(editingDocDueDate: value));
  }

  void clearEditMode() {
    emit(
      state.copyWith(
        clearEditingDocNum: true,
        clearFormData: true,
        searchResults: [],
        searchError: null,
      ),
    );
  }

  /// Clears form and edit state so the page shows a fresh "new order". Call when opening Sales Order for create.
  void resetFormForNewEntry() {
    emit(
      state.copyWith(
        clearEditingDocNum: true,
        clearFormData: true,
        clearSubmitError: true,
        clearInitialCustomer: true,
        clearVisitId: true,
        searchResults: [],
        searchError: null,
      ),
    );
  }

  void clearSearchResults() {
    emit(state.copyWith(searchResults: [], searchError: null));
  }
}

class ItemLookupResult {
  const ItemLookupResult({
    this.barcode,
    this.itemCode,
    this.itemName,
    this.quantity = 0,
    this.unitPrice = 0,
    this.unitOfMeasure,
    this.unitOfMeasureEntry,
    this.vatGroup,
    this.uoMs,
    this.onHand,
  });

  final String? barcode;
  final String? itemCode;
  final String? itemName;
  final num quantity;
  final num unitPrice;
  final String? unitOfMeasure;
  final int? unitOfMeasureEntry;
  final String? vatGroup;
  final List<ItemUoMModel>? uoMs;
  final num? onHand;

  SalesOrderLineModel toLine({String? warehouseCode}) {
    return SalesOrderLineModel(
      barcode: barcode,
      itemCode: itemCode,
      itemName: itemName,
      quantity: quantity,
      unitPrice: unitPrice,
      unitOfMeasure: unitOfMeasure,
      unitOfMeasureEntry: unitOfMeasureEntry,
      vatGroup: vatGroup,
      uoMs: uoMs,
      warehouseCode: warehouseCode,
      onHand: onHand,
    );
  }
}
