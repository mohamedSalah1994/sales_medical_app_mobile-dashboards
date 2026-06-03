import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/core/utils/format_date.dart';
import 'package:sales_medical_app_mobile/core/utils/odbc_card_type_label.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/erp_customer_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_line_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/vat_code_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_cubit.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_state.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/widgets/inventory_product_pick_dialog.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/item_lookup_response_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/delivery_from_sales_order_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/erp_document_header_widgets.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/helpers/register_visit_action_after_erp.dart';
import 'package:sales_medical_app_mobile/core/pdf/erp_document_pdf_factories.dart';
import 'package:sales_medical_app_mobile/core/pdf/erp_document_pdf_share.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/erp_cancel_document_dialog.dart';

class SalesOrderPage extends StatefulWidget {
  const SalesOrderPage({
    super.key,
    this.showScaffold = true,
    this.visitId,
    this.initialDocEntry,
    this.initialCardCode,
    this.initialCustomerName,
  });

  final bool showScaffold;

  /// When set, create request sends this visitId to POST /api/erp/sales-orders (links order to visit).
  final String? visitId;

  /// When set, load this order for view/edit on init.
  final int? initialDocEntry;

  /// When set (e.g. from visit), customer is pre-selected and not editable.
  final String? initialCardCode;
  final String? initialCustomerName;

