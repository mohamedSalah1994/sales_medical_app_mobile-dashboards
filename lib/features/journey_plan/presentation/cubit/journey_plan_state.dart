import 'package:equatable/equatable.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/subordinate_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/supervisor_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/customer.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/journey_plan.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit.dart';

class JourneyPlanState extends Equatable {
  final int currentStep;
  final int planType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String notes;
  final JourneyPlan? journeyPlan;
  final bool isLoading;
  final String? errorMessage;
  final List<Customer> customers;
  final bool isLoadingCustomers;
  final String? customersErrorMessage;
  final Customer? selectedCustomer;
  final List<JourneyPlan> journeyPlans;
  final bool isLoadingJourneyPlans;
  final String? journeyPlansErrorMessage;
  final bool showCreateForm;
  final String? filterUserId;
  final String? filterSupervisorId;
  final String? filterCustomerId;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final List<SubordinateModel> subordinates;
  final bool isLoadingSubordinates;
  final String? subordinatesErrorMessage;
  final bool createForMyself;
  final SubordinateModel? selectedSubordinate;
  final bool isEditing;
  final String? editingJourneyPlanId;
  final bool
  isViewOnly; // If true, supervisor can only view and assign, not edit
  final int
  selectedTabIndex; // 0 = My Journeys/My Visits, 1 = Assigned Journeys
  final List<Visit> visits;
  final bool isLoadingVisits;
  final bool isLoadingMoreVisits;
  final String? visitsErrorMessage;
  final int visitsPageNumber;
  final int visitsTotalPages;
  final bool visitsHasNextPage;
  final int?
  visitStatusFilter; // 1 = Planned/Not Started, 3 = Completed, null = All
  /// Sales rep journey list segment: `'past'` (ended), `'current'`, `'future'`.
  final String? planViewFilter;
  final List<SupervisorModel> supervisors;
  final bool isLoadingSupervisors;
  final String? supervisorsErrorMessage;
  final bool isOffline;
  final int pendingSyncCount;
  /// True while syncing pending actions after coming back online.
  final bool isSyncing;
  final String? loggedInUserId;
  /// Elapsed seconds at pause time (visitId -> seconds) so the counter stops when visit is paused.
  final Map<String, int> pausedVisitElapsedSeconds;
  /// When pause was pressed (visitId -> ms since epoch) so we can add pause duration on resume.
  final Map<String, int> pauseStartTimestampMs;
  /// Total seconds this visit has been paused so far; subtracted from elapsed so counter continues from pre-pause.
  final Map<String, int> totalPausedDurationSeconds;
  /// Original visit start time (visitId -> ms since epoch) restored when API/cache objects miss `actualStartDateTime`.
  final Map<String, int> actualStartTimestampMs;
  /// Running elapsed seconds captured when app backgrounds/closes (visitId -> seconds).
  final Map<String, int> activeVisitElapsedSeconds;
  /// When running elapsed was captured (visitId -> ms since epoch).
  final Map<String, int> activeVisitSnapshotTimestampMs;
  /// Final elapsed seconds after checkout (visitId -> seconds), for card display.
  final Map<String, int> endedVisitElapsedSeconds;
  /// Visit id to scroll to after opening the journey plan editor.
  final String? pendingScrollToVisitId;
  /// When set (e.g. from global visit banner), [HomePage] switches to this bottom-nav index then clears.
  final int? pendingHomeTabIndex;

  /// 0 = History, 1 = Current (today), 2 = Future — kept in sync with standalone UI for background refresh.
  final int standaloneVisitsTabIndex;

  /// True after [JourneyPlanCubit.loadVisits] with `standaloneOnly: true` so ERP callbacks can reload that list.
  final bool lastVisitsLoadWasStandaloneOnly;

