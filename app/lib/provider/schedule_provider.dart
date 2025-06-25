import 'package:app/api/api.dart';
import 'package:app/api/device.dart';
import 'package:app/api/schedule.dart';
import 'package:flutter/material.dart';

class ScheduleProvider with ChangeNotifier {
  final Map<int, SimpleSchedule> _schedules = {};
  final Map<int, Future<SimpleSchedule?>> _futures = {};

  bool _isLoading = false;
  bool _isUpdatingSchedule = false;

  bool get isLoading => _isLoading;
  bool get isUpdatingSchedule => _isUpdatingSchedule;

  final ScheduleRepository repo = ScheduleRepository(client: client);

  ScheduleProvider update(DeviceUser? selected) {
    if (selected != null) {
      load(selected.deviceID);
    }
    return this;
  }

  ScheduleProvider(
      {SimpleSchedule? schedule, DeviceUser? selectedDevice, int? deviceID}) {
    if (schedule != null && deviceID != null) {
      _schedules[deviceID] = schedule;
    }
    if (selectedDevice != null) {
      load(selectedDevice.deviceID);
    } else if (deviceID != null) {
      load(deviceID);
    }
  }

  Future<SimpleSchedule?> load(int deviceID) async {
    if (_schedules.containsKey(deviceID)) {
      return _schedules[deviceID];
    }

    _isLoading = true;
    notifyListeners();

    try {
      final value = await repo.getDispenseTimes(deviceID);
      _schedules[deviceID] = value;
      _futures[deviceID] = Future.value(value);
      return value;
    } catch (error) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SimpleSchedule?> updateTime(
      DayPeriod period, TimeOfDay tod, int deviceID) async {
    _isUpdatingSchedule = true;
    notifyListeners();

    SimpleSchedule currentSchedule =
        _schedules[deviceID] ?? const SimpleSchedule();

    if (period == DayPeriod.am) {
      currentSchedule = currentSchedule.copyWith(
          am: currentSchedule.am?.copyWith(time: tod) ??
              DispenseTime(time: tod, period: DayPeriod.am));
    } else if (period == DayPeriod.pm) {
      currentSchedule = currentSchedule.copyWith(
          pm: currentSchedule.pm?.copyWith(time: tod) ??
              DispenseTime(time: tod, period: DayPeriod.pm));
    }

    try {
      final value = await repo.updateDispenseTimes(deviceID, currentSchedule);
      _schedules[deviceID] = value;
      _futures[deviceID] = Future.value(value);
      return value;
    } catch (error) {
      rethrow;
    } finally {
      _isUpdatingSchedule = false;
      notifyListeners();
    }
  }

  SimpleSchedule? getScheduleForDevice(int deviceID) {
    return _schedules[deviceID];
  }
}
