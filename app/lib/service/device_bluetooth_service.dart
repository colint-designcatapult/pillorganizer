import 'dart:convert';
import 'dart:io';

import 'package:app/api/api.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

//Read-Write chracteristic on all device that is used to communicate the bin states
const stateBinsState = '20ded876-5bf8-06b8-354c-759dae9d26c1';
//Read subscribable chracteristic that returns the device battery info (charging)
const stateBatteryInfo = '00002bed-0000-1000-8000-00805f9b34fb';
//Read subscribable chracteristic that returns the device battery level
const stateBatteryLevel = '00002a19-0000-1000-8000-00805f9b34fb';

class DeviceBluetoothController {
  final FlutterBluePlus _ble = FlutterBluePlus.instance;
  String? _target;
  int? _deviceID;
  BluetoothDevice? device;
  BluetoothCharacteristic? _stateChr;
  final int _timeoutTime = 60;
  Function? onDisconnect;
  int? batteryLevel;
  bool? batteryCharging;

  Future<bool> checkBluetoothState() async {
    return await _ble.isOn;
  }

  Future<void> disconnect() async {
    await _ble.stopScan();
    await device?.disconnect();

    device = null;
    _stateChr = null;
    onDisconnect?.call();
  }

  void setTarget(String deviceName, int deviceID) {
    _target = deviceName;
    _deviceID = deviceID;
  }

  void handleSyncData(List<int> data) {
    String encoded = base64Encode(data);
    client.deviceSync(_deviceID!, encoded).then((value) {
      _stateChr?.write(base64Decode(value).toList());
      return null;
    }).onError((error, stackTrace) {
      print("BLE - Err: $error");
    });
  }

  Future<bool> find() async {
    List scanResult =
        await _ble.startScan(timeout: Duration(seconds: _timeoutTime));
    for (ScanResult r in scanResult) {
      if (r.device.name == _target) {
        try {
          return await connectTo(r.device);
        } catch (e) {
          await disconnect();
          return false;
        }
      }
    }
    return device != null && _stateChr != null;
  }

  Future<bool> connectTo(BluetoothDevice device) async {
    await device.connect(timeout: const Duration(seconds: 20));
    this.device = device;

    await device.clearGattCache();
    if (!Platform.isIOS) {
      await device.requestMtu(512);
    }
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService svc in services) {
      for (BluetoothCharacteristic chr in svc.characteristics) {
        if (chr.uuid.toString() == stateBinsState) {
          _stateChr = chr;
        }

        if (chr.uuid.toString() == stateBatteryLevel) {
          chr.setNotifyValue(true).then((_) {
            chr.value.listen((value) {
              batteryLevel = value[0];
            });
          });
        }

        if (chr.uuid.toString() == stateBatteryInfo) {
          chr.setNotifyValue(true).then((_) {
            chr.value.listen((value) {
              batteryCharging = value[1] == 1;
            });
          });
        }
      }
    }

    return true;
  }

  Future<void> sync() async {
    bool isBleOn = await checkBluetoothState();
    if (isBleOn) {
      _stateChr?.read().then((value) => handleSyncData(value));
    } else {
      disconnect();
    }
  }
}
