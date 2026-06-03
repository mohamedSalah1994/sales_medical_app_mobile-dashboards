import 'package:flutter/material.dart';
import 'package:sales_medical_app_mobile/core/constants/app_assets.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';

/// App logo from [AppAssets.logo]. Falls back to a medical icon if the asset is missing.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.width,
    this.height = 48,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.fallbackIconColor,
  });

  final double? width;
  final double height;
  final BoxFit fit;
  final double? borderRadius;
  final Color? fallbackIconColor;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      AppAssets.logo,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.medical_services_rounded,
          size: height * 0.55,
          color: fallbackIconColor ?? AppColors.primary,
        );
      },
    );
    final r = borderRadius;
    // Optional clip for rounded containers. Omit [borderRadius] for sharpest edges.
    if (r != null && r > 0) {
      image = ClipRRect(
        clipBehavior: Clip.hardEdge,
        borderRadius: BorderRadius.circular(r),
        child: image,
      );
    }
    return image;
  }
}
