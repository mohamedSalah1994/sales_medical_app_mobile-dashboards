import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/journey_plan.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_state.dart';

class Step1CreatePlan extends StatefulWidget {
  const Step1CreatePlan({super.key});

  @override
  State<Step1CreatePlan> createState() => _Step1CreatePlanState();
}

class _Step1CreatePlanState extends State<Step1CreatePlan> {
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Store original values when editing starts
  int? _originalPlanType;
  DateTime? _originalStartDate;
  DateTime? _originalEndDate;
  String? _originalNotes;

  @override
  void initState() {
    super.initState();
    // Check if user is supervisor and load subordinates if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthCubit>().state;
      final user = authState.loginResponse?.user;
      final state = context.read<JourneyPlanCubit>().state;

      if (user != null && user.role.toLowerCase() == 'supervisor') {
        context.read<JourneyPlanCubit>().loadSubordinates(user.id);
        // For supervisors, default to "For Another User" when creating (not editing)
        if (!state.isEditing && state.createForMyself) {
          context.read<JourneyPlanCubit>().setCreateForMyself(
            false,
            userId: user.id,
          );
        }
      }

      // Pre-populate form if editing and store original values
      if (state.isEditing && state.journeyPlan != null) {
        _notesController.text = state.notes;
        _originalPlanType = state.planType;
        _originalStartDate = state.startDate;
        _originalEndDate = state.endDate;
        _originalNotes = state.notes;
      }
    });
  }

  bool _hasChanges(JourneyPlanState state) {
    if (!state.isEditing) return true; // Always allow create

    // Compare current values with original values
    if (_originalPlanType != state.planType) return true;
    if (_originalStartDate == null || state.startDate == null) {
      if (_originalStartDate != state.startDate) return true;
    } else {
      if (_originalStartDate!.millisecondsSinceEpoch !=
          state.startDate!.millisecondsSinceEpoch)
        return true;
    }
    if (_originalEndDate == null || state.endDate == null) {
      if (_originalEndDate != state.endDate) return true;
    } else {
      if (_originalEndDate!.millisecondsSinceEpoch !=
          state.endDate!.millisecondsSinceEpoch)
        return true;
    }
    if (_originalNotes != state.notes) return true;

    return false; // No changes detected
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<JourneyPlanCubit, JourneyPlanState>(
      listenWhen:
          (prev, curr) =>
              (prev.isLoading != curr.isLoading && !curr.isLoading) ||
              (prev.currentStep != curr.currentStep) ||
              (prev.journeyPlan != curr.journeyPlan && curr.isEditing) ||
              (prev.errorMessage != curr.errorMessage),
      listener: (context, state) {
        // Store original values when journey plan is loaded for editing
        if (state.isEditing &&
            state.journeyPlan != null &&
            (_originalPlanType == null || _originalStartDate == null)) {
          _originalPlanType = state.planType;
          _originalStartDate = state.startDate;
          _originalEndDate = state.endDate;
          _originalNotes = state.notes;
          if (_notesController.text != state.notes) {
            _notesController.text = state.notes;
          }
        }

        // Show error in popup dialog only when error message appears (not when it's cleared)
        if (!state.isLoading && state.errorMessage != null) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Error',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    state.errorMessage!,
                    style: const TextStyle(fontSize: 14),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
          );
        }
      },
      child: BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
        builder: (context, state) {
          final authState = context.read<AuthCubit>().state;
          final user = authState.loginResponse?.user;
          final isSupervisor = user?.role.toLowerCase() == 'supervisor';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    state.isEditing
                        ? 'Edit Journey Plan'
                        : 'Create Journey Plan',
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.isEditing
                        ? 'Update the details of your journey plan'
                        : 'Fill in the details to create your journey plan',
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Supervisor Options - Select User (only show when creating, not editing)
                  if (isSupervisor && !state.isEditing) ...[
                    Text(
                      l10n.selectUser,
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (state.isLoadingSubordinates)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (state.subordinatesErrorMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                state.subordinatesErrorMessage!,
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (state.subordinates.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.textSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.noUsersAvailable,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: state.selectedSubordinate?.id,
                          decoration: InputDecoration(
                            hintText: l10n.selectUserHint,
                            hintStyle: const TextStyle(fontSize: 13),
                            prefixIcon: Icon(
                              Icons.person,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                          ),
                          items:
                              state.subordinates.isEmpty
                                  ? null
                                  : state.subordinates
                                      .map(
                                        (subordinate) =>
                                            DropdownMenuItem<String>(
                                              value: subordinate.id,
                                              child: Text(
                                                subordinate.username,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                      )
                                      .toList(),
                          onChanged:
                              state.subordinates.isEmpty
                                  ? null
                                  : (value) {
                                    final selected = state.subordinates
                                        .firstWhere((s) => s.id == value);
                                    context
                                        .read<JourneyPlanCubit>()
                                        .selectSubordinate(selected);
                                  },
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                  // Plan Type (disabled when plan has stops)
                  Text(
                    'Plan Type',
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  IgnorePointer(
                    ignoring: state.isViewOnly ||
                        (state.isEditing &&
                            (state.journeyPlan?.stops.isNotEmpty ?? false)),
                    child: Opacity(
                      opacity: state.isViewOnly ||
                              (state.isEditing &&
                                  (state.journeyPlan?.stops.isNotEmpty ??
                                      false))
                          ? 0.6
                          : 1.0,
                      child: _PlanTypeSelector(
                        selectedType: state.planType,
                        onTypeSelected: (type) {
                          context.read<JourneyPlanCubit>().updatePlanType(type);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Start Date (date only; disable dates that have existing journeys)
                  IgnorePointer(
                    ignoring: state.isViewOnly,
                    child: Opacity(
                      opacity: state.isViewOnly ? 0.6 : 1.0,
                      child: _DateField(
                        label: l10n.startDate,
                        date: state.startDate,
                        onDateSelected: (date) {
                          context.read<JourneyPlanCubit>().updateStartDate(
                            date,
                          );
                        },
                        selectableDayPredicate: (day) =>
                            !_isDateInAnyJourneyPlan(day, state.journeyPlans),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // End Date (date only; disable dates that have existing journeys)
                  IgnorePointer(
                    ignoring: state.isViewOnly,
                    child: Opacity(
                      opacity: state.isViewOnly ? 0.6 : 1.0,
                      child: _DateField(
                        label: l10n.endDate,
                        date: state.endDate,
                        onDateSelected: (date) {
                          context.read<JourneyPlanCubit>().updateEndDate(date);
                        },
                        selectableDayPredicate: (day) =>
                            !_isDateInAnyJourneyPlan(day, state.journeyPlans),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Notes
                  Text(
                    l10n.notesOptional,
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    enabled: !state.isViewOnly,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          state.isViewOnly
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                    ),
                    onChanged: (value) {
                      context.read<JourneyPlanCubit>().updateNotes(value);
                    },
                    decoration: InputDecoration(
                      hintText: l10n.enterAdditionalNotes,
                      hintStyle: const TextStyle(fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Action Buttons
                  if (!state.isViewOnly) ...[
                    Row(
                      children: [
                        // Next Button (Navigate to Step 2) - Only show in create mode
                        if (!state.isEditing) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  state.isLoading || state.journeyPlan == null
                                      ? null
                                      : () {
                                        context
                                            .read<JourneyPlanCubit>()
                                            .nextStep();
                                      },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 44),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                side: BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                l10n.next,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Create/Update Button
                        Expanded(
                          flex: state.isEditing ? 1 : 2,
                          child: ElevatedButton(
                            onPressed:
                                state.isLoading
                                    ? null
                                    : () async {
                                    // Validate form first
                                    if (!_formKey.currentState!.validate()) {
                                      return;
                                    }

                                    // Check dates
                                    if (state.startDate == null ||
                                        state.endDate == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please select start and end dates',
                                          ),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                      return;
                                    }

                                    // Check if supervisor selected a user
                                    if (isSupervisor &&
                                        !state.createForMyself &&
                                        state.selectedSubordinate == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.pleaseSelectUser),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                      return;
                                    }

                                    if (state.isEditing) {
                                      // Check if any values have changed
                                      if (_hasChanges(state)) {
                                        // Values changed - update journey plan with all stops
                                        await context
                                            .read<JourneyPlanCubit>()
                                            .updateJourneyPlanWithStops();
                                        // Check if update was successful (no error)
                                        final updatedState =
                                            context
                                                .read<JourneyPlanCubit>()
                                                .state;
                                        if (updatedState.errorMessage == null &&
                                            !updatedState.isLoading) {
                                          context
                                              .read<JourneyPlanCubit>()
                                              .nextStep();
                                        }
                                      } else {
                                        // No changes - just navigate to Step 2
                                        context
                                            .read<JourneyPlanCubit>()
                                            .nextStep();
                                      }
                                    } else {
                                      // Get user ID
                                      final userId =
                                          context
                                              .read<AuthCubit>()
                                              .state
                                              .loginResponse
                                              ?.user
                                              .id;
                                      if (userId == null || userId.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'User not found. Please login again.',
                                            ),
                                            backgroundColor: AppColors.error,
                                          ),
                                        );
                                        return;
                                      }

                                      // Create journey plan
                                      context
                                          .read<JourneyPlanCubit>()
                                          .createJourneyPlan(userId);
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child:
                              state.isLoading
                                  ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Text(
                                    state.isEditing
                                        ? l10n.next
                                        : l10n.createPlan,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlanTypeSelector extends StatelessWidget {
  const _PlanTypeSelector({
    required this.selectedType,
    required this.onTypeSelected,
  });

  final int selectedType;
  final ValueChanged<int> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _PlanTypeCard(
            type: 1,
            title: l10n.day,
            icon: Icons.today_outlined,
            isSelected: selectedType == 1,
            onTap: () => onTypeSelected(1),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _PlanTypeCard(
            type: 2,
            title: l10n.week,
            icon: Icons.date_range_outlined,
            isSelected: selectedType == 2,
            onTap: () => onTypeSelected(2),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _PlanTypeCard(
            type: 3,
            title: l10n.month,
            icon: Icons.calendar_month_outlined,
            isSelected: selectedType == 3,
            onTap: () => onTypeSelected(3),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _PlanTypeCard(
            type: 4,
            title: l10n.quarter,
            icon: Icons.view_module_outlined,
            isSelected: selectedType == 4,
            onTap: () => onTypeSelected(4),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _PlanTypeCard(
            type: 5,
            title: l10n.year,
            icon: Icons.event_note_outlined,
            isSelected: selectedType == 5,
            onTap: () => onTypeSelected(5),
          ),
        ),
      ],
    );
  }
}

class _PlanTypeCard extends StatelessWidget {
  const _PlanTypeCard({
    required this.type,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final int type;
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 14,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 9,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.start,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Returns true if [day] falls within any journey plan's [startDate, endDate] (date-only).
bool _isDateInAnyJourneyPlan(DateTime day, List<JourneyPlan> plans) {
  final d = DateTime(day.year, day.month, day.day);
  for (final plan in plans) {
    final start = DateTime(
      plan.startDate.year,
      plan.startDate.month,
      plan.startDate.day,
    );
    final end = DateTime(
      plan.endDate.year,
      plan.endDate.month,
      plan.endDate.day,
    );
    if ((d.isAfter(start) || d.isAtSameMomentAs(start)) &&
        (d.isBefore(end) || d.isAtSameMomentAs(end))) {
      return true;
    }
  }
  return false;
}

/// Returns a date that satisfies [selectableDayPredicate] for use as initialDate.
/// Uses [preferred] if selectable, otherwise the first selectable day in [firstDate]..[lastDate].
DateTime _firstSelectableDate({
  required DateTime preferred,
  required DateTime firstDate,
  required DateTime lastDate,
  bool Function(DateTime day)? selectableDayPredicate,
}) {
  if (selectableDayPredicate == null) return preferred;
  final firstDay = DateTime(firstDate.year, firstDate.month, firstDate.day);
  final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
  var preferredDay = DateTime(preferred.year, preferred.month, preferred.day);
  if (preferredDay.isBefore(firstDay)) {
    preferredDay = firstDay;
  } else if (preferredDay.isAfter(lastDay)) {
    preferredDay = lastDay;
  }
  if (selectableDayPredicate(preferredDay)) return preferredDay;
  for (var d = firstDay;
      !d.isAfter(lastDay);
      d = d.add(const Duration(days: 1))) {
    if (selectableDayPredicate(d)) return d;
  }
  return preferredDay;
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    this.date,
    required this.onDateSelected,
    this.selectableDayPredicate,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onDateSelected;
  final bool Function(DateTime day)? selectableDayPredicate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: TextAlign.start,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final firstDate = DateTime.now();
            final lastDate = DateTime.now().add(const Duration(days: 365));
            final preferred = date != null
                ? DateTime(date!.year, date!.month, date!.day)
                : firstDate;
            // initialDate must satisfy selectableDayPredicate; otherwise Flutter asserts
            final initialDate = _firstSelectableDate(
              preferred: preferred,
              firstDate: firstDate,
              lastDate: lastDate,
              selectableDayPredicate: selectableDayPredicate,
            );
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: firstDate,
              lastDate: lastDate,
              selectableDayPredicate: selectableDayPredicate,
            );
            if (selectedDate != null) {
              onDateSelected(
                DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('MMM dd, yyyy').format(
                            DateTime(date!.year, date!.month, date!.day),
                          )
                        : 'Select $label',
                    style: TextStyle(
                      color:
                          date != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
