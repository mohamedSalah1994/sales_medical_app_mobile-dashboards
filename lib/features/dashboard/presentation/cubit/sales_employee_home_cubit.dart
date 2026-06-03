import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/dashboard/data/models/sales_employee_home_models.dart';

enum SalesEmployeeHomeStatus { idle, loading, ready, error }

class SalesEmployeeHomeState extends Equatable {
  final SalesEmployeeHomeStatus status;
  final SalesEmployeeHome? data;
  final String? error;
  final DateTime? date;
  final bool refreshing;

  const SalesEmployeeHomeState({
    this.status = SalesEmployeeHomeStatus.idle,
    this.data,
    this.error,
    this.date,
    this.refreshing = false,
  });

  SalesEmployeeHomeState copyWith({
    SalesEmployeeHomeStatus? status,
    SalesEmployeeHome? data,
    String? error,
    DateTime? date,
    bool? refreshing,
    bool clearError = false,
  }) =>
      SalesEmployeeHomeState(
        status: status ?? this.status,
        data: data ?? this.data,
        error: clearError ? null : (error ?? this.error),
        date: date ?? this.date,
        refreshing: refreshing ?? this.refreshing,
      );

  @override
  List<Object?> get props => [status, data, error, date, refreshing];
}

class SalesEmployeeHomeCubit extends Cubit<SalesEmployeeHomeState> {
  SalesEmployeeHomeCubit(this._dataSource) : super(const SalesEmployeeHomeState());
  final DashboardRemoteDataSource _dataSource;

  Future<void> load({DateTime? date, bool forceRefresh = false}) async {
    final eff = date ?? state.date ?? DateTime.now();
    if (state.data == null) {
      emit(state.copyWith(
          status: SalesEmployeeHomeStatus.loading, date: eff, clearError: true));
    } else {
      emit(state.copyWith(refreshing: true, date: eff, clearError: true));
    }
    try {
      final data = await _dataSource.getSalesEmployeeHome(date: eff, forceRefresh: forceRefresh);
      emit(state.copyWith(
          status: SalesEmployeeHomeStatus.ready, data: data, refreshing: false));
    } catch (e) {
      emit(state.copyWith(
          status: SalesEmployeeHomeStatus.error, error: e.toString(), refreshing: false));
    }
  }

  Future<void> refresh() => load(forceRefresh: true);
}
