import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:tvs/dialogs/taxi_path_selection_dialog.dart';
import 'package:tvs/utils/coordinate_transformer.dart';

class MapPainter extends CustomPainter {
  final ui.Image mapImage;
  final List<RawPathSegment> rawPath;
  final Matrix4 transform;
  final double userLat;
  final double userLng;
  final CoordinateTransformer coordTransformer;

  MapPainter({
    required this.mapImage,
    required this.rawPath,
    required this.transform,
    required this.userLat,
    required this.userLng,
    required this.coordTransformer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Apply pan/zoom/rotate transform from InteractiveViewer
    canvas.transform(transform.storage);

    // Draw base map
    canvas.drawImage(mapImage, Offset.zero, Paint());

    // --- Draw Navigation Path ---
    final path = Path();
    for (int i = 0; i < rawPath.length; i++) {
      final segment = rawPath[i];

      final p1 = coordTransformer.latLngToOffset(
        segment.coordinates[0][0], // lat
        segment.coordinates[0][1], // lng
      );

      final p2 = coordTransformer.latLngToOffset(
        segment.coordinates[1][0],
        segment.coordinates[1][1],
      );

      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      }
      path.lineTo(p2.dx, p2.dy);
    }

    final pathPaint =
        Paint()
          ..color = Colors.blueAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, pathPaint);

    // --- Draw User Location Marker ---
    if (userLat != 0 && userLng != 0) {
      final userPt = coordTransformer.latLngToOffset(userLat, userLng);

      canvas.drawCircle(
        userPt,
        12,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return true; // Because nav + user location changes
  }
}
