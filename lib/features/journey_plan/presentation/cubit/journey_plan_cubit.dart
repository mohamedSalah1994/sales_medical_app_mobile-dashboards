import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/core/error/error_message_helper.dart';
import 'package:sales_medical_app_mobile/core/network/connectivity_service.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/datasources/journey_plan_local_data_source.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/create_stop_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/create_bulk_visits_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/create_visit_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/update_stop_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/update_visit_supervisor_and_type_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/update_visit_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/journey_plan_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/stop_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/visit_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/subordinate_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/customer.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/journey_plan.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/utils/visit_elapsed_seconds.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/utils/visit_execution_status.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/create_journey_plan_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/create_bulk_visits_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/create_stop_and_visit_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/create_visit_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/delete_journey_plan_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/get_customers_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/get_journey_plan_by_id_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/get_journey_plans_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/get_subordinates_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/get_supervisors_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/get_visits_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/update_journey_plan_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/update_stop_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/update_visit_supervisor_and_type_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/update_visit_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/start_visit_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/check_in_visit_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/check_out_visit_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/pause_visit_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/resume_visit_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/delete_visit_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/post_visit_action_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/check_in_visit_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/check_out_visit_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/supervisor_attendance_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_state.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/supervisor_attendance_usecase.dart';

class JourneyPlanCubit extends Cubit<JourneyPlanState> {
  JourneyPlanCubit({
    required this.createJourneyPlanUseCase,
    required this.updateJourneyPlanUseCase,
    required this.getJourneyPlanByIdUseCase,
    required this.createBulkVisitsUseCase,
    required this.createStopAndVisitUseCase,
    required this.createVisitUseCase,
    required this.updateStopUseCase,
    required this.getCustomersUseCase,
    required this.getJourneyPlansUseCase,
    required this.getSubordinatesUseCase,
    required this.getSupervisorsUseCase,
    required this.deleteJourneyPlanUseCase,
    required this.updateVisitSupervisorAndTypeUseCase,
    required this.updateVisitUseCase,
    required this.getVisitsUseCase,
    required this.startVisitUseCase,
    required this.checkInVisitUseCase,
    required this.checkOutVisitUseCase,
    required this.pauseVisitUseCase,
    required this.resumeVisitUseCase,
    required this.supervisorAttendanceUseCase,
    required this.deleteVisitUseCase,
    required this.postVisitActionUseCase,
    required this.connectivityService,
    required this.localDataSource,
  }) : super(JourneyPlanState.initial()) {
    _initConnectivity();
    _restoreVisitTimingState().then((_) => _restoreCachedActiveVisitContext());
  }

  final CreateJourneyPlanUseCase createJourneyPlanUseCase;
  final UpdateJourneyPlanUseCase updateJourneyPlanUseCase;
  final GetJourneyPlanByIdUseCase getJourneyPlanByIdUseCase;
  final CreateBulkVisitsUseCase createBulkVisitsUseCase;
  final CreateStopAndVisitUseCase createStopAndVisitUseCase;
  final CreateVisitUseCase createVisitUseCase;
  final UpdateStopUseCase updateStopUseCase;
  final GetCustomersUseCase getCustomersUseCase;
  final GetJourneyPlansUseCase getJourneyPlansUseCase;
  final GetSubordinatesUseCase getSubordinatesUseCase;
  final GetSupervisorsUseCase getSupervisorsUseCase;
  final DeleteJourneyPlanUseCase deleteJourneyPlanUseCase;
  final UpdateVisitSupervisorAndTypeUseCase updateVisitSupervisorAndTypeUseCase;
  final UpdateVisitUseCase updateVisitUseCase;
  final GetVisitsUseCase getVisitsUseCase;
  final StartVisitUseCase startVisitUseCase;
  final CheckInVisitUseCase checkInVisitUseCase;
  final CheckOutVisitUseCase checkOutVisitUseCase;
  final PauseVisitUseCase pauseVisitUseCase;
  final ResumeVisitUseCase resumeVisitUseCase;
  final SupervisorAttendanceUseCase supervisorAttendanceUseCase;
  final DeleteVisitUseCase deleteVisitUseCase;
  final PostVisitActionUseCase postVisitActionUseCase;
  final ConnectivityService connectivityService;
  final JourneyPlanLocalDataSource localDataSource;

  StreamSubscription<bool>? _connectivitySubscription;

  Future<void> _restoreCachedActiveVisitContext() async {
    final timingState = await localDataSource.getVisitTimingState();
    final actualStartTimestampMs =
        (timingState['actualStartTimestampMs'] as Map<String, int>?) ??
        const <String, int>{};
    final endedVisitElapsedSeconds =
        (timingState['endedVisitElapsedSeconds'] as Map<String, int>?) ??
        const <String, int>{};
    final cachedVisits = await localDataSource.getCachedVisits();
    final cachedCurrentPlan = await localDataSource.getCachedCurrentPlan();
    if (isClosed) return;

    final hydratedCachedVisits =
        cachedVisits
            .map(
              (visit) => _hydrateVisitFromLocalTiming(
                _hydrateVisitWithStoredStart(visit, actualStartTimestampMs),
                endedVisitElapsedSeconds: endedVisitElapsedSeconds,
              ),
            )
            .toList();
    final hydratedCurrentPlan =
        cachedCurrentPlan == null
            ? null
            : _hydrateJourneyPlanFromLocalTiming(
              JourneyPlanModel(
                id: cachedCurrentPlan.id,
                userId: cachedCurrentPlan.userId,
                userName: cachedCurrentPlan.userName,
                createdByUserId: cachedCurrentPlan.createdByUserId,
                createdByUserName: cachedCurrentPlan.createdByUserName,
                createdBy: cachedCurrentPlan.createdBy,
                planType: cachedCurrentPlan.planType,
                startDate: cachedCurrentPlan.startDate,
                endDate: cachedCurrentPlan.endDate,
                notes: cachedCurrentPlan.notes,
                isApproved: cachedCurrentPlan.isApproved,
                approvedAt: cachedCurrentPlan.approvedAt,
                stops:
                    cachedCurrentPlan.stops.map((stop) {
                      final visit = stop.visit;
                      return StopModel(
                        id: stop.id,
                        visitId: stop.visitId,
                        sequenceNo: stop.sequenceNo,
                        plannedTime: stop.plannedTime,
                        estimatedDurationMinutes: stop.estimatedDurationMinutes,
                        visit:
                            visit == null
                                ? null
                                : _hydrateVisitWithStoredStart(
                                  visit,
                                  actualStartTimestampMs,
                                ),
                      );
                    }).toList(),
                createdAt: cachedCurrentPlan.createdAt,
              ),
              endedVisitElapsedSeconds: endedVisitElapsedSeconds,
            );

    final mergedVisits = _mergeKeepingActiveVisits(
      hydratedCachedVisits,
      hydratedCurrentPlan?.stops.map((s) => s.visit).whereType<Visit>() ??
          const <Visit>[],
    );

    if (mergedVisits.isEmpty && hydratedCurrentPlan == null) return;

    emit(
      state.copyWith(
        visits: mergedVisits,
        journeyPlan: hydratedCurrentPlan ?? state.journeyPlan,
        actualStartTimestampMs: actualStartTimestampMs,
      ),
    );
  }

  Future<void> _restoreVisitTimingState() async {
    final timingState = await localDataSource.getVisitTimingState();
    if (isClosed) return;
    emit(
      state.copyWith(
        pausedVisitElapsedSeconds:
            (timingState['pausedVisitElapsedSeconds'] as Map<String, int>?) ??
            const {},
        pauseStartTimestampMs:
            (timingState['pauseStartTimestampMs'] as Map<String, int>?) ??
            const {},
        totalPausedDurationSeconds:
            (timingState['totalPausedDurationSeconds'] as Map<String, int>?) ??
            const {},
        actualStartTimestampMs:
            (timingState['actualStartTimestampMs'] as Map<String, int>?) ??
            const {},
        activeVisitElapsedSeconds:
            (timingState['activeVisitElapsedSeconds'] as Map<String, int>?) ??
            const {},
        activeVisitSnapshotTimestampMs:
            (timingState['activeVisitSnapshotTimestampMs']
                as Map<String, int>?) ??
            const {},
        endedVisitElapsedSeconds:
            (timingState['endedVisitElapsedSeconds'] as Map<String, int>?) ??
            const {},
      ),
    );
    _rehydratePlansAfterTimingRestore();
  }

  void _rehydratePlansAfterTimingRestore() {
    if (isClosed) return;
    final currentPlan = state.journeyPlan;
    final plans = state.journeyPlans;
    if (currentPlan == null && plans.isEmpty) return;
    emit(
      state.copyWith(
        journeyPlan:
            currentPlan == null
                ? null
                : _hydrateJourneyPlanFromLocalTiming(
                  currentPlan as JourneyPlanModel,
                ),
        journeyPlans:
            plans.isEmpty ? plans : _hydrateJourneyPlansFromLocalTiming(plans),
      ),
    );
  }

  Future<void> _persistVisitTimingState({
    Map<String, int>? pausedVisitElapsedSeconds,
    Map<String, int>? pauseStartTimestampMs,
    Map<String, int>? totalPausedDurationSeconds,
    Map<String, int>? actualStartTimestampMs,
    Map<String, int>? activeVisitElapsedSeconds,
    Map<String, int>? activeVisitSnapshotTimestampMs,
    Map<String, int>? endedVisitElapsedSeconds,
  }) {
    return localDataSource.saveVisitTimingState(
      pausedVisitElapsedSeconds:
          pausedVisitElapsedSeconds ?? state.pausedVisitElapsedSeconds,
      pauseStartTimestampMs:
          pauseStartTimestampMs ?? state.pauseStartTimestampMs,
      totalPausedDurationSeconds:
          totalPausedDurationSeconds ?? state.totalPausedDurationSeconds,
      actualStartTimestampMs:
          actualStartTimestampMs ?? state.actualStartTimestampMs,
      activeVisitElapsedSeconds:
          activeVisitElapsedSeconds ?? state.activeVisitElapsedSeconds,
      activeVisitSnapshotTimestampMs:
          activeVisitSnapshotTimestampMs ??
          state.activeVisitSnapshotTimestampMs,
      endedVisitElapsedSeconds:
          endedVisitElapsedSeconds ?? state.endedVisitElapsedSeconds,
    );
  }

  ({
    Map<String, int> actualStartTimestampMs,
    Map<String, int> activeVisitElapsedSeconds,
    Map<String, int> activeVisitSnapshotTimestampMs,
    Map<String, int> endedVisitElapsedSeconds,
  })
  _timingMapsForCheckIn(String visitId, DateTime now) {
    final actualStart = Map<String, int>.from(state.actualStartTimestampMs);
    final activeElapsed = Map<String, int>.from(
      state.activeVisitElapsedSeconds,
    );
    final activeSnapshot = Map<String, int>.from(
      state.activeVisitSnapshotTimestampMs,
    );
    final ended = Map<String, int>.from(state.endedVisitElapsedSeconds)
      ..remove(visitId);
    actualStart[visitId] = now.millisecondsSinceEpoch;
    activeElapsed[visitId] = 0;
    activeSnapshot[visitId] = now.millisecondsSinceEpoch;
    return (
      actualStartTimestampMs: actualStart,
      activeVisitElapsedSeconds: activeElapsed,
      activeVisitSnapshotTimestampMs: activeSnapshot,
      endedVisitElapsedSeconds: ended,
    );
  }

  ({
    Map<String, int> pausedVisitElapsedSeconds,
    Map<String, int> pauseStartTimestampMs,
    Map<String, int> totalPausedDurationSeconds,
    Map<String, int> actualStartTimestampMs,
    Map<String, int> activeVisitElapsedSeconds,
    Map<String, int> activeVisitSnapshotTimestampMs,
    Map<String, int> endedVisitElapsedSeconds,
  })
  _timingMapsForCheckOut(String visitId, int durationSeconds) {
    final paused = Map<String, int>.from(state.pausedVisitElapsedSeconds)
      ..remove(visitId);
    final pauseStart = Map<String, int>.from(state.pauseStartTimestampMs)
      ..remove(visitId);
    final totalPaused = Map<String, int>.from(state.totalPausedDurationSeconds)
      ..remove(visitId);
    final actualStart = Map<String, int>.from(state.actualStartTimestampMs)
      ..remove(visitId);
    final activeElapsed = Map<String, int>.from(state.activeVisitElapsedSeconds)
      ..remove(visitId);
    final activeSnapshot = Map<String, int>.from(
      state.activeVisitSnapshotTimestampMs,
    )..remove(visitId);
    final ended = Map<String, int>.from(state.endedVisitElapsedSeconds);
    ended[visitId] = durationSeconds;
    return (
      pausedVisitElapsedSeconds: paused,
      pauseStartTimestampMs: pauseStart,
      totalPausedDurationSeconds: totalPaused,
      actualStartTimestampMs: actualStart,
      activeVisitElapsedSeconds: activeElapsed,
      activeVisitSnapshotTimestampMs: activeSnapshot,
      endedVisitElapsedSeconds: ended,
    );
  }

  void _initConnectivity() {
    connectivityService.isOnline.then((online) {
      if (!isClosed) emit(state.copyWith(isOffline: !online));
    });
    _connectivitySubscription = connectivityService.onConnectivityChanged
        .listen((online) async {
          if (!isClosed) emit(state.copyWith(isOffline: !online));
          if (online) {
            final pending = await localDataSource.getPendingVisitActions();
            if (pending.isNotEmpty && !isClosed) {
              emit(state.copyWith(isSyncing: true));
            }
            try {
              await _syncPendingActions();
            } finally {
              if (!isClosed) emit(state.copyWith(isSyncing: false));
            }
          }
        });
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }

  Future<void> _syncPendingActions() async {
    if (isClosed) return;
    final pending = await localDataSource.getPendingVisitActions();
    if (pending.isEmpty) return;
    for (final action in pending) {
      try {
        switch (action.action) {
          case 'checkIn':
            await checkInVisitUseCase(
              CheckInVisitParams(
                visitId: action.visitId,
                request: CheckInVisitRequestModel(
                  latitude: action.latitude,
                  longitude: action.longitude,
                ),
              ),
            );
            break;
          case 'checkOut':
            await checkOutVisitUseCase(
              CheckOutVisitParams(
                visitId: action.visitId,
                request: CheckOutVisitRequestModel(
                  latitude: action.latitude,
                  longitude: action.longitude,
                  actualDurationSeconds: action.actualDurationSeconds,
                  actualDuration: action.actualDuration,
                ),
              ),
            );
            break;
          case 'pause':
            await pauseVisitUseCase(action.visitId);
            break;
          case 'resume':
            await resumeVisitUseCase(action.visitId);
            break;
        }
      } catch (_) {
        break;
      }
    }
    await localDataSource.clearPendingVisitActions();
    // Reload for the logged-in user only, not other users (e.g. admin viewing another supervisor)
    final loggedInUserId = state.loggedInUserId;
    if (!isClosed) {
      emit(
        state.copyWith(
          pendingSyncCount: 0,
          isSyncing: false,
          filterUserId: loggedInUserId,
          filterSupervisorId: null,
        ),
      );
    }
    await loadJourneyPlans();
    await loadVisits(userId: loggedInUserId);
  }

  void setLoggedInUserId(String? userId) {
    if (isClosed) return;
    emit(state.copyWith(loggedInUserId: userId));
  }

  List<Visit> _replaceVisitInVisitsList(
    List<Visit> visits,
    String visitId,
    VisitModel updatedVisit,
  ) {
    final i = visits.indexWhere((v) => v.id == visitId);
    final copy = List<Visit>.from(visits);
    if (i < 0) {
      copy.insert(0, updatedVisit);
    } else {
      copy[i] = updatedVisit;
    }
    return copy;
  }

  bool _isActiveOngoingVisit(Visit visit) {
    final endedMap = state.endedVisitElapsedSeconds;
    if (VisitExecutionStatus.isVisitEnded(
      visit,
      endedVisitElapsedSeconds: endedMap,
    )) {
      return false;
    }
    if (VisitExecutionStatus.isVisitCancelled(
          visit,
          endedVisitElapsedSeconds: endedMap,
        ) ||
        VisitExecutionStatus.isVisitNoShow(visit)) {
      return false;
    }
    if (VisitExecutionStatus.isVisitPausedFromTiming(
      visit,
      pausedVisitElapsedSeconds: state.pausedVisitElapsedSeconds,
      pauseStartTimestampMs: state.pauseStartTimestampMs,
      endedVisitElapsedSeconds: endedMap,
    )) {
      return true;
    }
    if (visit.actualStartDateTime != null) {
      return visit.status == VisitExecutionStatus.inProgress ||
          visit.status == null;
    }
    return state.actualStartTimestampMs.containsKey(visit.id);
  }

  /// Active visits from standalone list and current journey plan stops.
  Iterable<Visit> _activeOngoingVisitsInState() sync* {
    final seen = <String>{};
    for (final visit in state.visits) {
      final hydrated = _hydrateVisitWithStoredStart(
        visit,
        state.actualStartTimestampMs,
      );
      if (_isActiveOngoingVisit(hydrated)) {
        seen.add(hydrated.id);
        yield hydrated;
      }
    }
    final plan = state.journeyPlan;
    if (plan == null) return;
    for (final stop in plan.stops) {
      final visit = stop.visit;
      if (visit == null || seen.contains(visit.id)) continue;
      final hydrated = _hydrateVisitWithStoredStart(
        visit,
        state.actualStartTimestampMs,
      );
      if (_isActiveOngoingVisit(hydrated)) {
        seen.add(hydrated.id);
        yield hydrated;
      }
    }
  }

  List<Visit> _mergeActiveOngoingVisitsIntoList(List<Visit> visits) {
    var merged = List<Visit>.from(visits);
    for (final active in _activeOngoingVisitsInState()) {
      merged = _replaceVisitInVisitsList(
        merged,
        active.id,
        active as VisitModel,
      );
    }
    return merged;
  }

  /// Merges [primary] (fresh API or cache) with in-flight [candidates] (e.g. ongoing visit).
  ///
  /// Previously we always replaced the API row with the local active visit, which kept
  /// **stale [Visit.actions]** after ERP flows even when [registerVisitActionIfInJourneyContext]
  /// re-fetched the list. We now keep server actions when they are at least as complete,
  /// while still preserving local `actualStartDateTime` when the API row omits it.
  List<Visit> _mergeKeepingActiveVisits(
    List<Visit> primary,
    Iterable<Visit> candidates,
  ) {
    final merged = <String, Visit>{
      for (final visit in primary) visit.id: visit,
    };
    for (final visit in candidates) {
      final existing = merged[visit.id];
      if (existing == null) {
        merged[visit.id] = visit;
        continue;
      }
      if (!_isActiveOngoingVisit(visit)) {
        continue;
      }
      merged[visit.id] = _mergeFreshVisitWithActiveLocal(
        primaryRow: existing,
        localActive: visit,
      );
    }
    return merged.values.toList();
  }

