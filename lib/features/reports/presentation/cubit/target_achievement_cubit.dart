import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/features/reports/data/models/target_achievement_model.dart';
import 'package:sales_medical_app_mobile/features/reports/domain/usecases/get_target_achievement_usecase.dart';

part 'target_achievement_state.dart';

class TargetAchievementCubit extends Cubit<TargetAchievementState> {
  TargetAchievementCubit({
    required GetTargetAchievementUseCase getTargetAchievementUseCase,
  })  : _getTargetAchievementUseCase = getTargetAchievementUseCase,
        super(_initialState());

  final GetTargetAchievementUseCase _getTargetAchievementUseCase;

  static TargetAchievementState _initialState() {
    final now = DateTime.now();
    return TargetAchievementState(
      startDate: DateTime(now.year, now.month, 1),
      endDate: now,
    );
  }

  Future<void> loadReport({
    required String userId,
    required String role,
    DateTime? startDate,
    DateTime? endDate,
    String? filterEmployeeId,
  }) async {
    final start = startDate ?? state.startDate;
    final end = endDate ?? state.endDate;

    String resolvedUserId;
    String userType;

    if (role.toLowerCase() == 'salesrep') {
      resolvedUserId = userId;
      userType = 'SE';
    } else if (filterEmployeeId != null && filterEmployeeId.isNotEmpty) {
      resolvedUserId = filterEmployeeId;
      userType = 'SE';
    } else {
      resolvedUserId = userId;
      userType = 'S';
    }

    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final report = await _getTargetAchievementUseCase(
        GetTargetAchievementParams(
          userId: resolvedUserId,
          userType: userType,
          startDate: start,
          endDate: end,
        ),
      );
      emit(state.copyWith(isLoading: false, report: report));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void startDateChanged(DateTime v) {
    emit(state.copyWith(startDate: v));
  }

  void endDateChanged(DateTime v) {
    emit(state.copyWith(endDate: v));
  }

  void filterByEmployee(String? id, String? name) {
    emit(
      state.copyWith(
        selectedEmployeeId: id,
        selectedEmployeeName: name,
        clearReport: true,
      ),
    );
  }

  void clearEmployeeFilter() {
    emit(
      state.copyWith(
        clearEmployee: true,
        clearReport: true,
      ),
    );
  }

  void applyFiltersBatch({
    required DateTime start,
    required DateTime end,
    String? employeeId,
    String? employeeName,
  }) {
    emit(
      state.copyWith(
        startDate: start,
        endDate: end,
        selectedEmployeeId: employeeId,
        selectedEmployeeName: employeeName,
        clearEmployee: employeeId == null,
        clearReport: true,
      ),
    );
  }
}
