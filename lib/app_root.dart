import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tvs/dashboard.dart';
import 'package:tvs/data_service.dart';
import 'package:tvs/providers/navigation.dart';
import 'package:tvs/providers/settings.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

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
