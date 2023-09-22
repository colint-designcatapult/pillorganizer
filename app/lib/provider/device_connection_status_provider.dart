import 'dart:async';
import 'package:app/api/device.dart';
import 'package:flutter/material.dart';

class DeviceConnectionStatusProvider extends ChangeNotifier {
  DeviceConnectionStatus _value = DeviceConnectionStatus.undefined;
  DeviceConnectionStatus get value => _value;
  Timer? _stateTimer;
  int _prevStateHash = 0;
  int? _prevID;

  DeviceConnectionStatusProvider() {
    value = DeviceConnectionStatus.loading;
  }

  set value(DeviceConnectionStatus newVal) {
    if (newVal == _value) {
      return;
    }

    _value = newVal;
    if (newVal == DeviceConnectionStatus.loading && _stateTimer == null) {
      _stateTimer = Timer(const Duration(seconds: 15), () {
        if (_value == DeviceConnectionStatus.loading) {
          value = DeviceConnectionStatus.offline;
        }
      });
    } else if (newVal == DeviceConnectionStatus.online) {
      _stateTimer?.cancel();
      _stateTimer = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    _stateTimer?.cancel();
  }

  DeviceConnectionStatusProvider update(DeviceState? state) {
    if (state != null) {
      if (_prevStateHash == state.hashCode) {
        return this;
      }
      _prevStateHash = state.hashCode;

      if (_prevID != state.id) {
        _stateTimer = null;
        _prevID = state.id;
      }

      if (isOnlineFromLastSeen(state.lastSync)) {
        value = DeviceConnectionStatus.online;
      } else {
        value = DeviceConnectionStatus.loading;
      }
    } else {
      value = DeviceConnectionStatus.loading;
    }
    return this;
  }
}
