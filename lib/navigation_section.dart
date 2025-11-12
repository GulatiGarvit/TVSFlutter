import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tvs/navigation_step.dart';
import 'package:tvs/providers/navigation.dart';

class NavigationSection extends StatefulWidget {
  const NavigationSection({super.key});

  @override
  State<NavigationSection> createState() => _NavigationSectionState();
}

class _NavigationSectionState extends State<NavigationSection> {
  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.blueGrey[800],
          ),
          child: Column(
            children: [
              _buildHeader(navProvider),
              Expanded(
                child:
                    navProvider.isNavigating
                        ? _buildNavigationView(navProvider)
                        : _buildNoRouteView(navProvider),
              ),
              if (navProvider.isNavigating) _buildFooter(navProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(NavigationProvider navProvider) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.blueGrey[900],
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Taxi Navigation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (navProvider.isNavigating)
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.white70, size: 20),
                  onPressed: () {
                    // TODO: Implement edit navigation
                  },
                  tooltip: 'Edit Route',
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red[300], size: 20),
                  onPressed: () {
                    navProvider.stopNavigation();
                  },
                  tooltip: 'Stop Navigation',
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNoRouteView(NavigationProvider navProvider) {
    return Center(
      child: GestureDetector(
        onTap: () {
          navProvider.startNavigation([
            NavigationStep(
              action: NavigationAction.turn,
              direction: Direction.right,
              pathType: PathType.taxiway,
              pathValue: 'TWY B',
              distance: 300,
              time: 120,
            ),
            NavigationStep(
              action: NavigationAction.continueAlong,
              direction: Direction.straight,
              pathType: PathType.runway,
              pathValue: 'RWY 27',
              distance: 1500,
              time: 480,
            ),
            NavigationStep(
              action: NavigationAction.hold,
              direction: Direction.straight,
              pathType: PathType.gate,
              pathValue: 'Gate A5',
              distance: 200,
              time: 60,
            ),
          ]);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 64, color: Colors.white38),
            SizedBox(height: 16),
            Text(
              'No Route Set',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Set a destination to begin navigation',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationView(NavigationProvider navProvider) {
    return Column(
      children: [
        if (navProvider.currentStep != null)
          _buildCurrentStep(navProvider.currentStep!),
        if (navProvider.upcomingSteps.isNotEmpty)
          Expanded(child: _buildUpcomingSteps(navProvider.upcomingSteps)),
      ],
    );
  }

  Widget _buildCurrentStep(NavigationStep step) {
    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          _buildDirectionIcon(step.direction, size: 48),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getActionText(step.action, step.direction),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    _buildPathTypeChip(step.pathType),
                    SizedBox(width: 8),
                    Text(
                      step.pathValue,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.straighten, color: Colors.white70, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '${step.distance}m',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.timer, color: Colors.white70, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '${_formatTime(step.time)}',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSteps(List<NavigationStep> steps) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Upcoming Steps',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: steps.length,
              itemBuilder: (context, index) {
                return _buildUpcomingStepItem(steps[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingStepItem(NavigationStep step, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey[700],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blueGrey[600],
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12),
          _buildDirectionIcon(step.direction, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getActionText(step.action, step.direction),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    _buildPathTypeChip(step.pathType, compact: true),
                    SizedBox(width: 6),
                    Text(
                      step.pathValue,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${step.distance}m',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionIcon(Direction direction, {double size = 32}) {
    IconData icon;
    switch (direction) {
      case Direction.left:
        icon = Icons.turn_left;
        break;
      case Direction.right:
        icon = Icons.turn_right;
        break;
      case Direction.straight:
        icon = Icons.arrow_upward;
        break;
    }

    return Icon(icon, color: Colors.white, size: size);
  }

  Widget _buildPathTypeChip(PathType pathType, {bool compact = false}) {
    Color color;
    String label;

    switch (pathType) {
      case PathType.taxiway:
        color = Colors.yellow[700]!;
        label = 'TWY';
        break;
      case PathType.runway:
        color = Colors.red[700]!;
        label = 'RWY';
        break;
      case PathType.apron:
        color = Colors.green[700]!;
        label = 'APRON';
        break;
      case PathType.gate:
        color = Colors.blue[700]!;
        label = 'GATE';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFooter(NavigationProvider navProvider) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey[900],
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFooterItem(
            icon: Icons.straighten,
            label: 'Distance',
            value: '${navProvider.totalDistance}m',
          ),
          Container(width: 1, height: 30, color: Colors.white24),
          _buildFooterItem(
            icon: Icons.access_time,
            label: 'ETA',
            value: _formatTime(navProvider.totalTime),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getActionText(NavigationAction action, Direction direction) {
    switch (action) {
      case NavigationAction.hold:
        return 'Hold Short';
      case NavigationAction.turn:
        return direction == Direction.left
            ? 'Turn Left'
            : direction == Direction.right
            ? 'Turn Right'
            : 'Continue';
      case NavigationAction.continueAlong:
        return 'Continue Along';
    }
  }

  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return remainingSeconds > 0
        ? '${minutes}m ${remainingSeconds}s'
        : '${minutes}m';
  }
}
