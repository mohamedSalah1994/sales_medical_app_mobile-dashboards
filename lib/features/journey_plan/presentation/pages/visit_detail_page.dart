import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sales_medical_app_mobile/core/error/error_message_helper.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/core/utils/launch_google_maps.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_state.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/utils/visit_execution_status.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/utils/visit_start_eligibility.dart';

class VisitDetailPage extends StatelessWidget {
  const VisitDetailPage({super.key, required this.visit});

  final Visit visit;

  String _getVisitTypeName(int? visitType) {
    switch (visitType) {
      case 1:
        return 'Normal';
      case 2:
        return 'Coach';
      case 3:
        return 'Double';
      default:
        return 'Unknown';
    }
  }

  String _getStatusName(int? status) {
    switch (status) {
      case 1:
        return 'Planned';
      case 2:
        return 'In Progress';
      case 3:
        return 'Completed';
      case 4:
        return 'Cancelled';
      case 5:
        return 'No Show';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(int? status) {
    switch (status) {
      case 1:
        return AppColors.primary;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.success;
      case 4:
        return AppColors.error;
      case 5:
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
      buildWhen: (prev, curr) =>
          prev.visits != curr.visits ||
          prev.isLoading != curr.isLoading ||
          prev.journeyPlan != curr.journeyPlan ||
          prev.endedVisitElapsedSeconds != curr.endedVisitElapsedSeconds ||
          prev.pausedVisitElapsedSeconds != curr.pausedVisitElapsedSeconds ||
          prev.pauseStartTimestampMs != curr.pauseStartTimestampMs,
      builder: (context, state) {
        final displayVisit = state.visits.any((v) => v.id == visit.id)
            ? state.visits.firstWhere((v) => v.id == visit.id)
            : visit;
        final canStartVisit = showStartVisitButton(state, displayVisit);
        final cardColor =
            displayVisit.supervisorId != null &&
                    displayVisit.supervisorId!.isNotEmpty
                ? AppColors.warning
                : AppColors.primary;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: Text(
              'Visit Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VisitSummaryCard(
                  visit: displayVisit,
                  cardColor: cardColor,
                  getVisitTypeName: _getVisitTypeName,
                  getStatusName: _getStatusName,
                  getStatusColor: _getStatusColor,
                  endedVisitElapsedSeconds: state.endedVisitElapsedSeconds,
                  pausedVisitElapsedSeconds: state.pausedVisitElapsedSeconds,
                  pauseStartTimestampMs: state.pauseStartTimestampMs,
                ),
                const SizedBox(height: 24),
                _VisitActionsSection(
                  visit: displayVisit,
                  isLoading: state.isLoading,
                  showStartVisitButton: canStartVisit,
                  getStatusName: _getStatusName,
                  getStatusColor: _getStatusColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VisitSummaryCard extends StatelessWidget {
  const _VisitSummaryCard({
    required this.visit,
    required this.cardColor,
    required this.getVisitTypeName,
    required this.getStatusName,
    required this.getStatusColor,
    required this.endedVisitElapsedSeconds,
    required this.pausedVisitElapsedSeconds,
    required this.pauseStartTimestampMs,
  });

  final Visit visit;
  final Color cardColor;
  final String Function(int?) getVisitTypeName;
  final String Function(int?) getStatusName;
  final Color Function(int?) getStatusColor;
  final Map<String, int> endedVisitElapsedSeconds;
  final Map<String, int> pausedVisitElapsedSeconds;
  final Map<String, int> pauseStartTimestampMs;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: cardColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor.withValues(alpha: 0.05),
              cardColor.withValues(alpha: 0.02),
              Colors.white,
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VisitHeader(visit: visit, cardColor: cardColor),
            const SizedBox(height: 16),
            _VisitDivider(cardColor: cardColor),
            const SizedBox(height: 16),
            _VisitDetailsList(
              visit: visit,
              getVisitTypeName: getVisitTypeName,
              getStatusName: getStatusName,
              getStatusColor: getStatusColor,
              endedVisitElapsedSeconds: endedVisitElapsedSeconds,
              pausedVisitElapsedSeconds: pausedVisitElapsedSeconds,
              pauseStartTimestampMs: pauseStartTimestampMs,
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitActionsSection extends StatelessWidget {
  const _VisitActionsSection({
    required this.visit,
    required this.isLoading,
    required this.showStartVisitButton,
    required this.getStatusName,
    required this.getStatusColor,
  });

  final Visit visit;
  final bool isLoading;
  final bool showStartVisitButton;
  final String Function(int?) getStatusName;
  final Color Function(int?) getStatusColor;

  Future<({double? lat, double? lng})> _getCurrentPosition(BuildContext context) async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyErrorMessage(e.toString())),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return (lat: null, lng: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final user = authState.loginResponse?.user;
    final isSalesRep = user?.role.toLowerCase() == 'salesrep';
    if (!isSalesRep) return const SizedBox.shrink();

    final state = context.watch<JourneyPlanCubit>().state;
    final endedMap = state.endedVisitElapsedSeconds;
    final isCanceled = VisitExecutionStatus.isVisitCancelled(
      visit,
      endedVisitElapsedSeconds: endedMap,
    );
    final isClosed = VisitExecutionStatus.isVisitEnded(
      visit,
      endedVisitElapsedSeconds: endedMap,
    );
    final isPaused = VisitExecutionStatus.isVisitPausedFromTiming(
      visit,
      pausedVisitElapsedSeconds: state.pausedVisitElapsedSeconds,
      pauseStartTimestampMs: state.pauseStartTimestampMs,
      endedVisitElapsedSeconds: endedMap,
    );
    final isStarted =
        VisitExecutionStatus.isVisitInProgress(
          visit,
          endedVisitElapsedSeconds: endedMap,
        ) &&
        !isPaused;
    final isOpen =
        VisitExecutionStatus.isVisitPlanned(
          visit,
          endedVisitElapsedSeconds: endedMap,
        ) &&
        !isClosed &&
        !isCanceled &&
        !isPaused &&
        !isStarted;

    if (isClosed || isCanceled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              isClosed ? Icons.flag_circle : Icons.cancel_outlined,
              size: 16,
              color: isClosed ? AppColors.success : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              isClosed ? 'Visit Ended' : 'Canceled',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isClosed ? AppColors.success : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        if (isOpen && showStartVisitButton) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : () async {
                      final pos = await _getCurrentPosition(context);
                      if (!context.mounted) return;
                      await context.read<JourneyPlanCubit>().startVisit(
                            visit.id,
                            latitude: pos.lat,
                            longitude: pos.lng,
                          );
                    },
              icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.play_arrow, size: 18),
              label: Text(isLoading ? 'Starting...' : 'Start Visit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              onPressed: isLoading ? null : () => context.read<JourneyPlanCubit>().pauseVisit(visit.id),
              icon: const Icon(Icons.pause, size: 18),
              label: const Text('Pause Visit'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              onPressed: isLoading
                  ? null
                  : () async {
                      final pos = await _getCurrentPosition(context);
                      if (!context.mounted) return;
                      await context.read<JourneyPlanCubit>().checkOutVisit(
                            visit.id,
                            latitude: pos.lat,
                            longitude: pos.lng,
                          );
                    },
              icon: const Icon(Icons.stop, size: 18),
              label: const Text('End Visit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              onPressed: isLoading ? null : () => context.read<JourneyPlanCubit>().resumeVisit(visit.id),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Resume Visit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              onPressed: isLoading
                  ? null
                  : () async {
                      final pos = await _getCurrentPosition(context);
                      if (!context.mounted) return;
                      await context.read<JourneyPlanCubit>().checkOutVisit(
                            visit.id,
                            latitude: pos.lat,
                            longitude: pos.lng,
                          );
                    },
              icon: const Icon(Icons.stop, size: 18),
              label: const Text('End Visit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

class _VisitHeader extends StatelessWidget {
  const _VisitHeader({
    required this.visit,
    required this.cardColor,
  });

  final Visit visit;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.visibility,
            color: cardColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                visit.customerName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (visit.userName != null && visit.userName!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  visit.userName!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (visit.supervisorId != null && visit.supervisorId!.isNotEmpty)
          _AssignedBadge(),
      ],
    );
  }
}

class _AssignedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.supervisor_account,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            'Assigned',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitDivider extends StatelessWidget {
  const _VisitDivider({required this.cardColor});

  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardColor.withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _VisitDetailsList extends StatelessWidget {
  const _VisitDetailsList({
    required this.visit,
    required this.getVisitTypeName,
    required this.getStatusName,
    required this.getStatusColor,
    required this.endedVisitElapsedSeconds,
    required this.pausedVisitElapsedSeconds,
    required this.pauseStartTimestampMs,
  });

  final Visit visit;
  final String Function(int?) getVisitTypeName;
  final String Function(int?) getStatusName;
  final Color Function(int?) getStatusColor;
  final Map<String, int> endedVisitElapsedSeconds;
  final Map<String, int> pausedVisitElapsedSeconds;
  final Map<String, int> pauseStartTimestampMs;

  Color _statusColorForLabel(String label) {
    switch (label) {
      case 'Planned':
        return AppColors.primary;
      case 'In Progress':
        return AppColors.warning;
      case 'Paused':
        return AppColors.warning;
      case 'Completed':
        return AppColors.success;
      case 'Cancelled':
        return AppColors.error;
      case 'No Show':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = VisitExecutionStatus.displayStatusLabel(
      visit,
      endedVisitElapsedSeconds: endedVisitElapsedSeconds,
      pausedVisitElapsedSeconds: pausedVisitElapsedSeconds,
      pauseStartTimestampMs: pauseStartTimestampMs,
    );

    return Column(
      children: [
        _DetailRow(label: 'Customer Name', value: visit.customerName),
        if (visit.customerCode != null && visit.customerCode!.isNotEmpty)
          _DetailRow(
            label: 'Customer Code',
            value: visit.customerCode!,
          ),
        _DetailRow(
          label: 'Visit Type',
          value: visit.visitType != null
              ? getVisitTypeName(visit.visitType)
              : 'N/A',
        ),
        _DetailRow(
          label: 'Status',
          value: statusLabel,
          valueColor: _statusColorForLabel(statusLabel),
        ),
        _DetailRow(
          label: 'Planned Date & Time',
          value: DateFormat('MMM dd, yyyy • HH:mm').format(visit.plannedDateTime),
        ),
        if (visit.actualStartDateTime != null)
          _DetailRow(
            label: 'Actual Start Time',
            value: DateFormat('MMM dd, yyyy • HH:mm')
                .format(visit.actualStartDateTime!),
          ),
        if (visit.actualEndDateTime != null)
          _DetailRow(
            label: 'Actual End Time',
            value: DateFormat('MMM dd, yyyy • HH:mm')
                .format(visit.actualEndDateTime!),
          ),
        if (visit.supervisorName != null && visit.supervisorName!.isNotEmpty)
          _SupervisorInfo(supervisorName: visit.supervisorName!),
        if (visit.notes != null && visit.notes!.isNotEmpty)
          _NotesInfo(notes: visit.notes!),
        if (visit.checkInLatitude != null && visit.checkInLongitude != null)
          _LocationInfo(
            label: 'Check-In Location',
            icon: Icons.location_on,
            latitude: visit.checkInLatitude!,
            longitude: visit.checkInLongitude!,
          ),
        if (visit.checkOutLatitude != null && visit.checkOutLongitude != null)
          _LocationInfo(
            label: 'Check-Out Location',
            icon: Icons.location_off,
            latitude: visit.checkOutLatitude!,
            longitude: visit.checkOutLongitude!,
          ),
        _GoogleMapsLinkInfo(visit: visit),
        if (visit.createdAt != null)
          _DetailRow(
            label: 'Created At',
            value: DateFormat('MMM dd, yyyy • HH:mm').format(visit.createdAt!),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
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

class _SupervisorInfo extends StatelessWidget {
  const _SupervisorInfo({required this.supervisorName});

  final String supervisorName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.supervisor_account,
                size: 20,
                color: AppColors.warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supervisor',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      supervisorName,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotesInfo extends StatelessWidget {
  const _NotesInfo({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notes,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationInfo extends StatelessWidget {
  const _LocationInfo({
    required this.label,
    required this.icon,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final IconData icon;
  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoogleMapsLinkInfo extends StatefulWidget {
  const _GoogleMapsLinkInfo({required this.visit});

  final Visit visit;

  @override
  State<_GoogleMapsLinkInfo> createState() => _GoogleMapsLinkInfoState();
}

class _GoogleMapsLinkInfoState extends State<_GoogleMapsLinkInfo> {
  String _generateGoogleMapsLink(double latitude, double longitude) {
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
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
          _showLocationErrorDialog('Location services are disabled. Please enable location services in your device settings.');
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            Navigator.of(context).pop();
            _showLocationErrorDialog('Location permissions are denied. Please grant location permissions to use this feature.');
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          Navigator.of(context).pop();
          _showLocationErrorDialog('Location permissions are permanently denied. Please enable them in app settings.', showSettingsButton: true);
        }
        return;
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final mapsLink = _generateGoogleMapsLink(position.latitude, position.longitude);
      if (mounted) {
        Navigator.of(context).pop();
        _showEditDialog(mapsLink);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showLocationErrorDialog(userFriendlyErrorMessage(e.toString()));
      }
    }
  }

  void _showLocationErrorDialog(String message, {bool showSettingsButton = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Error'),
        content: Text(message),
        actions: [
          if (showSettingsButton)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
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

  Future<void> _openGoogleMaps() async {
    bool success = false;
    try {
      final webUrl = Uri.parse('https://www.google.com/maps');
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      success = true;
    } catch (e) {
      try {
        Uri? platformUrl;
        if (Theme.of(context).platform == TargetPlatform.android) {
          platformUrl = Uri.parse('geo:0,0?q=');
        } else if (Theme.of(context).platform == TargetPlatform.iOS) {
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
              content: Text(userFriendlyErrorMessage(e2.toString())),
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
          content: Text('Google Maps opened. Select a location, tap Share, copy the link, and paste it in the field above.'),
          duration: Duration(seconds: 4),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showEditDialog([String? initialValue]) {
    final controller = TextEditingController(
      text: initialValue ?? widget.visit.effectiveGoogleMapsLink ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Google Maps Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Google Maps Link',
                hintText: 'https://www.google.com/maps?q=...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location, size: 18),
                    label: const Text('Get Current Location'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openGoogleMaps,
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('Open Maps'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final link = controller.text.trim();
              if (link.isNotEmpty) {
                context.read<JourneyPlanCubit>().updateVisit(
                  visitId: widget.visit.id,
                  googleMapsLink: link,
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Google Maps link updated successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _openMapsLink(BuildContext context, String link) async {
    debugPrint('[maps] visit_detail_page tap link="$link"');
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await launchGoogleMapsFromRaw(link);
      if (!ok && mounted && context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(userFriendlyErrorMessage(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapsLink = widget.visit.effectiveGoogleMapsLink;
    final hasLink = mapsLink != null && mapsLink.isNotEmpty;

    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasLink 
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasLink
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.map,
                size: 20,
                color: hasLink ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Maps Link',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasLink)
                      InkWell(
                        onTap: () => _openMapsLink(context, mapsLink),
                        child: Text(
                          mapsLink,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      Text(
                        'No link set',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              if (hasLink)
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  color: AppColors.primary,
                  onPressed: () => _openMapsLink(context, mapsLink),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(hasLink ? Icons.edit : Icons.add, size: 18),
                color: AppColors.primary,
                onPressed: () => _showEditDialog(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
