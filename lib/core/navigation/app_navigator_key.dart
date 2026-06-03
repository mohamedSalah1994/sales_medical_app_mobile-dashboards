import 'package:flutter/material.dart';

/// Root [Navigator] key for [MaterialApp]. Used where a [BuildContext] is not
/// under the navigator (e.g. overlays in [MaterialApp.builder]).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
