import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/dashboard/data/models/dashboard_models.dart';

enum AreaManagerHomeStatus { idle, loading, ready, error }

class AreaManagerHomeState extends Equatable {
  final AreaManagerHomeStatus status;
  final AreaManagerDashboard? data;
  final String? error;
  final DateTime? date;
  final bool refreshing;

  const AreaManagerHomeState({
    this.status = AreaManagerHomeStatus.idle,
    this.data,
    this.error,
    this.date,
    this.refreshing = false,
  });

  AreaManagerHomeState copyWith({
    AreaManagerHomeStatus? status,
    AreaManagerDashboard? data,
    String? error,
    DateTime? date,
    bool? refreshing,
    bool clearError = false,
  }) =>
      AreaManagerHomeState(
        status: status ?? this.status,
        data: data ?? this.data,
        error: clearError ? null : (error ?? this.error),
        date: date ?? this.date,
        refreshing: refreshing ?? this.refreshing,
      );

  @override
  List<Object?> get props => [status, data, error, date, refreshing];
}

class AreaManagerHomeCubit extends Cubit<AreaManagerHomeState> {
  AreaManagerHomeCubit(this._dataSource) : super(const AreaManagerHomeState());
  final DashboardRemoteDataSource _dataSource;

  Future<void> load({DateTime? date, bool forceRefresh = false}) async {
    final eff = date ?? state.date ?? DateTime.now();
    if (state.data == null) {
      emit(state.copyWith(
          status: AreaManagerHomeStatus.loading, date: eff, clearError: true));
    } else {
      emit(state.copyWith(refreshing: true, date: eff, clearError: true));
    }
    try {
      final data = await _dataSource.getAreaManager(date: eff, forceRefresh: forceRefresh);
      emit(state.copyWith(
          status: AreaManagerHomeStatus.ready, data: data, refreshing: false));
    } catch (e) {
      emit(state.copyWith(
          status: AreaManagerHomeStatus.error, error: e.toString(), refreshing: false));
    }
  }

  Future<void> refresh() => load(forceRefresh: true);
}
