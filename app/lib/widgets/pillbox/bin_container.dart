import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../api/device.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BinContainer extends StatelessWidget {
  final bool isToday;
  final String icon;
  final BinStatus status;
  final bool isDeviceActive;

  const BinContainer({
    super.key,
    required this.isToday,
    required this.icon,
    required this.status,
    required this.isDeviceActive,
  });

  @override
  Widget build(BuildContext context) {

    Color backgroundColor = isDeviceActive
        ? (isToday ? const Color(0xFF206B8B) : const Color(0xFFBFD2DB))
        : Colors.white;

    String iconName = isDeviceActive ? (isToday ? '${icon}White' : icon) : icon;

    String binStatusIconPath = getBinStatusIcon(status, isDeviceActive);

    return Container(
      // 108 is the padding on each side of the pillbox and the padding between the column
      width: ((MediaQuery.of(context).size.width - 108.w) / 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0).r,
        border: isDeviceActive
            ? null
            : Border.all(
                color: const Color(0xFF206B8B),
                width: 1.5.w,
              ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 14.h),
            child: SvgPicture.asset(
              'lib/assets/SVG/$iconName.svg',
              height: 20.h,
            ),
          ),
          const Spacer(), // This will push the bottom icon to the bottom
          Padding(
            padding: EdgeInsets.only(bottom: 5.h),
            child: SvgPicture.asset(
              binStatusIconPath,
              height: 30.h,
            ),
          ),
        ],
      ),
    );
  }

  String getBinStatusIcon(BinStatus status, bool isActive) {
    if (isActive) {
      switch (status) {
        case BinStatus.MISSED:
          return 'lib/assets/SVG/redlight.svg';
        case BinStatus.TAKEN:
        case BinStatus.TAKE_NOW:
          return 'lib/assets/SVG/greenlight.svg';
        case BinStatus.DISABLED:
        case BinStatus.PENDING:
          return 'lib/assets/SVG/offlight.svg';
        default:
          return 'lib/assets/SVG/redlight.svg';
      }
    } else {
      return 'lib/assets/SVG/cancelIcon.svg';
    }
  }
}
