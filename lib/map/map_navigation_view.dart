import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:tvs/map/map_painter.dart';
import 'package:tvs/providers/navigation.dart';
import 'package:tvs/utils/coordinate_transformer.dart';

class MapNavigationView extends StatelessWidget {
  final ui.Image mapImage;
  final NavigationProvider nav;
  final CoordinateTransformer transform;
  final TransformationController controller = TransformationController();

  MapNavigationView({
    required this.mapImage,
    required this.nav,
    required this.transform,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: controller,
      panEnabled: true,
      scaleEnabled: true,
      minScale: 0.5,
      maxScale: 5,
      child: CustomPaint(
        size: Size(mapImage.width.toDouble(), mapImage.height.toDouble()),
        painter: MapPainter(
          mapImage: mapImage,
          rawPath: nav.rawPath, // OR nav._rawPath if you prefer
          transform: controller.value,
          userLat: nav.currentLatitude,
          userLng: nav.currentLongitude,
          coordTransformer: transform,
        ),
      ),
    );
  }
}
