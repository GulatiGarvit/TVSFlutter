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
  final ui.Image? airplaneIcon;

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

    // Draw user marker with compass and airplane
    if (userLat != 0 && userLng != 0) {
      final userPt = coordTransformer.latLngToOffset(userLat, userLng);

      // Draw compass rose
      _drawCompassRose(canvas, userPt, userHeading);

      // Draw airplane (rotated)
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
        // fallback triangle (rotated)
        canvas.save();
        canvas.translate(userPt.dx, userPt.dy);
        canvas.rotate(userHeading * math.pi / 180);

        final tri =
            Path()
              ..moveTo(0, -10)
              ..lineTo(-7, 7)
              ..lineTo(7, 7)
              ..close();

        canvas.drawPath(tri, Paint()..color = Colors.white);
        canvas.restore();
      }
    }

    canvas.restore();
  }

  void _drawCompassRose(Canvas canvas, Offset center, double heading) {
    const double outerRadius = 60.0;
    const double innerRadius = 50.0;
    const double labelRadius = 40.0; // Position inside the circle
    const int majorDivisions = 8; // Number of labeled tick marks (360/majorDivisions degrees apart)
    const int minorDivisions = 8; // Number of minor ticks between each major tick (e.g., 2 = ticks at every 1/3)

    final compassPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final cardinalPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final tickPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final minorTickPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw outer circle
    canvas.drawCircle(center, outerRadius, compassPaint);

    final majorStep = 360 / majorDivisions;
    final minorStep = majorStep / (minorDivisions + 1);

    // Draw all tick marks (major and minor)
    for (double deg = 0; deg < 360; deg += minorStep) {
      final angle = (deg - 90) * math.pi / 180; // -90 to start from top (0°)
      
      final isMajorTick = (deg % majorStep).abs() < 0.01; // Check if it's a major division
      final isCardinal = isMajorTick && (deg % 90).abs() < 0.01;

      final outerPoint = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );
      
      // Minor ticks are shorter
      final tickInnerRadius = isMajorTick ? innerRadius : innerRadius + 5;
      final innerPoint = Offset(
        center.dx + tickInnerRadius * math.cos(angle),
        center.dy + tickInnerRadius * math.sin(angle),
      );

      // Draw tick mark
      if (isMajorTick) {
        canvas.drawLine(
          innerPoint,
          outerPoint,
          isCardinal ? cardinalPaint : tickPaint,
        );
      } else {
        canvas.drawLine(
          innerPoint,
          outerPoint,
          minorTickPaint,
        );
      }

      // Draw degree labels only for major ticks
      if (isMajorTick) {
        final textPoint = Offset(
          center.dx + labelRadius * math.cos(angle),
          center.dy + labelRadius * math.sin(angle),
        );

        final textPainter = TextPainter(
          text: TextSpan(
            text: '${deg.round()}°',
            style: TextStyle(
              color: Colors.black.withOpacity(0.7),
              fontSize: 11,
              fontWeight: isCardinal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            textPoint.dx - textPainter.width / 2,
            textPoint.dy - textPainter.height / 2,
          ),
        );
      }
    }

    // Draw heading indicator (small triangle pointing north on the compass)
    final northAngle = (heading - 90) * math.pi / 180;
    final headingPoint = Offset(
      center.dx + (outerRadius + 8) * math.cos(northAngle),
      center.dy + (outerRadius + 8) * math.sin(northAngle),
    );

    canvas.save();
    canvas.translate(headingPoint.dx, headingPoint.dy);
    canvas.rotate(northAngle + math.pi / 2);

    final headingTriangle = Path()
      ..moveTo(0, -6)
      ..lineTo(-4, 4)
      ..lineTo(4, 4)
      ..close();

    canvas.drawPath(
      headingTriangle,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MapPainter old) => true;
}