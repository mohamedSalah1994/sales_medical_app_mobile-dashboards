import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists successful `/api/MasterData/items/lookup-odbc` payloads for offline use.
///
/// Values are JSON-decodable objects (list or map) compatible with
/// [ItemLookupResponseModel.fromOdbcAny].
class ItemLookupOdbcCache {
  ItemLookupOdbcCache(this._prefs);

  final SharedPreferences _prefs;

  static const _storeKey = 'item_lookup_odbc.cache.v1';
  static const _maxEntries = 48;

  /// Stable key for a lookup request (sales order uses [namespace] `so`).
  static String buildKey({
    required String namespace,
    required String code,
    String? customerCode,
    String? warehouseCode,
    required int skip,
    required int take,
  }) {
    final c = code.trim();
    final cc = (customerCode ?? '').trim();
    final wh = (warehouseCode ?? '').trim();
    return '$namespace|$c|$cc|$wh|$skip|$take';
  }

  Map<String, dynamic> _readMap() {
    final raw = _prefs.getString(_storeKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return Map<String, dynamic>.from(decoded);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  Future<void> _writeMap(Map<String, dynamic> map) async {
    while (map.length > _maxEntries) {
      map.remove(map.keys.last);
    }
    await _prefs.setString(_storeKey, jsonEncode(map));
  }

  /// Returns a JSON-decodable value for [ItemLookupResponseModel.fromOdbcAny], or null.
  Future<dynamic> read({
    required String namespace,
    required String code,
    String? customerCode,
    String? warehouseCode,
    required int skip,
    required int take,
  }) async {
    final key = buildKey(
      namespace: namespace,
      code: code,
      customerCode: customerCode,
      warehouseCode: warehouseCode,
      skip: skip,
      take: take,
    );
    final map = _readMap();
    final v = map[key];
    return v;
  }

  Future<void> write({
    required String namespace,
    required String code,
    String? customerCode,
    String? warehouseCode,
    required int skip,
    required int take,
    required dynamic rawBody,
  }) async {
    final normalized = _normalizeRawBody(rawBody);
    if (normalized == null) return;

    final key = buildKey(
      namespace: namespace,
      code: code,
      customerCode: customerCode,
      warehouseCode: warehouseCode,
      skip: skip,
      take: take,
    );

    final map = _readMap();
    map.remove(key);
    final ordered = <String, dynamic>{key: normalized};
    for (final e in map.entries) {
      ordered[e.key] = e.value;
    }
    await _writeMap(ordered);
  }

  /// Converts Dio `response.data` to JSON-encodable form.
  static dynamic _normalizeRawBody(dynamic rawBody) {
    if (rawBody == null) return null;
    if (rawBody is String) {
      final t = rawBody.trim();
      if (t.isEmpty) return null;
      try {
        return jsonDecode(t);
      } catch (_) {
        return null;
      }
    }
    if (rawBody is Map || rawBody is List) {
      return rawBody;
    }
    return null;
  }
}
