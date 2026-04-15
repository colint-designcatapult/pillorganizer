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

  /// Fetches schedule for a device with automatic retry on transient errors.
  /// 
  /// Retries silently with exponential backoff for:
  /// - Auth errors (401/403) - device endpoint might not be ready yet
  /// - Connection errors - network or server temporarily unavailable
  /// - NoSuchMethodError - extension loading race condition
  /// 
  /// For newly provisioned devices with no schedule set, the API returns
  /// 200 OK with null currentSchedule/requestedSchedule fields. This is
  /// handled correctly by the DTO mapper and results in an empty DeviceScheduleState.
  /// 
  /// For all other failures after retries exhausted, rethrows the error
  /// to let the UI show it and give the user a manual retry option.
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
        print('[Schedule] Error on attempt $attempt: $errorStr');
        
        final isAuthError = errorStr.contains('401') || errorStr.contains('Unauthorized') || errorStr.contains('403') || errorStr.contains('Forbidden');
        final isConnectionError = errorStr.contains('SocketException') || errorStr.contains('TimeoutException') || errorStr.contains('Connection refused');
        final isNoSuchMethod = e is NoSuchMethodError;
        
        // For transient errors, retry with exponential backoff
        if ((isAuthError || isConnectionError || isNoSuchMethod) && attempt < maxAttempts) {
          final delayMs = retryDelayMs * (1 << (attempt - 1)); // 500ms, 1s, 2s
          print('[Schedule] Transient error, retrying after ${delayMs}ms...');
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }
        
        // If we've exhausted retries for transient errors, rethrow
        // Don't silently fall back - let the UI show the error and retry button
        if ((isAuthError || isConnectionError || isNoSuchMethod) && attempt == maxAttempts) {
          print('[Schedule] Exhausted retries after $maxAttempts attempts - returning error to UI');
          rethrow;
        }
        
        // Unexpected error - rethrow immediately
        print('[Schedule] Unexpected error type, rethrowing: $e');
        rethrow;
      }
    }
    
    // Should never reach here due to rethrows above
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
