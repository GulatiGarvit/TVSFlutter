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
    );
  }
}
