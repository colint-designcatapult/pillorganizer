import 'package:app/apiv2/models/device.dart';
import 'package:app/provider/device_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/service/error_handler.dart';

class NotificationsSettings extends ConsumerStatefulWidget {
  final DeviceMetadata? device;

  const NotificationsSettings({
    super.key,
    this.device,
  });

  @override
  ConsumerState<NotificationsSettings> createState() => _NotificationsSettingsState();
}

class _NotificationsSettingsState extends ConsumerState<NotificationsSettings>
    with WidgetsBindingObserver {
  late Future<bool> _notificationPreference;

  // Sub-preference state (local, synced on toggle)
  late bool _notifyTakeNow;
  late bool _notifyTaken;
  late bool _notifyMissed;
  bool _updatingPrefs = false;

  @override
  Widget build(BuildContext context) {
    final targetDevice = widget.device ?? ref.read(activeDeviceProvider);

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
          //AppSettings.openAppSettings();
        } else {
          updateNotification(true, targetDevice);
        }
      }
    }

    return FutureBuilder<bool>(
        future: _notificationPreference,
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(
              color: Color(0xff708F72),
            );
          } else if (snapshot.hasData ||
              snapshot.hasError ||
              snapshot.connectionState == ConnectionState.done) {
            final isSubscribed = snapshot.data ?? false;
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
                  // Master toggle
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 50.h,
                          height: 40.h,
                          child: FittedBox(
                              fit: BoxFit.fill,
                              child: Switch(
                                value: isSubscribed,
                                onChanged: (bool value) {
                                  toggleNotifications(value);
                                },
                                activeTrackColor: const Color(0xff708F72),
                                thumbIcon:
                                    WidgetStateProperty.resolveWith<Icon?>(
                                  (Set<WidgetState> states) {
                                    if (states
                                        .contains(WidgetState.selected)) {
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
                  // Sub-preference toggles (visible only when subscribed)
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: EdgeInsets.only(left: 16.w, top: 12.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPreferenceSwitch(
                            label: AppLocalizations.of(context)!.takeNowNotifications,
                            value: _notifyTakeNow,
                            onChanged: _updatingPrefs ? null : (val) {
                              setState(() => _notifyTakeNow = val);
                              _savePreferences(targetDevice);
                            },
                          ),
                          _buildPreferenceSwitch(
                            label: AppLocalizations.of(context)!.takenNotifications,
                            value: _notifyTaken,
                            onChanged: _updatingPrefs ? null : (val) {
                              setState(() => _notifyTaken = val);
                              _savePreferences(targetDevice);
                            },
                          ),
                          _buildPreferenceSwitch(
                            label: AppLocalizations.of(context)!.missedNotifications,
                            value: _notifyMissed,
                            onChanged: _updatingPrefs ? null : (val) {
                              setState(() => _notifyMissed = val);
                              _savePreferences(targetDevice);
                            },
                          ),
                        ],
                      ),
                    ),
                    crossFadeState: isSubscribed
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                ]);
          } else {
            return const CircularProgressIndicator(
              color: Colors.white,
            );
          }
        });
  }

  Widget _buildPreferenceSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 50.h,
          height: 40.h,
          child: FittedBox(
            fit: BoxFit.fill,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: const Color(0xff708F72),
              thumbIcon: WidgetStateProperty.resolveWith<Icon?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return Icon(Icons.check,
                        color: const Color(0xff708F72), size: 18.h);
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
        SizedBox(width: 16.h),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Future<void> _savePreferences(DeviceMetadata targetDevice) async {
    setState(() => _updatingPrefs = true);
    try {
      await ref.read(deviceListProvider.notifier).updateNotificationPreferences(
        targetDevice.id,
        notifyTakeNow: _notifyTakeNow,
        notifyTaken: _notifyTaken,
        notifyMissed: _notifyMissed,
      );
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, AppLocalizations.of(context)!.genericError);
        // Revert to device state
        setState(() {
          _notifyTakeNow = targetDevice.notifyTakeNow;
          _notifyTaken = targetDevice.notifyTaken;
          _notifyMissed = targetDevice.notifyMissed;
        });
      }
    } finally {
      if (mounted) setState(() => _updatingPrefs = false);
    }
  }

  Future<void> updateNotification(bool value, DeviceMetadata targetDevice) async {
    final future = ref.read(deviceListProvider.notifier).updateDeviceNotifications(
      targetDevice.id, value,
      notifyTakeNow: _notifyTakeNow,
      notifyTaken: _notifyTaken,
      notifyMissed: _notifyMissed,
    );

    setState(() {
      _notificationPreference = future.then((device) => device.notifications);
    });

    try {
      await future;
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, AppLocalizations.of(context)!.genericError);
      }
      setState(() {
        _notificationPreference = Future.value(!value);
      });
    }
  }

  Future<void> checkPermission() async {
    final targetDevice = widget.device ?? ref.read(activeDeviceProvider);

    if (targetDevice == null) return;

    if (await Permission.notification.status.isGranted) {
      updateNotification(true, targetDevice);
    } else if (await Permission.notification.status.isDenied ||
        await Permission.notification.status.isPermanentlyDenied) {
      updateNotification(false, targetDevice);
    }
  }

  Future<void> initPermission() async {
    final targetDevice = widget.device ?? ref.read(activeDeviceProvider);

    if (targetDevice == null) return;

    // Initialise sub-preferences from the device state
    _notifyTakeNow = targetDevice.notifyTakeNow;
    _notifyTaken = targetDevice.notifyTaken;
    _notifyMissed = targetDevice.notifyMissed;

    // Initialise from the persisted backend value so the toggle reflects the
    // real subscription state on first load.
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
    final targetDevice = widget.device ?? ref.read(activeDeviceProvider);
    _notifyTakeNow = targetDevice?.notifyTakeNow ?? true;
    _notifyTaken = targetDevice?.notifyTaken ?? true;
    _notifyMissed = targetDevice?.notifyMissed ?? true;
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
