import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sales_medical_app_mobile/core/di/service_locator.dart';
import 'package:sales_medical_app_mobile/core/error/error_message_helper.dart';
import 'package:sales_medical_app_mobile/core/network/api_service.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/core/utils/odbc_card_type_label.dart';
import 'package:sales_medical_app_mobile/core/utils/odbc_state_filter_options.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:sales_medical_app_mobile/features/customers/presentation/pages/customers_page.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/customer.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_state.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/pages/visit_actions_page.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/widgets/stop_visit_card.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_cubit.dart';
import 'package:sales_medical_app_mobile/features/surveys/presentation/pages/visit_survey_list_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/delivery_from_sales_order_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/return_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/incoming_payment_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/pages/sales_order_page.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/ready_for_delivery_picker_sheet.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/ready_for_return_picker_sheet.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

String? _customerGoogleMapsLink(Customer? customer) {
  return customer?.visitGoogleMapsFieldValue;
}

/// Bottom sheet to create a standalone visit (not linked to a journey plan).
/// Uses the same create-visit API with journey plan id "standalone".
/// [customersCubit] is used to navigate to Create Customer from the sheet.
void showStandaloneVisitSheet(
  BuildContext context, {
  CustomersCubit? customersCubit,
}) {
  final createCustomerCubit = customersCubit ?? context.read<CustomersCubit>();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (sheetContext) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder:
              (_, scrollController) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: BlocProvider.value(
                  value: context.read<JourneyPlanCubit>(),
                  child: _StandaloneVisitSheetContent(
                    scrollController: scrollController,
                    showDragHandle: true,
                    createCustomerCubit: createCustomerCubit,
                    onCreated: () {
                      Navigator.of(sheetContext).pop();
                      final l10n = AppLocalizations.of(context)!;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.visitCreatedSuccess),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      // Do not call loadVisits(userId) here - it has no tab params and overwrites current/history
                      // List will refresh on pull-to-refresh or when content reloads for current tab
                    },
                  ),
                ),
              ),
        ),
  );
}

/// Full-page widget for the Standalone Visit tab. Shows the same form as the sheet.
class StandaloneVisitPage extends StatefulWidget {
  const StandaloneVisitPage({super.key, this.onCreated});

  final VoidCallback? onCreated;

  @override
  State<StandaloneVisitPage> createState() => _StandaloneVisitPageState();
}

class _StandaloneVisitPageState extends State<StandaloneVisitPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<JourneyPlanCubit>().selectCustomer(null);
        // Initial visits load is done by _StandaloneVisitSheetContent._loadVisitsForCurrentTab
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onCreated() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.visitCreatedSuccess),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.onCreated?.call();
    // Reload for current tab is done by _StandaloneVisitSheetContent after create
  }

  Future<void> _onRefreshVisits() async {
    // No-op: content uses _loadVisitsForCurrentTab() in RefreshIndicator so tab params are correct
  }

  @override
  Widget build(BuildContext context) {
    return _StandaloneVisitSheetContent(
      scrollController: _scrollController,
      showDragHandle: false,
      onCreated: _onCreated,
      onRefreshVisits: _onRefreshVisits,
      createCustomerCubit: context.read<CustomersCubit>(),
    );
  }
}

class _StandaloneVisitSheetContent extends StatefulWidget {
  const _StandaloneVisitSheetContent({
    required this.scrollController,
    required this.onCreated,
    this.showDragHandle = true,
    this.onRefreshVisits,
    this.createCustomerCubit,
  });

  final ScrollController scrollController;
  final VoidCallback onCreated;
  final bool showDragHandle;
  final Future<void> Function()? onRefreshVisits;
  final CustomersCubit? createCustomerCubit;

  @override
  State<_StandaloneVisitSheetContent> createState() =>
      _StandaloneVisitSheetContentState();
}

