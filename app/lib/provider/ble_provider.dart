import 'dart:async';
import 'package:app/service/device_bluetooth_service.dart';
import 'package:flutter/foundation.dart';
import '../api/device.dart';

enum BLEConnectionStatus { suppressed, disconnected, connecting, connected }

class DeviceBluetoothProvider with ChangeNotifier {
  final DeviceBluetoothController _controller = DeviceBluetoothController();
  BLEConnectionStatus _status = BLEConnectionStatus.disconnected;
  BLEConnectionStatus get status => _status;
  Timer? _heartbeat;

  DeviceBluetoothProvider({DeviceUser? selectedDevice}) {
    _controller.onDisconnect = () {
      _status = BLEConnectionStatus.disconnected;
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
    } else if (status == BLEConnectionStatus.disconnected) {
      _connect();
    }
  }

  Future<void> _connect() async {
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
    return "PROV_${hex.substring(hex.length - 6).toUpperCase()}";
  }
}
