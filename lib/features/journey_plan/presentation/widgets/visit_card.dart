import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/error/error_message_helper.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/core/utils/launch_google_maps.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/pages/visit_detail_page.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/widgets/info_item_widget.dart';

class VisitCard extends StatelessWidget {
  const VisitCard({super.key, required this.visit});

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

  Color get _statusColor {
    if (visit.supervisorId != null && visit.supervisorId!.isNotEmpty) {
      return AppColors.warning;
    }
    return AppColors.primary;
  }

  void _onTap(BuildContext context) {
    final journeyPlanCubit = context.read<JourneyPlanCubit>();
    final authCubit = context.read<AuthCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: journeyPlanCubit),
                BlocProvider.value(value: authCubit),
              ],
              child: VisitDetailPage(visit: visit),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _statusColor.withValues(alpha: 0.3),
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
                _statusColor.withValues(alpha: 0.05),
                _statusColor.withValues(alpha: 0.02),
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VisitHeader(statusColor: _statusColor, visit: visit),
                const SizedBox(height: 12),
                _VisitBadges(
                  visit: visit,
                  getVisitTypeName: _getVisitTypeName,
                  showVisitTypeBadge: false,
                ),
                const SizedBox(height: 12),
                _VisitDivider(statusColor: _statusColor),
                const SizedBox(height: 10),
                _CustomerName(customerName: visit.customerName),
                const SizedBox(height: 10),
                _VisitInfoRow(
                  visit: visit,
                  getVisitTypeName: _getVisitTypeName,
                  statusColor: _statusColor,
                ),
                if (visit.supervisorName != null &&
                    visit.supervisorName!.isNotEmpty)
                  _SupervisorInfo(
                    supervisorName: visit.supervisorName!,
                    visitType: visit.visitType,
                    getVisitTypeName: _getVisitTypeName,
                  ),
                if (visit.effectiveGoogleMapsLink != null &&
                    visit.effectiveGoogleMapsLink!.isNotEmpty)
                  _GoogleMapsLink(
                    googleMapsLink: visit.effectiveGoogleMapsLink!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleMapsLink extends StatelessWidget {
  const _GoogleMapsLink({required this.googleMapsLink});

  final String googleMapsLink;

  Future<void> _openMapsLink(BuildContext context) async {
    debugPrint('[maps] visit_card tap link="$googleMapsLink"');
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await launchGoogleMapsFromRaw(googleMapsLink);
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
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        InkWell(
          onTap: () => _openMapsLink(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
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
        ),
      ],
    );
  }
}

class _VisitHeader extends StatelessWidget {
  const _VisitHeader({required this.statusColor, required this.visit});

  final Color statusColor;
  final Visit visit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.visibility, color: statusColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (visit.userName != null && visit.userName!.isNotEmpty)
                Text(
                  visit.userName!,
                  style: const TextStyle(
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

class _VisitBadges extends StatelessWidget {
  const _VisitBadges({
    required this.visit,
    required this.getVisitTypeName,
    this.showVisitTypeBadge = false,
  });

  final Visit visit;
  final String Function(int?) getVisitTypeName;
  final bool showVisitTypeBadge;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (showVisitTypeBadge &&
            visit.visitType != null &&
            visit.visitType != 1)
          _VisitTypeBadge(
            visitType: visit.visitType!,
            getVisitTypeName: getVisitTypeName,
          ),
        if (visit.supervisorId != null && visit.supervisorId!.isNotEmpty)
          _SupervisorBadge(visit: visit, getVisitTypeName: getVisitTypeName),
      ],
    );
  }
}

class _VisitTypeBadge extends StatelessWidget {
  const _VisitTypeBadge({
    required this.visitType,
    required this.getVisitTypeName,
  });

  final int visitType;
  final String Function(int?) getVisitTypeName;

  @override
  Widget build(BuildContext context) {
    final isCoaching = visitType == 2;
    final isDouble = visitType == 3;
    final badgeColor =
        isCoaching
            ? AppColors.warning
            : isDouble
            ? AppColors.error
            : AppColors.textSecondary;
    final badgeText = getVisitTypeName(visitType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCoaching ? Icons.school_outlined : Icons.people_outline,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupervisorBadge extends StatelessWidget {
  const _SupervisorBadge({required this.visit, required this.getVisitTypeName});

  final Visit visit;
  final String Function(int?) getVisitTypeName;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final user = authState.loginResponse?.user;
    final currentUserId = user?.id;
    final isSupervisorAssigned = visit.supervisorId == currentUserId;
    final isSalesRep = user?.role.toLowerCase() == 'salesrep';

    if (!isSupervisorAssigned && !isSalesRep) {
      return const SizedBox.shrink();
    }

    final supervisorLabel =
        isSupervisorAssigned
            ? 'Assigned'
            : (visit.supervisorName ?? 'Supervisor');
    final visitTypeLabel =
        visit.visitType != null && visit.visitType != 1
            ? ' (${getVisitTypeName(visit.visitType)})'
            : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          Icon(Icons.supervisor_account, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            '$supervisorLabel$visitTypeLabel',
            style: const TextStyle(
              fontSize: 10,
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
  const _VisitDivider({required this.statusColor});

  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withValues(alpha: 0.2), Colors.transparent],
        ),
      ),
    );
  }
}

class _CustomerName extends StatelessWidget {
  const _CustomerName({required this.customerName});

  final String customerName;

  @override
  Widget build(BuildContext context) {
    return Text(
      customerName,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _VisitInfoRow extends StatelessWidget {
  const _VisitInfoRow({
    required this.visit,
    required this.getVisitTypeName,
    required this.statusColor,
  });

  final Visit visit;
  final String Function(int?) getVisitTypeName;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InfoItemWidget(
            icon: Icons.access_time,
            label: 'Planned',
            value: DateFormat('MMM dd, yyyy').format(visit.plannedDateTime),
            iconColor: statusColor,
          ),
        ),
      ],
    );
  }
}

class _SupervisorInfo extends StatelessWidget {
  const _SupervisorInfo({
    required this.supervisorName,
    required this.visitType,
    required this.getVisitTypeName,
  });

  final String supervisorName;
  final int? visitType;
  final String Function(int?) getVisitTypeName;

  @override
  Widget build(BuildContext context) {
    final visitTypeLabel =
        visitType != null && visitType != 1
            ? ' (${getVisitTypeName(visitType)})'
            : '';
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.supervisor_account,
                size: 16,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Supervisor: $supervisorName$visitTypeLabel',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
