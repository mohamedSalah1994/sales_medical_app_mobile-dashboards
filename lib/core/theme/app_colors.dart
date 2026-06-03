import 'package:flutter/material.dart';

/// Brand-led palette aligned with the dkt logo (vivid red on light neutral).
class AppColors {
  /// Logo-aligned red, deepened for stronger on-screen presence (less “light” red).
  static const Color primary = Color(0xFFC41C20);

  /// Deeper crimson for gradients and emphasis.
  static const Color primaryDark = Color(0xFF8E161A);

  /// Secondary accent for variety (stats/quick actions); slate so it pairs cleanly with red.
  static const Color accent = Color(0xFF475569);

  /// Page background — soft grey like the logo backdrop.
  static const Color surface = Color(0xFFF4F4F5);

  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF18181B);
  static const Color textSecondary = Color(0xFF71717A);

  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);

  /// Orange-leaning red so errors read as “problem” vs brand [primary].
  static const Color error = Color(0xFFEA580C);

  static const Color border = Color(0xFFE4E4E7);
}
