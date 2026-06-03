import 'package:equatable/equatable.dart';
import 'package:sales_medical_app_mobile/features/targets/domain/entities/target.dart';

class TargetsState extends Equatable {
  final List<Target> targets;
  final bool isLoadingTargets;
  final String? targetsErrorMessage;
  final String? filterUserId;
  final String? filterCreatedById;
  final int? filterPeriodType;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final int selectedTabIndex;

  const TargetsState({
    required this.targets,
    required this.isLoadingTargets,
    this.targetsErrorMessage,
    this.filterUserId,
    this.filterCreatedById,
    this.filterPeriodType,
    this.filterStartDate,
    this.filterEndDate,
    required this.selectedTabIndex,
  });

  factory TargetsState.initial() {
    return const TargetsState(
      targets: [],
      isLoadingTargets: false,
      targetsErrorMessage: null,
      filterUserId: null,
      filterCreatedById: null,
      filterPeriodType: null,
      filterStartDate: null,
      filterEndDate: null,
      selectedTabIndex: 0,
    );
  }

  TargetsState copyWith({
    List<Target>? targets,
    bool? isLoadingTargets,
    String? targetsErrorMessage,
    String? filterUserId,
    String? filterCreatedById,
    int? filterPeriodType,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
    bool clearFilters = false,
    int? selectedTabIndex,
  }) {
    return TargetsState(
      targets: targets ?? this.targets,
      isLoadingTargets: isLoadingTargets ?? this.isLoadingTargets,
      targetsErrorMessage: targetsErrorMessage,
      filterUserId: clearFilters ? null : (filterUserId ?? this.filterUserId),
      filterCreatedById: clearFilters ? null : (filterCreatedById ?? this.filterCreatedById),
      filterPeriodType: clearFilters ? null : (filterPeriodType ?? this.filterPeriodType),
      filterStartDate: clearFilters ? null : (filterStartDate ?? this.filterStartDate),
      filterEndDate: clearFilters ? null : (filterEndDate ?? this.filterEndDate),
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
    );
  }

  bool get hasActiveFilters {
    return filterUserId != null ||
        filterCreatedById != null ||
        filterPeriodType != null ||
        filterStartDate != null ||
        filterEndDate != null;
  }

  @override
  List<Object?> get props => [
        targets,
        isLoadingTargets,
        targetsErrorMessage,
        filterUserId,
        filterCreatedById,
        filterPeriodType,
        filterStartDate,
        filterEndDate,
        selectedTabIndex,
      ];
}
