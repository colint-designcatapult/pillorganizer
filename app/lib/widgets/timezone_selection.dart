import 'package:app/apiv2/models/device.dart';
import 'package:app/provider/schedule_provider.dart';
import 'package:app/screens/modals/time_zone_selection.dart';
import 'package:app/service/time_service.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/standalone.dart' as tz;

class TimeZoneSelection extends ConsumerStatefulWidget {
  final DeviceMetadata? device;
  final bool isOwner;

  const TimeZoneSelection({
    super.key,
    required this.device,
    required this.isOwner,
  });

  @override
  ConsumerState<TimeZoneSelection> createState() => TimeZoneSelectionState();
}

class TimeZoneSelectionState extends ConsumerState<TimeZoneSelection> {
  tz.Location? phoneLocation;
  bool _isUpdatingTimezone = false;

  @override
  void initState() {
    super.initState();
    _getCurrentPhoneLocation();
  }

  Future<void> _getCurrentPhoneLocation() async {
    final String timeZoneName = normalizeIanaTimezone((await FlutterTimezone.getLocalTimezone()).identifier);
    final tz.Location location = tz.getLocation(timeZoneName);
    setState(() {
      phoneLocation = location;
    });
  }

  Future<void> _updateDeviceTimezone(tz.Location location) async {
    if (widget.device == null) return;
    setState(() => _isUpdatingTimezone = true);
    try {
      await ref.read(scheduleProvider.notifier).updateTimezone(widget.device!.id, location.name);
    } finally {
      if (mounted) setState(() => _isUpdatingTimezone = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleState = ref.watch(scheduleProvider);
    final bool scheduleLoaded = scheduleState.hasValue;
    final timezone = scheduleState.asData?.value.effectiveTimezoneIana;
    final bool timezoneMismatch = phoneLocation != null &&
        timezone != null &&
        phoneLocation!.name != timezone;

    return Column(
      children: [
        _buildTimezoneSection(timezone, widget.isOwner, _isUpdatingTimezone || !scheduleLoaded, timezoneMismatch),
        SizedBox(height: 16.h),
        _buildCurrentTimezoneButton(_isUpdatingTimezone || !scheduleLoaded, timezoneMismatch),
      ],
    );
  }

  Widget _buildTimezoneSection(
      String? timezone, bool isOwner, bool isUpdatingTimezone, bool timezoneMismatch) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.selectManualTimezone,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (timezoneMismatch) ...[
              SizedBox(width: 8.w),
              Icon(Icons.warning_amber_rounded, size: 16.h, color: Colors.orange),
            ],
          ],
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
                    _buildTimeZoneName(timezone),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  leading: SvgPicture.asset(
                    'lib/assets/SVG/Globe.svg',
                    width: 24.w,
                    height: 24.h,
                  ),
                  trailing: isOwner ? Icon(Icons.arrow_drop_down, size: 24.h) : null,
                  onTap: () {
                    if (!isOwner) return;
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

  Widget _buildCurrentTimezoneButton(bool isUpdatingTimezone, bool timezoneMismatch) {
    if (!widget.isOwner) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: (isUpdatingTimezone || phoneLocation == null)
            ? null
            : () => _updateDeviceTimezone(phoneLocation!),
        style: ButtonStyle(
          side: WidgetStateProperty.all<BorderSide>(
            BorderSide(
              color: timezoneMismatch ? Colors.orange : const Color(0xFFBFD2DB),
              width: 2.0,
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
        ),
        child: Text(
          AppLocalizations.of(context)!.setToCurrentTimezone,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  String _buildTimeZoneName(String? tzString) {
    final loc = lookupTimeZoneLocation(tzString);
    if (loc == null) {
      return tzString ?? "UTC/GMT";
    } else {
      final idx = loc.name.indexOf('/') + 1;
      return "${loc.name.substring(idx, loc.name.length).replaceAll("_", " ")} (${loc.currentTimeZone.abbreviation})";
    }
  }
}
