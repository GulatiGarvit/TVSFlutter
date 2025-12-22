import 'dart:io';

class ServerController {
  static final ServerController instance = ServerController._internal();
  ServerController._internal();

  Process? _serverProcess;

  /// Call this right after starting the server
  void attach(Process process) {
    _serverProcess = process;
  }

  /// Safe to call multiple times
  void shutdownServer() {
    if (_serverProcess != null) {
      try {
        _serverProcess!.kill(ProcessSignal.sigkill);
      } catch (_) {}
      _serverProcess = null;
    }
  }
}
