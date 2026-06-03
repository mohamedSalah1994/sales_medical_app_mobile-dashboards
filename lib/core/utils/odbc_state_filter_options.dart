import 'dart:convert';

import 'package:sales_medical_app_mobile/core/network/api_service.dart';

/// State value for ODBC customer filters (`state` query = ERP `u_S`).
class OdbcStateFilterOption {
  const OdbcStateFilterOption({required this.code, required this.name});

  /// Sent as `state` on GET `/api/MasterData/customers/odbc`.
  final String code;
  final String name;

  factory OdbcStateFilterOption.fromJson(Map<String, dynamic> json) {
    final name =
        (json['name'] ?? json['code'] ?? json['state'] ?? '')
            .toString()
            .trim();
    return OdbcStateFilterOption(code: name, name: name);
  }

  factory OdbcStateFilterOption.fromPlainString(String value) {
    final v = value.trim();
    return OdbcStateFilterOption(code: v, name: v);
  }
}

List<OdbcStateFilterOption>? _cachedStateFilterOptions;
DateTime? _cacheLoadedAt;
const Duration _cacheTtl = Duration(hours: 6);

List<dynamic> _extractJsonList(dynamic raw) {
  if (raw is String) {
    final decoded = jsonDecode(raw);
    if (decoded is List<dynamic>) return decoded;
    if (decoded is Map<String, dynamic>) {
      return _extractJsonList(decoded);
    }
    return const [];
  }
  if (raw is List<dynamic>) return raw;
  if (raw is Map<String, dynamic>) {
    if (raw['value'] is List) return raw['value'] as List<dynamic>;
    if (raw['items'] is List) return raw['items'] as List<dynamic>;
    if (raw['data'] is List) return raw['data'] as List<dynamic>;
  }
  return const [];
}

List<OdbcStateFilterOption> _parseStateFilterList(List<dynamic> list) {
  final options = <OdbcStateFilterOption>[];
  final seen = <String>{};
  for (final e in list) {
    final OdbcStateFilterOption? opt;
    if (e is String) {
      opt = OdbcStateFilterOption.fromPlainString(e);
    } else if (e is Map) {
      opt = OdbcStateFilterOption.fromJson(Map<String, dynamic>.from(e));
    } else {
      continue;
    }
    if (opt.code.isEmpty) continue;
    if (seen.add(opt.code)) options.add(opt);
  }
  options.sort((a, b) => a.name.compareTo(b.name));
  return options;
}

Future<List<String>> _getAreaUdtStringList(
  ApiService api,
  String path, {
  Map<String, dynamic>? queryParameters,
}) async {
  final response = await api.get(path, queryParameters: queryParameters);
  if (response.statusCode != 200) return const [];
  return _parseStateFilterList(_extractJsonList(response.data))
      .map((o) => o.code)
      .toList();
}

Future<List<OdbcStateFilterOption>> _loadFromStateCity(ApiService api) async {
  final response = await api.get('/api/MasterData/state-city');
  if (response.statusCode != 200) return const [];
  return _parseStateFilterList(_extractJsonList(response.data));
}

Future<List<OdbcStateFilterOption>> _loadFromAreaUdt(ApiService api) async {
  final areas = await _getAreaUdtStringList(api, '/api/MasterData/area-udt/areas');
  if (areas.isEmpty) return const [];

  final zoneLists = await Future.wait(
    areas.map(
      (area) => _getAreaUdtStringList(
        api,
        '/api/MasterData/area-udt/zones',
        queryParameters: <String, dynamic>{'area': area},
      ),
    ),
  );

  final zones = <String>{};
  for (final list in zoneLists) {
    zones.addAll(list);
  }
  if (zones.isEmpty) return const [];

  final stateLists = await Future.wait(
    zones.map(
      (zone) => _getAreaUdtStringList(
        api,
        '/api/MasterData/area-udt/states',
        queryParameters: <String, dynamic>{'zone': zone},
      ),
    ),
  );

  final seen = <String>{};
  final options = <OdbcStateFilterOption>[];
  for (final list in stateLists) {
    for (final state in list) {
      if (state.isEmpty) continue;
      if (seen.add(state)) {
        options.add(OdbcStateFilterOption.fromPlainString(state));
      }
    }
  }

  options.sort((a, b) => a.name.compareTo(b.name));
  return options;
}

Future<List<OdbcStateFilterOption>> _fetchStateFilterOptions(
  ApiService api,
) async {
  try {
    final fromStateCity = await _loadFromStateCity(api);
    if (fromStateCity.isNotEmpty) return fromStateCity;
  } catch (_) {}

  try {
    return await _loadFromAreaUdt(api).timeout(
      const Duration(seconds: 20),
      onTimeout: () => const [],
    );
  } catch (_) {
    return const [];
  }
}

/// Loads state options for visit / journey customer pickers (ODBC `state` filter).
///
/// Results are cached in memory so repeat dialogs open quickly.
Future<List<OdbcStateFilterOption>> loadOdbcStateFilterOptions(
  ApiService api,
) async {
  final cachedAt = _cacheLoadedAt;
  if (_cachedStateFilterOptions != null &&
      cachedAt != null &&
      DateTime.now().difference(cachedAt) < _cacheTtl) {
    return _cachedStateFilterOptions!;
  }

  final result = await _fetchStateFilterOptions(api);
  if (result.isNotEmpty) {
    _cachedStateFilterOptions = result;
    _cacheLoadedAt = DateTime.now();
  }
  return result;
}
