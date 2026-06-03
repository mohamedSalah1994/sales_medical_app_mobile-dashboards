import 'package:sales_medical_app_mobile/features/field_staff/data/models/team_member_location_model.dart';

abstract class FieldStaffRemoteDataSource {
  Future<void> postLocation({
    required double latitude,
    required double longitude,
    DateTime? recordedAt,
    double? accuracyMeters,
  });

  Future<List<TeamMemberLocationModel>> getTeamLocations();
}

class FieldStaffRemoteDataSourceImpl implements FieldStaffRemoteDataSource {
  FieldStaffRemoteDataSourceImpl({required this.apiService});

  final dynamic apiService;

  @override
  Future<void> postLocation({
    required double latitude,
    required double longitude,
    DateTime? recordedAt,
    double? accuracyMeters,
  }) async {
    final body = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      if (recordedAt != null)
        'recordedAt': recordedAt.toUtc().toIso8601String(),
      if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
    };
    final response = await apiService.post(
      '/api/FieldStaff/location',
      data: body,
    );
    final code = response.statusCode;
    if (code != null && code != 204 && code != 200) {
      throw Exception('Location update failed ($code)');
    }
  }

  @override
  Future<List<TeamMemberLocationModel>> getTeamLocations() async {
    final response = await apiService.get('/api/FieldStaff/team-locations');
    if (response.statusCode != 200) {
      throw Exception('Failed to load team locations');
    }
    final raw = response.data;
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map(
          (e) => TeamMemberLocationModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }
}
