import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:tvs/map/map_painter.dart';
import 'package:tvs/providers/navigation.dart';
import 'package:tvs/utils/coordinate_transformer.dart';

class MapNavigationView extends StatefulWidget {
  final ui.Image mapImage;
  final NavigationProvider nav;
  final CoordinateTransformer transform;

  MapNavigationView({
    super.key,
    required this.mapImage,
    required this.nav,
    required this.transform,
  });

  @override
  State<MapNavigationView> createState() => _MapNavigationViewState();
}

class _MapNavigationViewState extends State<MapNavigationView> {
  final TransformationController controller = TransformationController();

  ui.Image? airplaneIcon;

  @override
  void initState() {
    super.initState();

    widget.nav.addListener(_onNavigationUpdate);

    _loadAirplaneIcon();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _panToUserLocation(animate: false);
    });
  }

  @override
  void dispose() {
    widget.nav.removeListener(_onNavigationUpdate);
    controller.dispose();
    super.dispose();
  }

  Future<void> _loadAirplaneIcon() async {
    final data = await rootBundle.load('assets/airplane.png');
    final bytes = data.buffer.asUint8List();
    final decoded = await decodeImageFromList(bytes);

    setState(() {
      airplaneIcon = decoded;
    });
  }

  void _onNavigationUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _panToUserLocation({bool animate = true}) {
    final userLat = widget.nav.currentLatitude;
    final userLng = widget.nav.currentLongitude;

    if (userLat == 0.0 && userLng == 0.0) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final viewportWidth = renderBox.size.width;
    final viewportHeight = renderBox.size.height;

    final userPosition = widget.transform.latLngToOffset(userLat, userLng);

    final currentTransform = controller.value;
    final currentScale = currentTransform.getMaxScaleOnAxis();

    final targetX = viewportWidth / 2;
    final targetY = viewportHeight / 2;

    final scaledUserX = userPosition.dx * currentScale;
    final scaledUserY = userPosition.dy * currentScale;

    final translateX = targetX - scaledUserX;
    final translateY = targetY - scaledUserY;

    controller.value =
        Matrix4.identity()
          ..translate(translateX, translateY)
          ..scale(currentScale);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InteractiveViewer(
          transformationController: controller,
          panEnabled: true,
          scaleEnabled: true,
          minScale: 0.5,
          maxScale: 5.0,
          boundaryMargin: EdgeInsets.all(double.infinity),
          constrained: false,
          child: CustomPaint(
            size: Size(
              widget.mapImage.width.toDouble(),
              widget.mapImage.height.toDouble(),
            ),
            painter: MapPainter(
              mapImage: widget.mapImage,
              rawPath: widget.nav.rawPath,
              transform: Matrix4.identity(),
              userLat: widget.nav.currentLatitude,
              userLng: widget.nav.currentLongitude,
              userHeading: widget.nav.currentHeading,
              coordTransformer: widget.transform,
              airplaneIcon: airplaneIcon,
            ),
          ),
        ),
      ],
    );
  }
}