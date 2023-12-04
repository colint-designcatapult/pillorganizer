import 'package:app/api/schedule.dart';
import 'package:app/provider/schedule_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/screens/ScreenUtilWrapper.dart';
import 'package:app/screens/modals/time_zone_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../service/time_service.dart';
import 'package:timezone/standalone.dart' as tz;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ScheduleEntry extends StatefulWidget {
  const ScheduleEntry({super.key});

  @override
  State<StatefulWidget> createState() => _ScheduleEntyState();
}

class _ScheduleEntyState extends State<ScheduleEntry> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, schedProv, _) {
        return ScreenUtilWrapper(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Text(AppLocalizations.of(context)!.timeSetup,
                      style: Theme.of(context).textTheme.titleSmall)),
              Padding(
                  padding: EdgeInsets.only(bottom: 22.h),
                  child: Text(AppLocalizations.of(context)!.timeSetupSubtitle,
                      style: Theme.of(context).textTheme.bodySmall)),
              Row(
                children: [
                  Expanded(
                    child:
                        _buildTimeBlock(DayPeriod.am, schedProv.schedule?.am),
                  ),
                  SizedBox(
                    width: 20.w,
                  ),
                  Expanded(
                    child:
                        _buildTimeBlock(DayPeriod.pm, schedProv.schedule?.pm),
                  ),
                ],
              ),
              Padding(
                  padding: EdgeInsets.only(bottom: 8.h, top: 36.h),
                  child: Text(AppLocalizations.of(context)!.timezone,
                      style: Theme.of(context).textTheme.titleSmall)),
              Text(AppLocalizations.of(context)!.timezoneSubtitle,
                  style: Theme.of(context).textTheme.bodySmall),
              SizedBox(
                height: 8.h,
              ),
              TimeZoneSelectionWidget(),
              SizedBox(
                height: 80.h,
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeBlock(DayPeriod dayPeriod, DispenseTime? entry) {
    return GestureDetector(
        onTap: () {
          showTimePicker(
            initialTime: entry?.time ?? TimeOfDay.now(),
            context: context,
            initialEntryMode: TimePickerEntryMode.input,
          ).then((value) {
            if (value != null) {
              Provider.of<ScheduleProvider>(context, listen: false)
                  .updateTime(dayPeriod, value);
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<SelectedDeviceProvider>(context, listen: false);
    return Column(children: [
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
                value: 0,
                label: Text(
                  AppLocalizations.of(context)!.manual,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ButtonSegment(
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
                  prov.updateTimeZone(phoneLocation);
                }
              });
            },
            style: ButtonStyle(
              shape: MaterialStateProperty.all<OutlinedBorder>(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadiusDirectional.circular(8.r))),
              side: MaterialStateProperty.resolveWith<BorderSide>(
                  (Set<MaterialState> states) {
                return const BorderSide(color: Color(0xFFBFD2DB), width: 2.0);
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
          ))
        ],
      ),
      if (selectedButtonIndex == 0)
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 16.h),
          Text(AppLocalizations.of(context)!.selectManualTimezone,
              style: Theme.of(context).textTheme.bodySmall),
          ListTile(
            title: Text(
                _buildTimeZoneName(
                    Provider.of<SelectedDeviceProvider>(context, listen: false)
                        .device
                        ?.timezone),
                style: Theme.of(context).textTheme.displaySmall),
            leading: SvgPicture.asset(
              'lib/assets/SVG/Globe.svg',
              width: 24.w,
              height: 24.h,
            ),
            trailing: const Icon(Icons.arrow_right),
            onTap: () {
              Navigator.of(context)
                  .push(TimeZoneSelectionModal.route(context))
                  .then((value) {
                if (value != null) {
                  prov.updateTimeZone(value);
                }
              });
            },
          )
        ]),
      if (selectedButtonIndex == 1)
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.timezoneChangeReminder,
              style: Theme.of(context).textTheme.bodySmall),
        ]),
    ]);
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
