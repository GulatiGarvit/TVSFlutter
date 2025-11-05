import 'package:flutter/material.dart';
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
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: _navWidth,
            child: const NavigationSection(),
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
              child: Container(
                width: 8,
                color: Colors.grey.shade300,
                child: Center(
                  child: Container(
                    width: 2,
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
                VideoFeed(title: 'Camera Feed', dataService: dataService),
                const Feed(title: 'Feed 2'),
                const Feed(title: 'Feed 3'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