  const JourneyPlanState({
    required this.currentStep,
    required this.planType,
    this.startDate,
    this.endDate,
    required this.notes,
    this.journeyPlan,
    required this.isLoading,
    this.errorMessage,
    required this.customers,
    required this.isLoadingCustomers,
    this.customersErrorMessage,
    this.selectedCustomer,
    required this.journeyPlans,
    required this.isLoadingJourneyPlans,
    this.journeyPlansErrorMessage,
    required this.showCreateForm,
    this.filterUserId,
    this.filterSupervisorId,
    this.filterCustomerId,
    this.filterStartDate,
    this.filterEndDate,
    required this.subordinates,
    required this.isLoadingSubordinates,
    this.subordinatesErrorMessage,
    required this.createForMyself,
    this.selectedSubordinate,
    required this.isEditing,
    this.editingJourneyPlanId,
    required this.isViewOnly,
    this.selectedTabIndex = 0,
    required this.visits,
    required this.isLoadingVisits,
    this.isLoadingMoreVisits = false,
    this.visitsErrorMessage,
    this.visitsPageNumber = 1,
    this.visitsTotalPages = 0,
    this.visitsHasNextPage = false,
    this.visitStatusFilter = 1, // Default to Planned/Not Started
    this.planViewFilter = 'current', // Default to Current for Sales Employee
    required this.supervisors,
    required this.isLoadingSupervisors,
    this.supervisorsErrorMessage,
    this.isOffline = false,
    this.pendingSyncCount = 0,
    this.isSyncing = false,
    this.loggedInUserId,
    this.pausedVisitElapsedSeconds = const {},
    this.pauseStartTimestampMs = const {},
    this.totalPausedDurationSeconds = const {},
    this.actualStartTimestampMs = const {},
    this.activeVisitElapsedSeconds = const {},
    this.activeVisitSnapshotTimestampMs = const {},
    this.endedVisitElapsedSeconds = const {},
    this.pendingScrollToVisitId,
    this.pendingHomeTabIndex,
    this.standaloneVisitsTabIndex = 1,
    this.lastVisitsLoadWasStandaloneOnly = false,
  });

  factory JourneyPlanState.initial() {
    return const JourneyPlanState(
      currentStep: 1,
      planType: 1,
      notes: '',
      isLoading: false,
      customers: [],
      isLoadingCustomers: false,
      journeyPlans: [],
      isLoadingJourneyPlans: false,
      showCreateForm: false,
      filterUserId: null,
      filterSupervisorId: null,
      filterCustomerId: null,
      filterStartDate: null,
      filterEndDate: null,
      subordinates: [],
      isLoadingSubordinates: false,
      createForMyself: true,
      selectedSubordinate: null,
      isEditing: false,
      editingJourneyPlanId: null,
      isViewOnly: false,
      selectedTabIndex: 0,
      visits: [],
      isLoadingVisits: false,
      isLoadingMoreVisits: false,
      visitsErrorMessage: null,
      visitsPageNumber: 1,
      visitsTotalPages: 0,
      visitsHasNextPage: false,
      visitStatusFilter: 1, // Default to Planned/Not Started
      planViewFilter: 'current', // Default to Current for Sales Employee
      supervisors: [],
      isLoadingSupervisors: false,
      supervisorsErrorMessage: null,
      isOffline: false,
      pendingSyncCount: 0,
      isSyncing: false,
      loggedInUserId: null,
      pausedVisitElapsedSeconds: const {},
      pauseStartTimestampMs: const {},
      totalPausedDurationSeconds: const {},
      actualStartTimestampMs: const {},
      activeVisitElapsedSeconds: const {},
      activeVisitSnapshotTimestampMs: const {},
      endedVisitElapsedSeconds: const {},
      pendingScrollToVisitId: null,
      pendingHomeTabIndex: null,
      standaloneVisitsTabIndex: 1,
      lastVisitsLoadWasStandaloneOnly: false,
    );
  }

