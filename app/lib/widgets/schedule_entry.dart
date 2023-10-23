import 'package:app/api/schedule.dart';
import 'package:app/provider/schedule_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/screens/modals/time_zone_selection.dart';
import 'package:app/widgets/shimmer_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../service/time_service.dart';
import 'package:timezone/standalone.dart' as tz;

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
        return Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Time Setup:',
                    style: Theme.of(context).textTheme.titleSmall)),
            Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Text(
                    'Select the time when you\'d like to be reminded to take your pills.',
                    style: Theme.of(context).textTheme.bodySmall)),
            Row(
              children: [
                Expanded(
                  child: _buildTimeBlock(DayPeriod.am, schedProv.schedule?.am),
                ),
                const SizedBox(
                  width: 20,
                ),
                Expanded(
                  child: _buildTimeBlock(DayPeriod.pm, schedProv.schedule?.pm),
                ),
              ],
            ),
            Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 36),
                child: Text('Timezone:',
                    style: Theme.of(context).textTheme.titleSmall)),
            Text('Select the time zone your pill organizer should use.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(
              height: 8,
            ),
            TimeZoneSelectionWidget(),
            const SizedBox(
              height: 80,
            )
          ],
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
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFE8EFF4),
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(dayPeriod == DayPeriod.am ? "AM" : "PM",
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(
                        width: 12,
                      ),
                      SvgPicture.asset(
                        dayPeriod == DayPeriod.am
                            ? 'lib/assets/SVG/DEV_SYM_AM.svg'
                            : 'lib/assets/SVG/DEV_SYM_PM.svg',
                        width: 24,
                        height: 24,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry != null
                              ? entry.time
                                  .format(context)
                                  .replaceAll(RegExp(r'[APap][Mm]$'), '')
                              : 'Tap to set time',
                          style: const TextStyle(
                            fontSize: 18.0,
                          ),
                        ),
                        Row(children: [
                          SvgPicture.asset(
                              'lib/assets/SVG/PencilSimpleLine.svg'),
                          const SizedBox(width: 4),
                          const Text('Edit')
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
            selectedIcon: const Icon(Icons.check_sharp),
            segments: const <ButtonSegment>[
              ButtonSegment(
                value: 0,
                label: Text('Manual'),
              ),
              ButtonSegment(
                value: 1,
                label: Text('Automatic'),
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
                      borderRadius: BorderRadiusDirectional.circular(8))),
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
                const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ))
        ],
      ),
      if (selectedButtonIndex == 0)
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          Text('Select manual time zone:',
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
              width: 24,
              height: 24,
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
          Text("You will be reminded of this when you change countries.",
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
