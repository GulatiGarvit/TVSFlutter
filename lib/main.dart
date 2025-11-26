import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tvs/dashboard.dart';
import 'package:tvs/data_service.dart';
import 'package:tvs/providers/navigation.dart';
import 'package:tvs/providers/settings.dart';
import 'package:tvs/video_feed.dart';
import 'package:tvs/feed_section.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:tvs/navigation_section.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FullScreen.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'TVS Dashboard',
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = DataService("ws://127.0.0.1:8765");
    dataService.connect();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider(dataService)),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const DashboardPage(),
    );
  }
}
