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
  FutureOr<DeviceScheduleState> build() async {
    print('[ScheduleProvider] build() called');
    final device = ref.watch(activeDeviceProvider);
    print('[ScheduleProvider] Active device: ${device?.name ?? 'null'} (id=${device?.id})');

    if (device == null) {
      print('[ScheduleProvider] Device is null, returning empty state');
      return const DeviceScheduleState();
    }

    final client = ref.watch(activeTenantClientProvider);
    if (client == null) {
      print('[ScheduleProvider] Client is null, returning empty state');
      return const DeviceScheduleState();
    }

    print('[ScheduleProvider] Fetching schedule for device ${device.id}');
    try {
      final dto = await client.getSchedule(device.id);
      final state = dto.toDomain();
      print('[ScheduleProvider] Schedule fetched successfully');
      return state;
    } catch (e, st) {
      print('[ScheduleProvider] Error fetching schedule: $e');
      print('[ScheduleProvider] Stack trace: $st');
      rethrow;
    }
  }

  Future<void> load(String deviceID) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(activeTenantClientProvider);
      if (client == null) return const DeviceScheduleState();
      final dto = await client.getSchedule(deviceID);
      return dto.toDomain();
    });
  }


  Future<void> setScheduleAndTimezone(
      String deviceID, TimeOfDay amTime, TimeOfDay pmTime, String ianaTimezone) async {
    final amBins = DayOfWeek.values
        .map((day) => DosePeriodV2(dayOfWeek: day, time: amTime))
        .toList();
    final pmBins = DayOfWeek.values
        .map((day) => DosePeriodV2(dayOfWeek: day, time: pmTime))
        .toList();
    final newSchedule = SimpleSchedule(bins: [...amBins, ...pmBins]);
    await _postSchedule(deviceID, newSchedule, ianaTimezone);
  }

  Future<void> _postSchedule(String deviceID, BaseSchedule newSchedule, String timezoneIana) async {
    final client = ref.read(activeTenantClientProvider);
    if (client == null) return;

    final request = SetScheduleRequestDto(
      schedule: newSchedule.toDto(),
      takeEffect: ScheduleTakeEffect.immediate,
      timezoneIana: timezoneIana,
    );
    try {
      final responseDto = await client.setSchedule(deviceID, request);
      state = AsyncValue.data(responseDto.toDomain());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

