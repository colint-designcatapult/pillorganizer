import 'dart:io';

import 'package:app/api/device.dart';
import 'package:app/provider/ble_provider.dart';
import 'package:app/service/device_information_service.dart';
import 'package:app/widgets/switch_device.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../provider/selected_device_provider.dart';

class DeviceInfoHeader extends StatelessWidget {
  final bool deviceOffline;

  const DeviceInfoHeader({Key? key, required this.deviceOffline})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectedDeviceProvider>(builder: (_, selectedDevice, __) {
      return Consumer<DeviceBluetoothProvider>(builder: (_, bleProv, __) {
        int? batteryLevel;
        bool? batteryCharging;
        DeviceState? deviceState =
            Provider.of<DeviceStateProvider>(context, listen: false).value;
        bool isMissingPermission =
            bleProv.status == BLEConnectionStatus.missingPermission;
        var numberOfDevices =
            Provider.of<DeviceListProvider>(context, listen: false)
                .value
                ?.length;
        if (wifiIsConnected(context, bleProv) && deviceState != null) {
          batteryLevel = deviceState.battery;
          batteryCharging = deviceState.charging;
        } else {
          batteryLevel = bleProv.batteryLevel;
          batteryCharging = bleProv.batteryCharging;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
                onTap: () => _showConnectionStatus(
                    context, bleProv, isMissingPermission),
                child: Row(
                  children: [
                    Text(
                        selectedDevice.device?.name ??
                            AppLocalizations.of(context)!.loadingState,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24.h,
                            fontWeight: FontWeight.w600)),
                    SizedBox(width: 8.w),
                  ],
                )),
            if (deviceOffline &&
                bleProv.status == BLEConnectionStatus.connecting)
              Column(
                children: [
                  SizedBox(height: 8.h),
                  Row(children: [
                    SizedBox(
                        height: 16.h,
                        width: 16.w,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )),
                    SizedBox(width: 8.w),
                    Text(AppLocalizations.of(context)!.bluetoothConnecting,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white)),
                    SizedBox(width: 8.w),
                    Icon(
                      PhosphorIcons.bluetooth_fill,
                      size: 20.h,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8.w),
                  ]),
                ],
              ),
            if (numberOfDevices != null && numberOfDevices > 1)
              Column(
                children: [SizedBox(height: 8.h), SwitchDevice()],
              ),
            if (batteryLevel != null)
              Column(
                children: [
                  SizedBox(height: 8.h),
                  Row(children: [
                    Text(AppLocalizations.of(context)!.batteryLevel,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white)),
                    SizedBox(width: 8.w),
                    Icon(
                      batteryIcon(batteryLevel, batteryCharging),
                      size: 20.h,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "${batteryLevel.toString()} %",
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontSize: 14.h, color: Colors.white),
                    )
                  ]),
                ],
              )
            else
              SizedBox(height: 12.h),
          ],
        );
      });
    });
  }

  void _showConnectionStatus(BuildContext context,
      DeviceBluetoothProvider bleProv, bool isMissingPermission) {
    String bleText = bluetoothText(context, bleProv);
    const int maxLength = 30;
    showDialog(
      context: context,
      builder: (_) => Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Icon(
                        PhosphorIcons.x_bold,
                        size: 24.h,
                        color: const Color(0XFF101828),
                      )),
                ),
                Column(
                  children: [
                    Icon(
                      PhosphorIcons.hard_drives_fill,
                      size: 48.h,
                      color: const Color(0xFF206B8B),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  AppLocalizations.of(context)!.deviceInfo,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: const Color(0XFF101828)),
                ),
                SizedBox(height: 8.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text(
                    AppLocalizations.of(context)!.deviceInfoSubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 24.h),
                Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12).r,
                      border: Border.all(
                          color: const Color(0xFFBFD2DB), width: 2.w),
                      color: const Color(0xFFF1F3F6),
                    ),
                    height: 58.h,
                    child: Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIcons.wifi_high,
                              size: 24.h,
                              color: const Color(0xFF191B1D),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              wirelessText(context, bleProv),
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                          ],
                        ))),
                SizedBox(height: 12.h),
                Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12).r,
                      border: Border.all(
                          color: const Color(0xFFBFD2DB), width: 2.w),
                      color: const Color(0xFFF1F3F6),
                    ),
                    height: 58.h,
                    child: Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIcons.bluetooth_fill,
                              size: 24.h,
                              color: const Color(0xFF191B1D),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              bleText,
                              style: bleText.length > maxLength
                                  ? Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontSize: 13.h)
                                  : Theme.of(context).textTheme.bodyMedium,
                            )
                          ],
                        ))),
                if (isMissingPermission)
                  SizedBox(
                      height: 125.w,
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          child: Column(children: [
                            SizedBox(
                              height: 10.h,
                            ),
                            Text(
                                Platform.isIOS
                                    ? AppLocalizations.of(context)!
                                        .missingBlePermissionTextIos
                                    : AppLocalizations.of(context)!
                                        .missingBlePermissionTextAndroid,
                                style: Theme.of(context).textTheme.bodySmall),
                            Padding(
                              padding: EdgeInsets.all(6.h),
                              child: ElevatedButton(
                                onPressed: () {
                                  AppSettings.openAppSettings();
                                },
                                child: Text(
                                    AppLocalizations.of(context)!.openSettings,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall),
                              ),
                            ),
                          ])))
              ],
            ),
          )),
    );
  }
}
