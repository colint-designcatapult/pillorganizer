import 'package:app/apiv2/models/device.dart';
import 'package:app/apiv2/models/schedule.dart';
import 'package:app/provider/device_connection_status_provider.dart';
import 'package:app/provider/schedule_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/screens/ScreenUtilWrapper.dart';
import 'package:app/widgets/add_device.dart';
import 'package:app/widgets/custom_time_picker.dart';
import 'package:app/widgets/remove_device_modal.dart';
import 'package:app/widgets/timezone_selection.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'device_alert_popup.dart';

const double _sectionSpacing = 32.0;
const double _titleSubtitleSpacing = 8.0;
const double _subtitleContentSpacing = 16.0;

class ScheduleEntry extends ConsumerStatefulWidget {
  final bool showRemovalSection;
  final bool showAddDeviceSection;
  final DeviceMetadata? device;
  final bool ignoreOffline;

  const ScheduleEntry({
    super.key,
    this.showRemovalSection = true,
    this.showAddDeviceSection = true,
    this.device,
    this.ignoreOffline = false
  });

  @override
  ConsumerState<ScheduleEntry> createState() => _ScheduleEntryState();
}

void deleteDevice(BuildContext context, DeviceMetadata? device) {
  showDialog(
    context: context,
    builder: (_) => RemoveDeviceDialog(device: device),
  );
}

