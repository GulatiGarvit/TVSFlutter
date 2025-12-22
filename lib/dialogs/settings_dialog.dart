import 'dart:async';
import 'dart:typed_data';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tvs/data.dart';
import 'package:tvs/providers/navigation.dart';
import 'package:tvs/providers/settings.dart';
import 'package:tvs/widgets/box_radio_group.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  String? _selectedAirport;
  late String _selectedUnit;

  // ---- RAW Telemetry ----
  double heading = 0;
  double lat = 0;
  double lng = 0;
  double speed = 0;
  int sats = 0;
  String gpsStatus = "Unknown";

  StreamSubscription? _telemetrySub;

  @override
  void initState() {
    super.initState();

    final dataService = context.read<NavigationProvider>().dataService;

    // subscribe to raw telemetry stream
    if (dataService == null) return;

    _telemetrySub = dataService.telemetryStream.listen((t) {
      setState(() {
        heading = t.heading;
        lat = t.lat;
        lng = t.lng;
        speed = t.speed;
        sats = t.sats;
        gpsStatus = t.gpsStatus;
      });
    });
  }

  @override
  void dispose() {
    _telemetrySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _selectedAirport =
        context.watch<SettingsProvider>().airportCode != null
            ? "${context.watch<SettingsProvider>().airportCode} - ${airportData[context.watch<SettingsProvider>().airportCode]!['name']}"
            : "KJFK - ${airportData['KJFK']!['name']}";

    _selectedUnit = context.watch<SettingsProvider>().unitSystem;

    return AlertDialog(
      title: const Text('Settings'),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---------------- AIRPORT SELECTOR ----------------
            Row(
              children: [
                Text(
                  "Select Airport: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownSearch<String>(
                    items:
                        (f, cs) =>
                            airportData.entries
                                .map((e) => "${e.key} - ${e.value['name']}")
                                .toList(),
                    selectedItem: _selectedAirport,
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          labelText: 'Search airport',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    decoratorProps: const DropDownDecoratorProps(
                      decoration: InputDecoration(border: OutlineInputBorder()),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedAirport = value;
                        if (_selectedAirport == null) return;

                        context.read<SettingsProvider>().setAirportCode(
                          _selectedAirport!.split(" - ")[0],
                        );

                        // Clear any existing navigation
                        context.read<NavigationProvider>().stopNavigation();
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ---------------- UNITS SELECTOR ----------------
            Row(
              children: [
                Text(
                  "Measurement Units: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BoxRadioGroup(
                    options: ["Nautical", "Metric", "Imperial"],
                    selected: _selectedUnit,
                    onChanged: (value) {
                      setState(() {
                        _selectedUnit = value;
                        context.read<SettingsProvider>().setUnitSystem(value);
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ---------------- RAW DEBUG TELEMETRY ----------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Debug Telemetry (Raw)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _kv("GPS Status", gpsStatus),
                  _kv("Heading", heading.toStringAsFixed(2)),
                  _kv("Latitude", lat.toStringAsFixed(6)),
                  _kv("Longitude", lng.toStringAsFixed(6)),
                  _kv("Speed (km/h)", speed.toStringAsFixed(2)),
                  _kv("Satellites", sats.toString()),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ---------------- CLOSE BUTTON ----------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  backgroundColor: Colors.blueGrey,
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper KV Row
  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(key, style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontFamily: "monospace")),
          ),
        ],
      ),
    );
  }
}
