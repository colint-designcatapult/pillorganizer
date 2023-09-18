import 'dart:math';

import 'package:flutter/material.dart';

import '../api/device.dart';
import '../service/bin_service.dart';

class DevicePeriodIcon extends StatelessWidget {
  const DevicePeriodIcon({super.key, required this.period, this.width});

  final DayPeriod period;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      period == DayPeriod.am
          ? "lib/assets/256w/DEV_SYM_AM.png"
          : "lib/assets/256w/DEV_SYM_PM.png",
      color: Theme.of(context).colorScheme.primary,
      width: this.width,
    );
  }
}

class DeviceStatusIcon extends StatelessWidget {
  final double size;
  final DeviceConnectionStatus status;
  const DeviceStatusIcon(
      {super.key,
      this.status = DeviceConnectionStatus.offline,
      this.size = 48.0});

  @override
  Widget build(BuildContext context) {
    final double orbSize = max(size / 3.5, 16.0);
    final Color outlineColor;
    final Color orbColor;

    switch (status) {
      case DeviceConnectionStatus.online:
        orbColor = Colors.green;
        outlineColor = orbColor;
        break;
      case DeviceConnectionStatus.loading:
        orbColor = Theme.of(context).colorScheme.primary;
        outlineColor = Theme.of(context).colorScheme.primary;
        break;
      default:
        orbColor = Theme.of(context).colorScheme.outline;
        outlineColor = orbColor;
        break;
    }

    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        children: [
          Positioned.fill(
              child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset("lib/assets/organizer_128.png"),
          )),
          Positioned.fill(
              child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.surface,
            value: 1,
            strokeWidth: 3.0,
          )),
          Positioned.fill(
              child: CircularProgressIndicator(
            color: outlineColor,
            value: status == DeviceConnectionStatus.loading ? null : 1.0,
            strokeWidth: 3.0,
          )),
          if (status != DeviceConnectionStatus.loading) ...[
            Positioned.fill(
                child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.only(right: (orbSize / 4.0)),
                child: Container(
                  height: orbSize,
                  width: orbSize,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: orbColor),
                ),
              ),
            ))
          ]
        ],
      ),
    );
  }
}

class BinIcon extends StatelessWidget {
  final String? text;
  final DayPeriod dayPeriod;
  final Color? color;
  final double size;
  const BinIcon(
      {super.key,
      this.text,
      required this.dayPeriod,
      this.color,
      this.size = 32.0});

  factory BinIcon.forBin({required int bin, Color? color, double size = 32.0}) {
    return BinIcon(
      text: BinService.binLabel(bin),
      dayPeriod: BinService.binDayPeriod(bin),
      size: size,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color? c = color ?? Theme.of(context).iconTheme.color;
    String icon =
        "lib/assets/256w/DEV_SYM_${dayPeriod == DayPeriod.am ? 'AM' : 'PM'}.png";
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(icon, color: c, width: size, height: size),
        if (text != null)
          Text(
            text!,
            style: TextStyle(
                color: c,
                fontSize: (3.0 * size) / 5,
                fontWeight: FontWeight.w700),
          )
      ],
    );
  }
}
