import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/features/targets/domain/usecases/get_targets_usecase.dart';
import 'package:sales_medical_app_mobile/features/targets/presentation/cubit/targets_state.dart';

class TargetsCubit extends Cubit<TargetsState> {
  TargetsCubit({
    required this.getTargetsUseCase,
  }) : super(TargetsState.initial());

  final GetTargetsUseCase getTargetsUseCase;

  Future<void> loadTargets({
    String? userId,
    String? createdById,
    int? periodType,
    DateTime? startDate,
    DateTime? endDate,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    if (isClosed) return;
    emit(state.copyWith(isLoadingTargets: true, targetsErrorMessage: null));

    try {
      final filterUserId = userId ?? state.filterUserId;
      final filterCreatedById = createdById ?? state.filterCreatedById;
      final filterPeriodType = periodType ?? state.filterPeriodType;
      final filterStartDate = startDate ?? state.filterStartDate;
      final filterEndDate = endDate ?? state.filterEndDate;

      final response = await getTargetsUseCase(
        GetTargetsParams(
          userId: filterUserId,
          createdById: filterCreatedById,
          periodType: filterPeriodType,
          startDate: filterStartDate,
          endDate: filterEndDate,
          pageNumber: pageNumber,
          pageSize: pageSize,
        ),
      );

      if (!isClosed) {
        emit(
          state.copyWith(
            isLoadingTargets: false,
            targets: response.items,
          ),
        );
      }
    } on Failure catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoadingTargets: false,
            targetsErrorMessage: e.message,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoadingTargets: false,
            targetsErrorMessage: 'Failed to load targets',
          ),
        );
      }
    }
  }

  void setFilters({
    String? userId,
    String? createdById,
    int? periodType,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    emit(
      state.copyWith(
        filterUserId: userId,
        filterCreatedById: createdById,
        filterPeriodType: periodType,
        filterStartDate: startDate,
        filterEndDate: endDate,
      ),
    );
  }

  void clearFilters() {
    emit(state.copyWith(clearFilters: true));
  }

  void applyFilters() {
    // Reload targets with current filters
    loadTargets();
  }

  void setSelectedTab(int index) {
    emit(state.copyWith(selectedTabIndex: index));
  }
}
