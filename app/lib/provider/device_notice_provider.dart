import 'package:app/api/api.dart';
import 'package:app/api/device.dart';
import 'package:flutter/material.dart';

class DeviceNoticeProvider extends ChangeNotifier {
  DeviceNotice _value = DeviceNotice.none;
  DeviceNotice get value => _value;
  int? _deviceID;
  Future<void>? _reloadFuture;
  Future<void>? get reloadFuture => _reloadFuture;

  set value(DeviceNotice v) {
    if (v != _value) {
      _value = v;
      notifyListeners();
    }
  }

  DeviceNoticeProvider update(
      DeviceState? state, DeviceConnectionStatus status) {
    if (state != null) {
      if (_deviceID != state.id && _reloadFuture != null) {
        _reloadFuture = null;
        notifyListeners();
      }
      _deviceID = state.id;
    }

    if (status == DeviceConnectionStatus.offline) {
      value = DeviceNotice.disconnected;
    } else if (status == DeviceConnectionStatus.online &&
        (state?.dosePeriods.isEmpty ?? true)) {
      value = DeviceNotice.empty;
    } else {
      value = DeviceNotice.none;
    }
    return this;
  }

  void reload() {
    if (_deviceID != null) {
      _reloadFuture = client.reload(_deviceID!);
      notifyListeners();
    }
  }
}
