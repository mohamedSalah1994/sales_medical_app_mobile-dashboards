class SupervisorAttendanceRequestModel {
  const SupervisorAttendanceRequestModel({
    required this.action,
    this.latitude,
    this.longitude,
  });

  final String action;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
