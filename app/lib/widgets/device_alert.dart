import 'package:app/widgets/button_icon.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../apiv2/models/device.dart';

class DeviceAlert extends StatelessWidget {
  final DeviceError notice;
  final Function onReload;
  final Future<void>? Function() reloadFuture;

  const DeviceAlert({
    Key? key,
    required this.notice,
    required this.onReload,
    required this.reloadFuture,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (notice != DeviceError.none) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 10.w,
          vertical: 10.h,
        ),
        child: _buildNotice(context, notice),
      );
    } else {
      return Container();
    }
  }

  Widget _buildNotice(BuildContext context, DeviceError notice) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0).r,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6.0).w,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                   crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTitle(notice, context),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.black,
                          ),
                    ),
                    Text(
                      _getDescription(notice, context),
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            ButtonIcon(
              isDisabled: notice == DeviceError.disconnected,
              icon: _getIcon(notice),
              label: _getAction(notice, context),
              onPressed: () => onReload(),
            )
          ],
        ),
      ),
    );
  }

  String _getTitle(DeviceError notice, BuildContext context) {
    switch (notice) {
      case DeviceError.disconnected:
        return AppLocalizations.of(context)!.noticeDisconnected;
      case DeviceError.phoneDisconnected:
        return AppLocalizations.of(context)!.noticePhoneDisconnected;
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
      case DeviceError.disconnected:
        return AppLocalizations.of(context)!.noticeDisconnectedSubtitle;
      case DeviceError.phoneDisconnected:
        return AppLocalizations.of(context)!.noticePhoneDisconnectedSubtitle;
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

  Icon _getIcon(DeviceError notice) {
    switch (notice) {
      case DeviceError.disconnected:
        return Icon(PhosphorIconsBold.plugs, color: Colors.black, size: 20.h);
      case DeviceError.phoneDisconnected:
        return Icon(PhosphorIconsBold.cloudSlash, color: Colors.black, size: 20.h);
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

  String _getAction(DeviceError notice, BuildContext context) {
    switch (notice) {
      case DeviceError.disconnected:
        return AppLocalizations.of(context)!.noticeDisconnectedAction;
      case DeviceError.phoneDisconnected:
        return AppLocalizations.of(context)!.noticePhoneDisconnectedAction;
      case DeviceError.needsReload:
        return AppLocalizations.of(context)!.noticeNeedsReloadAction;
      case DeviceError.noSchedule:
        return AppLocalizations.of(context)!.noticeNoScheduleAction;
      case DeviceError.stateCorrupted:
        return AppLocalizations.of(context)!.noticeStateCorruptedAction;
      case DeviceError.noRtcTime:
        return AppLocalizations.of(context)!.noticeNoRtcTimeAction;
      default:
        return AppLocalizations.of(context)!.noticeUnknownErrorAction;
    }
  }
}