  @override
  State<SalesOrderPage> createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage> {
  final _remarksController = TextEditingController();
  final _itemSearchController = TextEditingController();
  Timer? _customerPickerSearchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<SalesOrderCubit>();
      if (widget.initialDocEntry == null) {
        cubit.resetFormForNewEntry();
      } else {
        final docEntry = widget.initialDocEntry!;
        final alreadyLoaded = cubit.state.editingDocNum == docEntry;
        if (!alreadyLoaded) {
          cubit.searchSalesOrders(docEntry: docEntry);
        }
      }
      cubit.loadVatCodes();
      if (widget.visitId != null) cubit.setVisitId(widget.visitId);
      if (widget.initialCardCode != null ||
          widget.initialCustomerName != null) {
        cubit.setInitialCustomer(
          widget.initialCardCode,
          widget.initialCustomerName,
        );
      }
      final sapCode =
          context
              .read<AuthCubit>()
              .state
              .loginResponse
              ?.user
              .sapSalesEmployeeCode;
      cubit.loadCustomers(salesEmployeeCode: sapCode);
    });
  }

  @override
  void dispose() {
    _customerPickerSearchDebounce?.cancel();
    _remarksController.dispose();
    _itemSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SalesOrderCubit, SalesOrderState>(
      listenWhen: (p, c) => p.isSubmitting != c.isSubmitting && !c.isSubmitting,
      listener: (context, state) {
        final error = state.submitError;
        final docNumber = state.lastDocumentNumber;
        if (error != null) {
          showDialog<void>(
            context: context,
            builder:
                (ctx) => AlertDialog(
                  title: const Text('Sales Order'),
                  content: Text(error),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
        } else if (docNumber != null || state.lastDocumentId != null) {
          Future<void> syncVisitThenShowSuccess() async {
            final vid = state.visitId?.trim();
            if (!state.lastSubmitWasUpdate && vid != null && vid.isNotEmpty) {
              await registerVisitActionIfInJourneyContext(
                context,
                visitId: vid,
              );
            }
            if (!context.mounted) return;
            final parts = <String>[
              state.lastSubmitWasUpdate
                  ? 'Order updated successfully.'
                  : 'Order created successfully.',
            ];
            if (docNumber != null && docNumber.isNotEmpty) {
              parts.add('Document number: $docNumber');
            }
            if (state.lastDocumentId != null &&
                state.lastDocumentId!.isNotEmpty) {
              parts.add('Doc Entry: ${state.lastDocumentId}');
            }
            final orderMessage = parts.join(' ');
            showDialog<void>(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    title: const Text('Sales Order'),
                    content: Text(orderMessage),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
            );
          }

          syncVisitThenShowSuccess();
        }
      },
      child: BlocBuilder<SalesOrderCubit, SalesOrderState>(
        builder: (context, state) {
          _syncControllers(state);

          final loadingOrder =
              widget.initialDocEntry != null && state.isLoadingSearch;

          final content = SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.initialDocEntry != null &&
                    state.searchError != null &&
                    !state.isLoadingSearch &&
                    state.editingOrder == null) ...[
                  Text(
                    state.searchError!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (state.editingOrder != null) ...[
                  const SizedBox(height: 8),
                  ErpSalesOrderListDocumentCard(
                    order: state.editingOrder!,
                    showTotalInHeader: false,
                    dueDateEditable: state.editingDocumentStatus == 'bost_Open',
                    draftDueDate: state.editingDocDueDate,
                    onDueDateTap:
                        state.editingDocumentStatus == 'bost_Open'
                            ? () => _pickSalesOrderDueDate(context)
                            : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        context.read<SalesOrderCubit>().clearEditMode();
                      },
                      child: const Text('New order'),
                    ),
                  ),
                ],
                if (state.editingDocNum == null) ...[
                  _buildCustomerField(context, state),
                  const SizedBox(height: 8),
                ],
                const Text(
                  'Order Lines',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (state.editingDocNum == null) ...[
                  const SizedBox(height: 6),
                  _buildAddItemBar(context, state),
                  const SizedBox(height: 6),
                ] else
                  const SizedBox(height: 6),
                _buildLinesTable(context, state),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _remarksController,
                  label: 'Remarks (Optional)',
                  maxLines: 2,
                  onChanged:
                      (v) => context.read<SalesOrderCubit>().setRemarks(v),
                ),
                if (state.editingOrder != null) ...[
                  const SizedBox(height: 10),
                  ErpDocFieldRow(
                    label: 'Total',
                    value: erpDocumentTotalLabel(state.editingOrder!.docTotal),
                    fillColor: Colors.white,
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          );

          final isEditing = state.editingDocNum != null;
          final isOpenStatus = state.editingDocumentStatus == 'bost_Open';
          final canCopyToDelivery = isEditing && isOpenStatus;
          final canCancelOrder =
              isEditing && isOpenStatus && state.editingOrder != null;
          final mainFab =
              loadingOrder
                  ? null
                  : FloatingActionButton.extended(
                    heroTag: 'so-main-fab',
                    onPressed:
                        state.isSubmitting
                            ? null
                            : () async {
                              await context
                                  .read<SalesOrderCubit>()
                                  .submitOrder();
                            },
                    icon:
                        state.isSubmitting
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Icon(
                              isEditing ? Icons.save : Icons.add,
                              size: 20,
                            ),
                    label: Text(
                      isEditing ? 'Update' : 'Create',
                      style: const TextStyle(fontSize: 13),
                    ),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  );

          final pdfFab =
              (!loadingOrder && state.editingOrder != null)
                  ? FloatingActionButton.extended(
                    heroTag: 'so-pdf-fab',
                    tooltip: 'Export PDF',
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 3,
                    onPressed:
                        state.isSubmitting
                            ? null
                            : () {
                              shareErpDocumentPdf(
                                context,
                                builder: buildSalesOrderShapedPdf(
                                  title: 'Sales Order',
                                  order: state.editingOrder!,
                                  remarksOverride: state.remarks,
                                  documentStatusOverride:
                                      state.editingDocumentStatus,
                                ),
                              );
                            },
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                    label: const Text(
                      'Export',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  : null;

          final Widget? fab =
              (mainFab == null && pdfFab == null)
                  ? null
                  : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (pdfFab != null) ...[
                        pdfFab,
                        const SizedBox(width: 12),
                      ],
                      if (mainFab != null) mainFab,
                    ],
                  );

          if (!widget.showScaffold) {
            return Stack(
              children: [
                Scaffold(body: content, floatingActionButton: fab),
                if (loadingOrder)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                else if (state.isSubmitting)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }

          return Stack(
            children: [
              Scaffold(
                backgroundColor: AppColors.surface,
                appBar: AppBar(
                  title: ErpDocHeaderAppBarTitle(
                    title: 'Sales Order',
                    docEntry: state.editingDocNum,
                  ),
                  actions: [
                    if (canCopyToDelivery)
                      TextButton.icon(
                        onPressed: () async {
                          final docEntry = state.editingDocNum;
                          if (docEntry == null) return;
                          final soCubit = context.read<SalesOrderCubit>();
                          final visitId = soCubit.state.visitId?.trim();
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => BlocProvider.value(
                                    value: soCubit,
                                    child: DeliveryFromSalesOrderPage(
                                      salesOrderDocEntry: docEntry,
                                      visitId:
                                          visitId != null && visitId.isNotEmpty
                                              ? visitId
                                              : null,
                                    ),
                                  ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.copy_all,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        label: const Text(
                          'Copy To',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (canCancelOrder)
                      TextButton.icon(
                        onPressed:
                            state.isSubmitting
                                ? null
                                : () async {
                                  final soCubit =
                                      context.read<SalesOrderCubit>();
                                  final docNumLabel =
                                      state.editingOrder?.docNum?.toString();
                                  final result =
                                      await showErpCancelDocumentDialog(
                                        context,
                                        documentLabel: 'Sales Order',
                                        docNumberLabel: docNumLabel,
                                        action: soCubit.cancelEditingSalesOrder,
                                      );
                                  if (result?.success == true &&
                                      context.mounted) {
                                    Navigator.of(context).maybePop();
                                  }
                                },
                        icon: const Icon(
                          Icons.cancel_outlined,
                          size: 18,
                          color: AppColors.error,
                        ),
                        label: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                  backgroundColor: Colors.white,
                  elevation: 0,
                ),
                body: content,
                floatingActionButton: fab,
              ),
              if (loadingOrder)
                Positioned.fill(
                  child: Container(
                    color: Colors.white,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              else if (state.isSubmitting)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickSalesOrderDueDate(BuildContext context) async {
    final cubit = context.read<SalesOrderCubit>();
    final s = cubit.state;
    final order = s.editingOrder;
    if (order == null) return;
    final initial =
        s.editingDocDueDate ??
        parseIsoDateTime(order.docDueDate) ??
        DateTime.now();
    final day = DateTime(initial.year, initial.month, initial.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && context.mounted) {
      cubit.setEditingDocDueDate(
        DateTime.utc(picked.year, picked.month, picked.day),
      );
    }
  }

  void _syncControllers(SalesOrderState state) {
    if (_remarksController.text != (state.remarks ?? '')) {
      _remarksController.text = state.remarks ?? '';
    }
  }

  Widget _buildCustomerField(BuildContext context, SalesOrderState state) {
    final l10n = AppLocalizations.of(context)!;
    final isCustomerLocked =
        state.editingDocNum != null || state.initialCardCode != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectCustomer,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap:
              isCustomerLocked || state.isLoadingCustomers
                  ? null
                  : () => _showCustomerDialog(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: BlocBuilder<SalesOrderCubit, SalesOrderState>(
              buildWhen:
                  (prev, curr) =>
                      prev.selectedCardCode != curr.selectedCardCode ||
                      prev.isLoadingCustomers != curr.isLoadingCustomers ||
                      prev.editingDocNum != curr.editingDocNum ||
                      prev.initialCardCode != curr.initialCardCode ||
                      prev.customers != curr.customers,
              builder: (context, state) {
                final label = _selectedCustomerLabel(state);
                final locked =
                    state.editingDocNum != null ||
                    state.initialCardCode != null;
                return Row(
                  children: [
                    Icon(
                      Icons.business,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              state.selectedCardCode != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (state.selectedCardCode != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatCustomerBalance(_selectedCustomerBalance(state)),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                    if (state.isLoadingCustomers)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else if (locked)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        if (state.customersError != null) ...[
          const SizedBox(height: 2),
          Text(
            state.customersError!,
            style: const TextStyle(fontSize: 10, color: AppColors.error),
          ),
        ],
      ],
    );
  }

  String _selectedCustomerLabel(SalesOrderState state) {
    if (state.selectedCardCode == null) {
      return AppLocalizations.of(context)!.selectCustomer;
    }
    final match =
        state.customers.where((e) => e.code == state.selectedCardCode).toList();
    if (match.isEmpty) {
      return state.initialCustomerName?.trim().isNotEmpty == true
          ? state.initialCustomerName!
          : state.selectedCardCode!;
    }
    final c = match.first;
    return c.name?.isNotEmpty == true ? c.name! : c.code;
  }

  double? _selectedCustomerBalance(SalesOrderState state) {
    final code = state.selectedCardCode;
    if (code == null) return null;
    final match = state.customers.where((e) => e.code == code).toList();
    if (match.isEmpty) return null;
    return match.first.balance;
  }

  String _formatCustomerBalance(double? balance) {
    if (balance == null) return '—';
    return NumberFormat.currency(symbol: '', decimalDigits: 2).format(balance);
  }

  void _showCustomerDialog(BuildContext context) {
    final sapCode =
        context
            .read<AuthCubit>()
            .state
            .loginResponse
            ?.user
            .sapSalesEmployeeCode;
    context.read<SalesOrderCubit>().loadCustomers(salesEmployeeCode: sapCode);
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<SalesOrderCubit>(),
            child: BlocBuilder<SalesOrderCubit, SalesOrderState>(
              builder: (context, state) {
                final l10n = AppLocalizations.of(context)!;
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 500,
                      maxHeight: 500,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.selectCustomer,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed:
                                    () => Navigator.of(dialogContext).pop(),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: l10n.searchCustomers,
                              hintStyle: const TextStyle(fontSize: 13),
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                              filled: true,
                              fillColor: AppColors.card,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                            ),
                            onChanged: (value) {
                              _customerPickerSearchDebounce?.cancel();
                              _customerPickerSearchDebounce = Timer(
                                const Duration(seconds: 1),
                                () {
                                  if (!mounted) return;
                                  final q = value.trim();
                                  context.read<SalesOrderCubit>().loadCustomers(
                                    salesEmployeeCode: sapCode,
                                    search: q.isEmpty ? null : q,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child:
                              state.isLoadingCustomers &&
                                      state.customers.isEmpty
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : state.customers.isEmpty
                                  ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Text(
                                        state.customersError ??
                                            'No customers found',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                  : NotificationListener<ScrollNotification>(
                                    onNotification: (n) {
                                      if (n.metrics.extentAfter > 160) {
                                        return false;
                                      }
                                      final cubit =
                                          context.read<SalesOrderCubit>();
                                      final st = cubit.state;
                                      if (!st.customersHasMore ||
                                          st.isLoadingMoreCustomers ||
                                          st.isLoadingCustomers) {
                                        return false;
                                      }
                                      cubit.loadCustomers(
                                        salesEmployeeCode: sapCode,
                                        search: null,
                                        append: true,
                                      );
                                      return false;
                                    },
                                    child: ListView.builder(
                                      itemCount:
                                          state.customers.length +
                                          (state.customersHasMore ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index >= state.customers.length) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            child: Center(
                                              child:
                                                  state.isLoadingMoreCustomers
                                                      ? const SizedBox(
                                                        width: 28,
                                                        height: 28,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                            ),
                                                      )
                                                      : const SizedBox.shrink(),
                                            ),
                                          );
                                        }
                                        final customer = state.customers[index];
                                        return _ErpCustomerTile(
                                          customer: customer,
                                          onTap: () {
                                            context
                                                .read<SalesOrderCubit>()
                                                .selectCustomer(customer.code);
                                            Navigator.of(dialogContext).pop();
                                          },
                                        );
                                      },
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
    ).whenComplete(() => _customerPickerSearchDebounce?.cancel());
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 12),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddItemBar(BuildContext context, SalesOrderState state) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Item',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _itemSearchController,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Code, barcode or name',
                    hintStyle: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                  onSubmitted: (_) => _onSearchItem(context, state),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 40,
                width: 40,
                child: IconButton(
                  tooltip: 'Search',
                  onPressed:
                      state.isLoadingLookup
                          ? null
                          : () => _onSearchItem(context, state),
                  icon:
                      state.isLoadingLookup
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                          : const Icon(Icons.search, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        state.isLoadingLookup
                            ? AppColors.surface
                            : AppColors.primary,
                    foregroundColor:
                        state.isLoadingLookup
                            ? AppColors.primary
                            : Colors.white,
                    side:
                        state.isLoadingLookup
                            ? const BorderSide(color: AppColors.border)
                            : null,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          if (state.lookupError != null) ...[
            const SizedBox(height: 4),
            Text(
              state.lookupError!,
              style: const TextStyle(fontSize: 10, color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onSearchItem(
    BuildContext context,
    SalesOrderState state,
  ) async {
    final q = _itemSearchController.text.trim();
    final cubit = context.read<SalesOrderCubit>();
    final raw = await cubit.loadItemLookupOdbc(q);
    if (!context.mounted || raw == null) return;
    final lineBundles = raw.expandedLinePickBundles();
    if (lineBundles.isEmpty) return;

    final rawRowCount = raw.rawMatchCountForPagination();
    final chosen = await showItemLookupRowPickDialog(
      context,
      query: q,
      initialRows: lineBundles,
      initialRawRowCount: rawRowCount,
      initialHasMore: rawRowCount >= kOdbcItemLookupTake,
      fetchPage:
          (query, skip) =>
              cubit.loadItemLookupOdbc(query, skip: skip, silent: true),
    );
    if (!context.mounted || chosen == null) return;
    final result = cubit.itemLookupResultFromRow(chosen);
    cubit.addLine(result.toLine());
    _itemSearchController.clear();
  }

  Widget _buildLinesTable(BuildContext context, SalesOrderState state) {
    if (state.lines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'No items. Use "Add Item" above to search and add.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    const tableTextStyle = TextStyle(fontSize: 11);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Table(
          border: TableBorder.all(color: AppColors.border),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: {
            for (var i = 0; i < 9; i++) i: const IntrinsicColumnWidth(),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                const _HeaderCell('', style: tableTextStyle),
                const _HeaderCell('Barcode', style: tableTextStyle),
                const _HeaderCell('Item Code', style: tableTextStyle),
                const _HeaderCell('Item Name', style: tableTextStyle),
                _HeaderCell(
                  AppLocalizations.of(context)!.inventoryColOnHand,
                  style: tableTextStyle,
                ),
                const _HeaderCell('Qty', style: tableTextStyle),
                const _HeaderCell('Unit Price', style: tableTextStyle),
                const _HeaderCell('UoM', style: tableTextStyle),
                const _HeaderCell('VAT Group', style: tableTextStyle),
              ],
            ),
            ...List.generate(state.lines.length, (i) {
              final line = state.lines[i];
              return TableRow(
                children: [
                  _BodyCell(
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap:
                          () => context.read<SalesOrderCubit>().removeLineAt(i),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.remove_circle_outline,
                          size: 18,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                  _BodyCell(Text(line.barcode ?? '—', style: tableTextStyle)),
                  _BodyCell(Text(line.itemCode ?? '—', style: tableTextStyle)),
                  _BodyCell(
                    Text(
                      line.itemName ?? '—',
                      style: tableTextStyle,
                      softWrap: true,
                    ),
                  ),
                  _BodyCell(
                    Text(
                      line.onHand != null ? line.onHand.toString() : '—',
                      style: tableTextStyle,
                    ),
                  ),
                  _BodyCell(
                    TextFormField(
                      initialValue: line.quantity.toString(),
                      style: tableTextStyle,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        final q = num.tryParse(v);
                        if (q != null && q > 0) {
                          context.read<SalesOrderCubit>().updateLineQuantity(
                            i,
                            q,
                          );
                        }
                      },
                    ),
                  ),
                  _BodyCell(
                    Text(() {
                      final cur = line.currency?.trim() ?? '';
                      return cur.isEmpty
                          ? line.unitPrice.toString()
                          : '${line.unitPrice} $cur';
                    }(), style: tableTextStyle),
                  ),
                  _BodyCell(
                    (line.uoMs != null && line.uoMs!.isNotEmpty)
                        ? DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value:
                                line.unitOfMeasure?.isNotEmpty == true &&
                                        line.uoMs!.any(
                                          (u) =>
                                              u.uoMCode == line.unitOfMeasure,
                                        )
                                    ? line.unitOfMeasure
                                    : line.uoMs!.first.uoMCode,
                            isExpanded: true,
                            isDense: true,
                            style: tableTextStyle.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            selectedItemBuilder:
                                (context) =>
                                    line.uoMs!
                                        .map<Widget>(
                                          (u) => Text(
                                            u.uoMCode,
                                            style: tableTextStyle.copyWith(
                                              color: AppColors.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )
                                        .toList(),
                            items:
                                line.uoMs!
                                    .map(
                                      (u) => DropdownMenuItem<String>(
                                        value: u.uoMCode,
                                        child: Text(
                                          u.uoMCode,
                                          style: tableTextStyle.copyWith(
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              context
                                  .read<SalesOrderCubit>()
                                  .updateLineUnitOfMeasure(i, value);
                            },
                          ),
                        )
                        : Text(
                          line.unitOfMeasure ?? '—',
                          style: tableTextStyle.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                  ),
                  _BodyCell(
                    _VatGroupDropdown(
                      line: line,
                      lineIndex: i,
                      vatCodes: state.vatCodes,
                      tableTextStyle: tableTextStyle,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        text,
        style: style.copyWith(fontWeight: FontWeight.w600),
        softWrap: true,
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: child,
    );
  }
}

/// Same tile design as _CustomerTile in standalone_visit_sheet (name + code).
class _ErpCustomerTile extends StatelessWidget {
  const _ErpCustomerTile({required this.customer, required this.onTap});

  final ErpCustomerModel customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            Icon(Icons.business, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name?.isNotEmpty == true
                        ? customer.name!
                        : customer.code,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (odbcCardTypeKindLabel(customer.cardType).isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      odbcCardTypeKindLabel(customer.cardType),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                  if (customer.foreignName?.trim().isNotEmpty == true &&
                      customer.foreignName!.trim() !=
                          (customer.name?.trim() ?? '')) ...[
                    const SizedBox(height: 2),
                    Text(
                      customer.foreignName!.trim(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (customer.code.isNotEmpty)
                    Text(
                      customer.code,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Balance: ${customer.balance != null ? NumberFormat.currency(symbol: '', decimalDigits: 2).format(customer.balance) : '—'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// VAT group dropdown that only uses values present in [vatCodes] and deduplicates by code
/// to avoid "exactly one item" assertion when line.vatGroup is C14 but list has 0 or 2+ C14.
class _VatGroupDropdown extends StatelessWidget {
  const _VatGroupDropdown({
    required this.line,
    required this.lineIndex,
    required this.vatCodes,
    required this.tableTextStyle,
  });

  final SalesOrderLineModel line;
  final int lineIndex;
  final List<VatCodeModel> vatCodes;
  final TextStyle tableTextStyle;

  @override
  Widget build(BuildContext context) {
    // Deduplicate by code (keep first occurrence) so dropdown has unique values.
    final seen = <String>{};
    final distinct = vatCodes.where((v) => seen.add(v.code)).toList();
    final codes = distinct.map((v) => v.code).toSet();
    // Only use line.vatGroup as value if it exists in the dropdown items.
    final value =
        line.vatGroup != null &&
                line.vatGroup!.isNotEmpty &&
                codes.contains(line.vatGroup)
            ? line.vatGroup
            : null;

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        isDense: true,
        hint: Text('—', style: tableTextStyle),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text('—', style: tableTextStyle),
          ),
          ...distinct.map(
            (v) => DropdownMenuItem<String>(
              value: v.code,
              child: Text(
                v.name ?? v.code,
                style: tableTextStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: (v) {
          context.read<SalesOrderCubit>().updateLineVatGroup(lineIndex, v);
        },
      ),
    );
  }
}
