import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to check and listen to network connectivity.
/// Considered online when WiFi or mobile data is available.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Returns true if device has WiFi or mobile connectivity.
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return _hasConnection(result);
  }

  /// Stream of connectivity changes. Emits true when online, false when offline.
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_hasConnection);

  static bool _hasConnection(List<ConnectivityResult> result) {
    if (result.isEmpty) return false;
    return result.any((r) =>
        r == ConnectivityResult.wifi || r == ConnectivityResult.mobile);
  }
}
