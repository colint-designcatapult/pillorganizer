import 'package:app/apiv2/models/device.dart';
import 'package:app/apiv2/models/schedule.dart';
import 'package:app/provider/device_connection_status_provider.dart';
import 'package:app/provider/schedule_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/screens/ScreenUtilWrapper.dart';
import 'package:app/screens/modals/time_zone_selection.dart';
import 'package:app/service/time_service.dart';
import 'package:app/widgets/add_device.dart';
import 'package:app/widgets/custom_time_picker.dart';
import 'package:app/widgets/remove_device_modal.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/standalone.dart' as tz;

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
    this.ignoreOffline = false,
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
  // Local form state — not persisted until Save is pressed
  TimeOfDay? _amTime;
  TimeOfDay? _pmTime;
  tz.Location? _selectedTimezone;
  tz.Location? _phoneLocation;
  bool _isSubmitting = false;
  bool _stateInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadPhoneTimezone();
  }

  Future<void> _loadPhoneTimezone() async {
    try {
      final tzName = normalizeIanaTimezone(
          (await FlutterTimezone.getLocalTimezone()).identifier);
      final loc = tz.getLocation(tzName);
      if (mounted) {
        setState(() {
          _phoneLocation = loc;
          // Pre-fill timezone as default if not yet set from device state
          if (_selectedTimezone == null) {
            _selectedTimezone = loc;
          }
        });
      }
    } catch (_) {}
  }

  /// Called once when the schedule state first loads — seeds form fields.
  void _initializeFromScheduleState(DeviceScheduleState state) {
    if (_stateInitialized) return;
    _stateInitialized = true;

    final effective = state.effectiveSchedule;
    final simple = effective is SimpleSchedule ? effective : null;

    setState(() {
      if (simple?.amPeriod != null) _amTime = simple!.amPeriod!.time;
      if (simple?.pmPeriod != null) _pmTime = simple!.pmPeriod!.time;
      if (state.effectiveTimezoneIana != null) {
        try {
          _selectedTimezone = tz.getLocation(state.effectiveTimezoneIana!);
        } catch (_) {}
      }
    });
  }

  Future<void> _pickTime(DayPeriod period) async {
    final isAM = period == DayPeriod.am;
    final current = isAM
        ? (_amTime ?? const TimeOfDay(hour: 8, minute: 0))
        : (_pmTime ?? const TimeOfDay(hour: 20, minute: 0));

    final selected = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: CustomTimePicker(initialTime: current, isAM: isAM),
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        if (isAM) {
          _amTime = selected;
        } else {
          _pmTime = selected;
        }
      });
    }
  }

  Future<void> _pickTimezone() async {
    final selected =
        await Navigator.of(context).push(TimeZoneSelectionModal.route(context));
    if (selected != null && mounted) {
      setState(() => _selectedTimezone = selected);
    }
  }

  Future<void> _submit(String deviceId) async {
    if (_amTime == null || _pmTime == null || _selectedTimezone == null) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(scheduleProvider.notifier).setScheduleAndTimezone(
            deviceId,
            _amTime!,
            _pmTime!,
            _selectedTimezone!.name,
          );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetDevice = widget.device ?? ref.watch(activeDeviceProvider);
    final connectionStatus = ref.watch(deviceConnectionStatusProvider);

    // Seed form fields once when schedule data arrives
    ref.listen<AsyncValue<DeviceScheduleState>>(scheduleProvider, (_, next) {
      if (next.hasValue && next.value != null) {
        _initializeFromScheduleState(next.value!);
      }
    });

    if (targetDevice == null) {
      print('[ScheduleEntry] DEBUG: targetDevice is null, hiding widget');
      return const SizedBox.shrink();
    }

    final scheduleAsync = ref.watch(scheduleProvider);
    print('[ScheduleEntry] DEBUG: Device=${targetDevice.name}, Schedule State=${scheduleAsync.runtimeType}');

    return scheduleAsync.when(
      data: (scheduleState) {
        print('[ScheduleEntry] DEBUG: Schedule loaded: am=${scheduleState.effectiveSchedule is SimpleSchedule ? (scheduleState.effectiveSchedule as SimpleSchedule).amPeriod : 'N/A'}, tz=${scheduleState.effectiveTimezoneIana}');
        final isOnline = widget.ignoreOffline ||
            connectionStatus == DeviceConnectionStatus.online;
        print('[ScheduleEntry] DEBUG: isOnline=$isOnline, ignoreOffline=${widget.ignoreOffline}, connectionStatus=$connectionStatus');

        return ScreenUtilWrapper(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isOnline)
                _buildScheduleForm(targetDevice)
              else
                _buildOfflineCard(),
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
      loading: () {
        print('[ScheduleEntry] DEBUG: Schedule LOADING');
        return const Center(child: CircularProgressIndicator());
      },
      error: (e, s) {
        print('[ScheduleEntry] DEBUG: Schedule ERROR: $e');
        return Center(child: Text(e.toString()));
      },
    );
  }

  // ── Offline card ────────────────────────────────────────────────────────────

  Widget _buildOfflineCard() {
    return Card(
      color: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFBFD2DB), width: 1.w),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Device offline',
                  style: Theme.of(context).textTheme.titleSmall),
              SizedBox(height: _titleSubtitleSpacing.h),
              Text(
                  'Schedule and timezone changes can only be made while your device is connected.',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  // ── Unified schedule form ───────────────────────────────────────────────────

  Widget _buildScheduleForm(DeviceMetadata device) {
    final loc = AppLocalizations.of(context)!;
    final isOwner = device.primaryUser;
    final canSubmit = isOwner &&
        _amTime != null &&
        _pmTime != null &&
        _selectedTimezone != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time Setup section
        Text(loc.timeSetup, style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: _titleSubtitleSpacing.h),
        Text(loc.timeSetupSubtitle,
            style: Theme.of(context).textTheme.bodySmall),
        SizedBox(height: _subtitleContentSpacing.h),
        Row(
          children: [
            Expanded(
                child: _buildTimeBlock(DayPeriod.am, _amTime, device)),
            SizedBox(width: 12.w),
            Expanded(
                child: _buildTimeBlock(DayPeriod.pm, _pmTime, device)),
          ],
        ),

        // Timezone section (owners only)
        if (isOwner) ...[
          SizedBox(height: _sectionSpacing.h),
          Text(loc.timezone, style: Theme.of(context).textTheme.titleSmall),
          SizedBox(height: _titleSubtitleSpacing.h),
          Text(loc.timezoneSubtitle,
              style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: _subtitleContentSpacing.h),
          _buildTimezoneSelector(),
          SizedBox(height: 12.h),
          _buildUseMyTimezoneButton(),
        ],

        // Single Save button (owners only)
        if (isOwner) ...[
          SizedBox(height: _sectionSpacing.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (canSubmit && !_isSubmitting)
                  ? () => _submit(device.id)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF206B8B),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF206B8B).withOpacity(0.4),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r)),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      height: 20.h,
                      width: 20.h,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      loc.save,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimezoneSelector() {
    final tzName = _selectedTimezone != null
        ? _buildTimeZoneName(_selectedTimezone!.name)
        : 'UTC/GMT';

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFBFD2DB), width: 2.0),
        borderRadius: BorderRadius.circular(8.0).r,
      ),
      child: ListTile(
        title:
            Text(tzName, style: Theme.of(context).textTheme.displaySmall),
        leading: SvgPicture.asset('lib/assets/SVG/Globe.svg',
            width: 24.w, height: 24.h),
        trailing: Icon(Icons.arrow_drop_down, size: 24.h),
        onTap: _pickTimezone,
      ),
    );
  }

  Widget _buildUseMyTimezoneButton() {
    final loc = AppLocalizations.of(context)!;
    final timezoneMismatch = _phoneLocation != null &&
        _selectedTimezone != null &&
        _phoneLocation!.name != _selectedTimezone!.name;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _phoneLocation == null
            ? null
            : () => setState(() => _selectedTimezone = _phoneLocation),
        style: ButtonStyle(
          side: WidgetStateProperty.all<BorderSide>(BorderSide(
            color:
                timezoneMismatch ? Colors.orange : const Color(0xFFBFD2DB),
            width: 2.0,
          )),
          shape: WidgetStateProperty.all<OutlinedBorder>(
            RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0).r),
          ),
          padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
              EdgeInsets.symmetric(vertical: 16.h)),
        ),
        child: Text(loc.setToCurrentTimezone,
            style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }

  Widget _buildTimeBlock(
      DayPeriod dayPeriod, TimeOfDay? selectedTime, DeviceMetadata device) {
    final isAM = dayPeriod == DayPeriod.am;
    return GestureDetector(
      onTap: device.primaryUser ? () => _pickTime(dayPeriod) : null,
      child: Container(
        decoration: BoxDecoration(
          border:
              Border.all(color: const Color(0xFFE8EFF4), width: 1.0),
          borderRadius: BorderRadius.circular(8.0).r,
        ),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        child: Column(
          children: [
            Container(
              color: const Color(0xFFE8EFF4),
              padding:
                  EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isAM ? 'AM' : 'PM',
                      style:
                          Theme.of(context).textTheme.titleMedium),
                  SizedBox(width: 12.w),
                  SvgPicture.asset(
                    isAM
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
              padding: EdgeInsets.symmetric(
                  horizontal: 8.w, vertical: 12.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    selectedTime != null
                        ? selectedTime
                            .format(context)
                            .replaceAll(RegExp(r'[APap][Mm]$'), '')
                        : AppLocalizations.of(context)!.setTime,
                    textAlign: TextAlign.center,
                    style: AppLocalizations.of(context)!.localeName == 'fr'
                        ? Theme.of(context).textTheme.bodySmall
                        : Theme.of(context).textTheme.labelSmall,
                  ),
                  if (device.primaryUser && selectedTime != null) ...[
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                            'lib/assets/SVG/PencilSimpleLine.svg',
                            width: 16.w,
                            height: 16.h),
                        SizedBox(width: 4.w),
                        Text(AppLocalizations.of(context)!.edit,
                            style:
                                Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildTimeZoneName(String? tzString) {
    final loc = lookupTimeZoneLocation(tzString);
    if (loc == null) return tzString ?? 'UTC/GMT';
    final idx = loc.name.indexOf('/') + 1;
    return '${loc.name.substring(idx).replaceAll('_', ' ')} (${loc.currentTimeZone.abbreviation})';
  }
}

// ── Removal section (unchanged) ────────────────────────────────────────────────

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
        SizedBox(height: 16.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => deleteDevice(context, device),
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
                (states) => states.contains(WidgetState.pressed)
                    ? Theme.of(context).colorScheme.error.withOpacity(0.2)
                    : Colors.transparent,
              ),
              overlayColor: WidgetStateProperty.resolveWith<Color>(
                (states) => states.contains(WidgetState.pressed)
                    ? Theme.of(context).colorScheme.error.withOpacity(0.2)
                    : Colors.transparent,
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
