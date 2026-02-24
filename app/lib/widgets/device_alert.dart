import 'package:app/widgets/button_icon.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../api/device.dart';

class DeviceAlert extends StatelessWidget {
  final DeviceNotice notice;
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
    if (notice != DeviceNotice.none) {
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

  Widget _buildNotice(BuildContext context, DeviceNotice notice) {
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
              isDisabled: notice == DeviceNotice.disconnected,
              icon: _getIcon(notice),
              label: _getAction(notice, context),
              onPressed: () => onReload(),
            )
          ],
        ),
      ),
    );
  }

  String _getTitle(DeviceNotice notice, BuildContext context) {
    switch (notice) {
      case DeviceNotice.disconnected:
        return AppLocalizations.of(context)!.noticeDisconnected;
      case DeviceNotice.empty:
        return AppLocalizations.of(context)!.noticeEmpty;
      default:
        return '';
    }
  }

  String _getDescription(DeviceNotice notice, BuildContext context) {
    switch (notice) {
      case DeviceNotice.disconnected:
        return AppLocalizations.of(context)!.noticeDisconnectedSubtitle;
      case DeviceNotice.empty:
        return AppLocalizations.of(context)!.noticeEmptySubtitle;
      default:
        return '';
    }
  }

  Icon _getIcon(DeviceNotice notice) {
    switch (notice) {
      case DeviceNotice.disconnected:
        return Icon(PhosphorIconsBold.plugs, color: Colors.black, size: 20.h);
      case DeviceNotice.empty:
        return Icon(PhosphorIconsBold.pill, color: Colors.black, size: 20.h);
      default:
        return Icon(PhosphorIconsBold.pill, color: Colors.black, size: 20.h);
    }
  }

  String _getAction(DeviceNotice notice, BuildContext context) {
    switch (notice) {
      case DeviceNotice.disconnected:
        return AppLocalizations.of(context)!.noticeDisconnectedAction;
      case DeviceNotice.empty:
        return AppLocalizations.of(context)!.noticeEmptyAction;
      default:
        return "";
    }
  }
}
