import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit.dart';

/// Resolves visit start from entity or persisted timing maps (same as [ActiveVisitBanner]).
DateTime? visitEffectiveStart(
  Visit visit,
  Map<String, int> actualStartTimestampMs,
) {
  if (visit.actualStartDateTime != null) return visit.actualStartDateTime;
  final ms = actualStartTimestampMs[visit.id];
  if (ms == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(ms);
}

/// Elapsed seconds while visit is running (status 2).
int visitRunningElapsedSeconds({
  required DateTime effectiveStart,
  required int totalPausedSeconds,
  int? activeElapsedSeconds,
  int? activeSnapshotMs,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  if (activeElapsedSeconds != null && activeSnapshotMs != null) {
    final delta =
        (clock.millisecondsSinceEpoch - activeSnapshotMs) ~/ 1000;
    final sec = activeElapsedSeconds + delta;
    return sec > 0 ? sec : 0;
  }
  final sec =
      clock.difference(effectiveStart).inSeconds - totalPausedSeconds;
  return sec > 0 ? sec : 0;
}

/// Elapsed seconds while visit is paused (status 3).
int visitPausedElapsedSeconds({
  required DateTime effectiveStart,
  required int totalPausedSeconds,
  int? pausedElapsedSeconds,
  DateTime? now,
}) {
  if (pausedElapsedSeconds != null) {
    return pausedElapsedSeconds.clamp(0, 1 << 30);
  }
  final clock = now ?? DateTime.now();
  final sec =
      clock.difference(effectiveStart).inSeconds - totalPausedSeconds;
  return sec.clamp(0, 1 << 30);
}

String formatVisitElapsedHms(int totalSeconds) {
  final safe = totalSeconds < 0 ? 0 : totalSeconds;
  final hours = (safe ~/ 3600).toString().padLeft(2, '0');
  final minutes = ((safe % 3600) ~/ 60).toString().padLeft(2, '0');
  final seconds = (safe % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

/// Elapsed seconds at checkout — matches banner/card running timer.
int visitCheckoutElapsedSeconds({
  required Visit visit,
  required Map<String, int> actualStartTimestampMs,
  required Map<String, int> pausedVisitElapsedSeconds,
  required Map<String, int> totalPausedDurationSeconds,
  required Map<String, int> activeVisitElapsedSeconds,
  required Map<String, int> activeVisitSnapshotTimestampMs,
  DateTime? endAt,
}) {
  final paused = pausedVisitElapsedSeconds[visit.id];
  if (paused != null && paused >= 0) return paused;

  final effectiveStart = visitEffectiveStart(visit, actualStartTimestampMs);
  if (effectiveStart == null) return 0;

  return visitRunningElapsedSeconds(
    effectiveStart: effectiveStart,
    totalPausedSeconds: totalPausedDurationSeconds[visit.id] ?? 0,
    activeElapsedSeconds: activeVisitElapsedSeconds[visit.id],
    activeSnapshotMs: activeVisitSnapshotTimestampMs[visit.id],
    now: endAt,
  );
}

/// Display duration after visit ended (stored value, else start/end on visit).
int resolveEndedVisitDisplaySeconds({
  required Visit visit,
  required Map<String, int> endedVisitElapsedSeconds,
  required Map<String, int> actualStartTimestampMs,
}) {
  final stored = endedVisitElapsedSeconds[visit.id];
  if (stored != null && stored > 0) return stored;

  final start = visitEffectiveStart(visit, actualStartTimestampMs);
  final end = visit.actualEndDateTime;
  if (start != null && end != null) {
    final fromTimes = end.difference(start).inSeconds;
    if (fromTimes > 0) return fromTimes;
  }

  return stored ?? 0;
}
