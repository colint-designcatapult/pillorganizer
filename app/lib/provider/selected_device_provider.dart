import 'dart:async';

import 'package:app/api/device.dart';
import 'package:app/provider/device_provider.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectedDeviceProvider with ChangeNotifier {
  List<DeviceUser>? _devices;
  DeviceUser? get device => _selectedDevice;
  DeviceUser? _selectedDevice;
  int? _prevID;
  int? _selectedID;
  static const String lastSelectedKeyName = "selectedDeviceID";

  SelectedDeviceProvider() {
    _loadSaved();
  }

  SelectedDeviceProvider update(List<DeviceUser>? deviceList) {
    if (_devices != deviceList) {
      _devices = deviceList;
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
      final deviceProvider =
          Provider.of<DeviceProvider>(context, listen: false);
      await deviceProvider.removeDevice(_selectedDevice!.deviceID);
      if (context.mounted) {
        if (deviceProvider.devices != null &&
            deviceProvider.devices!.isNotEmpty) {
          selectDevice(deviceProvider.devices!.first);
        }
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/index', (route) => false);
      }
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
}
