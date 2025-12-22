import 'dart:ui';

class CoordinateTransformer {
  final double minLat, maxLat;
  final double minLng, maxLng;
  final double imageWidth, imageHeight;

  CoordinateTransformer({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    required this.imageWidth,
    required this.imageHeight,
  });

  Offset latLngToOffset(double lat, double lng) {
    final x = ((lng - minLng) / (maxLng - minLng)) * imageWidth;
    final y = (1 - (lat - minLat) / (maxLat - minLat)) * imageHeight;
    return Offset(x, y);
  }
}
