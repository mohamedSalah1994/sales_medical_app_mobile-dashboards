import 'package:sales_medical_app_mobile/core/utils/maps_link.dart';

class Customer {
  Customer({
    required this.id,
    required this.customerCode,
    required this.name,
    required this.foreignName,
    required this.address,
    required this.city,
    required this.phone,
    required this.phone2,
    required this.email,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.externalId,
    required this.locationPoint,
    this.createdAt,
    this.creditLimit = 0,
    this.balance = 0,
    this.paymentTerms = '',
    this.priceListCode = '',
    this.series = '',
    this.cardType = '',
    this.channelBP = '',
    this.uArea = '',
    this.uGov = '',
    this.uTerr = '',
    this.uS = '',
    this.uRegion = '',
    this.extendedProperties,
  });

  final String id;
  final String customerCode;
  final String name;
  final String foreignName;
  final String address;
  final String city;
  final String phone;
  final String phone2;
  final String email;
  final double latitude;
  final double longitude;
  final int status;
  final String externalId;
  final String locationPoint;
  /// Present only when the API returns `createdAt`.
  final DateTime? createdAt;

  final double creditLimit;
  final double balance;
  final String paymentTerms;
  final String priceListCode;
  final String series;
  final String cardType;
  final String channelBP;
  final String uArea;
  final String uGov;
  final String uTerr;
  final String uS;
  /// ERP `U_REGION` (sub-city / district).
  final String uRegion;
  final Map<String, dynamic>? extendedProperties;

  static const _locationPointKeys = [
    'U_LOC_PNT',
    'u_LOC_PNT',
    'u_Loc_Pnt',
    'uLocPnt',
    'locationPoint',
    'LocationPoint',
    'LOC_PNT',
    'loc_pnt',
  ];

  /// Human-readable location from ERP `U_LOC_PNT` ([locationPoint]) or coordinates.
  String? get locationDisplayText {
    final p = locationPoint.trim();
    if (p.isNotEmpty) {
      final coords = parseLatLng(p);
      if (coords != null) {
        return '${coords.lat.toStringAsFixed(6)}, ${coords.lng.toStringAsFixed(6)}';
      }
      return p;
    }
    if (latitude != 0 || longitude != 0) {
      return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    }
    return null;
  }

  /// Opens in Google Maps when coordinates, a maps URL, or a `lat,lng` in [locationPoint] exist.
  Uri? get mapsLaunchUri {
    final fromPoint = buildGoogleMapsUri(locationPoint);
    if (fromPoint != null) return fromPoint;
    if (latitude != 0 || longitude != 0) {
      return googleMapsSearchUri(latitude, longitude);
    }
    return null;
  }

  static ({double lat, double lng})? _tryParseLatLng(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final plain = RegExp(
      r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$',
    ).firstMatch(text);
    if (plain != null) {
      final lat = double.tryParse(plain.group(1) ?? '');
      final lng = double.tryParse(plain.group(2) ?? '');
      if (lat != null &&
          lng != null &&
          lat.abs() <= 90 &&
          lng.abs() <= 180) {
        return (lat: lat, lng: lng);
      }
    }

    for (final re in <RegExp>[
      RegExp(r'@(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)'),
      RegExp(r'[?&]q=(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)'),
      RegExp(r'[?&]ll=(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)'),
    ]) {
      final m = re.firstMatch(text);
      if (m == null) continue;
      final lat = double.tryParse(m.group(1) ?? '');
      final lng = double.tryParse(m.group(2) ?? '');
      if (lat != null &&
          lng != null &&
          lat.abs() <= 90 &&
          lng.abs() <= 180) {
        return (lat: lat, lng: lng);
      }
    }
    return null;
  }

  String localizedName(String languageCode) {
    final isEnglish = languageCode.toLowerCase().startsWith('en');
    if (!isEnglish && foreignName.isNotEmpty) return foreignName;
    if (name.isNotEmpty) return name;
    return foreignName;
  }

  /// Extra name line for lists/dialogs (other language) when it differs from [localizedName].
  String? secondaryDisplayName(String languageCode) {
    final primary = localizedName(languageCode).trim();
    final nameTrim = name.trim();
    final foreignTrim = foreignName.trim();
    if (nameTrim.isNotEmpty && nameTrim != primary) return nameTrim;
    if (foreignTrim.isNotEmpty && foreignTrim != primary) return foreignTrim;
    return null;
  }

