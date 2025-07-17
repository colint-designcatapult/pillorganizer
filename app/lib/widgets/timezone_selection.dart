import 'package:app/api/device.dart';
import 'package:app/provider/device_provider.dart';
import 'package:app/screens/modals/time_zone_selection.dart';
import 'package:app/service/time_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:timezone/standalone.dart' as tz;

class TimeZoneSelection extends StatefulWidget {
  final DeviceUser device;
  final bool isOwner;

  const TimeZoneSelection({
    super.key,
    required this.device,
    required this.isOwner,
  });

  @override
  TimeZoneSelectionState createState() => TimeZoneSelectionState();
}

class TimeZoneSelectionState extends State<TimeZoneSelection> {
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

      bool isUpdatingTimezone = deviceProvider.isUpdatingTimezone;

      return Column(
        children: [
          _buildTimezoneSection(
              currentDevice, widget.isOwner, isUpdatingTimezone),
          SizedBox(height: 16.h),
          _buildCurrentTimezoneButton(isUpdatingTimezone),
        ],
      );
    });
  }

  Widget _buildTimezoneSection(
      DeviceUser currentDevice, bool isOwner, bool isUpdatingTimezone) {
    return Column(
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
          child: isUpdatingTimezone
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: const Center(child: CircularProgressIndicator()),
                )
              : ListTile(
                  title: Text(
                    _buildTimeZoneName(currentDevice.timezone),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  leading: SvgPicture.asset(
                    'lib/assets/SVG/Globe.svg',
                    width: 24.w,
                    height: 24.h,
                  ),
                  trailing:
                      isOwner ? Icon(Icons.arrow_drop_down, size: 24.h) : null,
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

  Widget _buildCurrentTimezoneButton(bool isUpdatingTimezone) {
    if (!widget.isOwner) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isUpdatingTimezone
            ? null
            : () => _updateDeviceTimezone(phoneLocation),
        style: ButtonStyle(
          side: MaterialStateProperty.all<BorderSide>(
            const BorderSide(color: Color(0xFFBFD2DB), width: 2.0),
          ),
          shape: MaterialStateProperty.all<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0).r,
            ),
          ),
          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(vertical: 16.h),
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.setToCurrentTimezone,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
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
