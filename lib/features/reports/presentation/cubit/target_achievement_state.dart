part of 'target_achievement_cubit.dart';

class TargetAchievementState extends Equatable {
  const TargetAchievementState({
    this.startDate,
    this.endDate,
    this.selectedEmployeeId,
    this.selectedEmployeeName,
    this.isLoading = false,
    this.errorMessage,
    this.report,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedEmployeeId;
  final String? selectedEmployeeName;
  final bool isLoading;
  final String? errorMessage;
  final TargetAchievementModel? report;

  TargetAchievementState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? selectedEmployeeId,
    String? selectedEmployeeName,
    bool? isLoading,
    String? errorMessage,
    TargetAchievementModel? report,
    bool clearError = false,
    bool clearEmployee = false,
    bool clearReport = false,
  }) {
    return TargetAchievementState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedEmployeeId:
          clearEmployee ? null : (selectedEmployeeId ?? this.selectedEmployeeId),
      selectedEmployeeName:
          clearEmployee ? null : (selectedEmployeeName ?? this.selectedEmployeeName),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      report: clearReport ? null : (report ?? this.report),
    );
  }

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        selectedEmployeeId,
        selectedEmployeeName,
        isLoading,
        errorMessage,
        report,
      ];
}
