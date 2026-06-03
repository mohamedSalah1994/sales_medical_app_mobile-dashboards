import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';

/// Builds a map marker bitmap: sales name in a pill above a pin. Geographic
/// anchor is the bottom center of the pin ([anchor] = [0.5, 1.0]).
Future<BitmapDescriptor> createTeamMapMemberMarkerBitmap({
  required String displayName,
  required TextDirection textDirection,
  double devicePixelRatio = 3.0,
}) async {
  const maxLabelWidth = 220.0;
  const padH = 10.0;
  const padV = 8.0;
  const pinRadius = 8.0;
  const gapAfterLabel = 6.0;
  const stemLength = 6.0;
  const fontSize = 13.0;

  var text = displayName.trim();
  if (text.isEmpty) text = '?';

  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    ),
    textDirection: textDirection,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxLabelWidth - padH * 2);

  final labelW = (textPainter.width + padH * 2).clamp(48.0, maxLabelWidth);
  final labelH = textPainter.height + padV * 2;
  final totalW = labelW;
  final totalH = labelH + gapAfterLabel + stemLength + pinRadius * 2;

  final dpr = devicePixelRatio.clamp(1.0, 4.0);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(dpr);

  final rrect = RRect.fromRectAndRadius(
    Rect.fromLTWH(0, 0, labelW, labelH),
    const Radius.circular(10),
  );
  canvas.drawRRect(rrect, Paint()..color = Colors.white);
  canvas.drawRRect(
    rrect,
    Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );

  textPainter.paint(
    canvas,
    Offset((labelW - textPainter.width) / 2, padV),
  );

  final cx = totalW / 2;
  final stemTop = labelH;
  final stemBottom = stemTop + gapAfterLabel + stemLength;

  canvas.drawLine(
    Offset(cx, stemTop),
    Offset(cx, stemBottom),
    Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round,
  );

  final pinCenterY = stemBottom + pinRadius;
  canvas.drawCircle(Offset(cx, pinCenterY), pinRadius, Paint()..color = AppColors.primary);
  canvas.drawCircle(
    Offset(cx, pinCenterY),
    pinRadius,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );

  final picture = recorder.endRecording();
  final outW = (totalW * dpr).round();
  final outH = (totalH * dpr).round();
  final image = await picture.toImage(outW, outH);
  final bd = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (bd == null) {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }
  return BitmapDescriptor.bytes(
    bd.buffer.asUint8List(),
    width: totalW,
    height: totalH,
    imagePixelRatio: dpr,
  );
}
