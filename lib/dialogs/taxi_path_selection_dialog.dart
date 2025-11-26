import 'package:flutter/material.dart';
import 'package:tvs/navigation_step.dart';

class TaxiPathSelectionDialog extends StatefulWidget {
  final Map<String, dynamic> airportData;
  final String airportCode;
  final List<RawPathSegment>? existingPath;

  const TaxiPathSelectionDialog({
    super.key,
    required this.airportData,
    required this.airportCode,
    this.existingPath,
  });

  @override
  State<TaxiPathSelectionDialog> createState() => _TaxiPathSelectionDialogState();
}

class _TaxiPathSelectionDialogState extends State<TaxiPathSelectionDialog> {
  List<SelectedPath> _selectedPaths = [];
  String? _currentPath;
  Set<String> _availablePaths = {};
  bool _showHoldOption = false;

  @override
  void initState() {
    super.initState();
    _initializeAvailablePaths();
    _loadExistingPath();
  }

  void _initializeAvailablePaths() {
    final airport = widget.airportData[widget.airportCode];
    if (airport != null) {
      _availablePaths = {};
      
      if (airport['taxiways'] != null) {
        _availablePaths.addAll(List<String>.from(airport['taxiways']));
      }
      if (airport['runways'] != null) {
        _availablePaths.addAll(List<String>.from(airport['runways']));
      }
      if (airport['aprons'] != null) {
        _availablePaths.addAll(List<String>.from(airport['aprons']));
      }
      if (airport['gates'] != null) {
        _availablePaths.addAll(List<String>.from(airport['gates']));
      }
    }
  }

  void _loadExistingPath() {
    if (widget.existingPath != null && widget.existingPath!.isNotEmpty) {
      _selectedPaths = widget.existingPath!.map((segment) {
        return SelectedPath(
          name: segment.name,
          type: segment.type,
          action: segment.action,
        );
      }).toList();
      
      _currentPath = _selectedPaths.last.name;
      _updateAvailablePaths();
    }
  }

  void _selectPath(String path, PathType type) {
    setState(() {
      _selectedPaths.add(SelectedPath(
        name: path,
        type: type,
        action: NavigationAction.continueAlong,
      ));
      _currentPath = path;
      _updateAvailablePaths();
    });
  }

  void _addHold() {
    if (_currentPath != null) {
      setState(() {
        _selectedPaths.add(SelectedPath(
          name: _currentPath!,
          type: _selectedPaths.last.type,
          action: NavigationAction.hold,
        ));
      });
    }
  }

  void _updateAvailablePaths() {
    if (_currentPath == null) return;

    final airport = widget.airportData[widget.airportCode];
    final intersections = airport['intersections'];

    if (intersections != null && intersections[_currentPath] != null) {
      setState(() {
        _availablePaths = Set<String>.from(
          (intersections[_currentPath] as Map<String, dynamic>).keys,
        );
        _showHoldOption = true;
      });
    } else {
      setState(() {
        _availablePaths = {};
        _showHoldOption = true;
      });
    }
  }

  void _removeLastPath() {
    if (_selectedPaths.isEmpty) return;

    setState(() {
      _selectedPaths.removeLast();
      if (_selectedPaths.isEmpty) {
        _currentPath = null;
        _initializeAvailablePaths();
        _showHoldOption = false;
      } else {
        _currentPath = _selectedPaths.last.name;
        _updateAvailablePaths();
      }
    });
  }

  void _confirmRoute() {
    if (_selectedPaths.isEmpty) return;

    final rawPath = _buildRawPath();
    Navigator.of(context).pop(rawPath);
  }

  List<RawPathSegment> _buildRawPath() {
    List<RawPathSegment> rawPath = [];
    final airport = widget.airportData[widget.airportCode];
    final segments = airport['segments'] as Map<String, dynamic>?;

    if (segments == null) return rawPath;

    for (final selected in _selectedPaths) {
      final segmentCoords = segments[selected.name] as List<dynamic>?;
      if (segmentCoords == null || segmentCoords.length < 2) continue;

      rawPath.add(RawPathSegment(
        name: selected.name,
        type: selected.type,
        action: selected.action,
        coordinates: [
          [segmentCoords[0][0].toDouble(), segmentCoords[0][1].toDouble()],
          [segmentCoords[1][0].toDouble(), segmentCoords[1][1].toDouble()],
        ],
      ));
    }

    return rawPath;
  }

