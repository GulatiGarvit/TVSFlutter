import 'package:flutter/foundation.dart';

enum Direction { left, right, straight }

enum NavigationAction { hold, turn, continueAlong }

enum PathType { taxiway, runway, apron, gate }

class NavigationStep {
  final Direction direction;
  final NavigationAction action;
  final PathType pathType;
  final String pathValue;
  final int distance;
  final int time;
  final String unit;

  NavigationStep({
    required this.direction,
    required this.action,
    required this.pathType,
    required this.pathValue,
    required this.distance,
    required this.time,
    required this.unit,
  });

  NavigationStep copyWith({
    Direction? direction,
    NavigationAction? action,
    PathType? pathType,
    String? pathValue,
    int? distance,
    int? time,
    String? unit,
  }) {
    return NavigationStep(
      direction: direction ?? this.direction,
      action: action ?? this.action,
      pathType: pathType ?? this.pathType,
      pathValue: pathValue ?? this.pathValue,
      distance: distance ?? this.distance,
      time: time ?? this.time,
      unit: unit ?? this.unit,
    );
  }
}
