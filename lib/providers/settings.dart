import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  String? _airportCode;
  String _unitSystem = "Nautical";

  bool get isDarkMode => _isDarkMode;
  String? get airportCode => _airportCode;
  String get unitSystem => _unitSystem;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setAirportCode(String code) {
    _airportCode = code;
    notifyListeners();
  }

  void setUnitSystem(String unit) {
    _unitSystem = unit;
    notifyListeners();
  }
}
