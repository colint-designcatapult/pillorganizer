import 'package:app/api/device.dart';
import 'package:app/provider/device_notice_provider.dart';
import 'package:app/provider/time_provider.dart';
import 'package:app/widgets/pillbox/bin_column.dart';
import 'package:flutter/material.dart';
import 'package:app/service/time_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class Pillbox extends StatelessWidget {
  static TimeService timeService = TimeService();
  const Pillbox({super.key});
  @override
  Widget build(BuildContext context) {
    final List<String> daysOfWeek =
        DayOfWeek.values.map((e) => e.displayName(context).toString()).toList();
    return Consumer3<DeviceStateProvider, MinuteBasedTimeProvider,
            DeviceNoticeProvider>(
        builder: (context, deviceProv, minuteProv, deviceNoticeProv, _) {
      final String currentDayOfWeek =
          DateFormat.EEEE().format(minuteProv!.value);
      final DeviceNotice notice = deviceNoticeProv!.value;
      final bool isDeviceActive =
          notice.name != 'empty' && notice.name != 'disconnected';

      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.32,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: daysOfWeek.asMap().entries.map((entry) {
            final nightIndex = entry.key * 2;
            final day = entry.value;
            final dayIndex = nightIndex + 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(day[0].toUpperCase(),
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: const Color(0xFF03012C))),
                ),
                BinColumn(
                    isDeviceLoading: deviceProv.value == null,
                    isDeviceActive: isDeviceActive,
                    isToday:
                        day.toUpperCase() == currentDayOfWeek.toUpperCase(),
                    dayStatus: deviceProv.value != null
                        ? deviceProv.value!.bins[dayIndex]
                        : BinStatus.DISABLED,
                    nightStatus: deviceProv.value != null
                        ? deviceProv.value!.bins[nightIndex]
                        : BinStatus.DISABLED),
              ],
            );
          }).toList(),
        ),
      );
    });
  }
}
