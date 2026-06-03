import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/di/service_locator.dart';
import 'package:sales_medical_app_mobile/core/error/error_message_helper.dart';
import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit_action.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_cubit.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/delivery_from_sales_order_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/incoming_payment_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/return_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/sales_order_page.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/entities/survey_response_entities.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/repositories/survey_repository.dart';
import 'package:sales_medical_app_mobile/features/surveys/presentation/pages/visit_survey_response_pages.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';

enum _ErpNavKind {
  salesOrder,
  delivery,
  returnDoc,
  incomingPayment,
  none,
}

int? _erpDocEntry(VisitAction action) {
  final raw = action.sapDocumentId;
  if (raw == null || raw.isEmpty) return null;
  return int.tryParse(raw);
}

_ErpNavKind _erpNavKind(VisitAction action) {
  final c = action.actionCode.toUpperCase();
  if (c == 'SALES_ORDER' || (c.contains('SALES') && c.contains('ORDER'))) {
    return _ErpNavKind.salesOrder;
  }
  if (_isIncomingPaymentActionCode(c)) {
    return _ErpNavKind.incomingPayment;
  }
  if (c.contains('RETURN')) {
    return _ErpNavKind.returnDoc;
  }
  if (c.contains('DELIV') || c.contains('DELIVERY')) {
    return _ErpNavKind.delivery;
  }
  return _ErpNavKind.none;
}

bool _isIncomingPaymentActionCode(String c) {
  if (c == 'INCOMING_PAYMENT' ||
      c == 'INCOMINGPAYMENT' ||
      c.contains('INCOMING_PAYMENT')) {
    return true;
  }
  return c.contains('INCOMING') && c.contains('PAYMENT');
}

bool _erpCanOpen(VisitAction action) {
  return _erpDocEntry(action) != null &&
      _erpNavKind(action) != _ErpNavKind.none;
}

/// Page showing ERP visit actions and **answered** survey responses only
/// (GET /api/Surveys/responses). Use the visit card menu to start a new survey.
class VisitActionsPage extends StatefulWidget {
  const VisitActionsPage({super.key, required this.visit});

  final Visit visit;

  @override
  State<VisitActionsPage> createState() => _VisitActionsPageState();
}

class _VisitActionsPageState extends State<VisitActionsPage> {
  final _repo = sl<SurveyRepository>();

  List<SurveyResponseEntry> _submissions = [];
  bool _loadingExtras = true;
  String? _extrasError;

  @override
  void initState() {
    super.initState();
    _loadSurveyResponses();
  }

  Future<void> _loadSurveyResponses() async {
    setState(() {
      _loadingExtras = true;
      _extrasError = null;
    });
    try {
      final subs = await _repo.getSurveyResponses(
        visitId: widget.visit.id,
        pageNumber: 1,
        pageSize: 100,
      );
      if (!mounted) return;
      final filtered =
          subs.items.where((e) => e.hasAnsweredQuestions).toList()..sort(
            (a, b) => (b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(
                  a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                ),
          );
      setState(() {
        _submissions = filtered;
        _loadingExtras = false;
      });
    } on ServerFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingExtras = false;
        _extrasError = userFriendlyErrorMessage(e.message);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingExtras = false;
        _extrasError = userFriendlyErrorMessage(e.toString());
      });
    }
  }

  void _onErpActionTap(BuildContext context, VisitAction action) {
    final docEntry = _erpDocEntry(action);
    if (docEntry == null) return;

    final kind = _erpNavKind(action);
    if (kind == _ErpNavKind.incomingPayment) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => IncomingPaymentDetailsPage.fromDocEntry(docEntry: docEntry),
        ),
      );
      return;
    }

    final salesOrderCubit = context.read<SalesOrderCubit>();
    switch (kind) {
      case _ErpNavKind.salesOrder:
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder:
                (_) => BlocProvider.value(
                  value: salesOrderCubit,
                  child: SalesOrderPage(
                    showScaffold: true,
                    initialDocEntry: docEntry,
                  ),
                ),
          ),
        );
      case _ErpNavKind.delivery:
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder:
                (_) => BlocProvider.value(
                  value: salesOrderCubit,
                  child: DeliveryFromSalesOrderPage.viewExisting(
                    existingDeliveryDocEntry: docEntry,
                  ),
                ),
          ),
        );
      case _ErpNavKind.returnDoc:
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder:
                (_) => BlocProvider.value(
                  value: salesOrderCubit,
                  child: ReturnPage.viewExisting(returnDocEntry: docEntry),
                ),
          ),
        );
      case _ErpNavKind.incomingPayment:
      case _ErpNavKind.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = widget.visit.actions;
    final l10n = AppLocalizations.of(context)!;

    final children = <Widget>[
      ...actions.map(
        (action) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ErpActionCard(
            action: action,
            onTap: () => _onErpActionTap(context, action),
          ),
        ),
      ),
      if (_loadingExtras)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        )
      else if (_extrasError != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            _extrasError!,
            style: const TextStyle(color: AppColors.error, fontSize: 14),
          ),
        ),
      ..._submissions.map(
        (e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SurveySubmissionActionCard(
            entry: e,
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder:
                      (_) => VisitSurveyResponseDetailPage(responseId: e.id),
                ),
              );
            },
          ),
        ),
      ),
    ];

    final hasAny = actions.isNotEmpty || _submissions.isNotEmpty;
    final showEmpty = !_loadingExtras && _extrasError == null && !hasAny;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Visit Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSurveyResponses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          showEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.visitSurveyNoErpActions,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: () async {
                  await _loadSurveyResponses();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: children,
                ),
              ),
    );
  }
}

class _ErpActionCard extends StatelessWidget {
  const _ErpActionCard({required this.action, required this.onTap});

  final VisitAction action;
  final VoidCallback onTap;

  static String _statusLabel(int? status) {
    if (status == null) return '—';
    switch (status) {
      case 1:
        return 'Pending';
      case 2:
        return 'In Progress';
      case 3:
        return 'Completed';
      case 4:
        return 'Cancelled';
      case 5:
        return 'Rejected';
      case 6:
        return 'Posted';
      default:
        return 'Status $status';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = action.actionName ?? action.actionCode;
    final openable = _erpCanOpen(action);
    final docNum = action.sapDocumentNumber;
    final docDate =
        action.postedAt != null
            ? DateFormat.yMMMd().format(action.postedAt!)
            : '—';
    final statusText = _statusLabel(action.status);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: openable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (docNum != null && docNum.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$docNum',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  if (docNum != null && docNum.isNotEmpty)
                    const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    docDate,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (openable) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurveySubmissionActionCard extends StatelessWidget {
  const _SurveySubmissionActionCard({required this.entry, required this.onTap});

  final SurveyResponseEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date =
        entry.submittedAt != null
            ? DateFormat.yMMMd().add_jm().format(entry.submittedAt!)
            : '—';
    final title =
        entry.surveyName.isNotEmpty ? entry.surveyName : entry.surveyId;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 22,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
