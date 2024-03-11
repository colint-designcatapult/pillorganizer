import 'package:app/api/device.dart';
import 'package:app/api/api.dart';
import 'package:app/service/time_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';

class SelectedDeviceProvider with ChangeNotifier {
  List<DeviceUser>? _devices;
  DeviceUser? get device => _selectedDevice;
  DeviceUser? _selectedDevice;
  int? _prevID;
  int? _selectedID;
  static const String lastSelectedKeyName = "selectedDeviceID";
  bool isUpdatedTimeZoneCalled = false;

  SelectedDeviceProvider() {
    _loadSaved();
  }

  SelectedDeviceProvider update(List<DeviceUser>? deviceList) {
    if (_devices != deviceList) {
      _devices = deviceList;
      isUpdatedTimeZoneCalled = false;
      if (_selectedID != null) {
        _selectDeviceByID(_selectedID!);
      } else if (deviceList != null && deviceList.isNotEmpty) {
        _selectDeviceByID(deviceList.first.deviceID);
      }
    }
    return this;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(lastSelectedKeyName)) {
      int? selected = prefs.getInt(lastSelectedKeyName);
      if (selected != null) {
        _selectDeviceByID(selected);
      }
    }
  }

  Future<void> _persistSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedID != null) {
      prefs.setInt(lastSelectedKeyName, _selectedID!);
    }
  }

  void selectDeviceByID(int deviceID) {
    if (_prevID != deviceID) {
      _selectDeviceByID(deviceID);
    }
  }

  void selectDevice(DeviceUser du) {
    _selectDeviceByID(du.deviceID);
  }

  Future<void> removeDevice(context) async {
    try {
      await client.removeDevice(_selectedDevice!.deviceID).then((value) async {
        if (context.mounted) {
          _devices = await deviceRepo.myDevices();
          selectDevice(_devices!.first);
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/index', (route) => false);
        }
      });
    } catch (error) {
      rethrow;
    }
  }

  void _selectDeviceByID(int deviceID) {
    _prevID = _selectedID;
    _selectedID = deviceID;
    _selectedDevice =
        _devices?.firstWhereOrNull((element) => element.deviceID == deviceID);
    _persistSaved();
    notifyListeners();
  }

  Future<void> updateName(String newName) async {
    var newDevice =
        await deviceRepo.update(_selectedDevice!.deviceID, name: newName);
    _selectedDevice = newDevice;
    notifyListeners();
  }

  Future<void> updateTimeZone(TimeZoneLocation newTZ) async {
    var newDevice =
        await deviceRepo.update(_selectedDevice!.deviceID, timezone: newTZ);
    _selectedDevice = newDevice;
    isUpdatedTimeZoneCalled = true;
    notifyListeners();
  }

  Future<void> updateNotifications(bool notifications) async {
    var newDevice = await deviceRepo.update(_selectedDevice!.deviceID,
        notifications: notifications);
    notifyListeners();
    _selectedDevice = newDevice;
  }

  Future<void> updateNotificationsForAll(bool notifications) async {
    if (_devices != null) {
      for (var device in _devices!) {
        var newDevice = await deviceRepo.update(device.deviceID,
            notifications: notifications);
        notifyListeners();
        _selectedDevice = newDevice;
      }
    }
  }
}
