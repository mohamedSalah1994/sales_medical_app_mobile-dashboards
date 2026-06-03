class CheckInVisitRequestModel {
  final double? latitude;
  final double? longitude;

  CheckInVisitRequestModel({
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
