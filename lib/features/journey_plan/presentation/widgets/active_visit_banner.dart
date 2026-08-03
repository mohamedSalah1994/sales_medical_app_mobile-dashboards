import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sales_medical_app_mobile/core/navigation/app_navigator_key.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_state.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/pages/visit_detail_page.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/utils/visit_elapsed_seconds.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/utils/visit_execution_status.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';

/// All visits currently in progress (started or paused), de-duped across the
/// open journey plan stops and the standalone visits list.
List<Visit> findActiveOngoingVisits(JourneyPlanState state) {
  final fromStops =
      state.journeyPlan?.stops
          .map((s) => s.visit)
          .whereType<Visit>()
          .toList() ??
      <Visit>[];
  final merged = <String, Visit>{};
  for (final v in fromStops) {
    merged[v.id] = v;
  }
  for (final v in state.visits) {
    final existing = merged[v.id];
    if (existing == null) {
      merged[v.id] = v;
    } else {
      merged[v.id] = existing.actions.length >= v.actions.length ? existing : v;
    }
  }
  return [
    for (final v in merged.values)
      if (_isActiveOngoing(v, state)) v,
  ];
}

/// Slim bar under the app bar when a visit is in progress (started or paused).
Visit? findActiveOngoingVisit(JourneyPlanState state) {
  final list = findActiveOngoingVisits(state);
  return list.isEmpty ? null : list.first;
}

/// Whether the global floating visit banner has content to show.
bool activeVisitBannerShouldShow(JourneyPlanState state) {
  final visit = findActiveOngoingVisit(state);
  if (visit == null) return false;
  return visitEffectiveStart(visit, state.actualStartTimestampMs) != null;
}

bool _isActiveOngoing(Visit v, JourneyPlanState state) {
  final endedMap = state.endedVisitElapsedSeconds;
  if (VisitExecutionStatus.isVisitEnded(
        v,
        endedVisitElapsedSeconds: endedMap,
      ) ||
      VisitExecutionStatus.isVisitCancelled(
        v,
        endedVisitElapsedSeconds: endedMap,
      ) ||
      VisitExecutionStatus.isVisitNoShow(v)) {
    return false;
  }
  if (VisitExecutionStatus.isVisitPausedFromTiming(
    v,
    pausedVisitElapsedSeconds: state.pausedVisitElapsedSeconds,
    pauseStartTimestampMs: state.pauseStartTimestampMs,
    endedVisitElapsedSeconds: state.endedVisitElapsedSeconds,
  )) {
    return true;
  }
  if (v.actualStartDateTime != null) {
    return v.status == VisitExecutionStatus.inProgress || v.status == null;
  }
  return state.actualStartTimestampMs.containsKey(v.id);
}

String? _resolveActiveJourneyPlanId(JourneyPlanState state, Visit visit) {
  final explicitId = visit.journeyPlanId?.trim();
  if (explicitId != null && explicitId.isNotEmpty) {
    if (explicitId.toLowerCase() == 'standalone') {
      return null;
    }
    return explicitId;
  }

  final currentPlanContainsVisit =
      state.journeyPlan?.stops.any((s) => s.visit?.id == visit.id) == true;
  if (currentPlanContainsVisit) {
    return state.journeyPlan?.id;
  }

  for (final plan in state.journeyPlans) {
    final containsVisit = plan.stops.any(
      (stop) => stop.visitId == visit.id || stop.visit?.id == visit.id,
    );
    if (containsVisit) {
      return plan.id;
    }
  }

  return null;
}

int _standaloneTabForVisit(Visit visit) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final planned = visit.plannedDateTime;
  final plannedDay = DateTime(planned.year, planned.month, planned.day);
  if (plannedDay.isBefore(today)) return 0;
  if (plannedDay.isAfter(today)) return 2;
  return 1;
}

/// Visit is considered past when its planned day or actual start day is before today,
/// so tapping the banner ends the leftover visit instead of opening it.
bool _isVisitPast(Visit visit) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final planned = visit.plannedDateTime;
  final plannedDay = DateTime(planned.year, planned.month, planned.day);
  if (plannedDay.isBefore(today)) return true;
  final started = visit.actualStartDateTime;
  if (started != null) {
    final startedDay = DateTime(started.year, started.month, started.day);
    if (startedDay.isBefore(today)) return true;
  }
  return false;
}

