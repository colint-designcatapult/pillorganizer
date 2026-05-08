import 'package:app/apiv2/models/dto.dart';
import 'package:app/apiv2/models/schedule.dart';
import 'package:app/apiv2/tenant.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/provider/tenant_providers.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'schedule_provider.g.dart';

@riverpod
class Schedule extends _$Schedule {
  @override
  FutureOr<DeviceScheduleState> build() async {
    final device = ref.watch(activeDeviceProvider);
    if (device == null) return const DeviceScheduleState();

    final client = ref.watch(activeTenantClientProvider);
    if (client == null) return const DeviceScheduleState();

    final dto = await client.getSchedule(device.id);
    final state = dto.toDomain();

    // If the device has no schedule set, try to fetch the tenant default schedule
    if (state.effectiveSchedule == null) {
      final defaultSchedule = await _fetchDefaultSchedule(client);
      if (defaultSchedule != null) {
        return state.copyWithDefault(defaultSchedule);
      }
    }

    return state;
  }

  Future<void> load(String deviceID) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(activeTenantClientProvider);
      if (client == null) return const DeviceScheduleState();
      final dto = await client.getSchedule(deviceID);
      final scheduleState = dto.toDomain();

      // If the device has no schedule set, try to fetch the tenant default schedule
      if (scheduleState.effectiveSchedule == null) {
        final defaultSchedule = await _fetchDefaultSchedule(client);
        if (defaultSchedule != null) {
          return scheduleState.copyWithDefault(defaultSchedule);
        }
      }

      return scheduleState;
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

  /// Fetches the tenant's default schedule. Returns null if not configured or on error.
  Future<BaseSchedule?> _fetchDefaultSchedule(TenantApiClient client) async {
    try {
      final dto = await client.getDefaultSchedule();
      return dto.toDomain();
    } catch (_) {
      // 404 or any other error — no default schedule configured
      return null;
    }
  }
}
