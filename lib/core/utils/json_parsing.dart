/// Parses API/JSON values that may be int, double, or string (e.g. legacy cached data).
int? parseOptionalInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

/// Parses API/JSON values that may be string or number (e.g. territoryId `"CAIRO"` or `12`).
String? parseOptionalString(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }
  if (value is num) return value.toString();
  final t = value.toString().trim();
  return t.isEmpty ? null : t;
}
