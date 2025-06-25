import 'dart:async';

import 'package:flutter/material.dart';

import '../api/device.dart';

class StateLed extends StatefulWidget {
  const StateLed({super.key, required this.binStatus, required this.ledWidth});

  final BinStatus? binStatus;
  final double ledWidth;

  @override
  State<StateLed> createState() => _StateLed();
}

class _StateLed extends State<StateLed> {
  Timer? blinkTimer;
  bool blinkState = true;
  late Image? imageGreen;
  late Image? imageRed;

  @override
  Widget build(BuildContext context) {
    Image? image;
    bool shouldBlink = false;
    BinStatus? status = widget.binStatus;
    if (status == BinStatus.TAKE_NOW) {
      image = imageGreen;
      shouldBlink = true;
    } else if (status == BinStatus.TAKEN) {
      image = imageGreen;
    } else if (status == BinStatus.MISSED) {
      image = imageRed;
    } else {
      image = null;
    }
    // todo: fix hardcoded sizes
    var ratio = widget.ledWidth / 356;
    var height = 103 * ratio;

    return image == null
        ? Container(width: widget.ledWidth, height: height)
        : Visibility(
            visible: !shouldBlink || blinkState,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: image);
  }

  void blink(Timer t) {
    setState(() {
      blinkState = !blinkState;
    });
  }

  @override
  void initState() {
    imageGreen = Image.asset("lib/assets/greenled.png", width: widget.ledWidth);
    imageRed = Image.asset("lib/assets/redled.png", width: widget.ledWidth);

    super.initState();
    blinkTimer = Timer.periodic(const Duration(milliseconds: 500), blink);
  }

  @override
  void dispose() {
    super.dispose();
    blinkTimer?.cancel();
  }
}

class MiniDevice extends StatefulWidget {
  const MiniDevice({Key? key, required this.status}) : super(key: key);

  final List<BinStatus> status;

  @override
  State<MiniDevice> createState() => _MiniDeviceState();
}

class _MiniDeviceState extends State<MiniDevice> {
  @override
  Widget build(BuildContext context) {
    var imgWidth = MediaQuery.of(context).size.width - 70;
    var ledWidth = imgWidth / 7;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Image.asset("lib/assets/organizer.png"),
        Positioned.fill(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) => 2 * index)
                    .map((e) => StateLed(
                        binStatus: widget.status.elementAtOrNull(e),
                        ledWidth: ledWidth))
                    .toList()),
            Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) => (2 * index) + 1)
                    .map((e) => StateLed(
                        binStatus: widget.status.elementAtOrNull(e),
                        ledWidth: ledWidth))
                    .toList())
          ],
        ))
      ],
    );
  }
}
