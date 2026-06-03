import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_state.dart';

class StepIndicatorWidget extends StatelessWidget {
  const StepIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
      buildWhen:
          (prev, curr) =>
              prev.currentStep != curr.currentStep ||
              prev.journeyPlan?.id != curr.journeyPlan?.id,
      builder: (context, state) {
        final currentStep = state.currentStep;
        final canOpenAddVisits = state.journeyPlan != null;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StepItemWidget(
                stepNumber: 1,
                title: AppLocalizations.of(context)!.createPlan,
                isActive: currentStep >= 1,
                isCompleted: currentStep > 1,
                enabled: true,
                onTap: () {
                  context.read<JourneyPlanCubit>().previousStep();
                },
              ),
              StepConnectorWidget(isActive: currentStep > 1),
              StepItemWidget(
                stepNumber: 2,
                title: AppLocalizations.of(context)!.addStops,
                isActive: currentStep >= 2,
                isCompleted: false,
                enabled: canOpenAddVisits,
                onTap: () {
                  if (!canOpenAddVisits) return;
                  context.read<JourneyPlanCubit>().nextStep();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class StepItemWidget extends StatelessWidget {
  const StepItemWidget({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.isActive,
    required this.isCompleted,
    required this.enabled,
    required this.onTap,
  });

  final int stepNumber;
  final String title;
  final bool isActive;
  final bool isCompleted;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveActive = enabled && isActive;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isCompleted
                        ? AppColors.success
                        : effectiveActive
                        ? AppColors.primary
                        : AppColors.border,
              ),
              child: Center(
                child:
                    isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                          '$stepNumber',
                          style: TextStyle(
                            color:
                                effectiveActive
                                    ? Colors.white
                                    : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: effectiveActive ? FontWeight.w600 : FontWeight.normal,
                color:
                    effectiveActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StepConnectorWidget extends StatelessWidget {
  const StepConnectorWidget({super.key, required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: 60,
      height: 2,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