  int? _mergedVisitStatus(Visit primaryRow, Visit localActive) {
    final ended =
        VisitExecutionStatus.isVisitEnded(
          primaryRow,
          endedVisitElapsedSeconds: state.endedVisitElapsedSeconds,
        ) ||
        VisitExecutionStatus.isVisitEnded(
          localActive,
          endedVisitElapsedSeconds: state.endedVisitElapsedSeconds,
        );
    if (ended) return VisitExecutionStatus.completed;
    return primaryRow.status ?? localActive.status;
  }

  VisitModel _hydrateVisitFromLocalTiming(
    Visit visit, {
    Map<String, int>? endedVisitElapsedSeconds,
  }) {
    final model = visit is VisitModel ? visit : null;
    if (model == null) return visit as VisitModel;
    final endedMap = endedVisitElapsedSeconds ?? state.endedVisitElapsedSeconds;
    final ended = VisitExecutionStatus.isVisitEnded(
      model,
      endedVisitElapsedSeconds: endedMap,
    );
    if (!ended || model.status == VisitExecutionStatus.completed) {
      return model;
    }
    return VisitModel(
      id: model.id,
      userId: model.userId,
      userName: model.userName,
      loginUsername: model.loginUsername,
      customerId: model.customerId,
      customerName: model.customerName,
      customerCode: model.customerCode,
      journeyPlanId: model.journeyPlanId,
      plannedDateTime: model.plannedDateTime,
      actualStartDateTime: model.actualStartDateTime,
      actualEndDateTime: model.actualEndDateTime,
      visitType: model.visitType,
      status: VisitExecutionStatus.completed,
      supervisorId: model.supervisorId,
      supervisorName: model.supervisorName,
      supervisorCheckInAt: model.supervisorCheckInAt,
      supervisorCheckOutAt: model.supervisorCheckOutAt,
      supervisorCheckInLatitude: model.supervisorCheckInLatitude,
      supervisorCheckInLongitude: model.supervisorCheckInLongitude,
      supervisorCheckOutLatitude: model.supervisorCheckOutLatitude,
      supervisorCheckOutLongitude: model.supervisorCheckOutLongitude,
      checkInLatitude: model.checkInLatitude,
      checkInLongitude: model.checkInLongitude,
      checkOutLatitude: model.checkOutLatitude,
      checkOutLongitude: model.checkOutLongitude,
      notes: model.notes,
      googleMapsLink: model.googleMapsLink,
      createdAt: model.createdAt,
      actions: model.actions,
      customerLocationPoint: model.customerLocationPoint,
      customerUGLink: model.customerUGLink,
    );
  }

  JourneyPlanModel _hydrateJourneyPlanFromLocalTiming(
    JourneyPlanModel plan, {
    Map<String, int>? endedVisitElapsedSeconds,
  }) {
    return JourneyPlanModel(
      id: plan.id,
      userId: plan.userId,
      userName: plan.userName,
      createdByUserId: plan.createdByUserId,
      createdByUserName: plan.createdByUserName,
      createdBy: plan.createdBy,
      planType: plan.planType,
      startDate: plan.startDate,
      endDate: plan.endDate,
      notes: plan.notes,
      isApproved: plan.isApproved,
      approvedAt: plan.approvedAt,
      stops:
          plan.stops.map((stop) {
            final visit = stop.visit;
            return StopModel(
              id: stop.id,
              visitId: stop.visitId,
              sequenceNo: stop.sequenceNo,
              plannedTime: stop.plannedTime,
              estimatedDurationMinutes: stop.estimatedDurationMinutes,
              visit:
                  visit == null
                      ? null
                      : _hydrateVisitFromLocalTiming(
                        visit,
                        endedVisitElapsedSeconds: endedVisitElapsedSeconds,
                      ),
            );
          }).toList(),
      createdAt: plan.createdAt,
    );
  }

  List<JourneyPlanModel> _hydrateJourneyPlansFromLocalTiming(
    List<JourneyPlan> plans, {
    Map<String, int>? endedVisitElapsedSeconds,
  }) {
    return plans
        .map(
          (p) => _hydrateJourneyPlanFromLocalTiming(
            p as JourneyPlanModel,
            endedVisitElapsedSeconds: endedVisitElapsedSeconds,
          ),
        )
        .toList();
  }

  VisitModel _mergeFreshVisitWithActiveLocal({
    required Visit primaryRow,
    required Visit localActive,
  }) {
    final useActions =
        primaryRow.actions.length >= localActive.actions.length
            ? primaryRow.actions
            : localActive.actions;
    return VisitModel(
      id: primaryRow.id,
      userId: primaryRow.userId,
      userName: primaryRow.userName,
      customerId: primaryRow.customerId,
      customerName: primaryRow.customerName,
      customerCode: primaryRow.customerCode,
      journeyPlanId: primaryRow.journeyPlanId,
      plannedDateTime: primaryRow.plannedDateTime,
      actualStartDateTime:
          primaryRow.actualStartDateTime ?? localActive.actualStartDateTime,
      actualEndDateTime:
          primaryRow.actualEndDateTime ?? localActive.actualEndDateTime,
      visitType: primaryRow.visitType,
      status: _mergedVisitStatus(primaryRow, localActive),
      supervisorId: primaryRow.supervisorId,
      supervisorName: primaryRow.supervisorName,
      supervisorCheckInAt: primaryRow.supervisorCheckInAt,
      supervisorCheckOutAt: primaryRow.supervisorCheckOutAt,
      supervisorCheckInLatitude: primaryRow.supervisorCheckInLatitude,
      supervisorCheckInLongitude: primaryRow.supervisorCheckInLongitude,
      supervisorCheckOutLatitude: primaryRow.supervisorCheckOutLatitude,
      supervisorCheckOutLongitude: primaryRow.supervisorCheckOutLongitude,
      checkInLatitude: primaryRow.checkInLatitude,
      checkInLongitude: primaryRow.checkInLongitude,
      checkOutLatitude: primaryRow.checkOutLatitude,
      checkOutLongitude: primaryRow.checkOutLongitude,
      notes: primaryRow.notes,
      googleMapsLink: primaryRow.googleMapsLink,
      createdAt: primaryRow.createdAt,
      actions: useActions,
    );
  }

