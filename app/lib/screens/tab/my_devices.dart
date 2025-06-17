import 'package:app/api/device.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/widgets/add_device.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../widgets/device_rename_modal.dart';
import '../../widgets/schedule_entry.dart';

class MyDevicesScreen extends StatefulWidget {
  const MyDevicesScreen({super.key});

  @override
  _MyDevicesScreenState createState() => _MyDevicesScreenState();
}

void changeName(context) {
  showDialog(
    context: context,
    builder: (_) => const ChangeDeviceNameDialog(),
  );
}

class _MyDevicesScreenState extends State<MyDevicesScreen> {
  int selectedButtonIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer2<SelectedDeviceProvider, DeviceListProvider>(
      builder: (context, prov, deviceListProv, _) {
        final deviceCount = deviceListProv.value?.length ?? 0;

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
                        AppLocalizations.of(context)!.myDevices,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 36.h,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0).w,
                        child: deviceCount > 1
                            ? MultipleDevicesWidget(
                                devices: deviceListProv.value!,
                                selectedButtonIndex: selectedButtonIndex,
                                onSelectionChanged: (index) {
                                  setState(() {
                                    selectedButtonIndex = index;
                                  });
                                },
                              )
                            : SingleDeviceWidget(
                                showAddDeviceSection: deviceCount == 1,
                                device: prov.device,
                                isModal: false,
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

class MultipleDevicesWidget extends StatelessWidget {
  final List<DeviceUser> devices;
  final int selectedButtonIndex;
  final Function(int) onSelectionChanged;

  const MultipleDevicesWidget({
    super.key,
    required this.devices,
    required this.selectedButtonIndex,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 0.h),
      margin: EdgeInsets.only(bottom: 60.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0).r,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24.h),
            Text(
              AppLocalizations.of(context)!.manageDevices,
              style: TextStyle(
                fontSize: 16.h,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              AppLocalizations.of(context)!.modifyExistingPillOrganiser,
              style: TextStyle(
                fontSize: 16.h,
              ),
            ),
            SizedBox(height: 16.h),
            Consumer<SelectedDeviceProvider>(
              builder: (context, selectedDeviceProv, _) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final isCurrentDevice =
                        selectedDeviceProv.device?.deviceID == device.deviceID;
                    final isDeviceReadOnly = !device.owner;

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 4.h),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFE8EFF4),
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0).r,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.name,
                                    style: TextStyle(
                                      fontSize: 16.h,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      if (isCurrentDevice) ...[
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.w,
                                            vertical: 2.h,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: const Color(0xffBED4D8),
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.r),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 8.w,
                                                height: 8.w,
                                                margin:
                                                    EdgeInsets.only(right: 6.w),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF7CAC7B),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              Text(
                                                AppLocalizations.of(context)!
                                                    .current,
                                                style: TextStyle(
                                                  fontSize: 12.h,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      const Color(0xff31454D),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isDeviceReadOnly) ...[
                                          SizedBox(width: 4.w),
                                          Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xffF8F9FC),
                                                borderRadius:
                                                    BorderRadius.circular(50).r,
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8.w,
                                                  vertical: 2.h),
                                              child: Text(
                                                AppLocalizations.of(context)!
                                                    .viewOnly,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xff363F72),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ))
                                        ],
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isCurrentDevice) ...[
                                  IconButton(
                                    padding: const EdgeInsets.all(12),
                                    icon: Icon(
                                      PhosphorIcons.arrows_left_right,
                                      size: 24.h,
                                    ),
                                    color: const Color(0xFF206B8B),
                                    onPressed: () {
                                      selectedDeviceProv.selectDevice(device);
                                    },
                                    style: ButtonStyle(
                                      shape: MaterialStateProperty.all<
                                          OutlinedBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.r),
                                        ),
                                      ),
                                      side: MaterialStateProperty.resolveWith<
                                          BorderSide>(
                                        (Set<MaterialState> states) {
                                          return const BorderSide(
                                            color: Color(0xFF8BCAE5),
                                            width: 2.0,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                ],
                                IconButton(
                                  padding: const EdgeInsets.all(12),
                                  icon: SvgPicture.asset(
                                    'lib/assets/SVG/pencilLight.svg',
                                    width: 24.w,
                                    height: 24.h,
                                  ),
                                  onPressed: isDeviceReadOnly
                                      ? null
                                      : () {
                                          showMaterialModalBottomSheet(
                                            context: context,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) =>
                                                SingleDeviceWidget(
                                              showAddDeviceSection: false,
                                              device: device,
                                              isModal: true,
                                            ),
                                          );
                                        },
                                  color: isDeviceReadOnly
                                      ? const Color(0xFF9BAEB6)
                                      : const Color(0xFF206B8B),
                                  style: ButtonStyle(
                                    backgroundColor: isDeviceReadOnly
                                        ? MaterialStateProperty.all<Color>(
                                            const Color(0xFFE3EAEE))
                                        : MaterialStateProperty.all<Color>(
                                            Colors.transparent),
                                    shape: MaterialStateProperty.all<
                                        OutlinedBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                      ),
                                    ),
                                    side: MaterialStateProperty.resolveWith<
                                        BorderSide>(
                                      (Set<MaterialState> states) {
                                        return BorderSide(
                                          color: isDeviceReadOnly
                                              ? const Color(0xFFCFDDE3)
                                              : Color(0xFF8BCAE5),
                                          width: 2.0,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            SizedBox(height: 28.h),
            AddDevice(
              onJoinExistingDevice: () {
                print("join existing device");
              },
            ),
            SizedBox(height: 28.h),
          ],
        ),
      ),
    );
  }
}

