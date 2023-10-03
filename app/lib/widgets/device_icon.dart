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
  final DayPeriod dayPeriod;
  final Color? color;
  const BinIcon({super.key, required this.dayPeriod, this.color});

  factory BinIcon.forBin({required int bin, Color? color}) {
    return BinIcon(
      dayPeriod: BinService.binDayPeriod(bin),
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    String dayPeriodString = dayPeriod == DayPeriod.am ? 'AM' : 'PM';
    String icon = "lib/assets/256w/DEV_SYM_$dayPeriodString.png";
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(icon,
            color: const Color(0xFF03012C), width: 24, height: 24),
        const SizedBox(
          width: 8,
        ),
        Text(
          dayPeriodString,
          style: Theme.of(context).textTheme.titleSmall,
        )
      ],
    );
  }
}