  DateTime? _restoredActualStartFor(String visitId) {
    final ms = state.actualStartTimestampMs[visitId];
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Visit? _findVisitById(String visitId) {
    for (final v in state.visits) {
      if (v.id == visitId) return v;
    }
    final plan = state.journeyPlan;
    if (plan != null) {
      for (final s in plan.stops) {
        final v = s.visit;
        if (v != null && v.id == visitId) return v;
      }
    }
    return null;
  }

  /// ASP.NET can return 400 from the *response serializer* after check-in
  /// succeeded (e.g. duplicate JSON names on VisitDto). We detect that
  /// message and align local state from a fresh GET when the visit is
  /// actually started.
  bool _isCheckInResponseSerializationBug(String message) {
    final m = message.toLowerCase();
    return m.contains('collides with another property') ||
        m.contains('visitdto.username');
  }

  VisitModel _mergeRequestCheckInCoordsIntoVisit(
    VisitModel fresh,
    double? latitude,
    double? longitude,
  ) {
    return VisitModel(
      id: fresh.id,
      userId: fresh.userId,
      userName: fresh.userName,
      customerId: fresh.customerId,
      customerName: fresh.customerName,
      customerCode: fresh.customerCode,
      journeyPlanId: fresh.journeyPlanId,
      plannedDateTime: fresh.plannedDateTime,
      actualStartDateTime: fresh.actualStartDateTime,
      actualEndDateTime: fresh.actualEndDateTime,
      visitType: fresh.visitType,
      status: fresh.status,
      supervisorId: fresh.supervisorId,
      supervisorName: fresh.supervisorName,
      supervisorCheckInAt: fresh.supervisorCheckInAt,
      supervisorCheckOutAt: fresh.supervisorCheckOutAt,
      supervisorCheckInLatitude: fresh.supervisorCheckInLatitude,
      supervisorCheckInLongitude: fresh.supervisorCheckInLongitude,
      supervisorCheckOutLatitude: fresh.supervisorCheckOutLatitude,
      supervisorCheckOutLongitude: fresh.supervisorCheckOutLongitude,
      checkInLatitude: fresh.checkInLatitude ?? latitude,
      checkInLongitude: fresh.checkInLongitude ?? longitude,
      checkOutLatitude: fresh.checkOutLatitude,
      checkOutLongitude: fresh.checkOutLongitude,
      notes: fresh.notes,
      googleMapsLink: fresh.googleMapsLink,
      createdAt: fresh.createdAt,
      actions: fresh.actions,
      customerLocationPoint: fresh.customerLocationPoint,
      customerUGLink: fresh.customerUGLink,
    );
  }

  Future<VisitModel?> _refetchVisitRowForRecovery(String visitId) async {
    final planId = state.journeyPlan?.id;
    if (planId != null) {
      try {
        final raw = await getJourneyPlanByIdUseCase(planId);
        var planModel = raw as JourneyPlanModel;
        try {
          planModel = await _mergeJourneyPlanStopsWithVisitsList(raw);
        } catch (_) {
          // Keep plan from GET only if visits merge fails.
        }
        for (final s in planModel.stops) {
          final v = s.visit;
          if (v != null && v.id == visitId) {
            return v as VisitModel;
          }
        }
      } catch (_) {}
    }

    final existing = _findVisitById(visitId);
    final userId =
        existing?.userId ?? state.loggedInUserId ?? state.filterUserId;
    if (userId == null || userId.isEmpty) {
      return null;
    }
    final planned = existing?.plannedDateTime ?? DateTime.now();
    final start = DateTime(planned.year, planned.month, planned.day);
    final end = DateTime(
      planned.year,
      planned.month,
      planned.day,
      23,
      59,
      59,
      999,
    );
    for (var page = 1; page <= 10; page++) {
      try {
        final response = await getVisitsUseCase(
          GetVisitsParams(
            userId: userId,
            startDate: start,
            endDate: end,
            standaloneOnly: state.lastVisitsLoadWasStandaloneOnly,
            pageNumber: page,
            pageSize: 100,
          ),
        );
        for (final v in response.items) {
          if (v.id == visitId) {
            return v;
          }
        }
        if (!response.hasNextPage) {
          break;
        }
      } catch (_) {
        break;
      }
    }
    return null;
  }

  Future<bool> _tryRecoverCheckInAfterBadResponse(
    String visitId,
    double? latitude,
    double? longitude,
  ) async {
    if (isClosed) {
      return false;
    }
    VisitModel? fresh;
    try {
      fresh = await _refetchVisitRowForRecovery(visitId);
    } catch (_) {
      return false;
    }
    if (fresh == null) {
      return false;
    }
    if (fresh.actualStartDateTime == null || fresh.actualEndDateTime != null) {
      return false;
    }
    final updatedVisit = _mergeRequestCheckInCoordsIntoVisit(
      fresh,
      latitude,
      longitude,
    );
    await _applyLocalStartedVisitFromServerRow(visitId, updatedVisit);
    return true;
  }

  Future<void> _applyLocalStartedVisitFromServerRow(
    String visitId,
    VisitModel updatedVisit,
  ) async {
    final currentPlan = state.journeyPlan;
    if (currentPlan != null) {
      final updatedStops =
          currentPlan.stops.map((stop) {
            final visit = stop.visit;
            if (visit == null || visit.id != visitId) {
              return stop as StopModel;
            }
            return StopModel(
              id: stop.id,
              visitId: stop.visitId,
              sequenceNo: stop.sequenceNo,
              plannedTime: stop.plannedTime,
              estimatedDurationMinutes: stop.estimatedDurationMinutes,
              visit: updatedVisit,
            );
          }).toList();

      final plan = currentPlan as JourneyPlanModel;
      final optimisticPlan = JourneyPlanModel(
        id: plan.id,
        userId: plan.userId,
        userName: plan.userName,
        createdByUserId: plan.createdByUserId,
        createdByUserName: plan.createdByUserName,
        createdBy: plan.createdBy,
        planType: plan.planType,
        startDate: plan.startDate,
        endDate: plan.endDate,
        notes: plan.notes,
        isApproved: plan.isApproved,
        approvedAt: plan.approvedAt,
        stops: updatedStops,
        createdAt: plan.createdAt,
      );

      if (!isClosed) {
        await localDataSource.saveCachedCurrentPlan(optimisticPlan);
        final newVisits = _replaceVisitInVisitsList(
          state.visits,
          visitId,
          updatedVisit,
        );
        final newActualStart = Map<String, int>.from(
          state.actualStartTimestampMs,
        );
        if (updatedVisit.actualStartDateTime != null) {
          newActualStart[visitId] =
              updatedVisit.actualStartDateTime!.millisecondsSinceEpoch;
        }
        await localDataSource.saveCachedVisits(
          newVisits.map((visit) => visit as VisitModel).toList(),
        );
        emit(
          state.copyWith(
            isLoading: false,
            journeyPlan: optimisticPlan,
            visits: newVisits,
            actualStartTimestampMs: newActualStart,
            clearError: true,
          ),
        );
        await _persistVisitTimingState(actualStartTimestampMs: newActualStart);
      }
    } else {
      if (!isClosed) {
        final newVisits = _replaceVisitInVisitsList(
          state.visits,
          visitId,
          updatedVisit,
        );
        final newActualStart = Map<String, int>.from(
          state.actualStartTimestampMs,
        );
        if (updatedVisit.actualStartDateTime != null) {
          newActualStart[visitId] =
              updatedVisit.actualStartDateTime!.millisecondsSinceEpoch;
        }
        await localDataSource.saveCachedVisits(
          newVisits.map((visit) => visit as VisitModel).toList(),
        );
        emit(
          state.copyWith(
            isLoading: false,
            visits: newVisits,
            actualStartTimestampMs: newActualStart,
            clearError: true,
          ),
        );
        await _persistVisitTimingState(
          pausedVisitElapsedSeconds: const {},
          pauseStartTimestampMs: const {},
          totalPausedDurationSeconds: const {},
          actualStartTimestampMs: newActualStart,
        );
      }
    }
  }

  /// Current running elapsed seconds for [visitId] exactly as the live timer
  /// renders it. Prefers the active snapshot maps (activeElapsed + time since
  /// snapshot) so the value is carried forward and never collapses to ~0 just
  /// because a freshly reloaded server `actualStartDateTime` is missing or
  /// close to "now" (which happens after navigating into a visit).
  int _currentRunningElapsedSeconds(
    String visitId, {
    Visit? visit,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final activeElapsed = state.activeVisitElapsedSeconds[visitId];
    final activeSnapshot = state.activeVisitSnapshotTimestampMs[visitId];
    if (activeElapsed != null && activeSnapshot != null) {
      final delta =
          (clock.millisecondsSinceEpoch - activeSnapshot) ~/ 1000;
      final sec = activeElapsed + delta;
      return sec > 0 ? sec : 0;
    }
    final start =
        _effectiveVisitStartForTiming(
          visit,
          visitId,
          state.actualStartTimestampMs,
        ) ??
        _restoredActualStartFor(visitId);
    if (start == null) return 0;
    final totalPaused = state.totalPausedDurationSeconds[visitId] ?? 0;
    final sec = clock.difference(start).inSeconds - totalPaused;
    return sec > 0 ? sec : 0;
  }

  int _computeActualDurationSeconds(Visit visit, {DateTime? endAt}) {
    return visitCheckoutElapsedSeconds(
      visit: visit,
      actualStartTimestampMs: state.actualStartTimestampMs,
      pausedVisitElapsedSeconds: state.pausedVisitElapsedSeconds,
      totalPausedDurationSeconds: state.totalPausedDurationSeconds,
      activeVisitElapsedSeconds: state.activeVisitElapsedSeconds,
      activeVisitSnapshotTimestampMs: state.activeVisitSnapshotTimestampMs,
      endAt: endAt,
    );
  }

  String _formatDurationHms(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final h = (safe ~/ 3600).toString().padLeft(2, '0');
    final m = ((safe % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (safe % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> persistActiveVisitSnapshot() async {
    if (isClosed) return;

    final activeVisits = _activeOngoingVisitsInState().toList();
    final activePlan = state.journeyPlan;

    final actualStartMap = Map<String, int>.from(state.actualStartTimestampMs);
    final activeElapsedMap = Map<String, int>.from(
      state.activeVisitElapsedSeconds,
    );
    final activeSnapshotMap = Map<String, int>.from(
      state.activeVisitSnapshotTimestampMs,
    );
    final now = DateTime.now();
    for (final visit in activeVisits) {
      final effectiveStart =
          visit.actualStartDateTime ?? _restoredActualStartFor(visit.id);
      if (effectiveStart != null) {
        actualStartMap[visit.id] = effectiveStart.millisecondsSinceEpoch;
      }
      // A paused visit's timer must stay frozen — its value lives in
      // pausedVisitElapsedSeconds, so never re-stamp its active snapshot.
      final isPaused = VisitExecutionStatus.isVisitPausedFromTiming(
        visit,
        pausedVisitElapsedSeconds: state.pausedVisitElapsedSeconds,
        pauseStartTimestampMs: state.pauseStartTimestampMs,
        endedVisitElapsedSeconds: state.endedVisitElapsedSeconds,
      );
      if (visit.status == 2 && !isPaused) {
        // Carry the live value forward from the existing snapshot maps instead
        // of recomputing from the start, so a missing/near-now reloaded start
        // can never reset the running timer to ~0.
        final elapsed = _currentRunningElapsedSeconds(
          visit.id,
          visit: visit,
          now: now,
        );
        activeElapsedMap[visit.id] = elapsed;
        activeSnapshotMap[visit.id] = now.millisecondsSinceEpoch;
      }
    }

    if (activePlan != null) {
      final hydratedPlan = JourneyPlanModel(
        id: activePlan.id,
        userId: activePlan.userId,
        userName: activePlan.userName,
        createdByUserId: activePlan.createdByUserId,
        createdByUserName: activePlan.createdByUserName,
        createdBy: activePlan.createdBy,
        planType: activePlan.planType,
        startDate: activePlan.startDate,
        endDate: activePlan.endDate,
        notes: activePlan.notes,
        isApproved: activePlan.isApproved,
        approvedAt: activePlan.approvedAt,
        stops:
            activePlan.stops.map((stop) {
              final visit = stop.visit;
              return StopModel(
                id: stop.id,
                visitId: stop.visitId,
                sequenceNo: stop.sequenceNo,
                plannedTime: stop.plannedTime,
                estimatedDurationMinutes: stop.estimatedDurationMinutes,
                visit:
                    visit == null
                        ? null
                        : _hydrateVisitWithStoredStart(visit, actualStartMap),
              );
            }).toList(),
        createdAt: activePlan.createdAt,
      );
      await localDataSource.saveCachedCurrentPlan(hydratedPlan);
    }

    if (state.visits.isNotEmpty) {
      final hydratedVisits =
          state.visits
              .map(
                (visit) => _hydrateVisitWithStoredStart(visit, actualStartMap),
              )
              .toList();
      await localDataSource.saveCachedVisits(hydratedVisits);
    }

    await _persistVisitTimingState(
      actualStartTimestampMs: actualStartMap,
      activeVisitElapsedSeconds: activeElapsedMap,
      activeVisitSnapshotTimestampMs: activeSnapshotMap,
    );
    if (!isClosed &&
        (actualStartMap != state.actualStartTimestampMs ||
            activeElapsedMap != state.activeVisitElapsedSeconds ||
            activeSnapshotMap != state.activeVisitSnapshotTimestampMs)) {
      emit(
        state.copyWith(
          actualStartTimestampMs: actualStartMap,
          activeVisitElapsedSeconds: activeElapsedMap,
          activeVisitSnapshotTimestampMs: activeSnapshotMap,
        ),
      );
    }
  }

  VisitModel _hydrateVisitWithStoredStart(
    Visit visit,
    Map<String, int> actualStartTimestampMs,
  ) {
    final restoredStartMs = actualStartTimestampMs[visit.id];
    final effectiveStart =
        visit.actualStartDateTime ??
        (restoredStartMs != null
            ? DateTime.fromMillisecondsSinceEpoch(restoredStartMs)
            : null);
    return VisitModel(
      id: visit.id,
      userId: visit.userId,
      userName: visit.userName,
      customerId: visit.customerId,
      customerName: visit.customerName,
      customerCode: visit.customerCode,
      journeyPlanId: visit.journeyPlanId,
      plannedDateTime: visit.plannedDateTime,
      actualStartDateTime: effectiveStart,
      actualEndDateTime: visit.actualEndDateTime,
      visitType: visit.visitType,
      status: visit.status,
      supervisorId: visit.supervisorId,
      supervisorName: visit.supervisorName,
      checkInLatitude: visit.checkInLatitude,
      checkInLongitude: visit.checkInLongitude,
      checkOutLatitude: visit.checkOutLatitude,
      checkOutLongitude: visit.checkOutLongitude,
      notes: visit.notes,
      googleMapsLink: visit.googleMapsLink,
      createdAt: visit.createdAt,
      actions: visit.actions,
    );
  }

  /// Like standalone [loadVisits] (GET /api/Visits), preserves all visit fields and actions.
  VisitModel _hydrateVisitFullWithStoredStart(Visit visit) {
    final restoredStartMs = state.actualStartTimestampMs[visit.id];
    final effectiveStart =
        visit.actualStartDateTime ??
        (restoredStartMs != null
            ? DateTime.fromMillisecondsSinceEpoch(restoredStartMs)
            : null);
    return _copyVisitWithStart(visit, effectiveStart);
  }

  /// Combines a visit row from GET /api/Visits with the embedded stop visit from the plan.
  ///
  /// The list endpoint sometimes returns visits **without** populated [Visit.actions],
  /// while the journey-plan payload may include actions. We keep scalars from [freshFromList]
  /// (status, times, etc.) but use whichever copy has the **longer** actions list so the
  /// UI badge `Actions (n)` stays correct.
  VisitModel _coalesceVisitForJourneyMerge(
    Visit freshFromList,
    Visit? embedded,
  ) {
    final f = freshFromList as VisitModel;
    if (embedded == null) {
      return _hydrateVisitFullWithStoredStart(f);
    }
    final e = embedded as VisitModel;
    final useActions =
        f.actions.length >= e.actions.length ? f.actions : e.actions;
    if (identical(useActions, f.actions)) {
      return _hydrateVisitFullWithStoredStart(f);
    }
    return _hydrateVisitFullWithStoredStart(
      VisitModel(
        id: f.id,
        userId: f.userId,
        userName: f.userName,
        customerId: f.customerId,
        customerName: f.customerName,
        customerCode: f.customerCode,
        journeyPlanId: f.journeyPlanId,
        plannedDateTime: f.plannedDateTime,
        actualStartDateTime: f.actualStartDateTime,
        actualEndDateTime: f.actualEndDateTime,
        visitType: f.visitType,
        status: f.status,
        supervisorId: f.supervisorId,
        supervisorName: f.supervisorName,
        supervisorCheckInAt: f.supervisorCheckInAt,
        supervisorCheckOutAt: f.supervisorCheckOutAt,
        supervisorCheckInLatitude: f.supervisorCheckInLatitude,
        supervisorCheckInLongitude: f.supervisorCheckInLongitude,
        supervisorCheckOutLatitude: f.supervisorCheckOutLatitude,
        supervisorCheckOutLongitude: f.supervisorCheckOutLongitude,
        checkInLatitude: f.checkInLatitude,
        checkInLongitude: f.checkInLongitude,
        checkOutLatitude: f.checkOutLatitude,
        checkOutLongitude: f.checkOutLongitude,
        notes: f.notes,
        googleMapsLink: f.googleMapsLink,
        createdAt: f.createdAt,
        actions: useActions,
      ),
    );
  }

  /// Merges each stop's embedded visit with the same visit from GET /api/Visits (not standalone),
  /// which includes [Visit.actions] like the standalone visit list.
  Future<JourneyPlanModel> _mergeJourneyPlanStopsWithVisitsList(
    JourneyPlan plan,
  ) async {
    final visitIdsInStops = <String>{};
    for (final s in plan.stops) {
      visitIdsInStops.add(s.visitId);
      if (s.visit != null) visitIdsInStops.add(s.visit!.id);
    }
    if (visitIdsInStops.isEmpty) {
      return plan as JourneyPlanModel;
    }

    final start = DateTime(
      plan.startDate.year,
      plan.startDate.month,
      plan.startDate.day,
    );
    final end = DateTime(
      plan.endDate.year,
      plan.endDate.month,
      plan.endDate.day,
      23,
      59,
      59,
      999,
    );

    final byId = <String, Visit>{};
    var page = 1;
    const pageSize = 100;
    while (true) {
      final response = await getVisitsUseCase(
        GetVisitsParams(
          userId: plan.userId,
          startDate: start,
          endDate: end,
          standaloneOnly: false,
          pageNumber: page,
          pageSize: pageSize,
        ),
      );
      for (final v in response.items) {
        if (visitIdsInStops.contains(v.id)) {
          byId[v.id] = v;
        }
      }
      if (!response.hasNextPage || page >= response.totalPages) break;
      page++;
      if (page > 50) break;
    }

    final p = plan as JourneyPlanModel;
    final newStops =
        plan.stops.map((stop) {
          final fresh =
              stop.visit != null
                  ? (byId[stop.visit!.id] ?? byId[stop.visitId])
                  : byId[stop.visitId];
          if (fresh != null) {
            final hydrated = _coalesceVisitForJourneyMerge(fresh, stop.visit);
            return StopModel(
              id: stop.id,
              visitId: stop.visitId,
              sequenceNo: stop.sequenceNo,
              plannedTime: stop.plannedTime,
              estimatedDurationMinutes: stop.estimatedDurationMinutes,
              visit: hydrated,
            );
          }
          if (stop.visit == null) {
            return StopModel(
              id: stop.id,
              visitId: stop.visitId,
              sequenceNo: stop.sequenceNo,
              plannedTime: stop.plannedTime,
              estimatedDurationMinutes: stop.estimatedDurationMinutes,
              visit: null,
            );
          }
          final hydrated = _hydrateVisitFullWithStoredStart(
            stop.visit as VisitModel,
          );
          return StopModel(
            id: stop.id,
            visitId: stop.visitId,
            sequenceNo: stop.sequenceNo,
            plannedTime: stop.plannedTime,
            estimatedDurationMinutes: stop.estimatedDurationMinutes,
            visit: hydrated,
          );
        }).toList();

    return JourneyPlanModel(
      id: p.id,
      userId: p.userId,
      userName: p.userName,
      createdByUserId: p.createdByUserId,
      createdByUserName: p.createdByUserName,
      createdBy: p.createdBy,
      planType: p.planType,
      startDate: p.startDate,
      endDate: p.endDate,
      notes: p.notes,
      isApproved: p.isApproved,
      approvedAt: p.approvedAt,
      stops: newStops,
      createdAt: p.createdAt,
    );
  }

  VisitModel _copyVisitWithStart(Visit visit, DateTime? actualStartDateTime) {
    return VisitModel(
      id: visit.id,
      userId: visit.userId,
      userName: visit.userName,
      customerId: visit.customerId,
      customerName: visit.customerName,
      customerCode: visit.customerCode,
      journeyPlanId: visit.journeyPlanId,
      plannedDateTime: visit.plannedDateTime,
      actualStartDateTime: actualStartDateTime,
      actualEndDateTime: visit.actualEndDateTime,
      visitType: visit.visitType,
      status: visit.status,
      supervisorId: visit.supervisorId,
      supervisorName: visit.supervisorName,
      supervisorCheckInAt: visit.supervisorCheckInAt,
      supervisorCheckOutAt: visit.supervisorCheckOutAt,
      supervisorCheckInLatitude: visit.supervisorCheckInLatitude,
      supervisorCheckInLongitude: visit.supervisorCheckInLongitude,
      supervisorCheckOutLatitude: visit.supervisorCheckOutLatitude,
      supervisorCheckOutLongitude: visit.supervisorCheckOutLongitude,
      checkInLatitude: visit.checkInLatitude,
      checkInLongitude: visit.checkInLongitude,
      checkOutLatitude: visit.checkOutLatitude,
      checkOutLongitude: visit.checkOutLongitude,
      notes: visit.notes,
      googleMapsLink: visit.googleMapsLink,
      createdAt: visit.createdAt,
      actions: visit.actions,
    );
  }

  Future<void> _applyVisitUpdate(VisitModel updatedVisit) async {
    final updatedPlan =
        state.journeyPlan == null
            ? null
            : JourneyPlanModel(
              id: state.journeyPlan!.id,
              userId: state.journeyPlan!.userId,
              userName: state.journeyPlan!.userName,
              createdByUserId: state.journeyPlan!.createdByUserId,
              createdByUserName: state.journeyPlan!.createdByUserName,
              createdBy: state.journeyPlan!.createdBy,
              planType: state.journeyPlan!.planType,
              startDate: state.journeyPlan!.startDate,
              endDate: state.journeyPlan!.endDate,
              notes: state.journeyPlan!.notes,
              isApproved: state.journeyPlan!.isApproved,
              approvedAt: state.journeyPlan!.approvedAt,
              stops:
                  state.journeyPlan!.stops.map((stop) {
                    if (stop.visit?.id != updatedVisit.id) return stop;
                    return StopModel(
                      id: stop.id,
                      visitId: stop.visitId,
                      sequenceNo: stop.sequenceNo,
                      plannedTime: stop.plannedTime,
                      estimatedDurationMinutes: stop.estimatedDurationMinutes,
                      visit: updatedVisit,
                    );
                  }).toList(),
              createdAt: state.journeyPlan!.createdAt,
            );

    final newVisits = _replaceVisitInVisitsList(
      state.visits,
      updatedVisit.id,
      updatedVisit,
    );
    if (updatedPlan != null) {
      await localDataSource.saveCachedCurrentPlan(updatedPlan);
    }
    await localDataSource.saveCachedVisits(
      newVisits.map((visit) => visit as VisitModel).toList(),
    );
    if (!isClosed) {
      emit(
        state.copyWith(
          journeyPlan: updatedPlan ?? state.journeyPlan,
          visits: newVisits,
          isLoading: false,
          clearError: true,
        ),
      );
    }
  }

  Future<void> _applyOfflineVisitAction({
    required String visitId,
    required String action,
    required int newStatus,
    bool setActualStart = false,
    bool setActualEnd = false,
    double? checkInLat,
    double? checkInLng,
    double? checkOutLat,
    double? checkOutLng,
  }) async {
    final now = DateTime.now();
    VisitModel? updatedVisit;
    JourneyPlanModel? optimisticPlan;
    final currentPlan = state.journeyPlan;

    if (currentPlan != null) {
      for (final stop in currentPlan.stops) {
        if (stop.visit?.id == visitId) {
          final visit = stop.visit!;
          updatedVisit = VisitModel(
            id: visit.id,
            userId: visit.userId,
            userName: visit.userName,
            customerId: visit.customerId,
            customerName: visit.customerName,
            customerCode: visit.customerCode,
            journeyPlanId: visit.journeyPlanId,
            plannedDateTime: visit.plannedDateTime,
            actualStartDateTime:
                setActualStart
                    ? (visit.actualStartDateTime ?? now)
                    : visit.actualStartDateTime,
            actualEndDateTime: setActualEnd ? now : visit.actualEndDateTime,
            visitType: visit.visitType,
            status: newStatus,
            supervisorId: visit.supervisorId,
            supervisorName: visit.supervisorName,
            checkInLatitude: checkInLat ?? visit.checkInLatitude,
            checkInLongitude: checkInLng ?? visit.checkInLongitude,
            checkOutLatitude: checkOutLat ?? visit.checkOutLatitude,
            checkOutLongitude: checkOutLng ?? visit.checkOutLongitude,
            notes: visit.notes,
            googleMapsLink: visit.googleMapsLink,
            createdAt: visit.createdAt,
            actions: visit.actions,
          );
          final updatedStops =
              currentPlan.stops.map((s) {
                if (s.visit?.id != visitId) return s;
                return StopModel(
                  id: s.id,
                  visitId: s.visitId,
                  sequenceNo: s.sequenceNo,
                  plannedTime: s.plannedTime,
                  estimatedDurationMinutes: s.estimatedDurationMinutes,
                  visit: updatedVisit,
                );
              }).toList();
          optimisticPlan = JourneyPlanModel(
            id: currentPlan.id,
            userId: currentPlan.userId,
            userName: currentPlan.userName,
            createdByUserId: currentPlan.createdByUserId,
            createdByUserName: currentPlan.createdByUserName,
            createdBy: currentPlan.createdBy,
            planType: currentPlan.planType,
            startDate: currentPlan.startDate,
            endDate: currentPlan.endDate,
            notes: currentPlan.notes,
            isApproved: currentPlan.isApproved,
            approvedAt: currentPlan.approvedAt,
            stops: updatedStops,
            createdAt: currentPlan.createdAt,
          );
          break;
        }
      }
    }
    if (updatedVisit == null && state.visits.isNotEmpty) {
      final idx = state.visits.indexWhere((v) => v.id == visitId);
      if (idx >= 0) {
        final visit = state.visits[idx] as VisitModel;
        updatedVisit = VisitModel(
          id: visit.id,
          userId: visit.userId,
          userName: visit.userName,
          customerId: visit.customerId,
          customerName: visit.customerName,
          customerCode: visit.customerCode,
          journeyPlanId: visit.journeyPlanId,
          plannedDateTime: visit.plannedDateTime,
          actualStartDateTime:
              setActualStart
                  ? (visit.actualStartDateTime ?? now)
                  : visit.actualStartDateTime,
          actualEndDateTime: setActualEnd ? now : visit.actualEndDateTime,
          visitType: visit.visitType,
          status: newStatus,
          supervisorId: visit.supervisorId,
          supervisorName: visit.supervisorName,
          checkInLatitude: checkInLat ?? visit.checkInLatitude,
          checkInLongitude: checkInLng ?? visit.checkInLongitude,
          checkOutLatitude: checkOutLat ?? visit.checkOutLatitude,
          checkOutLongitude: checkOutLng ?? visit.checkOutLongitude,
          notes: visit.notes,
          googleMapsLink: visit.googleMapsLink,
          createdAt: visit.createdAt,
          actions: visit.actions,
        );
      }
    }
    if (updatedVisit == null && optimisticPlan == null) return;

    List<VisitModel> newVisits =
        state.visits.map((v) => v as VisitModel).toList();

    var visitForTiming = updatedVisit ?? _findVisitById(visitId);
    if (visitForTiming == null && optimisticPlan != null) {
      for (final stop in optimisticPlan.stops) {
        if (stop.visit?.id == visitId) {
          visitForTiming = stop.visit;
          break;
        }
      }
    }

    var newPaused = Map<String, int>.from(state.pausedVisitElapsedSeconds);
    var newPauseStart = Map<String, int>.from(state.pauseStartTimestampMs);
    var newTotalPaused = Map<String, int>.from(
      state.totalPausedDurationSeconds,
    );
    var newActualStart = Map<String, int>.from(state.actualStartTimestampMs);
    var newActiveElapsed = Map<String, int>.from(
      state.activeVisitElapsedSeconds,
    );
    var newActiveSnapshot = Map<String, int>.from(
      state.activeVisitSnapshotTimestampMs,
    );
    var newEnded = Map<String, int>.from(state.endedVisitElapsedSeconds);
    var finalPlan = optimisticPlan;
    int? durationSeconds;

    switch (action) {
      case 'checkIn':
        newActualStart[visitId] = now.millisecondsSinceEpoch;
        newPaused.remove(visitId);
        newPauseStart.remove(visitId);
        newTotalPaused.remove(visitId);
        newActiveElapsed[visitId] = 0;
        newActiveSnapshot[visitId] = now.millisecondsSinceEpoch;
        newEnded.remove(visitId);
        break;
      case 'pause':
        final start = _effectiveVisitStartForTiming(
          visitForTiming,
          visitId,
          newActualStart,
        );
        if (start != null) {
          newActualStart[visitId] = start.millisecondsSinceEpoch;
          // Freeze at the value the live timer is showing (carried forward from
          // the snapshot maps) so it can't reset to ~0 on a stale start.
          final elapsed = _currentRunningElapsedSeconds(
            visitId,
            visit: visitForTiming,
            now: now,
          );
          newPaused[visitId] = elapsed.clamp(0, 1 << 30);
          newPauseStart[visitId] = now.millisecondsSinceEpoch;
          newActiveElapsed.remove(visitId);
          newActiveSnapshot.remove(visitId);
        }
        break;
      case 'resume':
        final pausedElapsed = newPaused[visitId];
        final pauseStartMs = newPauseStart.remove(visitId);
        newPaused.remove(visitId);
        if (pauseStartMs != null) {
          final pausedDurationSec =
              (now.millisecondsSinceEpoch - pauseStartMs) ~/ 1000;
          newTotalPaused[visitId] =
              (newTotalPaused[visitId] ?? 0) + pausedDurationSec;
        } else if (pausedElapsed != null &&
            visitForTiming?.actualStartDateTime != null) {
          final recomputed =
              now.difference(visitForTiming!.actualStartDateTime!).inSeconds -
              pausedElapsed;
          newTotalPaused[visitId] = recomputed > 0 ? recomputed : 0;
        }
        if (pausedElapsed != null) {
          final adjustedStart = now.subtract(
            Duration(seconds: pausedElapsed + (newTotalPaused[visitId] ?? 0)),
          );
          newActualStart[visitId] = adjustedStart.millisecondsSinceEpoch;
          if (visitForTiming != null) {
            final resumed = _copyVisitWithStart(visitForTiming, adjustedStart);
            updatedVisit = resumed;
            visitForTiming = resumed;
            final i = newVisits.indexWhere((v) => v.id == visitId);
            if (i >= 0) {
              newVisits[i] = resumed;
            }
            if (finalPlan != null) {
              finalPlan = _journeyPlanWithVisit(finalPlan, visitId, resumed);
            }
            newActiveElapsed[visitId] = pausedElapsed;
            newActiveSnapshot[visitId] = now.millisecondsSinceEpoch;
          }
        }
        break;
      case 'checkOut':
        final checkoutVisit = updatedVisit ?? visitForTiming;
        if (checkoutVisit != null) {
          durationSeconds = visitCheckoutElapsedSeconds(
            visit: checkoutVisit,
            actualStartTimestampMs: newActualStart,
            pausedVisitElapsedSeconds: newPaused,
            totalPausedDurationSeconds: newTotalPaused,
            activeVisitElapsedSeconds: newActiveElapsed,
            activeVisitSnapshotTimestampMs: newActiveSnapshot,
            endAt: now,
          );
        }
        newPaused.remove(visitId);
        newPauseStart.remove(visitId);
        newTotalPaused.remove(visitId);
        newActualStart.remove(visitId);
        newActiveElapsed.remove(visitId);
        newActiveSnapshot.remove(visitId);
        if (durationSeconds != null) {
          newEnded[visitId] = durationSeconds;
        }
        break;
    }

    if (updatedVisit != null) {
      final visitIndex = newVisits.indexWhere((v) => v.id == visitId);
      if (visitIndex >= 0) {
        newVisits[visitIndex] = updatedVisit;
      } else {
        newVisits.insert(0, updatedVisit);
      }
    }

    final durationHms =
        durationSeconds == null ? null : _formatDurationHms(durationSeconds);

    await localDataSource.addPendingVisitAction(
      PendingVisitAction(
        action: action,
        visitId: visitId,
        latitude: checkInLat ?? checkOutLat,
        longitude: checkInLng ?? checkOutLng,
        actualDurationSeconds: durationSeconds,
        actualDuration: durationHms,
        createdAt: now,
      ),
    );
    if (finalPlan != null) {
      await localDataSource.saveCachedCurrentPlan(finalPlan);
    }
    if (newVisits.isNotEmpty) {
      await localDataSource.saveCachedVisits(newVisits);
    }
    final pending = await localDataSource.getPendingVisitActions();
    if (!isClosed) {
      emit(
        state.copyWith(
          journeyPlan: finalPlan ?? state.journeyPlan,
          visits: newVisits,
          pendingSyncCount: pending.length,
          pausedVisitElapsedSeconds: newPaused,
          pauseStartTimestampMs: newPauseStart,
          totalPausedDurationSeconds: newTotalPaused,
          actualStartTimestampMs: newActualStart,
          activeVisitElapsedSeconds: newActiveElapsed,
          activeVisitSnapshotTimestampMs: newActiveSnapshot,
          endedVisitElapsedSeconds: newEnded,
          clearError: true,
        ),
      );
      await _persistVisitTimingState(
        pausedVisitElapsedSeconds: newPaused,
        pauseStartTimestampMs: newPauseStart,
        totalPausedDurationSeconds: newTotalPaused,
        actualStartTimestampMs: newActualStart,
        activeVisitElapsedSeconds: newActiveElapsed,
        activeVisitSnapshotTimestampMs: newActiveSnapshot,
        endedVisitElapsedSeconds: newEnded,
      );
    }
  }

  DateTime? _effectiveVisitStartForTiming(
    Visit? visit,
    String visitId,
    Map<String, int> actualStartTimestampMs,
  ) {
    final fromVisit = visit?.actualStartDateTime;
    if (fromVisit != null) return fromVisit;
    final ms = actualStartTimestampMs[visitId];
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    return _restoredActualStartFor(visitId);
  }

  JourneyPlanModel _journeyPlanWithVisit(
    JourneyPlanModel plan,
    String visitId,
    VisitModel visit,
  ) {
    final updatedStops =
        plan.stops.map((stop) {
          if (stop.visit?.id != visitId) return stop;
          return StopModel(
            id: stop.id,
            visitId: stop.visitId,
            sequenceNo: stop.sequenceNo,
            plannedTime: stop.plannedTime,
            estimatedDurationMinutes: stop.estimatedDurationMinutes,
            visit: visit,
          );
        }).toList();
    return JourneyPlanModel(
      id: plan.id,
      userId: plan.userId,
      userName: plan.userName,
      createdByUserId: plan.createdByUserId,
      createdByUserName: plan.createdByUserName,
      createdBy: plan.createdBy,
      planType: plan.planType,
      startDate: plan.startDate,
      endDate: plan.endDate,
      notes: plan.notes,
      isApproved: plan.isApproved,
      approvedAt: plan.approvedAt,
      stops: updatedStops,
      createdAt: plan.createdAt,
    );
  }

  /// Default end date from start date and plan type (day=same, week=+7d, month=+1, quarter=+3, year=+1). End date remains editable.
  static DateTime _defaultEndDateFor(DateTime startDate, int planType) {
    final d = DateTime(startDate.year, startDate.month, startDate.day);
    switch (planType) {
      case 1:
        return d; // day
      case 2:
        return d.add(const Duration(days: 7)); // week
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

  void updatePlanType(int planType) {
    final newEndDate =
        state.startDate != null
            ? _defaultEndDateFor(state.startDate!, planType)
            : state.endDate;
    emit(
      state.copyWith(
        planType: planType,
        endDate: state.startDate != null ? newEndDate : state.endDate,
      ),
    );
  }

  void updateStartDate(DateTime startDate) {
    final endDate = _defaultEndDateFor(startDate, state.planType);
    emit(state.copyWith(startDate: startDate, endDate: endDate));
  }

  void updateEndDate(DateTime endDate) {
    emit(state.copyWith(endDate: endDate));
  }

  void updateNotes(String notes) {
    emit(state.copyWith(notes: notes));
  }

  void nextStep() {
    if (state.currentStep >= 2) return;
    final next = state.currentStep + 1;
    // Step 2 requires a saved journey plan (create failed → no plan → stay on step 1)
    if (next == 2 && state.journeyPlan == null) {
      return;
    }
    emit(state.copyWith(currentStep: next));
  }

  void previousStep() {
    if (state.currentStep > 1) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  void setCreateForMyself(bool forMyself, {String? userId}) {
    emit(
      state.copyWith(
        createForMyself: forMyself,
        selectedSubordinate: forMyself ? null : state.selectedSubordinate,
      ),
    );

    // If creating for another user and subordinates haven't been loaded, load them
    if (!forMyself &&
        userId != null &&
        state.subordinates.isEmpty &&
        !state.isLoadingSubordinates) {
      loadSubordinates(userId);
    }
  }

  void selectSubordinate(SubordinateModel? subordinate) {
    emit(state.copyWith(selectedSubordinate: subordinate));
  }

  Future<void> loadSubordinates(String userId) async {
    emit(
      state.copyWith(
        isLoadingSubordinates: true,
        subordinatesErrorMessage: null,
      ),
    );

    try {
      final response = await getSubordinatesUseCase(userId);
      emit(
        state.copyWith(
          isLoadingSubordinates: false,
          subordinates: response.directSubordinates,
        ),
      );
    } on Failure catch (e) {
      emit(
        state.copyWith(
          isLoadingSubordinates: false,
          subordinatesErrorMessage: userFriendlyErrorMessage(e.message),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingSubordinates: false,
          subordinatesErrorMessage: 'Failed to load subordinates',
        ),
      );
    }
  }

  Future<void> loadSupervisors() async {
    emit(
      state.copyWith(isLoadingSupervisors: true, clearSupervisorsError: true),
    );

    try {
      final supervisors = await getSupervisorsUseCase();
      emit(
        state.copyWith(
          isLoadingSupervisors: false,
          supervisors: supervisors,
          clearSupervisorsError: true,
        ),
      );
    } on Failure catch (e) {
      print('❌ loadSupervisors Failure: ${e.message}');
      emit(
        state.copyWith(
          isLoadingSupervisors: false,
          supervisorsErrorMessage: userFriendlyErrorMessage(e.message),
        ),
      );
    } catch (e, stackTrace) {
      print('❌ loadSupervisors Exception: $e');
      print('❌ StackTrace: $stackTrace');
      emit(
        state.copyWith(
          isLoadingSupervisors: false,
          supervisorsErrorMessage: 'Failed to load supervisors: $e',
        ),
      );
    }
  }

  Future<void> createJourneyPlan(String loggedInUserId) async {
    if (state.startDate == null || state.endDate == null) {
      emit(state.copyWith(errorMessage: 'Please select start and end dates'));
      return;
    }

    // Determine the userId for the journey plan
    // If a subordinate is selected, use their ID (supervisors creating for another user)
    // Otherwise, use the logged-in user's ID
    final userId = state.selectedSubordinate?.id ?? loggedInUserId;

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final journeyPlan = JourneyPlanModel(
        id: '',
        userId: userId,
        userName: state.selectedSubordinate?.fullName ?? '',
        createdByUserId: loggedInUserId,
        createdByUserName: '',
        planType: state.planType,
        startDate: state.startDate!,
        endDate: state.endDate!,
        notes: state.notes,
        isApproved: false,
        approvedAt: null,
        stops: [],
        createdAt: DateTime.now(),
      );

      final createdPlan = await createJourneyPlanUseCase(journeyPlan);
      emit(
        state.copyWith(
          isLoading: false,
          journeyPlan: createdPlan,
          currentStep: 2,
          clearError: true,
        ),
      );
    } on Failure catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: userFriendlyErrorMessage(e.message),
          currentStep: 1,
          clearJourneyPlan: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: userFriendlyErrorMessage(null),
          currentStep: 1,
          clearJourneyPlan: true,
        ),
      );
    }
  }

  Future<void> loadJourneyPlanForEdit(
    String journeyPlanId, {
    String? currentUserId,
    bool? isSupervisor,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final online = await connectivityService.isOnline;
    if (!online) {
      JourneyPlanModel? cached = await localDataSource.getCachedCurrentPlan();
      if (cached?.id != journeyPlanId) {
        final cachedList = await localDataSource.getCachedJourneyPlans();
        final found = cachedList.where((p) => p.id == journeyPlanId).toList();
        cached = found.isNotEmpty ? found.first : null;
        if (cached != null) {
          await localDataSource.saveCachedCurrentPlan(cached);
        }
      }
      if (cached != null && cached.id == journeyPlanId) {
        final createdById = cached.createdBy?.id ?? cached.createdByUserId;
        final isViewOnly =
            isSupervisor == true ||
            (currentUserId != null && createdById != currentUserId);
        if (!isClosed) {
          emit(
            state.copyWith(
              isLoading: false,
              isEditing: true,
              editingJourneyPlanId: cached.id,
              planType: cached.planType,
              startDate: cached.startDate,
              endDate: cached.endDate,
              notes: cached.notes,
              journeyPlan: _hydrateJourneyPlanFromLocalTiming(cached),
              currentStep: 1,
              showCreateForm: true,
              createForMyself: true,
              selectedSubordinate: null,
              isViewOnly: isViewOnly,
            ),
          );
        }
        return;
      }
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage:
                'This journey plan is not available offline. Please connect to the internet to open it.',
          ),
        );
      }
      return;
    }

    try {
      final journeyPlan = await getJourneyPlanByIdUseCase(journeyPlanId);

      print('Loaded journey plan for edit: ${journeyPlan.id}');
      print('Number of stops loaded: ${journeyPlan.stops.length}');

      // Check if user is viewing a journey created by another user
      // Use createdBy.id if available, otherwise fall back to createdByUserId
      final createdById =
          journeyPlan.createdBy?.id ?? journeyPlan.createdByUserId;
      // If isSupervisor is true (manager viewing), always set to view-only
      // Otherwise, check if viewing journey created by another user
      final isViewOnly =
          isSupervisor == true ||
          (currentUserId != null && createdById != currentUserId);

      if (!isClosed) {
        JourneyPlanModel planModel = journeyPlan as JourneyPlanModel;
        try {
          planModel = await _mergeJourneyPlanStopsWithVisitsList(journeyPlan);
        } catch (_) {
          // Same as standalone: full visit rows come from GET /api/Visits; merge is best-effort.
        }
        planModel = _hydrateJourneyPlanFromLocalTiming(planModel);
        await localDataSource.saveCachedCurrentPlan(planModel);
        await localDataSource.updateCachedJourneyPlan(planModel);
        emit(
          state.copyWith(
            isLoading: false,
            isEditing: true,
            editingJourneyPlanId: planModel.id,
            planType: planModel.planType,
            startDate: planModel.startDate,
            endDate: planModel.endDate,
            notes: planModel.notes,
            journeyPlan: planModel,
            currentStep: 1,
            showCreateForm: true,
            createForMyself:
                true, // When editing, assume it's for the same user
            selectedSubordinate: null,
            isViewOnly: isViewOnly,
          ),
        );
      }
    } on Failure catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.message),
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(null),
          ),
        );
      }
    }
  }

  /// Reloads the current journey plan from the API without changing wizard step
  /// or form fields. Use after ERP flows linked to a visit so embedded stops show
  /// updated [Visit.actions].
  Future<void> refreshJourneyPlanFromServer() async {
    final planId = state.journeyPlan?.id;
    if (planId == null || isClosed) return;

    final online = await connectivityService.isOnline;
    if (!online) return;

    try {
      final journeyPlan = await getJourneyPlanByIdUseCase(planId);
      if (isClosed) return;
      JourneyPlanModel planModel = journeyPlan as JourneyPlanModel;
      try {
        planModel = await _mergeJourneyPlanStopsWithVisitsList(journeyPlan);
      } catch (_) {
        // Keep plan-only payload if visits list merge fails.
      }
      await localDataSource.saveCachedCurrentPlan(planModel);
      await localDataSource.updateCachedJourneyPlan(planModel);
      emit(state.copyWith(journeyPlan: planModel, clearError: true));
    } catch (_) {
      // Background refresh; avoid disrupting step 2 UX with errors.
    }
  }

  Future<void> updateJourneyPlan() async {
    if (isClosed) return;

    if (state.startDate == null || state.endDate == null) {
      if (!isClosed) {
        emit(state.copyWith(errorMessage: 'Please select start and end dates'));
      }
      return;
    }

    if (state.editingJourneyPlanId == null) {
      if (!isClosed) {
        emit(
          state.copyWith(errorMessage: 'No journey plan selected for editing'),
        );
      }
      return;
    }

    if (state.journeyPlan == null) {
      if (!isClosed) {
        emit(state.copyWith(errorMessage: 'Journey plan data not loaded'));
      }
      return;
    }

    if (!isClosed) {
      emit(state.copyWith(isLoading: true, errorMessage: null));
    }

    try {
      final journeyPlan = JourneyPlanModel(
        id: state.editingJourneyPlanId!,
        userId: state.journeyPlan!.userId,
        userName: state.journeyPlan!.userName,
        createdByUserId: state.journeyPlan!.createdByUserId,
        createdByUserName: state.journeyPlan!.createdByUserName,
        planType: state.planType,
        startDate: state.startDate!,
        endDate: state.endDate!,
        notes: state.notes,
        isApproved: state.journeyPlan!.isApproved,
        approvedAt: state.journeyPlan!.approvedAt,
        stops: [], // Step 1 update should send empty stops array
        createdAt: state.journeyPlan!.createdAt,
      );

      print('Calling PUT /api/journey-plans/${state.editingJourneyPlanId}');
      print('Request data: ${journeyPlan.toUpdateJson()}');

      final updatedPlan = await updateJourneyPlanUseCase.call(
        state.editingJourneyPlanId!,
        journeyPlan,
      );

      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            journeyPlan: updatedPlan,
            currentStep: 2,
            clearError: true,
          ),
        );
      }
    } on Failure catch (e) {
      print('Update failed: ${e.message}');
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.message),
          ),
        );
      }
    } catch (e) {
      print('Update error: ${e.toString()}');
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.toString()),
          ),
        );
      }
    }
  }

  Future<void> updateJourneyPlanWithStops() async {
    if (isClosed) return;

    if (state.startDate == null || state.endDate == null) {
      if (!isClosed) {
        emit(state.copyWith(errorMessage: 'Please select start and end dates'));
      }
      return;
    }

    if (state.editingJourneyPlanId == null) {
      if (!isClosed) {
        emit(
          state.copyWith(errorMessage: 'No journey plan selected for editing'),
        );
      }
      return;
    }

    if (state.journeyPlan == null) {
      if (!isClosed) {
        emit(state.copyWith(errorMessage: 'Journey plan data not loaded'));
      }
      return;
    }

    if (!isClosed) {
      emit(state.copyWith(isLoading: true, errorMessage: null));
    }

    try {
      // Ensure we have stops from the loaded journey plan
      final existingStops = state.journeyPlan!.stops;
      print('Updating journey plan with ${existingStops.length} stops');

      // Include all existing stops in the update to prevent them from being removed
      final journeyPlan = JourneyPlanModel(
        id: state.editingJourneyPlanId!,
        userId: state.journeyPlan!.userId,
        userName: state.journeyPlan!.userName,
        createdByUserId: state.journeyPlan!.createdByUserId,
        createdByUserName: state.journeyPlan!.createdByUserName,
        planType: state.planType,
        startDate: state.startDate!,
        endDate: state.endDate!,
        notes: state.notes,
        isApproved: state.journeyPlan!.isApproved,
        approvedAt: state.journeyPlan!.approvedAt,
        stops: existingStops, // Include all existing stops to prevent removal
        createdAt: state.journeyPlan!.createdAt,
      );

      final updateJson = journeyPlan.toUpdateJson();
      print(
        'Calling PUT /api/journey-plans/${state.editingJourneyPlanId} with stops',
      );
      print('Number of stops in request: ${updateJson['stops'].length}');
      print('Request data: $updateJson');

      final updatedPlan = await updateJourneyPlanUseCase.call(
        state.editingJourneyPlanId!,
        journeyPlan,
      );

      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            journeyPlan: updatedPlan,
            clearError: true,
          ),
        );
      }
    } on Failure catch (e) {
      print('Update failed: ${e.message}');
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.message),
          ),
        );
      }
    } catch (e) {
      print('Update error: ${e.toString()}');
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.toString()),
          ),
        );
      }
    }
  }

  void cancelEdit() {
    emit(
      state.copyWith(
        isEditing: false,
        editingJourneyPlanId: null,
        showCreateForm: false,
        currentStep: 1,
        planType: 1,
        startDate: null,
        endDate: null,
        notes: '',
        clearJourneyPlan: true,
        isViewOnly: false,
      ),
    );
  }

  Future<void> createStopAndVisit({
    required String customerCode,
    required String customerName,
    required DateTime plannedDateTime,
    required int visitType,
    String? supervisorId,
    String? notes,
    required DateTime plannedTime,
    required int estimatedDurationMinutes,
    String? googleMapsLink,
  }) async {
    if (state.journeyPlan == null) return;

    if (isClosed) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final request = CreateStopRequestModel(
        customerCode: customerCode,
        customerName: customerName,
        plannedDateTime: plannedDateTime,
        visitType: visitType,
        supervisorId: supervisorId,
        notes: notes,
        plannedTime: plannedTime,
        estimatedDurationMinutes: estimatedDurationMinutes,
        googleMapsLink: googleMapsLink,
      );

      final updatedPlan = await createStopAndVisitUseCase(
        CreateStopAndVisitParams(
          journeyPlanId: state.journeyPlan!.id,
          request: request,
        ),
      );

      // Check if googleMapsLink was provided but not saved, and update if needed
      if (googleMapsLink != null && googleMapsLink.isNotEmpty) {
        if (kDebugMode) {
          print('📍 googleMapsLink provided: $googleMapsLink');
        }

        if (updatedPlan.stops.isNotEmpty) {
          final lastStop = updatedPlan.stops.last;
          if (lastStop.visit != null) {
            final visitLink = lastStop.visit!.googleMapsLink;
            if (kDebugMode) {
              print('📍 Visit ID: ${lastStop.visit!.id}');
              print('📍 googleMapsLink in response: $visitLink');
            }

            // If googleMapsLink was provided but not saved, update the visit
            if (visitLink == null || visitLink.isEmpty) {
              if (kDebugMode) {
                print('📍 googleMapsLink not saved, updating visit...');
              }
              try {
                await updateVisitUseCase(
                  UpdateVisitParams(
                    visitId: lastStop.visit!.id,
                    request: UpdateVisitRequestModel(
                      googleMapsLink: googleMapsLink,
                    ),
                  ),
                );
                if (kDebugMode) {
                  print('✅ Visit updated with googleMapsLink');
                }
              } catch (e) {
                // If update fails, still show the created visit
                if (kDebugMode) {
                  print('⚠️ Failed to update visit googleMapsLink: $e');
                }
              }
            }
          }
        }
      }

      // ALWAYS reload the journey plan to get the latest data (including any updates)
      try {
        final reloadedPlan = await getJourneyPlanByIdUseCase(
          state.journeyPlan!.id,
        );
        if (kDebugMode) {
          if (reloadedPlan.stops.isNotEmpty) {
            final lastStop = reloadedPlan.stops.last;
            if (lastStop.visit != null) {
              print('📍 Reloaded visit ID: ${lastStop.visit!.id}');
              print(
                '📍 Reloaded visit googleMapsLink: ${lastStop.visit!.googleMapsLink}',
              );
            }
          }
        }
        if (!isClosed) {
          emit(
            state.copyWith(
              isLoading: false,
              journeyPlan: reloadedPlan,
              clearError: true,
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Failed to reload journey plan: $e');
        }
        // Fallback to using the updated plan if reload fails
        if (!isClosed) {
          emit(
            state.copyWith(
              isLoading: false,
              journeyPlan: updatedPlan,
              clearError: true,
            ),
          );
        }
      }
    } on Failure catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.message),
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(null),
          ),
        );
      }
    }
  }

  Future<int> createBulkStopsAndVisits({
    required List<BulkVisitCustomerRequestModel> customers,
    Map<String, String?>? customerGoogleMapsLinks,
  }) async {
    if (state.journeyPlan == null || customers.isEmpty) return 0;

    if (isClosed) return 0;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final response = await createBulkVisitsUseCase(
        CreateBulkVisitsParams(
          journeyPlanId: state.journeyPlan!.id,
          request: CreateBulkVisitsRequestModel(customers: customers),
        ),
      );

      final normalizedLinks = <String, String>{};
      if (customerGoogleMapsLinks != null) {
        for (final entry in customerGoogleMapsLinks.entries) {
          final key = entry.key.trim().toLowerCase();
          final value = entry.value?.trim();
          if (key.isNotEmpty && value != null && value.isNotEmpty) {
            normalizedLinks[key] = value;
          }
        }
      }

      final patchedStops =
          response.journeyPlan.stops.map((stop) {
            final visit = stop.visit;
            if (visit == null) return stop;
            final code = (visit.customerCode ?? '').trim().toLowerCase();
            final fallbackLink = normalizedLinks[code];
            if (fallbackLink == null || fallbackLink.isEmpty) return stop;
            return StopModel(
              id: stop.id,
              visitId: stop.visitId,
              sequenceNo: stop.sequenceNo,
              plannedTime: stop.plannedTime,
              estimatedDurationMinutes: stop.estimatedDurationMinutes,
              visit: VisitModel(
                id: visit.id,
                userId: visit.userId,
                userName: visit.userName,
                customerId: visit.customerId,
                customerName: visit.customerName,
                customerCode: visit.customerCode,
                journeyPlanId: visit.journeyPlanId,
                plannedDateTime: visit.plannedDateTime,
                actualStartDateTime: visit.actualStartDateTime,
                actualEndDateTime: visit.actualEndDateTime,
                visitType: visit.visitType,
                status: visit.status,
                supervisorId: visit.supervisorId,
                supervisorName: visit.supervisorName,
                checkInLatitude: visit.checkInLatitude,
                checkInLongitude: visit.checkInLongitude,
                checkOutLatitude: visit.checkOutLatitude,
                checkOutLongitude: visit.checkOutLongitude,
                notes: visit.notes,
                googleMapsLink:
                    (visit.googleMapsLink?.trim().isNotEmpty ?? false)
                        ? visit.googleMapsLink
                        : fallbackLink,
                createdAt: visit.createdAt,
                actions: visit.actions,
              ),
            );
          }).toList();

      final patchedPlan = JourneyPlanModel(
        id: response.journeyPlan.id,
        userId: response.journeyPlan.userId,
        userName: response.journeyPlan.userName,
        createdByUserId: response.journeyPlan.createdByUserId,
        createdByUserName: response.journeyPlan.createdByUserName,
        createdBy: response.journeyPlan.createdBy,
        planType: response.journeyPlan.planType,
        startDate: response.journeyPlan.startDate,
        endDate: response.journeyPlan.endDate,
        notes: response.journeyPlan.notes,
        isApproved: response.journeyPlan.isApproved,
        approvedAt: response.journeyPlan.approvedAt,
        stops: patchedStops,
        createdAt: response.journeyPlan.createdAt,
      );

      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            journeyPlan: patchedPlan,
            clearError: true,
          ),
        );
      }

      return response.created.length;
    } on Failure catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.message),
          ),
        );
      }
      return 0;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(null),
          ),
        );
      }
      return 0;
    }
  }

  /// Creates a visit not linked to a journey plan (standalone visit).
  /// Uses POST /api/Visits.
  Future<void> createStandaloneVisit({
    required String userId,
    required String customerCode,
    required String customerName,
    required DateTime plannedDateTime,
    required int visitType,
    String? supervisorId,
    String? notes,
    String? googleMapsLink,
  }) async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final request = CreateVisitRequestModel(
        userId: userId,
        customerCode: customerCode,
        customerName: customerName,
        plannedDateTime: plannedDateTime,
        visitType: visitType,
        supervisorId: supervisorId,
        googleMapsLink: googleMapsLink,
        notes: notes,
      );

      await createVisitUseCase(request);

      if (!isClosed) {
        emit(state.copyWith(isLoading: false, clearError: true));
      }
    } on Failure catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.message),
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(null),
          ),
        );
      }
    }
  }

  Future<void> updateStop({
    required String stopId,
    required String visitId,
    required int sequenceNo,
    required DateTime plannedTime,
    required int estimatedDurationMinutes,
  }) async {
    if (state.journeyPlan == null) return;
    if (isClosed) return;

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final request = UpdateStopRequestModel(
        visitId: visitId,
        sequenceNo: sequenceNo,
        plannedTime: plannedTime,
        estimatedDurationMinutes: estimatedDurationMinutes,
      );

      final updatedPlan = await updateStopUseCase(
        UpdateStopParams(
          journeyPlanId: state.journeyPlan!.id,
          stopId: stopId,
          request: request,
        ),
      );

      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            journeyPlan: updatedPlan,
            clearError: true,
          ),
        );
      }
    } on Failure catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.message),
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(null),
          ),
        );
      }
    }
  }

  Future<void> updateVisit({
    required String visitId,
    String? googleMapsLink,
    String? notes,
  }) async {
    if (state.journeyPlan == null) return;

    if (isClosed) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final request = UpdateVisitRequestModel(
        googleMapsLink: googleMapsLink,
        notes: notes,
      );

      await updateVisitUseCase(
        UpdateVisitParams(visitId: visitId, request: request),
      );

      // Reload the journey plan to get updated visit data
      final updatedPlan = await getJourneyPlanByIdUseCase(
        state.journeyPlan!.id,
      );

      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            journeyPlan: updatedPlan,
            clearError: true,
          ),
        );
      }
    } on Failure catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.message),
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(null),
          ),
        );
      }
    }
  }

  Future<void> updateVisitSupervisorAndType({
    required String visitId,
    String? supervisorId, // Made nullable to allow removal
    required int visitType,
  }) async {
    if (isClosed) return;

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final request = UpdateVisitSupervisorAndTypeRequestModel(
        supervisorId: supervisorId,
        visitType: visitType,
      );

      await updateVisitSupervisorAndTypeUseCase(
        UpdateVisitSupervisorAndTypeParams(visitId: visitId, request: request),
      );

      // Reload the current journey plan (if any) so the open detail screen
      // immediately reflects the new supervisor / visit type.
      if (state.journeyPlan != null) {
        final updatedPlan = await getJourneyPlanByIdUseCase.call(
          state.journeyPlan!.id,
        );
        if (!isClosed) {
          emit(state.copyWith(journeyPlan: updatedPlan, clearError: true));
        }
      }

      // Refresh the "My Visits" list so a supervisor that just self-assigned
      // sees the visit appear in their tab without a manual reload. We pass
      // supervisorId so the request matches what the journey plan page uses
      // for the supervisor "My Visits" tab.
      if (supervisorId != null && supervisorId.isNotEmpty) {
        // Best-effort: reuse the current visit status filter so the list
        // doesn't suddenly broaden / narrow vs. what the user was looking at.
        unawaited(
          loadVisits(
            supervisorId: supervisorId,
            status: state.visitStatusFilter,
          ),
        );
      }

      // Refresh the journey plans list with the currently active filters so
      // any tab listening to `journeyPlans` updates after assignment/removal.
      unawaited(
        loadJourneyPlans(
          userId: state.filterUserId,
          supervisorId: state.filterSupervisorId,
          customerId: state.filterCustomerId,
          startDate: state.filterStartDate,
          endDate: state.filterEndDate,
        ),
      );

      if (!isClosed) {
        emit(state.copyWith(isLoading: false, clearError: true));
      }
    } on Failure catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.message),
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(null),
          ),
        );
      }
    }
  }

  void selectCustomer(Customer? customer) {
    if (customer == null) {
      emit(state.copyWith(clearSelectedCustomer: true));
    } else {
      emit(state.copyWith(selectedCustomer: customer));
    }
  }

  /// Loads ODBC customers (`/api/MasterData/customers/odbc`) in pages of [pageSize]
  /// until a short page or [maxPages] is reached (default: one request per call).
  Future<void> loadCustomers({
    String? search,
    String? stateFilter,
    String? city,
    bool? activeOnly,
    int pageSize = 50,
    int maxPages = 1,
  }) async {
    final online = await connectivityService.isOnline;
    if (!online) {
      if (!isClosed) {
        emit(state.copyWith(isLoadingCustomers: false));
      }
      return;
    }
    emit(state.copyWith(isLoadingCustomers: true, customersErrorMessage: null));

    try {
      final all = <Customer>[];
      for (var page = 1; page <= maxPages; page++) {
        final batch = await getCustomersUseCase(
          GetCustomersParams(
            search: search,
            state: stateFilter,
            city: city,
            activeOnly: activeOnly,
            pageNumber: page,
            pageSize: pageSize,
          ),
        );
        all.addAll(batch);
        if (batch.length < pageSize) break;
      }

      if (!isClosed) {
        emit(state.copyWith(isLoadingCustomers: false, customers: all));
      }
    } on Failure catch (e) {
      emit(
        state.copyWith(
          isLoadingCustomers: false,
          customersErrorMessage: userFriendlyErrorMessage(e.message),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingCustomers: false,
          customersErrorMessage: 'Failed to load customers',
        ),
      );
    }
  }

  void reset() {
    emit(JourneyPlanState.initial());
  }

  /// Pops to root if needed, then [HomePage] should switch tab via [pendingHomeTabIndex].
  void requestOpenHomeTab(int bottomNavIndex) {
    if (isClosed) return;
    emit(state.copyWith(pendingHomeTabIndex: bottomNavIndex));
  }

  void clearPendingHomeTab() {
    if (isClosed) return;
    if (state.pendingHomeTabIndex == null) return;
    emit(state.copyWith(clearPendingHomeTab: true));
  }

  Future<void> reopenJourneyPlanForActiveVisit(
    String journeyPlanId, {
    String? currentUserId,
    bool? isSupervisor,
    String? visitId,
  }) async {
    if (isClosed) return;

    if (state.showCreateForm) {
      hideCreateForm();
    }

    await Future<void>.delayed(Duration.zero);
    if (isClosed) return;

    await loadJourneyPlanForEdit(
      journeyPlanId,
      currentUserId: currentUserId,
      isSupervisor: isSupervisor,
    );

    if (isClosed) return;
    if (state.editingJourneyPlanId == journeyPlanId &&
        state.journeyPlan != null &&
        state.showCreateForm) {
      emit(state.copyWith(currentStep: 2, pendingScrollToVisitId: visitId));
    }
  }

  void clearPendingScrollToVisit() {
    if (isClosed || state.pendingScrollToVisitId == null) return;
    emit(state.copyWith(clearPendingScrollToVisitId: true));
  }

  void showCreateForm() {
    if (isClosed) return;
    emit(
      state.copyWith(
        showCreateForm: true,
        currentStep: 1,
        isEditing: false,
        editingJourneyPlanId: null,
        planType: 1,
        startDate: null,
        endDate: null,
        notes: '',
        clearJourneyPlan: true,
        createForMyself: true,
        selectedSubordinate: null,
        isViewOnly: false,
      ),
    );
  }

  void hideCreateForm() {
    if (isClosed) return;
    final preservedVisits = _mergeActiveOngoingVisitsIntoList(state.visits);
    emit(
      state.copyWith(
        isEditing: false,
        editingJourneyPlanId: null,
        showCreateForm: false,
        currentStep: 1,
        planType: 1,
        startDate: null,
        endDate: null,
        notes: '',
        visits: preservedVisits,
        clearJourneyPlan: true,
        isViewOnly: false,
      ),
    );
    unawaited(persistActiveVisitSnapshot());
  }

  void setFilters({
    String? userId,
    String? supervisorId,
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
    bool clearCustomerId = false,
  }) {
    emit(
      state.copyWith(
        filterUserId: userId,
        filterSupervisorId: supervisorId,
        filterCustomerId:
            clearCustomerId ? null : (customerId ?? state.filterCustomerId),
        filterStartDate: startDate,
        filterEndDate: endDate,
      ),
    );
  }

  void clearFilters() {
    emit(state.copyWith(clearFilters: true));
  }

  /// Admin: Select a supervisor → goes to subordinates level
  void selectSupervisorForAdmin(String supervisorId) {
    emit(
      state.copyWith(
        filterSupervisorId: supervisorId,
        // Clear subordinate selection and journey plans
        journeyPlans: [],
      ),
    );
  }

  /// Admin: Select a subordinate (sales employee) → goes to journey plans level
  void selectSubordinateForAdmin(String subordinateId) {
    emit(state.copyWith(filterUserId: subordinateId, journeyPlans: []));
  }

  /// Admin: Go back to supervisor list (clear everything)
  void clearSupervisorSelection() {
    emit(
      state.copyWith(clearFilters: true, journeyPlans: [], subordinates: []),
    );
  }

  /// Admin: Go back to subordinates list (clear user selection, keep supervisor)
  void clearSubordinateSelection() {
    emit(
      state.copyWith(
        clearFilterUserId: true,
        journeyPlans: [],
        clearJourneyPlansError: true,
      ),
    );
  }

  Future<void> loadJourneyPlans({
    String? userId,
    String? createdById,
    String? supervisorId,
    String? customerId,
    int? planType,
    DateTime? startDate,
    DateTime? endDate,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    if (isClosed) return;
    final online = await connectivityService.isOnline;
    if (!online) {
      final cached = await localDataSource.getCachedJourneyPlans();
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoadingJourneyPlans: false,
            journeyPlans: cached,
            clearJourneyPlansError: true,
          ),
        );
      }
      return;
    }
    final cached = await localDataSource.getCachedJourneyPlans();
    if (cached.isNotEmpty && state.journeyPlans.isEmpty && !isClosed) {
      emit(state.copyWith(journeyPlans: cached, clearJourneyPlansError: true));
    }
    emit(
      state.copyWith(isLoadingJourneyPlans: true, clearJourneyPlansError: true),
    );

    try {
      // Use filter values if provided, otherwise use state filters
      final filterUserId = userId ?? state.filterUserId;
      final filterSupervisorId = supervisorId ?? state.filterSupervisorId;
      final filterCustomerId = customerId ?? state.filterCustomerId;
      final filterStartDate = startDate ?? state.filterStartDate;
      final filterEndDate = endDate ?? state.filterEndDate;

      // If a specific userId is set, don't also send supervisorId
      // (supervisorId returns ALL JPs under that supervisor, overriding userId filter)
      final effectiveUserId = filterUserId;
      final effectiveSupervisorId =
          filterUserId != null ? null : filterSupervisorId;

      print(
        '📋 loadJourneyPlans: userId=$effectiveUserId, supervisorId=$effectiveSupervisorId, customerId=$filterCustomerId',
      );

      final response = await getJourneyPlansUseCase(
        GetJourneyPlansParams(
          userId: effectiveUserId,
          createdById: createdById,
          supervisorId: effectiveSupervisorId,
          customerId: filterCustomerId,
          planType: planType,
          startDate: filterStartDate,
          endDate: filterEndDate,
          pageNumber: pageNumber,
          pageSize: pageSize,
        ),
      );

      print('📋 loadJourneyPlans: Got ${response.items.length} items');

      if (!isClosed) {
        final hydrated = _hydrateJourneyPlansFromLocalTiming(response.items);
        await localDataSource.saveCachedJourneyPlans(hydrated);
        emit(
          state.copyWith(
            isLoadingJourneyPlans: false,
            journeyPlans: hydrated,
            clearJourneyPlansError: true,
          ),
        );
      }
    } on Failure catch (e) {
      print('❌ loadJourneyPlans Failure: ${e.message}');
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoadingJourneyPlans: false,
            journeyPlansErrorMessage: userFriendlyErrorMessage(e.message),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ loadJourneyPlans Exception: $e');
      print('❌ StackTrace: $stackTrace');
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoadingJourneyPlans: false,
            journeyPlansErrorMessage: userFriendlyErrorMessage(e.toString()),
          ),
        );
      }
    }
  }

  void setSelectedTab(int tabIndex) {
    if (isClosed) return;
    emit(state.copyWith(selectedTabIndex: tabIndex));
  }

  void setVisitStatusFilter(int? status, {String? supervisorId}) {
    if (isClosed) return;
    emit(state.copyWith(visitStatusFilter: status));
    // Reload visits with new status filter
    if (supervisorId != null) {
      loadVisits(supervisorId: supervisorId, status: status);
    }
  }

  void setPlanViewFilter(String? filter) {
    if (isClosed) return;
    emit(state.copyWith(planViewFilter: filter));
  }

  Future<void> startVisit(
    String visitId, {
    double? latitude,
    double? longitude,
  }) async {
    if (isClosed) return;
    final online = await connectivityService.isOnline;
    if (!online) {
      await _applyOfflineVisitAction(
        visitId: visitId,
        action: 'checkIn',
        newStatus: 2,
        setActualStart: true,
        setActualEnd: false,
        checkInLat: latitude,
        checkInLng: longitude,
        checkOutLat: null,
        checkOutLng: null,
      );
      return;
    }
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final request = CheckInVisitRequestModel(
        latitude: latitude,
        longitude: longitude,
      );

      await checkInVisitUseCase(
        CheckInVisitParams(visitId: visitId, request: request),
      );

      final currentPlan = state.journeyPlan;
      if (currentPlan != null &&
          currentPlan.stops.any((s) => s.visit?.id == visitId)) {
        final now = DateTime.now();
        final updatedStops =
            currentPlan.stops.map((stop) {
              final visit = stop.visit;
              if (visit == null || visit.id != visitId) {
                return stop;
              }

              final updatedVisit = VisitModel(
                id: visit.id,
                userId: visit.userId,
                userName: visit.userName,
                customerId: visit.customerId,
                customerName: visit.customerName,
                customerCode: visit.customerCode,
                journeyPlanId: visit.journeyPlanId,
                plannedDateTime: visit.plannedDateTime,
                actualStartDateTime: visit.actualStartDateTime ?? now,
                actualEndDateTime: visit.actualEndDateTime,
                visitType: visit.visitType,
                status: 2,
                supervisorId: visit.supervisorId,
                supervisorName: visit.supervisorName,
                checkInLatitude: latitude ?? visit.checkInLatitude,
                checkInLongitude: longitude ?? visit.checkInLongitude,
                checkOutLatitude: visit.checkOutLatitude,
                checkOutLongitude: visit.checkOutLongitude,
                notes: visit.notes,
                googleMapsLink: visit.googleMapsLink,
                createdAt: visit.createdAt,
                actions: visit.actions,
              );

              return StopModel(
                id: stop.id,
                visitId: stop.visitId,
                sequenceNo: stop.sequenceNo,
                plannedTime: stop.plannedTime,
                estimatedDurationMinutes: stop.estimatedDurationMinutes,
                visit: updatedVisit,
              );
            }).toList();

        final optimisticPlan = JourneyPlanModel(
          id: currentPlan.id,
          userId: currentPlan.userId,
          userName: currentPlan.userName,
          createdByUserId: currentPlan.createdByUserId,
          createdByUserName: currentPlan.createdByUserName,
          createdBy: currentPlan.createdBy,
          planType: currentPlan.planType,
          startDate: currentPlan.startDate,
          endDate: currentPlan.endDate,
          notes: currentPlan.notes,
          isApproved: currentPlan.isApproved,
          approvedAt: currentPlan.approvedAt,
          stops: updatedStops,
          createdAt: currentPlan.createdAt,
        );

        if (!isClosed) {
          await localDataSource.saveCachedCurrentPlan(optimisticPlan);
          final updatedVisit = updatedStops
              .map((stop) => stop.visit)
              .whereType<VisitModel>()
              .firstWhere((visit) => visit.id == visitId);
          final newVisits = _replaceVisitInVisitsList(
            state.visits,
            visitId,
            updatedVisit,
          );
          final newActualStart = Map<String, int>.from(
            state.actualStartTimestampMs,
          );
          if (updatedVisit.actualStartDateTime != null) {
            newActualStart[visitId] =
                updatedVisit.actualStartDateTime!.millisecondsSinceEpoch;
          }
          await localDataSource.saveCachedVisits(
            newVisits.map((visit) => visit as VisitModel).toList(),
          );
          emit(
            state.copyWith(
              isLoading: false,
              journeyPlan: optimisticPlan,
              visits: newVisits,
              actualStartTimestampMs: newActualStart,
              clearError: true,
            ),
          );
          await _persistVisitTimingState(
            actualStartTimestampMs: newActualStart,
          );
        }
      } else {
        if (!isClosed) {
          final idx = state.visits.indexWhere((v) => v.id == visitId);
          if (idx >= 0) {
            final visit = state.visits[idx];
            final now = DateTime.now();
            final updatedVisit = VisitModel(
              id: visit.id,
              userId: visit.userId,
              userName: visit.userName,
              customerId: visit.customerId,
              customerName: visit.customerName,
              customerCode: visit.customerCode,
              journeyPlanId: visit.journeyPlanId,
              plannedDateTime: visit.plannedDateTime,
              actualStartDateTime: visit.actualStartDateTime ?? now,
              actualEndDateTime: visit.actualEndDateTime,
              visitType: visit.visitType,
              status: 2,
              supervisorId: visit.supervisorId,
              supervisorName: visit.supervisorName,
              checkInLatitude: latitude ?? visit.checkInLatitude,
              checkInLongitude: longitude ?? visit.checkInLongitude,
              checkOutLatitude: visit.checkOutLatitude,
              checkOutLongitude: visit.checkOutLongitude,
              notes: visit.notes,
              googleMapsLink: visit.googleMapsLink,
              createdAt: visit.createdAt,
              actions: visit.actions,
            );
            final newVisits = _replaceVisitInVisitsList(
              state.visits,
              visitId,
              updatedVisit,
            );
            final newActualStart = Map<String, int>.from(
              state.actualStartTimestampMs,
            );
            if (updatedVisit.actualStartDateTime != null) {
              newActualStart[visitId] =
                  updatedVisit.actualStartDateTime!.millisecondsSinceEpoch;
            }
            await localDataSource.saveCachedVisits(
              newVisits.map((visit) => visit as VisitModel).toList(),
            );
            emit(
              state.copyWith(
                isLoading: false,
                visits: newVisits,
                actualStartTimestampMs: newActualStart,
                clearError: true,
              ),
            );
            await _persistVisitTimingState(
              pausedVisitElapsedSeconds: const {},
              pauseStartTimestampMs: const {},
              totalPausedDurationSeconds: const {},
              actualStartTimestampMs: newActualStart,
            );
          } else {
            emit(state.copyWith(isLoading: false, clearError: true));
          }
        }
      }
    } on Failure catch (e) {
      if (!isClosed &&
          _isCheckInResponseSerializationBug(e.message) &&
          await _tryRecoverCheckInAfterBadResponse(
            visitId,
            latitude,
            longitude,
          )) {
        return;
      }
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.message),
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.toString()),
          ),
        );
      }
    }
  }

  Future<void> checkInVisit(
    String visitId, {
    double? latitude,
    double? longitude,
  }) async {
    if (isClosed) return;
    final online = await connectivityService.isOnline;
    if (!online) {
      await _applyOfflineVisitAction(
        visitId: visitId,
        action: 'checkIn',
        newStatus: 2,
        setActualStart: true,
        setActualEnd: false,
        checkInLat: latitude,
        checkInLng: longitude,
        checkOutLat: null,
        checkOutLng: null,
      );
      return;
    }
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final request = CheckInVisitRequestModel(
        latitude: latitude,
        longitude: longitude,
      );

      await checkInVisitUseCase(
        CheckInVisitParams(visitId: visitId, request: request),
      );

      final currentPlan = state.journeyPlan;
      if (currentPlan != null &&
          currentPlan.stops.any((s) => s.visit?.id == visitId)) {
        final now = DateTime.now();
        final updatedStops =
            currentPlan.stops.map((stop) {
              final visit = stop.visit;
              if (visit == null || visit.id != visitId) {
                return stop;
              }

              final updatedVisit = VisitModel(
                id: visit.id,
                userId: visit.userId,
                userName: visit.userName,
                customerId: visit.customerId,
                customerName: visit.customerName,
                customerCode: visit.customerCode,
                journeyPlanId: visit.journeyPlanId,
                plannedDateTime: visit.plannedDateTime,
                actualStartDateTime: visit.actualStartDateTime ?? now,
                actualEndDateTime: visit.actualEndDateTime,
                visitType: visit.visitType,
                status: 2,
                supervisorId: visit.supervisorId,
                supervisorName: visit.supervisorName,
                checkInLatitude: latitude ?? visit.checkInLatitude,
                checkInLongitude: longitude ?? visit.checkInLongitude,
                checkOutLatitude: visit.checkOutLatitude,
                checkOutLongitude: visit.checkOutLongitude,
                notes: visit.notes,
                googleMapsLink: visit.googleMapsLink,
                createdAt: visit.createdAt,
                actions: visit.actions,
              );

              return StopModel(
                id: stop.id,
                visitId: stop.visitId,
                sequenceNo: stop.sequenceNo,
                plannedTime: stop.plannedTime,
                estimatedDurationMinutes: stop.estimatedDurationMinutes,
                visit: updatedVisit,
              );
            }).toList();

        final optimisticPlan = JourneyPlanModel(
          id: currentPlan.id,
          userId: currentPlan.userId,
          userName: currentPlan.userName,
          createdByUserId: currentPlan.createdByUserId,
          createdByUserName: currentPlan.createdByUserName,
          createdBy: currentPlan.createdBy,
          planType: currentPlan.planType,
          startDate: currentPlan.startDate,
          endDate: currentPlan.endDate,
          notes: currentPlan.notes,
          isApproved: currentPlan.isApproved,
          approvedAt: currentPlan.approvedAt,
          stops: updatedStops,
          createdAt: currentPlan.createdAt,
        );

        if (!isClosed) {
          await localDataSource.saveCachedCurrentPlan(optimisticPlan);
          final updatedVisit = updatedStops
              .map((stop) => stop.visit)
              .whereType<VisitModel>()
              .firstWhere((visit) => visit.id == visitId);
          final newVisits = _replaceVisitInVisitsList(
            state.visits,
            visitId,
            updatedVisit,
          );
          await localDataSource.saveCachedVisits(
            newVisits.map((visit) => visit as VisitModel).toList(),
          );
          final checkInTiming = _timingMapsForCheckIn(visitId, now);
          emit(
            state.copyWith(
              isLoading: false,
              journeyPlan: optimisticPlan,
              visits: newVisits,
              actualStartTimestampMs: checkInTiming.actualStartTimestampMs,
              activeVisitElapsedSeconds:
                  checkInTiming.activeVisitElapsedSeconds,
              activeVisitSnapshotTimestampMs:
                  checkInTiming.activeVisitSnapshotTimestampMs,
              endedVisitElapsedSeconds: checkInTiming.endedVisitElapsedSeconds,
              clearError: true,
            ),
          );
          await _persistVisitTimingState(
            actualStartTimestampMs: checkInTiming.actualStartTimestampMs,
            activeVisitElapsedSeconds: checkInTiming.activeVisitElapsedSeconds,
            activeVisitSnapshotTimestampMs:
                checkInTiming.activeVisitSnapshotTimestampMs,
            endedVisitElapsedSeconds: checkInTiming.endedVisitElapsedSeconds,
          );
        }
      } else {
        if (!isClosed) {
          final idx = state.visits.indexWhere((v) => v.id == visitId);
          if (idx >= 0) {
            final visit = state.visits[idx];
            final now = DateTime.now();
            final updatedVisit = VisitModel(
              id: visit.id,
              userId: visit.userId,
              userName: visit.userName,
              customerId: visit.customerId,
              customerName: visit.customerName,
              customerCode: visit.customerCode,
              journeyPlanId: visit.journeyPlanId,
              plannedDateTime: visit.plannedDateTime,
              actualStartDateTime: visit.actualStartDateTime ?? now,
              actualEndDateTime: visit.actualEndDateTime,
              visitType: visit.visitType,
              status: 2,
              supervisorId: visit.supervisorId,
              supervisorName: visit.supervisorName,
              checkInLatitude: latitude ?? visit.checkInLatitude,
              checkInLongitude: longitude ?? visit.checkInLongitude,
              checkOutLatitude: visit.checkOutLatitude,
              checkOutLongitude: visit.checkOutLongitude,
              notes: visit.notes,
              googleMapsLink: visit.googleMapsLink,
              createdAt: visit.createdAt,
              actions: visit.actions,
            );
            final newVisits = _replaceVisitInVisitsList(
              state.visits,
              visitId,
              updatedVisit,
            );
            await localDataSource.saveCachedVisits(
              newVisits.map((visit) => visit as VisitModel).toList(),
            );
            final checkInTiming = _timingMapsForCheckIn(visitId, now);
            emit(
              state.copyWith(
                isLoading: false,
                visits: newVisits,
                actualStartTimestampMs: checkInTiming.actualStartTimestampMs,
                activeVisitElapsedSeconds:
                    checkInTiming.activeVisitElapsedSeconds,
                activeVisitSnapshotTimestampMs:
                    checkInTiming.activeVisitSnapshotTimestampMs,
                endedVisitElapsedSeconds:
                    checkInTiming.endedVisitElapsedSeconds,
                clearError: true,
              ),
            );
            await _persistVisitTimingState(
              actualStartTimestampMs: checkInTiming.actualStartTimestampMs,
              activeVisitElapsedSeconds:
                  checkInTiming.activeVisitElapsedSeconds,
              activeVisitSnapshotTimestampMs:
                  checkInTiming.activeVisitSnapshotTimestampMs,
              endedVisitElapsedSeconds: checkInTiming.endedVisitElapsedSeconds,
            );
          } else {
            emit(state.copyWith(isLoading: false, clearError: true));
          }
        }
      }
    } on Failure catch (e) {
      if (!isClosed &&
          _isCheckInResponseSerializationBug(e.message) &&
          await _tryRecoverCheckInAfterBadResponse(
            visitId,
            latitude,
            longitude,
          )) {
        return;
      }
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.message),
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.toString()),
          ),
        );
      }
    }
  }

  Future<void> checkOutVisit(
    String visitId, {
    double? latitude,
    double? longitude,
  }) async {
    if (isClosed) return;
    final online = await connectivityService.isOnline;
    if (!online) {
      await _applyOfflineVisitAction(
        visitId: visitId,
        action: 'checkOut',
        newStatus: VisitExecutionStatus.completed,
        setActualStart: false,
        setActualEnd: true,
        checkInLat: null,
        checkInLng: null,
        checkOutLat: latitude,
        checkOutLng: longitude,
      );
      return;
    }
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final visit = _findVisitById(visitId);
      final durationSeconds =
          visit == null ? 0 : _computeActualDurationSeconds(visit);
      final request = CheckOutVisitRequestModel(
        latitude: latitude,
        longitude: longitude,
        actualDurationSeconds: durationSeconds,
        actualDuration: _formatDurationHms(durationSeconds),
      );

      await checkOutVisitUseCase(
        CheckOutVisitParams(visitId: visitId, request: request),
      );

      final currentPlan = state.journeyPlan;
      if (currentPlan != null &&
          currentPlan.stops.any((s) => s.visit?.id == visitId)) {
        final now = DateTime.now();
        final updatedStops =
            currentPlan.stops.map((stop) {
              final visit = stop.visit;
              if (visit == null || visit.id != visitId) {
                return stop;
              }

              final updatedVisit = VisitModel(
                id: visit.id,
                userId: visit.userId,
                userName: visit.userName,
                customerId: visit.customerId,
                customerName: visit.customerName,
                customerCode: visit.customerCode,
                journeyPlanId: visit.journeyPlanId,
                plannedDateTime: visit.plannedDateTime,
                actualStartDateTime: visit.actualStartDateTime ?? now,
                actualEndDateTime: now,
                visitType: visit.visitType,
                status: VisitExecutionStatus.completed,
                supervisorId: visit.supervisorId,
                supervisorName: visit.supervisorName,
                checkInLatitude: visit.checkInLatitude,
                checkInLongitude: visit.checkInLongitude,
                checkOutLatitude: latitude ?? visit.checkOutLatitude,
                checkOutLongitude: longitude ?? visit.checkOutLongitude,
                notes: visit.notes,
                googleMapsLink: visit.googleMapsLink,
                createdAt: visit.createdAt,
                actions: visit.actions,
              );

              return StopModel(
                id: stop.id,
                visitId: stop.visitId,
                sequenceNo: stop.sequenceNo,
                plannedTime: stop.plannedTime,
                estimatedDurationMinutes: stop.estimatedDurationMinutes,
                visit: updatedVisit,
              );
            }).toList();

        final optimisticPlan = JourneyPlanModel(
          id: currentPlan.id,
          userId: currentPlan.userId,
          userName: currentPlan.userName,
          createdByUserId: currentPlan.createdByUserId,
          createdByUserName: currentPlan.createdByUserName,
          createdBy: currentPlan.createdBy,
          planType: currentPlan.planType,
          startDate: currentPlan.startDate,
          endDate: currentPlan.endDate,
          notes: currentPlan.notes,
          isApproved: currentPlan.isApproved,
          approvedAt: currentPlan.approvedAt,
          stops: updatedStops,
          createdAt: currentPlan.createdAt,
        );

        if (!isClosed) {
          await localDataSource.saveCachedCurrentPlan(optimisticPlan);
          final checkoutTiming = _timingMapsForCheckOut(
            visitId,
            durationSeconds,
          );
          final updatedVisit = updatedStops
              .map((stop) => stop.visit)
              .whereType<VisitModel>()
              .firstWhere((visit) => visit.id == visitId);
          final newVisits = _replaceVisitInVisitsList(
            state.visits,
            visitId,
            updatedVisit,
          );
          await localDataSource.saveCachedVisits(
            newVisits.map((visit) => visit as VisitModel).toList(),
          );
          emit(
            state.copyWith(
              isLoading: false,
              journeyPlan: optimisticPlan,
              visits: newVisits,
              pausedVisitElapsedSeconds:
                  checkoutTiming.pausedVisitElapsedSeconds,
              pauseStartTimestampMs: checkoutTiming.pauseStartTimestampMs,
              totalPausedDurationSeconds:
                  checkoutTiming.totalPausedDurationSeconds,
              actualStartTimestampMs: checkoutTiming.actualStartTimestampMs,
              activeVisitElapsedSeconds:
                  checkoutTiming.activeVisitElapsedSeconds,
              activeVisitSnapshotTimestampMs:
                  checkoutTiming.activeVisitSnapshotTimestampMs,
              endedVisitElapsedSeconds: checkoutTiming.endedVisitElapsedSeconds,
              clearError: true,
            ),
          );
          await _persistVisitTimingState(
            pausedVisitElapsedSeconds: checkoutTiming.pausedVisitElapsedSeconds,
            pauseStartTimestampMs: checkoutTiming.pauseStartTimestampMs,
            totalPausedDurationSeconds:
                checkoutTiming.totalPausedDurationSeconds,
            actualStartTimestampMs: checkoutTiming.actualStartTimestampMs,
            activeVisitElapsedSeconds: checkoutTiming.activeVisitElapsedSeconds,
            activeVisitSnapshotTimestampMs:
                checkoutTiming.activeVisitSnapshotTimestampMs,
            endedVisitElapsedSeconds: checkoutTiming.endedVisitElapsedSeconds,
          );
        }
      } else {
        if (!isClosed) {
          final idx = state.visits.indexWhere((v) => v.id == visitId);
          if (idx >= 0) {
            final visit = state.visits[idx];
            final now = DateTime.now();
            final checkoutTiming = _timingMapsForCheckOut(
              visitId,
              durationSeconds,
            );
            final updatedVisit = VisitModel(
              id: visit.id,
              userId: visit.userId,
              userName: visit.userName,
              customerId: visit.customerId,
              customerName: visit.customerName,
              customerCode: visit.customerCode,
              journeyPlanId: visit.journeyPlanId,
              plannedDateTime: visit.plannedDateTime,
              actualStartDateTime: visit.actualStartDateTime,
              actualEndDateTime: now,
              visitType: visit.visitType,
              status: VisitExecutionStatus.completed,
              supervisorId: visit.supervisorId,
              supervisorName: visit.supervisorName,
              checkInLatitude: visit.checkInLatitude,
              checkInLongitude: visit.checkInLongitude,
              checkOutLatitude: latitude ?? visit.checkOutLatitude,
              checkOutLongitude: longitude ?? visit.checkOutLongitude,
              notes: visit.notes,
              googleMapsLink: visit.googleMapsLink,
              createdAt: visit.createdAt,
              actions: visit.actions,
            );
            final newVisits = _replaceVisitInVisitsList(
              state.visits,
              visitId,
              updatedVisit,
            );
            await localDataSource.saveCachedVisits(
              newVisits.map((visit) => visit as VisitModel).toList(),
            );
            emit(
              state.copyWith(
                isLoading: false,
                visits: newVisits,
                pausedVisitElapsedSeconds:
                    checkoutTiming.pausedVisitElapsedSeconds,
                pauseStartTimestampMs: checkoutTiming.pauseStartTimestampMs,
                totalPausedDurationSeconds:
                    checkoutTiming.totalPausedDurationSeconds,
                actualStartTimestampMs: checkoutTiming.actualStartTimestampMs,
                activeVisitElapsedSeconds:
                    checkoutTiming.activeVisitElapsedSeconds,
                activeVisitSnapshotTimestampMs:
                    checkoutTiming.activeVisitSnapshotTimestampMs,
                endedVisitElapsedSeconds:
                    checkoutTiming.endedVisitElapsedSeconds,
                clearError: true,
              ),
            );
            await _persistVisitTimingState(
              pausedVisitElapsedSeconds:
                  checkoutTiming.pausedVisitElapsedSeconds,
              pauseStartTimestampMs: checkoutTiming.pauseStartTimestampMs,
              totalPausedDurationSeconds:
                  checkoutTiming.totalPausedDurationSeconds,
              actualStartTimestampMs: checkoutTiming.actualStartTimestampMs,
              activeVisitElapsedSeconds:
                  checkoutTiming.activeVisitElapsedSeconds,
              activeVisitSnapshotTimestampMs:
                  checkoutTiming.activeVisitSnapshotTimestampMs,
              endedVisitElapsedSeconds: checkoutTiming.endedVisitElapsedSeconds,
            );
          } else {
            emit(state.copyWith(isLoading: false, clearError: true));
          }
        }
      }
    } on Failure catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.message),
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.toString()),
          ),
        );
      }
    }
  }

  Future<void> pauseVisit(String visitId) async {
    if (isClosed) return;
    final online = await connectivityService.isOnline;
    if (!online) {
      await _applyOfflineVisitAction(
        visitId: visitId,
        action: 'pause',
        newStatus: VisitExecutionStatus.inProgress,
        setActualStart: false,
        setActualEnd: false,
        checkInLat: null,
        checkInLng: null,
        checkOutLat: null,
        checkOutLng: null,
      );
      return;
    }
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      await pauseVisitUseCase(visitId);

      final visitFromState =
          state.visits.where((v) => v.id == visitId).cast<Visit>().firstOrNull;
      final currentPlan = state.journeyPlan;
      if (currentPlan != null &&
          currentPlan.stops.any((s) => s.visit?.id == visitId)) {
        final now = DateTime.now();
        final updatedStops =
            currentPlan.stops.map((stop) {
              final visit = stop.visit;
              if (visit == null || visit.id != visitId) {
                return stop;
              }
              final effectiveActualStart =
                  visit.actualStartDateTime ??
                  visitFromState?.actualStartDateTime ??
                  now;

              final updatedVisit = VisitModel(
                id: visit.id,
                userId: visit.userId,
                userName: visit.userName,
                customerId: visit.customerId,
                customerName: visit.customerName,
                customerCode: visit.customerCode,
                journeyPlanId: visit.journeyPlanId,
                plannedDateTime: visit.plannedDateTime,
                actualStartDateTime: effectiveActualStart,
                actualEndDateTime: visit.actualEndDateTime,
                visitType: visit.visitType,
                status: VisitExecutionStatus.inProgress,
                supervisorId: visit.supervisorId,
                supervisorName: visit.supervisorName,
                checkInLatitude: visit.checkInLatitude,
                checkInLongitude: visit.checkInLongitude,
                checkOutLatitude: visit.checkOutLatitude,
                checkOutLongitude: visit.checkOutLongitude,
                notes: visit.notes,
                googleMapsLink: visit.googleMapsLink,
                createdAt: visit.createdAt,
                actions: visit.actions,
              );

              return StopModel(
                id: stop.id,
                visitId: stop.visitId,
                sequenceNo: stop.sequenceNo,
                plannedTime: stop.plannedTime,
                estimatedDurationMinutes: stop.estimatedDurationMinutes,
                visit: updatedVisit,
              );
            }).toList();

        final optimisticPlan = JourneyPlanModel(
          id: currentPlan.id,
          userId: currentPlan.userId,
          userName: currentPlan.userName,
          createdByUserId: currentPlan.createdByUserId,
          createdByUserName: currentPlan.createdByUserName,
          createdBy: currentPlan.createdBy,
          planType: currentPlan.planType,
          startDate: currentPlan.startDate,
          endDate: currentPlan.endDate,
          notes: currentPlan.notes,
          isApproved: currentPlan.isApproved,
          approvedAt: currentPlan.approvedAt,
          stops: updatedStops,
          createdAt: currentPlan.createdAt,
        );

        if (!isClosed) {
          await localDataSource.saveCachedCurrentPlan(optimisticPlan);
          DateTime? actualStart = visitFromState?.actualStartDateTime;
          for (final stop in currentPlan.stops) {
            if (stop.visit?.id == visitId &&
                stop.visit?.actualStartDateTime != null) {
              actualStart = stop.visit!.actualStartDateTime;
              break;
            }
          }
          // Freeze the timer at exactly what it currently shows by carrying the
          // value forward from the live snapshot. This keeps the paused value
          // correct even when the server-reloaded start is missing/near-now.
          final int effectiveElapsedSec = _currentRunningElapsedSeconds(
            visitId,
            visit: visitFromState,
          );
          final newPaused = Map<String, int>.from(
            state.pausedVisitElapsedSeconds,
          );
          final newPauseStart = Map<String, int>.from(
            state.pauseStartTimestampMs,
          );
          final newActualStart = Map<String, int>.from(
            state.actualStartTimestampMs,
          );
          // While paused the live timer must stop ticking, so clear the active
          // snapshot maps (the paused value lives in pausedVisitElapsedSeconds).
          final newActiveElapsed = Map<String, int>.from(
            state.activeVisitElapsedSeconds,
          )..remove(visitId);
          final newActiveSnapshot = Map<String, int>.from(
            state.activeVisitSnapshotTimestampMs,
          )..remove(visitId);
          final effectiveStartForTimer =
              actualStart ??
              visitFromState?.actualStartDateTime ??
              _restoredActualStartFor(visitId);
          if (effectiveStartForTimer != null) {
            newActualStart[visitId] =
                effectiveStartForTimer.millisecondsSinceEpoch;
          }
          newPaused[visitId] = effectiveElapsedSec.clamp(0, 1 << 30);
          newPauseStart[visitId] = DateTime.now().millisecondsSinceEpoch;
          final updatedVisit = updatedStops
              .map((stop) => stop.visit)
              .whereType<VisitModel>()
              .firstWhere((visit) => visit.id == visitId);
          final newVisits = _replaceVisitInVisitsList(
            state.visits,
            visitId,
            updatedVisit,
          );
          emit(
            state.copyWith(
              isLoading: false,
              journeyPlan: optimisticPlan,
              visits: newVisits,
              pausedVisitElapsedSeconds: newPaused,
              pauseStartTimestampMs: newPauseStart,
              actualStartTimestampMs: newActualStart,
              activeVisitElapsedSeconds: newActiveElapsed,
              activeVisitSnapshotTimestampMs: newActiveSnapshot,
              clearError: true,
            ),
          );
          await _persistVisitTimingState(
            pausedVisitElapsedSeconds: newPaused,
            pauseStartTimestampMs: newPauseStart,
            totalPausedDurationSeconds: state.totalPausedDurationSeconds,
            actualStartTimestampMs: newActualStart,
            activeVisitElapsedSeconds: newActiveElapsed,
            activeVisitSnapshotTimestampMs: newActiveSnapshot,
          );
        }
      } else {
        if (!isClosed) {
          final idx = state.visits.indexWhere((v) => v.id == visitId);
          if (idx >= 0) {
            final visit = state.visits[idx];
            // Freeze at the live value (carried forward from the snapshot maps)
            // so navigating in before pausing can't reset the stored elapsed.
            final effectiveElapsedSec = _currentRunningElapsedSeconds(
              visitId,
              visit: visit,
            );
            final updatedVisit = VisitModel(
              id: visit.id,
              userId: visit.userId,
              userName: visit.userName,
              customerId: visit.customerId,
              customerName: visit.customerName,
              customerCode: visit.customerCode,
              journeyPlanId: visit.journeyPlanId,
              plannedDateTime: visit.plannedDateTime,
              actualStartDateTime: visit.actualStartDateTime,
              actualEndDateTime: visit.actualEndDateTime,
              visitType: visit.visitType,
              status: VisitExecutionStatus.inProgress,
              supervisorId: visit.supervisorId,
              supervisorName: visit.supervisorName,
              checkInLatitude: visit.checkInLatitude,
              checkInLongitude: visit.checkInLongitude,
              checkOutLatitude: visit.checkOutLatitude,
              checkOutLongitude: visit.checkOutLongitude,
              notes: visit.notes,
              googleMapsLink: visit.googleMapsLink,
              createdAt: visit.createdAt,
              actions: visit.actions,
            );
            final newVisits = _replaceVisitInVisitsList(
              state.visits,
              visitId,
              updatedVisit,
            );
            final newPaused = Map<String, int>.from(
              state.pausedVisitElapsedSeconds,
            );
            final newPauseStart = Map<String, int>.from(
              state.pauseStartTimestampMs,
            );
            final newActualStart = Map<String, int>.from(
              state.actualStartTimestampMs,
            );
            final newActiveElapsed = Map<String, int>.from(
              state.activeVisitElapsedSeconds,
            )..remove(visitId);
            final newActiveSnapshot = Map<String, int>.from(
              state.activeVisitSnapshotTimestampMs,
            )..remove(visitId);
            if (visit.actualStartDateTime != null) {
              newActualStart[visitId] =
                  visit.actualStartDateTime!.millisecondsSinceEpoch;
            }
            newPaused[visitId] = effectiveElapsedSec.clamp(0, 1 << 30);
            newPauseStart[visitId] = DateTime.now().millisecondsSinceEpoch;
            emit(
              state.copyWith(
                isLoading: false,
                visits: newVisits,
                pausedVisitElapsedSeconds: newPaused,
                pauseStartTimestampMs: newPauseStart,
                actualStartTimestampMs: newActualStart,
                activeVisitElapsedSeconds: newActiveElapsed,
                activeVisitSnapshotTimestampMs: newActiveSnapshot,
                clearError: true,
              ),
            );
            await _persistVisitTimingState(
              pausedVisitElapsedSeconds: newPaused,
              pauseStartTimestampMs: newPauseStart,
              totalPausedDurationSeconds: state.totalPausedDurationSeconds,
              actualStartTimestampMs: newActualStart,
              activeVisitElapsedSeconds: newActiveElapsed,
              activeVisitSnapshotTimestampMs: newActiveSnapshot,
            );
          } else {
            emit(state.copyWith(isLoading: false, clearError: true));
          }
        }
      }
    } on Failure catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.message),
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.toString()),
          ),
        );
      }
    }
  }

  Future<void> resumeVisit(String visitId) async {
    if (isClosed) return;
    final online = await connectivityService.isOnline;
    if (!online) {
      await _applyOfflineVisitAction(
        visitId: visitId,
        action: 'resume',
        newStatus: 2,
        setActualStart: false,
        setActualEnd: false,
        checkInLat: null,
        checkInLng: null,
        checkOutLat: null,
        checkOutLng: null,
      );
      return;
    }
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final persistedTimingState = await localDataSource.getVisitTimingState();
      final persistedPausedElapsed =
          (persistedTimingState['pausedVisitElapsedSeconds']
              as Map<String, int>?) ??
          const <String, int>{};
      final persistedPauseStart =
          (persistedTimingState['pauseStartTimestampMs']
              as Map<String, int>?) ??
          const <String, int>{};
      final persistedTotalPaused =
          (persistedTimingState['totalPausedDurationSeconds']
              as Map<String, int>?) ??
          const <String, int>{};
      final persistedActualStart =
          (persistedTimingState['actualStartTimestampMs']
              as Map<String, int>?) ??
          const <String, int>{};

      await resumeVisitUseCase(visitId);

      final visitFromState =
          state.visits.where((v) => v.id == visitId).cast<Visit>().firstOrNull;
      final effectivePausedElapsedSec =
          state.pausedVisitElapsedSeconds[visitId] ??
          persistedPausedElapsed[visitId];
      final effectivePauseStartMs =
          state.pauseStartTimestampMs[visitId] ?? persistedPauseStart[visitId];
      final currentPlan = state.journeyPlan;
      if (currentPlan != null &&
          currentPlan.stops.any((s) => s.visit?.id == visitId)) {
        final now = DateTime.now();
        final updatedStops =
            currentPlan.stops.map((stop) {
              final visit = stop.visit;
              if (visit == null || visit.id != visitId) {
                return stop;
              }
              final effectiveActualStart =
                  visit.actualStartDateTime ??
                  visitFromState?.actualStartDateTime ??
                  (persistedActualStart[visitId] != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                        persistedActualStart[visitId]!,
                      )
                      : null) ??
                  now;

              final updatedVisit = VisitModel(
                id: visit.id,
                userId: visit.userId,
                userName: visit.userName,
                customerId: visit.customerId,
                customerName: visit.customerName,
                customerCode: visit.customerCode,
                journeyPlanId: visit.journeyPlanId,
                plannedDateTime: visit.plannedDateTime,
                actualStartDateTime: effectiveActualStart,
                actualEndDateTime: visit.actualEndDateTime,
                visitType: visit.visitType,
                status: 2,
                supervisorId: visit.supervisorId,
                supervisorName: visit.supervisorName,
                checkInLatitude: visit.checkInLatitude,
                checkInLongitude: visit.checkInLongitude,
                checkOutLatitude: visit.checkOutLatitude,
                checkOutLongitude: visit.checkOutLongitude,
                notes: visit.notes,
                googleMapsLink: visit.googleMapsLink,
                createdAt: visit.createdAt,
                actions: visit.actions,
              );

              return StopModel(
                id: stop.id,
                visitId: stop.visitId,
                sequenceNo: stop.sequenceNo,
                plannedTime: stop.plannedTime,
                estimatedDurationMinutes: stop.estimatedDurationMinutes,
                visit: updatedVisit,
              );
            }).toList();

        final optimisticPlan = JourneyPlanModel(
          id: currentPlan.id,
          userId: currentPlan.userId,
          userName: currentPlan.userName,
          createdByUserId: currentPlan.createdByUserId,
          createdByUserName: currentPlan.createdByUserName,
          createdBy: currentPlan.createdBy,
          planType: currentPlan.planType,
          startDate: currentPlan.startDate,
          endDate: currentPlan.endDate,
          notes: currentPlan.notes,
          isApproved: currentPlan.isApproved,
          approvedAt: currentPlan.approvedAt,
          stops: updatedStops,
          createdAt: currentPlan.createdAt,
        );

        if (!isClosed) {
          await localDataSource.saveCachedCurrentPlan(optimisticPlan);
          final newPaused = Map<String, int>.from(
            state.pausedVisitElapsedSeconds,
          )..remove(visitId);
          final newPauseStart = Map<String, int>.from(
            state.pauseStartTimestampMs,
          );
          final pauseStartMs =
              newPauseStart.remove(visitId) ?? effectivePauseStartMs;
          final newTotalPaused = Map<String, int>.from(
            state.totalPausedDurationSeconds,
          )..addAll(persistedTotalPaused);
          final newActualStart = Map<String, int>.from(
            state.actualStartTimestampMs,
          )..addAll(persistedActualStart);
          final pausedElapsedSec = effectivePausedElapsedSec;
          if (pausedElapsedSec != null &&
              visitFromState?.actualStartDateTime != null) {
            final recomputedTotalPaused =
                DateTime.now()
                    .difference(visitFromState!.actualStartDateTime!)
                    .inSeconds -
                pausedElapsedSec;
            newTotalPaused[visitId] =
                recomputedTotalPaused > 0 ? recomputedTotalPaused : 0;
          } else if (pauseStartMs != null) {
            final pausedDurationSec =
                ((DateTime.now().millisecondsSinceEpoch - pauseStartMs) ~/
                    1000);
            newTotalPaused[visitId] =
                (newTotalPaused[visitId] ?? 0) + pausedDurationSec;
          }
          var updatedVisit = updatedStops
              .map((stop) => stop.visit)
              .whereType<VisitModel>()
              .firstWhere((visit) => visit.id == visitId);
          if (pausedElapsedSec != null) {
            final adjustedStart = DateTime.now().subtract(
              Duration(
                seconds: pausedElapsedSec + (newTotalPaused[visitId] ?? 0),
              ),
            );
            newActualStart[visitId] = adjustedStart.millisecondsSinceEpoch;
            updatedVisit = _copyVisitWithStart(updatedVisit, adjustedStart);
          }
          final resumedStops =
              optimisticPlan.stops.map((stop) {
                if (stop.visit?.id != visitId) return stop;
                return StopModel(
                  id: stop.id,
                  visitId: stop.visitId,
                  sequenceNo: stop.sequenceNo,
                  plannedTime: stop.plannedTime,
                  estimatedDurationMinutes: stop.estimatedDurationMinutes,
                  visit: updatedVisit,
                );
              }).toList();
          final resumedPlan = JourneyPlanModel(
            id: optimisticPlan.id,
            userId: optimisticPlan.userId,
            userName: optimisticPlan.userName,
            createdByUserId: optimisticPlan.createdByUserId,
            createdByUserName: optimisticPlan.createdByUserName,
            createdBy: optimisticPlan.createdBy,
            planType: optimisticPlan.planType,
            startDate: optimisticPlan.startDate,
            endDate: optimisticPlan.endDate,
            notes: optimisticPlan.notes,
            isApproved: optimisticPlan.isApproved,
            approvedAt: optimisticPlan.approvedAt,
            stops: resumedStops,
            createdAt: optimisticPlan.createdAt,
          );
          final newVisits = _replaceVisitInVisitsList(
            state.visits,
            visitId,
            updatedVisit,
          );
          // Continue the running timer from the paused value (e.g. paused at
          // 10s resumes at 10s → 11s …). The live timer prefers these active
          // maps, so reset the snapshot to "now" with the paused elapsed.
          final newActiveElapsed = Map<String, int>.from(
            state.activeVisitElapsedSeconds,
          );
          final newActiveSnapshot = Map<String, int>.from(
            state.activeVisitSnapshotTimestampMs,
          );
          if (pausedElapsedSec != null) {
            newActiveElapsed[visitId] = pausedElapsedSec.clamp(0, 1 << 30);
            newActiveSnapshot[visitId] = DateTime.now().millisecondsSinceEpoch;
          } else {
            newActiveElapsed.remove(visitId);
            newActiveSnapshot.remove(visitId);
          }
          await localDataSource.saveCachedCurrentPlan(resumedPlan);
          await localDataSource.saveCachedVisits(
            newVisits.map((visit) => visit as VisitModel).toList(),
          );
          emit(
            state.copyWith(
              isLoading: false,
              journeyPlan: resumedPlan,
              visits: newVisits,
              pausedVisitElapsedSeconds: newPaused,
              pauseStartTimestampMs: newPauseStart,
              totalPausedDurationSeconds: newTotalPaused,
              actualStartTimestampMs: newActualStart,
              activeVisitElapsedSeconds: newActiveElapsed,
              activeVisitSnapshotTimestampMs: newActiveSnapshot,
              clearError: true,
            ),
          );
          await _persistVisitTimingState(
            pausedVisitElapsedSeconds: newPaused,
            pauseStartTimestampMs: newPauseStart,
            totalPausedDurationSeconds: newTotalPaused,
            actualStartTimestampMs: newActualStart,
            activeVisitElapsedSeconds: newActiveElapsed,
            activeVisitSnapshotTimestampMs: newActiveSnapshot,
          );
        }
      } else {
        if (!isClosed) {
          final idx = state.visits.indexWhere((v) => v.id == visitId);
          if (idx >= 0) {
            final visit = state.visits[idx];
            final updatedVisit = VisitModel(
              id: visit.id,
              userId: visit.userId,
              userName: visit.userName,
              customerId: visit.customerId,
              customerName: visit.customerName,
              customerCode: visit.customerCode,
              journeyPlanId: visit.journeyPlanId,
              plannedDateTime: visit.plannedDateTime,
              actualStartDateTime:
                  visit.actualStartDateTime ??
                  (persistedActualStart[visitId] != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                        persistedActualStart[visitId]!,
                      )
                      : null),
              actualEndDateTime: visit.actualEndDateTime,
              visitType: visit.visitType,
              status: 2,
              supervisorId: visit.supervisorId,
              supervisorName: visit.supervisorName,
              checkInLatitude: visit.checkInLatitude,
              checkInLongitude: visit.checkInLongitude,
              checkOutLatitude: visit.checkOutLatitude,
              checkOutLongitude: visit.checkOutLongitude,
              notes: visit.notes,
              googleMapsLink: visit.googleMapsLink,
              createdAt: visit.createdAt,
              actions: visit.actions,
            );
            final newPaused = Map<String, int>.from(
              state.pausedVisitElapsedSeconds,
            )..remove(visitId);
            final newPauseStart = Map<String, int>.from(
              state.pauseStartTimestampMs,
            );
            final pauseStartMs =
                newPauseStart.remove(visitId) ?? effectivePauseStartMs;
            final newTotalPaused = Map<String, int>.from(
              state.totalPausedDurationSeconds,
            )..addAll(persistedTotalPaused);
            final newActualStart = Map<String, int>.from(
              state.actualStartTimestampMs,
            )..addAll(persistedActualStart);
            final pausedElapsedSec = effectivePausedElapsedSec;
            if (pausedElapsedSec != null &&
                updatedVisit.actualStartDateTime != null) {
              final recomputedTotalPaused =
                  DateTime.now()
                      .difference(updatedVisit.actualStartDateTime!)
                      .inSeconds -
                  pausedElapsedSec;
              newTotalPaused[visitId] =
                  recomputedTotalPaused > 0 ? recomputedTotalPaused : 0;
            } else if (pauseStartMs != null) {
              final pausedDurationSec =
                  ((DateTime.now().millisecondsSinceEpoch - pauseStartMs) ~/
                      1000);
              newTotalPaused[visitId] =
                  (newTotalPaused[visitId] ?? 0) + pausedDurationSec;
            }
            var resumedVisit = updatedVisit;
            if (pausedElapsedSec != null) {
              final adjustedStart = DateTime.now().subtract(
                Duration(
                  seconds: pausedElapsedSec + (newTotalPaused[visitId] ?? 0),
                ),
              );
              newActualStart[visitId] = adjustedStart.millisecondsSinceEpoch;
              resumedVisit = _copyVisitWithStart(updatedVisit, adjustedStart);
            }
            // Continue the running timer from the paused value (e.g. paused at
            // 10s resumes at 10s → 11s …). The live timer prefers these active
            // maps, so reset the snapshot to "now" with the paused elapsed.
            final newActiveElapsed = Map<String, int>.from(
              state.activeVisitElapsedSeconds,
            );
            final newActiveSnapshot = Map<String, int>.from(
              state.activeVisitSnapshotTimestampMs,
            );
            if (pausedElapsedSec != null) {
              newActiveElapsed[visitId] = pausedElapsedSec.clamp(0, 1 << 30);
              newActiveSnapshot[visitId] =
                  DateTime.now().millisecondsSinceEpoch;
            } else {
              newActiveElapsed.remove(visitId);
              newActiveSnapshot.remove(visitId);
            }
            final resumedVisits = _replaceVisitInVisitsList(
              state.visits,
              visitId,
              resumedVisit,
            );
            await localDataSource.saveCachedVisits(
              resumedVisits.map((visit) => visit as VisitModel).toList(),
            );
            emit(
              state.copyWith(
                isLoading: false,
                visits: resumedVisits,
                pausedVisitElapsedSeconds: newPaused,
                pauseStartTimestampMs: newPauseStart,
                totalPausedDurationSeconds: newTotalPaused,
                actualStartTimestampMs: newActualStart,
                activeVisitElapsedSeconds: newActiveElapsed,
                activeVisitSnapshotTimestampMs: newActiveSnapshot,
                clearError: true,
              ),
            );
            await _persistVisitTimingState(
              pausedVisitElapsedSeconds: newPaused,
              pauseStartTimestampMs: newPauseStart,
              totalPausedDurationSeconds: newTotalPaused,
              actualStartTimestampMs: newActualStart,
              activeVisitElapsedSeconds: newActiveElapsed,
              activeVisitSnapshotTimestampMs: newActiveSnapshot,
            );
          } else {
            emit(state.copyWith(isLoading: false, clearError: true));
          }
        }
      }
    } on Failure catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.message),
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.toString()),
          ),
        );
      }
    }
  }

  Future<void> supervisorAttendVisit(
    String visitId, {
    required String action,
    double? latitude,
    double? longitude,
  }) async {
    if (isClosed) return;
    final online = await connectivityService.isOnline;
    if (!online) {
      emit(
        state.copyWith(
          errorMessage:
              'Supervisor attendance requires an internet connection.',
        ),
      );
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final updated = await supervisorAttendanceUseCase(
        SupervisorAttendanceParams(
          visitId: visitId,
          request: SupervisorAttendanceRequestModel(
            action: action,
            latitude: latitude,
            longitude: longitude,
          ),
        ),
      );
      await _applyVisitUpdate(updated as VisitModel);
    } on Failure catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.message),
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.toString()),
          ),
        );
      }
    }
  }

  /// Posts a visit action (e.g. link sales order). Returns the API response message.
  Future<String> postVisitAction(
    String visitId, {
    required String actionCode,
    String? sapDocumentNumber,
    String? sapDocumentId,
  }) async {
    final message = await postVisitActionUseCase(
      visitId,
      actionCode: actionCode,
      sapDocumentNumber: sapDocumentNumber,
      sapDocumentId: sapDocumentId,
    );
    if (state.journeyPlan != null) {
      await refreshJourneyPlanFromServer();
    }
    return message;
  }

  Future<void> cancelVisit(String visitId, {String? reason}) async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      await deleteVisitUseCase(visitId);

      // Reload journey plan to reflect removed visit
      if (state.journeyPlan != null) {
        final reloadedPlan = await getJourneyPlanByIdUseCase(
          state.journeyPlan!.id,
        );
        if (!isClosed) {
          emit(
            state.copyWith(
              isLoading: false,
              journeyPlan: reloadedPlan,
              clearError: true,
            ),
          );
        }
      } else {
        if (!isClosed) {
          // Remove cancelled visit from standalone visits list so UI updates
          final newVisits = state.visits.where((v) => v.id != visitId).toList();
          emit(
            state.copyWith(
              isLoading: false,
              visits: newVisits,
              clearError: true,
            ),
          );
        }
      }
      // Reload visits list if we have a filter user
      final userId = state.filterUserId ?? state.loggedInUserId;
      if (userId != null && !isClosed) {
        await loadVisits(
          userId: userId,
          applyStatusFilterFromState: state.journeyPlan != null,
        );
      }
    } on Failure catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.message),
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: userFriendlyErrorMessage(e.toString()),
          ),
        );
      }
    }
  }

  Future<void> loadVisits({
    String? userId,
    String? customerId,
    String? customerCode,
    String? supervisorId,
    DateTime? startDate,
    DateTime? endDate,
    int? status,
    bool standaloneOnly = false,

    /// When true (default), if [status] is null, use [visitStatusFilter] (e.g. Planned only).
    /// When false, null means omit status from the API request so started/paused visits appear too.
    bool applyStatusFilterFromState = true,
    int pageNumber = 1,
    int pageSize = 20,
    bool append = false,
  }) async {
    if (isClosed) return;

    final online = await connectivityService.isOnline;
    if (!online) {
      final cached = await localDataSource.getCachedVisits();
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoadingVisits: false,
            visits: cached,
            visitsErrorMessage: null,
          ),
        );
      }
      return;
    }

    final int? finalStatus;
    if (status != null) {
      finalStatus = status;
    } else if (applyStatusFilterFromState) {
      finalStatus = state.visitStatusFilter;
    } else {
      finalStatus = null;
    }

    if (append && pageNumber > 1) {
      if (!isClosed) emit(state.copyWith(isLoadingMoreVisits: true));
    } else {
      if (!isClosed)
        emit(state.copyWith(isLoadingVisits: true, visitsErrorMessage: null));
    }

    try {
      final response = await getVisitsUseCase(
        GetVisitsParams(
          userId: userId,
          customerId: customerId,
          customerCode: customerCode,
          supervisorId: supervisorId,
          startDate: startDate,
          endDate: endDate,
          status: finalStatus,
          standaloneOnly: standaloneOnly,
          pageNumber: pageNumber,
          pageSize: pageSize,
        ),
      );

      if (!isClosed) {
        var newVisits =
            append && pageNumber > 1
                ? [...state.visits, ...response.items]
                : response.items;
        newVisits = _mergeKeepingActiveVisits(
          newVisits,
          state.visits.where(_isActiveOngoingVisit),
        );
        if (standaloneOnly) {
          newVisits.sort((a, b) {
            final aDate = a.plannedDateTime;
            final bDate = b.plannedDateTime;
            final byPlanned = bDate.compareTo(aDate);
            if (byPlanned != 0) return byPlanned;
            final aCreated =
                a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bCreated =
                b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bCreated.compareTo(aCreated);
          });
        }
        if (!append) await localDataSource.saveCachedVisits(response.items);
        emit(
          state.copyWith(
            isLoadingVisits: false,
            isLoadingMoreVisits: false,
            visits: newVisits,
            visitsPageNumber: response.pageNumber,
            visitsTotalPages: response.totalPages,
            visitsHasNextPage: response.hasNextPage,
            lastVisitsLoadWasStandaloneOnly: standaloneOnly,
          ),
        );
      }
    } on Failure catch (e) {
      if (!isClosed) {
        final isServerVisitBug = isVisitDtoCollisionError(e.message);
        if (isServerVisitBug && !append) {
          final cached = await localDataSource.getCachedVisits();
          if (!isClosed) {
            emit(
              state.copyWith(
                isLoadingVisits: false,
                isLoadingMoreVisits: false,
                visits: cached,
                visitsErrorMessage: userFriendlyErrorMessage(e.message),
              ),
            );
            return;
          }
        }
        emit(
          state.copyWith(
            isLoadingVisits: false,
            isLoadingMoreVisits: false,
            visitsErrorMessage: userFriendlyErrorMessage(e.message),
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoadingVisits: false,
            isLoadingMoreVisits: false,
            visitsErrorMessage: userFriendlyErrorMessage(null),
          ),
        );
      }
    }
  }

  /// Syncs History / Current / Future tab (0/1/2) for [refreshStandaloneVisitsListUsingStoredTab].
  void setStandaloneVisitsTabIndex(int index) {
    if (isClosed) return;
    if (index < 0 || index > 2) return;
    if (index == state.standaloneVisitsTabIndex) return;
    emit(state.copyWith(standaloneVisitsTabIndex: index));
  }

  /// Reloads standalone visits for the tab stored in [JourneyPlanState.standaloneVisitsTabIndex].
  Future<void> refreshStandaloneVisitsListUsingStoredTab(String userId) async {
    if (isClosed) return;
    final trimmed = userId.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tab = state.standaloneVisitsTabIndex;
    DateTime? startDate;
    DateTime? endDate;
    if (tab == 0) {
      endDate = today;
    } else if (tab == 1) {
      startDate = today;
    } else {
      startDate = today.add(const Duration(days: 1));
    }
    await loadVisits(
      userId: trimmed,
      startDate: startDate,
      endDate: endDate,
      status: null,
      standaloneOnly: true,
      applyStatusFilterFromState: false,
      pageNumber: 1,
      pageSize: 20,
    );
  }

  Future<void> applyFilters() async {
    // Reload journey plans with current filter values from state
    // The loadJourneyPlans method will use filter values from state
    await loadJourneyPlans();
  }

  Future<void> deleteJourneyPlan(
    String journeyPlanId, {
    String? userId,
    String? createdById,
  }) async {
    if (isClosed) return;
    emit(
      state.copyWith(
        isLoadingJourneyPlans: true,
        journeyPlansErrorMessage: null,
      ),
    );

    try {
      await deleteJourneyPlanUseCase(journeyPlanId);

      // Remove the deleted journey plan from the list
      final updatedPlans =
          state.journeyPlans.where((p) => p.id != journeyPlanId).toList();

      if (!isClosed) {
        emit(
          state.copyWith(
            isLoadingJourneyPlans: false,
            journeyPlans: updatedPlans,
            clearError: true,
          ),
        );
      }

      // Reload journey plans to ensure consistency
      if (!isClosed) {
        if (state.selectedTabIndex == 0 && userId != null) {
          await loadJourneyPlans(userId: userId);
        } else if (state.selectedTabIndex == 1 && createdById != null) {
          await loadJourneyPlans(createdById: createdById);
        }
      }
    } on Failure catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoadingJourneyPlans: false,
            journeyPlansErrorMessage: userFriendlyErrorMessage(e.message),
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoadingJourneyPlans: false,
            journeyPlansErrorMessage: userFriendlyErrorMessage(null),
          ),
        );
      }
    }
  }
}
