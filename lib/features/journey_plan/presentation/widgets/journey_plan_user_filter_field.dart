import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/subordinate_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_state.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';

/// Resolves whose subordinates to load for journey-plan user filters.
/// Admin with a selected supervisor uses that supervisor's team; otherwise the
/// logged-in user (supervisor/manager).
String? resolveSubordinatesOwnerId({
  required String? loggedInUserId,
  required String? role,
  required String? filterSupervisorId,
}) {
  final normalizedRole = role?.toLowerCase().trim() ?? '';
  if (normalizedRole == 'admin' &&
      filterSupervisorId != null &&
      filterSupervisorId.isNotEmpty) {
    return filterSupervisorId;
  }
  if (loggedInUserId == null || loggedInUserId.isEmpty) return null;
  if (normalizedRole == 'supervisor' ||
      normalizedRole == 'manager' ||
      normalizedRole == 'admin') {
    return loggedInUserId;
  }
  return null;
}

bool showJourneyPlanUserFilterForRole(String? role) {
  final r = role?.toLowerCase().trim() ?? '';
  return r == 'supervisor' || r == 'manager' || r == 'admin';
}

/// Tap field used in journey-plan filter sheets — opens a searchable dialog.
class JourneyPlanUserFilterField extends StatelessWidget {
  const JourneyPlanUserFilterField({
    super.key,
    required this.state,
    required this.onUserSelected,
  });

  final JourneyPlanState state;
  final void Function(String? userId) onUserSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthCubit>().state.loginResponse?.user;
    final ownerId = resolveSubordinatesOwnerId(
      loggedInUserId: auth?.id,
      role: auth?.role,
      filterSupervisorId: state.filterSupervisorId,
    );

    final selected = state.subordinates
        .where((s) => s.id == state.filterUserId)
        .toList();
    final selectedName =
        selected.isEmpty ? null : selected.first.fullName;

    return InkWell(
      onTap:
          ownerId == null
              ? null
              : () => showJourneyPlanUserPickerDialog(
                context,
                state: state,
                subordinatesOwnerId: ownerId,
                onUserSelected: onUserSelected,
              ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.person, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedName ?? l10n.allUsers,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      selectedName != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                ),
              ),
            ),
            if (state.isLoadingSubordinates)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.arrow_drop_down,
                color: AppColors.textSecondary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> showJourneyPlanUserPickerDialog(
  BuildContext context, {
  required JourneyPlanState state,
  required String subordinatesOwnerId,
  required void Function(String? userId) onUserSelected,
}) {
  final cubit = context.read<JourneyPlanCubit>();
  if (state.subordinates.isEmpty && !state.isLoadingSubordinates) {
    cubit.loadSubordinates(subordinatesOwnerId);
  }

  return showDialog<void>(
    context: context,
    builder:
        (dialogContext) => BlocProvider.value(
          value: cubit,
          child: _JourneyPlanUserPickerDialog(
            subordinatesOwnerId: subordinatesOwnerId,
            selectedUserId: state.filterUserId,
            onUserSelected: (userId) {
              Navigator.of(dialogContext).pop();
              onUserSelected(userId);
            },
          ),
        ),
  );
}

class _JourneyPlanUserPickerDialog extends StatefulWidget {
  const _JourneyPlanUserPickerDialog({
    required this.subordinatesOwnerId,
    required this.selectedUserId,
    required this.onUserSelected,
  });

  final String subordinatesOwnerId;
  final String? selectedUserId;
  final void Function(String? userId) onUserSelected;

  @override
  State<_JourneyPlanUserPickerDialog> createState() =>
      _JourneyPlanUserPickerDialogState();
}

class _JourneyPlanUserPickerDialogState
    extends State<_JourneyPlanUserPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<JourneyPlanCubit>();
      final state = cubit.state;
      if (!state.isLoadingSubordinates &&
          (state.subordinates.isEmpty ||
              state.subordinatesErrorMessage != null)) {
        cubit.loadSubordinates(widget.subordinatesOwnerId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SubordinateModel> _filtered(List<SubordinateModel> subordinates) {
    if (_query.trim().isEmpty) return subordinates;
    final q = _query.trim().toLowerCase();
    return subordinates
        .where(
          (s) =>
              s.fullName.toLowerCase().contains(q) ||
              s.email.toLowerCase().contains(q) ||
              s.username.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          maxWidth: 480,
        ),
        child: BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
          builder: (context, state) {
            final filtered = _filtered(state.subordinates);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.selectUserHint,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name or email',
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (state.isLoadingSubordinates && state.subordinates.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  )
                else if (state.subordinatesErrorMessage != null &&
                    state.subordinates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          state.subordinatesErrorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed:
                              () => context.read<JourneyPlanCubit>().loadSubordinates(
                                widget.subordinatesOwnerId,
                              ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                      children: [
                        ListTile(
                          dense: true,
                          title: Text(
                            l10n.allUsers,
                            style: TextStyle(
                              fontWeight:
                                  widget.selectedUserId == null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                              color:
                                  widget.selectedUserId == null
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                            ),
                          ),
                          onTap: () => widget.onUserSelected(null),
                        ),
                        ...filtered.map((sub) {
                          final isSelected = widget.selectedUserId == sub.id;
                          return ListTile(
                            dense: true,
                            title: Text(
                              sub.fullName,
                              style: TextStyle(
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                color:
                                    isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                              ),
                            ),
                            subtitle:
                                sub.email.isNotEmpty
                                    ? Text(
                                      sub.email,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    )
                                    : null,
                            onTap: () => widget.onUserSelected(sub.id),
                          );
                        }),
                        if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No matching users',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
