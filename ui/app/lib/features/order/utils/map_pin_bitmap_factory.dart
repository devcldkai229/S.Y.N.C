import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:sync_app/features/challenges/models/challenge_route_models.dart';
import 'package:sync_app/features/order/widgets/tracking_map_pin.dart';

/// Raster map-pin icons for MapLibre (AWS style has no Vietnamese glyph PBFs).
abstract final class MapPinBitmapFactory {
  static const restaurantImageId = 'sync-pin-restaurant';
  static const userImageId = 'sync-pin-user';
  static const driverImageId = 'sync-pin-driver';
  static const challengeOriginImageId = 'sync-pin-challenge-origin';
  static const challengeDestinationImageId = 'sync-pin-challenge-destination';

  static Future<void> registerAll(ml.MapLibreMapController controller) async {
    await controller.addImage(
      restaurantImageId,
      await _render(
        color: TrackingMapMarkerStyle.restaurantColor,
        icon: Icons.restaurant_rounded,
        label: TrackingMapMarkerStyle.restaurantLabel,
      ),
    );
    await controller.addImage(
      userImageId,
      await _render(
        color: TrackingMapMarkerStyle.userColor,
        icon: Icons.home_rounded,
        label: TrackingMapMarkerStyle.userLabel,
      ),
    );
    await controller.addImage(
      driverImageId,
      await _render(
        color: TrackingMapMarkerStyle.driverColor,
        icon: Icons.two_wheeler_rounded,
        label: TrackingMapMarkerStyle.driverLabel,
      ),
    );
    await controller.addImage(
      challengeOriginImageId,
      await _render(
        color: const Color(0xFF2563EB),
        icon: Icons.person_pin_circle_rounded,
        label: 'Bạn',
      ),
    );
    await controller.addImage(
      challengeDestinationImageId,
      await _render(
        color: const Color(0xFF16803A),
        icon: Icons.flag_rounded,
        label: 'Tụ tập',
      ),
    );
  }

  static String routeCalloutImageId(TravelModeRouteInfo info) =>
      'sync-route-callout-${info.distanceKm.toStringAsFixed(1)}-${info.estimatedMinutes}';

  static Future<String> registerRouteCallout(
    ml.MapLibreMapController controller,
    TravelModeRouteInfo info,
  ) async {
    final id = routeCalloutImageId(info);
    await controller.addImage(id, await renderRouteCallout(info));
    return id;
  }

  static Future<Uint8List> renderRouteCallout(TravelModeRouteInfo info) async {
    const width = 168.0;
    const height = 56.0;
    const hPad = 10.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    final bubbleRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, width, height - 8),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      bubbleRect,
      Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5),
    );
    canvas.drawRRect(
      bubbleRect,
      Paint()
        ..color = const Color(0xFF16803A).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    void paintLine(String text, double top, {double size = 12, FontWeight weight = FontWeight.w700, Color? color}) {
      final painter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: size,
            fontWeight: weight,
            color: color ?? const Color(0xFF111827),
          ),
        ),
      )..layout(maxWidth: width - hPad * 2);
      painter.paint(canvas, Offset((width - painter.width) / 2, top));
    }

    paintLine('🛵 Xe máy', 8, size: 11, weight: FontWeight.w800);
    paintLine(
      '${info.distanceLabel} · ${info.durationLabel}',
      26,
      size: 13,
      weight: FontWeight.w800,
      color: const Color(0xFF16803A),
    );

    final tail = Path()
      ..moveTo(width / 2 - 7, height - 8)
      ..lineTo(width / 2 + 7, height - 8)
      ..lineTo(width / 2, height)
      ..close();
    canvas.drawPath(tail, Paint()..color = Colors.white);

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.ceil(), height.ceil());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  static Future<Uint8List> _render({
    required Color color,
    required IconData icon,
    String? label,
  }) async {
    const iconSize = 40.0;
    const labelBand = 20.0;
    const hPad = 6.0;
    const width = 88.0;
    final height = iconSize + (label != null ? labelBand + 4 : 0);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    const iconCenter = Offset(width / 2, iconSize / 2);
    const radius = 18.0;

    canvas.drawCircle(
      iconCenter,
      radius + 1.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(iconCenter, radius, Paint()..color = color);

    final iconPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily ?? 'MaterialIcons',
          package: icon.fontPackage,
          fontSize: 22,
          color: Colors.white,
        ),
      ),
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(
        iconCenter.dx - iconPainter.width / 2,
        iconCenter.dy - iconPainter.height / 2,
      ),
    );

    if (label != null && label.isNotEmpty) {
      final labelPainter = TextPainter(
        textDirection: TextDirection.ltr,
        maxLines: 1,
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      )..layout(maxWidth: width - hPad * 2);

      final pillW = labelPainter.width + 10;
      final pillH = labelPainter.height + 6;
      final pillLeft = (width - pillW) / 2;
      final pillTop = iconSize + 2;

      final pillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(pillLeft, pillTop, pillW, pillH),
        const Radius.circular(6),
      );
      canvas.drawRRect(
        pillRect,
        Paint()..color = Colors.white,
      );
      canvas.drawRRect(
        pillRect,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      labelPainter.paint(
        canvas,
        Offset(
          pillLeft + (pillW - labelPainter.width) / 2,
          pillTop + (pillH - labelPainter.height) / 2,
        ),
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.ceil(), height.ceil());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }
}
