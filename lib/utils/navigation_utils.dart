import 'dart:math' as math;

class NavigationUtils {
  // Earth's radius in meters
  static const double earthRadiusMeters = 6371000;

  // Average taxi speed in meters per second (15 knots ≈ 7.7 m/s)
  static const double averageTaxiSpeed = 7.7;

  // Distance before turn to start turning instruction (in meters)
  static const double turnPreparationDistance = 50;

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in meters
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  /// Calculate bearing from point 1 to point 2
  /// Returns bearing in degrees (0-360)
  static double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLon = _toRadians(lon2 - lon1);
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);

    final y = math.sin(dLon) * math.cos(lat2Rad);
    final x =
        math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);

    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  /// Calculate relative turn angle between two bearings
  /// Returns angle in degrees (-180 to 180)
  /// Positive = right turn, Negative = left turn
  static double calculateRelativeAngle(double bearing1, double bearing2) {
    double angle = bearing2 - bearing1;
    if (angle > 180) angle -= 360;
    if (angle < -180) angle += 360;
    return angle;
  }

  /// Determine turn direction based on relative angle
  static TurnDirection getTurnDirection(double relativeAngle) {
    if (relativeAngle.abs() < 30) {
      return TurnDirection.straight;
    } else if (relativeAngle > 0) {
      return TurnDirection.right;
    } else {
      return TurnDirection.left;
    }
  }

  /// Convert meters to the specified unit system
  static double convertFromMeters(double meters, String unitSystem) {
    switch (unitSystem.toLowerCase()) {
      case "nautical":
        return meters * 0.000539957; // meters to nautical miles
      case "imperial":
        return meters * 3.28084; // meters to feet
      case "metric":
      default:
        return meters;
    }
  }

  /// Convert from the specified unit system to meters
  static double convertToMeters(double value, String unitSystem) {
    switch (unitSystem.toLowerCase()) {
      case "nautical":
        return value / 0.000539957; // nautical miles to meters
      case "imperial":
        return value / 3.28084; // feet to meters
      case "metric":
      default:
        return value;
    }
  }

  /// Calculate estimated time based on distance
  /// Distance should be in meters
  /// Returns time in seconds
  static int calculateTime(double distanceMeters) {
    return (distanceMeters / averageTaxiSpeed).round();
  }

  /// Format time in seconds to readable string
  static String formatTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return remainingSeconds > 0
        ? '${minutes}m ${remainingSeconds}s'
        : '${minutes}m';
  }

  /// Format distance based on unit system
  static String formatDistance(int distance, String unitSystem) {
    switch (unitSystem.toLowerCase()) {
      case "nautical":
        if (distance < 1) {
          return '${(distance * 6076).round()}ft'; // Convert NM to feet for small distances
        }
        return '${distance.toStringAsFixed(1)}NM';
      case "imperial":
        if (distance > 5280) {
          return '${(distance / 5280).toStringAsFixed(1)}mi';
        }
        return '${distance}ft';
      case "metric":
      default:
        if (distance >= 1000) {
          return '${(distance / 1000).toStringAsFixed(1)}km';
        }
        return '${distance}m';
    }
  }

  /// Get the unit label for the current unit system
  static String getDistanceUnit(String unitSystem) {
    switch (unitSystem.toLowerCase()) {
      case "nautical":
        return "NM";
      case "imperial":
        return "ft";
      case "metric":
      default:
        return "m";
    }
  }

  /// Calculate intermediate point along a path
  /// fraction: 0.0 = start point, 1.0 = end point
  static List<double> getIntermediatePoint(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
    double fraction,
  ) {
    final lat1Rad = _toRadians(lat1);
    final lon1Rad = _toRadians(lon1);
    final lat2Rad = _toRadians(lat2);
    final lon2Rad = _toRadians(lon2);

    final d = calculateDistance(lat1, lon1, lat2, lon2) / earthRadiusMeters;

    final a = math.sin((1 - fraction) * d) / math.sin(d);
    final b = math.sin(fraction * d) / math.sin(d);

    final x =
        a * math.cos(lat1Rad) * math.cos(lon1Rad) +
        b * math.cos(lat2Rad) * math.cos(lon2Rad);
    final y =
        a * math.cos(lat1Rad) * math.sin(lon1Rad) +
        b * math.cos(lat2Rad) * math.sin(lon2Rad);
    final z = a * math.sin(lat1Rad) + b * math.sin(lat2Rad);

    final lat = math.atan2(z, math.sqrt(x * x + y * y));
    final lon = math.atan2(y, x);

    return [_toDegrees(lat), _toDegrees(lon)];
  }

  /// Check if a point is within a certain distance of a target point
  static bool isWithinDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
    double thresholdMeters,
  ) {
    return calculateDistance(lat1, lon1, lat2, lon2) <= thresholdMeters;
  }

  static double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  static double _toDegrees(double radians) {
    return radians * 180 / math.pi;
  }
}

enum TurnDirection { left, right, straight }
