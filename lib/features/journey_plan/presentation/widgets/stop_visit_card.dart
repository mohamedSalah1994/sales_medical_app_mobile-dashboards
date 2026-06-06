import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/di/service_locator.dart';
import 'package:sales_medical_app_mobile/core/error/error_message_helper.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/core/utils/launch_google_maps.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_state.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/utils/visit_elapsed_seconds.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/utils/visit_execution_status.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/utils/visit_start_eligibility.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/repositories/survey_repository.dart';

/// Same card as in journey plan "Existing Visits": number badge, optional edit,
/// supervisor badge, customer, date, duration, View on Google Maps, and
/// Start/Pause/Resume/End status buttons. No tap-to-detail; all actions on card.
class StopVisitCard extends StatelessWidget {
  const StopVisitCard({
    super.key,
    required this.visit,
    this.sequenceNo,
    this.durationMinutes,
    this.showEditIcon = false,
    this.onEdit,
    this.showActionsMenu = false,
    this.showActionsButton = false,
    this.onViewActions,
    this.disableForPastDate = false,
    this.onCreateCustomer,
    this.onCreateSalesOrder,
    this.onCreateDelivery,
    this.onCreateReturn,
    this.onCreateIncomingPayment,
    this.onSurvey,
  });

  final Visit visit;
  final int? sequenceNo;
  final int? durationMinutes;
  final bool showEditIcon;
  final VoidCallback? onEdit;
  final bool showActionsMenu;

  /// When true, show "Actions (n)" button instead of [sequenceNo] (e.g. standalone visit list).
  final bool showActionsButton;
  final VoidCallback? onViewActions;

  /// When true, for visits with planned date before today: hide timer and action buttons (e.g. standalone list).
  final bool disableForPastDate;
  final VoidCallback? onCreateCustomer;
  final VoidCallback? onCreateSalesOrder;
  final VoidCallback? onCreateDelivery;
  final VoidCallback? onCreateReturn;
  final VoidCallback? onCreateIncomingPayment;
  final VoidCallback? onSurvey;

  static String _formatElapsed(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  static String _getVisitTypeName(int? visitType) {
    switch (visitType) {
      case 1:
        return 'Normal';
      case 2:
        return 'Coaching';
      case 3:
        return 'Double';
      default:
        return 'Unknown';
    }
  }

  static String _formatVisitDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • HH:mm').format(dateTime);
  }

