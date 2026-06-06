import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';

/// Shows the app version (e.g. "v1.0.0 (1)") read from the build metadata.
class AppVersionLabel extends StatefulWidget {
  const AppVersionLabel({super.key, this.textAlign = TextAlign.center, this.style});

  final TextAlign textAlign;
  final TextStyle? style;

  @override
  State<AppVersionLabel> createState() => _AppVersionLabelState();
}

class _AppVersionLabelState extends State<AppVersionLabel> {
  /// Fallback shown before the native plugin loads (or if it is unavailable).
  /// Keep in sync with the `version:` field in pubspec.yaml.
  static const String _fallback = 'v1.0.2';

  static String? _cached;
  late String _version;

  @override
  void initState() {
    super.initState();
    _version = _cached ?? _fallback;
    if (_cached == null) _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final value = 'v${info.version} (${info.buildNumber})';
      _cached = value;
      if (mounted) setState(() => _version = value);
    } catch (_) {
      // Keep the fallback if version metadata is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _version,
      textAlign: widget.textAlign,
      style: widget.style ??
          const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
    );
  }
}
