/// Helpers for turning ERP / ODBC location strings into launchable Google Maps
/// URIs.
///
/// The visit "Google Maps link" field carries whatever the customer record
/// provided - sometimes a real `https://maps.google.com/...` URL, sometimes
/// just `U_LOC_PNT` as `(lat,lng)` or `lat,lng`. This helper normalises all of
/// those into a URI we can pass to `url_launcher`.
library;

/// Builds a launchable Google Maps URI from [raw], supporting:
///   - Already-formed `http://` / `https://` URLs (returned as-is).
///   - `geo:` URIs (returned as-is).
///   - `(lat,lng)` strings, e.g. `(24.4074,32.9258)`.
///   - `lat,lng` strings, e.g. `24.4074, 32.9258`.
///
/// Returns `null` when [raw] is empty or cannot be interpreted.
Uri? buildGoogleMapsUri(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final lower = trimmed.toLowerCase();
  if (lower.startsWith('http://') ||
      lower.startsWith('https://') ||
      lower.startsWith('geo:')) {
    return Uri.tryParse(trimmed);
  }

  final coords = parseLatLng(trimmed);
  if (coords != null) {
    return googleMapsSearchUri(coords.lat, coords.lng);
  }
  return null;
}

/// Canonical HTTPS URI for opening a point in Google Maps (proper encoding).
Uri googleMapsSearchUri(double lat, double lng) {
  return Uri.https('www.google.com', '/maps', <String, String>{
    'q': '$lat,$lng',
  });
}

/// Parses a coordinate pair from `(lat,lng)`, `lat,lng`, or `lat;lng`.
({double lat, double lng})? parseLatLng(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return null;

  // Decode %2C etc. when the string is URL-encoded or pasted from a browser.
  try {
    s = Uri.decodeQueryComponent(s);
  } catch (_) {
    try {
      s = Uri.decodeFull(s);
    } catch (_) {}
  }

  // Unicode parentheses sometimes appear in copied ERP text.
  s = s
      .replaceAll('（', '(')
      .replaceAll('）', ')')
      .trim();

  // Strict pattern: optional parens, lat, comma or semicolon, lng.
  final strict = RegExp(
    r'^\s*\(?\s*(-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)\s*[,;]\s*(-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)\s*\)?\s*$',
  ).firstMatch(s);
  if (strict != null) {
    final lat = double.tryParse(strict.group(1)!);
    final lng = double.tryParse(strict.group(2)!);
    if (lat != null &&
        lng != null &&
        lat.abs() <= 90 &&
        lng.abs() <= 180) {
      return (lat: lat, lng: lng);
    }
  }

  if (s.startsWith('(') && s.endsWith(')')) {
    s = s.substring(1, s.length - 1);
  }
  final parts = s.split(',');
  if (parts.length != 2) {
    final semi = s.split(';');
    if (semi.length == 2) {
      final lat = double.tryParse(semi[0].trim());
      final lng = double.tryParse(semi[1].trim());
      if (lat != null &&
          lng != null &&
          lat.abs() <= 90 &&
          lng.abs() <= 180) {
        return (lat: lat, lng: lng);
      }
    }
    return null;
  }
  final lat = double.tryParse(parts[0].trim());
  final lng = double.tryParse(parts[1].trim());
  if (lat == null || lng == null) return null;
  if (lat.abs() > 90 || lng.abs() > 180) return null;
  return (lat: lat, lng: lng);
}

/// Last-resort: find first two decimal numbers in [raw] that look like lat/lng.
({double lat, double lng})? scrapeLatLngPair(String raw) {
  final matches = RegExp(r'(-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)')
      .allMatches(raw)
      .map((m) => double.tryParse(m.group(0)!))
      .whereType<double>()
      .toList();
  if (matches.length < 2) return null;
  final lat = matches[0];
  final lng = matches[1];
  if (lat.abs() <= 90 && lng.abs() <= 180) {
    return (lat: lat, lng: lng);
  }
  return null;
}

/// Tries to read lat/lng from a plain coordinate string or a Google Maps URL.
({double lat, double lng})? extractLatLngFromMapsRaw(String? raw) {
  if (raw == null) return null;
  var t = raw.trim();
  if (t.isEmpty) return null;

  final fromPlain = parseLatLng(t);
  if (fromPlain != null) return fromPlain;

  final lower = t.toLowerCase();
  if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
    return scrapeLatLngPair(t);
  }

  final uri = Uri.tryParse(t);
  if (uri != null) {
    for (final key in ['q', 'query', 'center', 'll', 'daddr']) {
      final v = uri.queryParameters[key];
      if (v == null || v.isEmpty) continue;
      final decoded = Uri.decodeQueryComponent(v.replaceAll('+', ' '));
      final p = parseLatLng(decoded);
      if (p != null) return p;
      final s2 = scrapeLatLngPair(decoded);
      if (s2 != null) return s2;
    }
  }

  final atMatch = RegExp(
    r'@(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)',
  ).firstMatch(t);
  if (atMatch != null) {
    final lat = double.tryParse(atMatch.group(1)!);
    final lng = double.tryParse(atMatch.group(2)!);
    if (lat != null && lng != null) return (lat: lat, lng: lng);
  }

  final qMatch = RegExp(
    r'[?&]q=([^&]+)',
  ).firstMatch(t);
  if (qMatch != null) {
    final segment = Uri.decodeQueryComponent(qMatch.group(1)!);
    final p = parseLatLng(segment);
    if (p != null) return p;
  }

  return scrapeLatLngPair(t);
}
