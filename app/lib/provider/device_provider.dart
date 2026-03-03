import 'package:app/api/api.dart';
import 'package:app/api/device.dart';
import 'package:app/service/time_service.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class DeviceProvider with ChangeNotifier {
  List<DeviceUser> _devices = [];
  bool _isLoading = false;
  bool _isUpdatingTimezone = false;
  bool _isUpdatingName = false;
  bool _isUpdatingNotifications = false;
  bool _isUpdatingAllNotifications = false;
  bool _isRemovingDevice = false;

  List<DeviceUser> get devices => _devices;
  bool get isLoading => _isLoading;
  bool get isUpdatingTimezone => _isUpdatingTimezone;
  bool get isUpdatingName => _isUpdatingName;
  bool get isUpdatingNotifications => _isUpdatingNotifications;
  bool get isUpdatingAllNotifications => _isUpdatingAllNotifications;
  bool get isRemovingDevice => _isRemovingDevice;

  Future<void> loadDevices() async {
    _isLoading = true;
    notifyListeners();

    try {
      _devices = await _fetchDevices();
    } catch (error) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadDevices();
  }

  Future<List<DeviceUser>> _fetchDevices() {
    return Future.value(List.of({DeviceUser(
        id: 0,
        deviceID: 0,
        deviceClass: '',
        name: '',
        serialNo: 0,
        isOnline: false,
        primaryUser: false,
        owner: false,
        notifications: false,
        timezone: null
    )}));
  }

  Future<DeviceUser> updateDeviceName(int deviceID, String newName) async {
    DeviceUser? currentDevice =
        _devices.firstWhereOrNull((device) => device.deviceID == deviceID);

    if (currentDevice != null && currentDevice.name == newName) {
      return currentDevice;
    }

    _isUpdatingName = true;
    notifyListeners();

    try {
      final updatedDevice = await deviceRepo.update(deviceID, name: newName);
      _updateDeviceInList(updatedDevice);
      return updatedDevice;
    } catch (error) {
      rethrow;
    } finally {
      _isUpdatingName = false;
      notifyListeners();
    }
  }

  Future<DeviceUser> updateDeviceTimeZone(
      int deviceID, TimeZoneLocation newTZ) async {
    DeviceUser? currentDevice =
        _devices.firstWhereOrNull((device) => device.deviceID == deviceID);

    if (currentDevice != null && currentDevice.timezone?.name == newTZ.name) {
      return currentDevice;
    }

    _isUpdatingTimezone = true;
    notifyListeners();

    try {
      final updatedDevice = await deviceRepo.update(deviceID, timezone: newTZ);
      _updateDeviceInList(updatedDevice);
      return updatedDevice;
    } catch (error) {
      rethrow;
    } finally {
      _isUpdatingTimezone = false;
      notifyListeners();
    }
  }

  Future<DeviceUser> updateDeviceNotifications(
      int deviceID, bool notifications) async {
    DeviceUser? currentDevice =
        _devices.firstWhereOrNull((device) => device.deviceID == deviceID);

    if (currentDevice != null && currentDevice.notifications == notifications) {
      return currentDevice;
    }

    _isUpdatingNotifications = true;
    notifyListeners();

    try {
      final updatedDevice =
          await deviceRepo.update(deviceID, notifications: notifications);
      _updateDeviceInList(updatedDevice);
      return updatedDevice;
    } catch (error) {
      rethrow;
    } finally {
      _isUpdatingNotifications = false;
      notifyListeners();
    }
  }

  Future<void> updateNotificationsForAllDevices(bool notifications) async {
    _isUpdatingAllNotifications = true;
    notifyListeners();

    try {
      if (_devices.isNotEmpty) {
        for (var device in _devices) {
          final updatedDevice = await deviceRepo.update(device.deviceID,
              notifications: notifications);
          _updateDeviceInList(updatedDevice);
        }
      }
    } catch (error) {
      rethrow;
    } finally {
      _isUpdatingAllNotifications = false;
      notifyListeners();
    }
  }

  Future<void> removeDevice(int deviceID) async {
    _isRemovingDevice = true;
    notifyListeners();

    try {
      await client.removeDevice(deviceID);
      _devices.removeWhere((device) => device.deviceID == deviceID);
    } catch (error) {
      rethrow;
    } finally {
      _isRemovingDevice = false;
      notifyListeners();
    }
  }

  void _updateDeviceInList(DeviceUser updatedDevice) {
    if (_devices.isNotEmpty) {
      final index = _devices
          .indexWhere((device) => device.deviceID == updatedDevice.deviceID);
      if (index != -1) {
        _devices[index] = updatedDevice;
      }
    }
  }
}