  JourneyPlanState copyWith({
    int? currentStep,
    int? planType,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    JourneyPlan? journeyPlan,
    bool? isLoading,
    String? errorMessage,
    List<Customer>? customers,
    bool? isLoadingCustomers,
    String? customersErrorMessage,
    Customer? selectedCustomer,
    List<JourneyPlan>? journeyPlans,
    bool? isLoadingJourneyPlans,
    String? journeyPlansErrorMessage,
    bool? showCreateForm,
    String? filterUserId,
    String? filterSupervisorId,
    String? filterCustomerId,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
    bool clearFilters = false,
    bool clearFilterUserId = false,
    bool clearError = false,
    bool clearJourneyPlansError = false,
    bool clearSupervisorsError = false,
    bool clearSelectedCustomer = false,
    bool clearJourneyPlan = false,
    List<SubordinateModel>? subordinates,
    bool? isLoadingSubordinates,
    String? subordinatesErrorMessage,
    bool? createForMyself,
    SubordinateModel? selectedSubordinate,
    bool? isEditing,
    String? editingJourneyPlanId,
    bool? isViewOnly,
    int? selectedTabIndex,
    List<Visit>? visits,
    bool? isLoadingVisits,
    bool? isLoadingMoreVisits,
    String? visitsErrorMessage,
    int? visitsPageNumber,
    int? visitsTotalPages,
    bool? visitsHasNextPage,
    int? visitStatusFilter,
    String? planViewFilter,
    List<SupervisorModel>? supervisors,
    bool? isLoadingSupervisors,
    String? supervisorsErrorMessage,
    bool? isOffline,
    int? pendingSyncCount,
    bool? isSyncing,
    String? loggedInUserId,
    Map<String, int>? pausedVisitElapsedSeconds,
    Map<String, int>? pauseStartTimestampMs,
    Map<String, int>? totalPausedDurationSeconds,
    Map<String, int>? actualStartTimestampMs,
    Map<String, int>? activeVisitElapsedSeconds,
    Map<String, int>? activeVisitSnapshotTimestampMs,
    Map<String, int>? endedVisitElapsedSeconds,
    String? pendingScrollToVisitId,
    bool clearPendingScrollToVisitId = false,
    int? pendingHomeTabIndex,
    bool clearPendingHomeTab = false,
    int? standaloneVisitsTabIndex,
    bool? lastVisitsLoadWasStandaloneOnly,
  }) {
    return JourneyPlanState(
      currentStep: currentStep ?? this.currentStep,
      planType: planType ?? this.planType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      journeyPlan:
          clearJourneyPlan ? null : (journeyPlan ?? this.journeyPlan),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      customers: customers ?? this.customers,
      isLoadingCustomers: isLoadingCustomers ?? this.isLoadingCustomers,
      customersErrorMessage:
          customersErrorMessage ?? this.customersErrorMessage,
      selectedCustomer:
          clearSelectedCustomer
              ? null
              : (selectedCustomer ?? this.selectedCustomer),
      journeyPlans: journeyPlans ?? this.journeyPlans,
      isLoadingJourneyPlans:
          isLoadingJourneyPlans ?? this.isLoadingJourneyPlans,
      journeyPlansErrorMessage:
          clearJourneyPlansError
              ? null
              : (journeyPlansErrorMessage ?? this.journeyPlansErrorMessage),
      showCreateForm: showCreateForm ?? this.showCreateForm,
      filterUserId:
          (clearFilters || clearFilterUserId)
              ? null
              : (filterUserId ?? this.filterUserId),
      filterSupervisorId:
          clearFilters ? null : (filterSupervisorId ?? this.filterSupervisorId),
      filterCustomerId:
          clearFilters ? null : (filterCustomerId ?? this.filterCustomerId),
      filterStartDate:
          clearFilters ? null : (filterStartDate ?? this.filterStartDate),
      filterEndDate:
          clearFilters ? null : (filterEndDate ?? this.filterEndDate),
      subordinates: subordinates ?? this.subordinates,
      isLoadingSubordinates:
          isLoadingSubordinates ?? this.isLoadingSubordinates,
      subordinatesErrorMessage:
          subordinatesErrorMessage ?? this.subordinatesErrorMessage,
      createForMyself: createForMyself ?? this.createForMyself,
      selectedSubordinate: selectedSubordinate ?? this.selectedSubordinate,
      isEditing: isEditing ?? this.isEditing,
      editingJourneyPlanId: editingJourneyPlanId ?? this.editingJourneyPlanId,
      isViewOnly: isViewOnly ?? this.isViewOnly,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      visits: visits ?? this.visits,
      isLoadingVisits: isLoadingVisits ?? this.isLoadingVisits,
      isLoadingMoreVisits: isLoadingMoreVisits ?? this.isLoadingMoreVisits,
      visitsErrorMessage: visitsErrorMessage ?? this.visitsErrorMessage,
      visitsPageNumber: visitsPageNumber ?? this.visitsPageNumber,
      visitsTotalPages: visitsTotalPages ?? this.visitsTotalPages,
      visitsHasNextPage: visitsHasNextPage ?? this.visitsHasNextPage,
      visitStatusFilter: visitStatusFilter ?? this.visitStatusFilter,
      planViewFilter: planViewFilter ?? this.planViewFilter,
      supervisors: supervisors ?? this.supervisors,
      isLoadingSupervisors: isLoadingSupervisors ?? this.isLoadingSupervisors,
      supervisorsErrorMessage:
          clearSupervisorsError
              ? null
              : (supervisorsErrorMessage ?? this.supervisorsErrorMessage),
      isOffline: isOffline ?? this.isOffline,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      isSyncing: isSyncing ?? this.isSyncing,
      loggedInUserId: loggedInUserId ?? this.loggedInUserId,
      pausedVisitElapsedSeconds:
          pausedVisitElapsedSeconds ?? this.pausedVisitElapsedSeconds,
      pauseStartTimestampMs:
          pauseStartTimestampMs ?? this.pauseStartTimestampMs,
      totalPausedDurationSeconds:
          totalPausedDurationSeconds ?? this.totalPausedDurationSeconds,
      actualStartTimestampMs:
          actualStartTimestampMs ?? this.actualStartTimestampMs,
      activeVisitElapsedSeconds:
          activeVisitElapsedSeconds ?? this.activeVisitElapsedSeconds,
      activeVisitSnapshotTimestampMs:
          activeVisitSnapshotTimestampMs ?? this.activeVisitSnapshotTimestampMs,
      endedVisitElapsedSeconds:
          endedVisitElapsedSeconds ?? this.endedVisitElapsedSeconds,
      pendingScrollToVisitId:
          clearPendingScrollToVisitId
              ? null
              : (pendingScrollToVisitId ?? this.pendingScrollToVisitId),
      pendingHomeTabIndex:
          clearPendingHomeTab
              ? null
              : (pendingHomeTabIndex ?? this.pendingHomeTabIndex),
      standaloneVisitsTabIndex:
          standaloneVisitsTabIndex ?? this.standaloneVisitsTabIndex,
      lastVisitsLoadWasStandaloneOnly:
          lastVisitsLoadWasStandaloneOnly ??
          this.lastVisitsLoadWasStandaloneOnly,
    );
  }

