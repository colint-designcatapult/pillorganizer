import 'package:app/api/device.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectedDeviceProvider with ChangeNotifier {
  List<DeviceUser>? _devices;
  int? _selectedID;
  static const String lastSelectedKeyName = "selectedDeviceID";

  DeviceUser? get device =>
      _devices?.firstWhereOrNull((device) => device.deviceID == _selectedID);

  SelectedDeviceProvider() {
    _loadSaved();
  }

  SelectedDeviceProvider update(List<DeviceUser>? deviceList) {
    _devices = deviceList;
    _ensureValidSelection();
    notifyListeners();
    return this;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(lastSelectedKeyName)) {
      int? selected = prefs.getInt(lastSelectedKeyName);
      if (selected != null) {
        _selectedID = selected;
        notifyListeners();
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
    if (_selectedID != deviceID) {
      _selectedID = deviceID;
      _persistSaved();
      notifyListeners();
    }
  }

  void selectDevice(DeviceUser deviceUser) {
    selectDeviceByID(deviceUser.deviceID);
  }

  void _ensureValidSelection() {
    if (_selectedID == null || !_isSelectedDeviceValid()) {
      _selectFirstAvailableDevice();
    }
  }

  bool _isSelectedDeviceValid() {
    return _devices?.any((device) => device.deviceID == _selectedID) ?? false;
  }

  void _selectFirstAvailableDevice() {
    if (_devices != null && _devices!.isNotEmpty) {
      _selectedID = _devices!.first.deviceID;
      _persistSaved();
    } else {
      _selectedID = null;
    }
  }
}
