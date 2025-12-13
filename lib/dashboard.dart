import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:provider/provider.dart';
import 'package:tvs/widgets/demo_video_player.dart';
import 'package:video_player/video_player.dart';

import 'package:tvs/data.dart';
import 'package:tvs/map/map_navigation_view.dart';
import 'package:tvs/providers/navigation.dart';
import 'package:tvs/providers/settings.dart';
import 'package:tvs/dialogs/settings_dialog.dart';
import 'package:tvs/utils/coordinate_transformer.dart';
import 'package:tvs/widgets/clock.dart';

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
  bool _isDemoMode = false;

  VideoPlayerController? _demoDehazedController;
  VideoPlayerController? _demoCameraController;

  @override
  void dispose() {
    _disposeDemoVideos();
    super.dispose();
  }

  // -----------------------------------------------------
  // FULLSCREEN
  // -----------------------------------------------------
  Future<void> _toggleFullscreen() async {
    setState(() => _isFullscreen = !_isFullscreen);
    FullScreen.setFullScreen(_isFullscreen);
  }

  // -----------------------------------------------------
  // DEMO VIDEOS (SYNCED LOOP)
  // -----------------------------------------------------
  Future<void> _initDemoVideos() async {
    _demoDehazedController = VideoPlayerController.asset(
      'assets/defogged_trimmed_fixed.mp4',
    );
    _demoCameraController = VideoPlayerController.asset(
      'assets/trimmed_fixed.mp4',
    );

    await Future.wait([
      _demoDehazedController!.initialize(),
      _demoCameraController!.initialize(),
    ]);

    void syncLoop() {
      final d = _demoDehazedController!;
      final c = _demoCameraController!;

      if (d.value.position >= d.value.duration &&
          c.value.position >= c.value.duration) {
        d.seekTo(Duration.zero);
        c.seekTo(Duration.zero);
        d.play();
        c.play();
      }
    }

    _demoDehazedController!.addListener(syncLoop);
    _demoCameraController!.addListener(syncLoop);

    _demoDehazedController!.play();
    _demoCameraController!.play();
  }

  void _disposeDemoVideos() {
    _demoDehazedController?.dispose();
    _demoCameraController?.dispose();
    _demoDehazedController = null;
    _demoCameraController = null;
  }

  // -----------------------------------------------------
  // MAP IMAGE + TRANSFORMER
  // -----------------------------------------------------
  Future<Map<String, dynamic>> _loadMapImageFor(String airportCode) async {
    final data = await rootBundle.load('assets/$airportCode.png');
    final bytes = data.buffer.asUint8List();
    final decoded = await decodeImageFromList(bytes);

    final airport = airportData[airportCode]!;

    final transformer = CoordinateTransformer(
      minLat: airport['minLat'] as double,
      maxLat: airport['maxLat'] as double,
      minLng: airport['minLng'] as double,
      maxLng: airport['maxLng'] as double,
      imageWidth: decoded.width.toDouble(),
      imageHeight: decoded.height.toDouble(),
    );

    return {"image": decoded, "transform": transformer};
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
          elevation: 8,
          toolbarHeight: 40,
          automaticallyImplyLeading: false,
          centerTitle: true,

          leading: const Padding(
            padding: EdgeInsets.only(left: 12, top: 8, bottom: 8),
            child: ClockWidget(textStyle: TextStyle(color: Colors.white)),
          ),
          leadingWidth: 200,

          title: GestureDetector(
            onTap: _toggleFullscreen,
            child: const Text(
              'TVS Dashboard',
              style: TextStyle(color: Colors.white),
            ),
          ),

          actions: [
            Row(
              children: [
                const Text("LIVE", style: TextStyle(color: Colors.white)),
                Switch(
                  value: _isDemoMode,
                  activeColor: Colors.greenAccent,
                  onChanged: (value) async {
                    setState(() => _isDemoMode = value);
                    if (_isDemoMode) {
                      await _initDemoVideos();
                    } else {
                      _disposeDemoVideos();
                    }
                  },
                ),
                const Text("DEMO", style: TextStyle(color: Colors.white)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder:
                      (_) => MultiProvider(
                        providers: [
                          ChangeNotifierProvider.value(value: settingsProvider),
                          ChangeNotifierProvider.value(
                            value: navigationProvider,
                          ),
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
          // ---------------- NAVIGATION SIDEBAR ----------------
          Padding(
            padding: const EdgeInsets.all(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _navWidth,
              child: const NavigationSection(),
            ),
          ),

          // ---------------- RESIZE HANDLE ----------------
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

          // ---------------- MAIN SECTION ----------------
          Expanded(
            child: FeedSection(
              feeds: [
                if (!_isDemoMode) ...[
                  VideoFeed(
                    title: 'Dehazed Feed',
                    dataService: navigationProvider.dataService,
                    streamType: StreamType.dehazed,
                  ),
                  VideoFeed(
                    title: 'Camera Feed',
                    dataService: navigationProvider.dataService,
                    streamType: StreamType.camera,
                  ),
                ] else ...[
                  DemoVideoPlayer(
                    title: 'Demo – Dehazed',
                    controller: _demoDehazedController!,
                  ),
                  DemoVideoPlayer(
                    title: 'Demo – Camera',
                    controller: _demoCameraController!,
                  ),
                ],

                // ---------------- MAP (UNCHANGED) ----------------
                Consumer2<SettingsProvider, NavigationProvider>(
                  builder: (context, settings, nav, _) {
                    return FutureBuilder<Map<String, dynamic>>(
                      future: _loadMapImageFor(settings.airportCode),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
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
