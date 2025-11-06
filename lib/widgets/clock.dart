import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClockWidget extends StatelessWidget {
  final TextStyle? textStyle;
  const ClockWidget({super.key, this.textStyle});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        return Text(
          DateFormat('EEE, dd MMM yyyy – HH:mm:ss').format(DateTime.now()),
          style: textStyle,
        );
      },
    );
  }
}
