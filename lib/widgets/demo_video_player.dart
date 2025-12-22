import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

class DemoVideoPlayer extends StatelessWidget {
  final VideoController controller;
  final String title;

  const DemoVideoPlayer({
    super.key,
    required this.controller,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.black54,
          child: Text(title, style: const TextStyle(color: Colors.white)),
        ),
        Expanded(
          child: Video(
            controller: controller,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}