class _ScheduleEntryState extends ConsumerState<ScheduleEntry> {
  bool _isUpdatingAM = false;
  bool _isUpdatingPM = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetDevice = widget.device ?? ref.read(activeDeviceProvider);
      if (targetDevice != null) {
        ref.read(scheduleProvider.notifier).load(targetDevice.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final targetDevice = widget.device ?? ref.watch(activeDeviceProvider);
    final connectionStatus = ref.watch(deviceConnectionStatusProvider);

    if (targetDevice == null) {
      return const SizedBox.shrink();
    }

    final scheduleAsync = ref.watch(scheduleProvider);
    return scheduleAsync.when(
      data: (scheduleState) {
        final effective = scheduleState.effectiveSchedule;
        final simpleSchedule = effective is SimpleSchedule ? effective : null;

        return ScreenUtilWrapper(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.ignoreOffline || connectionStatus == DeviceConnectionStatus.online) ...[
                _buildTimeSetupSection(
                    simpleSchedule,
                    targetDevice,
                    false,
                    _isUpdatingAM,
                    _isUpdatingPM),
                if (targetDevice.primaryUser) ...[
                  SizedBox(height: _sectionSpacing.h),
                  _buildTimezoneSection(targetDevice),
                ],
              ] else ...[
                Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    elevation: 0, // Matched with headers inset dialog elevation
                    child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: const Color(0xFFBFD2DB), width: 1.w),
                        ),
                        child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Device offline",
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                SizedBox(height: _titleSubtitleSpacing.h),
                                Text(
                                  "Schedule and timezone changes can only be made while your device is connected.",
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            )
                        )
                    )
                )
              ],
              if (widget.showRemovalSection) ...[
                SizedBox(height: _sectionSpacing.h),
                RemovalSection(device: targetDevice),
              ],
              if (widget.showAddDeviceSection) ...[
                SizedBox(height: _sectionSpacing.h),
                const AddDevice(titleSize: 30.0),
              ],
              SizedBox(height: 8.h),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text(e.toString())),
    );
  }

  Widget _buildTimeSetupSection(
      SimpleSchedule? deviceSchedule,
      DeviceMetadata targetDevice,
      bool isLoadingSchedule,
      bool isUpdatingAMSchedule,
      bool isUpdatingPMSchedule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.timeSetup,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        SizedBox(height: _titleSubtitleSpacing.h),
        Text(
          AppLocalizations.of(context)!.timeSetupSubtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SizedBox(height: _subtitleContentSpacing.h),
        if (isLoadingSchedule)
          const Center(child: CircularProgressIndicator())
        else
          Row(
            children: [
              Expanded(
                  flex: 1,
                  child: _buildTimeBlock(DayPeriod.am, deviceSchedule?.amPeriod,
                      targetDevice, isUpdatingAMSchedule)),
              SizedBox(width: 12.w),
              Expanded(
                  flex: 1,
                  child: _buildTimeBlock(DayPeriod.pm, deviceSchedule?.pmPeriod,
                      targetDevice, isUpdatingPMSchedule)),
            ],
          ),
      ],
    );
  }

  Widget _buildTimezoneSection(DeviceMetadata targetDevice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.timezone,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        SizedBox(height: _titleSubtitleSpacing.h),
        Text(
          AppLocalizations.of(context)!.timezoneSubtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SizedBox(height: _subtitleContentSpacing.h),
        TimeZoneSelection(device: targetDevice, isOwner: targetDevice.primaryUser),
      ],
    );
  }

  Widget _buildTimeBlock(DayPeriod dayPeriod, DosePeriodV2? entry,
      DeviceMetadata device, bool isUpdating) {
    return GestureDetector(
        onTap: () async {
          if (!device.primaryUser) {
            return;
          }

          final selectedTime = await showDialog<TimeOfDay>(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: CustomTimePicker(
                  initialTime: entry?.time ?? TimeOfDay.now(),
                  isAM: dayPeriod == DayPeriod.am,
                ),
              );
            },
          );

          if (selectedTime != null && mounted) {
            setState(() {
              if (dayPeriod == DayPeriod.am) {
                _isUpdatingAM = true;
              } else {
                _isUpdatingPM = true;
              }
            });
            try {
              await ref.read(scheduleProvider.notifier)
                  .updateTime(dayPeriod, selectedTime, device.id);
            } finally {
              if (mounted) {
                setState(() {
                  if (dayPeriod == DayPeriod.am) {
                    _isUpdatingAM = false;
                  } else {
                    _isUpdatingPM = false;
                  }
                });
              }
            }
          }
        },
        child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFE8EFF4),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(8.0).r,
            ),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFE8EFF4),
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(dayPeriod == DayPeriod.am ? "AM" : "PM",
                          style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(
                        width: 12.w,
                      ),
                      SvgPicture.asset(
                        dayPeriod == DayPeriod.am
                            ? 'lib/assets/SVG/DEV_SYM_AM.svg'
                            : 'lib/assets/SVG/DEV_SYM_PM.svg',
                        width: 24.w,
                        height: 24.h,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                isUpdating
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              entry != null
                                  ? entry.time
                                      .format(context)
                                      .replaceAll(RegExp(r'[APap][Mm]$'), '')
                                  : AppLocalizations.of(context)!.setTime,
                              textAlign: TextAlign.center,
                              style: AppLocalizations.of(context)!.localeName ==
                                      'fr'
                                  ? Theme.of(context).textTheme.bodySmall
                                  : Theme.of(context).textTheme.labelSmall,
                            ),
                            if (device.primaryUser && entry != null) ...[
                              SizedBox(height: 8.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'lib/assets/SVG/PencilSimpleLine.svg',
                                    width: 16.w,
                                    height: 16.h,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(AppLocalizations.of(context)!.edit,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall)
                                ],
                              )
                            ]
                          ],
                        )),
              ],
            )));
  }
}

class RemovalSection extends ConsumerWidget {
  final DeviceMetadata? device;
  const RemovalSection({super.key, this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.removal,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        SizedBox(
          height: 16.h,
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              deleteDevice(context, device);
            },
            style: ButtonStyle(
              side: WidgetStateProperty.all<BorderSide>(
                BorderSide(
                  color: Theme.of(context).colorScheme.error,
                  width: 1.0,
                ),
              ),
              shape: WidgetStateProperty.all<OutlinedBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0).r,
                ),
              ),
              padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                EdgeInsets.symmetric(vertical: 16.h),
              ),
              backgroundColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.pressed)) {
                    return Theme.of(context)
                        .colorScheme
                        .error
                        .withOpacity(0.2);
                  }
                  return Colors.transparent;
                },
              ),
              overlayColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.pressed)) {
                    return Theme.of(context)
                        .colorScheme
                        .error
                        .withOpacity(0.2);
                  }
                  return Colors.transparent;
                },
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.removeDevice,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
