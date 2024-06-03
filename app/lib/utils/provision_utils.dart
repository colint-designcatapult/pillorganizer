import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';

class ProvisionUtils {
  static Future<bool> checkDeviceBluetoothIsOn() async {
    FlutterBluePlus bluetooth = FlutterBluePlus.instance;
    return await bluetooth.isOn;
  }

  static Future<bool> missingProvisionPermission() async {
    if (Platform.isIOS) {
      return !await checkDeviceBluetoothIsOn();
    }
    await Permission.location.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    PermissionStatus locationStatus = await Permission.location.status;
    PermissionStatus bleScanStatus = await Permission.bluetoothScan.status;
    return !await checkDeviceBluetoothIsOn() ||
        locationStatus == PermissionStatus.denied ||
        locationStatus == PermissionStatus.permanentlyDenied ||
        bleScanStatus == PermissionStatus.denied ||
        bleScanStatus == PermissionStatus.permanentlyDenied;
  }
}