  PathType _getPathType(String pathName) {
    if (pathName.contains('-') || pathName.contains(RegExp(r'^\d{2}[LCR]?$'))) {
      return PathType.runway;
    } else if (pathName.toLowerCase().contains('gate')) {
      return PathType.gate;
    } else if (pathName.toLowerCase().contains('apron')) {
      return PathType.apron;
    }
    return PathType.taxiway;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        height: 700,
        decoration: BoxDecoration(
          color: Colors.blueGrey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 3, child: _buildPathSelection()),
                  Container(width: 1, color: Colors.white24),
                  Expanded(flex: 2, child: _buildVisualization()),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[900],
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(Icons.route, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existingPath != null ? 'Edit Taxi Route' : 'Set Taxi Route',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.airportCode} - Select paths in sequence',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPathSelection() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            _selectedPaths.isEmpty
                ? 'Select your starting taxiway or runway'
                : 'Select next path or action',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16),
            children: [
              if (_availablePaths.isNotEmpty) ...[
                _buildSectionHeader('Available Paths'),
                ..._availablePaths.map((path) => _buildPathOption(path)),
                SizedBox(height: 16),
              ],
              if (_showHoldOption) ...[
                _buildSectionHeader('Actions'),
                _buildActionOption(
                  'Hold Short',
                  Icons.back_hand,
                  Colors.orange[700]!,
                  _addHold,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white60,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPathOption(String path) {
    final type = _getPathType(path);
    Color color;
    String typeLabel;

    switch (type) {
      case PathType.runway:
        color = Colors.red[700]!;
        typeLabel = 'RWY';
        break;
      case PathType.apron:
        color = Colors.green[700]!;
        typeLabel = 'APRON';
        break;
      case PathType.gate:
        color = Colors.blue[700]!;
        typeLabel = 'GATE';
        break;
      case PathType.taxiway:
      default:
        color = Colors.yellow[700]!;
        typeLabel = 'TWY';
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectPath(path, type),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey[700],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    path,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionOption(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey[700],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.add, color: Colors.white38, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualization() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Preview',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: _selectedPaths.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          size: 48,
                          color: Colors.white24,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No paths selected',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _selectedPaths.length,
                    itemBuilder: (context, index) {
                      return _buildSelectedPathItem(
                        _selectedPaths[index],
                        index,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPathItem(SelectedPath path, int index) {
    Color color;
    String typeLabel;

    if (path.action == NavigationAction.hold) {
      color = Colors.orange[400]!;
      typeLabel = 'HLD';
    } else {
      switch (path.type) {
        case PathType.runway:
          color = Colors.red[400]!;
          typeLabel = 'RWY';
          break;
        case PathType.apron:
          color = Colors.green[400]!;
          typeLabel = 'APRON';
          break;
        case PathType.gate:
          color = Colors.blue[400]!;
          typeLabel = 'GATE';
          break;
        case PathType.taxiway:
        default:
          color = Colors.yellow[400]!;
          typeLabel = 'TWY';
          break;
      }
    }

    final isLast = index == _selectedPaths.length - 1;
    final actionText = path.action == NavigationAction.hold
        ? 'Hold Short'
        : 'Continue';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: color.withOpacity(0.3),
              ),
          ],
        ),
        SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueGrey[700],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        path.action == NavigationAction.hold ? 'Hold Short' : path.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  actionText,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[900],
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        children: [
          if (_selectedPaths.isNotEmpty)
            TextButton.icon(
              onPressed: _removeLastPath,
              icon: Icon(Icons.undo, color: Colors.white70),
              label: Text(
                'Undo',
                style: TextStyle(color: Colors.white70),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.blueGrey[700],
              ),
            ),
          Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _selectedPaths.isEmpty ? null : _confirmRoute,
            icon: Icon(Icons.check),
            label: Text('Confirm Route'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.blueGrey[700],
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectedPath {
  final String name;
  final PathType type;
  final NavigationAction action;

  SelectedPath({
    required this.name,
    required this.type,
    required this.action,
  });
}

class RawPathSegment {
  final String name;
  final PathType type;
  final NavigationAction action;
  final List<List<double>> coordinates;

  RawPathSegment({
    required this.name,
    required this.type,
    required this.action,
    required this.coordinates,
  });
}