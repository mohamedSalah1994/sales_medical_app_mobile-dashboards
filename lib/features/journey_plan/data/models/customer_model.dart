import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/customer.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    required super.customerCode,
    required super.name,
    super.foreignName = '',
    required super.address,
    required super.city,
    required super.phone,
    required super.email,
    required super.locationPoint,
    super.uGLink,
    required super.latitude,
    required super.longitude,
    required super.status,
    required super.externalId,
    required super.createdAt,
    super.cardType = '',
  });

  /// Returns the first non-empty trimmed string from the given keys, or `null`.
  /// Used to be lenient about ERP/ODBC field-name casing variations.
  static String? _pick(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final raw = json[k];
      if (raw == null) continue;
      final s = raw.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  /// Reads a numeric value from the first key whose value parses as a number.
  /// Accepts both `num` and `String` JSON values.
  static double? _pickDouble(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final raw = json[k];
      if (raw == null) continue;
      if (raw is num) return raw.toDouble();
      final parsed = double.tryParse(raw.toString().trim());
      if (parsed != null) return parsed;
    }
    return null;
  }

  /// Best-effort `(lat,lng)` parser supporting `(lat,lng)` and `lat,lng`.
  static ({double lat, double lng})? _parseLatLngString(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('(') && s.endsWith(')')) {
      s = s.substring(1, s.length - 1);
    }
    final parts = s.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    // Support both legacy (id, customerCode) and Erp (code, name) response shapes
    final id = (json['id'] ?? json['code'])?.toString() ?? '';
    final code = (json['customerCode'] ?? json['code'])?.toString() ?? '';
    final foreign =
        (json['cardForeignName'] ?? json['foreignName'])?.toString() ?? '';
    // ERP / ODBC may return the location field under several casings.
    final locPnt = _pick(json, [
      'U_LOC_PNT',
      'u_LOC_PNT',
      'u_Loc_Pnt',
      'uLocPnt',
      'locationPoint',
      'LocationPoint',
      'LOC_PNT',
      'loc_pnt',
    ]);
    final uGLinkRaw = _pick(json, [
      'U_G_Link',
      'u_G_Link',
      'u_g_link',
      'uGLink',
      'googleMapsLink',
      'GoogleMapsLink',
      'G_Link',
      'g_link',
    ]);
    var latitude = _pickDouble(json, [
          'latitude',
          'Latitude',
          'lat',
          'Lat',
        ]) ??
        0.0;
    var longitude = _pickDouble(json, [
          'longitude',
          'Longitude',
          'lng',
          'Lng',
          'lon',
          'Lon',
        ]) ??
        0.0;
    // Derive lat/lng from `(lat,lng)` location point when direct fields are
    // missing or zero - keeps the auto-fill working when the API only returns
    // U_LOC_PNT.
    if ((latitude == 0.0 && longitude == 0.0) &&
        locPnt != null &&
        locPnt.isNotEmpty) {
      final parsed = _parseLatLngString(locPnt);
      if (parsed != null) {
        latitude = parsed.lat;
        longitude = parsed.lng;
      }
    }

    return CustomerModel(
      id: id,
      customerCode: code,
      name: json['name'] as String? ?? '',
      foreignName: foreign,
      address: json['address'] as String? ?? '',
      city: _pick(json, ['U_C', 'u_City', 'city']) ?? '',
      phone: _pick(json, ['phone1', 'phone']) ?? '',
      email: json['email'] as String? ?? '',
      locationPoint: locPnt ?? '',
      uGLink: uGLinkRaw,
      latitude: latitude,
      longitude: longitude,
      status: json['status'] as int? ?? (json['isActive'] == true ? 1 : 0),
      externalId: json['externalId'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      cardType: json['cardType']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerCode': customerCode,
      'name': name,
      if (foreignName.isNotEmpty) 'cardForeignName': foreignName,
      'address': address,
      'city': city,
      'phone': phone,
      'email': email,
      'U_LOC_PNT': locationPoint,
      if (uGLink != null && uGLink!.trim().isNotEmpty) 'U_G_Link': uGLink,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'externalId': externalId,
      'createdAt': createdAt.toIso8601String(),
      if (cardType.isNotEmpty) 'cardType': cardType,
    };
  }
}
