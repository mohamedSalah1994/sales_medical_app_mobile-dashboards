class StartVisitRequestModel {
  final double? latitude;
  final double? longitude;

  StartVisitRequestModel({
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
