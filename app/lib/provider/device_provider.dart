import 'dart:async';
import 'dart:math';

import 'package:app/apiv2/models/device.dart';
import 'package:app/apiv2/models/dto.dart';
import 'package:app/provider/control_plane_providers.dart';
import 'package:app/service/time_service.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/standalone.dart' as tz;

part 'device_provider.g.dart';

/// Returns true for errors that are likely temporary and worth retrying.
/// Auth/permission failures (401, 403) and not-found (404) are permanent —
/// retrying them would just flood the server.
bool _isTransientError(Object e) {
  if (e is DioException) {
    final status = e.response?.statusCode;
    if (status != null && (status == 401 || status == 403 || status == 404)) {
      return false;
    }
    // Network errors, timeouts, and 5xx are transient
    return true;
  }
  return true;
}

/// Schedules a single retry using exponential backoff.
/// [attempt] is zero-based. Max delay is capped at 5 minutes.
Duration _backoffDelay(int attempt) {
  const base = Duration(seconds: 5);
  const cap = Duration(minutes: 5);
  final ms = base.inMilliseconds * pow(2, attempt).toInt();
  return Duration(milliseconds: min(ms, cap.inMilliseconds));
}

const int _maxRetries = 5;

@riverpod
class DeviceList extends _$DeviceList {
  int _retryCount = 0;

  @override
  FutureOr<List<DeviceMetadata>> build() async {
    try {
      final devices = await _fetchDevices();

      // Reset retry count on success; reschedule if list is still empty.
      _retryCount = 0;
      if (devices.isEmpty) {
        final timer = Timer(const Duration(seconds: 5), () {
          ref.invalidateSelf();
        });
        ref.onDispose(timer.cancel);
      }

      return devices;
    } catch (e) {
      if (!_isTransientError(e) || _retryCount >= _maxRetries) {
        // Permanent error or retry budget exhausted — let the UI show the error.
        rethrow;
      }

      final delay = _backoffDelay(_retryCount);
      _retryCount++;

      final timer = Timer(delay, () {
        ref.invalidateSelf();
      });
      ref.onDispose(timer.cancel);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchDevices());
  }

  Future<List<DeviceMetadata>> _fetchDevices() async {
    var deviceandUser = await ref.read(controlPlaneClientProvider).getDevices();
    return deviceandUser.devices?.map((dto) => dto.toDomain()).toList() ?? List.empty();
  }

  Future<DeviceMetadata> updateDeviceName(String id, String newName) async {
    throw UnimplementedError();
  }

  Future<DeviceMetadata> updateDeviceTimeZone(String id, tz.Location newTZ) async {
    throw UnimplementedError();
  }

  Future<DeviceMetadata> updateDeviceNotifications(String id, bool notifications) async {
    throw UnimplementedError();
  }

  Future<void> updateNotificationsForAllDevices(bool notifications) async {
    throw UnimplementedError();
  }

  Future<void> removeDevice(String id) async {
    throw UnimplementedError();
  }
}
