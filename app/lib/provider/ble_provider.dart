import 'dart:async';
import 'dart:io';
import 'package:app/service/device_bluetooth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../api/device.dart';

enum BLEConnectionStatus {
  suppressed,
  disconnected,
  connecting,
  connected,
  missingPermission
}

class DeviceBluetoothProvider with ChangeNotifier {
  final DeviceBluetoothController _controller = DeviceBluetoothController();
  BLEConnectionStatus _status = BLEConnectionStatus.disconnected;
  BLEConnectionStatus get status => _status;
  int? get batteryLevel => _controller.batteryLevel;
  bool? get batteryCharging => _controller.batteryCharging;
  Timer? _heartbeat;

  DeviceBluetoothProvider({DeviceUser? selectedDevice}) {
    _controller.onDisconnect = () {
      if (_status != BLEConnectionStatus.suppressed) {
        _status = BLEConnectionStatus.disconnected;
      }
      notifyListeners();
    };
    createDevice(selectedDevice);
    _status = BLEConnectionStatus.suppressed;
  }

  void _resetTimer() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 10), (timer) {
      _tick();
    });
  }

  Future<void> suppress() async {
    await _controller.disconnect();
    _status = BLEConnectionStatus.suppressed;
    notifyListeners();
  }

  void unsuppress() {
    if (_status == BLEConnectionStatus.suppressed) {
      _status = BLEConnectionStatus.disconnected;
      notifyListeners();
      _resetTimer();
    }
  }

  void _tick() {
    print("BLE - tick status: $status");
    if (status == BLEConnectionStatus.suppressed) {
      _controller.disconnect();
    } else if (status == BLEConnectionStatus.connected) {
      _controller.sync();
      _status = BLEConnectionStatus.connected;
      notifyListeners();
    } else if (status == BLEConnectionStatus.disconnected ||
        status == BLEConnectionStatus.missingPermission) {
      _connect();
    }
  }

  Future<bool> _missingBlePermission() async {
    if (Platform.isIOS) {
      return !await _controller.checkBluetoothState();
    }
    await Permission.location.request();
    await Permission.bluetoothScan.request();
    PermissionStatus locationStatus = await Permission.location.status;
    PermissionStatus bleScanStatus = await Permission.bluetoothScan.status;
    return !await _controller.checkBluetoothState() ||
        locationStatus == PermissionStatus.denied ||
        locationStatus == PermissionStatus.permanentlyDenied ||
        bleScanStatus == PermissionStatus.denied ||
        bleScanStatus == PermissionStatus.permanentlyDenied;
  }

  Future<void> _connect() async {
    if (await _missingBlePermission()) {
      _status = BLEConnectionStatus.missingPermission;
      notifyListeners();
    } else {
      _status = BLEConnectionStatus.connecting;
      notifyListeners();

      if (await _controller.find()) {
        _status = BLEConnectionStatus.connected;
        notifyListeners();
      } else {
        _status = BLEConnectionStatus.disconnected;
        notifyListeners();
      }
    }
  }

  void createDevice(DeviceUser? newUser) {
    if (newUser != null) {
      _createDevice(_getDeviceName(newUser), newUser.deviceID);
    }
  }

  Future<void> _createDevice(String deviceName, int deviceID) async {
    _status = BLEConnectionStatus.suppressed;
    notifyListeners();
    await _controller.disconnect();
    _controller.setTarget(deviceName, deviceID);
  }

  void changeDevice(DeviceUser? newUser) {
    if (newUser != null) {
      _changeDevice(_getDeviceName(newUser), newUser.deviceID);
    } else {
      _controller.disconnect();
    }
  }

  Future<void> _changeDevice(String deviceName, int deviceID) async {
    _status = BLEConnectionStatus.disconnected;
    notifyListeners();
    await _controller.disconnect();
    _controller.setTarget(deviceName, deviceID);
    _resetTimer();
  }

  String _getDeviceName(DeviceUser d) {
    String hex = d.serialNo.toRadixString(16);
    return "CAB_${hex.substring(hex.length - 6).toUpperCase()}";
  }
}
