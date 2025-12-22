import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tvs/dashboard.dart';
import 'package:tvs/data_service.dart';
import 'package:tvs/providers/navigation.dart';
import 'package:tvs/providers/settings.dart';
import 'package:tvs/startup_screen.dart';
import 'package:tvs/video_feed.dart';
import 'package:tvs/feed_section.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:tvs/navigation_section.dart';
import 'package:media_kit/media_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FullScreen.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartupScreen(),
    );
  }
}
