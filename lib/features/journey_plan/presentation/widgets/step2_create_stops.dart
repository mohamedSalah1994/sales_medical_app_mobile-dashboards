import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sales_medical_app_mobile/core/di/service_locator.dart';
import 'package:sales_medical_app_mobile/core/error/error_message_helper.dart';
import 'package:sales_medical_app_mobile/core/network/api_service.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/core/utils/odbc_card_type_label.dart';
import 'package:sales_medical_app_mobile/core/utils/odbc_state_filter_options.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/customer.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/journey_plan.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_state.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/pages/visit_actions_page.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/widgets/stop_visit_card.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_cubit.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/delivery_from_sales_order_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/return_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/incoming_payment_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/sales_order_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/ready_for_delivery_picker_sheet.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/ready_for_return_picker_sheet.dart';
import 'package:sales_medical_app_mobile/features/surveys/presentation/pages/visit_survey_list_page.dart';

String? _customerGoogleMapsLink(Customer? customer) {
  return customer?.visitGoogleMapsFieldValue;
}

Visit? _visitFromPlan(JourneyPlan? plan, String visitId) {
  if (plan == null) return null;
  for (final stop in plan.stops) {
    final v = stop.visit;
    if (v != null && v.id == visitId) return v;
  }
  return null;
}

class Step2CreateStops extends StatefulWidget {
  const Step2CreateStops({super.key});

  @override
  State<Step2CreateStops> createState() => _Step2CreateStopsState();
}

class _Step2CreateStopsState extends State<Step2CreateStops> {
  final _formKey = GlobalKey<FormState>();
  final _customerSearchController = TextEditingController();
  final _notesController = TextEditingController();
  final _googleMapsLinkController = TextEditingController();
  final _durationController = TextEditingController(text: '30');

  /// Single date+time for the stop (replaces separate planned date and planned time).
  DateTime? _plannedDateTime;
  int _visitType = 1; // Will be set based on user role in initState
  int _estimatedDurationMinutes = 30;
  bool _wasLoading = false;

  /// After a successful "Add to list", skip re-seeding customer/date from the first stop
  /// (edit mode syncs on every rebuild and would otherwise refill cleared fields).
  bool _forceEmptyVisitFormAfterAdd = false;
  String? _formBoundPlanId;
  final Map<String, GlobalKey> _visitCardKeys = <String, GlobalKey>{};
  String? _highlightedVisitId;

  // Helper method to get default visit type based on user role
  int _getDefaultVisitType(BuildContext context) {
    // Always default to Normal (1) for all users including supervisors
    return 1;
  }

  // Local list to store pending stops before saving
  final List<_PendingStop> _pendingStops = [];

