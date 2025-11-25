import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tvs/direct_camera_feed.dart';
import 'package:tvs/map/map_navigation_view.dart';
import 'package:tvs/providers/navigation.dart';
import 'package:tvs/providers/settings.dart';
import 'package:tvs/dialogs/settings_dialog.dart';
import 'package:tvs/utils/coordinate_transformer.dart';
import 'package:tvs/widgets/clock.dart';
import 'data_service.dart';
import 'video_feed.dart';
import 'feed_section.dart';
import 'navigation_section.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DataService dataService;

  late double _defaultNavWidth;
  double? _navWidth;
  late double _minNavWidth;
  late double _maxNavWidth;

  ui.Image? _mapImage; // <--- Loaded PNG
  CoordinateTransformer? _transform; // <--- Lat/lng transformer

  @override
  void initState() {
    super.initState();
    dataService = DataService("ws://127.0.0.1:8765");
    dataService.connect();

    _loadMapImage(); // <--- Load PNG asset
  }

  @override
  void dispose() {
    dataService.dispose();
    super.dispose();
  }

  // -----------------------------------------------------
  // LOAD PNG AS ui.Image
  // -----------------------------------------------------
  Future<void> _loadMapImage() async {
    final data = await rootBundle.load('assets/kjfk.png');
    final bytes = data.buffer.asUint8List();
    final decoded = await decodeImageFromList(bytes);

    // ---- SET YOUR MIN/MAX LAT/LNG HERE ----
    // top-left corner
    const maxLat = 40.669243017527556;
    const minLng = -73.82430283537411;

    // bottom-right corner
    const minLat = 40.61951825537284;
    const maxLng = -73.74163620878646;

    setState(() {
      _mapImage = decoded;
      _transform = CoordinateTransformer(
        minLat: minLat,
        maxLat: maxLat,
        minLng: minLng,
        maxLng: maxLng,
        imageWidth: decoded.width.toDouble(),
        imageHeight: decoded.height.toDouble(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    _defaultNavWidth = screenWidth * 0.25;
    _navWidth ??= _defaultNavWidth;
    _minNavWidth = 0.0;
    _maxNavWidth = screenWidth * 0.35;

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: AppBar(
          title: const Text(
            'TVS Dashboard',
            style: TextStyle(color: Colors.white),
          ),
          leading: const Padding(
            padding: EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
            child: ClockWidget(textStyle: TextStyle(color: Colors.white)),
          ),
          leadingWidth: 200,
          actions: [
            IconButton(
              onPressed: () {
                final provider = context.read<SettingsProvider>();
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (context) => ChangeNotifierProvider.value(
                        value: provider,
                        child: const SettingsDialog(),
                      ),
                );
              },
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
            ),
          ],
          backgroundColor: Colors.blueGrey,
          centerTitle: true,
          toolbarHeight: 40,
          automaticallyImplyLeading: false,
          elevation: 8,
          shadowColor: Colors.black,
        ),
      ),
      body: Row(
        children: [
          // NAVIGATION SIDEBAR
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8, left: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _navWidth,
              child: const NavigationSection(),
            ),
          ),

          // DRAG RESIZER
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: (details) {
              setState(() {
                _navWidth = (_navWidth! + details.delta.dx).clamp(
                  _minNavWidth,
                  _maxNavWidth,
                );
              });
            },
            onTap: () => setState(() => _navWidth = _defaultNavWidth),
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: SizedBox(
                width: 8,
                child: Center(
                  child: Container(
                    width: 4,
                    height: 40,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ),

          // MAIN AREA WITH FEEDS + MAP
          Expanded(
            child: FeedSection(
              feeds: [
                VideoFeed(title: 'Dehazed Feed', dataService: dataService),
                const DirectCameraFeed(),

                // --- MAP FEED ---
                Consumer<NavigationProvider>(
                  builder: (context, nav, _) {
                    if (_mapImage == null || _transform == null) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    return MapNavigationView(
                      mapImage: _mapImage!,
                      nav: nav,
                      transform: _transform!,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
