import 'package:geocoding/geocoding.dart';

/// Builds a single-line label from a platform [Placemark] (nearby point / area).
String? placemarkToReadableLabel(Placemark p) {
  String? clean(String? s) {
    if (s == null) return null;
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  final name = clean(p.name);
  var street = clean(p.street);
  if (street == null) {
    final sub = clean(p.subThoroughfare);
    final thru = clean(p.thoroughfare);
    if (sub != null || thru != null) {
      final combined = [sub, thru].whereType<String>().join(' ').trim();
      street = combined.isEmpty ? null : combined;
    }
  }
  final subLocality = clean(p.subLocality);
  final locality = clean(p.locality);
  final admin = clean(p.administrativeArea);
  final country = clean(p.country);

  final segments = <String>[];
  void addDistinct(String s) {
    final lower = s.toLowerCase();
    if (segments.any((e) => e.toLowerCase() == lower)) return;
    segments.add(s);
  }

  if (name != null &&
      street != null &&
      name.toLowerCase() != street.toLowerCase()) {
    addDistinct(name);
    addDistinct(street);
  } else if (name != null) {
    addDistinct(name);
  } else if (street != null) {
    addDistinct(street);
  }

  if (subLocality != null) addDistinct(subLocality);
  if (locality != null) addDistinct(locality);
  if (admin != null &&
      locality != null &&
      admin.toLowerCase() != locality.toLowerCase()) {
    addDistinct(admin);
  } else if (admin != null && locality == null) {
    addDistinct(admin);
  }
  if (country != null && segments.length < 2) addDistinct(country);

  if (segments.isEmpty) return null;
  return segments.join(', ');
}
