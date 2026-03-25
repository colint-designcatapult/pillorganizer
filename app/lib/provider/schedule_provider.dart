import 'package:app/apiv2/models/device.dart';
import 'package:app/apiv2/models/dto.dart';
import 'package:app/apiv2/models/schedule.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/provider/tenant_providers.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'schedule_provider.g.dart';

@riverpod
class Schedule extends _$Schedule {
  @override
  FutureOr<SimpleSchedule> build() async {
    final device = ref.watch(activeDeviceProvider);
    if (device == null) return const SimpleSchedule();

    final client = ref.watch(activeTenantClientProvider);
    if (client == null) return const SimpleSchedule();

    final dto = await client.getSchedule(device.id);
    return _dtoToSchedule(dto);
  }

  Future<void> load(String deviceID) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(activeTenantClientProvider);
      if (client == null) return const SimpleSchedule();
      final dto = await client.getSchedule(deviceID);
      return _dtoToSchedule(dto);
    });
  }

  Future<void> updateTime(DayPeriod period, TimeOfDay time, String deviceID) async {
    final current = state.asData?.value ?? const SimpleSchedule();

    final newSchedule = period == DayPeriod.am
        ? SimpleSchedule(
            am: DispenseTime(time: time, period: DayPeriod.am),
            pm: current.pm,
          )
        : SimpleSchedule(
            am: current.am,
            pm: DispenseTime(time: time, period: DayPeriod.pm),
          );

    await _postSchedule(deviceID, newSchedule);
  }

  Future<void> _postSchedule(String deviceID, SimpleSchedule newSchedule) async {
    final client = ref.read(activeTenantClientProvider);
    if (client == null) return;

    final request = _scheduleToRequest(newSchedule);
    await client.setSchedule(deviceID, request);
    state = AsyncValue.data(newSchedule);
  }

  SimpleSchedule _dtoToSchedule(DeviceScheduleStateDto dto) {
    final schedule = dto.currentSchedule;
    if (schedule == null) return const SimpleSchedule();

    DosePeriodDto? amBin;
    DosePeriodDto? pmBin;
    for (final bin in schedule.bins) {
      final hour = int.parse(bin.time.split(':')[0]);
      if (hour < 12 && amBin == null) amBin = bin;
      if (hour >= 12 && pmBin == null) pmBin = bin;
    }

    return SimpleSchedule(
      am: amBin != null
          ? DispenseTime(
              time: TimeOfDay(
                hour: int.parse(amBin.time.split(':')[0]),
                minute: int.parse(amBin.time.split(':')[1]),
              ),
              period: DayPeriod.am,
            )
          : null,
      pm: pmBin != null
          ? DispenseTime(
              time: TimeOfDay(
                hour: int.parse(pmBin.time.split(':')[0]),
                minute: int.parse(pmBin.time.split(':')[1]),
              ),
              period: DayPeriod.pm,
            )
          : null,
    );
  }

  SetScheduleRequestDto _scheduleToRequest(SimpleSchedule schedule) {
    const days = [
      'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'
    ];

    final bins = <DosePeriodDto>[];
    if (schedule.am != null) {
      final t = schedule.am!.time;
      final time = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      for (final day in days) {
        bins.add(DosePeriodDto(dayOfWeek: day, time: time));
      }
    }
    if (schedule.pm != null) {
      final t = schedule.pm!.time;
      final time = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      for (final day in days) {
        bins.add(DosePeriodDto(dayOfWeek: day, time: time));
      }
    }

    return SetScheduleRequestDto(
      schedule: SimpleScheduleDto(bins: bins),
      takeEffect: ScheduleTakeEffect.immediate,
    );
  }
}
