import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';

class DataService {
  final String uri;
  late final WebSocketChannel _channel;
  final StreamController<Uint8List> _cameraStreamController =
      StreamController.broadcast();

  Stream<Uint8List> get cameraStream => _cameraStreamController.stream;

  DataService(this.uri);

  void connect() {
    print('[DataService] Connecting to $uri');
    _channel = WebSocketChannel.connect(Uri.parse(uri));

    _channel.stream.listen(
      (message) {
        try {
          final decoded = jsonDecode(message);
          if (decoded is Map && decoded['type'] == 'camera') {
            final base64Data = decoded['data'] as String;
            final bytes = base64Decode(base64Data);
            _cameraStreamController.add(bytes);
          }
        } catch (e) {
          print('[DataService] Error decoding: $e');
        }
      },
      onDone: () {
        print('[DataService] Connection closed');
      },
      onError: (err) {
        print('[DataService] WebSocket error: $err');
      },
    );
  }

  void dispose() {
    _cameraStreamController.close();
    _channel.sink.close();
  }
}
