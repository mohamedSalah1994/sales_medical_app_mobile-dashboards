import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/journey_plan_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/visit_model.dart';

const _keyCachedVisits = 'journey_plan_cached_visits';
const _keyCachedPlans = 'journey_plan_cached_plans';
const _keyCachedCurrentPlan = 'journey_plan_cached_current_plan';
const _keyPendingActions = 'journey_plan_pending_visit_actions';
const _keyVisitTimingState = 'journey_plan_visit_timing_state';

/// Pending visit action to be sent when back online.
class PendingVisitAction {
  const PendingVisitAction({
    required this.action,
    required this.visitId,
    this.latitude,
    this.longitude,
    this.actualDurationSeconds,
    this.actualDuration,
    required this.createdAt,
  });

  final String action; // 'checkIn' | 'checkOut' | 'pause' | 'resume'
  final String visitId;
  final double? latitude;
  final double? longitude;
  final int? actualDurationSeconds;
  final String? actualDuration;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'action': action,
        'visitId': visitId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (actualDurationSeconds != null)
          'actualDurationSeconds': actualDurationSeconds,
        if (actualDuration != null && actualDuration!.isNotEmpty)
          'actualDuration': actualDuration,
        'createdAt': createdAt.toIso8601String(),
      };

  static PendingVisitAction fromJson(Map<String, dynamic> json) =>
      PendingVisitAction(
        action: json['action'] as String,
        visitId: json['visitId'] as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        actualDurationSeconds: (json['actualDurationSeconds'] as num?)?.toInt(),
        actualDuration: json['actualDuration'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

abstract class JourneyPlanLocalDataSource {
  Future<List<VisitModel>> getCachedVisits();
  Future<void> saveCachedVisits(List<VisitModel> visits);

  Future<List<JourneyPlanModel>> getCachedJourneyPlans();
  Future<void> saveCachedJourneyPlans(List<JourneyPlanModel> plans);
  /// Replaces the plan with the same id in the cached list, or appends if not found.
  Future<void> updateCachedJourneyPlan(JourneyPlanModel plan);

  Future<JourneyPlanModel?> getCachedCurrentPlan();
  Future<void> saveCachedCurrentPlan(JourneyPlanModel? plan);

  Future<List<PendingVisitAction>> getPendingVisitActions();
  Future<void> addPendingVisitAction(PendingVisitAction action);
  Future<void> clearPendingVisitActions();

  Future<Map<String, dynamic>> getVisitTimingState();
  Future<void> saveVisitTimingState({
    required Map<String, int> pausedVisitElapsedSeconds,
    required Map<String, int> pauseStartTimestampMs,
    required Map<String, int> totalPausedDurationSeconds,
    required Map<String, int> actualStartTimestampMs,
    required Map<String, int> activeVisitElapsedSeconds,
    required Map<String, int> activeVisitSnapshotTimestampMs,
    required Map<String, int> endedVisitElapsedSeconds,
  });
  Future<void> clearVisitTimingState();
}

class JourneyPlanLocalDataSourceImpl implements JourneyPlanLocalDataSource {
  JourneyPlanLocalDataSourceImpl({required this.preferences});

  final SharedPreferences preferences;

  @override
  Future<List<VisitModel>> getCachedVisits() async {
    final json = preferences.getString(_keyCachedVisits);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => VisitModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveCachedVisits(List<VisitModel> visits) async {
    final list = visits.map((v) => v.toJson()).toList();
    await preferences.setString(_keyCachedVisits, jsonEncode(list));
  }

  @override
  Future<List<JourneyPlanModel>> getCachedJourneyPlans() async {
    final json = preferences.getString(_keyCachedPlans);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => JourneyPlanModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveCachedJourneyPlans(List<JourneyPlanModel> plans) async {
    final list = plans.map((p) => p.toJson()).toList();
    await preferences.setString(_keyCachedPlans, jsonEncode(list));
  }

  @override
  Future<void> updateCachedJourneyPlan(JourneyPlanModel plan) async {
    final list = await getCachedJourneyPlans();
    final index = list.indexWhere((p) => p.id == plan.id);
    final updated = List<JourneyPlanModel>.from(list);
    if (index >= 0) {
      updated[index] = plan;
    } else {
      updated.add(plan);
    }
    await saveCachedJourneyPlans(updated);
  }

  @override
  Future<JourneyPlanModel?> getCachedCurrentPlan() async {
    final json = preferences.getString(_keyCachedCurrentPlan);
    if (json == null) return null;
    return JourneyPlanModel.fromJson(
        jsonDecode(json) as Map<String, dynamic>);
  }

  @override
  Future<void> saveCachedCurrentPlan(JourneyPlanModel? plan) async {
    if (plan == null) {
      await preferences.remove(_keyCachedCurrentPlan);
      return;
    }
    await preferences.setString(
        _keyCachedCurrentPlan, jsonEncode(plan.toJson()));
  }

  @override
  Future<List<PendingVisitAction>> getPendingVisitActions() async {
    final json = preferences.getString(_keyPendingActions);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => PendingVisitAction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addPendingVisitAction(PendingVisitAction action) async {
    final list = await getPendingVisitActions();
    list.add(action);
    await preferences.setString(
        _keyPendingActions,
        jsonEncode(list.map((a) => a.toJson()).toList()));
  }

  @override
  Future<void> clearPendingVisitActions() async {
    await preferences.remove(_keyPendingActions);
  }

  @override
  Future<Map<String, dynamic>> getVisitTimingState() async {
    final json = preferences.getString(_keyVisitTimingState);
    if (json == null) {
      return {
        'pausedVisitElapsedSeconds': <String, int>{},
        'pauseStartTimestampMs': <String, int>{},
        'totalPausedDurationSeconds': <String, int>{},
        'actualStartTimestampMs': <String, int>{},
        'activeVisitElapsedSeconds': <String, int>{},
        'activeVisitSnapshotTimestampMs': <String, int>{},
        'endedVisitElapsedSeconds': <String, int>{},
      };
    }
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    Map<String, int> toIntMap(String key) {
      final raw = decoded[key] as Map<String, dynamic>? ?? <String, dynamic>{};
      return raw.map((k, v) => MapEntry(k, (v as num).toInt()));
    }

    return {
      'pausedVisitElapsedSeconds': toIntMap('pausedVisitElapsedSeconds'),
      'pauseStartTimestampMs': toIntMap('pauseStartTimestampMs'),
      'totalPausedDurationSeconds': toIntMap('totalPausedDurationSeconds'),
      'actualStartTimestampMs': toIntMap('actualStartTimestampMs'),
      'activeVisitElapsedSeconds': toIntMap('activeVisitElapsedSeconds'),
      'activeVisitSnapshotTimestampMs': toIntMap('activeVisitSnapshotTimestampMs'),
      'endedVisitElapsedSeconds': toIntMap('endedVisitElapsedSeconds'),
    };
  }

  @override
  Future<void> saveVisitTimingState({
    required Map<String, int> pausedVisitElapsedSeconds,
    required Map<String, int> pauseStartTimestampMs,
    required Map<String, int> totalPausedDurationSeconds,
    required Map<String, int> actualStartTimestampMs,
    required Map<String, int> activeVisitElapsedSeconds,
    required Map<String, int> activeVisitSnapshotTimestampMs,
    required Map<String, int> endedVisitElapsedSeconds,
  }) async {
    await preferences.setString(
      _keyVisitTimingState,
      jsonEncode({
        'pausedVisitElapsedSeconds': pausedVisitElapsedSeconds,
        'pauseStartTimestampMs': pauseStartTimestampMs,
        'totalPausedDurationSeconds': totalPausedDurationSeconds,
        'actualStartTimestampMs': actualStartTimestampMs,
        'activeVisitElapsedSeconds': activeVisitElapsedSeconds,
        'activeVisitSnapshotTimestampMs': activeVisitSnapshotTimestampMs,
        'endedVisitElapsedSeconds': endedVisitElapsedSeconds,
      }),
    );
  }

  @override
  Future<void> clearVisitTimingState() async {
    await preferences.remove(_keyVisitTimingState);
  }
}