class _StandaloneVisitSheetContentState
    extends State<_StandaloneVisitSheetContent> {
  /// 0 = History (past), 1 = Current (today), 2 = Future
  int _visitListTabIndex = 1;
  DateTime? _plannedDateTime;
  int _visitType = 1;
  final _customerSearchController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _googleMapsLinkController = TextEditingController();
  String? _selectedCustomerStateCode;
  List<OdbcStateFilterOption> _customerStateOptions = const [];
  String _customerDialogSearch = '';
  Timer? _customerDialogSearchDebounce;

  void _applySelectedCustomerLocation(Customer? customer) {
    _googleMapsLinkController.text = _customerGoogleMapsLink(customer) ?? '';
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadCustomerStateOptions());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onRefreshVisits == null) {
        context.read<JourneyPlanCubit>().loadCustomers(
          stateFilter: _selectedCustomerStateCode,
        );
        context.read<JourneyPlanCubit>().selectCustomer(null);
        _applySelectedCustomerLocation(null);
      } else {
        _visitListTabIndex =
            context.read<JourneyPlanCubit>().state.standaloneVisitsTabIndex;
        _loadVisitsForCurrentTab();
        _attachScrollListener();
      }
    });
  }

  @override
  void dispose() {
    _customerDialogSearchDebounce?.cancel();
    widget.scrollController.removeListener(_onScroll);
    _customerSearchController.dispose();
    _durationController.dispose();
    _googleMapsLinkController.dispose();
    super.dispose();
  }

  void _attachScrollListener() {
    widget.scrollController.removeListener(_onScroll);
    widget.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = widget.scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200 && pos.maxScrollExtent > 0) {
      final state = context.read<JourneyPlanCubit>().state;
      if (!state.visitsHasNextPage || state.isLoadingMoreVisits) return;
      final userId = context.read<AuthCubit>().state.loginResponse?.user.id;
      if (userId == null) return;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      DateTime? startDate;
      DateTime? endDate;
      if (_visitListTabIndex == 0) {
        endDate = today;
      } else if (_visitListTabIndex == 1) {
        startDate = today;
      } else {
        startDate = today.add(const Duration(days: 1));
      }
      context.read<JourneyPlanCubit>().loadVisits(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        status: null,
        standaloneOnly: true,
        applyStatusFilterFromState: false,
        pageNumber: state.visitsPageNumber + 1,
        pageSize: 20,
        append: true,
      );
    }
  }

  Future<void> _loadVisitsForCurrentTab() async {
    if (!mounted) return;
    context.read<JourneyPlanCubit>().setStandaloneVisitsTabIndex(
      _visitListTabIndex,
    );
    final userId = context.read<AuthCubit>().state.loginResponse?.user.id;
    if (userId == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? startDate;
    DateTime? endDate;
    if (_visitListTabIndex == 0) {
      endDate = today;
    } else if (_visitListTabIndex == 1) {
      startDate = today;
    } else {
      startDate = today.add(const Duration(days: 1));
    }
    await context.read<JourneyPlanCubit>().loadVisits(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      status: null,
      standaloneOnly: true,
      applyStatusFilterFromState: false,
      pageNumber: 1,
      pageSize: 20,
    );
  }

  Future<void> _loadCustomerStateOptions() async {
    final options = await loadOdbcStateFilterOptions(sl<ApiService>());
    if (!mounted) return;
    setState(() {
      _customerStateOptions = options;
    });
  }

  void _showCustomerDialog() {
    context.read<JourneyPlanCubit>().loadCustomers(
      stateFilter: _selectedCustomerStateCode,
    );
    showDialog<void>(
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText:
                                  AppLocalizations.of(context)!.searchCustomers,
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
                              _customerDialogSearch = value;
                              _customerDialogSearchDebounce?.cancel();
                              _customerDialogSearchDebounce = Timer(
                                const Duration(seconds: 1),
                                () {
                                  if (!mounted) return;
                                  final q = value.trim();
                                  context
                                      .read<JourneyPlanCubit>()
                                      .loadCustomers(
                                        search: q.isEmpty ? null : q,
                                        stateFilter: _selectedCustomerStateCode,
                                      );
                                },
                              );
                            },
                          ),
                        ),
                        if (_customerStateOptions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                            child: DropdownButtonFormField<String?>(
                              value: _selectedCustomerStateCode,
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
                                ..._customerStateOptions.map(
                                  (s) => DropdownMenuItem<String?>(
                                    value: s.code,
                                    child: Text(s.name),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCustomerStateCode = value;
                                });
                                context.read<JourneyPlanCubit>().loadCustomers(
                                  search:
                                      _customerDialogSearch.trim().isEmpty
                                          ? null
                                          : _customerDialogSearch.trim(),
                                  stateFilter: _selectedCustomerStateCode,
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 8),
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
                                            AppLocalizations.of(
                                              context,
                                            )!.customersNoCustomersFoundList,
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
                                      return _CustomerTile(
                                        customer: customer,
                                        onTap: () {
                                          context
                                              .read<JourneyPlanCubit>()
                                              .selectCustomer(customer);
                                          _applySelectedCustomerLocation(
                                            customer,
                                          );
                                          _customerSearchController.text =
                                              customer.name;
                                          Navigator.of(dialogContext).pop();
                                        },
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
    ).whenComplete(() => _customerDialogSearchDebounce?.cancel());
  }

  void _openCreateCustomer() {
    final cubit = widget.createCustomerCubit;
    if (cubit == null) return;
    final isSheet = widget.onRefreshVisits == null;
    final navigator = Navigator.of(context);
    if (isSheet) navigator.pop();
    navigator.push<void>(
      MaterialPageRoute(
        builder:
            (_) => BlocProvider.value(
              value: cubit,
              child: const CustomersPage(showScaffold: true),
            ),
      ),
    );
  }

  Future<void> _submit() async {
    final cubit = context.read<JourneyPlanCubit>();
    final state = cubit.state;
    final authState = context.read<AuthCubit>().state;
    final user = authState.loginResponse?.user;

    final userId = user?.id;
    final l10n = AppLocalizations.of(context)!;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.userNotFound),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (state.selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectCustomer),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final effectivePlannedDateTime = _plannedDateTime ?? DateTime.now();

    final role = user?.role.toLowerCase() ?? '';
    final supervisorId =
        (role == 'salesrep' || role == 'supervisor')
            ? null
            : (user?.supervisorId?.isEmpty ?? true ? null : user?.supervisorId);

    final googleMapsLink = _googleMapsLinkController.text.trim();
    await cubit.createStandaloneVisit(
      userId: userId,
      customerCode: state.selectedCustomer!.customerCode,
      customerName: state.selectedCustomer!.name,
      plannedDateTime: effectivePlannedDateTime,
      visitType: _visitType,
      supervisorId: supervisorId,
      notes: null,
      googleMapsLink: googleMapsLink.isEmpty ? null : googleMapsLink,
    );

    if (!mounted) return;
    final currentState = context.read<JourneyPlanCubit>().state;
    if (currentState.errorMessage == null && !currentState.isLoading) {
      widget.onCreated();
      final planned = effectivePlannedDateTime;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final planDay = DateTime(planned.year, planned.month, planned.day);
      var targetTab = 1;
      if (planDay.isBefore(today)) {
        targetTab = 0;
      } else if (planDay.isAfter(today)) {
        targetTab = 2;
      }
      setState(() => _visitListTabIndex = targetTab);
      if (mounted) {
        context.read<JourneyPlanCubit>().setStandaloneVisitsTabIndex(targetTab);
      }
      await _loadVisitsForCurrentTab();
    }
  }

  String _generateGoogleMapsLink(double latitude, double longitude) {
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }

  Future<void> _getCurrentLocation(BuildContext context) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          Navigator.of(context).pop();
          _showLocationErrorDialog(context, l10n.locationServicesDisabled);
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            Navigator.of(context).pop();
            _showLocationErrorDialog(context, l10n.locationPermissionDenied);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          Navigator.of(context).pop();
          _showLocationErrorDialog(
            context,
            l10n.locationPermissionDeniedForever,
            showSettingsButton: true,
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final mapsLink = _generateGoogleMapsLink(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        Navigator.of(context).pop();
        setState(() {
          _googleMapsLinkController.text = mapsLink;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.locationCapturedSuccess),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showLocationErrorDialog(
          context,
          userFriendlyErrorMessage(e.toString()),
        );
      }
    }
  }

  void _showLocationErrorDialog(
    BuildContext context,
    String message, {
    bool showSettingsButton = false,
  }) {
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
                Icon(Icons.error_outline, color: AppColors.error),
                const SizedBox(width: 8),
                Text(l10n.locationErrorTitle),
              ],
            ),
            content: Text(message),
            actions: [
              if (showSettingsButton)
                TextButton(
                  onPressed: () async {
                    await openAppSettings();
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: Text(l10n.openSettings),
                ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.ok),
              ),
            ],
          ),
    );
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    bool success = false;

    try {
      final webUrl = Uri.parse('https://www.google.com/maps');
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      success = true;
    } catch (e) {
      try {
        Uri? platformUrl;
        if (Platform.isAndroid) {
          platformUrl = Uri.parse('geo:0,0?q=');
        } else if (Platform.isIOS) {
          platformUrl = Uri.parse('comgooglemaps://');
        }

        if (platformUrl != null) {
          try {
            await launchUrl(platformUrl, mode: LaunchMode.externalApplication);
            success = true;
          } catch (_) {}
        }

        if (!success) {
          final webUrl = Uri.parse('https://www.google.com/maps');
          await launchUrl(webUrl, mode: LaunchMode.platformDefault);
          success = true;
        }
      } catch (e2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.couldNotOpenGoogleMaps} ${e2.toString()}'),
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
        SnackBar(
          content: Text(l10n.googleMapsOpenedPasteLinkAbove),
          duration: const Duration(seconds: 4),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<JourneyPlanCubit, JourneyPlanState>(
      listenWhen:
          (prev, curr) =>
              prev.selectedCustomer != curr.selectedCustomer ||
              prev.standaloneVisitsTabIndex != curr.standaloneVisitsTabIndex ||
              prev.errorMessage != curr.errorMessage &&
                  curr.errorMessage != null,
      listener: (context, state) {
        if (state.selectedCustomer != null ||
            _googleMapsLinkController.text.isNotEmpty) {
          _applySelectedCustomerLocation(state.selectedCustomer);
        }
        if (widget.onRefreshVisits != null &&
            state.standaloneVisitsTabIndex != _visitListTabIndex) {
          setState(() {
            _visitListTabIndex = state.standaloneVisitsTabIndex;
          });
          _loadVisitsForCurrentTab();
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: RefreshIndicator(
        onRefresh: () async {
          if (widget.onRefreshVisits != null) await _loadVisitsForCurrentTab();
        },
        child: ListView(
          controller: widget.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: widget.showDragHandle ? 12 : 20,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          children: [
            if (widget.showDragHandle) ...[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Standalone visits list with History / Current / Future tabs (full page only)
            if (widget.onRefreshVisits != null) ...[
              _StandaloneVisitTabs(
                l10n: l10n,
                tabIndex: _visitListTabIndex,
                onTabChanged: (i) {
                  setState(() => _visitListTabIndex = i);
                  _loadVisitsForCurrentTab();
                },
              ),
              const SizedBox(height: 12),
              BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
                buildWhen:
                    (prev, curr) =>
                        prev.visits != curr.visits ||
                        prev.isLoadingVisits != curr.isLoadingVisits ||
                        prev.visitsErrorMessage != curr.visitsErrorMessage ||
                        prev.visitsPageNumber != curr.visitsPageNumber ||
                        prev.visitsHasNextPage != curr.visitsHasNextPage ||
                        prev.isLoadingMoreVisits != curr.isLoadingMoreVisits,
                builder: (context, state) {
                  final listL10n = AppLocalizations.of(context)!;
                  if (state.isLoadingVisits && state.visits.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (state.visitsErrorMessage != null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        state.visitsErrorMessage!,
                        style: TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    );
                  }
                  final now = DateTime.now();
                  final todayStart = DateTime(now.year, now.month, now.day);
                  // API already filters by tab; use state.visits as-is
                  final list =
                      state.visits
                          .where(
                            (visit) =>
                                visit.journeyPlanId == null ||
                                visit.journeyPlanId!.trim().isEmpty ||
                                visit.journeyPlanId!.trim().toLowerCase() ==
                                    'standalone',
                          )
                          .toList();
                  if (list.isEmpty) {
                    final emptyMsg =
                        _visitListTabIndex == 0
                            ? listL10n.standaloneListNoPastVisits
                            : _visitListTabIndex == 1
                            ? listL10n.standaloneListNoVisitsToday
                            : listL10n.standaloneListNoFutureVisits;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          emptyMsg,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }
                  // Group visits by date and sort
                  final visitDate =
                      (Visit v) => DateTime(
                        v.plannedDateTime.year,
                        v.plannedDateTime.month,
                        v.plannedDateTime.day,
                      );
                  final grouped = <DateTime, List<Visit>>{};
                  for (final v in list) {
                    final d = visitDate(v);
                    grouped.putIfAbsent(d, () => []).add(v);
                  }
                  for (final visitList in grouped.values) {
                    visitList.sort(
                      (a, b) => a.plannedDateTime.compareTo(b.plannedDateTime),
                    );
                  }
                  final dates = grouped.keys.toList();
                  dates.sort(
                    (a, b) =>
                        _visitListTabIndex == 0
                            ? b.compareTo(a)
                            : a.compareTo(b),
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...dates.expand((date) {
                        final visits = grouped[date]!;
                        final isToday = date == todayStart;
                        final isYesterday =
                            _visitListTabIndex == 0 &&
                            date ==
                                todayStart.subtract(const Duration(days: 1));
                        final dateLabel =
                            isToday
                                ? listL10n.dateLabelToday
                                : isYesterday
                                ? listL10n.dateLabelYesterday
                                : DateFormat.yMMMd().format(date);
                        return [
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Text(
                              dateLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          ...visits.map(
                            (visit) => StopVisitCard(
                              visit: visit,
                              durationMinutes: null,
                              showEditIcon: false,
                              showActionsButton: true,
                              disableForPastDate: true,
                              onViewActions: () {
                                final salesOrderCubit =
                                    context.read<SalesOrderCubit>();
                                Navigator.of(context)
                                    .push<void>(
                                      MaterialPageRoute<void>(
                                        builder:
                                            (_) => BlocProvider.value(
                                              value: salesOrderCubit,
                                              child: VisitActionsPage(
                                                visit: visit,
                                              ),
                                            ),
                                      ),
                                    )
                                    .then((_) {
                                      if (!mounted) return;
                                      _loadVisitsForCurrentTab();
                                    });
                              },
                              showActionsMenu: true,
                              onCreateSalesOrder: () {
                                final salesOrderCubit =
                                    context.read<SalesOrderCubit>();
                                Navigator.of(context)
                                    .push<void>(
                                      MaterialPageRoute<void>(
                                        builder:
                                            (_) => BlocProvider.value(
                                              value: salesOrderCubit,
                                              child: SalesOrderPage(
                                                visitId: visit.id,
                                                initialCardCode:
                                                    visit.customerCode ??
                                                    visit.customerId,
                                                initialCustomerName:
                                                    visit.customerName,
                                              ),
                                            ),
                                      ),
                                    )
                                    .then((_) {
                                      if (!mounted) return;
                                      _loadVisitsForCurrentTab();
                                    });
                              },
                              onCreateDelivery: () async {
                                final salesOrderCubit =
                                    context.read<SalesOrderCubit>();
                                final docEntry =
                                    await showReadyForDeliveryPicker(
                                      context,
                                      salesOrderCubit,
                                      customerCardCode:
                                          visit.erpCustomerCardOrId,
                                    );
                                if (docEntry == null || !context.mounted) {
                                  return;
                                }
                                await Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder:
                                        (_) => BlocProvider.value(
                                          value: salesOrderCubit,
                                          child: DeliveryFromSalesOrderPage(
                                            salesOrderDocEntry: docEntry,
                                            visitId: visit.id,
                                          ),
                                        ),
                                  ),
                                );
                                if (!mounted) return;
                                _loadVisitsForCurrentTab();
                              },
                              onCreateReturn: () async {
                                final salesOrderCubit =
                                    context.read<SalesOrderCubit>();
                                final docEntry = await showReadyForReturnPicker(
                                  context,
                                  salesOrderCubit,
                                  customerCardCode: visit.erpCustomerCardOrId,
                                );
                                if (docEntry == null || !context.mounted) {
                                  return;
                                }
                                await Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder:
                                        (_) => BlocProvider.value(
                                          value: salesOrderCubit,
                                          child: ReturnPage.fromDelivery(
                                            deliveryDocEntry: docEntry,
                                            visitId: visit.id,
                                          ),
                                        ),
                                  ),
                                );
                                if (!mounted) return;
                                _loadVisitsForCurrentTab();
                              },
                              onCreateIncomingPayment: () {
                                Navigator.of(context)
                                    .push<void>(
                                      MaterialPageRoute<void>(
                                        builder:
                                            (_) => IncomingPaymentCreatePage(
                                              visitId: visit.id,
                                              initialCardCode:
                                                  visit.customerCode ??
                                                  visit.customerId,
                                              initialCustomerName:
                                                  visit.customerName,
                                            ),
                                      ),
                                    )
                                    .then((_) {
                                      if (!mounted) return;
                                      _loadVisitsForCurrentTab();
                                    });
                              },
                              onSurvey: () {
                                Navigator.of(context)
                                    .push<void>(
                                      MaterialPageRoute<void>(
                                        builder:
                                            (_) => VisitSurveyListPage(
                                              visitId: visit.id,
                                            ),
                                      ),
                                    )
                                    .then((_) {
                                      if (!mounted) return;
                                      _loadVisitsForCurrentTab();
                                    });
                              },
                            ),
                          ),
                        ];
                      }),
                      if (state.isLoadingMoreVisits)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ],
            // Create form: only in bottom sheet (not on full page)
            if (widget.onRefreshVisits == null) ...[
              Text(
                l10n.createStandaloneVisit,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              // Customer: title left, Create customer button right
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.selectCustomer,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.createCustomerCubit != null)
                    OutlinedButton.icon(
                      onPressed: _openCreateCustomer,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.createCustomer),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showCustomerDialog,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
                    buildWhen:
                        (prev, curr) =>
                            prev.selectedCustomer != curr.selectedCustomer,
                    builder: (context, state) {
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
                              state.selectedCustomer?.name ??
                                  l10n.selectCustomer,
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    state.selectedCustomer != null
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Planned date & time (single field)
              _DateField(
                label: l10n.plannedDateAndTime,
                date: _plannedDateTime,
                onDateSelected: (d) => setState(() => _plannedDateTime = d),
              ),
              const SizedBox(height: 12),
              // Duration
              Text(
                l10n.estimatedDurationMinutes,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 14),
                onChanged: (_) => setState(() {}),
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
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Google Maps Link (Optional) - same as journey plan
              Text(
                l10n.standaloneGoogleMapsLinkOptional,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _googleMapsLinkController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: l10n.standaloneGoogleMapsHintAuto,
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
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _getCurrentLocation(context),
                    icon: const Icon(
                      Icons.my_location,
                      color: AppColors.primary,
                    ),
                    tooltip: l10n.tooltipGetCurrentLocation,
                  ),
                  IconButton(
                    onPressed: () => _openGoogleMaps(context),
                    icon: const Icon(Icons.map, color: AppColors.primary),
                    tooltip: l10n.tooltipOpenMapsSelectLocation,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.standaloneMapsLocationTip,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
                buildWhen: (prev, curr) => prev.isLoading != curr.isLoading,
                builder: (context, state) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                                l10n.createStandaloneVisit,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StandaloneVisitTabs extends StatelessWidget {
  const _StandaloneVisitTabs({
    required this.l10n,
    required this.tabIndex,
    required this.onTabChanged,
  });

  final AppLocalizations l10n;
  final int tabIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabChip(
            label: l10n.standaloneVisitHistoryTab,
            isSelected: tabIndex == 0,
            onTap: () => onTabChanged(0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TabChip(
            label: l10n.standaloneVisitCurrentTab,
            isSelected: tabIndex == 1,
            onTap: () => onTabChanged(1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TabChip(
            label: l10n.standaloneVisitFutureTab,
            isSelected: tabIndex == 2,
            onTap: () => onTabChanged(2),
          ),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color:
                isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.surface,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    this.date,
    required this.onDateSelected,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final last = now.add(const Duration(days: 365));
    final initial = date ?? now;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: now,
              lastDate: last,
            );
            if (d != null) {
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(date ?? now),
              );
              if (t != null) {
                onDateSelected(
                  DateTime(d.year, d.month, d.day, t.hour, t.minute),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  date != null
                      ? DateFormat.yMMMd().add_Hm().format(date!)
                      : label,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        date != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer, required this.onTap});

  final Customer customer;
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
                    customer.name,
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
                  if (customer.distinctForeignNameLine != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      customer.distinctForeignNameLine!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (customer.customerCode.isNotEmpty)
                    Text(
                      customer.customerCode,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
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
