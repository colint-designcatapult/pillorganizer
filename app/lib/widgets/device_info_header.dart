import 'dart:io';

import 'package:app/api/device.dart';
import 'package:app/provider/ble_provider.dart';
import 'package:app/provider/device_provider.dart';
import 'package:app/service/device_information_service.dart';
import 'package:app/widgets/switch_device.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../provider/selected_device_provider.dart';

class DeviceInfoHeader extends StatelessWidget {
  const DeviceInfoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer4<SelectedDeviceProvider, DeviceBluetoothProvider,
            DeviceStateProvider, DeviceProvider>(
        builder: (_, selectedDeviceProvider, bleProvider, deviceStateProvider,
            deviceProvider, __) {
      int? batteryLevel;
      bool? batteryCharging;
      DeviceState? deviceState = deviceStateProvider.value;
      int numberOfDevices = deviceProvider.devices.length;
      bool isOwner = selectedDeviceProvider.device?.owner ?? false;
      String deviceName = selectedDeviceProvider.device?.name ??
          AppLocalizations.of(context)!.loadingState;

      bool isMissingPermission =
          bleProvider.status == BLEConnectionStatus.missingPermission;
      bool isConnecting = bleProvider.status == BLEConnectionStatus.connecting;

      if (wifiIsConnected(context, bleProvider.status) && deviceState != null) {
        batteryLevel = deviceState.battery;
        batteryCharging = deviceState.charging;
      } else {
        batteryLevel = bleProvider.batteryLevel;
        batteryCharging = bleProvider.batteryCharging;
      }

      if (deviceState == null) {
        return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                Text(AppLocalizations.of(context)!.welcome,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 36.h,
                        fontWeight: FontWeight.w700)),
              ],
            ));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
              onTap: () => _showConnectionStatus(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(deviceName,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24.h,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1),
                        SizedBox(width: 8.w),
                        Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  width: 2.h,
                                  color: isMissingPermission
                                      ? Colors.red
                                      : const Color.fromARGB(0, 0, 0, 0))),
                          child:
                              Icon(Icons.info, color: Colors.white, size: 16.h),
                        ),
                      ],
                    ),
                  ),
                  if (!isOwner) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FC),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.viewOnly,
                        style: TextStyle(
                          color: const Color(0xFF363F72),
                          fontSize: 12.h,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ]
                ],
              )),
          if (isConnecting)
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
                    PhosphorIconsRegular.bluetooth,
                    size: 20.h,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8.w),
                ]),
              ],
            ),
          if (numberOfDevices > 1)
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
  }

  void _showConnectionStatus(
    BuildContext context,
  ) {
    showDialog(
        context: context,
        builder: (_) =>
            Consumer<DeviceBluetoothProvider>(builder: (_, bleProv, __) {
              String bleText = bluetoothText(context, bleProv.status);
              String wrlText = wirelessText(context, bleProv.status);
              bool isMissingPermission =
                  bleProv.status == BLEConnectionStatus.missingPermission;
              return Dialog(
                  insetPadding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
                                PhosphorIconsBold.x,
                                size: 24.h,
                                color: const Color(0XFF101828),
                              )),
                        ),
                        Column(
                          children: [
                            Icon(
                              PhosphorIconsFill.hardDrives,
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
                                padding:
                                    EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
                                child: Row(
                                  children: [
                                    Icon(
                                      PhosphorIconsRegular.wifiHigh,
                                      size: 24.h,
                                      color: const Color(0xFF191B1D),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Text(
                                        wrlText,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                                padding:
                                    EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
                                child: Row(
                                  children: [
                                    Icon(
                                      PhosphorIconsRegular.bluetooth,
                                      size: 24.h,
                                      color: const Color(0xFF191B1D),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Text(
                                        bleText,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  ],
                                ))),
                        if (isMissingPermission)
                          SizedBox(
                              height: 125.w,
                              child: Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 10.w),
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                    Padding(
                                      padding: EdgeInsets.all(6.h),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          AppSettings.openAppSettings();
                                        },
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .openSettings,
                                            style: Theme.of(context)
                                                .textTheme
                                                .displaySmall),
                                      ),
                                    ),
                                  ])))
                      ],
                    ),
                  ));
            }));
  }
}
