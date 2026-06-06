import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/constants/customer_odbc_scope.dart';
import 'package:sales_medical_app_mobile/core/utils/odbc_card_type_label.dart';
import 'package:sales_medical_app_mobile/core/di/service_locator.dart';
import 'package:sales_medical_app_mobile/core/network/api_error_message.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/entities/customer.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/usecases/get_customers_usecase.dart';
import 'package:sales_medical_app_mobile/core/network/api_service.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/helpers/register_visit_action_after_erp.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/erp_document_header_widgets.dart';
import 'package:sales_medical_app_mobile/core/pdf/erp_document_pdf.dart';
import 'package:sales_medical_app_mobile/core/pdf/erp_document_pdf_share.dart';

class IncomingPaymentFilters {
  const IncomingPaymentFilters({
    this.customerCode = '',
    this.dateFrom,
    this.dateTo,
  });

  final String customerCode;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  bool get hasActive =>
      customerCode.trim().isNotEmpty || dateFrom != null || dateTo != null;
}

class IncomingPaymentFilterBridge {
  static final ValueNotifier<IncomingPaymentFilters> notifier = ValueNotifier(
    const IncomingPaymentFilters(),
  );

  static void apply({
    required String customerCode,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    notifier.value = IncomingPaymentFilters(
      customerCode: customerCode,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }
}

class IncomingPaymentPage extends StatefulWidget {
  const IncomingPaymentPage({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  State<IncomingPaymentPage> createState() => _IncomingPaymentPageState();
}

class _IncomingPaymentPageState extends State<IncomingPaymentPage> {
  final ApiService _apiService = sl<ApiService>();
  final TextEditingController _customerSearchController =
      TextEditingController();
  final TextEditingController _docEntrySearchController =
      TextEditingController();

  bool _showSearchBar = false;
  bool _isLoading = false;
  bool _isSearchingDoc = false;
  String? _error;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  List<_IncomingPaymentDocument> _documents = const [];

  @override
  void initState() {
    super.initState();
    IncomingPaymentFilterBridge.notifier.addListener(_onExternalFiltersChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDocuments());
  }

  @override
  void dispose() {
    IncomingPaymentFilterBridge.notifier.removeListener(
      _onExternalFiltersChanged,
    );
    _customerSearchController.dispose();
    _docEntrySearchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters {
    return _customerSearchController.text.trim().isNotEmpty ||
        _dateFrom != null ||
        _dateTo != null;
  }

  Future<void> _onExternalFiltersChanged() async {
    final f = IncomingPaymentFilterBridge.notifier.value;
    if (!mounted) return;
    setState(() {
      _customerSearchController.text = f.customerCode;
      _dateFrom = f.dateFrom;
      _dateTo = f.dateTo;
    });
    await _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final salesEmployeeCode =
        context
            .read<AuthCubit>()
            .state
            .loginResponse
            ?.user
            .sapSalesEmployeeCode;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final query = <String, dynamic>{'skip': 0, 'take': 10};
      final customerCode = _customerSearchController.text.trim();
      if (customerCode.isNotEmpty) query['customerCode'] = customerCode;
      if (_dateFrom != null) {
        query['dateFrom'] =
            DateTime(
              _dateFrom!.year,
              _dateFrom!.month,
              _dateFrom!.day,
            ).toUtc().toIso8601String();
      }
      if (_dateTo != null) {
        query['dateTo'] =
            DateTime(
              _dateTo!.year,
              _dateTo!.month,
              _dateTo!.day,
              23,
              59,
              59,
              999,
            ).toUtc().toIso8601String();
      }
      if (salesEmployeeCode != null) {
        query['salesEmployeeCode'] = salesEmployeeCode;
      }

      final response = await _apiService.get(
        '/api/erp/incoming-payments',
        queryParameters: query,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to load incoming payments');
      }
      final raw = response.data;
      final list = raw is List ? raw : <dynamic>[];
      if (!mounted) return;
      setState(() {
        _documents =
            list
                .whereType<Map<String, dynamic>>()
                .map(_IncomingPaymentDocument.fromJson)
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = userVisibleApiErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _searchByDocEntry() async {
    final docEntry = int.tryParse(_docEntrySearchController.text.trim());
    if (docEntry == null) {
      _showMessage('Enter a valid Doc Entry');
      return;
    }
    setState(() => _isSearchingDoc = true);
    try {
      final response = await _apiService.get(
        '/api/erp/incoming-payments/$docEntry',
      );
      if (response.statusCode != 200 ||
          response.data is! Map<String, dynamic>) {
        throw Exception('Document not found');
      }
      final doc = _IncomingPaymentDocument.fromJson(
        response.data as Map<String, dynamic>,
      );
      if (!mounted) return;
      setState(() => _isSearchingDoc = false);
      await _openDetails(doc);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearchingDoc = false);
      final msg = userVisibleApiErrorMessage(e);
      if (msg != null) _showMessage(msg);
    }
  }

  Future<void> _openDetails(_IncomingPaymentDocument doc) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => IncomingPaymentDetailsPage(initialDocument: doc),
      ),
    );
  }

  void _openFiltersSheet() {
    final customerCtrl = TextEditingController(
      text: _customerSearchController.text,
    );
    DateTime? tempFrom = _dateFrom;
    DateTime? tempTo = _dateTo;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> pickFrom() async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: tempFrom ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked == null) return;
              setModalState(() => tempFrom = picked);
            }

            Future<void> pickTo() async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: tempTo ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked == null) return;
              setModalState(() => tempTo = picked);
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: customerCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Customer code',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: pickFrom,
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            tempFrom == null
                                ? 'Date from'
                                : DateFormat('yyyy-MM-dd').format(tempFrom!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: pickTo,
                          icon: const Icon(Icons.event),
                          label: Text(
                            tempTo == null
                                ? 'Date to'
                                : DateFormat('yyyy-MM-dd').format(tempTo!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            customerCtrl.clear();
                            setModalState(() {
                              tempFrom = null;
                              tempTo = null;
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            setState(() {
                              _customerSearchController.text =
                                  customerCtrl.text.trim();
                              _dateFrom = tempFrom;
                              _dateTo = tempTo;
                            });
                            Navigator.of(ctx).pop();
                            await _loadDocuments();
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openCreateForm() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const IncomingPaymentCreatePage(),
      ),
    );
    if (!mounted) return;
    await _loadDocuments();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildListContent() {
    if (_isLoading && _documents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _documents.isEmpty) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: AppColors.error)),
      );
    }
    if (_documents.isEmpty) {
      return const Center(
        child: Text(
          'No incoming payments found',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        itemCount: _documents.length,
        itemBuilder: (context, index) {
          final doc = _documents[index];
          final docBadge = erpListCardPrimaryDocLabel(
            doc.docNum == 0 ? null : doc.docNum,
            doc.docEntry,
          );
          final subtitleLead =
              doc.docNum != 0
                  ? 'Entry ${doc.docEntry} • ${doc.docDateLabel}'
                  : doc.docDateLabel;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(
                '${docBadge ?? '#${doc.docEntry}'}  ${doc.cardCode} - ${doc.cardName}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '$subtitleLead\nCash ${doc.cashSum.toStringAsFixed(2)}',
              ),
              isThreeLine: true,
              onTap: () => _openDetails(doc),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_showSearchBar) ...[
                Expanded(
                  child: TextField(
                    controller: _docEntrySearchController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Doc Entry',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _searchByDocEntry(),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Search',
                  onPressed: _isSearchingDoc ? null : _searchByDocEntry,
                  icon:
                      _isSearchingDoc
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.arrow_forward),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _showSearchBar = false),
                ),
              ] else ...[
                const Spacer(),
                IconButton(
                  tooltip: 'Search by Doc Entry',
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() => _showSearchBar = true),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Stack(
      children: [
        Column(
          children: [_buildSearchRow(), Expanded(child: _buildListContent())],
        ),
        if (_isLoading && _documents.isNotEmpty)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x22000000),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ),
      ],
    );

    final scaffold = Scaffold(
      appBar:
          widget.showScaffold
              ? AppBar(
                title: const Text('Incoming payment'),
                actions: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.filter_list,
                          color:
                              _hasActiveFilters
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                        ),
                        onPressed: _openFiltersSheet,
                        tooltip: 'Filters',
                      ),
                      if (_hasActiveFilters)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              )
              : null,
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateForm,
        icon: const Icon(Icons.add),
        label: const Text('Create'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
    return scaffold;
  }
}

class IncomingPaymentDetailsPage extends StatefulWidget {
  const IncomingPaymentDetailsPage({super.key, required this.initialDocument});

  /// Opens details; full data is loaded from ERP using [docEntry] (e.g. visit action).
  IncomingPaymentDetailsPage.fromDocEntry({super.key, required int docEntry})
    : initialDocument = _IncomingPaymentDocument.placeholderForDocEntry(
        docEntry,
      );

  final _IncomingPaymentDocument initialDocument;

  @override
  State<IncomingPaymentDetailsPage> createState() =>
      _IncomingPaymentDetailsPageState();
}

class _IncomingPaymentDetailsPageState
    extends State<IncomingPaymentDetailsPage> {
  final ApiService _apiService = sl<ApiService>();
  bool _isLoading = false;
  String? _error;
  late _IncomingPaymentDocument _doc;

  @override
  void initState() {
    super.initState();
    _doc = widget.initialDocument;
    _loadByDocEntry();
  }

  Future<void> _loadByDocEntry() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _apiService.get(
        '/api/erp/incoming-payments/${_doc.docEntry}',
      );
      if (response.statusCode != 200 ||
          response.data is! Map<String, dynamic>) {
        throw Exception('Failed to load incoming payment details');
      }
      if (!mounted) return;
      setState(() {
        _doc = _IncomingPaymentDocument.fromJson(
          response.data as Map<String, dynamic>,
        );
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = userVisibleApiErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ErpDocHeaderShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ErpDocNumTotalStatusRow(
                  docNum: _doc.docNum.toString(),
                  totalStr: _doc.cashSum.toStringAsFixed(2),
                  statusLabel: _doc.docType.isEmpty ? 'Payment' : _doc.docType,
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    children: [
                      ErpDocFieldRow(
                        label: 'Customer',
                        value: _doc.cardName.isEmpty ? '—' : _doc.cardName,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),
                      ErpDocFieldRow(
                        label: 'Card code',
                        value: _doc.cardCode.isEmpty ? '—' : _doc.cardCode,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ErpDocFieldRow(
                              label: 'Doc date',
                              value: _doc.docDateLabel,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ErpDocFieldRow(
                              label: 'Cash sum',
                              value: _doc.cashSum.toStringAsFixed(2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ErpDocFieldRow(
                        label: 'Cash account',
                        value:
                            _doc.cashAccount.trim().isEmpty
                                ? '—'
                                : _doc.cashAccount,
                      ),
                      const SizedBox(height: 10),
                      ErpDocFieldRow(
                        label: 'Control account',
                        value:
                            _doc.controlAccount.trim().isEmpty
                                ? '—'
                                : _doc.controlAccount,
                      ),
                      const SizedBox(height: 10),
                      ErpDocFieldRow(
                        label: 'Remarks',
                        value:
                            _doc.journalRemarks.trim().isEmpty
                                ? '—'
                                : _doc.journalRemarks,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Payment Invoices',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Table(
              border: TableBorder.all(color: AppColors.border),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
                  children: [
                    _TableCell(
                      'Line Num',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _TableCell(
                      'Doc Entry',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _TableCell(
                      'Sum Applied',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                ..._doc.paymentInvoices.map(
                  (line) => TableRow(
                    children: [
                      _TableCell(
                        '${line.lineNum}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      _TableCell(
                        '${line.docEntry}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      _TableCell(
                        line.sumApplied.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: ErpDocHeaderAppBarTitle(
          title: 'Incoming Payment',
          docEntry: _doc.docEntry,
        ),
      ),
      floatingActionButton:
          _isLoading
              ? null
              : FloatingActionButton.extended(
                heroTag: 'incoming-payment-pdf-fab',
                tooltip: 'Export PDF',
                onPressed: () {
                  shareErpDocumentPdf(
                    context,
                    builder: _buildIncomingPaymentPdfBuilder(_doc),
                  );
                },
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                elevation: 3,
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                label: const Text(
                  'Export',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
              ),
            )
          else
            content,
          if (_isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x22000000),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class IncomingPaymentCreatePage extends StatefulWidget {
  const IncomingPaymentCreatePage({
    super.key,
    this.visitId,
    this.initialCardCode,
    this.initialCustomerName,
  });

  /// When opened from a visit, sent on POST as `visitId`.
  final String? visitId;

  /// Pre-select customer and load open invoices (e.g. from visit card).
  final String? initialCardCode;
  final String? initialCustomerName;

  @override
  State<IncomingPaymentCreatePage> createState() =>
      _IncomingPaymentCreatePageState();
}

class _IncomingPaymentCreatePageState extends State<IncomingPaymentCreatePage> {
  final ApiService _apiService = sl<ApiService>();

  _IncomingCustomer? _selectedCustomer;
  List<_IncomingInvoice> _invoices = const [];
  bool _isLoadingInvoices = false;
  bool _isSaving = false;
  String? _error;
  double _cashSum = 0;
  String _paymentMethod = 'Cash';

  @override
  void initState() {
    super.initState();
    final code = widget.initialCardCode?.trim();
    if (code != null && code.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final name = widget.initialCustomerName?.trim();
        setState(() {
          _selectedCustomer = _IncomingCustomer(
            code: code,
            name: (name != null && name.isNotEmpty) ? name : code,
            foreignName: '',
            balance: 0,
          );
        });
        await _loadOpenInvoices(code);
      });
    }
  }

  @override
  void dispose() {
    for (final invoice in _invoices) {
      invoice.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _openCustomerDialog() async {
    final selected = await showDialog<_IncomingCustomer?>(
      context: context,
      builder: (_) => const _IncomingCustomerDialog(),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedCustomer = selected;
    });
    await _loadOpenInvoices(selected.code);
  }

  Future<void> _loadOpenInvoices(String cardCode) async {
    setState(() {
      _isLoadingInvoices = true;
      _error = null;
      _cashSum = 0;
    });
    try {
      final response = await _apiService.get(
        '/api/erp/incoming-payments/open-invoices/$cardCode',
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to load open invoices');
      }
      final raw = response.data;
      final list = raw is List ? raw : <dynamic>[];
      final invoices =
          list
              .whereType<Map<String, dynamic>>()
              .map(_IncomingInvoice.fromJson)
              .toList();
      for (final old in _invoices) {
        old.controller.dispose();
      }
      if (!mounted) return;
      setState(() {
        _invoices = invoices;
        _isLoadingInvoices = false;
      });
      await _promptAndAutoDistribute();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingInvoices = false;
        _error = userVisibleApiErrorMessage(e);
      });
    }
  }

  Future<void> _promptAndAutoDistribute() async {
    String amountInput = _cashSum > 0 ? _cashSum.toStringAsFixed(2) : '';
    final entered = await showDialog<double?>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Payment amount'),
            content: TextFormField(
              initialValue: amountInput,
              onChanged: (v) => amountInput = v,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Customer will pay',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final value = double.tryParse(amountInput.trim());
                  Navigator.of(ctx).pop(value);
                },
                child: const Text('Apply'),
              ),
            ],
          ),
    );
    if (!mounted || entered == null || entered < 0) return;

    if (_invoices.isNotEmpty) {
      var remaining = entered;
      for (final invoice in _invoices) {
        final apply =
            remaining <= 0
                ? 0.0
                : (remaining >= invoice.balanceDue
                    ? invoice.balanceDue
                    : remaining);
        invoice.setApplied(apply);
        remaining -= apply;
      }
    }
    setState(() {
      _cashSum = entered;
    });
  }

  double get _totalApplied {
    return _invoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.appliedValue,
    );
  }

  Future<void> _saveIncomingPayment() async {
    final customer = _selectedCustomer;
    if (customer == null) {
      _showMessage('Please select a customer');
      return;
    }
    if (_cashSum <= 0) {
      _showMessage('Please enter payment amount');
      return;
    }
    final totalApplied = _totalApplied;
    if (_invoices.isNotEmpty && totalApplied <= 0) {
      _showMessage('Please apply amount to at least one invoice');
      return;
    }
    if (totalApplied - _cashSum > 0.0001) {
      _showMessage('Applied amount cannot be greater than cash sum');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final payload = <String, dynamic>{
        'docDate': DateTime.now().toUtc().toIso8601String(),
        'cardCode': customer.code,
        'cashSum': _cashSum,
        'paymentInvoices':
            _invoices
                .where((invoice) => invoice.appliedValue > 0)
                .map(
                  (invoice) => <String, dynamic>{
                    'docEntry': invoice.docEntry,
                    'sumApplied': invoice.appliedValue,
                  },
                )
                .toList(),
      };
      final visitId = widget.visitId?.trim();
      if (visitId != null && visitId.isNotEmpty) {
        payload['visitId'] = visitId;
      }
      final response = await _apiService.post(
        '/api/erp/incoming-payments',
        data: payload,
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save incoming payment');
      }
      final data = response.data;
      final mapData = data is Map<String, dynamic> ? data : null;
      final success = mapData?['success'] == true || mapData == null;
      if (!success) {
        final msg =
            (mapData['errorMessage']?.toString().trim().isNotEmpty == true
                ? mapData['errorMessage'].toString()
                : 'Failed to save incoming payment');
        throw Exception(msg);
      }
      if (!mounted) return;
      final docNum =
          mapData != null ? mapData['documentNumber']?.toString().trim() : null;
      final docEntry =
          mapData != null ? mapData['documentId']?.toString().trim() : null;
      final lines = <String>['Incoming payment created successfully.'];
      if (docEntry != null && docEntry.isNotEmpty) {
        lines.add('Doc Entry: $docEntry');
      }
      if (docNum != null && docNum.isNotEmpty) {
        lines.add('Document number: $docNum');
      }
      final vid = widget.visitId?.trim();
      if (vid != null && vid.isNotEmpty) {
        await registerVisitActionIfInJourneyContext(context, visitId: vid);
      }
      if (!mounted) return;
      await _showSaveResponseDialog(
        title: 'Incoming payment',
        message: lines.join('\n'),
        closePageOnOk: true,
      );
    } catch (e) {
      if (!mounted) return;
      final resolved = userVisibleApiErrorMessage(e);
      // A 401 is handled globally (silent logout); don't show any message.
      if (resolved == null) {
        setState(() => _isSaving = false);
        return;
      }
      setState(() {
        _isSaving = false;
        _error = resolved;
      });
      await _showSaveResponseDialog(
        title: 'Incoming payment',
        message: resolved,
      );
    }
  }

  Future<void> _showSaveResponseDialog({
    required String title,
    required String message,
    bool closePageOnOk = false,
  }) async {
    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (closePageOnOk && mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create incoming payment')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment method',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'Bank', child: Text('Bank')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _paymentMethod = value);
                  },
                ),
                const SizedBox(height: 10),
                _buildCustomerField(),
                const SizedBox(height: 10),
                if (_selectedCustomer != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Customer Balance: ${_selectedCustomer!.balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_selectedCustomer != null)
                  Text(
                    'Cash sum: ${_cashSum.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                const SizedBox(height: 10),
                Expanded(child: _buildInvoicesTable()),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveIncomingPayment,
                  icon: const Icon(Icons.save),
                  label: const Text('Save incoming payment'),
                ),
              ],
            ),
          ),
          if (_isSaving || _isLoadingInvoices)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerField() {
    final customer = _selectedCustomer;
    final subtitle =
        customer == null
            ? 'Tap to select customer'
            : () {
              final f = customer.foreignName.trim();
              final n = customer.name.trim();
              final foreignSuffix = f.isNotEmpty && f != n ? ' · $f' : '';
              return '${customer.code} - $n$foreignSuffix (Balance: ${customer.balance.toStringAsFixed(2)})';
            }();
    return InkWell(
      onTap: _openCustomerDialog,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.business, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                subtitle,
                style: TextStyle(
                  color:
                      customer == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesTable() {
    if (_error != null && _invoices.isEmpty) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: AppColors.error)),
      );
    }
    if (_invoices.isEmpty) {
      final hasCustomer = _selectedCustomer != null;
      return Center(
        child: Text(
          hasCustomer
              ? 'No open invoices for this customer'
              : 'Select customer to load open invoices',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    const headerStyle = TextStyle(fontWeight: FontWeight.w600, fontSize: 11);
    const bodyStyle = TextStyle(fontSize: 11);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: AppColors.border),
        columnWidths: {
          for (var i = 0; i < 7; i++) i: const IntrinsicColumnWidth(),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
            children: [
              _TableCell('Doc No', style: headerStyle),
              _TableCell('Type', style: headerStyle),
              _TableCell('Date', style: headerStyle),
              _TableCell('Total', style: headerStyle),
              _TableCell('Paid', style: headerStyle),
              _TableCell('Balance', style: headerStyle),
              _TableCell('Applied', style: headerStyle),
            ],
          ),
          ...List.generate(_invoices.length, (index) {
            final invoice = _invoices[index];
            return TableRow(
              children: [
                _TableCell('${invoice.documentNo}', style: bodyStyle),
                _TableCell(invoice.documentType, style: bodyStyle),
                _TableCell(
                  DateFormat('yyyy-MM-dd').format(invoice.date),
                  style: bodyStyle,
                ),
                _TableCell(invoice.total.toStringAsFixed(2), style: bodyStyle),
                _TableCell(invoice.paid.toStringAsFixed(2), style: bodyStyle),
                _TableCell(
                  invoice.balanceDue.toStringAsFixed(2),
                  style: bodyStyle,
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: TextField(
                    controller: invoice.controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: bodyStyle,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      final parsed = double.tryParse(value) ?? 0;
                      if (parsed < 0) {
                        invoice.controller.text = '0';
                        invoice
                            .controller
                            .selection = TextSelection.fromPosition(
                          TextPosition(offset: invoice.controller.text.length),
                        );
                      }
                      setState(() {});
                    },
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _IncomingCustomerDialog extends StatefulWidget {
  const _IncomingCustomerDialog();

  @override
  State<_IncomingCustomerDialog> createState() =>
      _IncomingCustomerDialogState();
}

class _IncomingCustomerDialogState extends State<_IncomingCustomerDialog> {
  static const int _odbcPageSize = 20;

  final GetCustomersUseCase _getCustomersUseCase = sl<GetCustomersUseCase>();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  String? _lastSearch;
  List<_IncomingCustomer> _customers = const [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadCustomers();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      _loadCustomers();
    });
  }

  String? _normalizedSearch() {
    final t = _searchController.text.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _loadCustomers({bool append = false}) async {
    if (append) {
      if (!_hasMore || _isLoadingMore || _isLoading) return;
    } else {
      _lastSearch = _normalizedSearch();
    }

    setState(() {
      if (append) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _error = null;
        _hasMore = true;
      }
    });

    final pageNumber = append ? (_customers.length ~/ _odbcPageSize) + 1 : 1;
    final searchForApi = append ? _lastSearch : _normalizedSearch();

    final salesEmployeeCode = context
        .read<AuthCubit>()
        .state
        .loginResponse
        ?.user
        .sapSalesEmployeeCode;

    try {
      // Match Swagger: search + activeOnly + skip/take + scope=2 + salesEmpCode
      // for the logged-in user.
      final list = await _getCustomersUseCase(
        search: searchForApi,
        pageNumber: pageNumber,
        pageSize: _odbcPageSize,
        activeOnly: true,
        scope: CustomerOdbcScope.all,
        salesEmployeeCode: salesEmployeeCode,
      );
      if (!mounted) return;
      final mapped = list
          .map(_IncomingCustomer.fromCustomer)
          .toList(growable: false);
      setState(() {
        if (append) {
          _customers = [..._customers, ...mapped];
        } else {
          _customers = mapped;
        }
        _hasMore = mapped.length == _odbcPageSize;
        _isLoading = false;
        _isLoadingMore = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        if (!append) {
          _customers = const [];
          _error = userVisibleApiErrorMessage(e);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520, maxWidth: 560),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select customer',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) {
                  _debounce?.cancel();
                  _loadCustomers();
                },
                decoration: InputDecoration(
                  hintText: 'Search by code or name',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, value, _) {
                      if (value.text.trim().isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _debounce?.cancel();
                          _loadCustomers();
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            if (_isLoading && _customers.isNotEmpty)
              const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 8),
            Expanded(
              child:
                  _isLoading && _customers.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _customers.isEmpty
                      ? Center(
                        child: Text(
                          _error ?? 'No customers found',
                          style: TextStyle(
                            color:
                                _error == null
                                    ? AppColors.textSecondary
                                    : AppColors.error,
                          ),
                        ),
                      )
                      : NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (n.metrics.extentAfter > 160) return false;
                          _loadCustomers(append: true);
                          return false;
                        },
                        child: ListView.separated(
                          itemCount: _customers.length + (_hasMore ? 1 : 0),
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            if (index >= _customers.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Center(
                                  child:
                                      _isLoadingMore
                                          ? const SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const SizedBox.shrink(),
                                ),
                              );
                            }
                            final customer = _customers[index];
                            return ListTile(
                              leading: const Icon(Icons.business),
                              title: Text(
                                '${customer.code} - ${customer.name}',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (odbcCardTypeKindLabel(
                                    customer.cardType,
                                  ).isNotEmpty)
                                    Text(
                                      odbcCardTypeKindLabel(customer.cardType),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary.withValues(
                                          alpha: 0.95,
                                        ),
                                      ),
                                    ),
                                  if (customer.foreignName.trim().isNotEmpty &&
                                      customer.foreignName.trim() !=
                                          customer.name.trim())
                                    Text(
                                      customer.foreignName.trim(),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  Text(
                                    'Balance: ${customer.balance.toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                              isThreeLine:
                                  odbcCardTypeKindLabel(
                                    customer.cardType,
                                  ).isNotEmpty ||
                                  (customer.foreignName.trim().isNotEmpty &&
                                      customer.foreignName.trim() !=
                                          customer.name.trim()),
                              onTap:
                                  () => Navigator.of(
                                    context,
                                  ).pop<_IncomingCustomer>(customer),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomingPaymentDocument {
  const _IncomingPaymentDocument({
    required this.docNum,
    required this.docType,
    required this.docDate,
    required this.cardCode,
    required this.cardName,
    required this.cashAccount,
    required this.cashSum,
    required this.journalRemarks,
    required this.docEntry,
    required this.controlAccount,
    required this.paymentInvoices,
  });

  final int docNum;
  final String docType;
  final String docDate;
  final String cardCode;
  final String cardName;
  final String cashAccount;
  final double cashSum;
  final String journalRemarks;
  final int docEntry;
  final String controlAccount;
  final List<_IncomingPaymentInvoiceLine> paymentInvoices;

  String get docDateLabel {
    final parsed = DateTime.tryParse(docDate);
    if (parsed == null) return docDate;
    return DateFormat('yyyy-MM-dd').format(parsed);
  }

  /// Minimal row until GET `/incoming-payments/{docEntry}` completes.
  factory _IncomingPaymentDocument.placeholderForDocEntry(int docEntry) {
    return _IncomingPaymentDocument(
      docNum: 0,
      docType: '',
      docDate: '',
      cardCode: '',
      cardName: '',
      cashAccount: '',
      cashSum: 0,
      journalRemarks: '',
      docEntry: docEntry,
      controlAccount: '',
      paymentInvoices: const [],
    );
  }

  factory _IncomingPaymentDocument.fromJson(Map<String, dynamic> json) {
    final linesRaw = json['paymentInvoices'];
    final lineList = linesRaw is List ? linesRaw : <dynamic>[];
    return _IncomingPaymentDocument(
      docNum: (json['docNum'] as num?)?.toInt() ?? 0,
      docType: (json['docType'] ?? '').toString(),
      docDate: (json['docDate'] ?? '').toString(),
      cardCode: (json['cardCode'] ?? '').toString(),
      cardName: (json['cardName'] ?? '').toString(),
      cashAccount: (json['cashAccount'] ?? '').toString(),
      cashSum: (json['cashSum'] as num?)?.toDouble() ?? 0,
      journalRemarks: (json['journalRemarks'] ?? '').toString(),
      docEntry: (json['docEntry'] as num?)?.toInt() ?? 0,
      controlAccount: (json['controlAccount'] ?? '').toString(),
      paymentInvoices:
          lineList
              .whereType<Map<String, dynamic>>()
              .map(_IncomingPaymentInvoiceLine.fromJson)
              .toList(),
    );
  }
}

class _IncomingPaymentInvoiceLine {
  const _IncomingPaymentInvoiceLine({
    required this.lineNum,
    required this.docEntry,
    required this.sumApplied,
  });

  final int lineNum;
  final int docEntry;
  final double sumApplied;

  factory _IncomingPaymentInvoiceLine.fromJson(Map<String, dynamic> json) {
    return _IncomingPaymentInvoiceLine(
      lineNum: (json['lineNum'] as num?)?.toInt() ?? 0,
      docEntry: (json['docEntry'] as num?)?.toInt() ?? 0,
      sumApplied: (json['sumApplied'] as num?)?.toDouble() ?? 0,
    );
  }
}

class _IncomingCustomer {
  const _IncomingCustomer({
    required this.code,
    required this.name,
    this.foreignName = '',
    required this.balance,
    this.cardType = '',
  });

  final String code;
  final String name;
  final String foreignName;
  final double balance;
  final String cardType;

  factory _IncomingCustomer.fromCustomer(Customer customer) {
    final code =
        customer.customerCode.trim().isNotEmpty
            ? customer.customerCode.trim()
            : customer.id.trim();
    return _IncomingCustomer(
      code: code,
      name: customer.name,
      foreignName: customer.foreignName,
      balance: customer.balance,
      cardType: customer.cardType,
    );
  }
}

class _IncomingInvoice {
  _IncomingInvoice({
    required this.docEntry,
    required this.documentNo,
    required this.documentType,
    required this.date,
    required this.total,
    required this.paid,
    required this.balanceDue,
    required this.controller,
  });

  final int docEntry;
  final int documentNo;
  final String documentType;
  final DateTime date;
  final double total;
  final double paid;
  final double balanceDue;
  final TextEditingController controller;

  double get appliedValue => double.tryParse(controller.text.trim()) ?? 0;

  void setApplied(double value) {
    controller.text = value.toStringAsFixed(2);
  }

  factory _IncomingInvoice.fromJson(Map<String, dynamic> json) {
    final balance = (json['balanceDue'] as num?)?.toDouble() ?? 0;
    return _IncomingInvoice(
      docEntry: (json['docEntry'] as num?)?.toInt() ?? 0,
      documentNo: (json['documentNo'] as num?)?.toInt() ?? 0,
      documentType: (json['documentType'] ?? '').toString(),
      date:
          DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      paid: (json['paid'] as num?)?.toDouble() ?? 0,
      balanceDue: balance,
      controller: TextEditingController(text: '0'),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text, style: style, softWrap: true),
    );
  }
}

/// Build a screen-styled PDF for an incoming payment doc, mirroring the
/// fields rendered on the details screen above.
ErpDocumentPdfBuilder _buildIncomingPaymentPdfBuilder(
  _IncomingPaymentDocument doc,
) {
  String field(String value) =>
      erpPdfSafeText(value.trim().isEmpty ? '-' : value.trim());

  final headerFields = <ErpPdfField>[
    ErpPdfField(label: 'Customer', value: field(doc.cardName)),
    ErpPdfField(label: 'Card code', value: field(doc.cardCode)),
    ErpPdfField(label: 'Doc date', value: erpPdfSafeText(doc.docDateLabel)),
    ErpPdfField(label: 'Cash sum', value: doc.cashSum.toStringAsFixed(2)),
    ErpPdfField(label: 'Cash account', value: field(doc.cashAccount)),
    ErpPdfField(label: 'Control account', value: field(doc.controlAccount)),
  ];

  const columns = [
    ErpPdfColumn(label: 'Line num', flex: 8),
    ErpPdfColumn(label: 'Doc entry', flex: 12),
    ErpPdfColumn(label: 'Sum applied', flex: 12),
  ];

  final rows =
      doc.paymentInvoices
          .map(
            (line) => [
              line.lineNum.toString(),
              line.docEntry.toString(),
              line.sumApplied.toStringAsFixed(2),
            ],
          )
          .toList();

  return ErpDocumentPdfBuilder(
    title: 'Incoming Payment',
    docNum: doc.docNum.toString(),
    docEntry: doc.docEntry,
    statusLabel: erpPdfSafeText(
      doc.docType.isEmpty ? 'Payment' : doc.docType.trim(),
    ),
    headerFields: headerFields,
    linesColumns: columns,
    linesRows: rows,
    linesSectionTitle: 'Payment Invoices',
    remarks: doc.journalRemarks.trim(),
    alwaysShowRemarksRow: true,
    remarksPdfLabel: 'Remarks',
    totalLabel: 'Total',
    totalValue: doc.cashSum.toStringAsFixed(2),
    footerNote: 'Incoming Payment #${doc.docNum}',
  );
}
