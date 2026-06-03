import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/journey_plan.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit.dart';

/// ERP visit status values from the API (`VisitDetailPage` / Swagger).
abstract final class VisitExecutionStatus {
  static const int planned = 1;
  static const int inProgress = 2;
  static const int completed = 3;
  static const int cancelled = 4;
  static const int noShow = 5;

  /// Visit has check-out / end timestamps or coordinates.
  static bool hasEndEvidence(Visit visit) {
    return visit.actualEndDateTime != null ||
        visit.checkOutLatitude != null ||
        visit.checkOutLongitude != null;
  }

  static bool wasEndedLocally(
    Visit visit, {
    Map<String, int>? endedVisitElapsedSeconds,
  }) {
    return endedVisitElapsedSeconds?.containsKey(visit.id) ?? false;
  }

  /// True when the visit was completed/ended (not cancelled, not no-show).
  static bool isVisitEnded(
    Visit visit, {
    Map<String, int>? endedVisitElapsedSeconds,
  }) {
    if (visit.status == noShow) return false;
    if (wasEndedLocally(
      visit,
      endedVisitElapsedSeconds: endedVisitElapsedSeconds,
    )) {
      return true;
    }
    if (visit.status == completed) return true;
    if (hasEndEvidence(visit)) return true;
    return false;
  }

  /// True only for a genuine cancellation (not a completed visit).
  static bool isVisitCancelled(
    Visit visit, {
    Map<String, int>? endedVisitElapsedSeconds,
  }) {
    if (isVisitEnded(
      visit,
      endedVisitElapsedSeconds: endedVisitElapsedSeconds,
    )) {
      return false;
    }
    return visit.status == cancelled;
  }

  static bool isVisitNoShow(Visit visit) => visit.status == noShow;

  static bool isVisitPlanned(
    Visit visit, {
    Map<String, int>? endedVisitElapsedSeconds,
  }) {
    if (isVisitEnded(
          visit,
          endedVisitElapsedSeconds: endedVisitElapsedSeconds,
        ) ||
        isVisitCancelled(
          visit,
          endedVisitElapsedSeconds: endedVisitElapsedSeconds,
        ) ||
        isVisitNoShow(visit)) {
      return false;
    }
    final s = visit.status;
    return (s == null || s == planned) && visit.actualStartDateTime == null;
  }

  static bool isVisitInProgress(
    Visit visit, {
    Map<String, int>? endedVisitElapsedSeconds,
  }) {
    if (isVisitEnded(
          visit,
          endedVisitElapsedSeconds: endedVisitElapsedSeconds,
        ) ||
        isVisitCancelled(
          visit,
          endedVisitElapsedSeconds: endedVisitElapsedSeconds,
        ) ||
        isVisitNoShow(visit)) {
      return false;
    }
    return visit.status == inProgress || visit.actualStartDateTime != null;
  }

  static bool isVisitPausedFromTiming(
    Visit visit, {
    required Map<String, int> pausedVisitElapsedSeconds,
    Map<String, int>? pauseStartTimestampMs,
    Map<String, int>? endedVisitElapsedSeconds,
  }) {
    if (isVisitEnded(
          visit,
          endedVisitElapsedSeconds: endedVisitElapsedSeconds,
        ) ||
        isVisitCancelled(
          visit,
          endedVisitElapsedSeconds: endedVisitElapsedSeconds,
        )) {
      return false;
    }
    return pausedVisitElapsedSeconds.containsKey(visit.id) ||
        (pauseStartTimestampMs?.containsKey(visit.id) ?? false);
  }

  /// User-facing status label (not raw API int).
  static String displayStatusLabel(
    Visit visit, {
    Map<String, int>? endedVisitElapsedSeconds,
    Map<String, int>? pausedVisitElapsedSeconds,
    Map<String, int>? pauseStartTimestampMs,
  }) {
    if (isVisitEnded(
      visit,
      endedVisitElapsedSeconds: endedVisitElapsedSeconds,
    )) {
      return 'Completed';
    }
    if (isVisitCancelled(
      visit,
      endedVisitElapsedSeconds: endedVisitElapsedSeconds,
    )) {
      return 'Cancelled';
    }
    if (isVisitNoShow(visit)) return 'No Show';
    if (pausedVisitElapsedSeconds != null &&
        isVisitPausedFromTiming(
          visit,
          pausedVisitElapsedSeconds: pausedVisitElapsedSeconds,
          pauseStartTimestampMs: pauseStartTimestampMs,
          endedVisitElapsedSeconds: endedVisitElapsedSeconds,
        )) {
      return 'Paused';
    }
    switch (visit.status) {
      case planned:
        return 'Planned';
      case inProgress:
        return 'In Progress';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      case noShow:
        return 'No Show';
      default:
        return 'Unknown';
    }
  }

