import 'package:flutter/material.dart';
import 'package:tvs/navigation_step.dart';

class NavigationProvider extends ChangeNotifier {
  List<NavigationStep> _steps = [];
  int _currentStepIndex = 0;
  bool _isNavigating = false;

  // GPS and Gyro data
  double _currentLatitude = 0.0;
  double _currentLongitude = 0.0;
  double _currentHeading = 0.0;
  int _distanceToNextStep = 0;

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

  void startNavigation(List<NavigationStep> steps) {
    _steps = steps;
    _currentStepIndex = 0;
    _isNavigating = true;
    _distanceToNextStep = steps.isNotEmpty ? steps[0].distance : 0;
    notifyListeners();
  }

  void stopNavigation() {
    _steps = [];
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
    // TODO: Implement actual distance calculation based on GPS position
    // For now, this is a placeholder that simulates progress

    // Calculate distance to next waypoint
    // If distance is less than threshold, advance to next step
    // Update _distanceToNextStep and _currentStepIndex accordingly

    // This method will be called frequently, so we only update the current step's
    // distance and direction without recreating the entire step list

    // Example logic (replace with actual implementation):
    // _distanceToNextStep = calculateDistanceToNextWaypoint(_currentLatitude, _currentLongitude);
    // if (_distanceToNextStep < 10 && _currentStepIndex < _steps.length - 1) {
    //   _currentStepIndex++;
    //   _distanceToNextStep = _steps[_currentStepIndex].distance;
    //   notifyListeners();
    // }
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
