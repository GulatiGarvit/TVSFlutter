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
  Future<void> shutdownServer() async {
    if (_serverProcess != null) {
      try {
        // Kill any Python process running server.py
        await Process.run('pkill', ['-9', '-f', 'server.py']);
        
        // Also kill by process group
        final pid = _serverProcess!.pid;
        await Process.run('bash', ['-c', 'kill -9 -$pid 2>/dev/null || true']);
        
        // Force kill the process handle
        _serverProcess!.kill(ProcessSignal.sigkill);
        
        // Small delay to ensure cleanup
        await Future.delayed(const Duration(milliseconds: 100));
        
        print('[SHUTDOWN] Server killed');
      } catch (e) {
        print('[SHUTDOWN] Error: $e');
      }
      _serverProcess = null;
    }
  }
}