  @override
  void initState() {
    super.initState();
    _wasLoading = false;
    // Load customers when step 2 is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JourneyPlanCubit>().loadCustomers();
      // Pre-populate form fields when editing
      final state = context.read<JourneyPlanCubit>().state;
      if (state.isEditing && state.journeyPlan != null) {
        _notesController.text = state.notes;
      }
      // Set default visit type based on user role
      final defaultVisitType = _getDefaultVisitType(context);
      if (_visitType != defaultVisitType) {
        setState(() {
          _visitType = defaultVisitType;
        });
      }
    });
  }

  void _maybeResetFormBinding(JourneyPlanState state) {
    final id = state.journeyPlan?.id;
    if (id != null && id != _formBoundPlanId) {
      _formBoundPlanId = id;
      _forceEmptyVisitFormAfterAdd = false;
    }
  }

  void _syncFormFieldsFromState(JourneyPlanState state) {
    // Sync form fields with state when editing
    if (state.isEditing && state.journeyPlan != null) {
      _maybeResetFormBinding(state);
      // Sync notes - always update from state
      if (_notesController.text != state.notes) {
        _notesController.text = state.notes;
      }
      if (_forceEmptyVisitFormAfterAdd) {
        return;
      }
      // Populate form fields with first stop's data if available
      if (state.journeyPlan!.stops.isNotEmpty && state.customers.isNotEmpty) {
        final firstStop = state.journeyPlan!.stops.first;
        if (firstStop.visit != null) {
          // Set customer if not already set and customer exists in list
          if (state.selectedCustomer == null) {
            try {
              final customer = state.customers.firstWhere(
                (c) => c.id == firstStop.visit!.customerId,
              );
              context.read<JourneyPlanCubit>().selectCustomer(customer);
              _applySelectedCustomerLocation(customer);
            } catch (e) {
              // Customer not found in list, will be loaded later
            }
          }

          // Set planned date & time (single field from stop's planned time)
          if (_plannedDateTime == null) {
            setState(() {
              _plannedDateTime = firstStop.plannedTime;
            });
          }

          // Set duration
          if (_estimatedDurationMinutes == 30 &&
              firstStop.estimatedDurationMinutes != 30) {
            setState(() {
              _estimatedDurationMinutes = firstStop.estimatedDurationMinutes;
              _durationController.text =
                  '${firstStop.estimatedDurationMinutes}';
            });
          }
        }
      }
    }
  }

  DateTime _effectivePlannedDateTime(JourneyPlanState state) {
    final now = DateTime.now();
    final fallbackDate = state.journeyPlan?.startDate ?? state.startDate ?? now;
    return _plannedDateTime ??
        DateTime(
          fallbackDate.year,
          fallbackDate.month,
          fallbackDate.day,
          now.hour,
          now.minute,
        );
  }

  DateTime _dateTimeForBulkGroup(DateTime? groupDate, JourneyPlanState state) {
    final base = _effectivePlannedDateTime(state);
    if (groupDate == null) return base;
    return DateTime(
      groupDate.year,
      groupDate.month,
      groupDate.day,
      base.hour,
      base.minute,
    );
  }

  /// True when the journey plan (or step-1 draft) covers more than one calendar day.
  bool _planSpansMultipleCalendarDays(JourneyPlanState s) {
    final plan = s.journeyPlan;
    if (plan != null) {
      final a = DateTime(plan.startDate.year, plan.startDate.month, plan.startDate.day);
      final b = DateTime(plan.endDate.year, plan.endDate.month, plan.endDate.day);
      return a != b;
    }
    final start = s.startDate;
    if (start == null) return false;
    final end = s.endDate ?? _endDateForPlanType(start, s.planType);
    final a = DateTime(start.year, start.month, start.day);
    final b = DateTime(end.year, end.month, end.day);
    return a != b;
  }

  String? _currentSupervisorId(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final user = authState.loginResponse?.user;
    final role = user?.role.toLowerCase() ?? '';
    final isSalesRep = role == 'salesrep';
    final isSupervisor = role == 'supervisor';
    if (isSalesRep || isSupervisor) return null;
    if (user?.supervisorId?.isEmpty ?? true) return null;
    return user?.supervisorId;
  }

  bool _hasDuplicateVisitForCustomer({
    required JourneyPlanState state,
    required Customer customer,
    required DateTime plannedDateTime,
  }) {
    final plan = state.journeyPlan;
    if (plan == null) return false;

    final newSlot = DateTime(
      plannedDateTime.year,
      plannedDateTime.month,
      plannedDateTime.day,
      plannedDateTime.hour,
      plannedDateTime.minute,
    );

    return plan.stops.any((stop) {
      final visit = stop.visit;
      if (visit == null) return false;

      final aId = visit.customerId.trim().toLowerCase();
      final bId = customer.id.trim().toLowerCase();
      final aCode = (visit.customerCode ?? '').trim().toLowerCase();
      final bCode = customer.customerCode.trim().toLowerCase();
      final sameCustomer =
          (aId.isNotEmpty && aId == bId) ||
          (aCode.isNotEmpty && bCode.isNotEmpty && aCode == bCode);
      if (!sameCustomer) return false;

      final existingSlot = DateTime(
        stop.plannedTime.year,
        stop.plannedTime.month,
        stop.plannedTime.day,
        stop.plannedTime.hour,
        stop.plannedTime.minute,
      );
      return existingSlot == newSlot;
    });
  }

  void _resetVisitFormAfterSuccess(
    BuildContext context,
    JourneyPlanState state,
  ) {
    _forceEmptyVisitFormAfterAdd = true;
    _customerSearchController.clear();
    _googleMapsLinkController.clear();
    _durationController.text = '30';
    if (!state.isEditing) {
      _notesController.clear();
    }
    context.read<JourneyPlanCubit>().selectCustomer(null);
    setState(() {
      _plannedDateTime = null;
      _estimatedDurationMinutes = 30;
      _visitType = _getDefaultVisitType(context);
    });
    _formKey.currentState?.reset();
  }

  void _applySelectedCustomerLocation(Customer? customer) {
    _googleMapsLinkController.text = _customerGoogleMapsLink(customer) ?? '';
  }

  void _scrollToPendingVisit(JourneyPlanState state) {
    final visitId = state.pendingScrollToVisitId;
    if (visitId == null) return;
    final targetContext = _visitCardKeys[visitId]?.currentContext;
    if (targetContext == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
        alignment: 0.22,
      );
      if (!mounted) return;
      setState(() {
        _highlightedVisitId = visitId;
      });
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted || _highlightedVisitId != visitId) return;
        setState(() {
          _highlightedVisitId = null;
        });
      });
      if (!mounted) return;
      context.read<JourneyPlanCubit>().clearPendingScrollToVisit();
    });
  }

  Future<void> _showBulkCustomerSelectionDialog(
    BuildContext context,
    JourneyPlanState state,
  ) async {
    context.read<JourneyPlanCubit>().loadCustomers();
    final selectedCustomers = <String, Customer>{};
    final groupedSelections = <_BulkCustomerGroup>[];
    DateTime? selectedGroupDate;
    String? selectedStateCode;
    var stateOptions = <OdbcStateFilterOption>[];
    var stateOptionsLoading = true;
    var bulkSearch = '';
    var stateOptionsLoadStarted = false;

    Timer? bulkSearchDebounce;

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (dialogContext, setDialogState) {
                  if (!stateOptionsLoadStarted) {
                    stateOptionsLoadStarted = true;
                    loadOdbcStateFilterOptions(sl<ApiService>()).then((options) {
                      if (!dialogContext.mounted) return;
                      setDialogState(() {
                        stateOptions = options;
                        stateOptionsLoading = false;
                      });
                    });
                  }
                  return BlocProvider.value(
                  value: context.read<JourneyPlanCubit>(),
                  child: BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
                    builder: (context, dialogState) {
                      final bulkMultiDay =
                          _planSpansMultipleCalendarDays(dialogState);
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Builder(
                          builder: (context) {
                            final media = MediaQuery.of(dialogContext);
                            final viewInsets = media.viewInsets;
                            final availableHeight =
                                media.size.height -
                                viewInsets.top -
                                viewInsets.bottom;
                            return Container(
                          constraints: BoxConstraints(
                            maxWidth: 520,
                            maxHeight: math.min(
                              640,
                              availableHeight * 0.88,
                            ),
                          ),
                          child: LayoutBuilder(
                            builder: (context, dialogConstraints) {
                              final maxH = dialogConstraints.maxHeight;
                              final compact = maxH < 420;
                              final tight = maxH < 200;
                              final headerPad = compact ? 12.0 : 20.0;
                              final footerPad = compact ? 8.0 : 16.0;
                              final useStickyChrome = !tight;

                              Widget bulkHeader() {
                                return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: headerPad,
                                  vertical: compact ? 8 : headerPad,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.group_add_outlined,
                                      color: AppColors.primary,
                                      size: compact ? 22 : 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Create muliple visits',
                                        style: TextStyle(
                                          fontSize: compact ? 15 : 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      style: IconButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(36, 36),
                                      ),
                                      icon: const Icon(Icons.close),
                                      onPressed:
                                          () =>
                                              Navigator.of(dialogContext).pop(),
                                    ),
                                  ],
                                ),
                              );
                              }

                              List<Widget> bulkBodySlivers() {
                                return [
                              SliverToBoxAdapter(
                                child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: TextField(
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Search customers',
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
                                      borderSide: BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: AppColors.primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    bulkSearch = value;
                                    bulkSearchDebounce?.cancel();
                                    bulkSearchDebounce = Timer(
                                      const Duration(seconds: 1),
                                      () {
                                        final q = value.trim();
                                        context
                                            .read<JourneyPlanCubit>()
                                            .loadCustomers(
                                              search: q.isEmpty ? null : q,
                                              stateFilter: selectedStateCode,
                                            );
                                      },
                                    );
                                  },
                                ),
                              ),
                              ),
                              if (stateOptionsLoading)
                                const SliverToBoxAdapter(
                                  child: Padding(
                                  padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                                  child: SizedBox(
                                    height: 48,
                                    child: Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                )
                              else if (stateOptions.isNotEmpty)
                                SliverToBoxAdapter(
                                  child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    0,
                                    12,
                                    8,
                                  ),
                                  child: DropdownButtonFormField<String?>(
                                    value: selectedStateCode,
                                    decoration: const InputDecoration(
                                      labelText: 'State',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('All states'),
                                      ),
                                      ...stateOptions.map(
                                        (s) => DropdownMenuItem<String?>(
                                          value: s.code,
                                          child: Text(s.name),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setDialogState(() {
                                        selectedStateCode = value;
                                      });
                                      context
                                          .read<JourneyPlanCubit>()
                                          .loadCustomers(
                                            search:
                                                bulkSearch.trim().isEmpty
                                                    ? null
                                                    : bulkSearch.trim(),
                                            stateFilter: selectedStateCode,
                                          );
                                    },
                                  ),
                                ),
                                ),
                              SliverToBoxAdapter(
                                child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${selectedCustomers.length} customer(s) selected',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              ),
                              SliverToBoxAdapter(
                                child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  8,
                                  12,
                                  0,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () async {
                                              final chosen = await showDatePicker(
                                                context: dialogContext,
                                                initialDate:
                                                    selectedGroupDate ??
                                                    _effectivePlannedDateTime(
                                                      state,
                                                    ),
                                                firstDate:
                                                    state.startDate ??
                                                    DateTime.now().subtract(
                                                      const Duration(days: 365),
                                                    ),
                                                lastDate:
                                                    state.endDate ??
                                                    _endDateForPlanType(
                                                      state.startDate ??
                                                          DateTime.now(),
                                                      state.planType,
                                                    ),
                                              );
                                              if (chosen == null) return;
                                              setDialogState(() {
                                                selectedGroupDate = chosen;
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.event_outlined,
                                              size: 16,
                                            ),
                                            label: Text(
                                              selectedGroupDate == null
                                                  ? 'Date'
                                                  : DateFormat(
                                                    'dd/MM/yyyy',
                                                  ).format(selectedGroupDate!),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        if (selectedGroupDate != null &&
                                            !bulkMultiDay) ...[
                                          const SizedBox(width: 8),
                                          TextButton(
                                            onPressed: () {
                                              setDialogState(() {
                                                selectedGroupDate = null;
                                              });
                                            },
                                            child: const Text('Clear'),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (bulkMultiDay)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          'Visit date is required when the plan spans more than one day.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 48,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          if (selectedCustomers.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Select customers first',
                                                ),
                                                backgroundColor:
                                                    AppColors.error,
                                              ),
                                            );
                                            return;
                                          }
                                          if (bulkMultiDay &&
                                              selectedGroupDate == null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Select a visit date for this group',
                                                ),
                                                backgroundColor:
                                                    AppColors.error,
                                              ),
                                            );
                                            return;
                                          }
                                          setDialogState(() {
                                            groupedSelections.add(
                                              _BulkCustomerGroup(
                                                date: selectedGroupDate,
                                                customers:
                                                    selectedCustomers.values
                                                        .toList(),
                                              ),
                                            );
                                            selectedCustomers.clear();
                                            selectedGroupDate = null;
                                          });
                                        },
                                        icon: const Icon(Icons.playlist_add),
                                        label: const Text(
                                          'Add group',
                                          maxLines: 1,
                                          overflow: TextOverflow.visible,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ),
                              if (groupedSelections.isNotEmpty)
                                SliverToBoxAdapter(
                                  child: Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 120,
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    8,
                                    12,
                                    4,
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: groupedSelections.length,
                                    itemBuilder: (context, index) {
                                      final group = groupedSelections[index];
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${group.date == null ? 'No date' : DateFormat('dd/MM/yyyy').format(group.date!)} - ${group.customers.length} customers',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                setDialogState(() {
                                                  groupedSelections.removeAt(
                                                    index,
                                                  );
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.close,
                                                size: 16,
                                              ),
                                              constraints:
                                                  const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                ),
                              if (dialogState.isLoadingCustomers)
                                const SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (dialogState.customers.isEmpty)
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Text(
                                        dialogState.customersErrorMessage ??
                                            'No customers found',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final customer =
                                          dialogState.customers[index];
                                      final isSelected = selectedCustomers
                                          .containsKey(customer.id);
                                      return CheckboxListTile(
                                        value: isSelected,
                                        dense: true,
                                        activeColor: AppColors.primary,
                                        title: Text(
                                          customer.name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          [
                                            if (customer
                                                .customerCode
                                                .isNotEmpty)
                                              customer.customerCode,
                                            if (customer
                                                    .distinctForeignNameLine !=
                                                null)
                                              customer.distinctForeignNameLine!,
                                            if (customer.city.isNotEmpty)
                                              customer.city,
                                          ].join(' · '),
                                          style: const TextStyle(
                                            fontSize: 11,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        onChanged: (_) {
                                          setDialogState(() {
                                            if (isSelected) {
                                              selectedCustomers.remove(
                                                customer.id,
                                              );
                                            } else {
                                              selectedCustomers[customer.id] =
                                                  customer;
                                            }
                                          });
                                        },
                                      );
                                    },
                                    childCount: dialogState.customers.length,
                                  ),
                                ),
                                ];
                              }

                              Widget bulkFooter() {
                                return Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: footerPad,
                                  vertical: compact ? 6 : footerPad,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed:
                                            dialogState.isLoading
                                                ? null
                                                : () =>
                                                    Navigator.of(
                                                      dialogContext,
                                                    ).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed:
                                            dialogState.isLoading
                                                ? null
                                                : () async {
                                                  if (dialogState.journeyPlan ==
                                                      null) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Please create a journey plan first',
                                                        ),
                                                        backgroundColor:
                                                            AppColors.error,
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  if (selectedCustomers
                                                          .isEmpty &&
                                                      groupedSelections
                                                          .isEmpty) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Please select at least one customer',
                                                        ),
                                                        backgroundColor:
                                                            AppColors.error,
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  if (selectedCustomers
                                                      .isNotEmpty) {
                                                    if (bulkMultiDay &&
                                                        selectedGroupDate ==
                                                            null) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Select a visit date for the selected customers',
                                                          ),
                                                          backgroundColor:
                                                              AppColors.error,
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                    groupedSelections.add(
                                                      _BulkCustomerGroup(
                                                        date: selectedGroupDate,
                                                        customers:
                                                            selectedCustomers
                                                                .values
                                                                .toList(),
                                                      ),
                                                    );
                                                    selectedCustomers.clear();
                                                    selectedGroupDate = null;
                                                  }

                                                  if (bulkMultiDay) {
                                                    final missingDate = groupedSelections
                                                        .any((g) => g.date == null);
                                                    if (missingDate) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Each group needs a visit date for multi-day plans',
                                                          ),
                                                          backgroundColor:
                                                              AppColors.error,
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                  }

                                                  final supervisorId =
                                                      _currentSupervisorId(
                                                        context,
                                                      );
                                                  final cubit =
                                                      context
                                                          .read<
                                                            JourneyPlanCubit
                                                          >();
                                                  int createdCount = 0;
                                                  int failedCount = 0;

                                                  for (final group
                                                      in groupedSelections) {
                                                    final plannedDateTime =
                                                        _dateTimeForBulkGroup(
                                                          group.date,
                                                          state,
                                                        );
                                                    for (final customer
                                                        in group.customers) {
                                                      await cubit.createStopAndVisit(
                                                        customerCode:
                                                            customer
                                                                .customerCode,
                                                        customerName:
                                                            customer.name,
                                                        plannedDateTime:
                                                            plannedDateTime,
                                                        visitType: _visitType,
                                                        supervisorId:
                                                            supervisorId,
                                                        notes: null,
                                                        plannedTime:
                                                            plannedDateTime,
                                                        estimatedDurationMinutes:
                                                            _estimatedDurationMinutes,
                                                        googleMapsLink:
                                                            customer
                                                                .googleMapsLink,
                                                      );
                                                      final currentState =
                                                          cubit.state;
                                                      if (currentState
                                                                  .errorMessage ==
                                                              null &&
                                                          !currentState
                                                              .isLoading) {
                                                        createdCount++;
                                                      } else {
                                                        failedCount++;
                                                      }
                                                    }
                                                  }

                                                  final currentState =
                                                      context
                                                          .read<
                                                            JourneyPlanCubit
                                                          >()
                                                          .state;
                                                  if (createdCount > 0 &&
                                                      currentState
                                                              .errorMessage ==
                                                          null &&
                                                      mounted) {
                                                    Navigator.of(
                                                      dialogContext,
                                                    ).pop();
                                                    _resetVisitFormAfterSuccess(
                                                      context,
                                                      state,
                                                    );
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          failedCount == 0
                                                              ? '$createdCount visits created successfully'
                                                              : '$createdCount visits created, $failedCount failed',
                                                        ),
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                      ),
                                                    );
                                                  }
                                                },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          visualDensity: VisualDensity.compact,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child:
                                            dialogState.isLoading
                                                ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                                : const Text('Create'),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              }

                              final bodySlivers = bulkBodySlivers();
                              if (!useStickyChrome) {
                                return SizedBox(
                                  height: maxH,
                                  child: CustomScrollView(
                                    slivers: [
                                      SliverToBoxAdapter(child: bulkHeader()),
                                      ...bodySlivers,
                                      SliverToBoxAdapter(child: bulkFooter()),
                                    ],
                                  ),
                                );
                              }

                              return SizedBox(
                                height: maxH,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    bulkHeader(),
                                    Expanded(
                                      child: CustomScrollView(
                                        slivers: bodySlivers,
                                      ),
                                    ),
                                    bulkFooter(),
                                  ],
                                ),
                              );
                            },
                          ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
                },
          ),
    ).whenComplete(() => bulkSearchDebounce?.cancel());
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    _notesController.dispose();
    _googleMapsLinkController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<JourneyPlanCubit, JourneyPlanState>(
      listenWhen:
          (prev, curr) =>
              (prev.isLoading != curr.isLoading && !curr.isLoading) ||
              (prev.journeyPlan?.id != curr.journeyPlan?.id &&
                  curr.isEditing) ||
              prev.selectedCustomer != curr.selectedCustomer ||
              (prev.errorMessage != curr.errorMessage &&
                  curr.errorMessage != null),
      listener: (context, state) {
        if (state.selectedCustomer != null ||
            _googleMapsLinkController.text.isNotEmpty) {
          _applySelectedCustomerLocation(state.selectedCustomer);
        }
        // Sync form fields when journey plan is loaded
        if (state.isEditing && state.journeyPlan != null) {
          _syncFormFieldsFromState(state);
        }

        // Show error in popup dialog only when error message appears (not when it's cleared)
        if (!state.isLoading && state.errorMessage != null) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Error',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    state.errorMessage!,
                    style: const TextStyle(fontSize: 14),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
          );
        }

        // On success, stay on Step 2 to allow adding more stops
        if (!state.isLoading && state.errorMessage == null) {
          if (state.journeyPlan != null && !state.isEditing) {
            // Clear form for next stop - stay on Step 2
            // No automatic navigation - user can add more stops or use "Save and Return" button
          } else if (state.isEditing &&
              state.journeyPlan != null &&
              _wasLoading) {
            _wasLoading = false;
          }
        }

        // Track loading state
        if (state.isLoading) {
          _wasLoading = true;
        }
        _scrollToPendingVisit(state);
      },
      child: BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
        builder: (context, state) {
          // Sync form fields with state when editing and journey plan is loaded
          if (state.isEditing && state.journeyPlan != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _syncFormFieldsFromState(state);
            });
          }
          if (state.pendingScrollToVisitId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _scrollToPendingVisit(state);
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20),
                        iconSize: 20,
                        onPressed: () {
                          context.read<JourneyPlanCubit>().previousStep();
                        },
                        tooltip: 'Back to Step 1',
                      ),
                      Expanded(
                        child: Text(
                          l10n.journeyPlanAddVisitTitle,
                          textAlign: TextAlign.start,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Warning if no journey plan created
                  if (state.journeyPlan == null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.journeyPlanCreateFirstBeforeVisits,
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    state.isEditing
                        ? l10n.journeyPlanStep2SubtitleExisting
                        : l10n.journeyPlanStep2SubtitleNew,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Pending Stops List (when creating)
                  if (!state.isEditing && _pendingStops.isNotEmpty) ...[
                    Text(
                      '${l10n.pendingStops} (${_pendingStops.length})',
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._pendingStops.asMap().entries.map((entry) {
                      final index = entry.key;
                      final pendingStop = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warning),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    l10n.visitOrderBadge(index + 1),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                  ),
                                  color: AppColors.error,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() {
                                      _pendingStops.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    pendingStop.customerName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat(
                                    'MMM dd, yyyy • HH:mm',
                                  ).format(pendingStop.plannedDateTime),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Duration: ${pendingStop.estimatedDurationMinutes} minutes',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getVisitTypeColor(
                                      pendingStop.visitType,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _getVisitTypeName(
                                      pendingStop.visitType,
                                      context,
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _getVisitTypeColor(
                                        pendingStop.visitType,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                  ],
                  // Visits already saved on this plan (API). Show for new plans too — isEditing is false after create.
                  if (state.journeyPlan != null &&
                      state.journeyPlan!.stops.isNotEmpty) ...[
                    Text(
                      l10n.existingStops,
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...state.journeyPlan!.stops.map((stop) {
                      final visitId = stop.visit?.id;
                      final cardKey =
                          visitId == null
                              ? null
                              : (_visitCardKeys[visitId] ??= GlobalKey());
                      final isHighlighted =
                          visitId != null && visitId == _highlightedVisitId;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            key: cardKey,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  isHighlighted
                                      ? AppColors.primary.withValues(
                                        alpha: 0.08,
                                      )
                                      : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    isHighlighted
                                        ? AppColors.primary
                                        : AppColors.border,
                                width: isHighlighted ? 2 : 1,
                              ),
                              boxShadow:
                                  isHighlighted
                                      ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.18,
                                          ),
                                          blurRadius: 14,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                      : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Builder(
                                  builder: (context) {
                                    final role =
                                        context
                                            .read<AuthCubit>()
                                            .state
                                            .loginResponse
                                            ?.user
                                            .role
                                            .toLowerCase() ??
                                        '';
                                    final isSupervisor = role == 'supervisor';
                                    final isSalesRep = role == 'salesrep';
                                    final showShortStopNo =
                                        isSupervisor || isSalesRep;
                                    return Row(
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                showShortStopNo
                                                    ? '${stop.sequenceNo}'
                                                    : l10n.visitOrderBadge(
                                                      stop.sequenceNo,
                                                    ),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (!isSupervisor && !isSalesRep) ...[
                                          const SizedBox(width: 6),
                                          if (stop.visit != null)
                                            Flexible(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.success
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'Visit',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.success,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                        ],
                                        const SizedBox(width: 6),
                                        // Supervisor Assigned Badge (hidden for sales rep)
                                        if (stop.visit != null &&
                                            stop.visit!.supervisorId != null &&
                                            stop
                                                .visit!
                                                .supervisorId!
                                                .isNotEmpty)
                                          Flexible(
                                            child: Builder(
                                              builder: (context) {
                                                final authState =
                                                    context
                                                        .read<AuthCubit>()
                                                        .state;
                                                final user =
                                                    authState
                                                        .loginResponse
                                                        ?.user;
                                                final currentUserId = user?.id;
                                                final isSupervisorAssigned =
                                                    stop.visit!.supervisorId ==
                                                    currentUserId;
                                                final isSalesRep =
                                                    user?.role.toLowerCase() ==
                                                    'salesrep';

                                                if (isSalesRep) {
                                                  return const SizedBox.shrink();
                                                }
                                                // Show badge if current user is the assigned supervisor
                                                if (!isSupervisorAssigned) {
                                                  return const SizedBox.shrink();
                                                }

                                                return Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.warning
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .supervisor_account,
                                                        size: 12,
                                                        color:
                                                            AppColors.warning,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          isSupervisorAssigned
                                                              ? 'Assigned'
                                                              : stop
                                                                      .visit!
                                                                      .supervisorName ??
                                                                  'Supervisor',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                AppColors
                                                                    .warning,
                                                          ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        // Edit button (hidden in view-only mode)
                                        if (!state.isViewOnly) ...[
                                          const SizedBox(width: 6),
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              size: 18,
                                              color: AppColors.primary,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            onPressed: () {
                                              _showEditStopDialog(
                                                context,
                                                state,
                                                stop,
                                              );
                                            },
                                          ),
                                        ],
                                        // 3 dots menu for supervisor assignment (only for supervisors)
                                        Builder(
                                          builder: (context) {
                                            final authState =
                                                context.read<AuthCubit>().state;
                                            final user =
                                                authState.loginResponse?.user;
                                            final isSupervisor =
                                                user?.role.toLowerCase() ==
                                                'supervisor';

                                            if (!isSupervisor ||
                                                stop.visit == null) {
                                              return const SizedBox.shrink();
                                            }

                                            // Check if current supervisor is assigned and visit is not started
                                            final currentUserId = user?.id;
                                            final isCurrentSupervisorAssigned =
                                                stop.visit!.supervisorId !=
                                                    null &&
                                                stop.visit!.supervisorId ==
                                                    currentUserId;
                                            final visitStatus =
                                                stop.visit!.status;
                                            final isNotStarted =
                                                visitStatus == null ||
                                                visitStatus == 1;

                                            return PopupMenuButton<String>(
                                              icon: const Icon(
                                                Icons.more_vert,
                                                size: 20,
                                              ),
                                              color: AppColors.primary,
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onSelected: (value) {
                                                if (value == 'assign') {
                                                  _showAssignSupervisorDialog(
                                                    context,
                                                    state,
                                                    stop,
                                                  );
                                                } else if (value == 'remove') {
                                                  _removeSupervisorAssignment(
                                                    context,
                                                    state,
                                                    stop,
                                                  );
                                                }
                                              },
                                              itemBuilder: (context) {
                                                final items =
                                                    <PopupMenuItem<String>>[];

                                                // Add "Assign Supervisor" option
                                                items.add(
                                                  PopupMenuItem(
                                                    value: 'assign',
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.person_add,
                                                          size: 16,
                                                          color: Colors.white,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          'Assign Supervisor',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );

                                                // Add "Remove Assignment" option if conditions are met
                                                if (isCurrentSupervisorAssigned &&
                                                    isNotStarted) {
                                                  items.add(
                                                    PopupMenuItem(
                                                      value: 'remove',
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.person_remove,
                                                            size: 16,
                                                            color: Colors.white,
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Text(
                                                            'Remove Assignment',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }

                                                return items;
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                if (stop.visit != null) ...[
                                  const SizedBox(height: 12),
                                  Builder(
                                    builder: (context) {
                                      final visit = stop.visit!;
                                      return StopVisitCard(
                                        visit: visit,
                                        durationMinutes:
                                            stop.estimatedDurationMinutes,
                                        showActionsButton: true,
                                        showActionsMenu: true,
                                        onViewActions: () async {
                                          final cubit =
                                              context.read<JourneyPlanCubit>();
                                          await cubit
                                              .refreshJourneyPlanFromServer();
                                          if (!context.mounted) return;
                                          final freshVisit =
                                              _visitFromPlan(
                                                cubit.state.journeyPlan,
                                                visit.id,
                                              ) ??
                                              visit;
                                          await Navigator.of(
                                            context,
                                          ).push<void>(
                                            MaterialPageRoute<void>(
                                              builder:
                                                  (_) => BlocProvider(
                                                    create:
                                                        (_) =>
                                                            sl<
                                                              SalesOrderCubit
                                                            >(),
                                                    child: VisitActionsPage(
                                                      visit: freshVisit,
                                                    ),
                                                  ),
                                            ),
                                          );
                                          if (!context.mounted) return;
                                          await cubit
                                              .refreshJourneyPlanFromServer();
                                        },
                                        onCreateSalesOrder: () {
                                          final cubit =
                                              context.read<JourneyPlanCubit>();
                                          Navigator.of(context)
                                              .push<void>(
                                                MaterialPageRoute<void>(
                                                  builder:
                                                      (_) => BlocProvider(
                                                        create:
                                                            (_) =>
                                                                sl<
                                                                  SalesOrderCubit
                                                                >(),
                                                        child: SalesOrderPage(
                                                          visitId: visit.id,
                                                          initialCardCode:
                                                              visit
                                                                  .customerCode ??
                                                              visit.customerId,
                                                          initialCustomerName:
                                                              visit
                                                                  .customerName,
                                                        ),
                                                      ),
                                                ),
                                              )
                                              .then((_) async {
                                                if (!context.mounted) return;
                                                await cubit
                                                    .refreshJourneyPlanFromServer();
                                              });
                                        },
                                        onCreateDelivery: () async {
                                          final cubit =
                                              context.read<JourneyPlanCubit>();
                                          final salesOrderCubit =
                                              sl<SalesOrderCubit>();
                                          final docEntry =
                                              await showReadyForDeliveryPicker(
                                                context,
                                                salesOrderCubit,
                                                customerCardCode:
                                                    visit.erpCustomerCardOrId,
                                              );
                                          if (docEntry == null ||
                                              !context.mounted) {
                                            return;
                                          }
                                          await Navigator.of(
                                            context,
                                          ).push<void>(
                                            MaterialPageRoute<void>(
                                              builder:
                                                  (_) => BlocProvider.value(
                                                    value: salesOrderCubit,
                                                    child:
                                                        DeliveryFromSalesOrderPage(
                                                          salesOrderDocEntry:
                                                              docEntry,
                                                          visitId: visit.id,
                                                        ),
                                                  ),
                                            ),
                                          );
                                          if (!context.mounted) return;
                                          await cubit
                                              .refreshJourneyPlanFromServer();
                                        },
                                        onCreateReturn: () async {
                                          final cubit =
                                              context.read<JourneyPlanCubit>();
                                          final salesOrderCubit =
                                              sl<SalesOrderCubit>();
                                          final docEntry =
                                              await showReadyForReturnPicker(
                                                context,
                                                salesOrderCubit,
                                                customerCardCode:
                                                    visit.erpCustomerCardOrId,
                                              );
                                          if (docEntry == null ||
                                              !context.mounted) {
                                            return;
                                          }
                                          await Navigator.of(
                                            context,
                                          ).push<void>(
                                            MaterialPageRoute<void>(
                                              builder:
                                                  (_) => BlocProvider.value(
                                                    value: salesOrderCubit,
                                                    child:
                                                        ReturnPage.fromDelivery(
                                                          deliveryDocEntry:
                                                              docEntry,
                                                          visitId: visit.id,
                                                        ),
                                                  ),
                                            ),
                                          );
                                          if (!context.mounted) return;
                                          await cubit
                                              .refreshJourneyPlanFromServer();
                                        },
                                        onCreateIncomingPayment: () {
                                          final cubit =
                                              context.read<JourneyPlanCubit>();
                                          Navigator.of(context)
                                              .push<void>(
                                                MaterialPageRoute<void>(
                                                  builder:
                                                      (
                                                        _,
                                                      ) => IncomingPaymentCreatePage(
                                                        visitId: visit.id,
                                                        initialCardCode:
                                                            visit
                                                                .customerCode ??
                                                            visit.customerId,
                                                        initialCustomerName:
                                                            visit.customerName,
                                                      ),
                                                ),
                                              )
                                              .then((_) async {
                                                if (!context.mounted) return;
                                                await cubit
                                                    .refreshJourneyPlanFromServer();
                                              });
                                        },
                                        onSurvey: () {
                                          final cubit =
                                              context.read<JourneyPlanCubit>();
                                          Navigator.of(context)
                                              .push<void>(
                                                MaterialPageRoute<void>(
                                                  builder:
                                                      (_) =>
                                                          VisitSurveyListPage(
                                                            visitId: visit.id,
                                                          ),
                                                ),
                                              )
                                              .then((_) async {
                                                if (!context.mounted) return;
                                                await cubit
                                                    .refreshJourneyPlanFromServer();
                                              });
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    Text(
                      l10n.addNewVisit,
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Hide "Add New Stop" form in view-only mode
                  if (!state.isViewOnly) ...[
                    // Customer Selection
                    _CustomerSelector(
                      searchController: _customerSearchController,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed:
                            state.isLoading || state.journeyPlan == null
                                ? null
                                : () => _showBulkCustomerSelectionDialog(
                                  context,
                                  state,
                                ),
                        icon: const Icon(Icons.groups_2_outlined, size: 18),
                        label: const Text('Add multiple customers'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Visit Type (hidden for supervisors and SalesRep)
                    Builder(
                      builder: (context) {
                        final authState = context.read<AuthCubit>().state;
                        final user = authState.loginResponse?.user;
                        final role = user?.role.toLowerCase() ?? '';
                        final isSupervisor = role == 'supervisor';
                        final isSalesRep = role == 'salesrep';

                        // Hide visit type selector completely for supervisors and SalesRep
                        if (isSupervisor || isSalesRep) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.visitType,
                              textAlign: TextAlign.start,
                              style: Theme.of(
                                context,
                              ).textTheme.labelSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _VisitTypeSelector(
                              selectedType: _visitType,
                              onTypeSelected: (type) {
                                setState(() {
                                  _visitType = type;
                                });
                              },
                              hideNormal: false,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // Planned Date & Time: one field for both date and time
                    _DateField(
                      label: l10n.plannedDateAndTime,
                      date: _plannedDateTime,
                      onDateSelected: (date) {
                        setState(() {
                          _plannedDateTime = date;
                        });
                      },
                      firstDate: state.startDate,
                      lastDate:
                          state.endDate ??
                          _endDateForPlanType(
                            state.startDate ?? DateTime.now(),
                            state.planType,
                          ),
                    ),
                    const SizedBox(height: 12),
                    // Estimated Duration
                    Text(
                      l10n.estimatedDurationMinutes,
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13),
                      onChanged: (value) {
                        setState(() {
                          _estimatedDurationMinutes = int.tryParse(value) ?? 30;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: l10n.enterDurationMinutes,
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon: Icon(
                          Icons.timer_outlined,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Notes (Optional)
                    Text(
                      state.isEditing
                          ? 'Journey Plan Notes'
                          : 'Notes (Optional)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      enabled: !state.isViewOnly,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            state.isViewOnly
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                      ),
                      onChanged: (value) {
                        // Update journey plan notes when editing
                        if (state.isEditing) {
                          context.read<JourneyPlanCubit>().updateNotes(value);
                        }
                      },
                      decoration: InputDecoration(
                        hintText:
                            state.isEditing
                                ? 'Enter journey plan notes...'
                                : 'Enter any additional notes...',
                        hintStyle: const TextStyle(fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Google Maps Link (Optional)
                    Text(
                      'Google Maps Link (Optional)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _googleMapsLinkController,
                            enabled: !state.isViewOnly,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  state.isViewOnly
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Google Maps link will be generated automatically',
                              hintStyle: const TextStyle(fontSize: 13),
                              prefixIcon: Icon(
                                Icons.map_outlined,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Get Current Location Button
                        IconButton(
                          onPressed:
                              state.isViewOnly
                                  ? null
                                  : () => _getCurrentLocation(context),
                          icon: Icon(
                            Icons.my_location,
                            color:
                                state.isViewOnly
                                    ? AppColors.textSecondary
                                    : AppColors.primary,
                          ),
                          tooltip: 'Get current location',
                        ),
                        // Open Maps Button
                        IconButton(
                          onPressed:
                              state.isViewOnly
                                  ? null
                                  : () => _openGoogleMaps(context),
                          icon: Icon(
                            Icons.map,
                            color:
                                state.isViewOnly
                                    ? AppColors.textSecondary
                                    : AppColors.primary,
                          ),
                          tooltip: 'Open Google Maps to select location',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tip: Click the location icon to automatically get your current location, or click the map icon to open Google Maps and select a location manually.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        // Back Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                state.isLoading
                                    ? null
                                    : () {
                                      context
                                          .read<JourneyPlanCubit>()
                                          .previousStep();
                                    },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              side: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        // Create Button (hidden in view-only mode)
                        if (!state.isViewOnly) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed:
                                  state.isLoading || state.journeyPlan == null
                                      ? null
                                      : () async {
                                        if (_formKey.currentState!.validate()) {
                                          if (state.journeyPlan == null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please create a journey plan first',
                                                ),
                                                backgroundColor:
                                                    AppColors.error,
                                              ),
                                            );
                                            return;
                                          }
                                          if (state.selectedCustomer == null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please select a customer',
                                                ),
                                                backgroundColor:
                                                    AppColors.error,
                                              ),
                                            );
                                            return;
                                          }
                                          // Prevent duplicate: same customer at same planned date/time
                                          // Read latest plan from cubit (may have been updated by a previous add)
                                          final latestPlanState =
                                              context
                                                  .read<JourneyPlanCubit>()
                                                  .state;
                                          final effectivePlannedDateTime =
                                              _effectivePlannedDateTime(state);
                                          if (_hasDuplicateVisitForCustomer(
                                            state: latestPlanState,
                                            customer: state.selectedCustomer!,
                                            plannedDateTime:
                                                effectivePlannedDateTime,
                                          )) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'This customer already has a visit at this date and time. Please choose a different time or customer.',
                                                ),
                                                backgroundColor:
                                                    AppColors.error,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                            return;
                                          }
                                          final supervisorId =
                                              _currentSupervisorId(context);

                                          // Get Google Maps link from controller (read fresh at save time)
                                          final googleMapsLinkValue =
                                              _googleMapsLinkController.text
                                                  .trim();
                                          final finalGoogleMapsLink =
                                              googleMapsLinkValue.isEmpty
                                                  ? null
                                                  : googleMapsLinkValue;

                                          // Create pending stop object (same datetime for both)
                                          final pendingStop = _PendingStop(
                                            customerId:
                                                state.selectedCustomer!.id,
                                            customerCode:
                                                state
                                                    .selectedCustomer!
                                                    .customerCode,
                                            customerName:
                                                state.selectedCustomer!.name,
                                            plannedDateTime:
                                                effectivePlannedDateTime,
                                            plannedTime:
                                                effectivePlannedDateTime,
                                            visitType: _visitType,
                                            estimatedDurationMinutes:
                                                _estimatedDurationMinutes,
                                            googleMapsLink: finalGoogleMapsLink,
                                          );

                                          // Try to save immediately
                                          await context
                                              .read<JourneyPlanCubit>()
                                              .createStopAndVisit(
                                                customerCode:
                                                    pendingStop.customerCode,
                                                customerName:
                                                    pendingStop.customerName,
                                                plannedDateTime:
                                                    pendingStop.plannedDateTime,
                                                visitType:
                                                    pendingStop.visitType,
                                                supervisorId: supervisorId,
                                                notes: null,
                                                plannedTime:
                                                    pendingStop.plannedTime,
                                                estimatedDurationMinutes:
                                                    pendingStop
                                                        .estimatedDurationMinutes,
                                                googleMapsLink:
                                                    pendingStop.googleMapsLink,
                                              );

                                          // Check if save was successful
                                          final currentState =
                                              context
                                                  .read<JourneyPlanCubit>()
                                                  .state;
                                          if (currentState.errorMessage ==
                                                  null &&
                                              !currentState.isLoading &&
                                              currentState.journeyPlan !=
                                                  null) {
                                            // Save successful — clear all visit form fields for the next add
                                            _resetVisitFormAfterSuccess(
                                              context,
                                              state,
                                            );
                                          }
                                        }
                                      },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  state.isLoading
                                      ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                      : Text(
                                        l10n.addToList,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ], // End of view-only check for "Add New Stop" form
                  // Save and Return Button (always show when in Step 2 with a journey plan, but hide in view-only mode)
                  if (state.journeyPlan != null && !state.isViewOnly) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            state.isLoading
                                ? null
                                : () {
                                  // Hide the create form to return to main view
                                  context
                                      .read<JourneyPlanCubit>()
                                      .hideCreateForm();
                                  // Reload journey plans to show updated cards
                                  final authState =
                                      context.read<AuthCubit>().state;
                                  final userId =
                                      authState.loginResponse?.user.id;
                                  if (userId != null) {
                                    final cubit =
                                        context.read<JourneyPlanCubit>();
                                    final currentState = cubit.state;
                                    if (currentState.selectedTabIndex == 0) {
                                      cubit.loadJourneyPlans(userId: userId);
                                    } else {
                                      cubit.loadJourneyPlans(
                                        createdById: userId,
                                      );
                                    }
                                  }
                                  // If we navigated here, pop the route
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  }
                                },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          side: BorderSide(color: AppColors.primary, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          l10n.saveAndReturn,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Save All Stops Button (when creating or editing and has pending stops, but hide in view-only mode)
                  if (_pendingStops.isNotEmpty && !state.isViewOnly) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            state.isLoading
                                ? null
                                : () async {
                                  if (state.journeyPlan == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please create a journey plan first',
                                        ),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                    return;
                                  }

                                  // Get supervisorId from logged-in user
                                  final authState =
                                      context.read<AuthCubit>().state;
                                  final user = authState.loginResponse?.user;
                                  final role = user?.role.toLowerCase() ?? '';
                                  final isSalesRep = role == 'salesrep';
                                  final isSupervisor = role == 'supervisor';
                                  // Omit supervisorId for sales reps and supervisors (API expects null/omit)
                                  final supervisorId =
                                      (isSalesRep || isSupervisor)
                                          ? null
                                          : (user?.supervisorId?.isEmpty ?? true
                                              ? null
                                              : user?.supervisorId);

                                  // Save all pending stops (these are stops that failed to save earlier)
                                  final stopsToSave = List<_PendingStop>.from(
                                    _pendingStops,
                                  );
                                  final savedStops = <_PendingStop>[];

                                  for (final pendingStop in stopsToSave) {
                                    await context
                                        .read<JourneyPlanCubit>()
                                        .createStopAndVisit(
                                          customerCode:
                                              pendingStop.customerCode,
                                          customerName:
                                              pendingStop.customerName,
                                          plannedDateTime:
                                              pendingStop.plannedDateTime,
                                          visitType: pendingStop.visitType,
                                          supervisorId: supervisorId,
                                          notes: null,
                                          plannedTime: pendingStop.plannedTime,
                                          estimatedDurationMinutes:
                                              pendingStop
                                                  .estimatedDurationMinutes,
                                          googleMapsLink:
                                              pendingStop.googleMapsLink,
                                        );

                                    // Check for errors
                                    final currentState =
                                        context.read<JourneyPlanCubit>().state;
                                    if (currentState.errorMessage == null &&
                                        !currentState.isLoading) {
                                      // Successfully saved - mark for removal
                                      savedStops.add(pendingStop);
                                    } else {
                                      // Error occurred - stop trying to save remaining
                                      break;
                                    }
                                  }

                                  // Remove successfully saved stops from pending list
                                  if (savedStops.isNotEmpty) {
                                    setState(() {
                                      _pendingStops.removeWhere(
                                        (stop) => savedStops.contains(stop),
                                      );
                                    });
                                  }

                                  // Navigate back to main journey view after saving
                                  if (mounted) {
                                    // Hide the create form to return to main view
                                    context
                                        .read<JourneyPlanCubit>()
                                        .hideCreateForm();
                                    // Reload journey plans to show updated cards
                                    final authState =
                                        context.read<AuthCubit>().state;
                                    final userId =
                                        authState.loginResponse?.user.id;
                                    if (userId != null) {
                                      final cubit =
                                          context.read<JourneyPlanCubit>();
                                      final currentState = cubit.state;
                                      if (currentState.selectedTabIndex == 0) {
                                        cubit.loadJourneyPlans(userId: userId);
                                      } else {
                                        cubit.loadJourneyPlans(
                                          createdById: userId,
                                        );
                                      }
                                    }
                                  }
                                },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon:
                            state.isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.save),
                        label: Text(
                          state.isLoading
                              ? l10n.saving
                              : '${l10n.saveAllStops} (${_pendingStops.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getVisitTypeColor(int visitType) {
    switch (visitType) {
      case 1:
        return AppColors.primary;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getVisitTypeName(int visitType, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (visitType) {
      case 1:
        return l10n.normal;
      case 2:
        return l10n.coach;
      case 3:
        return l10n.double;
      default:
        return 'Unknown';
    }
  }

  void _showEditStopDialog(BuildContext context, JourneyPlanState state, stop) {
    final l10n = AppLocalizations.of(context)!;
    final _plannedTimeController = TextEditingController();
    final _durationController = TextEditingController();
    DateTime? _plannedTime;
    int _estimatedDurationMinutes = stop.estimatedDurationMinutes;

    // Initialize controllers
    _durationController.text = _estimatedDurationMinutes.toString();

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<JourneyPlanCubit>(),
            child: StatefulBuilder(
              builder:
                  (
                    dialogBuilderContext,
                    setDialogState,
                  ) => BlocListener<JourneyPlanCubit, JourneyPlanState>(
                    listenWhen:
                        (prev, curr) =>
                            prev.isLoading != curr.isLoading && !curr.isLoading,
                    listener: (context, currentState) {
                      if (currentState.errorMessage == null &&
                          !currentState.isLoading) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                    child: BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
                      builder: (context, currentState) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            constraints: const BoxConstraints(
                              maxWidth: 500,
                              maxHeight: 600,
                            ),
                            padding: const EdgeInsets.all(24),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.edit_location,
                                          color: AppColors.primary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          l10n.editVisit,
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
                                            () =>
                                                Navigator.of(
                                                  dialogContext,
                                                ).pop(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // Stop Info
                                  if (stop.visit != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            size: 18,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              stop.visit!.customerName,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  // Planned Time
                                  Text(
                                    l10n.plannedTime,
                                    style: Theme.of(
                                      dialogBuilderContext,
                                    ).textTheme.labelLarge?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () async {
                                      final now = DateTime.now();
                                      final start =
                                          currentState.startDate ?? now;
                                      final end =
                                          currentState.endDate ??
                                          _endDateForPlanType(
                                            start,
                                            currentState.planType,
                                          );
                                      final initial = _plannedTime ?? now;
                                      final initialClamped =
                                          initial.isBefore(start)
                                              ? start
                                              : (initial.isAfter(end)
                                                  ? end
                                                  : initial);
                                      final selectedDate = await showDatePicker(
                                        context: dialogBuilderContext,
                                        initialDate: initialClamped,
                                        firstDate: start,
                                        lastDate: end,
                                      );
                                      if (selectedDate != null) {
                                        final selectedTime =
                                            await showTimePicker(
                                              context: dialogBuilderContext,
                                              initialTime:
                                                  TimeOfDay.fromDateTime(
                                                    _plannedTime ??
                                                        DateTime.now(),
                                                  ),
                                            );
                                        if (selectedTime != null) {
                                          setDialogState(() {
                                            _plannedTime = DateTime(
                                              selectedDate.year,
                                              selectedDate.month,
                                              selectedDate.day,
                                              selectedTime.hour,
                                              selectedTime.minute,
                                            );
                                            _plannedTimeController
                                                .text = DateFormat(
                                              'MMM dd, yyyy - HH:mm',
                                            ).format(_plannedTime!);
                                          });
                                        }
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            color: AppColors.textSecondary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _plannedTime != null
                                                  ? DateFormat(
                                                    'MMM dd, yyyy - HH:mm',
                                                  ).format(_plannedTime!)
                                                  : 'Select planned time',
                                              style: TextStyle(
                                                color:
                                                    _plannedTime != null
                                                        ? AppColors.textPrimary
                                                        : AppColors
                                                            .textSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: AppColors.textSecondary,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Estimated Duration
                                  Text(
                                    l10n.estimatedDurationMinutes,
                                    style: Theme.of(
                                      dialogBuilderContext,
                                    ).textTheme.labelLarge?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _durationController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        _estimatedDurationMinutes =
                                            int.tryParse(value) ?? 30;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: l10n.enterDurationMinutes,
                                      prefixIcon: Icon(
                                        Icons.timer_outlined,
                                        color: AppColors.textSecondary,
                                      ),
                                      filled: true,
                                      fillColor: AppColors.surface,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Error Message
                                  // Error Message
                                  if (currentState.errorMessage != null)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.error,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: AppColors.error,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              currentState.errorMessage!,
                                              style: TextStyle(
                                                color: AppColors.error,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed:
                                              () =>
                                                  Navigator.of(
                                                    dialogContext,
                                                  ).pop(),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            side: BorderSide(
                                              color: AppColors.border,
                                              width: 2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(l10n.cancel),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 2,
                                        child: ElevatedButton(
                                          onPressed:
                                              currentState.isLoading
                                                  ? null
                                                  : () {
                                                    if (_plannedTime == null) {
                                                      ScaffoldMessenger.of(
                                                        dialogBuilderContext,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Please select planned time',
                                                          ),
                                                          backgroundColor:
                                                              AppColors.error,
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                    dialogBuilderContext
                                                        .read<
                                                          JourneyPlanCubit
                                                        >()
                                                        .updateStop(
                                                          stopId: stop.id,
                                                          visitId: stop.visitId,
                                                          sequenceNo:
                                                              stop.sequenceNo,
                                                          plannedTime:
                                                              _plannedTime!,
                                                          estimatedDurationMinutes:
                                                              _estimatedDurationMinutes,
                                                        );
                                                  },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child:
                                              currentState.isLoading
                                                  ? const SizedBox(
                                                    height: 24,
                                                    width: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                  : Text(
                                                    l10n.updateVisit,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            ),
          ),
    );
  }

  void _showAssignSupervisorDialog(
    BuildContext context,
    JourneyPlanState state,
    stop,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.read<AuthCubit>().state;
    final user = authState.loginResponse?.user;
    final supervisorId = user?.id ?? '';
    final supervisorName = user?.fullName ?? '';
    int _selectedVisitType = 2; // Default to Coach (2)

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<JourneyPlanCubit>(),
            child: StatefulBuilder(
              builder:
                  (
                    dialogBuilderContext,
                    setDialogState,
                  ) => BlocListener<JourneyPlanCubit, JourneyPlanState>(
                    listenWhen:
                        (prev, curr) =>
                            prev.isLoading != curr.isLoading && !curr.isLoading,
                    listener: (context, currentState) {
                      if (currentState.errorMessage == null &&
                          !currentState.isLoading) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                    child: BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
                      builder: (context, currentState) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            constraints: const BoxConstraints(
                              maxWidth: 500,
                              maxHeight: 600,
                            ),
                            padding: const EdgeInsets.all(24),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.supervisor_account,
                                          color: AppColors.primary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Assign Supervisor',
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
                                            () =>
                                                Navigator.of(
                                                  dialogContext,
                                                ).pop(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // Supervisor Info
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.05,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 20,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Supervisor',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                              Text(
                                                supervisorName,
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
                                  const SizedBox(height: 24),
                                  // Visit Type Selection
                                  Text(
                                    'Visit Type',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      // Coach (2)
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            setDialogState(() {
                                              _selectedVisitType = 2;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color:
                                                  _selectedVisitType == 2
                                                      ? AppColors.primary
                                                          .withValues(
                                                            alpha: 0.1,
                                                          )
                                                      : AppColors.surface,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color:
                                                    _selectedVisitType == 2
                                                        ? AppColors.primary
                                                        : AppColors.border,
                                                width:
                                                    _selectedVisitType == 2
                                                        ? 2
                                                        : 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.school,
                                                  color:
                                                      _selectedVisitType == 2
                                                          ? AppColors.primary
                                                          : AppColors
                                                              .textSecondary,
                                                  size: 32,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Coach',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        _selectedVisitType == 2
                                                            ? AppColors.primary
                                                            : AppColors
                                                                .textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Double (3)
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            setDialogState(() {
                                              _selectedVisitType = 3;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color:
                                                  _selectedVisitType == 3
                                                      ? AppColors.primary
                                                          .withValues(
                                                            alpha: 0.1,
                                                          )
                                                      : AppColors.surface,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color:
                                                    _selectedVisitType == 3
                                                        ? AppColors.primary
                                                        : AppColors.border,
                                                width:
                                                    _selectedVisitType == 3
                                                        ? 2
                                                        : 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.people,
                                                  color:
                                                      _selectedVisitType == 3
                                                          ? AppColors.primary
                                                          : AppColors
                                                              .textSecondary,
                                                  size: 32,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Double',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        _selectedVisitType == 3
                                                            ? AppColors.primary
                                                            : AppColors
                                                                .textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // Error Message
                                  if (currentState.errorMessage != null)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.error,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: AppColors.error,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              currentState.errorMessage!,
                                              style: TextStyle(
                                                color: AppColors.error,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed:
                                              () =>
                                                  Navigator.of(
                                                    dialogContext,
                                                  ).pop(),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            side: BorderSide(
                                              color: AppColors.border,
                                              width: 2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(l10n.cancel),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 2,
                                        child: ElevatedButton(
                                          onPressed:
                                              currentState.isLoading
                                                  ? null
                                                  : () {
                                                    dialogBuilderContext
                                                        .read<
                                                          JourneyPlanCubit
                                                        >()
                                                        .updateVisitSupervisorAndType(
                                                          visitId:
                                                              stop.visit!.id,
                                                          supervisorId:
                                                              supervisorId,
                                                          visitType:
                                                              _selectedVisitType,
                                                        );
                                                  },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child:
                                              currentState.isLoading
                                                  ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  )
                                                  : Text(
                                                    'Assign',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            ),
          ),
    );
  }

  void _removeSupervisorAssignment(
    BuildContext context,
    JourneyPlanState state,
    stop,
  ) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.person_remove, color: AppColors.error, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Remove Assignment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to remove yourself from this visit? This action cannot be undone.',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  l10n.cancel,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();

                  // When removing supervisor, reset visit type to Normal (1)
                  // This removes the Coach/Double flag
                  const visitType = 1; // Normal

                  // Call cubit to remove supervisor assignment (pass null for supervisorId)
                  await context
                      .read<JourneyPlanCubit>()
                      .updateVisitSupervisorAndType(
                        visitId: stop.visit!.id,
                        supervisorId: null, // null to remove assignment
                        visitType: visitType, // Reset to Normal (1)
                      );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Remove',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  /// Generates a Google Maps link from coordinates
  String _generateGoogleMapsLink(double latitude, double longitude) {
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }

  /// Gets the current location and generates a Google Maps link
  Future<void> _getCurrentLocation(BuildContext context) async {
    // Show loading indicator
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Check location service status
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading
          _showLocationErrorDialog(
            context,
            'Location services are disabled. Please enable location services in your device settings.',
          );
        }
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            Navigator.of(context).pop(); // Close loading
            _showLocationErrorDialog(
              context,
              'Location permissions are denied. Please grant location permission to use this feature.',
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading
          _showLocationErrorDialog(
            context,
            'Location permissions are permanently denied. Please enable them in app settings.',
            showSettingsButton: true,
          );
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Generate Google Maps link
      final mapsLink = _generateGoogleMapsLink(
        position.latitude,
        position.longitude,
      );

      // Update the text field
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        setState(() {
          _googleMapsLinkController.text = mapsLink;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location captured successfully!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        _showLocationErrorDialog(
          context,
          userFriendlyErrorMessage(e.toString()),
        );
      }
    }
  }

  /// Shows location error dialog
  void _showLocationErrorDialog(
    BuildContext context,
    String message, {
    bool showSettingsButton = false,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error),
                const SizedBox(width: 8),
                const Text('Location Error'),
              ],
            ),
            content: Text(message),
            actions: [
              if (showSettingsButton)
                TextButton(
                  onPressed: () async {
                    await openAppSettings();
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Open Settings'),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  /// Opens Google Maps for manual location selection
  Future<void> _openGoogleMaps(BuildContext context) async {
    bool success = false;

    // First, try the web URL directly (most reliable)
    try {
      final webUrl = Uri.parse('https://www.google.com/maps');
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      success = true;
    } catch (e) {
      // If that fails, try platform-specific URLs
      try {
        Uri? platformUrl;
        if (Platform.isAndroid) {
          // Try Google Maps app (Android)
          platformUrl = Uri.parse('geo:0,0?q=');
        } else if (Platform.isIOS) {
          // Try Google Maps app (iOS)
          platformUrl = Uri.parse('comgooglemaps://');
        }

        if (platformUrl != null) {
          try {
            await launchUrl(platformUrl, mode: LaunchMode.externalApplication);
            success = true;
          } catch (_) {
            // App not installed, fall through to web
          }
        }

        // If app launch failed, try web again with different mode
        if (!success) {
          final webUrl = Uri.parse('https://www.google.com/maps');
          await launchUrl(webUrl, mode: LaunchMode.platformDefault);
          success = true;
        }
      } catch (e2) {
        // Both failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not open Google Maps. Please ensure you have a browser or Google Maps installed. Error: ${e2.toString()}',
              ),
              duration: const Duration(seconds: 4),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Google Maps opened. Select a location, tap Share, copy the link, and paste it in the field above.',
          ),
          duration: Duration(seconds: 4),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }
}

class _VisitTypeSelector extends StatelessWidget {
  const _VisitTypeSelector({
    required this.selectedType,
    required this.onTypeSelected,
    this.hideNormal = false,
  });

  final int selectedType;
  final ValueChanged<int> onTypeSelected;
  final bool hideNormal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // If Normal is hidden and Normal is selected, default to Coach
    final effectiveSelectedType =
        hideNormal && selectedType == 1 ? 2 : selectedType;

    return Row(
      children: [
        if (!hideNormal) ...[
          Expanded(
            child: _VisitTypeCard(
              type: 1,
              title: l10n.normal,
              icon: Icons.check_circle_outline,
              isSelected: effectiveSelectedType == 1,
              onTap: () => onTypeSelected(1),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: _VisitTypeCard(
            type: 2,
            title: l10n.coach,
            icon: Icons.school_outlined,
            isSelected: effectiveSelectedType == 2,
            onTap: () => onTypeSelected(2),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _VisitTypeCard(
            type: 3,
            title: l10n.double,
            icon: Icons.double_arrow,
            isSelected: effectiveSelectedType == 3,
            onTap: () => onTypeSelected(3),
          ),
        ),
      ],
    );
  }
}

class _VisitTypeCard extends StatelessWidget {
  const _VisitTypeCard({
    required this.type,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final int type;
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 14,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 9,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// End date for a given start date and plan type (matches Step 1: day=same day, week=+7d, month=+1, quarter=+3, year=+1).
DateTime _endDateForPlanType(DateTime startDate, int planType) {
  final d = DateTime(startDate.year, startDate.month, startDate.day);
  switch (planType) {
    case 1:
      return d; // day → 24 hours of that day
    case 2:
      return d.add(const Duration(days: 7)); // week → all hours of week
    case 3:
      return DateTime(d.year, d.month + 1, d.day); // month
    case 4:
      return DateTime(d.year, d.month + 3, d.day); // quarter
    case 5:
      return DateTime(d.year + 1, d.month, d.day); // year
    default:
      return d;
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    this.date,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onDateSelected;

  /// When set (e.g. from journey plan Step 1), limits selectable date range.
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final effectiveFirst = firstDate ?? now;
    final effectiveLast = lastDate ?? now.add(const Duration(days: 365));
    DateTime clampToRange(DateTime d) {
      if (d.isBefore(effectiveFirst)) return effectiveFirst;
      if (d.isAfter(effectiveLast)) return effectiveLast;
      return d;
    }

    final initialDate = clampToRange(date ?? now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: TextAlign.start,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: effectiveFirst,
              lastDate: effectiveLast,
            );
            if (selectedDate != null) {
              final selectedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(date ?? DateTime.now()),
              );
              if (selectedTime != null) {
                onDateSelected(
                  DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  ),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('MMM dd, yyyy - HH:mm').format(date!)
                        : 'Select $label',
                    style: TextStyle(
                      color:
                          date != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomerSelector extends StatefulWidget {
  const _CustomerSelector({required this.searchController});

  final TextEditingController searchController;

  @override
  State<_CustomerSelector> createState() => _CustomerSelectorState();
}

class _CustomerSelectorState extends State<_CustomerSelector> {
  String? _singleSelectedStateCode;
  List<OdbcStateFilterOption> _singleStateOptions = const [];
  String _singleSearchText = '';
  Timer? _singleSearchDebounce;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _singleSearchDebounce?.cancel();
    super.dispose();
  }

  void _showCustomerSelectionDialog(BuildContext context) {
    // Load customers when dialog opens
    context.read<JourneyPlanCubit>().loadCustomers();
    _singleSearchText = '';
    _loadSingleStateOptions();

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<JourneyPlanCubit>(),
            child: BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
              builder: (context, state) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 500,
                      maxHeight: 600,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.business,
                                color: AppColors.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)!.selectCustomer,
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
                        // Search Field
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: TextField(
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText:
                                  AppLocalizations.of(
                                    dialogContext,
                                  )!.searchCustomers,
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
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              _singleSearchText = value;
                              _singleSearchDebounce?.cancel();
                              _singleSearchDebounce = Timer(
                                const Duration(seconds: 1),
                                () {
                                  if (!mounted) return;
                                  final q = value.trim();
                                  context
                                      .read<JourneyPlanCubit>()
                                      .loadCustomers(
                                        search: q.isEmpty ? null : q,
                                        stateFilter: _singleSelectedStateCode,
                                      );
                                },
                              );
                            },
                          ),
                        ),
                        if (_singleStateOptions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: DropdownButtonFormField<String?>(
                              value: _singleSelectedStateCode,
                              decoration: const InputDecoration(
                                labelText: 'State',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('All states'),
                                ),
                                ..._singleStateOptions.map(
                                  (s) => DropdownMenuItem<String?>(
                                    value: s.code,
                                    child: Text(s.name),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _singleSelectedStateCode = value;
                                });
                                context.read<JourneyPlanCubit>().loadCustomers(
                                  search:
                                      _singleSearchText.trim().isEmpty
                                          ? null
                                          : _singleSearchText.trim(),
                                  stateFilter: _singleSelectedStateCode,
                                );
                              },
                            ),
                          ),
                        // Customer List
                        Expanded(
                          child:
                              state.isLoadingCustomers
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : state.customers.isEmpty
                                  ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Text(
                                        state.customersErrorMessage ??
                                            'No customers found',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                  : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: state.customers.length,
                                    itemBuilder: (context, index) {
                                      final customer = state.customers[index];
                                      return InkWell(
                                        onTap: () {
                                          context
                                              .read<JourneyPlanCubit>()
                                              .selectCustomer(customer);
                                          final rootState =
                                              context
                                                  .findAncestorStateOfType<
                                                    _Step2CreateStopsState
                                                  >();
                                          rootState
                                              ?._googleMapsLinkController
                                              .text = _customerGoogleMapsLink(
                                                customer,
                                              ) ??
                                              '';
                                          widget.searchController.text =
                                              customer.name;
                                          Navigator.of(dialogContext).pop();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: AppColors.border,
                                                width:
                                                    index <
                                                            state
                                                                    .customers
                                                                    .length -
                                                                1
                                                        ? 1
                                                        : 0,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.business,
                                                  color: AppColors.primary,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      customer.name,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            AppColors
                                                                .textPrimary,
                                                      ),
                                                    ),
                                                    if (odbcCardTypeKindLabel(
                                                          customer.cardType,
                                                        )
                                                        .isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              top: 2,
                                                            ),
                                                        child: Text(
                                                          odbcCardTypeKindLabel(
                                                            customer.cardType,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: AppColors
                                                                .primary
                                                                .withValues(
                                                                  alpha: 0.95,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    if (customer
                                                            .distinctForeignNameLine !=
                                                        null)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              top: 2,
                                                            ),
                                                        child: Text(
                                                          customer
                                                              .distinctForeignNameLine!,
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            color:
                                                                AppColors
                                                                    .textSecondary,
                                                          ),
                                                          maxLines: 2,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                    if (customer
                                                        .customerCode
                                                        .isNotEmpty)
                                                      Text(
                                                        'Code: ${customer.customerCode}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              AppColors
                                                                  .textSecondary,
                                                        ),
                                                      ),
                                                    if (customer
                                                        .city
                                                        .isNotEmpty)
                                                      Text(
                                                        customer.city,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              AppColors
                                                                  .textSecondary,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                        // Error Message
                        if (state.customersErrorMessage != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.error),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      state.customersErrorMessage!,
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
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
    ).whenComplete(() => _singleSearchDebounce?.cancel());
  }

  Future<void> _loadSingleStateOptions() async {
    final parsed = await loadOdbcStateFilterOptions(sl<ApiService>());
    if (!mounted) return;
    setState(() {
      _singleStateOptions = parsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            // Customer Field (Read-only, tappable)
            InkWell(
              onTap: () {
                _showCustomerSelectionDialog(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.business,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.selectedCustomer != null
                            ? state.selectedCustomer!.name
                            : l10n.tapToSelectCustomer,
                        style: TextStyle(
                          color:
                              state.selectedCustomer != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (state.selectedCustomer != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.info_outline, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              _CustomerSelectorState._showCustomerDetailsPopup(
                                context,
                                state.selectedCustomer!,
                                l10n,
                              );
                            },
                            tooltip: 'View Details',
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              context.read<JourneyPlanCubit>().selectCustomer(
                                null,
                              );
                              final rootState =
                                  context
                                      .findAncestorStateOfType<
                                        _Step2CreateStopsState
                                      >();
                              rootState?._googleMapsLinkController.text = '';
                              widget.searchController.clear();
                            },
                            tooltip: 'Clear',
                          ),
                        ],
                      )
                    else
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void _showCustomerDetailsPopup(
    BuildContext context,
    customer,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.business,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Customer Details',
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
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(context, 'Name', customer.name),
                          if (customer.distinctForeignNameLine != null)
                            _buildDetailRow(
                              context,
                              'Foreign name',
                              customer.distinctForeignNameLine!,
                            ),
                          if (customer.customerCode.isNotEmpty)
                            _buildDetailRow(
                              context,
                              'Customer Code',
                              customer.customerCode,
                            ),
                          if (customer.address.isNotEmpty)
                            _buildDetailRow(
                              context,
                              'Address',
                              customer.address,
                            ),
                          if (customer.city.isNotEmpty)
                            _buildDetailRow(context, 'City', customer.city),
                          if (customer.phone.isNotEmpty)
                            _buildDetailRow(context, 'Phone', customer.phone),
                          if (customer.email.isNotEmpty)
                            _buildDetailRow(context, 'Email', customer.email),
                          if (customer.latitude != 0.0 &&
                              customer.longitude != 0.0)
                            _buildDetailRow(
                              context,
                              'Location',
                              '${customer.latitude.toStringAsFixed(6)}, ${customer.longitude.toStringAsFixed(6)}',
                            ),
                          _buildDetailRow(
                            context,
                            'Status',
                            customer.status == 1 ? 'Active' : 'Inactive',
                            valueColor:
                                customer.status == 1
                                    ? AppColors.success
                                    : AppColors.error,
                          ),
                          if (customer.externalId.isNotEmpty)
                            _buildDetailRow(
                              context,
                              'External ID',
                              customer.externalId,
                            ),
                          _buildDetailRow(
                            context,
                            'Created At',
                            DateFormat(
                              'MMM dd, yyyy - HH:mm',
                            ).format(customer.createdAt),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.close),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  static Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingStop {
  final String customerId;
  final String customerCode;
  final String customerName;
  final DateTime plannedDateTime;
  final DateTime plannedTime;
  final int visitType;
  final int estimatedDurationMinutes;
  final String? googleMapsLink;

  _PendingStop({
    required this.customerId,
    required this.customerCode,
    required this.customerName,
    required this.plannedDateTime,
    required this.plannedTime,
    required this.visitType,
    required this.estimatedDurationMinutes,
    this.googleMapsLink,
  });
}

class _BulkCustomerGroup {
  final DateTime? date;
  final List<Customer> customers;

  _BulkCustomerGroup({required this.date, required this.customers});
}

