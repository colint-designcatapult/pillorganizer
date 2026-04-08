import 'package:app/widgets/button_icon.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../apiv2/models/device.dart';

class DeviceAlertPopup extends StatelessWidget {
  final DeviceError notice;
  final Function onReload;
  final Future<void>? Function() reloadFuture;

  const DeviceAlertPopup({
    Key? key,
    required this.notice,
    required this.onReload,
    required this.reloadFuture,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (notice == DeviceError.none) return const SizedBox.shrink();

    String? action = _getAction(notice, context);

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
                if (action != null)
                  ElevatedButton(
                    onPressed: () => onReload(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF206B8B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8).r,
                      ),
                      padding:
                      EdgeInsets.symmetric(vertical: 20.h, horizontal: 18.w),
                    ),
                    child: Text(
                      action,
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
      default:
        return AppLocalizations.of(context)!.noticeUnknownErrorSubtitle;
    }
  }

  String? _getAction(DeviceError notice, BuildContext context) {
    switch (notice) {
      case DeviceError.phoneDisconnected:
        return AppLocalizations.of(context)!.noticePhoneDisconnectedAction;
      case DeviceError.noSchedule:
        return AppLocalizations.of(context)!.noticeNoScheduleAction;
      default:
        return AppLocalizations.of(context)!.noticeUnknownErrorAction;
    }
  }
}
