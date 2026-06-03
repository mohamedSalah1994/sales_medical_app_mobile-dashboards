import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sales_medical_app_mobile/core/navigation/app_navigator_key.dart';
import 'package:sales_medical_app_mobile/core/network/api_service.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';

/// Posts the logged-in sales rep's location on a timer and on movement (throttled).
class FieldStaffLocationTracker with WidgetsBindingObserver {
  FieldStaffLocationTracker({required ApiService apiService})
    : _api = apiService;

  final ApiService _api;

  StreamSubscription<AuthState>? _authSub;
  AuthCubit? _auth;
  Timer? _periodic;
  StreamSubscription<Position>? _positionSub;

  bool _lifecycleObserverRegistered = false;
  bool _startInFlight = false;

  DateTime? _suppressLocationServiceDialogUntil;
  DateTime? _suppressLocationPermissionDialogUntil;

  DateTime _lastPostAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _minInterval = Duration(minutes: 2);
  static const Duration _periodicInterval = Duration(minutes: 3);
  static const Duration _dialogDebounce = Duration(seconds: 45);

  void attach(AuthCubit authCubit) {
    _auth = authCubit;
    if (!_lifecycleObserverRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _lifecycleObserverRegistered = true;
    }
    _authSub?.cancel();
    _authSub = authCubit.stream.listen(_onAuthState);
    _onAuthState(authCubit.state);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_retryStartIfNeeded());
    }
  }

  void dispose() {
    if (_lifecycleObserverRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _lifecycleObserverRegistered = false;
    }
    _auth = null;
    _authSub?.cancel();
    _stopTracking();
  }

  void _onAuthState(AuthState state) {
    final user = state.loginResponse?.user;
    final role = user?.role.toLowerCase() ?? '';
    if (!state.isAuthenticated || user == null) {
      _stopTracking();
      return;
    }
    if (role == 'salesrep') {
      unawaited(_startTracking());
    } else {
      _stopTracking();
    }
  }

  Future<void> _retryStartIfNeeded() async {
    final auth = _auth;
    if (auth == null) return;
    final state = auth.state;
    if (!state.isAuthenticated) return;
    final user = state.loginResponse?.user;
    if (user == null) return;
    if (user.role.toLowerCase() != 'salesrep') return;
    if (_periodic != null) return;
    await _startTracking();
  }

  Future<void> _startTracking() async {
    if (_periodic != null) return;
    if (_startInFlight) return;
    _startInFlight = true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          debugPrint('FieldStaffLocationTracker: location services disabled');
        }
        _scheduleLocationServiceDialog();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          debugPrint('FieldStaffLocationTracker: permission denied');
        }
        _scheduleLocationPermissionDialog(
          deniedForever: permission == LocationPermission.deniedForever,
        );
        return;
      }

      _suppressLocationServiceDialogUntil = null;
      _suppressLocationPermissionDialogUntil = null;

      _periodic = Timer.periodic(_periodicInterval, (_) => _postCurrentPosition());

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 80,
        ),
      ).listen(_onPosition, onError: (_) {});

      unawaited(_postCurrentPosition());
    } finally {
      _startInFlight = false;
    }
  }

  void _stopTracking() {
    _periodic?.cancel();
    _periodic = null;
    _positionSub?.cancel();
    _positionSub = null;
    _suppressLocationServiceDialogUntil = null;
    _suppressLocationPermissionDialogUntil = null;
  }

  bool _shouldShowDialog(DateTime? suppressUntil) {
    final until = suppressUntil;
    if (until != null && DateTime.now().isBefore(until)) return false;
    return true;
  }

  void _scheduleLocationServiceDialog() {
    if (!_shouldShowDialog(_suppressLocationServiceDialogUntil)) return;
    _suppressLocationServiceDialogUntil = DateTime.now().add(_dialogDebounce);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      final ctx = appNavigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      final l10n = AppLocalizations.of(ctx);
      showDialog<void>(
        context: ctx,
        barrierDismissible: true,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n?.locationErrorTitle ?? 'Location'),
          content: Text(
            l10n?.locationServicesDisabled ??
                'Location services are disabled. Please enable them in device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                unawaited(Geolocator.openLocationSettings());
              },
              child: Text(l10n?.openSettings ?? 'Open Settings'),
            ),
          ],
        ),
      );
    });
  }

  void _scheduleLocationPermissionDialog({required bool deniedForever}) {
    if (!_shouldShowDialog(_suppressLocationPermissionDialogUntil)) return;
    _suppressLocationPermissionDialogUntil = DateTime.now().add(_dialogDebounce);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      final ctx = appNavigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      final l10n = AppLocalizations.of(ctx);
      final message = deniedForever
          ? (l10n?.locationPermissionDeniedForever ??
                'Location permission is permanently denied. Enable it in app settings.')
          : (l10n?.locationPermissionDenied ??
                'Location permission is denied. Please grant location access.');
      showDialog<void>(
        context: ctx,
        barrierDismissible: true,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n?.locationErrorTitle ?? 'Location'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                unawaited(Geolocator.openAppSettings());
              },
              child: Text(l10n?.openSettings ?? 'Open Settings'),
            ),
          ],
        ),
      );
    });
  }

  void _onPosition(Position p) {
    final now = DateTime.now();
    if (now.difference(_lastPostAt) < _minInterval) return;
    unawaited(_send(p));
  }

  Future<void> _postCurrentPosition() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      await _send(p);
    } catch (_) {}
  }

  Future<void> _send(Position p) async {
    try {
      await _api.post(
        '/api/FieldStaff/location',
        data: <String, dynamic>{
          'latitude': p.latitude,
          'longitude': p.longitude,
          'recordedAt': DateTime.now().toUtc().toIso8601String(),
          'accuracyMeters': p.accuracy,
        },
      );
      _lastPostAt = DateTime.now();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FieldStaffLocationTracker POST failed: $e');
      }
    }
  }
}
