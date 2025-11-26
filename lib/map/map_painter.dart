import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:tvs/dialogs/taxi_path_selection_dialog.dart';
import 'package:tvs/utils/coordinate_transformer.dart';

class MapPainter extends CustomPainter {
  final ui.Image mapImage;
  final List<RawPathSegment> rawPath;
  final Matrix4 transform;
  final double userLat;
  final double userLng;
  final double userHeading; // <---- NEW
  final CoordinateTransformer coordTransformer;

  static ui.Image? _airplaneIcon; // Cached airplane icon

  MapPainter({
    required this.mapImage,
    required this.rawPath,
    required this.transform,
    required this.userLat,
    required this.userLng,
    required this.userHeading,
    required this.coordTransformer,
  }) {
    _loadAirplaneIcon();
  }

  // -------------------------------------------------------------
  // LOAD AIRPLANE FROM ASSETS (only once)
  // -------------------------------------------------------------
  void _loadAirplaneIcon() async {
    if (_airplaneIcon != null) return;

    final data = await rootBundle.load('assets/airplane.png');
    final bytes = data.buffer.asUint8List();
    _airplaneIcon = await decodeImageFromList(bytes);

    // Trigger a repaint after the icon loads
    SchedulerBinding.instance.scheduleFrame();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // -------------------------------------------------------------
    // Apply viewer transform
    // -------------------------------------------------------------
    canvas.transform(transform.storage);

    // -------------------------------------------------------------
    // Draw Base Map
    // -------------------------------------------------------------
    canvas.drawImage(mapImage, Offset.zero, Paint());

    // -------------------------------------------------------------
    // Draw Navigation Path
    // -------------------------------------------------------------
    final path = Path();
    for (int i = 0; i < rawPath.length; i++) {
      final segment = rawPath[i];

      final p1 = coordTransformer.latLngToOffset(
        segment.coordinates[0][0],
        segment.coordinates[0][1],
      );

      final p2 = coordTransformer.latLngToOffset(
        segment.coordinates[1][0],
        segment.coordinates[1][1],
      );

      if (i == 0) path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
    }

    final pathPaint =
        Paint()
          ..color = Colors.blueAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, pathPaint);

    // -------------------------------------------------------------
    // Draw User Marker + Airplane
    // -------------------------------------------------------------
    if (userLat != 0 && userLng != 0) {
      final userPt = coordTransformer.latLngToOffset(userLat, userLng);

      // Base red circle
      canvas.drawCircle(
        userPt,
        12,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill,
      );

      // Draw airplane if available
      if (_airplaneIcon != null) {
        const double iconSize = 32.0;
        final double half = iconSize / 2;

        canvas.save();

        // Move origin to user center
        canvas.translate(userPt.dx, userPt.dy);

        // Rotate by heading
        canvas.rotate(userHeading * math.pi / 180);

        // Draw airplane icon centered
        final src = Rect.fromLTWH(
          0,
          0,
          _airplaneIcon!.width.toDouble(),
          _airplaneIcon!.height.toDouble(),
        );

        final dst = Rect.fromLTWH(-half, -half, iconSize, iconSize);

        canvas.drawImageRect(_airplaneIcon!, src, dst, Paint());

        canvas.restore();
      } else {
        // If airplane icon not loaded yet, draw a simple triangle
        final trianglePath = Path();
        trianglePath.moveTo(userPt.dx, userPt.dy - 10);
        trianglePath.lineTo(userPt.dx - 7, userPt.dy + 7);
        trianglePath.lineTo(userPt.dx + 7, userPt.dy + 7);
        trianglePath.close();

        canvas.drawPath(
          trianglePath,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return true;
  }
}
