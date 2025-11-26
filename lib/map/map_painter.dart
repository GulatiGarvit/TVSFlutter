import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tvs/dialogs/taxi_path_selection_dialog.dart';
import 'package:tvs/utils/coordinate_transformer.dart';

class MapPainter extends CustomPainter {
  final ui.Image mapImage;
  final List<RawPathSegment> rawPath;
  final Matrix4 transform;
  final double userLat;
  final double userLng;
  final double userHeading;
  final CoordinateTransformer coordTransformer;

  final ui.Image? airplaneIcon; // <-- ICON PROVIDED BY PARENT

  MapPainter({
    required this.mapImage,
    required this.rawPath,
    required this.transform,
    required this.userLat,
    required this.userLng,
    required this.userHeading,
    required this.coordTransformer,
    required this.airplaneIcon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    canvas.transform(transform.storage);

    // Draw map
    canvas.drawImage(mapImage, Offset.zero, Paint());

    // Draw path
    final path = Path();
    for (int i = 0; i < rawPath.length; i++) {
      final seg = rawPath[i];

      final p1 = coordTransformer.latLngToOffset(
        seg.coordinates[0][0],
        seg.coordinates[0][1],
      );
      final p2 = coordTransformer.latLngToOffset(
        seg.coordinates[1][0],
        seg.coordinates[1][1],
      );

      if (i == 0) path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blueAccent
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Draw user marker + airplane
    if (userLat != 0 && userLng != 0) {
      final userPt = coordTransformer.latLngToOffset(userLat, userLng);

      if (airplaneIcon != null) {
        const double size = 48;
        final double half = size / 2;

        canvas.save();
        canvas.translate(userPt.dx, userPt.dy);
        canvas.rotate(userHeading * math.pi / 180);

        final src = Rect.fromLTWH(
          0,
          0,
          airplaneIcon!.width.toDouble(),
          airplaneIcon!.height.toDouble(),
        );
        final dst = Rect.fromLTWH(-half, -half, size, size);

        canvas.drawImageRect(airplaneIcon!, src, dst, Paint());

        canvas.restore();
      } else {
        // fallback triangle
        final tri =
            Path()
              ..moveTo(userPt.dx, userPt.dy - 10)
              ..lineTo(userPt.dx - 7, userPt.dy + 7)
              ..lineTo(userPt.dx + 7, userPt.dy + 7)
              ..close();

        canvas.drawPath(tri, Paint()..color = Colors.white);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MapPainter old) => true;
}
