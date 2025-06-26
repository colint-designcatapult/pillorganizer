import 'package:app/api/device.dart';
import 'package:app/provider/device_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class NotificationsSettings extends StatefulWidget {
  final DeviceUser? device;

  const NotificationsSettings({
    super.key,
    this.device,
  });

  @override
  _NotificationsSettingsState createState() => _NotificationsSettingsState();
}

class _NotificationsSettingsState extends State<NotificationsSettings>
    with WidgetsBindingObserver {
  late Future<bool> _notificationPreference;

  @override
  Widget build(BuildContext context) {
    final targetDevice = widget.device ??
        Provider.of<SelectedDeviceProvider>(context, listen: false).device;

    if (targetDevice == null) {
      return const SizedBox.shrink();
    }

    Future<void> toggleNotifications(bool value) async {
      var status = await Permission.notification.status;
      if (value == false) {
        updateNotification(false, targetDevice);
      } else {
        if (status.isDenied) {
          await Permission.notification.request().then((value) =>
              value.isGranted ? updateNotification(true, targetDevice) : null);
        } else if (status.isPermanentlyDenied) {
          AppSettings.openAppSettings();
        } else {
          updateNotification(true, targetDevice);
        }
      }
    }

    return FutureBuilder<bool>(
        future: _notificationPreference,
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData ||
              snapshot.hasError ||
              snapshot.connectionState == ConnectionState.done) {
            return Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.notificationPreferences,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  SizedBox(height: 26.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 50.h,
                          height: 40.h,
                          child: FittedBox(
                              fit: BoxFit.fill,
                              child: Switch(
                                value: snapshot.data ?? false,
                                onChanged: (bool value) {
                                  toggleNotifications(value);
                                },
                                activeTrackColor: const Color(0xff708F72),
                                thumbIcon:
                                    MaterialStateProperty.resolveWith<Icon?>(
                                  (Set<MaterialState> states) {
                                    if (states
                                        .contains(MaterialState.selected)) {
                                      return Icon(Icons.check,
                                          color: const Color(0xff708F72),
                                          size: 18.h);
                                    }
                                    return null;
                                  },
                                ),
                              ))),
                      SizedBox(width: 16.h),
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context)!.notificationReminder,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ]);
          } else {
            return const CircularProgressIndicator(
              color: Colors.white,
            );
          }
        });
  }

  void updateNotification(bool value, DeviceUser targetDevice) {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    deviceProvider.updateDeviceNotifications(targetDevice.deviceID, value);

    setState(() {
      _notificationPreference = Future.value(value);
    });
  }

  Future<void> checkPermission() async {
    final targetDevice = widget.device ??
        Provider.of<SelectedDeviceProvider>(context, listen: false).device;

    if (targetDevice == null) return;

    if (await Permission.notification.status.isGranted) {
      updateNotification(true, targetDevice);
    } else if (await Permission.notification.status.isDenied ||
        await Permission.notification.status.isPermanentlyDenied) {
      updateNotification(false, targetDevice);
    }
  }

  Future<void> initPermission() async {
    final targetDevice = widget.device ??
        Provider.of<SelectedDeviceProvider>(context, listen: false).device;

    if (targetDevice == null) return;

    _notificationPreference = Future.value(targetDevice.notifications);

    if (await Permission.notification.status.isDenied ||
        await Permission.notification.status.isPermanentlyDenied) {
      //Only if the permission is disabled do we reflect in the app that no notification can be shown
      //Because having notification on in settings != wanting the notification for a device
      updateNotification(false, targetDevice);
    }
  }

  @override
  void initState() {
    super.initState();
    initPermission();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user leaves the app to go into notification, check permission
    if (state == AppLifecycleState.resumed) {
      checkPermission();
    }
  }
}
