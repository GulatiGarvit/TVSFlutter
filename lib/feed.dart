import 'package:flutter/material.dart';

class Feed extends StatefulWidget {
  final String title;
  const Feed({super.key, required this.title});

  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        color: Colors.grey,
        child: Center(
          child: Text(
            widget.title,
            style: const TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