class SingleDeviceWidget extends StatefulWidget {
  final DeviceUser? device;
  final bool showAddDeviceSection;
  final bool isModal;

  const SingleDeviceWidget({
    super.key,
    required this.device,
    required this.showAddDeviceSection,
    this.isModal = false,
  });

  @override
  State<SingleDeviceWidget> createState() => _SingleDeviceWidgetState();
}

class _SingleDeviceWidgetState extends State<SingleDeviceWidget> {
  int _selectedButtonIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.isModal
          ? EdgeInsets.only(top: 60.h)
          : EdgeInsets.only(bottom: 60.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12.0).r,
          topRight: const Radius.circular(12.0).r,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.only(
              top: 24.h,
              bottom: 12.h,
              left: 20.w,
              right: 20.w,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.isModal)
                  IconButton(
                    icon: Icon(
                      PhosphorIcons.x,
                      size: 24.h,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Text(
                    widget.device?.name ??
                        AppLocalizations.of(context)!.loadingState,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 30.h,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: SvgPicture.asset(
                      'lib/assets/SVG/pencilLight.svg',
                      width: 24.w,
                      height: 24.h,
                    ),
                    color: Theme.of(context).primaryColor,
                    onPressed: () {
                      changeName(context);
                    },
                  ),
                ]),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              top: 12.h,
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
                            PhosphorIcons.gear,
                            size: 18.h,
                          ),
                          value: 0,
                          label: Text(
                            AppLocalizations.of(context)!.settings,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          )),
                      ButtonSegment(
                        icon: Icon(
                          PhosphorIcons.bell_simple_ringing,
                          size: 18.h,
                        ),
                        value: 1,
                        label: Text(
                          AppLocalizations.of(context)!.notifications,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                    selected: {_selectedButtonIndex},
                    selectedIcon: _selectedButtonIndex == 0
                        ? Icon(
                            PhosphorIcons.gear,
                            size: 18.h,
                          )
                        : Icon(
                            PhosphorIcons.bell_simple_ringing,
                            size: 18.h,
                          ),
                    onSelectionChanged: (Set newSelection) {
                      setState(() {
                        _selectedButtonIndex = newSelection.first;
                      });
                    },
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all<OutlinedBorder>(
                          RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadiusDirectional.circular(8.r))),
                      side: MaterialStateProperty.resolveWith<BorderSide>(
                          (Set<MaterialState> states) {
                        return BorderSide(
                            color: const Color(0xFFBFD2DB), width: 2.h);
                      }),
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return const Color(0xFFE8EFF4);
                        }
                        return Colors.white;
                      }),
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                        EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                  child: _selectedButtonIndex == 0
                      ? ScheduleEntry(
                          showAddDeviceSection: widget.showAddDeviceSection)
                      : const NotificationsSettings()),
            ),
          )
        ],
      ),
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
