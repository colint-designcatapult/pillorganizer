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

    if (device == null) {
      return const DeviceScheduleState();
    }

    final client = ref.watch(activeTenantClientProvider);
    if (client == null) {
      return const DeviceScheduleState();
    }

    // Try to fetch schedule with automatic retry for 401 errors
    // (newly provisioned devices may have auth delays)
    return _fetchScheduleWithRetry(device.id, client, maxAttempts: 3);
  }

  /// Fetches schedule for a device, with graceful handling for newly provisioned devices.
  /// For newly provisioned devices that don't have a schedule yet, returns an empty
  /// schedule instead of failing. This lets the user set their first schedule in post_setup.
  Future<DeviceScheduleState> _fetchScheduleWithRetry(
    String deviceId,
    dynamic client, {
    int maxAttempts = 3,
    int retryDelayMs = 500,
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        print('[Schedule] Fetching schedule for device $deviceId (attempt $attempt/$maxAttempts)');
        final dto = await client.getSchedule(deviceId);
        final state = dto.toDomain();
        print('[Schedule] Successfully fetched schedule for device $deviceId');
        return state;
      } catch (e, st) {
        final errorStr = e.toString();
        final isAuthError = errorStr.contains('401') || errorStr.contains('Unauthorized') || errorStr.contains('403');
        final isNotFound = errorStr.contains('404') || errorStr.contains('Not Found');
        
        // For newly provisioned devices, no schedule exists yet → return empty schedule
        if (isNotFound) {
          print('[Schedule] Device has no schedule yet (404) - returning empty schedule for setup');
          return const DeviceScheduleState();
        }
        
        // For auth errors, retry with exponential backoff (device endpoint might not be ready)
        if (isAuthError && attempt < maxAttempts) {
          final delayMs = retryDelayMs * (1 << (attempt - 1)); // 500ms, 1s, 2s
          print('[Schedule] Auth error on attempt $attempt, retrying in ${delayMs}ms...');
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }
        
        // On final attempt with auth error, also return empty schedule
        // This allows the user to set up the device even if auth is temporarily failing
        if (isAuthError && attempt == maxAttempts) {
          print('[Schedule] Auth error after $maxAttempts attempts - returning empty schedule for user setup');
          return const DeviceScheduleState();
        }
        
        // Other errors - rethrow
        print('[Schedule] Failed to fetch schedule: $e');
        rethrow;
      }
    }
    
    // Should never reach here
    return const DeviceScheduleState();
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