  /// First non-empty trimmed string from the given keys, or `null`.
  static String? _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final raw = json[k];
      if (raw == null) continue;
      final s = raw.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  /// First numeric value (accepts num or numeric String) from the given keys.
  static double? _firstDouble(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final raw = json[k];
      if (raw == null) continue;
      if (raw is num) return raw.toDouble();
      final parsed = double.tryParse(raw.toString().trim());
      if (parsed != null) return parsed;
    }
    return null;
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['code'])?.toString() ?? '';
    final code = (json['customerCode'] ?? json['code'])?.toString() ?? '';
    final displayName = (json['cardName'] ?? json['name'])?.toString() ?? '';
    final foreignName =
        (json['cardForeignName'] ?? json['foreignName'])?.toString() ?? '';

    Map<String, dynamic>? ext;
    final rawExt = json['extendedProperties'];
    if (rawExt is Map) {
      ext = <String, dynamic>{};
      rawExt.forEach((k, v) {
        ext![k.toString()] = v;
      });
    }

    // ERP ODBC: location lives in `U_LOC_PNT` (top-level or extended properties).
    final locPnt =
        _firstString(json, _locationPointKeys) ??
        (ext != null ? _firstString(ext, _locationPointKeys) : null) ??
        '';

    var latitude =
        _firstDouble(json, ['latitude', 'Latitude', 'lat', 'Lat']) ?? 0.0;
    var longitude =
        _firstDouble(json, [
          'longitude',
          'Longitude',
          'lng',
          'Lng',
          'lon',
          'Lon',
        ]) ??
        0.0;
    if (latitude == 0 && longitude == 0 && locPnt.isNotEmpty) {
      final parsed = _tryParseLatLng(locPnt);
      if (parsed != null) {
        latitude = parsed.lat;
        longitude = parsed.lng;
      }
    }

    final isActive = json['isActive'];
    final status =
        json['status'] as int? ??
        (isActive == true
            ? 1
            : isActive == false
            ? 0
            : 0);

    return Customer(
      id: id,
      customerCode: code,
      name: displayName,
      foreignName: foreignName,
      address: json['address']?.toString() ?? '',
      city: (Customer._firstString(json, ['U_C', 'u_City', 'city'])) ?? '',
      phone: (Customer._firstString(json, ['phone1', 'phone'])) ?? '',
      phone2: json['phone2']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      latitude: latitude,
      longitude: longitude,
      status: status,
      externalId: json['externalId']?.toString() ?? '',
      locationPoint: locPnt,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      paymentTerms: json['paymentTerms']?.toString() ?? '',
      priceListCode: json['priceListCode']?.toString() ?? '',
      series: json['series']?.toString() ?? '',
      cardType: json['cardType']?.toString() ?? '',
      channelBP: json['channelBP']?.toString() ?? '',
      uArea: Customer._firstString(json, ['U_N_AREA', 'u_Area']) ?? '',
      uGov: Customer._firstString(json, ['U_ZONE', 'u_Gov']) ?? '',
      uTerr: json['u_Terr']?.toString() ?? '',
      uS: Customer._firstString(json, ['u_S', 'U_S']) ?? '',
      uRegion: Customer._firstString(json, ['U_REGION', 'u_REGION']) ?? '',
      extendedProperties: ext,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerCode': customerCode,
      'name': name,
      'foreignName': foreignName,
      'address': address,
      'city': city,
      'phone': phone,
      'phone2': phone2,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'externalId': externalId,
      'U_LOC_PNT': locationPoint,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      'creditLimit': creditLimit,
      'balance': balance,
      'paymentTerms': paymentTerms,
      'priceListCode': priceListCode,
      'series': series,
      'cardType': cardType,
      'channelBP': channelBP,
      'u_Area': uArea,
      'u_Gov': uGov,
      'u_Terr': uTerr,
      'u_S': uS,
      'U_REGION': uRegion,
      'u_City': city,
      if (extendedProperties != null)
        'extendedProperties': extendedProperties,
    };
  }
}
