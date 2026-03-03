import 'package:app/api/api.dart';
import 'package:app/api/device.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'schedule_provider.g.dart';

@riverpod
class Schedule extends _$Schedule {
  @override
  FutureOr<SimpleScheduleDTO> build() async {
    final device = ref.watch(activeDeviceProvider);
    if (device == null) return SimpleScheduleDTO();

    return client.getDispenseTimes(device.deviceID);
  }

  Future<void> load(int deviceID) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return client.getDispenseTimes(deviceID);
    });
  }

  Future<void> updateTime(DayPeriod period, TimeOfDay time, int deviceID) async {
    final current = state.asData?.value ?? SimpleScheduleDTO();
    final secondsFrom00 = time.hour * 3600 + time.minute * 60;
    
    final newSchedule = period == DayPeriod.am
        ? SimpleScheduleDTO(
            amID: current.amID,
            amSecondsFrom00: secondsFrom00,
            pmID: current.pmID,
            pmSecondsFrom00: current.pmSecondsFrom00,
          )
        : SimpleScheduleDTO(
            amID: current.amID,
            amSecondsFrom00: current.amSecondsFrom00,
            pmID: current.pmID,
            pmSecondsFrom00: secondsFrom00,
          );
    
    await updateSchedule(newSchedule);
  }

  Future<void> updateSchedule(SimpleScheduleDTO newSchedule) async {
    final device = ref.read(activeDeviceProvider);
    if (device == null) return;

    await client.updateDispenseTimes(device.deviceID, newSchedule);
    state = AsyncValue.data(newSchedule);
  }
}
