import 'package:app/apiv2/models/dto.dart';
import 'package:app/apiv2/models/schedule.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/provider/tenant_providers.dart';
import 'package:app/service/time_service.dart' show normalizeIanaTimezone;
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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
    return dto.toDomain();
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

  Future<void> updateTime(DayPeriod period, TimeOfDay time, String deviceID) async {
    final current = state.asData?.value ?? const DeviceScheduleState();
    final effectiveSchedule = current.effectiveSchedule;

    final currentBins = effectiveSchedule is SimpleSchedule
        ? effectiveSchedule.bins
        : <DosePeriodV2>[];

    final isAM = period == DayPeriod.am;
    final otherBins =
        currentBins.where((b) => isAM ? b.time.hour >= 12 : b.time.hour < 12).toList();
    final newBins = DayOfWeek.values
        .map((day) => DosePeriodV2(dayOfWeek: day, time: time))
        .toList();

    final newSchedule = SimpleSchedule(bins: [...otherBins, ...newBins]);
    try {
      final timezoneIana = current.effectiveTimezoneIana ??
          normalizeIanaTimezone((await FlutterTimezone.getLocalTimezone()).identifier);
      await _postSchedule(deviceID, newSchedule, timezoneIana);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTimezone(String deviceID, String ianaTimezone) async {
    final client = ref.read(activeTenantClientProvider);
    if (client == null) return;

    try {
      BaseSchedule? effectiveSchedule = state.asData?.value.effectiveSchedule;

      if (effectiveSchedule == null) {
        final dto = await client.getSchedule(deviceID);
        effectiveSchedule = dto.toDomain().effectiveSchedule;
      }

      if (effectiveSchedule == null) {
        throw StateError('Cannot update timezone without a loaded schedule.');
      }

      final request = SetScheduleRequestDto(
        schedule: effectiveSchedule.toDto(),
        takeEffect: ScheduleTakeEffect.immediate,
        timezoneIana: ianaTimezone,
      );
      final responseDto = await client.setSchedule(deviceID, request);
      state = AsyncValue.data(responseDto.toDomain());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
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
