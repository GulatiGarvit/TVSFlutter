import 'dart:ui' as ui;
import 'dart:math' as math;

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
  bool _isFollowingRotation = true;
  double _manualRotation = 0.0;
  double _baseRotation = 0.0;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Listen to navigation provider changes
    widget.nav.addListener(_onNavigationUpdate);

    // Pan to user location on first build
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

  void _onNavigationUpdate() {
    if (_isFollowingRotation && mounted) {
      setState(() {
        // Update rotation to match heading
      });
    }
  }

  void _panToUserLocation({bool animate = true}) {
    final userLat = widget.nav.currentLatitude;
    final userLng = widget.nav.currentLongitude;

    // Skip if no valid position
    if (userLat == 0.0 && userLng == 0.0) return;

    // Get viewport size
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final viewportWidth = renderBox.size.width;
    final viewportHeight = renderBox.size.height;

    // Convert lat/lng to map pixel coordinates
    final userPosition = widget.transform.latLngToOffset(userLat, userLng);

    // Calculate translation to center user in viewport
    // We want the user position to be at the center of the viewport
    final currentTransform = controller.value;
    final currentScale = currentTransform.getMaxScaleOnAxis();

    // Calculate where we want the user to be (center of viewport)
    final targetX = viewportWidth / 2;
    final targetY = viewportHeight / 2;

    // Calculate where the user currently is in viewport coordinates
    // (after current scale is applied)
    final scaledUserX = userPosition.dx * currentScale;
    final scaledUserY = userPosition.dy * currentScale;

    // Calculate the translation needed
    final translateX = targetX - scaledUserX;
    final translateY = targetY - scaledUserY;

    // Build new transformation matrix with updated translation
    final newTransform =
        Matrix4.identity()
          ..translate(translateX, translateY)
          ..scale(currentScale);

    controller.value = newTransform;
    _hasInitialized = true;
  }

  double get _currentRotation {
    if (_isFollowingRotation) {
      // Convert heading to radians (negative to rotate map correctly)
      return -widget.nav.currentHeading * math.pi / 180;
    } else {
      return _manualRotation;
    }
  }

  void _onRotationStart() {
    if (_isFollowingRotation) {
      setState(() {
        _isFollowingRotation = false;
        _manualRotation = -widget.nav.currentHeading * math.pi / 180;
      });
    }
    _baseRotation = _manualRotation;
  }

  void _onRotationUpdate(double rotation) {
    setState(() {
      _manualRotation = _baseRotation + rotation;
    });
  }

  void _resetRotation() {
    setState(() {
      _isFollowingRotation = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onScaleStart: (details) {
            if (details.pointerCount == 2) {
              _onRotationStart();
            }
          },
          onScaleUpdate: (details) {
            if (details.pointerCount == 2) {
              _onRotationUpdate(details.rotation);
            }
          },
          child: InteractiveViewer(
            transformationController: controller,
            panEnabled: true,
            scaleEnabled: true,
            minScale: 0.5,
            maxScale: 5.0,
            boundaryMargin: EdgeInsets.all(double.infinity),
            constrained: false,
            child: Transform.rotate(
              angle: _currentRotation,
              child: CustomPaint(
                size: Size(
                  widget.mapImage.width.toDouble(),
                  widget.mapImage.height.toDouble(),
                ),
                painter: MapPainter(
                  mapImage: widget.mapImage,
                  rawPath: widget.nav.rawPath,
                  transform: Matrix4.identity(), // Don't pass controller.value
                  userLat: widget.nav.currentLatitude,
                  userLng: widget.nav.currentLongitude,
                  coordTransformer: widget.transform,
                  userHeading: widget.nav.currentHeading,
                ),
              ),
            ),
          ),
        ),

        // Reset rotation button (only shown when not following rotation)
        if (!_isFollowingRotation)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: _resetRotation,
              tooltip: 'Reset Rotation',
              child: Icon(Icons.explore),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}