  static void countForJourneyPlanSummary(
    Visit visit, {
    required void Function() onPlanned,
    required void Function() onInProgress,
    required void Function() onPaused,
    required void Function() onEnded,
    required void Function() onCancelled,
    Map<String, int>? pausedVisitElapsedSeconds,
    Map<String, int>? pauseStartTimestampMs,
    Map<String, int>? endedVisitElapsedSeconds,
  }) {
    if (isVisitCancelled(
      visit,
      endedVisitElapsedSeconds: endedVisitElapsedSeconds,
    )) {
      onCancelled();
      return;
    }
    if (isVisitNoShow(visit)) {
      onCancelled();
      return;
    }
    if (isVisitEnded(
      visit,
      endedVisitElapsedSeconds: endedVisitElapsedSeconds,
    )) {
      onEnded();
      return;
    }
    if (pausedVisitElapsedSeconds != null &&
        isVisitPausedFromTiming(
          visit,
          pausedVisitElapsedSeconds: pausedVisitElapsedSeconds,
          pauseStartTimestampMs: pauseStartTimestampMs,
          endedVisitElapsedSeconds: endedVisitElapsedSeconds,
        )) {
      onPaused();
      return;
    }
    if (isVisitInProgress(
      visit,
      endedVisitElapsedSeconds: endedVisitElapsedSeconds,
    )) {
      onInProgress();
      return;
    }
    onPlanned();
  }

  static List<Visit> _planVisits(JourneyPlan plan) =>
      plan.stops.map((s) => s.visit).whereType<Visit>().toList();

  /// All stops have visits and every visit is ended/completed.
  static bool isJourneyPlanCompleted(
    JourneyPlan plan, {
    Map<String, int>? endedVisitElapsedSeconds,
    Map<String, int>? pausedVisitElapsedSeconds,
    Map<String, int>? pauseStartTimestampMs,
  }) {
    final visits = _planVisits(plan);
    if (visits.isEmpty) return false;
    return visits.every(
      (v) =>
          isVisitEnded(v, endedVisitElapsedSeconds: endedVisitElapsedSeconds),
    );
  }

  /// At least one visit started, paused, or ended while others are not all done.
  static bool isJourneyPlanInProgress(
    JourneyPlan plan, {
    Map<String, int>? endedVisitElapsedSeconds,
    Map<String, int>? pausedVisitElapsedSeconds,
    Map<String, int>? pauseStartTimestampMs,
  }) {
    if (isJourneyPlanCompleted(
      plan,
      endedVisitElapsedSeconds: endedVisitElapsedSeconds,
      pausedVisitElapsedSeconds: pausedVisitElapsedSeconds,
      pauseStartTimestampMs: pauseStartTimestampMs,
    )) {
      return false;
    }
    final visits = _planVisits(plan);
    if (visits.isEmpty) return false;

    final paused = pausedVisitElapsedSeconds ?? const <String, int>{};
    for (final v in visits) {
      if (isVisitEnded(v, endedVisitElapsedSeconds: endedVisitElapsedSeconds)) {
        return true;
      }
      if (isVisitInProgress(
        v,
        endedVisitElapsedSeconds: endedVisitElapsedSeconds,
      )) {
        return true;
      }
      if (isVisitPausedFromTiming(
        v,
        pausedVisitElapsedSeconds: paused,
        pauseStartTimestampMs: pauseStartTimestampMs,
        endedVisitElapsedSeconds: endedVisitElapsedSeconds,
      )) {
        return true;
      }
    }
    return false;
  }

  /// True when `plan.endDate` is in the past AND at least one visit is not
  /// completed. Used to flag plans whose period has finished without all
  /// visits being closed out.
  static bool isJourneyPlanIncompleted(
    JourneyPlan plan, {
    Map<String, int>? endedVisitElapsedSeconds,
    Map<String, int>? pausedVisitElapsedSeconds,
    Map<String, int>? pauseStartTimestampMs,
    DateTime? now,
  }) {
    final visits = _planVisits(plan);
    if (visits.isEmpty) return false;
    if (isJourneyPlanCompleted(
      plan,
      endedVisitElapsedSeconds: endedVisitElapsedSeconds,
      pausedVisitElapsedSeconds: pausedVisitElapsedSeconds,
      pauseStartTimestampMs: pauseStartTimestampMs,
    )) {
      return false;
    }
    final today = (now ?? DateTime.now()).toLocal();
    final todayDate = DateTime(today.year, today.month, today.day);
    final endLocal = plan.endDate.toLocal();
    final endDate = DateTime(endLocal.year, endLocal.month, endLocal.day);
    return todayDate.isAfter(endDate);
  }

  /// Card badge: `Completed`, `Incompleted`, `In Progress`, or null (planned / not started).
  static String? journeyPlanExecutionStatusLabel(
    JourneyPlan plan, {
    Map<String, int>? endedVisitElapsedSeconds,
    Map<String, int>? pausedVisitElapsedSeconds,
    Map<String, int>? pauseStartTimestampMs,
    DateTime? now,
  }) {
    if (isJourneyPlanCompleted(
      plan,
      endedVisitElapsedSeconds: endedVisitElapsedSeconds,
      pausedVisitElapsedSeconds: pausedVisitElapsedSeconds,
      pauseStartTimestampMs: pauseStartTimestampMs,
    )) {
      return 'Completed';
    }
    if (isJourneyPlanIncompleted(
      plan,
      endedVisitElapsedSeconds: endedVisitElapsedSeconds,
      pausedVisitElapsedSeconds: pausedVisitElapsedSeconds,
      pauseStartTimestampMs: pauseStartTimestampMs,
      now: now,
    )) {
      return 'Incompleted';
    }
    if (isJourneyPlanInProgress(
      plan,
      endedVisitElapsedSeconds: endedVisitElapsedSeconds,
      pausedVisitElapsedSeconds: pausedVisitElapsedSeconds,
      pauseStartTimestampMs: pauseStartTimestampMs,
    )) {
      return 'In Progress';
    }
    return null;
  }
}
