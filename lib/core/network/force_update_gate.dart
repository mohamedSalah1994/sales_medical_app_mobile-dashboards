import 'package:flutter/foundation.dart';
import 'package:sales_medical_app_mobile/core/network/force_update_info.dart';

/// Global gate for forced client updates (startup check or HTTP 426).
class ForceUpdateGate {
  ForceUpdateGate._();

  static final ValueNotifier<ForceUpdateInfo?> notifier =
      ValueNotifier<ForceUpdateInfo?>(null);

  static void show(ForceUpdateInfo info) {
    notifier.value = info;
  }

  static void clear() {
    notifier.value = null;
  }

  static bool get isActive => notifier.value != null;
}
