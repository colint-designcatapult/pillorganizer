import 'package:app/api/device.dart';
import 'package:app/api/schedule.dart';
import 'package:app/provider/device_provider.dart';
import 'package:app/provider/schedule_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/screens/ScreenUtilWrapper.dart';
import 'package:app/screens/modals/time_zone_selection.dart';
import 'package:app/widgets/add_device.dart';
import 'package:app/widgets/remove_device_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:timezone/standalone.dart' as tz;

import '../service/time_service.dart';

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

        return ScreenUtilWrapper(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimeSetupSection(deviceSchedule, targetDevice),
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
      SimpleSchedule? deviceSchedule, DeviceUser targetDevice) {
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
        Row(
          children: [
            Expanded(
              child: _buildTimeBlock(
                  DayPeriod.am, deviceSchedule?.am, targetDevice),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: _buildTimeBlock(
                  DayPeriod.pm, deviceSchedule?.pm, targetDevice),
            ),
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
        TimeZoneSelectionWidget(device: targetDevice, isOwner: widget.isOwner),
      ],
    );
  }

  Widget _buildTimeBlock(
      DayPeriod dayPeriod, DispenseTime? entry, DeviceUser device) {
    return GestureDetector(
        onTap: () {
          if (!widget.isOwner) {
            return;
          }

          showTimePicker(
            initialTime: entry?.time ?? TimeOfDay.now(),
            context: context,
            initialEntryMode: TimePickerEntryMode.input,
          ).then((value) {
            if (value != null) {
              Provider.of<ScheduleProvider>(context, listen: false)
                  .updateTime(dayPeriod, value, device.deviceID);
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
                Padding(
                    padding: AppLocalizations.of(context)!.localeName == 'fr'
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
                          style:
                              AppLocalizations.of(context)!.localeName == 'fr'
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
                                  style: Theme.of(context).textTheme.bodySmall)
                          ])
                      ],
                    )),
              ],
            )));
  }
}

class TimeZoneSelectionWidget extends StatefulWidget {
  final DeviceUser device;
  final bool isOwner;

  const TimeZoneSelectionWidget(
      {super.key, required this.device, required this.isOwner});

  @override
  _TimeZoneSelectionWidgetState createState() =>
      _TimeZoneSelectionWidgetState();
}

class _TimeZoneSelectionWidgetState extends State<TimeZoneSelectionWidget> {
  int selectedButtonIndex = 0;
  late tz.Location phoneLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentPhoneLocation();
  }

  Future<void> _getCurrentPhoneLocation() async {
    final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    final tz.Location location = tz.getLocation(timeZoneName);

    setState(() {
      phoneLocation = location;
    });
  }

  Future<void> _updateDeviceTimezone(tz.Location location) async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    await deviceProvider.updateDeviceTimeZone(widget.device.deviceID, location);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(builder: (context, deviceProvider, _) {
      DeviceUser? currentDevice;
      if (deviceProvider.devices.isNotEmpty) {
        currentDevice = deviceProvider.devices.firstWhere(
          (device) => device.deviceID == widget.device.deviceID,
          orElse: () => widget.device,
        );
      } else {
        currentDevice = widget.device;
      }

      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton(
                  selectedIcon: Icon(
                    Icons.check_sharp,
                    size: 20.h,
                  ),
                  segments: <ButtonSegment>[
                    ButtonSegment(
                      enabled: widget.isOwner,
                      value: 0,
                      label: Text(
                        AppLocalizations.of(context)!.manual,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    ButtonSegment(
                      enabled: widget.isOwner,
                      value: 1,
                      label: Text(
                        AppLocalizations.of(context)!.automatic,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                  selected: {selectedButtonIndex},
                  onSelectionChanged: (Set newSelection) {
                    setState(() {
                      selectedButtonIndex = newSelection.first;
                      if (selectedButtonIndex == 1) {
                        _updateDeviceTimezone(phoneLocation);
                      }
                    });
                  },
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<OutlinedBorder>(
                        RoundedRectangleBorder(
                            borderRadius:
                                BorderRadiusDirectional.circular(8.r))),
                    side: MaterialStateProperty.resolveWith<BorderSide>(
                        (Set<MaterialState> states) {
                      return const BorderSide(
                          color: Color(0xFFBFD2DB), width: 2.0);
                    }),
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return const Color(0xFFE8EFF4);
                      }
                      return Colors.white;
                    }),
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      EdgeInsets.symmetric(vertical: 16.h),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: selectedButtonIndex == 0
                ? _buildManualTimezoneSection(currentDevice, widget.isOwner)
                : _buildAutomaticTimezoneSection(),
          ),
        ],
      );
    });
  }

  Widget _buildManualTimezoneSection(DeviceUser currentDevice, bool isOwner) {
    return Column(
      key: const ValueKey('manual'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.selectManualTimezone,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFBFD2DB),
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(8.0).r,
          ),
          child: ListTile(
            title: Text(
              _buildTimeZoneName(currentDevice.timezone),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            leading: SvgPicture.asset(
              'lib/assets/SVG/Globe.svg',
              width: 24.w,
              height: 24.h,
            ),
            trailing: isOwner ? Icon(Icons.arrow_drop_down, size: 24.h) : null,
            onTap: () {
              if (!isOwner) {
                return;
              }

              Navigator.of(context)
                  .push(TimeZoneSelectionModal.route(context))
                  .then((value) {
                if (value != null) {
                  _updateDeviceTimezone(value);
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAutomaticTimezoneSection() {
    return Column(
      key: const ValueKey('automatic'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.timezoneChangeReminder,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _buildTimeZoneName(TimeZoneLocation? loc) {
    if (loc == null) {
      return "UTC/GMT";
    } else {
      final idx = loc.name.indexOf('/') + 1;
      return "${loc.name.substring(idx, loc.name.length).replaceAll("_", " ")} (${loc.currentTimeZone.abbreviation})";
    }
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
