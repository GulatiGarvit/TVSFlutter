import 'package:flutter/foundation.dart';
import 'package:tvs/data_service.dart';
import 'package:tvs/dialogs/taxi_path_selection_dialog.dart';
import 'package:tvs/navigation_step.dart';
import 'package:tvs/utils/navigation_utils.dart';
import 'dart:async';

class NavigationProvider extends ChangeNotifier {
  NavigationProvider(this._dataService) {
    _listenToTelemetry();
  }

  void _listenToTelemetry() {
    // Cancel any old subscription (safety)
    _telemetrySub?.cancel();

    _telemetrySub = _dataService.telemetryStream.listen((data) {
      try {
        // TODO: Uncomment when GPS is needed
        // double? lat = data.lat;
        double? lat = 30.3522;
        // double? lng = data.lng;
        double? lng = 76.3737;
        double? hdg = data.heading;

        bool changed = false;

        // TODO: Uncomment when GPS is needed
        // if (lat != null && lat != 0.0 && lat != _currentLatitude) {
        //   _currentLatitude = lat;
        //   changed = true;
        // }

        // if (lng != null && lng != 0.0 && lng != _currentLongitude) {
        //   _currentLongitude = lng;
        //   changed = true;
        // }
        // TODO: Uncomment when magnetometer works
        if (hdg != null && hdg != _currentHeading) {
          _currentHeading = hdg;
          changed = true;
        }

        if (changed) {
          if (_isNavigating && _steps.isNotEmpty) {
            _recalculateNavigation();
          }
          notifyListeners();
        }
      } catch (e) {
        print("[NavigationProvider] Telemetry parse error: $e");
      }
    });
  }

  @override
  void dispose() {
    _telemetrySub?.cancel();
    super.dispose();
  }

  List<NavigationStep> _steps = [];
  List<RawPathSegment> _rawPath = [];
  int _currentStepIndex = 0;
  bool _isNavigating = false;
  String _unitSystem = 'Nautical';
  Map<String, dynamic>? _airportData;
  DataService _dataService;
  StreamSubscription? _telemetrySub;

  // GPS and Gyro data
  double _currentLatitude = 40.6413;
  double _currentLongitude = -73.7781;
  double _currentHeading = 90.0;
  int _distanceToNextStep = 0;

  double get currentLatitude => _currentLatitude;
  double get heading => _currentHeading;
  double get currentLongitude => _currentLongitude;
  double get currentHeading => _currentHeading;
  List<RawPathSegment> get rawPath => _rawPath;
  DataService get dataService => _dataService;

  String get unitSystem => _unitSystem;

  List<NavigationStep> get steps => _steps;
  int get currentStepIndex => _currentStepIndex;
  bool get isNavigating => _isNavigating;
  NavigationStep? get currentStep =>
      _isNavigating && _steps.isNotEmpty ? _steps[_currentStepIndex] : null;
  List<NavigationStep> get upcomingSteps =>
      _isNavigating && _currentStepIndex < _steps.length - 1
          ? _steps.sublist(_currentStepIndex + 1)
          : [];

  int get totalDistance {
    if (!_isNavigating || _steps.isEmpty) return 0;
    return _steps
        .skip(_currentStepIndex)
        .fold(0, (sum, step) => sum + step.distance);
  }

  int get totalTime {
    if (!_isNavigating || _steps.isEmpty) return 0;
    return _steps
        .skip(_currentStepIndex)
        .fold(0, (sum, step) => sum + step.time);
  }

  int get distanceToNextStep => _distanceToNextStep;

  void setUnitSystem(String unitSystem) {
    if (_unitSystem != unitSystem) {
      _unitSystem = unitSystem;
      // Recalculate all steps with new unit system
      if (_isNavigating && _rawPath.isNotEmpty) {
        _steps = _calculateNavigationSteps(_rawPath);
        notifyListeners();
      }
    }
  }

