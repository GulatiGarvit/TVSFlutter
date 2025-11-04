import 'package:flutter/material.dart';
import 'package:tvs/feed.dart';
import 'package:tvs/feed_section.dart';
import 'package:tvs/navigation_section.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late double _defaultNavWidth;
  double? _navWidth;

  // Boundaries
  late double _minNavWidth;
  late double _maxNavWidth;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    _defaultNavWidth = screenWidth * 0.25;
    _navWidth ??= _defaultNavWidth;
    _minNavWidth = screenWidth * 0;
    _maxNavWidth = screenWidth * 0.35;

    return Scaffold(
      body: Row(
        children: [
          // Navigation Section
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: _navWidth,
            child: const NavigationSection(),
          ),

          // Drag / Tap Handle
          GestureDetector(
            behavior: HitTestBehavior.translucent,

            // Handle dragging
            onHorizontalDragUpdate: (details) {
              setState(() {
                _navWidth = _navWidth! + details.delta.dx;
                _navWidth = _navWidth!.clamp(_minNavWidth, _maxNavWidth);
              });
            },

            // Handle tapping → reset to default
            onTap: () {
              setState(() {
                _navWidth = _defaultNavWidth;
              });
            },

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

          // Feed Section
          Expanded(
            child: FeedSection(
              feeds: const [
                Feed(title: 'Feed 1'),
                Feed(title: 'Feed 2'),
                Feed(title: 'Feed 3'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
