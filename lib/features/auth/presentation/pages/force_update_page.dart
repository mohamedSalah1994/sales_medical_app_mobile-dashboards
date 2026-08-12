import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sales_medical_app_mobile/core/network/force_update_info.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/core/utils/app_version.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-screen block when the installed build is below the server min version.
class ForceUpdatePage extends StatelessWidget {
  const ForceUpdatePage({super.key, required this.info});

  final ForceUpdateInfo info;

  static const _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.salesmedical.sales_medical_app_mobile';

  Future<void> _openStore() async {
    final uri = Uri.parse(_androidStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool get _showStoreButton {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    final min = info.minVersion?.trim();
    final local =
        info.clientVersion?.trim().isNotEmpty == true
            ? info.clientVersion!.trim()
            : AppVersion.cachedApiOrFallback;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Icon(
                  Icons.system_update_alt,
                  size: 72,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Update required',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  info.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  [
                    'Installed: $local',
                    if (min != null && min.isNotEmpty) 'Required: $min',
                  ].join('\n'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_showStoreButton)
                  FilledButton.icon(
                    onPressed: _openStore,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Update app'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  )
                else
                  const Text(
                    'Please install the latest build of this app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
