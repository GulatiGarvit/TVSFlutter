import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'data_service.dart';

enum StreamType { camera, dehazed }

class VideoFeed extends StatefulWidget {
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
  State<VideoFeed> createState() => _VideoFeedState();
}

class _VideoFeedState extends State<VideoFeed> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ui.Image?>(
      stream: widget.streamType == StreamType.camera
          ? widget.dataService.cameraFrameStream
          : widget.dataService.dehazedFrameStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Text(
                'Waiting for ${widget.title}...',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover, // CHANGED FROM BoxFit.contain TO BoxFit.cover
            child: SizedBox(
              width: snapshot.data!.width.toDouble(),
              height: snapshot.data!.height.toDouble(),
              child: CustomPaint(
                painter: ImagePainter(snapshot.data!),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;
  ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}