  void setAirportData(Map<String, dynamic> airportData) {
    _airportData = airportData;
  }

  void startNavigation(List<RawPathSegment> rawPath) {
    _rawPath = rawPath;
    _steps = _calculateNavigationSteps(rawPath);
    _currentStepIndex = 0;
    _isNavigating = true;
    _distanceToNextStep = _steps.isNotEmpty ? _steps[0].distance : 0;
    notifyListeners();
  }

  void stopNavigation() {
    _steps = [];
    _rawPath = [];
    _currentStepIndex = 0;
    _isNavigating = false;
    _distanceToNextStep = 0;
    notifyListeners();
  }

  void updatePosition(double latitude, double longitude, double heading) {
    _currentLatitude = latitude;
    _currentLongitude = longitude;
    _currentHeading = heading;

    if (_isNavigating && _steps.isNotEmpty) {
      _recalculateNavigation();
    }
  }

  void _recalculateNavigation() {
    // Get current step's target coordinates
    if (_currentStepIndex >= _rawPath.length) return;

    final currentSegment = _rawPath[_currentStepIndex];
    final targetLat = currentSegment.coordinates[1][0];
    final targetLng = currentSegment.coordinates[1][1];

    // Calculate distance to target waypoint
    final distanceMeters = NavigationUtils.calculateDistance(
      _currentLatitude,
      _currentLongitude,
      targetLat,
      targetLng,
    );

    // Convert to current unit system
    final distance =
        NavigationUtils.convertFromMeters(distanceMeters, _unitSystem).round();

    // Update distance to next step
    _distanceToNextStep = distance;

    // Check if we should advance to next step (within 10 meters/units threshold)
    final thresholdMeters = NavigationUtils.convertToMeters(10, _unitSystem);
    if (distanceMeters < thresholdMeters &&
        _currentStepIndex < _steps.length - 1) {
      _currentStepIndex++;
      if (_currentStepIndex < _rawPath.length) {
        _distanceToNextStep = _steps[_currentStepIndex].distance;
      }
      notifyListeners();
    } else if (_currentStepIndex == _steps.length - 1 &&
        distanceMeters < thresholdMeters) {
      // Reached final destination
      stopNavigation();
    }
  }

