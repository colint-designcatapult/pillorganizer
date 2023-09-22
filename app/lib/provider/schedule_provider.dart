import 'package:app/api/api.dart';
import 'package:app/api/device.dart';
import 'package:app/api/schedule.dart';
import 'package:flutter/material.dart';

class ScheduleProvider with ChangeNotifier {
  SimpleSchedule? get schedule => _schedule;
  SimpleSchedule? _schedule;
  Future<SimpleSchedule?>? get future => _future;
  Future<SimpleSchedule?>? _future;
  int? deviceID;

  @override
  void dispose() {
    super.dispose();
  }

  final ScheduleRepository repo = ScheduleRepository(client: client);

  ScheduleProvider update(DeviceUser? selected) {
    if (selected != null) {
      load(selected.deviceID);
    }
    return this;
  }

  ScheduleProvider(
      {SimpleSchedule? schedule, DeviceUser? selectedDevice, int? deviceID}) {
    _schedule = schedule;
    if (selectedDevice != null) {
      load(selectedDevice.deviceID);
    } else if (deviceID != null) {
      load(deviceID!); // a voir maybe delete
    }
  }

  Future<SimpleSchedule?> load(int deviceID) {
    this.deviceID = deviceID;
    var resp = repo.getDispenseTimes(deviceID).then((value) {
      _schedule = value;
      notifyListeners();
      return _schedule;
    });
    _future = resp;
    notifyListeners();
    return resp;
  }

  Future<SimpleSchedule?> updateTime(DayPeriod period, TimeOfDay tod) {
    _schedule ??= const SimpleSchedule();
    if (period == DayPeriod.am) {
      _schedule = _schedule?.copyWith(
          am: _schedule?.am?.copyWith(time: tod) ??
              DispenseTime(time: tod, period: DayPeriod.am));
    } else if (period == DayPeriod.pm) {
      _schedule = _schedule?.copyWith(
          pm: _schedule?.pm?.copyWith(time: tod) ??
              DispenseTime(time: tod, period: DayPeriod.pm));
    }
    return repo.updateDispenseTimes(deviceID!, _schedule!).then((value) {
      _schedule = value;
      notifyListeners();
      return value;
    });
  }
}