Future<({double? lat, double? lng})> _bestEffortCurrentPosition() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return (lat: null, lng: null);
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      final position = await Geolocator.getCurrentPosition();
      return (lat: position.latitude, lng: position.longitude);
    }
  } catch (_) {}
  return (lat: null, lng: null);
}

Future<void> _endPastVisitFromGlobalOverlay(
  JourneyPlanCubit cubit,
  Visit visit,
) async {
  final overlayContext = appNavigatorKey.currentContext;
  if (overlayContext == null) return;
  final l10n = AppLocalizations.of(overlayContext);
  final confirmed = await showDialog<bool>(
    context: overlayContext,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('End visit?'),
        content: Text(
          'This visit was planned for an earlier day. Ending it now will check '
          'you out of "${visit.customerName}".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('End visit'),
          ),
        ],
      );
    },
  );
  if (confirmed != true) return;
  if (cubit.isClosed) return;

  final pos = await _bestEffortCurrentPosition();
  if (cubit.isClosed) return;

  await cubit.checkOutVisit(visit.id, latitude: pos.lat, longitude: pos.lng);

  final messengerContext = appNavigatorKey.currentContext;
  if (messengerContext == null) return;
  final errorMessage = cubit.isClosed ? null : cubit.state.errorMessage;
  // Fresh context from the global navigator key (re-fetched after awaits).
  // ignore: use_build_context_synchronously
  final messenger = ScaffoldMessenger.maybeOf(messengerContext);
  if (messenger == null) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        errorMessage != null && errorMessage.isNotEmpty
            ? errorMessage
            : 'Visit ended',
      ),
      backgroundColor:
          errorMessage != null && errorMessage.isNotEmpty
              ? AppColors.error
              : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Pops pushed routes to home, then [HomePage] switches tab (Journey Plans = 2, Standalone = 4).
///
/// Uses [appNavigatorKey] because this runs from the global overlay: that [BuildContext]
/// is not under the [Navigator] (overlay is a sibling in [MaterialApp.builder]'s [Stack]),
/// so [Navigator.of] would throw.
void openActiveVisitFromGlobalOverlay(BuildContext context, {Visit? visit}) {
  final cubit = context.read<JourneyPlanCubit>();
  final v = visit ?? findActiveOngoingVisit(cubit.state);
  if (v == null) return;

  if (_isVisitPast(v)) {
    unawaited(_endPastVisitFromGlobalOverlay(cubit, v));
    return;
  }

  final activeJourneyPlanId = _resolveActiveJourneyPlanId(cubit.state, v);
  final inPlan = activeJourneyPlanId != null;
  final tab = inPlan ? 2 : 4;
  if (!inPlan) {
    cubit.setStandaloneVisitsTabIndex(_standaloneTabForVisit(v));
  }
  final nav = appNavigatorKey.currentState;
  if (nav != null && nav.canPop()) {
    nav.popUntil((route) => route.isFirst);
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (cubit.isClosed) return;
    cubit.requestOpenHomeTab(tab);
    if (activeJourneyPlanId != null) {
      final user = context.read<AuthCubit>().state.loginResponse?.user;
      final role = user?.role.toLowerCase().trim();
      final isManagerOrAdmin = role == 'manager' || role == 'admin';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (cubit.isClosed) return;
        cubit.reopenJourneyPlanForActiveVisit(
          activeJourneyPlanId,
          currentUserId: user?.id,
          isSupervisor: isManagerOrAdmin,
          visitId: v.id,
        );
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (cubit.isClosed) return;
        final nav = appNavigatorKey.currentState;
        if (nav == null) return;
        nav.push<void>(
          MaterialPageRoute<void>(
            builder:
                (_) => BlocProvider.value(
                  value: cubit,
                  child: VisitDetailPage(visit: v),
                ),
          ),
        );
      });
    }
  });
}

