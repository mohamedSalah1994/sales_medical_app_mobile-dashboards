part of 'team_locations_cubit.dart';

class TeamLocationsState extends Equatable {
  const TeamLocationsState({
    this.members = const [],
    this.previousPointsByUserId = const {},
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  final List<TeamMemberLocationModel> members;
  final Map<String, LatLng> previousPointsByUserId;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  TeamLocationsState copyWith({
    List<TeamMemberLocationModel>? members,
    Map<String, LatLng>? previousPointsByUserId,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateTime? lastUpdated,
  }) {
    return TeamLocationsState(
      members: members ?? this.members,
      previousPointsByUserId:
          previousPointsByUserId ?? this.previousPointsByUserId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    members,
    previousPointsByUserId,
    isLoading,
    error,
    lastUpdated,
  ];
}
