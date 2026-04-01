import 'package:flutter/material.dart';
import 'package:app/apiv2/models/device.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'bin_container.dart';

class BinColumn extends StatelessWidget {
  final bool isToday;
  final BinStatus dayStatus;
  final BinStatus nightStatus;
  final bool isDeviceActive;
  final bool isDeviceLoading;
  final int? doors;
  final int dayBinIndex;
  final int nightBinIndex;

  const BinColumn(
      {Key? key,
      required this.isToday,
      required this.dayStatus,
      required this.nightStatus,
      required this.isDeviceActive,
      required this.isDeviceLoading,
      this.doors,
      required this.dayBinIndex,
      required this.nightBinIndex})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color borderColor = isToday ? const Color(0xFF043C4D) : Colors.transparent;
    return Expanded(
        child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
            decoration: BoxDecoration(
              border:
                  isToday ? Border.all(color: borderColor, width: 2.w) : null,
              borderRadius: isToday ? BorderRadius.circular(10.0).r : null,
            ),
            child: Column(
              children: [
                Expanded(
                  child: BinContainer(
                    isToday: isToday,
                    icon: 'moon',
                    status: nightStatus,
                    isDeviceActive: isDeviceActive,
                    isOpen: _isBinOpen(nightBinIndex),
                  ),
                ),
                SizedBox(height: 10.0.h),
                Expanded(
                  child: BinContainer(
                    isToday: isToday,
                    icon: 'sun',
                    status: dayStatus,
                    isDeviceActive: isDeviceActive,
                    isOpen: _isBinOpen(dayBinIndex),
                  ),
                ),
              ],
            )));
  }

  /// Check if a specific bin is physically open based on the doors bitfield
  bool _isBinOpen(int binIndex) {
    if (doors == null) return false;
    return (doors! & (1 << binIndex)) != 0;
  }
}
