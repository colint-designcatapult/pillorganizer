import 'package:app/provider/selected_device_provider.dart';
import 'package:app/widgets/button_icon_text.dart';
import 'package:app/widgets/remove_device_modal.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../widgets/device_rename_modal.dart';
import '../../widgets/schedule_entry.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

void changeName(context) {
  showDialog(
    context: context,
    builder: (_) => const ChangeDeviceNameDialog(),
  );
}

void deleteDevice(context) {
  showDialog(
    context: context,
    builder: (_) => const RemoveDeviceDialog(),
  );
}

class _SettingsScreenState extends State<SettingsScreen> {
  int selectedButtonIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectedDeviceProvider>(
      builder: (context, prov, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFBFD2DB),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: 75.h, bottom: 20.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(left: 24.w, bottom: 8.h),
                      child: Text(
                        prov.device?.name ??
                            AppLocalizations.of(context)!.loadingState,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 32.h,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 24.w, bottom: 32.h),
                      child: Row(
                        children: [
                          ButtonIconText(
                              text: AppLocalizations.of(context)!.changeName,
                              iconData: PhosphorIcons.pencil_simple,
                              onPressed: () {
                                changeName(context);
                              }),
                          SizedBox(width: 20.w),
                          ButtonIconText(
                              text: AppLocalizations.of(context)!.delete,
                              iconData: PhosphorIcons.trash_simple,
                              onPressed: () {
                                deleteDevice(context);
                              }),
                        ],
                      ),
                    ),
                    Flexible(
                      fit: FlexFit.tight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0).w,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.0).r,
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.only(
                                  top: 24.h,
                                  bottom: 12.h,
                                  left: 20.w,
                                  right: 20.w,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: SegmentedButton(
                                        segments: <ButtonSegment>[
                                          ButtonSegment(
                                              icon: Icon(
                                                PhosphorIcons.timer,
                                                size: 18.h,
                                              ),
                                              value: 0,
                                              label: Text(
                                                AppLocalizations.of(context)!
                                                    .timeSettings,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w500),
                                              )),
                                          ButtonSegment(
                                            icon: Icon(
                                              PhosphorIcons.bell_simple_ringing,
                                              size: 18.h,
                                            ),
                                            value: 1,
                                            label: Text(
                                              AppLocalizations.of(context)!
                                                  .notifications,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                        selected: {selectedButtonIndex},
                                        selectedIcon: selectedButtonIndex == 0
                                            ? Icon(
                                                PhosphorIcons.timer,
                                                size: 18.h,
                                              )
                                            : Icon(
                                                PhosphorIcons
                                                    .bell_simple_ringing,
                                                size: 18.h,
                                              ),
                                        onSelectionChanged: (Set newSelection) {
                                          setState(() {
                                            selectedButtonIndex =
                                                newSelection.first;
                                          });
                                        },
                                        style: ButtonStyle(
                                          shape: MaterialStateProperty.all<
                                                  OutlinedBorder>(
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadiusDirectional
                                                          .circular(8.r))),
                                          side: MaterialStateProperty
                                              .resolveWith<BorderSide>(
                                                  (Set<MaterialState> states) {
                                            return BorderSide(
                                                color: const Color(0xFFBFD2DB),
                                                width: 2.h);
                                          }),
                                          backgroundColor: MaterialStateProperty
                                              .resolveWith<Color>(
                                                  (Set<MaterialState> states) {
                                            if (states.contains(
                                                MaterialState.selected)) {
                                              return const Color(0xFFE8EFF4);
                                            }
                                            return Colors.white;
                                          }),
                                          padding: MaterialStateProperty.all<
                                              EdgeInsetsGeometry>(
                                            EdgeInsets.symmetric(
                                                vertical: 16.h,
                                                horizontal: 12.w),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20.w, vertical: 20.h),
                                      child: selectedButtonIndex == 0
                                          ? const ScheduleEntry()
                                          : const NotificationsSettings()),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NotificationsSettings extends StatefulWidget {
  const NotificationsSettings({
    super.key,
  });

  @override
  _NotificationsSettingsState createState() => _NotificationsSettingsState();
}

class _NotificationsSettingsState extends State<NotificationsSettings>
    with WidgetsBindingObserver {
  late Future<bool> _notificationPreference;
  @override
  Widget build(BuildContext context) {
    Future<void> toggleNotifications(bool value) async {
      var status = await Permission.notification.status;
      if (value == false) {
        //When we toggle off we don't turn permission off since we can have other devices with notification on
        updateNotification(false);
      } else {
        if (status.isDenied) {
          //Asks for permission with native popup
          await Permission.notification.request().then(
              (value) => value.isGranted ? updateNotification(true) : null);
        } else if (status.isPermanentlyDenied) {
          //If denied the native permission then we need to open settings since it won't show again
          AppSettings.openAppSettings();
        } else {
          //If permission was already granted and we toggle on
          updateNotification(true);
        }
      }
    }

    return FutureBuilder<bool>(
        future: _notificationPreference,
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData ||
              snapshot.hasError ||
              snapshot.connectionState == ConnectionState.done) {
            return Consumer<SelectedDeviceProvider>(
                builder: (_, selectedDevice, __) {
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
            });
          } else {
            return const CircularProgressIndicator(
              color: Colors.white,
            );
          }
        });
  }

  void updateNotification(bool value) {
    Provider.of<SelectedDeviceProvider>(context, listen: false)
        .updateNotifications(value);

    setState(() {
      _notificationPreference = Future.value(value);
    });
  }

  Future<void> checkPermission() async {
    if (await Permission.notification.status.isGranted) {
      updateNotification(true);
    } else if (await Permission.notification.status.isDenied ||
        await Permission.notification.status.isPermanentlyDenied) {
      updateNotification(false);
    }
  }

  Future<void> initPermission() async {
    _notificationPreference = Future.value(
        Provider.of<SelectedDeviceProvider>(context, listen: false)
                .device
                ?.notifications ??
            false);
    if (await Permission.notification.status.isDenied ||
        await Permission.notification.status.isPermanentlyDenied) {
      //Only if the permission is disabled do we reflect in the app that no notification can be shown
      //Because having notification on in settings != wanting the notification for a device
      updateNotification(false);
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
