import 'package:app/api/device.dart';
import 'package:app/api/schedule.dart';
import 'package:app/provider/schedule_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/screens/ScreenUtilWrapper.dart';
import 'package:app/widgets/add_device.dart';
import 'package:app/widgets/custom_time_picker.dart';
import 'package:app/widgets/remove_device_modal.dart';
import 'package:app/widgets/timezone_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

const double _sectionSpacing = 32.0;
const double _titleSubtitleSpacing = 8.0;
const double _subtitleContentSpacing = 16.0;

class ScheduleEntry extends StatefulWidget {
  final bool showRemovalSection;
  final bool showAddDeviceSection;
  final DeviceUser? device;
  final bool isOwner;

  const ScheduleEntry({
    super.key,
    this.showRemovalSection = true,
    this.showAddDeviceSection = true,
    this.device,
    this.isOwner = false,
  });

  @override
  State<StatefulWidget> createState() => _ScheduleEntryState();
}

void deleteDevice(context) {
  showDialog(
    context: context,
    builder: (_) => const RemoveDeviceDialog(),
  );
}

class _ScheduleEntryState extends State<ScheduleEntry> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetDevice = widget.device ??
          Provider.of<SelectedDeviceProvider>(context, listen: false).device;
      if (targetDevice != null) {
        Provider.of<ScheduleProvider>(context, listen: false)
            .load(targetDevice.deviceID);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final targetDevice = widget.device ??
        Provider.of<SelectedDeviceProvider>(context, listen: false).device;

    if (targetDevice == null) {
      return const SizedBox.shrink();
    }

    return Consumer<ScheduleProvider>(
      builder: (context, scheduleProvider, _) {
        final deviceSchedule =
            scheduleProvider.getScheduleForDevice(targetDevice.deviceID);
        final isLoadingSchedule = scheduleProvider.isLoading;
        final isUpdatingAMSchedule = scheduleProvider.isUpdatingAMSchedule;
        final isUpdatingPMSchedule = scheduleProvider.isUpdatingPMSchedule;

        return ScreenUtilWrapper(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimeSetupSection(
                  deviceSchedule,
                  targetDevice,
                  isLoadingSchedule,
                  isUpdatingAMSchedule,
                  isUpdatingPMSchedule),
              SizedBox(height: _sectionSpacing.h),
              _buildTimezoneSection(targetDevice),
              if (widget.showRemovalSection) ...[
                SizedBox(height: _sectionSpacing.h),
                const RemovalSection(),
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
    );
  }

  Widget _buildTimeSetupSection(
      SimpleSchedule? deviceSchedule,
      DeviceUser targetDevice,
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
                  child: _buildTimeBlock(DayPeriod.am, deviceSchedule?.am,
                      targetDevice, isUpdatingAMSchedule)),
              SizedBox(width: 20.w),
              Expanded(
                  child: _buildTimeBlock(DayPeriod.pm, deviceSchedule?.pm,
                      targetDevice, isUpdatingPMSchedule)),
            ],
          ),
      ],
    );
  }

  Widget _buildTimezoneSection(DeviceUser targetDevice) {
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
        TimeZoneSelection(device: targetDevice, isOwner: widget.isOwner),
      ],
    );
  }

  Widget _buildTimeBlock(DayPeriod dayPeriod, DispenseTime? entry,
      DeviceUser device, bool isUpdating) {
    return GestureDetector(
        onTap: () {
          if (!widget.isOwner) {
            return;
          }

          showDialog<TimeOfDay>(
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
          ).then((selectedTime) {
            if (selectedTime != null) {
              Provider.of<ScheduleProvider>(context, listen: false)
                  .updateTime(dayPeriod, selectedTime, device.deviceID);
            }
          });
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
                        padding:
                            AppLocalizations.of(context)!.localeName == 'fr'
                                ? EdgeInsets.fromLTRB(2.w, 16.h, 2.w, 16.h)
                                : EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 16.h),
                        child: Row(
                          mainAxisAlignment: widget.isOwner
                              ? MainAxisAlignment.spaceBetween
                              : MainAxisAlignment.center,
                          children: [
                            Text(
                              entry != null
                                  ? entry.time
                                      .format(context)
                                      .replaceAll(RegExp(r'[APap][Mm]$'), '')
                                  : AppLocalizations.of(context)!.setTime,
                              style: AppLocalizations.of(context)!.localeName ==
                                      'fr'
                                  ? Theme.of(context).textTheme.bodySmall
                                  : Theme.of(context).textTheme.labelSmall,
                            ),
                            if (widget.isOwner)
                              Row(children: [
                                SvgPicture.asset(
                                  'lib/assets/SVG/PencilSimpleLine.svg',
                                  width: 20.w,
                                  height: 20.h,
                                ),
                                SizedBox(width: 4.w),
                                if (entry != null)
                                  Text(AppLocalizations.of(context)!.edit,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          Theme.of(context).textTheme.bodySmall)
                              ])
                          ],
                        )),
              ],
            )));
  }
}

class RemovalSection extends StatelessWidget {
  const RemovalSection({super.key});

  @override
  Widget build(BuildContext context) {
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
        Consumer<SelectedDeviceProvider>(
          builder: (context, deviceProv, _) {
            return SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  deleteDevice(context);
                },
                style: ButtonStyle(
                  side: MaterialStateProperty.all<BorderSide>(
                    BorderSide(
                      color: Theme.of(context).colorScheme.error,
                      width: 1.0,
                    ),
                  ),
                  shape: MaterialStateProperty.all<OutlinedBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0).r,
                    ),
                  ),
                  padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                    EdgeInsets.symmetric(vertical: 16.h),
                  ),
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.pressed)) {
                        return Theme.of(context)
                            .colorScheme
                            .error
                            .withOpacity(0.2);
                      }
                      return Colors.transparent;
                    },
                  ),
                  overlayColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.pressed)) {
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
            );
          },
        ),
      ],
    );
  }
}
