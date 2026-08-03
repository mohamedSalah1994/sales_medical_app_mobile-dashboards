import 'package:package_info_plus/package_info_plus.dart';

/// App version string shown in the sidebar and sent on login.
/// Keep [fallback] in sync with `version:` in pubspec.yaml.
class AppVersion {
  AppVersion._();

  /// Fallback when package info is unavailable (e.g. before plugin loads).
  static const String fallback = 'v1.0.4 (5)';

  static String? _cached;

  /// Same value as sidebar: `v{version} ({buildNumber})`.
  static Future<String> getDisplayVersion() async {
    if (_cached != null) return _cached!;
    try {
      final info = await PackageInfo.fromPlatform();
      _cached = 'v${info.version} (${info.buildNumber})';
    } catch (_) {
      _cached = fallback;
    }
    return _cached!;
  }

  /// Synchronous cached value if already loaded; otherwise [fallback].
  static String get cachedOrFallback => _cached ?? fallback;
}
