import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tvs/direct_camera_feed.dart';
import 'package:tvs/providers/navigation.dart';
import 'package:tvs/settings_dialog.dart';
import 'package:tvs/widgets/clock.dart';
import 'data_service.dart';
import 'video_feed.dart';
import 'feed.dart';
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

  @override
  void initState() {
    super.initState();
    // Connect once on startup
    dataService = DataService("ws://127.0.0.1:8765");
    dataService.connect();
  }

  @override
  void dispose() {
    dataService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    _defaultNavWidth = screenWidth * 0.25;
    _navWidth ??= _defaultNavWidth;
    _minNavWidth = screenWidth * 0.0;
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
                // Show settings dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const SettingsDialog(),
                );
              },
              icon: Icon(Icons.settings_outlined, color: Colors.white),
            ),
          ],
          backgroundColor: Colors.blueGrey,
          centerTitle: true,
          toolbarHeight: 40,
          automaticallyImplyLeading: false,
          elevation: 8,
          shadowColor: Colors.black,
          flexibleSpace: Container(),
        ),
      ),
      body: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 8.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _navWidth,
              child: ChangeNotifierProvider(
                create: (_) => NavigationProvider(),
                child: NavigationSection(),
              ),
            ),
          ),
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
          Expanded(
            child: FeedSection(
              feeds: [
                VideoFeed(title: 'Dehazed Feed', dataService: dataService),
                const DirectCameraFeed(),
                const Feed(title: 'Feed 3'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
