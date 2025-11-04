import 'package:flutter/material.dart';
import 'package:tvs/dashboard.dart';
import 'package:tvs/feed.dart';
import 'package:tvs/feed_section.dart';
import 'package:tvs/navigation_section.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Resizable Sidebar Demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardPage();
  }
}
