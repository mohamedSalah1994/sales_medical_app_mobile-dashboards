import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:url_launcher/url_launcher.dart';

import 'package:sales_medical_app_mobile/core/utils/maps_link.dart';

bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// Opens Google Maps for [raw] (coordinates like `(lat,lng)`, `lat,lng`, or a
/// maps URL). Builds `https://www.google.com/maps?q=lat,lng` when possible.
///
/// On Android, [AndroidIntent] is used first so opening works even when
/// [launchUrl] incorrectly returns false (common on some OEMs).
Future<bool> launchGoogleMapsFromRaw(String? raw) async {
  debugPrint('[maps] launchGoogleMapsFromRaw raw="$raw"');

  final coords = extractLatLngFromMapsRaw(raw);
  final Uri? primaryUri =
      coords != null
          ? googleMapsSearchUri(coords.lat, coords.lng)
          : buildGoogleMapsUri(raw);

  if (primaryUri == null) {
    debugPrint('[maps] could not parse coordinates or URL');
    return false;
  }

  debugPrint('[maps] primaryUri=$primaryUri');

  Future<bool> tryLaunchUrl(Uri uri) async {
    const modes = <LaunchMode>[
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
      LaunchMode.externalNonBrowserApplication,
    ];
    for (final mode in modes) {
      try {
        final ok = await launchUrl(uri, mode: mode);
        debugPrint('[maps] launchUrl $uri mode=$mode -> $ok');
        if (ok) return true;
      } catch (e) {
        debugPrint('[maps] launchUrl $uri mode=$mode threw: $e');
      }
    }
    return false;
  }

  // --- Android: explicit VIEW intent (most reliable for Maps / browser) ---
  if (_isAndroid) {
    try {
      await AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: primaryUri.toString(),
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      ).launch();
      debugPrint('[maps] AndroidIntent VIEW dispatched');
      return true;
    } catch (e) {
      debugPrint('[maps] AndroidIntent https threw: $e');
    }
    if (coords != null) {
      final lat = coords.lat;
      final lng = coords.lng;
      final geo = 'geo:$lat,$lng?q=$lat,$lng';
      try {
        await AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: geo,
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        ).launch();
        debugPrint('[maps] AndroidIntent geo dispatched');
        return true;
      } catch (e) {
        debugPrint('[maps] AndroidIntent geo threw: $e');
      }
    }
  }

  // --- iOS: try native Google Maps app, then universal link ---
  if (_isIOS && coords != null) {
    final lat = coords.lat;
    final lng = coords.lng;
    final native = Uri.parse(
      'comgooglemaps://?q=$lat,$lng&center=$lat,$lng&zoom=16',
    );
    try {
      if (await launchUrl(native, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (e) {
      debugPrint('[maps] iOS comgooglemaps threw: $e');
    }
  }

  if (await tryLaunchUrl(primaryUri)) return true;

  if (coords != null) {
    final lat = coords.lat;
    final lng = coords.lng;
    final alt = Uri.https('maps.google.com', '/', <String, String>{
      'q': '$lat,$lng',
    });
    if (await tryLaunchUrl(alt)) return true;
  }

  debugPrint('[maps] all launch paths failed');
  return false;
}
