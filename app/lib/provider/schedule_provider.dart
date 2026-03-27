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
    await _postSchedule(deviceID, newSchedule);
  }

  Future<void> _postSchedule(String deviceID, BaseSchedule newSchedule) async {
    final client = ref.read(activeTenantClientProvider);
    if (client == null) return;

    final request = SetScheduleRequestDto(
      schedule: newSchedule.toDto(),
      takeEffect: ScheduleTakeEffect.immediate,
    );
    try {
      final responseDto = await client.setSchedule(deviceID, request);
      state = AsyncValue.data(responseDto.toDomain());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
