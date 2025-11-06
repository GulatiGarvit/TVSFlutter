import 'package:flutter/material.dart';
import 'package:tvs/data_service.dart';

class NavigationSection extends StatefulWidget {
  final DataService dataService;
  const NavigationSection({super.key, required this.dataService});

  @override
  State<NavigationSection> createState() => _NavigationSectionState();
}

class _NavigationSectionState extends State<NavigationSection> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.blueGrey,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Taxi Navigation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Add navigation controls here
        ],
      ),
    );
  }
}
