import 'package:flutter/material.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/core/utils/app_version.dart';

/// Shows the app version (e.g. "v1.0.0 (1)") read from the build metadata.
class AppVersionLabel extends StatefulWidget {
  const AppVersionLabel({super.key, this.textAlign = TextAlign.center, this.style});

  final TextAlign textAlign;
  final TextStyle? style;

  @override
  State<AppVersionLabel> createState() => _AppVersionLabelState();
}

class _AppVersionLabelState extends State<AppVersionLabel> {
  late String _version;

  @override
  void initState() {
    super.initState();
    _version = AppVersion.cachedOrFallback;
    _load();
  }

  Future<void> _load() async {
    final value = await AppVersion.getDisplayVersion();
    if (mounted) setState(() => _version = value);
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
