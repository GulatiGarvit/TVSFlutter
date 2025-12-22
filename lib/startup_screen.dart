import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tvs/app_root.dart';
import 'package:tvs/dialogs/settings_dialog.dart';
import 'package:tvs/utils/server_controller.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  final List<String> _logs = [];
  Process? _serverProcess;
  bool _ready = false;
  bool _fatal = false;

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  Future<void> _startServer() async {
    try {
      _serverProcess = await Process.start(
        'python3',
        ['server.py'],
        workingDirectory: '/home/nvidia/TVS',
        runInShell: false,
      );

      ServerController.instance.attach(_serverProcess!);

      _serverProcess!.stdout
          .transform(SystemEncoding().decoder)
          .listen(_handleLog);

      _serverProcess!.stderr
          .transform(SystemEncoding().decoder)
          .listen(_handleLog);

      _serverProcess!.exitCode.then((code) {
        if (!_ready) {
          setState(() {
            _fatal = true;
            _logs.add('[FATAL] Server exited with code $code');
          });

          Future.delayed(const Duration(seconds: 2), () {
            shutdownTVS();
          });
        }
      });
    } catch (e) {
      setState(() {
        _fatal = true;
        _logs.add('[FATAL] Failed to start server: $e');
      });

      Future.delayed(const Duration(seconds: 2), () {
        shutdownTVS();
      });
    }
  }

  void _handleLog(String line) {
    setState(() {
      _logs.add(line.trimRight());
    });

    if (line.contains('[READY]')) {
      setState(() => _ready = true);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const AppRoot(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _serverProcess?.kill(ProcessSignal.sigterm);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Starting TVS Server...',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (_, i) => Text(
                  _logs[i],
                  style: TextStyle(
                    color: _logs[i].contains('[FATAL]')
                        ? Colors.redAccent
                        : Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            if (_fatal)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Startup failed. Please restart the app.',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
