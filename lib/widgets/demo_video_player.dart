import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class DemoVideoPlayer extends StatelessWidget {
  final VideoPlayerController controller;
  final String title;

  const DemoVideoPlayer({
    super.key,
    required this.controller,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.black54,
          child: Text(title, style: const TextStyle(color: Colors.white)),
        ),
        Expanded(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
      ],
    );
  }
}
