import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  String? _airportCode;

  bool get isDarkMode => _isDarkMode;
  String? get airportCode => _airportCode;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setAirportCode(String code) {
    _airportCode = code;
    notifyListeners();
  }
}
