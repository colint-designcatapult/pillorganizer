import 'package:app/apiv2/models/device.dart';
import 'package:app/provider/provision_provider.dart';
import 'package:app/screens/provisioning/provision_flow_screen.dart';
import 'package:app/apiv2/models/schedule.dart';
import 'package:app/provider/device_connection_status_provider.dart';
import 'package:app/provider/device_provider.dart';
import 'package:app/provider/device_state_provider.dart';
import 'package:app/provider/pending_command_provider.dart';
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
  // Tracks which deviceId we've seeded form fields for; null = not yet seeded
  String? _seededDeviceId;
  // Tracks which deviceId the schedule was last loaded for
  String? _loadedForDeviceId;

  @override
  void initState() {
    super.initState();
    _loadPhoneTimezone();
  }

  @override
  void didUpdateWidget(ScheduleEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the explicitly-passed device changes, reset form and reload schedule
    if (widget.device?.id != oldWidget.device?.id) {
      setState(() {
        _seededDeviceId = null;
        _loadedForDeviceId = null;
        _amTime = null;
        _pmTime = null;
        _selectedTimezone = _phoneLocation;
      });
    }
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

  /// Called when schedule state loads — seeds form fields for the given device.
  void _initializeFromScheduleState(DeviceScheduleState state, String deviceId) {
    if (_seededDeviceId == deviceId) return;
    _seededDeviceId = deviceId;

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

    // If an explicit device is passed that differs from what scheduleProvider last loaded,
    // trigger a reload so the form reflects the correct device's schedule.
    if (targetDevice != null && _loadedForDeviceId != targetDevice.id) {
      _loadedForDeviceId = targetDevice.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(scheduleProvider.notifier).load(targetDevice.id);
      });
    }

    if (targetDevice == null) {
      if (!widget.showAddDeviceSection) return const SizedBox.shrink();
      return ScreenUtilWrapper(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AddDevice(titleSize: 30.0),
            SizedBox(height: 8.h),
          ],
        ),
      );
    }

    final scheduleAsync = ref.watch(scheduleProvider);
    final isOnline = widget.ignoreOffline ||
        connectionStatus == DeviceConnectionStatus.online;

    // Build the schedule section independently so loading/error states don't
    // hide unrelated sections (e.g. the delete-device button).
    final scheduleSection = scheduleAsync.when(
      data: (scheduleData) {
        // Initialize form fields only once when schedule first loads for this
        // device. Deferred because setState() must not run during build.
        if (_seededDeviceId != targetDevice.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_seededDeviceId != targetDevice.id) {
              _initializeFromScheduleState(scheduleData, targetDevice.id);
            }
          });
        }

        if (!isOnline) return _buildOfflineCard();
        return _buildScheduleForm(targetDevice);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) {
        print('[ScheduleEntry] Schedule load error: $e');
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isOnline) _buildOfflineCard(),
              Text(
                'Error loading schedule',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'An unexpected error occurred. Please try again.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(scheduleProvider.notifier).load(targetDevice.id),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );

    return ScreenUtilWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          scheduleSection,
          if (targetDevice.primaryUser) ...[
            SizedBox(height: _sectionSpacing.h),
            _buildWifiTransferButtons(targetDevice),
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
          child: Row(
            children: [
              Icon(Icons.wifi_off, size: 24.h, color: Theme.of(context).primaryColor),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.homeDisconnectedSubtext,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
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

        // Reload button (owners only)
        if (isOwner) ...[
          SizedBox(height: _sectionSpacing.h),
          _buildReloadButton(device),
        ],
      ],
    );
  }

  Widget _buildWifiTransferButtons(DeviceMetadata device) {
    final loc = AppLocalizations.of(context)!;
    final buttonStyle = OutlinedButton.styleFrom(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      side: const BorderSide(color: Color(0xFF206B8B)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
    );
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF206B8B),
          fontWeight: FontWeight.w600,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).push(
              ProvisionFlowPage.route(
                mode: ProvisionMode.wifiReconfigure,
                targetDeviceName: 'cabiNET-${device.serialNo}',
              ),
            );
          },
          style: buttonStyle,
          child: Text(loc.reconfigureWifi, style: textStyle),
        ),
        SizedBox(height: 12.h),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).push(
              ProvisionFlowPage.route(
                mode: ProvisionMode.transferDevice,
                existingDeviceId: device.id,
              ),
            );
          },
          style: buttonStyle,
          child: Text(loc.transferDeviceButton, style: textStyle),
        ),
      ],
    );
  }

  Widget _buildReloadButton(DeviceMetadata device) {
    final deviceStateAsync = ref.watch(deviceStateProvider);
    final isPending = ref.watch(pendingCommandProvider);

    return deviceStateAsync.when(
      data: (state) {
        if (state == null) return const SizedBox.shrink();

        final reloadState = state.reloadState;

        final loc = AppLocalizations.of(context)!;
        String label;
        VoidCallback? onPressed;

        if (!isPending) {
          if (reloadState != null && (reloadState.needed || reloadState.completeMask != null)) {
            label = loc.commandReloadComplete;
            onPressed = () => _sendReloadCommand(device.id, isComplete: true);
          } else {
            label = loc.commandReloadStart;
            onPressed = () => _sendReloadCommand(device.id, isComplete: false);
          }
        } else {
          label = reloadState != null && (reloadState.needed || reloadState.completeMask != null)
              ? loc.commandReloadComplete
              : loc.commandReloadStart;
          onPressed = null;
        }

        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              side: BorderSide(color: isPending ? Colors.grey : const Color(0xFF206B8B)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isPending ? Colors.grey : const Color(0xFF206B8B),
                  fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _sendReloadCommand(String deviceId, {required bool isComplete}) async {
    try {
      if (isComplete) {
        await ref.read(deviceListProvider.notifier).sendReloadCompleteCommand(deviceId);
      } else {
        await ref.read(deviceListProvider.notifier).sendReloadInitiateCommand(deviceId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.commandSent)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.commandFailed(e.toString()))),
        );
      }
    }
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
            SizedBox(height: 8.h),
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

// ── Removal section ─────────────────────────────────────────────────────────

class RemovalSection extends ConsumerWidget {
  final DeviceMetadata? device;
  const RemovalSection({super.key, this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isPrimary = device?.primaryUser ?? true;
    final String buttonLabel = isPrimary
        ? AppLocalizations.of(context)!.removeDevice
        : AppLocalizations.of(context)!.removeFromAccount;

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
              buttonLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
        if (device != null) ...[
          SizedBox(height: 16.h),
          if (device!.id.isNotEmpty)
            Text(
              'Device ID: ${device!.id}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B7280),
                fontSize: 11.h,
              ),
            ),
          if (device!.serialNo != null && device!.serialNo!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              'Serial: ${device!.serialNo}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B7280),
                fontSize: 11.h,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
