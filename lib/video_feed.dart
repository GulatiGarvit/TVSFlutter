import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'data_service.dart';

enum StreamType { camera, dehazed }

class VideoFeed extends StatelessWidget {
  final String title;
  final DataService dataService;
  final StreamType streamType;

  const VideoFeed({
    super.key,
    required this.title,
    required this.dataService,
    required this.streamType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: StreamBuilder<Uint8List>(
        stream:
            streamType == StreamType.camera
                ? dataService.cameraStream
                : dataService.dehazedStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Text(
              "Waiting for $title...",
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            );
          }

          return Image.memory(
            snapshot.data!,
            gaplessPlayback: true,
            filterQuality: FilterQuality.low,
            fit: BoxFit.contain,
          );
        },
      ),
    );
  }
}
