import 'package:package_info_plus/package_info_plus.dart';

/// Single source of truth for app version (aligned with `pubspec.yaml` / store build).
///
/// - [getApiVersion] → sent as `X-App-Version` and login body `version`
/// - [getDisplayVersion] → sidebar / UI (`v1.0.5 (17)`)
class AppVersion {
  AppVersion._();

  /// Fallback when package info is unavailable. Keep in sync with `version:` in pubspec.
  static const String fallbackApi = '1.0.4';
  static const String fallbackDisplay = 'v1.0.4';

  static String? _apiCached;
  static String? _displayCached;

  /// Semver (+ optional build) for API header/body, e.g. `1.0.5+17`.
  static Future<String> getApiVersion() async {
    if (_apiCached != null) return _apiCached!;
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      final build = info.buildNumber.trim();
      _apiCached = build.isEmpty ? version : '$version+$build';
      _displayCached = 'v$version ($build)';
    } catch (_) {
      _apiCached = fallbackApi;
      _displayCached = fallbackDisplay;
    }
    return _apiCached!;
  }

  /// Same value as sidebar: `v{version} ({buildNumber})`.
  static Future<String> getDisplayVersion() async {
    if (_displayCached != null) return _displayCached!;
    await getApiVersion();
    return _displayCached ?? fallbackDisplay;
  }

  /// Synchronous cached API version if already loaded; otherwise [fallbackApi].
  static String get cachedApiOrFallback => _apiCached ?? fallbackApi;

  /// Synchronous cached display value if already loaded; otherwise [fallbackDisplay].
  static String get cachedOrFallback => _displayCached ?? fallbackDisplay;

  /// Ensures package info is loaded once at app start.
  static Future<void> ensureLoaded() => getApiVersion();
}
