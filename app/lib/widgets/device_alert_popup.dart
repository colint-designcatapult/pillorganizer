import 'package:app/provider/device_provider.dart';
import 'package:app/provider/device_state_provider.dart';
import 'package:app/provider/pending_command_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../apiv2/models/device.dart';

class DeviceAlertPopup extends ConsumerWidget {
  final DeviceError notice;

  /// Called for non-command actions: reconnect (phoneDisconnected),
  /// or refresh (noSchedule, noTimezone).
  final VoidCallback? onActionPressed;

  const DeviceAlertPopup({
    Key? key,
    required this.notice,
    this.onActionPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (notice == DeviceError.none) return const SizedBox.shrink();

    final isPending = ref.watch(pendingCommandProvider);
    final reloadState = ref.watch(deviceStateProvider).asData?.value?.reloadState;
    final activeDevice = ref.watch(activeDeviceProvider);

    final String? actionLabel = _getAction(notice, context, reloadState);

    VoidCallback? onButtonPressed;
    if (notice == DeviceError.needsReload && activeDevice != null && !isPending) {
      final isInitiate = reloadState?.progress == null;
      onButtonPressed = () async {
        try {
          if (isInitiate) {
            await ref.read(deviceListProvider.notifier).sendReloadInitiateCommand(activeDevice.id);
          } else {
            await ref.read(deviceListProvider.notifier).sendReloadCompleteCommand(activeDevice.id);
          }
        } catch (_) {}
      };
    } else if (notice != DeviceError.needsReload) {
      onButtonPressed = onActionPressed;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Card(
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
            padding: EdgeInsets.fromLTRB(20.w, 40.h, 20.w, 40.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _getLargeIcon(notice),
                SizedBox(height: 16.h),
                Text(
                  _getTitle(notice, context),
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: const Color(0XFF101828)),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Text(
                    _getDescription(notice, context),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 32.h),
                if (actionLabel != null)
                  ElevatedButton(
                    onPressed: onButtonPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: onButtonPressed != null
                          ? const Color(0xFF206B8B)
                          : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8).r,
                      ),
                      padding:
                      EdgeInsets.symmetric(vertical: 20.h, horizontal: 18.w),
                    ),
                    child: Text(
                      actionLabel,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: const Color(0xFFFFFFFF)),
                    ),
                  )

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getLargeIcon(DeviceError notice) {
    IconData iconData;
    switch (notice) {
      case DeviceError.phoneDisconnected:
        iconData = PhosphorIconsFill.cloudSlash;
        break;
      case DeviceError.disconnected:
        iconData = PhosphorIconsFill.plugs;
        break;
      case DeviceError.needsReload:
        iconData = PhosphorIconsFill.arrowsClockwise;
        break;
      case DeviceError.noSchedule:
        iconData = PhosphorIconsFill.calendarX;
        break;
      case DeviceError.stateCorrupted:
        iconData = PhosphorIconsFill.warningCircle;
        break;
      case DeviceError.noRtcTime:
        iconData = PhosphorIconsFill.clockAfternoon;
        break;
      case DeviceError.noTimezone:
        iconData = PhosphorIconsFill.globe;
        break;
      default:
        iconData = PhosphorIconsFill.warningCircle;
        break;
    }
    return Icon(
      iconData,
      size: 48.h,
      color: const Color(0xFF206B8B),
    );
  }

  Icon _getIconSmall(DeviceError notice) {
    switch (notice) {
      case DeviceError.phoneDisconnected:
        return Icon(PhosphorIconsBold.cloudSlash, color: Colors.black, size: 20.h);
      case DeviceError.disconnected:
        return Icon(PhosphorIconsBold.plugs, color: Colors.black, size: 20.h);
      case DeviceError.needsReload:
        return Icon(PhosphorIconsBold.arrowsClockwise, color: Colors.black, size: 20.h);
      case DeviceError.noSchedule:
        return Icon(PhosphorIconsBold.calendarX, color: Colors.black, size: 20.h);
      case DeviceError.stateCorrupted:
        return Icon(PhosphorIconsBold.warningCircle, color: Colors.black, size: 20.h);
      case DeviceError.noRtcTime:
        return Icon(PhosphorIconsBold.clockAfternoon, color: Colors.black, size: 20.h);
      case DeviceError.noTimezone:
        return Icon(PhosphorIconsBold.globe, color: Colors.black, size: 20.h);
      default:
        return Icon(PhosphorIconsBold.warningCircle, color: Colors.black, size: 20.h);
    }
  }

  String _getTitle(DeviceError notice, BuildContext context) {
    switch (notice) {
      case DeviceError.phoneDisconnected:
        return AppLocalizations.of(context)!.noticePhoneDisconnected;
      case DeviceError.disconnected:
        return AppLocalizations.of(context)!.noticeDisconnected;
      case DeviceError.needsReload:
        return AppLocalizations.of(context)!.noticeNeedsReload;
      case DeviceError.noSchedule:
        return AppLocalizations.of(context)!.noticeNoSchedule;
      case DeviceError.stateCorrupted:
        return AppLocalizations.of(context)!.noticeStateCorrupted;
      case DeviceError.noRtcTime:
        return AppLocalizations.of(context)!.noticeNoRtcTime;
      case DeviceError.noTimezone:
        return AppLocalizations.of(context)!.noticeNoTimezone;
      default:
        return AppLocalizations.of(context)!.noticeUnknownError;
    }
  }

  String _getDescription(DeviceError notice, BuildContext context) {
    switch (notice) {
      case DeviceError.phoneDisconnected:
        return AppLocalizations.of(context)!.noticePhoneDisconnectedSubtitle;
      case DeviceError.disconnected:
        return AppLocalizations.of(context)!.noticeDisconnectedSubtitle;
      case DeviceError.needsReload:
        return AppLocalizations.of(context)!.noticeNeedsReloadSubtitle;
      case DeviceError.noSchedule:
        return AppLocalizations.of(context)!.noticeNoScheduleSubtitle;
      case DeviceError.stateCorrupted:
        return AppLocalizations.of(context)!.noticeStateCorruptedSubtitle;
      case DeviceError.noRtcTime:
        return AppLocalizations.of(context)!.noticeNoRtcTimeSubtitle;
      case DeviceError.noTimezone:
        return AppLocalizations.of(context)!.noticeNoTimezoneSubtitle;
      default:
        return AppLocalizations.of(context)!.noticeUnknownErrorSubtitle;
    }
  }

  String? _getAction(DeviceError notice, BuildContext context, ReloadState? reloadState) {
    switch (notice) {
      case DeviceError.phoneDisconnected:
        return AppLocalizations.of(context)!.noticePhoneDisconnectedAction;
      case DeviceError.noSchedule:
        return AppLocalizations.of(context)!.noticeNoScheduleAction;
      case DeviceError.noTimezone:
        return AppLocalizations.of(context)!.noticeNoTimezoneAction;
      case DeviceError.needsReload:
        return reloadState?.progress != null
            ? AppLocalizations.of(context)!.commandReloadComplete
            : AppLocalizations.of(context)!.commandReloadInitiate;
      default:
        return null;
    }
  }
}
