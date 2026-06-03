import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:sales_medical_app_mobile/core/config/google_maps_api_key.dart';
import 'package:sales_medical_app_mobile/core/utils/placemark_label.dart';

final Dio _reverseGeoDio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    validateStatus: (s) => s != null && s < 500,
  ),
);

/// Reverse geocode [lat],[lng] to a human-readable nearby place / address.
/// Tries Google Geocoding API, then platform geocoder, then OpenStreetMap Nominatim.
Future<String?> reverseGeocodeNearbyPlace(
  double lat,
  double lng, {
  Locale? locale,
}) async {
  final language = locale?.languageCode ?? 'en';

  final google = await _tryGoogleReverse(lat, lng, language);
  if (google != null && google.isNotEmpty) return google;

  final platform = await _tryPlatformPlacemark(lat, lng, locale);
  if (platform != null && platform.isNotEmpty) return platform;

  final nominatim = await _tryNominatimReverse(lat, lng, language);
  if (nominatim != null && nominatim.isNotEmpty) return nominatim;

  return null;
}

Future<String?> _tryGoogleReverse(
  double lat,
  double lng,
  String language,
) async {
  if (kGoogleMapsApiKey.isEmpty) return null;
  try {
    final response = await _reverseGeoDio.get<dynamic>(
      'https://maps.googleapis.com/maps/api/geocode/json',
      queryParameters: <String, dynamic>{
        'latlng': '$lat,$lng',
        'key': kGoogleMapsApiKey,
        'language': language,
      },
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) return null;
    if (data['status'] != 'OK') return null;
    final results = data['results'];
    if (results is! List || results.isEmpty) return null;
    final first = results.first;
    if (first is! Map<String, dynamic>) return null;
    final poi = _googlePoiOrPremiseName(first);
    if (poi != null && poi.isNotEmpty) return _trimDisplay(poi);
    final formatted = first['formatted_address'] as String?;
    if (formatted != null && formatted.trim().isNotEmpty) {
      return _trimDisplay(formatted.trim());
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('reverseGeocode Google: $e\n$st');
    }
  }
  return null;
}

String? _googlePoiOrPremiseName(Map<String, dynamic> result) {
  final components = result['address_components'];
  if (components is! List) return null;
  const preferredTypes = {
    'point_of_interest',
    'establishment',
    'premise',
    'subpremise',
    'tourist_attraction',
    'park',
  };
  for (final c in components) {
    if (c is! Map<String, dynamic>) continue;
    final types = (c['types'] as List?)?.cast<String>() ?? const [];
    if (types.any(preferredTypes.contains)) {
      final name = c['long_name'] as String?;
      if (name != null && name.trim().isNotEmpty) {
        final locality = _googleComponentLongName(components, {
          'locality',
          'administrative_area_level_2',
          'sublocality',
          'neighborhood',
        });
        if (locality != null &&
            locality.isNotEmpty &&
            !name.toLowerCase().contains(locality.toLowerCase())) {
          return '$name, $locality';
        }
        return name.trim();
      }
    }
  }
  return null;
}

String? _googleComponentLongName(
  List<dynamic> components,
  Set<String> wantTypes,
) {
  for (final c in components) {
    if (c is! Map<String, dynamic>) continue;
    final types = (c['types'] as List?)?.cast<String>() ?? const [];
    if (types.any(wantTypes.contains)) {
      final n = c['long_name'] as String?;
      if (n != null && n.trim().isNotEmpty) return n.trim();
    }
  }
  return null;
}

Future<String?> _tryPlatformPlacemark(
  double lat,
  double lng,
  Locale? locale,
) async {
  try {
    if (locale != null) {
      final id = locale.countryCode != null && locale.countryCode!.isNotEmpty
          ? '${locale.languageCode}_${locale.countryCode}'
          : locale.languageCode;
      await setLocaleIdentifier(id);
    }
    final list = await placemarkFromCoordinates(lat, lng);
    if (list.isEmpty) return null;
    return placemarkToReadableLabel(list.first);
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('reverseGeocode platform: $e\n$st');
    }
  }
  return null;
}

Future<String?> _tryNominatimReverse(
  double lat,
  double lng,
  String acceptLanguage,
) async {
  try {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      <String, String>{
        'lat': '$lat',
        'lon': '$lng',
        'format': 'json',
        'addressdetails': '1',
        'accept-language': acceptLanguage,
      },
    );
    final response = await _reverseGeoDio.getUri<dynamic>(
      uri,
      options: Options(
        headers: <String, dynamic>{
          'User-Agent':
              'SalesMedicalJourney/1.0 (Flutter; reverse-geocode; +https://github.com/)',
          'Accept': 'application/json',
        },
      ),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) return null;
    return _nominatimLabel(data);
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('reverseGeocode Nominatim: $e\n$st');
    }
  }
  return null;
}

String? _nominatimLabel(Map<String, dynamic> json) {
  final name = (json['name'] as String?)?.trim();
  final addr = json['address'];
  String? city;
  String? road;
  if (addr is Map<String, dynamic>) {
    city = _firstNonEmpty([
      addr['city'] as String?,
      addr['town'] as String?,
      addr['village'] as String?,
      addr['municipality'] as String?,
      addr['county'] as String?,
    ]);
    road = _firstNonEmpty([
      addr['road'] as String?,
      addr['pedestrian'] as String?,
      addr['path'] as String?,
      addr['neighbourhood'] as String?,
      addr['suburb'] as String?,
    ]);
  }
  if (name != null && name.isNotEmpty) {
    if (city != null &&
        city.isNotEmpty &&
        !name.toLowerCase().contains(city.toLowerCase())) {
      return _trimDisplay('$name, $city');
    }
    if (road != null &&
        road.isNotEmpty &&
        road.toLowerCase() != name.toLowerCase()) {
      return _trimDisplay('$name, $road');
    }
    return _trimDisplay(name);
  }
  final parts = <String>[];
  if (road != null && road.isNotEmpty) parts.add(road);
  if (city != null && city.isNotEmpty) parts.add(city);
  if (parts.isNotEmpty) return _trimDisplay(parts.join(', '));

  final display = (json['display_name'] as String?)?.trim();
  if (display != null && display.isNotEmpty) {
    final short = display
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .take(4)
        .join(', ');
    return _trimDisplay(short.isNotEmpty ? short : display);
  }
  return null;
}

String? _firstNonEmpty(List<String?> values) {
  for (final v in values) {
    if (v != null && v.trim().isNotEmpty) return v.trim();
  }
  return null;
}

String _trimDisplay(String s, {int maxLen = 160}) {
  if (s.length <= maxLen) return s;
  return '${s.substring(0, maxLen - 1)}…';
}
