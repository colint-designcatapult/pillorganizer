import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

class CountdownClock extends StatefulWidget {
  DateTime target;
  DateTime start;
  String? prompt;
  CountdownClock(
      {Key? key, required this.target, required this.start, this.prompt})
      : super(key: key);

  _CountdownClockState createState() => _CountdownClockState();
}

class _CountdownClockState extends State<CountdownClock> {
  late Timer _timer;
  int startSeconds = 0;
  int secondsToTarget = 0;

  @override
  Widget build(BuildContext context) {
    return SleekCircularSlider(
      appearance: CircularSliderAppearance(
          infoProperties: InfoProperties(
              topLabelText: widget.prompt,
              modifier: (v) {
                Duration d = Duration(seconds: v.toInt());
                String twoDigits(int n) => n.toString().padLeft(2, "0");
                String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
                String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
                return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
              })),
      min: 0,
      max: startSeconds.toDouble(),
      initialValue: secondsToTarget.toDouble(),
    );
  }

  void update(Timer timer) {
    setState(() {
      secondsToTarget = ((widget.target.millisecondsSinceEpoch -
                  DateTime.now().millisecondsSinceEpoch) /
              1000)
          .round();
    });
  }

  @override
  void initState() {
    super.initState();
    startSeconds = ((widget.target.millisecondsSinceEpoch -
                widget.start.millisecondsSinceEpoch) /
            1000)
        .round();
    _timer = Timer.periodic(const Duration(seconds: 1), update);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
