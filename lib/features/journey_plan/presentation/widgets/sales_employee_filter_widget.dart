import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/subordinate_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_state.dart';

class SalesEmployeeFilterWidget extends StatelessWidget {
  const SalesEmployeeFilterWidget({super.key, required this.state});

  final JourneyPlanState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (state.isLoadingSubordinates) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading sales employees...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final selectedList = state.subordinates
        .where((s) => s.id == state.filterUserId)
        .toList();
    final selectedName =
        selectedList.isEmpty ? null : selectedList.first.fullName;

    return InkWell(
      onTap: () => _showSalesEmployeePicker(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.person_outline,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedName ?? l10n.supervisorVisits,
                style: TextStyle(
                  fontSize: 13,
                  color: selectedName != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
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

  void _showSalesEmployeePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SalesEmployeePickerSheet(
        state: state,
        onSelect: (userId) {
          Navigator.of(sheetContext).pop();
          final cubit = context.read<JourneyPlanCubit>();
          if (userId == null) {
            cubit.clearSubordinateSelection();
            cubit.loadJourneyPlans(
              supervisorId: state.filterSupervisorId,
              customerId: state.filterCustomerId,
            );
          } else {
            cubit.selectSubordinateForAdmin(userId);
            cubit.loadJourneyPlans(
              userId: userId,
              customerId: state.filterCustomerId,
            );
          }
        },
      ),
    );
  }
}

class _SalesEmployeePickerSheet extends StatefulWidget {
  const _SalesEmployeePickerSheet({
    required this.state,
    required this.onSelect,
  });

  final JourneyPlanState state;
  final void Function(String? userId) onSelect;

  @override
  State<_SalesEmployeePickerSheet> createState() =>
      _SalesEmployeePickerSheetState();
}

class _SalesEmployeePickerSheetState extends State<_SalesEmployeePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SubordinateModel> get _filtered {
    if (_query.trim().isEmpty) return widget.state.subordinates;
    final q = _query.trim().toLowerCase();
    return widget.state.subordinates
        .where((s) =>
            s.fullName.toLowerCase().contains(q) ||
            (s.email.toLowerCase().contains(q)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final supervisorList = widget.state.supervisors
        .where((s) => s.id == widget.state.filterSupervisorId)
        .toList();
    final supervisorName =
        supervisorList.isEmpty ? 'Supervisor' : supervisorList.first.fullName;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sales Employees of $supervisorName',
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                ListTile(
                  dense: true,
                  title: Text(
                    l10n.supervisorVisits,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: widget.state.filterUserId == null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: widget.state.filterUserId == null
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  onTap: () => widget.onSelect(null),
                ),
                ..._filtered.map((sub) {
                  final isSelected = widget.state.filterUserId == sub.id;
                  return ListTile(
                    dense: true,
                    title: Text(
                      sub.fullName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: sub.email.isNotEmpty
                        ? Text(
                            sub.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : null,
                    onTap: () => widget.onSelect(sub.id),
                  );
                }),
                if (_filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No matching sales employees',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
