import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:provider/provider.dart';

import 'package:tvs/data.dart';
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
  late double _defaultNavWidth;
  double? _navWidth;
  late double _minNavWidth;
  late double _maxNavWidth;

  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _toggleFullscreen() async {
    setState(() => _isFullscreen = !_isFullscreen);

    if (_isFullscreen) {
      await FullScreen.setFullScreen(true);
    } else {
      await FullScreen.setFullScreen(false);
    }
  }

  // -----------------------------------------------------
  // LOAD MAP PNG + TRANSFORMER for selected airport
  // -----------------------------------------------------
  Future<Map<String, dynamic>> _loadMapImageFor(String airportCode) async {
    final data = await rootBundle.load('assets/$airportCode.png');
    final bytes = data.buffer.asUint8List();
    final decoded = await decodeImageFromList(bytes);

    final airport = airportData[airportCode]!;
    final maxLat = airport['maxLat'] as double;
    final minLng = airport['minLng'] as double;
    final minLat = airport['minLat'] as double;
    final maxLng = airport['maxLng'] as double;

    final transformer = CoordinateTransformer(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
      imageWidth: decoded.width.toDouble(),
      imageHeight: decoded.height.toDouble(),
    );

    return {
      "image": decoded,
      "transform": transformer,
    };
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    _defaultNavWidth = screenWidth * 0.25;
    _navWidth ??= _defaultNavWidth;
    _minNavWidth = screenWidth * 0.15;
    _maxNavWidth = screenWidth * 0.35;

    final settingsProvider = context.read<SettingsProvider>();
    final navigationProvider = context.read<NavigationProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: AppBar(
          backgroundColor: Colors.blueGrey,
          centerTitle: true,
          elevation: 8,
          shadowColor: Colors.black,
          toolbarHeight: 40,
          automaticallyImplyLeading: false,

          leading: const Padding(
            padding: EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
            child: ClockWidget(textStyle: TextStyle(color: Colors.white)),
          ),
          leadingWidth: 200,

          title: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleFullscreen,
            child: const Text(
              'TVS Dashboard',
              style: TextStyle(color: Colors.white),
            ),
          ),

          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider.value(value: settingsProvider),
                      ChangeNotifierProvider.value(value: navigationProvider),
                    ],
                    child: const SettingsDialog(),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      body: Row(
        children: [
          // ----------------------- NAVIGATION SIDEBAR -----------------------
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8, left: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _navWidth,
              child: const NavigationSection(),
            ),
          ),

          // ---------------------- RESIZE HANDLE ----------------------------
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: (details) {
              setState(() {
                _navWidth = (_navWidth! + details.delta.dx)
                    .clamp(_minNavWidth, _maxNavWidth);
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

          // ----------------------- MAIN SECTION -----------------------------
          Expanded(
            child: FeedSection(
              feeds: [
                VideoFeed(
                  title: 'Dehazed Feed',
                  dataService: navigationProvider.dataService,
                  streamType: StreamType.dehazed,
                ),
                VideoFeed(
                  title: "Camera Feed",
                  dataService: navigationProvider.dataService,
                  streamType: StreamType.camera,
                ),

                // ----------------------- MAP SECTION -----------------------
                Consumer2<SettingsProvider, NavigationProvider>(
                  builder: (context, settings, nav, _) {
                    return FutureBuilder<Map<String, dynamic>>(
                      future: _loadMapImageFor(settings.airportCode),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white),
                          );
                        }

                        final map = snapshot.data!;
                        return MapNavigationView(
                          mapImage: map['image'],
                          transform: map['transform'],
                          nav: nav,
                        );
                      },
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
