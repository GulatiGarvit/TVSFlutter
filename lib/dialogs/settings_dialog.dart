import 'dart:async';
import 'dart:io';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tvs/data.dart';
import 'package:tvs/providers/navigation.dart';
import 'package:tvs/providers/settings.dart';
import 'package:tvs/utils/server_controller.dart';
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

  // ---- Performance Stats ----
  double camFps = 0;
  double dehazeFps = 0;
  double avgInferenceMs = 0;
  double e2eLatencyMs = 0;
  double cpuPercent = 0;
  double gpuPercent = 0;

  bool showAdvanced = false;

  StreamSubscription? _telemetrySub;

  @override
  void initState() {
    super.initState();

    final dataService = context.read<NavigationProvider>().dataService;
    if (dataService == null) return;

    _telemetrySub = dataService.telemetryStream.listen((t) {
      setState(() {
        // Raw telemetry
        heading = t.heading;
        lat = t.lat;
        lng = t.lng;
        speed = t.speed;
        sats = t.sats;
        gpsStatus = t.gpsStatus;

        // Stats
        camFps = t.stats.cameraFps;
        dehazeFps = t.stats.dehazedFps;
        avgInferenceMs = t.stats.avgInferenceMs;
        e2eLatencyMs = t.stats.e2eLatencyMs;
        cpuPercent = t.stats.cpuPercent;
        gpuPercent = t.stats.gpuPercent;
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
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ---------------- AIRPORT SELECTOR ----------------
              Row(
                children: [
                  const Text("Select Airport:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownSearch<String>(
                      items: (f, cs) => airportData.entries
                          .map((e) => "${e.key} - ${e.value['name']}")
                          .toList(),
                      selectedItem: _selectedAirport,
                      popupProps: const PopupProps.menu(showSearchBox: true),
                      onChanged: (value) {
                        if (value == null) return;
                        context
                            .read<SettingsProvider>()
                            .setAirportCode(value.split(" - ")[0]);
                        context.read<NavigationProvider>().stopNavigation();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------------- UNITS SELECTOR ----------------
              Row(
                children: [
                  const Text("Measurement Units:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: BoxRadioGroup(
                      options: const ["Nautical", "Metric", "Imperial"],
                      selected: _selectedUnit,
                      onChanged: (value) {
                        context
                            .read<SettingsProvider>()
                            .setUnitSystem(value);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ---------------- RAW TELEMETRY ----------------
              _section(
                title: "Debug Telemetry (Raw)",
                children: [
                  // TODO: Replace with real telemetry values when GPS is working
                  _kv("GPS Status", "Locked"),
                  _kv("Heading", heading.toStringAsFixed(2)),
                  _kv("Latitude", "30.3522"),
                  _kv("Longitude", "76.3737"),
                  _kv("Speed (km/h)", "0"),
                  _kv("Satellites", "4"),
                ],
              ),

              const SizedBox(height: 16),

              // ---------------- ADVANCED TOGGLE ----------------
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  "Advanced",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle:
                    const Text("Show performance & system statistics"),
                value: showAdvanced,
                onChanged: (v) => setState(() => showAdvanced = v),
              ),

              if (showAdvanced) ...[
                const SizedBox(height: 8),

                // ---------------- PERFORMANCE STATS ----------------
                _section(
                  title: "Performance Stats",
                  children: [
                    _kv("Camera FPS", camFps.toStringAsFixed(2)),
                    _kv("Dehaze FPS", dehazeFps.toStringAsFixed(2)),
                    _kv("Inference (ms)", avgInferenceMs.toStringAsFixed(1)),
                    // _kv("Latency (ms)", e2eLatencyMs.toStringAsFixed(1)),
                    _kv("CPU Usage (%)", cpuPercent.toStringAsFixed(1)),
                    // _kv("GPU Usage (%)", gpuPercent.toStringAsFixed(1)),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // ---------------- CLOSE ----------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Close"),
                ),
              ),

              const SizedBox(height: 12),

              // ---------------- SHUTDOWN ----------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.power_settings_new),
                  label: const Text("Shutdown TVS"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Shutdown TVS'),
                        content: const Text(
                            'This will stop the server and exit the application.\n\nAre you sure?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Shutdown'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await shutdownTVS();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- UI HELPERS ----------------

  Widget _section({required String title, required List<Widget> children}) {
    return Container(
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
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child:
                Text(key, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child:
                Text(value, style: const TextStyle(fontFamily: "monospace")),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//                     Shutdown Logic
// ============================================================

Future<void> shutdownTVS({bool exitApp = true}) async {
  ServerController.instance.shutdownServer();
  await Future.delayed(const Duration(milliseconds: 200));
  if (exitApp) exit(0);
}
