import 'package:app/api/schedule.dart';
import 'package:app/provider/schedule_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/widgets/shimmer_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../screens/modals/time_zone_selection.dart';
import '../service/time_service.dart';
import 'device_icon.dart';

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
            const Text(
                'Select when you\'d like to be reminded to take your pills.'),
            _buildTimeBlock(schedProv, DayPeriod.am, schedProv.schedule?.am),
            _buildTimeBlock(schedProv, DayPeriod.pm, schedProv.schedule?.pm),
            const Text('Select the time zone your pill organizer should use.'),
            ListTile(
              title: Text(_buildTimeZoneName(
                  Provider.of<SelectedDeviceProvider>(context)
                      .device
                      ?.timezone)),
              leading: const Icon(Icons.south_america),
              trailing: const Icon(Icons.arrow_right),
              onTap: () {
                final prov =
                    Provider.of<SelectedDeviceProvider>(context, listen: false);

                Navigator.of(context)
                    .push(TimeZoneSelectionModal.route(context))
                    .then((value) {
                  if (value != null) {
                    prov.updateTimeZone(value);
                  }
                });
              },
            ),
            const Text('Notification preferences'),
            ListTile(
              title: const Text('Send reminder notifications to your phone'),
              leading: const Icon(Icons.notifications),
              trailing: Switch(
                value: Provider.of<SelectedDeviceProvider>(context)
                        .device
                        ?.notifications ??
                    false,
                onChanged: (bool value) {
                  _toggleNotifications();
                },
              ),
              onTap: _toggleNotifications,
            ),
            const SizedBox(
              height: 50,
            )
          ],
        );
      },
    );
  }

  void _toggleNotifications() {
    var sdp = Provider.of<SelectedDeviceProvider>(context, listen: false);
    sdp.updateNotifications(!(sdp.device?.notifications ?? false));
  }

  String _buildTimeZoneName(TimeZoneLocation? loc) {
    if (loc == null) {
      return "UTC/GMT";
    } else {
      final idx = loc.name.indexOf('/') + 1;
      return loc.name.substring(idx, loc.name.length).replaceAll("_", " ") +
          " (${loc.currentTimeZone.abbreviation})";
    }
  }

  Widget _buildTimeBlock(
      ScheduleProvider prov, DayPeriod dayPeriod, DispenseTime? entry) {
    /*return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        visualDensity: VisualDensity(horizontal: 3.0, vertical: 3.0),
        title: entry == null
            ? Text('Tap to set a time')
            : Text('a'),
        leading: BinIcon(dayPeriod: dayPeriod),
        trailing: Icon(Icons.arrow_right),
        onTap: () {},
      ),
    );*/
    return FutureBuilder(
      future: prov.future,
      builder: (context, snapshot) {
        return ShimmerPlaceholder(
          loading: !snapshot.hasData,
          builder: (context, loading) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ListTile(
                visualDensity:
                    const VisualDensity(horizontal: 2.0, vertical: 2.0),
                title: _buildTimeTitle(loading, entry),
                leading: BinIcon(dayPeriod: dayPeriod),
                trailing: Icon(Icons.arrow_right),
                onTap: () {
                  showTimePicker(
                    initialTime: entry?.time ?? TimeOfDay.now(),
                    context: context,
                  ).then((value) {
                    if (value != null) {
                      Provider.of<ScheduleProvider>(context, listen: false)
                          .updateTime(dayPeriod, value);
                    }
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeTitle(bool loading, DispenseTime? entry) {
    if (loading) {
      return Container(width: 120.0, height: 32.0, color: Colors.white);
    } else {
      if (entry == null) {
        return const Text('Tap to set time');
      } else {
        final fm = DateFormat.jm();
        return Text('Every day at ${entry.time.format(context)}');
      }
    }
  }
}
