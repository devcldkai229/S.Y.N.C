import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:sync_app/features/order/widgets/tracking_map_pin.dart';

/// Raster map-pin icons for MapLibre (AWS style has no Vietnamese glyph PBFs).
abstract final class MapPinBitmapFactory {
  static const restaurantImageId = 'sync-pin-restaurant';
  static const userImageId = 'sync-pin-user';
  static const driverImageId = 'sync-pin-driver';

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