  List<NavigationStep> _calculateNavigationSteps(List<RawPathSegment> rawPath) {
    List<NavigationStep> steps = [];

    for (int i = 0; i < rawPath.length; i++) {
      final current = rawPath[i];
      final isLast = i == rawPath.length - 1;

      // Handle hold action
      if (current.action == NavigationAction.hold) {
        steps.add(
          NavigationStep(
            direction: Direction.straight,
            action: NavigationAction.hold,
            pathType: current.type,
            pathValue: current.name,
            distance: 0,
            time: 30, // 30 seconds hold time
            unit: _unitSystem == 'Metric' ? 'm' : _unitSystem == 'Nautical' ? 'nm' : 'ft',
          ),
        );
        continue;
      }

      // Calculate distance for this segment
      final distanceMeters = NavigationUtils.calculateDistance(
        current.coordinates[0][0],
        current.coordinates[0][1],
        current.coordinates[1][0],
        current.coordinates[1][1],
      );

      final distance =
          NavigationUtils.convertFromMeters(
            distanceMeters,
            _unitSystem,
          ).round();

      // If there's a next path, calculate turn
      if (!isLast && i + 1 < rawPath.length) {
        final next = rawPath[i + 1];

        // Skip if next is a hold action
        if (next.action == NavigationAction.hold) {
          steps.add(
            NavigationStep(
              direction: Direction.straight,
              action: NavigationAction.continueAlong,
              pathType: current.type,
              pathValue: current.name,
              distance: distance,
              time: NavigationUtils.calculateTime(distanceMeters),
              unit: _unitSystem == 'Metric' ? 'm' : _unitSystem == 'Nautical' ? 'nm' : 'ft',
            ),
          );
          continue;
        }

        // Calculate turn direction
        final currentBearing = NavigationUtils.calculateBearing(
          current.coordinates[0][0],
          current.coordinates[0][1],
          current.coordinates[1][0],
          current.coordinates[1][1],
        );

        final nextBearing = NavigationUtils.calculateBearing(
          next.coordinates[0][0],
          next.coordinates[0][1],
          next.coordinates[1][0],
          next.coordinates[1][1],
        );

        final relativeAngle = NavigationUtils.calculateRelativeAngle(
          currentBearing,
          nextBearing,
        );

        final turnDirection = NavigationUtils.getTurnDirection(relativeAngle);

        // If it's a turn, split into two steps
        if (turnDirection != TurnDirection.straight) {
          // Distance before turn (90% of segment, or 50m before, whichever is larger)
          final turnPrepDistanceMeters = NavigationUtils.convertToMeters(
            NavigationUtils.turnPreparationDistance,
            'Metric',
          );

          final distanceBeforeTurnMeters =
              distanceMeters > turnPrepDistanceMeters
                  ? distanceMeters - turnPrepDistanceMeters
                  : distanceMeters * 0.9;

          final distanceBeforeTurn =
              NavigationUtils.convertFromMeters(
                distanceBeforeTurnMeters,
                _unitSystem,
              ).round();

          // Add straight segment before turn
          steps.add(
            NavigationStep(
              direction: Direction.straight,
              action: NavigationAction.continueAlong,
              pathType: current.type,
              pathValue: current.name,
              distance: distanceBeforeTurn,
              time: NavigationUtils.calculateTime(distanceBeforeTurnMeters),
              unit: _unitSystem == 'Metric' ? 'm' : _unitSystem == 'Nautical' ? 'nm' : 'ft'
            ),
          );

          // Add turn segment
          final turnDistanceMeters = distanceMeters - distanceBeforeTurnMeters;
          final turnDistance =
              NavigationUtils.convertFromMeters(
                turnDistanceMeters,
                _unitSystem,
              ).round();

          final direction =
              turnDirection == TurnDirection.left
                  ? Direction.left
                  : turnDirection == TurnDirection.right
                  ? Direction.right
                  : Direction.straight;

          steps.add(
            NavigationStep(
              direction: direction,
              action: NavigationAction.turn,
              pathType: next.type,
              pathValue: next.name,
              distance: turnDistance,
              time: NavigationUtils.calculateTime(turnDistanceMeters),
              unit: _unitSystem == 'Metric' ? 'm' : _unitSystem == 'Nautical' ? 'nm' : 'ft',
            ),
          );
        } else {
          // No significant turn, just continue
          steps.add(
            NavigationStep(
              direction: Direction.straight,
              action: NavigationAction.continueAlong,
              pathType: current.type,
              pathValue: current.name,
              distance: distance,
              time: NavigationUtils.calculateTime(distanceMeters),
              unit: _unitSystem == 'Metric' ? 'm' : _unitSystem == 'Nautical' ? 'nm' : 'ft',
            ),
          );
        }
      } else {
        // Last segment or followed by hold - just continue straight
        steps.add(
          NavigationStep(
            direction: Direction.straight,
            action: NavigationAction.continueAlong,
            pathType: current.type,
            pathValue: current.name,
            distance: distance,
            time: NavigationUtils.calculateTime(distanceMeters),
            unit: _unitSystem == 'Metric' ? 'm' : _unitSystem == 'Nautical' ? 'nm' : 'ft',
          ),
        );
      }
    }

    return steps;
  }

  void advanceStep() {
    if (_currentStepIndex < _steps.length - 1) {
      _currentStepIndex++;
      _distanceToNextStep = _steps[_currentStepIndex].distance;
      notifyListeners();
    } else {
      stopNavigation();
    }
  }

  void previousStep() {
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      _distanceToNextStep = _steps[_currentStepIndex].distance;
      notifyListeners();
    }
  }
}
