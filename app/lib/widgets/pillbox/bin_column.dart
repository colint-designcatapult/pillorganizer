import 'package:app/widgets/shimmer_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:app/api/device.dart';
import 'package:shimmer/shimmer.dart';

import 'bin_container.dart';

class BinColumn extends StatelessWidget {
  final bool isToday;
  final BinStatus dayStatus;
  final BinStatus nightStatus;
  final bool isDeviceActive;
  final bool isDeviceLoading;

  const BinColumn(
      {Key? key,
      required this.isToday,
      required this.dayStatus,
      required this.nightStatus,
      required this.isDeviceActive,
      required this.isDeviceLoading})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color borderColor = isToday ? const Color(0xFF043C4D) : Colors.transparent;
    return Expanded(
        child: ShimmerPlaceholder(
            loading: isDeviceLoading,
            baseColor: const Color(0xFFBFD2DB),
            highlightColor: const Color(0xFFF1F6F5),
            direction: ShimmerDirection.ttb,
            builder: (BuildContext context, bool loading) {
              return Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  border: isToday
                      ? Border.all(color: borderColor, width: 2.0)
                      : null,
                  borderRadius: isToday ? BorderRadius.circular(10.0) : null,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: BinContainer(
                        isToday: isToday,
                        icon: 'moon',
                        status: nightStatus,
                        isDeviceActive: isDeviceActive,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Expanded(
                      child: BinContainer(
                        isToday: isToday,
                        icon: 'sun',
                        status: dayStatus,
                        isDeviceActive: isDeviceActive,
                      ),
                    ),
                  ],
                ),
              );
            }));
  }
}
