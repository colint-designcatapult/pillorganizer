import 'dart:io';


import 'package:app/provider/device_connection_status_provider.dart';
import 'package:app/provider/device_provider.dart';
import 'package:app/provider/device_state_provider.dart';
import 'package:app/widgets/switch_device.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:app/apiv2/models/device.dart';
import '../provider/selected_device_provider.dart';


IconData batteryIcon(BatteryState bat) {
  if (!bat.batteryConnected) {
    return PhosphorIconsRegular.batteryWarning;
  } else if (bat.charging) {
    return PhosphorIconsRegular.batteryCharging;
  } else if (bat.percent < 5) {
    return PhosphorIconsRegular.batteryEmpty;
  } else if (bat.percent < 20) {
    return PhosphorIconsRegular.batteryLow;
  } else if (bat.percent <= 100) {
    return PhosphorIconsRegular.batteryFull;
  }
  return PhosphorIconsRegular.batteryWarning;
}

String batteryText(BatteryState bat) {
  if (!bat.batteryConnected) {
    return "No battery";
  } else if (bat.charging) {
    return "Charging";
  } else if (!bat.charging && bat.chargerConnected) {
    return "Not charging";
  } else if (bat.percent < 5) {
    return "Critical low battery";
  } else if (bat.percent < 20) {
    return "Low battery";
  }
  return "";
}

class DeviceInfoHeader extends ConsumerWidget {
  const DeviceInfoHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDevice = ref.watch(activeDeviceProvider);
    final deviceStateAsync = ref.watch(deviceStateProvider);
    final deviceListAsync = ref.watch(deviceListProvider);
    final deviceConnectionStatus = ref.watch(deviceConnectionStatusProvider);

    DeviceState? deviceState = deviceStateAsync.value;
    int numberOfDevices = deviceListAsync.value?.length ?? 0;
    bool isOwner = activeDevice?.primaryUser ?? false;
    String deviceName = activeDevice?.name ??
        AppLocalizations.of(context)!.loadingState;

    String? tenantName = activeDevice?.showTenant == true
        ? activeDevice?.tenantName
        : null;

    /*
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
    }*/

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
            onTap: () => _showConnectionStatus(context, activeDevice),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(deviceName,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24.h,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                width: 2.h,
                                color: true
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
        if(tenantName != null) Column(
          children: [
            Row(
              children: [

                Text(tenantName,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.h,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1
                )
              ],
            )
          ],
        ),
        if (false)
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
            children: [SizedBox(height: 8.h), const SwitchDevice()],
          ),
        if (deviceState?.battery != null && deviceConnectionStatus == DeviceConnectionStatus.online)
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
                  batteryIcon(deviceState!.battery!),
                  size: 20.h,
                  color: Colors.white,
                ),
                SizedBox(width: 8.w),
                if (deviceState!.battery!.chargerConnected)
                  Icon(
                    PhosphorIconsRegular.plugsConnected,
                    size: 20.h,
                    color: Colors.white,
                  ),
                SizedBox(width: 8.w),
                Text(
                  batteryText(deviceState!.battery!),
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
  }

  void _showConnectionStatus(
    BuildContext context,
    DeviceMetadata? activeDevice,
  ) {
    showDialog(
        context: context,
        builder: (_) =>
               Dialog(
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
                                        "wrlText",
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
                                        "bleText",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  ],
                                ))),
                        SizedBox(height: 16.h),
                        if (activeDevice != null) ...[
                          if (activeDevice.id.isNotEmpty)
                            Text(
                              'Device ID: ${activeDevice.id}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF6B7280),
                                fontSize: 11.h,
                              ),
                            ),
                          if (activeDevice.serialNo != null && activeDevice.serialNo!.isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Text(
                              'Serial: ${activeDevice.serialNo}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF6B7280),
                                fontSize: 11.h,
                              ),
                            ),
                          ],
                        ],
                        if (false)
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
                                          //AppSettings.openAppSettings();
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
                  )
               )
            );
  }
}
