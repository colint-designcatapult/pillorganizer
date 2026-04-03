import 'dart:async';

import 'package:app/api/intreceptors/auth-interceptors.dart';
import 'package:app/apiv2/models/device.dart';
import 'package:app/apiv2/models/dto.dart';
import 'package:app/apiv2/tenant.dart';
import 'package:app/provider/control_plane_providers.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/standalone.dart' as tz;

part 'device_provider.g.dart';

@riverpod
class DeviceList extends _$DeviceList {
  @override
  FutureOr<List<DeviceMetadata>> build() async {
    try {
      final devices = await _fetchDevices();

      // If no devices are found, start a timer to retry
      if (devices.isEmpty) {
        final timer = Timer(const Duration(seconds: 5), () {
          ref.invalidateSelf();
        });
        ref.onDispose(timer.cancel);
      }

      return devices;
    } catch (e) {
      // Retry on error after 5 seconds
      final timer = Timer(const Duration(seconds: 5), () {
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
    // Guard: don't mutate state if the device list isn't loaded yet.
    if (!state.hasValue) {
      await future;
    }

    final previous = state.asData!.value;
    final device = previous.firstWhere(
      (d) => d.id == id,
      orElse: () => throw StateError('Device $id not found in list'),
    );

    // Optimistic update — UI reflects the change immediately.
    final updated = previous
        .map((d) => d.id == id ? d.copyWith(nickname: newName) : d)
        .toList();
    state = AsyncValue.data(updated);

    // Persist to backend using the device's own apiBase so this works
    // regardless of which device is currently active.
    try {
      final dio = Dio(BaseOptions(
        baseUrl: device.apiBase,
        connectTimeout: const Duration(seconds: 10),
      ));
      dio.interceptors.add(JwtAuthInterceptor(dio: dio));
      await TenantApiClient(dio)
          .updateDeviceNickname(id, UpdateDeviceSettingsDto(deviceName: newName));
    } catch (e) {
      // Revert optimistic update so UI stays in sync with server.
      state = AsyncValue.data(previous);
      rethrow;
    }

    return updated.firstWhere((d) => d.id == id);
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
