import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:sales_medical_app_mobile/features/field_staff/data/field_staff_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/field_staff/data/models/team_member_location_model.dart';

part 'team_locations_state.dart';

class TeamLocationsCubit extends Cubit<TeamLocationsState> {
  TeamLocationsCubit({required this.remoteDataSource})
    : super(const TeamLocationsState());

  final FieldStaffRemoteDataSource remoteDataSource;

  Timer? _pollTimer;
  static const Duration pollInterval = Duration(minutes: 1);

  void startPolling() {
    if (_pollTimer != null) return;
    fetchTeamLocations();
    _pollTimer = Timer.periodic(pollInterval, (_) => fetchTeamLocations());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Future<void> close() {
    stopPolling();
    return super.close();
  }

  Future<void> fetchTeamLocations() async {
    final prevPoints = <String, LatLng>{};
    for (final m in state.members) {
      if (m.hasCoordinates) {
        prevPoints[m.userId] = LatLng(m.latitude!, m.longitude!);
      }
    }

    emit(state.copyWith(isLoading: true, error: null));
    try {
      final list = await remoteDataSource.getTeamLocations();
      if (isClosed) return;
      emit(
        TeamLocationsState(
          members: list,
          previousPointsByUserId: prevPoints,
          isLoading: false,
          error: null,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }
}
