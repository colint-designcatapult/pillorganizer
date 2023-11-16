import 'package:app/api/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CircularBinStatusIndicator extends StatelessWidget {
  final BinStatus status;
  final DeviceNotice deviceStatus;
  const CircularBinStatusIndicator(
      {super.key, required this.status, required this.deviceStatus});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color border;

    switch (status) {
      case BinStatus.TAKEN:
      case BinStatus.TAKE_NOW:
        color = const Color(0xFF7CAC7B);
        border = const Color(0xFF4D7B50);
        break;
      case BinStatus.MISSED:
        color = const Color(0xFFD45C5C);
        border = const Color(0xFF7A2C2C);
        break;
      default:
        color = const Color(0xFF798290);
        border = const Color(0xFF434747);
    }

    return Container(
      height: 20,
      width: 20,
      decoration:
          status != BinStatus.DISABLED && deviceStatus != DeviceNotice.empty
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(color: border, width: 3),
                )
              : null,
      child: Visibility(
          visible: status == BinStatus.DISABLED ||
              deviceStatus == DeviceNotice.empty,
          child: SvgPicture.asset(
            'lib/assets/SVG/cancelIcon.svg',
            height: 20,
            width: 20,
          )),
    );
  }
}
