import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'data_service.dart';

class VideoFeed extends StatelessWidget {
  final String title;
  final DataService dataService;

  const VideoFeed({super.key, required this.title, required this.dataService});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: StreamBuilder<Uint8List>(
        stream: dataService.cameraStream,
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
