import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  const DeviceStatusIcon({
    super.key,
    this.status = DeviceConnectionStatus.offline,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    // Improved orbSize calculation for better responsiveness
    final double orbSize = size / 4;
    final Color orbColor;
    final Color outlineColor;

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
                padding: const EdgeInsets.all(4).h,
                child: Image.asset('lib/assets/organizer_128.png')),
          ),

          Positioned.fill(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.surface,
              value: 1,
              strokeWidth: size / 16,
            ),
          ),
          Positioned.fill(
            child: CircularProgressIndicator(
              color: outlineColor,
              value: status == DeviceConnectionStatus.loading ? null : 1.0,
              strokeWidth: size / 16, // Dynamic stroke width
            ),
          ),
          // Orb
          if (status != DeviceConnectionStatus.loading)
            Positioned(
              right: orbSize / 2, // Dynamic positioning
              bottom: orbSize / 2, // Dynamic positioning
              child: Container(
                height: orbSize,
                width: orbSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: orbColor,
                ),
              ),
            ),
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
            color: const Color(0xFF03012C), width: 24.w, height: 24.h),
        SizedBox(
          width: 8.w,
        ),
        Text(
          dayPeriodString,
          style: Theme.of(context).textTheme.titleSmall,
        )
      ],
    );
  }
}