  bool get hasActiveFilters =>
      filterUserId != null ||
      filterSupervisorId != null ||
      filterCustomerId != null ||
      filterStartDate != null ||
      filterEndDate != null;

  @override
  List<Object?> get props => [
    currentStep,
    planType,
    startDate,
    endDate,
    notes,
    journeyPlan,
    isLoading,
    errorMessage,
    customers,
    isLoadingCustomers,
    customersErrorMessage,
    selectedCustomer,
    journeyPlans,
    isLoadingJourneyPlans,
    journeyPlansErrorMessage,
    showCreateForm,
    filterUserId,
    filterSupervisorId,
    filterCustomerId,
    filterStartDate,
    filterEndDate,
    subordinates,
    isLoadingSubordinates,
    subordinatesErrorMessage,
    createForMyself,
    selectedSubordinate,
    isEditing,
    editingJourneyPlanId,
    isViewOnly,
    selectedTabIndex,
    visits,
    isLoadingVisits,
    isLoadingMoreVisits,
    visitsErrorMessage,
    visitsPageNumber,
    visitsTotalPages,
    visitsHasNextPage,
    visitStatusFilter,
    planViewFilter,
    supervisors,
    isLoadingSupervisors,
    supervisorsErrorMessage,
    isOffline,
    pendingSyncCount,
    isSyncing,
    loggedInUserId,
    pausedVisitElapsedSeconds,
    pauseStartTimestampMs,
    totalPausedDurationSeconds,
    actualStartTimestampMs,
    activeVisitElapsedSeconds,
    activeVisitSnapshotTimestampMs,
    endedVisitElapsedSeconds,
    pendingScrollToVisitId,
    pendingHomeTabIndex,
    standaloneVisitsTabIndex,
    lastVisitsLoadWasStandaloneOnly,
  ];
}
