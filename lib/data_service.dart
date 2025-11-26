import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';

class TelemetryData {
  final double heading;
  final double lat;
  final double lng;
  final double speed;
  final int sats;
  final String gpsStatus;

  TelemetryData({
    required this.heading,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.sats,
    required this.gpsStatus,
  });

  factory TelemetryData.fromJson(Map<dynamic, dynamic> json) {
    return TelemetryData(
      heading: (json['heading'] ?? 0).toDouble(),
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      speed: (json['speed'] ?? 0).toDouble(),
      sats: (json['sats'] ?? 0).toInt(),
      gpsStatus: json['gps_status'] ?? "Unknown",
    );
  }
}

class DataService {
  final String uri;
  late final WebSocketChannel _channel;

  // ---- Streams ----
  final StreamController<Uint8List> _cameraStreamController =
      StreamController.broadcast();
  final StreamController<Uint8List> _dehazedStreamController =
      StreamController.broadcast();
  final StreamController<TelemetryData> _telemetryStreamController =
      StreamController.broadcast();

  Stream<Uint8List> get cameraStream => _cameraStreamController.stream;
  Stream<Uint8List> get dehazedStream => _dehazedStreamController.stream;
  Stream<TelemetryData> get telemetryStream =>
      _telemetryStreamController.stream;

  DataService(this.uri);

  void connect() {
    print('[DataService] Connecting to $uri');
    _channel = WebSocketChannel.connect(Uri.parse(uri));

    _channel.stream.listen(
      (message) {
        try {
          final decoded = jsonDecode(message);

          if (decoded is! Map || decoded['type'] == null) return;
          final type = decoded['type'];

          // CAMERA FRAME
          if (type == 'camera') {
            final bytes = base64Decode(decoded['data']);
            _cameraStreamController.add(bytes);
          }
          // DEHAZED FRAME
          else if (type == 'dehazed') {
            final bytes = base64Decode(decoded['data']);
            _dehazedStreamController.add(bytes);
          }
          // TELEMETRY
          else if (type == 'telemetry') {
            final telemetry = TelemetryData.fromJson(decoded);
            _telemetryStreamController.add(telemetry);
          }
        } catch (e) {
          print('[DataService] Decode error: $e');
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
    _dehazedStreamController.close();
    _telemetryStreamController.close();
    _channel.sink.close();
  }
}