/// Bottom sheet listing every in-progress/paused visit so the user can jump to
/// any of them when several are started at once (banner "3 dots" action).
void showOpenVisitsSheet(BuildContext context) {
  final cubit = context.read<JourneyPlanCubit>();
  final sheetHost = appNavigatorKey.currentContext;
  if (sheetHost == null) return;
  showModalBottomSheet<void>(
    context: sheetHost,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return BlocProvider.value(
        value: cubit,
        child: BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
          builder: (innerContext, state) {
            final visits = findActiveOngoingVisits(state);
            if (visits.isEmpty) {
              return const SizedBox(
                height: 120,
                child: Center(child: Text('No open visits')),
              );
            }
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Icon(Icons.layers, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Open visits (${visits.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: visits.length,
                      separatorBuilder:
                          (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final v = visits[index];
                        final isPaused =
                            VisitExecutionStatus.isVisitPausedFromTiming(
                          v,
                          pausedVisitElapsedSeconds:
                              state.pausedVisitElapsedSeconds,
                          pauseStartTimestampMs: state.pauseStartTimestampMs,
                          endedVisitElapsedSeconds:
                              state.endedVisitElapsedSeconds,
                        );
                        final start = visitEffectiveStart(
                          v,
                          state.actualStartTimestampMs,
                        );
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                (isPaused ? AppColors.warning : AppColors.primary)
                                    .withValues(alpha: 0.12),
                            child: Icon(
                              isPaused
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color:
                                  isPaused
                                      ? AppColors.warning
                                      : AppColors.primary,
                            ),
                          ),
                          title: Text(
                            v.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            isPaused ? 'Paused' : 'In progress',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isPaused
                                      ? AppColors.warning
                                      : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing:
                              start == null
                                  ? const Icon(Icons.chevron_right)
                                  : _OpenVisitRowTimer(
                                    start: start,
                                    isPaused: isPaused,
                                    pausedSec:
                                        state.pausedVisitElapsedSeconds[v.id],
                                    totalPaused:
                                        state.totalPausedDurationSeconds[v.id] ??
                                        0,
                                    activeElapsedSec:
                                        state.activeVisitElapsedSeconds[v.id],
                                    activeSnapshotMs: state
                                        .activeVisitSnapshotTimestampMs[v.id],
                                  ),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            openActiveVisitFromGlobalOverlay(
                              context,
                              visit: v,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

/// Banner + timer; [onOpen] should switch to the relevant tab (standalone vs journey plans).
class ActiveVisitBanner extends StatelessWidget {
  const ActiveVisitBanner({
    super.key,
    required this.onOpen,
    this.floating = false,
  });

  final VoidCallback onOpen;

  /// When true, shows as a floating card with margin and stronger elevation (global overlay).
  final bool floating;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
      buildWhen:
          (prev, curr) =>
              prev.visits != curr.visits ||
              prev.journeyPlan?.id != curr.journeyPlan?.id ||
              prev.journeyPlan?.stops != curr.journeyPlan?.stops ||
              prev.actualStartTimestampMs != curr.actualStartTimestampMs ||
              prev.activeVisitElapsedSeconds !=
                  curr.activeVisitElapsedSeconds ||
              prev.activeVisitSnapshotTimestampMs !=
                  curr.activeVisitSnapshotTimestampMs ||
              prev.pausedVisitElapsedSeconds !=
                  curr.pausedVisitElapsedSeconds ||
              prev.totalPausedDurationSeconds !=
                  curr.totalPausedDurationSeconds,
      builder: (context, state) {
        final activeVisits = findActiveOngoingVisits(state);
        final visit = activeVisits.isEmpty ? null : activeVisits.first;
        final hasMultiple = activeVisits.length > 1;
        final Widget inner;
        final effectiveStart =
            visit == null
                ? null
                : visitEffectiveStart(visit, state.actualStartTimestampMs);
        if (visit == null || effectiveStart == null) {
          inner = const SizedBox.shrink(key: ValueKey('banner-empty'));
        } else {
          final isPaused = VisitExecutionStatus.isVisitPausedFromTiming(
            visit,
            pausedVisitElapsedSeconds: state.pausedVisitElapsedSeconds,
            pauseStartTimestampMs: state.pauseStartTimestampMs,
            endedVisitElapsedSeconds: state.endedVisitElapsedSeconds,
          );
          final pausedSec = state.pausedVisitElapsedSeconds[visit.id];
          final totalPaused = state.totalPausedDurationSeconds[visit.id] ?? 0;
          final activeElapsedSec = state.activeVisitElapsedSeconds[visit.id];
          final activeSnapshotMs =
              state.activeVisitSnapshotTimestampMs[visit.id];
          inner = Material(
            key: ValueKey('banner-${visit.id}-${visit.status}'),
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpen,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.88),
                      const Color(0xFF0D9488),
                    ],
                  ),
                  boxShadow:
                      floating
                          ? null
                          : [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPaused
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isPaused ? 'Visit paused' : 'Visit in progress',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            visit.customerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _BannerTimer(
                      start: effectiveStart,
                      isPaused: isPaused,
                      pausedSec: pausedSec,
                      totalPaused: totalPaused,
                      activeElapsedSec: activeElapsedSec,
                      activeSnapshotMs: activeSnapshotMs,
                    ),
                    const SizedBox(width: 4),
                    if (hasMultiple) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${activeVisits.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => showOpenVisitsSheet(context),
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        iconSize: 22,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ] else
                      Icon(
                        Icons.chevron_right,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 22,
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        final animatedInner = AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0, -0.08),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offsetAnimation, child: child),
            );
          },
          child: inner,
        );

        if (!floating) return animatedInner;

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Material(
            color: Colors.transparent,
            elevation: 12,
            shadowColor: AppColors.primary.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: animatedInner,
          ),
        );
      },
    );
  }
}

class _BannerTimer extends StatelessWidget {
  const _BannerTimer({
    required this.start,
    required this.isPaused,
    required this.pausedSec,
    required this.totalPaused,
    required this.activeElapsedSec,
    required this.activeSnapshotMs,
  });

  final DateTime start;
  final bool isPaused;
  final int? pausedSec;
  final int totalPaused;
  final int? activeElapsedSec;
  final int? activeSnapshotMs;

  @override
  Widget build(BuildContext context) {
    if (isPaused) {
      final sec = visitPausedElapsedSeconds(
        effectiveStart: start,
        totalPausedSeconds: totalPaused,
        pausedElapsedSeconds: pausedSec,
      );
      return Text(
        formatVisitElapsedHms(sec),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      );
    }

    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (x) => x),
      builder: (context, snapshot) {
        final elapsedSec = visitRunningElapsedSeconds(
          effectiveStart: start,
          totalPausedSeconds: totalPaused,
          activeElapsedSeconds: activeElapsedSec,
          activeSnapshotMs: activeSnapshotMs,
        );
        return Text(
          formatVisitElapsedHms(elapsedSec),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}

/// Live timer shown for each row in [showOpenVisitsSheet] (dark text variant).
class _OpenVisitRowTimer extends StatelessWidget {
  const _OpenVisitRowTimer({
    required this.start,
    required this.isPaused,
    required this.pausedSec,
    required this.totalPaused,
    required this.activeElapsedSec,
    required this.activeSnapshotMs,
  });

  final DateTime start;
  final bool isPaused;
  final int? pausedSec;
  final int totalPaused;
  final int? activeElapsedSec;
  final int? activeSnapshotMs;

  static const _style = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    if (isPaused) {
      final sec = visitPausedElapsedSeconds(
        effectiveStart: start,
        totalPausedSeconds: totalPaused,
        pausedElapsedSeconds: pausedSec,
      );
      return Text(formatVisitElapsedHms(sec), style: _style);
    }
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (x) => x),
      builder: (context, snapshot) {
        final elapsedSec = visitRunningElapsedSeconds(
          effectiveStart: start,
          totalPausedSeconds: totalPaused,
          activeElapsedSeconds: activeElapsedSec,
          activeSnapshotMs: activeSnapshotMs,
        );
        return Text(formatVisitElapsedHms(elapsedSec), style: _style);
      },
    );
  }
}
