class CheckOutVisitRequestModel {
  final double? latitude;
  final double? longitude;
  final int? actualDurationSeconds;
  final String? actualDuration;

  CheckOutVisitRequestModel({
    this.latitude,
    this.longitude,
    this.actualDurationSeconds,
    this.actualDuration,
  });

  Map<String, dynamic> toJson() {
    return {
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (actualDurationSeconds != null)
        'actualDurationSeconds': actualDurationSeconds,
      if (actualDuration != null && actualDuration!.isNotEmpty)
        'actualDuration': actualDuration,
    };
  }
}