  static String _formatDurationMinutes(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final totalSeconds = safe.inSeconds;
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> _getLocationAndSupervisorAttendance(
    BuildContext context,
    Visit visit, {
    required String action,
  }) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await Geolocator.openLocationSettings();
        if (!serviceEnabled) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enable location services'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!context.mounted) return;
      await context.read<JourneyPlanCubit>().supervisorAttendVisit(
        visit.id,
        action: action,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyErrorMessage(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Resolves the row to show for **Actions (n)** and menus.
  ///
  /// After ERP flows, [JourneyPlanCubit.refreshJourneyPlanFromServer] updates embedded
  /// stops with merged [Visit.actions], while [JourneyPlanState.visits] can stay stale
  /// until a full list reload. Prefer the copy with more actions; on a tie, prefer the
  /// embedded plan visit when present so journey cards update immediately without ending
  /// the visit.
  Visit _resolveDisplayVisit(JourneyPlanState state) {
    Visit? fromList;
    for (final v in state.visits) {
      if (v.id == visit.id) {
        fromList = v;
        break;
      }
    }
    Visit? fromPlan;
    final plan = state.journeyPlan;
    if (plan != null) {
      for (final s in plan.stops) {
        final v = s.visit;
        if (v != null && v.id == visit.id) {
          fromPlan = v;
          break;
        }
      }
    }
    if (fromList == null && fromPlan == null) return visit;
    if (fromList == null) return fromPlan!;
    if (fromPlan == null) return fromList;
    if (fromPlan.actions.length != fromList.actions.length) {
      return fromPlan.actions.length > fromList.actions.length
          ? fromPlan
          : fromList;
    }
    return fromPlan;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
      buildWhen:
          (prev, curr) =>
              prev.visits != curr.visits ||
              prev.journeyPlan != curr.journeyPlan ||
              prev.journeyPlan?.stops != curr.journeyPlan?.stops ||
              prev.isLoading != curr.isLoading ||
              prev.isOffline != curr.isOffline ||
              prev.pausedVisitElapsedSeconds !=
                  curr.pausedVisitElapsedSeconds ||
              prev.totalPausedDurationSeconds !=
                  curr.totalPausedDurationSeconds ||
              prev.actualStartTimestampMs != curr.actualStartTimestampMs ||
              prev.activeVisitElapsedSeconds !=
                  curr.activeVisitElapsedSeconds ||
              prev.activeVisitSnapshotTimestampMs !=
                  curr.activeVisitSnapshotTimestampMs ||
              prev.endedVisitElapsedSeconds != curr.endedVisitElapsedSeconds,
      builder: (context, state) {
        final displayVisit = _resolveDisplayVisit(state);
        final canStartVisit = showStartVisitButton(state, displayVisit);
        final isPastVisit =
            disableForPastDate &&
            !visitPlannedDateIsToday(displayVisit.plannedDateTime);
        return Opacity(
          opacity: isPastVisit ? 0.75 : 1,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sequenceNo != null ||
                    showEditIcon ||
                    showActionsMenu ||
                    showActionsButton)
                  Row(
                    children: [
                      if (showActionsButton && onViewActions != null)
                        _VisitActionsCountBadge(
                          key: ObjectKey(displayVisit),
                          visitId: displayVisit.id,
                          erpActionsCount: displayVisit.actions.length,
                          onTap: onViewActions!,
                        )
                      else if (sequenceNo != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$sequenceNo',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      if (showEditIcon && onEdit != null) ...[
                        if (sequenceNo != null ||
                            (showActionsButton && onViewActions != null))
                          const SizedBox(width: 8),
                        IconButton(
                          onPressed: onEdit,
                          icon: Icon(
                            Icons.edit,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                      if (showActionsMenu &&
                          (onCreateCustomer != null ||
                              onCreateSalesOrder != null ||
                              onCreateDelivery != null ||
                              onCreateReturn != null ||
                              onCreateIncomingPayment != null ||
                              onSurvey != null)) ...[
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: AppColors.primary),
                          tooltip: AppLocalizations.of(context)!.actions,
                          onSelected: (value) {
                            if (value == 'create_customer') {
                              onCreateCustomer?.call();
                            } else if (value == 'create_sales_order' &&
                                !isPastVisit) {
                              onCreateSalesOrder?.call();
                            } else if (value == 'create_delivery' &&
                                !isPastVisit) {
                              onCreateDelivery?.call();
                            } else if (value == 'create_return' &&
                                !isPastVisit) {
                              onCreateReturn?.call();
                            } else if (value == 'create_incoming_payment' &&
                                !isPastVisit) {
                              onCreateIncomingPayment?.call();
                            } else if (value == 'survey' && !isPastVisit) {
                              onSurvey?.call();
                            }
                          },
                          itemBuilder: (ctx) {
                            final l10n = AppLocalizations.of(ctx)!;
                            return [
                              if (onCreateCustomer != null)
                                PopupMenuItem<String>(
                                  value: 'create_customer',
                                  child: Text(l10n.createCustomer),
                                ),
                              if (onCreateSalesOrder != null)
                                PopupMenuItem<String>(
                                  value: 'create_sales_order',
                                  enabled: !isPastVisit,
                                  child: Text(l10n.createSalesOrder),
                                ),
                              if (onCreateDelivery != null)
                                PopupMenuItem<String>(
                                  value: 'create_delivery',
                                  enabled: !isPastVisit,
                                  child: Text(l10n.createDelivery),
                                ),
                              if (onCreateReturn != null)
                                PopupMenuItem<String>(
                                  value: 'create_return',
                                  enabled: !isPastVisit,
                                  child: Text(l10n.createReturn),
                                ),
                              if (onCreateIncomingPayment != null)
                                PopupMenuItem<String>(
                                  value: 'create_incoming_payment',
                                  enabled: !isPastVisit,
                                  child: Text(l10n.createIncomingPayment),
                                ),
                              if (onSurvey != null)
                                PopupMenuItem<String>(
                                  value: 'survey',
                                  enabled: !isPastVisit,
                                  child: Text(l10n.visitSurvey),
                                ),
                            ];
                          },
                        ),
                      ],
                    ],
                  ),
                if (sequenceNo != null ||
                    showEditIcon ||
                    showActionsMenu ||
                    showActionsButton)
                  const SizedBox(height: 12),
                _VisitSection(
                  visit: displayVisit,
                  durationMinutes: durationMinutes,
                  isOffline: state.isOffline,
                  isLoading: state.isLoading,
                  pausedVisitElapsedSeconds: state.pausedVisitElapsedSeconds,
                  totalPausedDurationSeconds: state.totalPausedDurationSeconds,
                  actualStartTimestampMs: state.actualStartTimestampMs,
                  activeVisitElapsedSeconds: state.activeVisitElapsedSeconds,
                  activeVisitSnapshotTimestampMs:
                      state.activeVisitSnapshotTimestampMs,
                  endedVisitElapsedSeconds: state.endedVisitElapsedSeconds,
                  formatElapsed: _formatElapsed,
                  formatVisitDateTime: _formatVisitDateTime,
                  formatDurationMinutes: _formatDurationMinutes,
                  showStartVisitButton: canStartVisit,
                  getVisitTypeName: _getVisitTypeName,
                  onSupervisorAttendance:
                      (context, action) => _getLocationAndSupervisorAttendance(
                        context,
                        displayVisit,
                        action: action,
                      ),
                  hideTimerAndButtonsForPastVisit: isPastVisit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VisitSection extends StatelessWidget {
  const _VisitSection({
    required this.visit,
    required this.durationMinutes,
    required this.isOffline,
    required this.isLoading,
    required this.pausedVisitElapsedSeconds,
    required this.totalPausedDurationSeconds,
    required this.actualStartTimestampMs,
    required this.activeVisitElapsedSeconds,
    required this.activeVisitSnapshotTimestampMs,
    required this.endedVisitElapsedSeconds,
    required this.formatElapsed,
    required this.formatVisitDateTime,
    required this.formatDurationMinutes,
    required this.showStartVisitButton,
    required this.getVisitTypeName,
    required this.onSupervisorAttendance,
    this.hideTimerAndButtonsForPastVisit = false,
  });

  final Visit visit;
  final int? durationMinutes;
  final bool isOffline;
  final bool isLoading;
  final Map<String, int> pausedVisitElapsedSeconds;
  final Map<String, int> totalPausedDurationSeconds;
  final Map<String, int> actualStartTimestampMs;
  final Map<String, int> activeVisitElapsedSeconds;
  final Map<String, int> activeVisitSnapshotTimestampMs;
  final Map<String, int> endedVisitElapsedSeconds;
  final String Function(Duration) formatElapsed;
  final String Function(DateTime) formatVisitDateTime;
  final String Function(Duration) formatDurationMinutes;
  final bool showStartVisitButton;
  final String Function(int?) getVisitTypeName;
  final Future<void> Function(BuildContext context, String action)
  onSupervisorAttendance;
  final bool hideTimerAndButtonsForPastVisit;

  Future<void> _getLocationAndCheckIn(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    _showBlockingLoader(context, message: 'Starting visit...');
    try {
      double? latitude;
      double? longitude;
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            final position = await Geolocator.getCurrentPosition();
            latitude = position.latitude;
            longitude = position.longitude;
          }
        }
      } catch (_) {}
      if (!context.mounted) return;
      await context.read<JourneyPlanCubit>().checkInVisit(
        visit.id,
        latitude: latitude,
        longitude: longitude,
      );
    } finally {
      if (navigator.canPop()) navigator.pop();
    }
  }

  void _showBlockingLoader(BuildContext context, {required String message}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 16),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _getLocationAndCheckOut(BuildContext context) async {
    double? latitude;
    double? longitude;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition();
          latitude = position.latitude;
          longitude = position.longitude;
        }
      }
    } catch (_) {}
    if (!context.mounted) return;
    await context.read<JourneyPlanCubit>().checkOutVisit(
      visit.id,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAssigned =
        visit.supervisorId != null && visit.supervisorId!.isNotEmpty;
    final endedSec = resolveEndedVisitDisplaySeconds(
      visit: visit,
      endedVisitElapsedSeconds: endedVisitElapsedSeconds,
      actualStartTimestampMs: actualStartTimestampMs,
    );
    final effectiveStart = visitEffectiveStart(visit, actualStartTimestampMs);
    final actualDuration =
        endedSec > 0
            ? Duration(seconds: endedSec)
            : (effectiveStart != null && visit.actualEndDateTime != null
                ? visit.actualEndDateTime!.difference(effectiveStart)
                : null);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isAssigned
                ? AppColors.warning.withValues(alpha: 0.05)
                : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isAssigned
                  ? AppColors.warning.withValues(alpha: 0.3)
                  : AppColors.border,
          width: isAssigned ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (visit.supervisorId != null && visit.supervisorId!.isNotEmpty) ...[
            Builder(
              builder: (context) {
                final statusInfo = _resolveSupervisorStatusBadge(
                  visit: visit,
                  endedVisitElapsedSeconds: endedVisitElapsedSeconds,
                  pausedVisitElapsedSeconds: pausedVisitElapsedSeconds,
                  hideTimerAndButtonsForPastVisit:
                      hideTimerAndButtonsForPastVisit,
                );
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.supervisor_account,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            visit.supervisorName ?? 'Supervisor Assigned',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (visit.visitType != null && visit.visitType != 1)
                      _AssignTypeBadge(
                        label: getVisitTypeName(visit.visitType),
                        isCoaching: visit.visitType == 2,
                      ),
                    if (statusInfo != null)
                      _VisitStatusMiniPill(
                        label: statusInfo.label,
                        icon: statusInfo.icon,
                        color: statusInfo.color,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
          ],
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
                  visit.customerName,
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
              Icon(Icons.access_time, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                DateFormat(
                  'MMM dd, yyyy • HH:mm',
                ).format(visit.plannedDateTime),
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          if (visit.actualStartDateTime != null &&
              !(hideTimerAndButtonsForPastVisit &&
                  visit.actualEndDateTime == null)) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Actual start: ${formatVisitDateTime(visit.actualStartDateTime!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (visit.actualEndDateTime != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.flag_circle_outlined,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Actual end: ${formatVisitDateTime(visit.actualEndDateTime!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (actualDuration != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timelapse, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  endedSec > 0
                      ? 'Visit time: ${formatVisitElapsedHms(endedSec)}'
                      : 'Actual duration: ${formatDurationMinutes(actualDuration)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          if (durationMinutes != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Duration: $durationMinutes minutes',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          _SupervisorAttendanceSection(
            visit: visit,
            isLoading: isLoading,
            isOffline: isOffline,
            onSupervisorAttendance: onSupervisorAttendance,
          ),
          if (_SupervisorAttendanceSection.shouldShow(context, visit))
            const SizedBox(height: 8),
          _GoogleMapsRow(visit: visit),
          const SizedBox(height: 12),
          _VisitStatusButtons(
            visit: visit,
            isLoading: isLoading,
            isOffline: isOffline,
            showStartVisitButton: showStartVisitButton,
            formatElapsed: formatElapsed,
            pausedVisitElapsedSeconds: pausedVisitElapsedSeconds,
            totalPausedDurationSeconds: totalPausedDurationSeconds,
            actualStartTimestampMs: actualStartTimestampMs,
            activeVisitElapsedSeconds: activeVisitElapsedSeconds,
            activeVisitSnapshotTimestampMs: activeVisitSnapshotTimestampMs,
            endedVisitElapsedSeconds: endedVisitElapsedSeconds,
            onCheckIn: _getLocationAndCheckIn,
            onCheckOut: _getLocationAndCheckOut,
            hideTimerAndButtons: hideTimerAndButtonsForPastVisit,
          ),
        ],
      ),
    );
  }
}

class _GoogleMapsRow extends StatelessWidget {
  const _GoogleMapsRow({required this.visit});

  final Visit visit;

  @override
  Widget build(BuildContext context) {
    final mapsLink = visit.effectiveGoogleMapsLink;
    final hasLink = mapsLink != null && mapsLink.isNotEmpty;

    if (hasLink) {
      return InkWell(
        onTap: () async {
          debugPrint('[maps] stop_visit_card tap link="$mapsLink"');
          final messenger = ScaffoldMessenger.of(context);
          try {
            final ok = await launchGoogleMapsFromRaw(mapsLink);
            if (!ok && context.mounted) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Could not open Google Maps'),
                  backgroundColor: AppColors.error,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(userFriendlyErrorMessage(e.toString())),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.map, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'View on Google Maps',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.open_in_new, size: 14, color: AppColors.primary),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            'No location provided',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SupervisorAttendanceSection extends StatelessWidget {
  const _SupervisorAttendanceSection({
    required this.visit,
    required this.isLoading,
    required this.isOffline,
    required this.onSupervisorAttendance,
  });

  final Visit visit;
  final bool isLoading;
  final bool isOffline;
  final Future<void> Function(BuildContext context, String action)
  onSupervisorAttendance;

  static bool shouldShow(BuildContext context, Visit visit) {
    final user = context.read<AuthCubit>().state.loginResponse?.user;
    final isSupervisor = user?.role.toLowerCase() == 'supervisor';
    final isAssignedToCurrentSupervisor =
        isSupervisor &&
        user?.id != null &&
        visit.supervisorId != null &&
        visit.supervisorId == user!.id;
    if (!isAssignedToCurrentSupervisor) return false;

    final endedMap =
        context.read<JourneyPlanCubit>().state.endedVisitElapsedSeconds;
    // Cancelled / no-show visits leave nothing for the supervisor to attend.
    if (VisitExecutionStatus.isVisitCancelled(
          visit,
          endedVisitElapsedSeconds: endedMap,
        ) ||
        VisitExecutionStatus.isVisitNoShow(visit)) {
      return false;
    }
    // For coaching / double visits the supervisor's attendance is independent
    // from the sales employee's: keep the section visible (prompt + action,
    // or attendance summary) even after the sales employee closed the visit.
    // The check-in / check-out button only renders while there's still an
    // action to take (`!hasCheckedOut`).
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShow(context, visit)) return const SizedBox.shrink();

    final hasCheckedIn = visit.supervisorCheckInAt != null;
    final hasCheckedOut = visit.supervisorCheckOutAt != null;
    final action = hasCheckedIn && !hasCheckedOut ? 'CheckOut' : 'CheckIn';
    final label =
        hasCheckedIn && !hasCheckedOut
            ? 'Supervisor Check Out'
            : 'Supervisor Attend';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.how_to_reg, size: 16, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasCheckedIn
                      ? (hasCheckedOut
                          ? 'Supervisor attended this visit'
                          : 'Supervisor currently attending')
                      : 'Assigned supervisor can attend this visit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          if (visit.supervisorCheckInAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Check-in: ${DateFormat('MMM dd, yyyy • HH:mm').format(visit.supervisorCheckInAt!)}',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
          if (visit.supervisorCheckOutAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Check-out: ${DateFormat('MMM dd, yyyy • HH:mm').format(visit.supervisorCheckOutAt!)}',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
          if (!hasCheckedOut) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    isLoading || isOffline
                        ? null
                        : () => onSupervisorAttendance(context, action),
                icon: Icon(hasCheckedIn ? Icons.logout : Icons.login, size: 18),
                label: Text(
                  isLoading ? 'Please wait...' : label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: BorderSide(color: AppColors.warning),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VisitStatusButtons extends StatelessWidget {
  const _VisitStatusButtons({
    required this.visit,
    required this.isLoading,
    required this.isOffline,
    required this.showStartVisitButton,
    required this.formatElapsed,
    required this.pausedVisitElapsedSeconds,
    required this.totalPausedDurationSeconds,
    required this.actualStartTimestampMs,
    required this.activeVisitElapsedSeconds,
    required this.activeVisitSnapshotTimestampMs,
    required this.endedVisitElapsedSeconds,
    required this.onCheckIn,
    required this.onCheckOut,
    this.hideTimerAndButtons = false,
  });

  final Visit visit;
  final bool isLoading;
  final bool isOffline;
  final bool showStartVisitButton;
  final String Function(Duration) formatElapsed;
  final Map<String, int> pausedVisitElapsedSeconds;
  final Map<String, int> totalPausedDurationSeconds;
  final Map<String, int> actualStartTimestampMs;
  final Map<String, int> activeVisitElapsedSeconds;
  final Map<String, int> activeVisitSnapshotTimestampMs;
  final Map<String, int> endedVisitElapsedSeconds;
  final Future<void> Function(BuildContext) onCheckIn;
  final Future<void> Function(BuildContext) onCheckOut;
  final bool hideTimerAndButtons;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.loginResponse?.user;
    final isSalesRep = user?.role.toLowerCase() == 'salesrep';
    final hasActualStart = visit.actualStartDateTime != null;
    final isCanceled = VisitExecutionStatus.isVisitCancelled(
      visit,
      endedVisitElapsedSeconds: endedVisitElapsedSeconds,
    );
    final isNoShow = VisitExecutionStatus.isVisitNoShow(visit);
    final isClosed = VisitExecutionStatus.isVisitEnded(
      visit,
      endedVisitElapsedSeconds: endedVisitElapsedSeconds,
    );
    final isPaused = VisitExecutionStatus.isVisitPausedFromTiming(
      visit,
      pausedVisitElapsedSeconds: pausedVisitElapsedSeconds,
      endedVisitElapsedSeconds: endedVisitElapsedSeconds,
    );
    final isStarted =
        VisitExecutionStatus.isVisitInProgress(
          visit,
          endedVisitElapsedSeconds: endedVisitElapsedSeconds,
        ) &&
        !isPaused;
    final isOpen =
        VisitExecutionStatus.isVisitPlanned(
          visit,
          endedVisitElapsedSeconds: endedVisitElapsedSeconds,
        ) &&
        !isClosed &&
        !isCanceled &&
        !isNoShow &&
        !isPaused &&
        !isStarted;

    if (isClosed || isCanceled || isNoShow) {
      final endedSec = resolveEndedVisitDisplaySeconds(
        visit: visit,
        endedVisitElapsedSeconds: endedVisitElapsedSeconds,
        actualStartTimestampMs: actualStartTimestampMs,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (isClosed ? AppColors.success : AppColors.textSecondary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isClosed ? AppColors.success : AppColors.textSecondary,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isClosed
                      ? Icons.flag_circle
                      : isNoShow
                      ? Icons.person_off_outlined
                      : Icons.cancel_outlined,
                  size: 16,
                  color: isClosed ? AppColors.success : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  isClosed
                      ? 'Visit Ended'
                      : isNoShow
                      ? 'No Show'
                      : 'Canceled',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color:
                        isClosed ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isClosed && endedSec > 0) ...[
            const SizedBox(height: 8),
            _VisitTimeRow(
              label: 'Visit time:',
              elapsedSeconds: endedSec,
              formatElapsed: formatElapsed,
            ),
          ],
        ],
      );
    }

    if (!isSalesRep) {
      // Non-sales-rep (supervisor / manager) viewers see the visit status
      // pill beside the supervisor flag at the top of the card (see
      // [_VisitSection.build]), so we don't repeat it at the bottom.
      return const SizedBox.shrink();
    }

    if (hideTimerAndButtons) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.textSecondary, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Past visit',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if ((isStarted || isPaused) &&
            visitEffectiveStart(visit, actualStartTimestampMs) != null) ...[
          _VisitElapsedTimer(
            visit: visit,
            isPaused: isPaused,
            actualStartTimestampMs: actualStartTimestampMs,
            pausedVisitElapsedSeconds: pausedVisitElapsedSeconds,
            totalPausedDurationSeconds: totalPausedDurationSeconds,
            activeVisitElapsedSeconds: activeVisitElapsedSeconds,
            activeVisitSnapshotTimestampMs: activeVisitSnapshotTimestampMs,
            formatElapsed: formatElapsed,
          ),
          const SizedBox(height: 8),
        ],
        if (isOpen) ...[
          if (showStartVisitButton)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () => onCheckIn(context),
                icon:
                    isLoading
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.play_arrow, size: 18),
                label: Text(
                  isLoading ? 'Starting...' : 'Start Visit',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          if (showStartVisitButton) const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  isLoading || isOffline
                      ? null
                      : () async {
                        final reason = await showDialog<String>(
                          context: context,
                          builder: (dialogContext) {
                            final controller = TextEditingController();
                            return AlertDialog(
                              title: const Text('Cancel Visit'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Are you sure you want to cancel this visit?',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: controller,
                                    decoration: const InputDecoration(
                                      labelText: 'Reason (Optional)',
                                      hintText: 'Enter cancellation reason...',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: 3,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(dialogContext).pop(),
                                  child: const Text('No'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(
                                      dialogContext,
                                    ).pop(controller.text.trim());
                                  },
                                  child: const Text('Yes, Cancel'),
                                ),
                              ],
                            );
                          },
                        );
                        if (reason != null && context.mounted) {
                          await context.read<JourneyPlanCubit>().cancelVisit(
                            visit.id,
                            reason: reason.isEmpty ? null : reason,
                          );
                        }
                      },
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text(
                'Cancel Visit',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
        if (isStarted) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  isLoading
                      ? null
                      : () =>
                          context.read<JourneyPlanCubit>().pauseVisit(visit.id),
              icon: const Icon(Icons.pause, size: 18),
              label: const Text(
                'Pause Visit',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : () => onCheckOut(context),
              icon: const Icon(Icons.stop, size: 18),
              label: const Text(
                'End Visit',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
        if (isPaused) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  isLoading
                      ? null
                      : () => context.read<JourneyPlanCubit>().resumeVisit(
                        visit.id,
                      ),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text(
                'Resume Visit',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : () => onCheckOut(context),
              icon: const Icon(Icons.stop, size: 18),
              label: const Text(
                'End Visit',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Loads survey response count for [visitId] so **Actions (n)** includes ERP
/// actions plus submitted surveys for this visit.
class _VisitActionsCountBadge extends StatefulWidget {
  const _VisitActionsCountBadge({
    super.key,
    required this.visitId,
    required this.erpActionsCount,
    required this.onTap,
  });

  final String visitId;
  final int erpActionsCount;
  final VoidCallback onTap;

  @override
  State<_VisitActionsCountBadge> createState() =>
      _VisitActionsCountBadgeState();
}

class _VisitActionsCountBadgeState extends State<_VisitActionsCountBadge> {
  int _surveyResponseCount = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await sl<SurveyRepository>().getSurveyResponses(
        visitId: widget.visitId,
        pageNumber: 1,
        pageSize: 200,
      );
      if (!mounted) return;
      setState(() {
        _surveyResponseCount = r.effectiveResponseCount;
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _surveyResponseCount = 0;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.erpActionsCount + _surveyResponseCount;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _loaded ? 'Actions ($total)' : 'Actions (${widget.erpActionsCount})',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _VisitTimeRow extends StatelessWidget {
  const _VisitTimeRow({
    required this.label,
    required this.elapsedSeconds,
    required this.formatElapsed,
  });

  final String label;
  final int elapsedSeconds;
  final String Function(Duration) formatElapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.timer, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            formatElapsed(Duration(seconds: elapsedSeconds)),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitElapsedTimer extends StatelessWidget {
  const _VisitElapsedTimer({
    required this.visit,
    required this.isPaused,
    required this.actualStartTimestampMs,
    required this.pausedVisitElapsedSeconds,
    required this.totalPausedDurationSeconds,
    required this.activeVisitElapsedSeconds,
    required this.activeVisitSnapshotTimestampMs,
    required this.formatElapsed,
  });

  final Visit visit;
  final bool isPaused;
  final Map<String, int> actualStartTimestampMs;
  final Map<String, int> pausedVisitElapsedSeconds;
  final Map<String, int> totalPausedDurationSeconds;
  final Map<String, int> activeVisitElapsedSeconds;
  final Map<String, int> activeVisitSnapshotTimestampMs;
  final String Function(Duration) formatElapsed;

  @override
  Widget build(BuildContext context) {
    final effectiveStart = visitEffectiveStart(visit, actualStartTimestampMs)!;
    final totalPaused = totalPausedDurationSeconds[visit.id] ?? 0;

    if (isPaused) {
      return _VisitTimeRow(
        label: 'Visit Time:',
        elapsedSeconds: visitPausedElapsedSeconds(
          effectiveStart: effectiveStart,
          totalPausedSeconds: totalPaused,
          pausedElapsedSeconds: pausedVisitElapsedSeconds[visit.id],
        ),
        formatElapsed: formatElapsed,
      );
    }

    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (tick) => tick),
      builder: (context, snapshot) {
        return _VisitTimeRow(
          label: 'Visit Time:',
          elapsedSeconds: visitRunningElapsedSeconds(
            effectiveStart: effectiveStart,
            totalPausedSeconds: totalPaused,
            activeElapsedSeconds: activeVisitElapsedSeconds[visit.id],
            activeSnapshotMs: activeVisitSnapshotTimestampMs[visit.id],
          ),
          formatElapsed: formatElapsed,
        );
      },
    );
  }
}

/// Resolves the visit lifecycle pill (label / icon / colour) shown beside the
/// supervisor flag on the card. Returns `null` for visits we don't want to
/// badge (e.g. cancelled / no-show), so the caller can simply skip rendering.
class _VisitStatusBadgeInfo {
  const _VisitStatusBadgeInfo({
    required this.label,
    required this.icon,
    required this.color,
  });
  final String label;
  final IconData icon;
  final Color color;
}

_VisitStatusBadgeInfo? _resolveSupervisorStatusBadge({
  required Visit visit,
  required Map<String, int> endedVisitElapsedSeconds,
  required Map<String, int> pausedVisitElapsedSeconds,
  required bool hideTimerAndButtonsForPastVisit,
}) {
  final isClosed = VisitExecutionStatus.isVisitEnded(
    visit,
    endedVisitElapsedSeconds: endedVisitElapsedSeconds,
  );
  if (isClosed) {
    return const _VisitStatusBadgeInfo(
      label: 'Closed',
      icon: Icons.flag_circle,
      color: AppColors.success,
    );
  }
  final isCancelled = VisitExecutionStatus.isVisitCancelled(
    visit,
    endedVisitElapsedSeconds: endedVisitElapsedSeconds,
  );
  if (isCancelled) {
    return const _VisitStatusBadgeInfo(
      label: 'Cancelled',
      icon: Icons.cancel_outlined,
      color: AppColors.textSecondary,
    );
  }
  if (VisitExecutionStatus.isVisitNoShow(visit)) {
    return const _VisitStatusBadgeInfo(
      label: 'No Show',
      icon: Icons.person_off_outlined,
      color: AppColors.textSecondary,
    );
  }
  final isPaused = VisitExecutionStatus.isVisitPausedFromTiming(
    visit,
    pausedVisitElapsedSeconds: pausedVisitElapsedSeconds,
    endedVisitElapsedSeconds: endedVisitElapsedSeconds,
  );
  final isInProgress =
      VisitExecutionStatus.isVisitInProgress(
        visit,
        endedVisitElapsedSeconds: endedVisitElapsedSeconds,
      ) &&
      !isPaused;
  if (isPaused || isInProgress) {
    return _VisitStatusBadgeInfo(
      label: isPaused ? 'Paused' : 'In Progress',
      icon: isPaused ? Icons.pause_circle_outline : Icons.play_circle_outline,
      color: AppColors.warning,
    );
  }
  // Planned date is in the past with no end / cancel evidence -> the visit
  // period elapsed without completion. Mirrors the journey plan
  // "Incompleted" badge so supervisors see consistent wording.
  if (hideTimerAndButtonsForPastVisit) {
    return const _VisitStatusBadgeInfo(
      label: 'Incompleted',
      icon: Icons.error_outline,
      color: AppColors.error,
    );
  }
  return const _VisitStatusBadgeInfo(
    label: 'Planned',
    icon: Icons.event_outlined,
    color: AppColors.primary,
  );
}

/// Compact status pill sized to sit next to the supervisor / assign-type
/// badges in the card header `Wrap`. Slimmer than the previous bottom-of-card
/// pill so the row stays on a single line at typical widths.
class _VisitStatusMiniPill extends StatelessWidget {
  const _VisitStatusMiniPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Coloured pill that flags a visit's assign type (Coaching or Double),
/// shown beside the supervisor strip when the visit has been promoted out
/// of the default individual type.
class _AssignTypeBadge extends StatelessWidget {
  const _AssignTypeBadge({required this.label, required this.isCoaching});

  final String label;
  final bool isCoaching;

  @override
  Widget build(BuildContext context) {
    final color = isCoaching ? AppColors.primary : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCoaching ? Icons.school_outlined : Icons.groups_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
