import 'package:app/apiv2/models/device.dart';
import 'package:app/provider/device_notice_provider.dart';
import 'package:app/provider/device_state_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/provider/time_provider.dart';
import 'package:app/service/time_service.dart';
import 'package:app/widgets/pillbox/bin_column.dart';
import 'package:app/widgets/shimmer_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class Pillbox extends ConsumerWidget {
  const Pillbox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceStateAsync = ref.watch(deviceStateProvider);
    final minuteBasedTime = ref.watch(minuteBasedTimeProvider);
    final deviceNotice = ref.watch(deviceNoticeProvider);

    final List<String> daysOfWeek =
    DayOfWeek.values.map((e) => e.displayName(context).toString()).toList();

    final String currentDayOfWeek = DateFormat('EEEE',
        AppLocalizations.of(context)!.localeName == 'fr' ? 'fr' : 'en')
        .format(minuteBasedTime);

    final bool isDeviceActive = deviceNotice != DeviceNotice.disconnected;

    return SizedBox(
        height: 250.h,
        child: ShimmerPlaceholder(
            loading: deviceStateAsync.isLoading,
            baseColor: const Color(0xFFBFD2DB),
            highlightColor: const Color(0xFFF1F6F5),
            direction: ShimmerDirection.ltr,
            builder: (BuildContext context, bool loading) {
              final deviceState = deviceStateAsync.value;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: daysOfWeek.asMap().entries.map((entry) {
                  final nightIndex = entry.key * 2;
                  final day = entry.value;
                  final dayIndex = nightIndex + 1;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6).h,
                        child: Text(day[0].toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: const Color(0xFF03012C))),
                      ),
                      BinColumn(
                        isDeviceLoading: deviceStateAsync.isLoading,
                        isDeviceActive: isDeviceActive,
                        isToday: day.toUpperCase() == currentDayOfWeek.toUpperCase(),
                        dayStatus: deviceState?.bins[dayIndex]?.binStatus ?? BinStatus.disabled,
                        nightStatus: deviceState?.bins[nightIndex]?.binStatus ?? BinStatus.disabled,
                        doors: deviceState?.doors,
                        dayBinIndex: dayIndex,
                        nightBinIndex: nightIndex,
                      ),
                    ],
                  );
                }).toList(),
              );
            }));
  }
}