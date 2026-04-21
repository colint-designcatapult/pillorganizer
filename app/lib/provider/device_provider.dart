

import 'package:app/apiv2/models/device.dart';
import 'package:app/apiv2/models/dto.dart';
import 'package:app/provider/control_plane_providers.dart';
import 'package:app/provider/tenant_providers.dart';
import 'package:app/service/notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/standalone.dart' as tz;

part 'device_provider.g.dart';

@riverpod
class DeviceList extends _$DeviceList {
  @override
  FutureOr<List<DeviceMetadata>> build() async {
    return await _fetchDevices();
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

    // Persist to backend using the device's own apiBase so this works
    // regardless of which device is currently active.
    try {
      await tenantClientForUrl(device.apiBase)
          .updateDeviceNickname(id, UpdateDeviceSettingsDto(deviceName: newName));
    } catch (e) {
      state = AsyncValue.data(previous);
      rethrow;
    }

    // Pessimistic update — UI reflects the change only after persistence.
    final updated = previous
        .map((d) => d.id == id ? d.copyWith(nickname: newName) : d)
        .toList();
    state = AsyncValue.data(updated);


    return updated.firstWhere((d) => d.id == id);
  }

  Future<DeviceMetadata> updateDeviceTimeZone(String id, tz.Location newTZ) async {
    throw UnimplementedError();
  }

  /// Subscribes or unsubscribes the current user from push notifications for
  /// [id]. Registers the FCM token with the control plane first so the
  /// backend always has a fresh endpoint ARN before toggling the subscription.
  Future<DeviceMetadata> updateDeviceNotifications(String id, bool subscribe) async {
    if (!state.hasValue) {
      await future;
    }

    final previous = state.asData!.value;
    final device = previous.firstWhere(
      (d) => d.id == id,
      orElse: () => throw StateError('Device $id not found in list'),
    );

    final controlPlane = ref.read(controlPlaneClientProvider);

    // 1. Register / refresh FCM token (only needed when subscribing).
    //    Unsubscribe relies solely on the server-side stored subscription ARN.
    if (subscribe) {
      final token = await getFcmToken();
      if (token == null) {
        throw StateError(
          'Cannot enable notifications: FCM token is unavailable. '
          'Please grant notification permission and try again.',
        );
      }
      await controlPlane.registerFcmToken(RegisterFcmTokenDto(fcmToken: token));
    }

    // 2. Toggle the subscription on the control plane.
    final updated = await controlPlane.updateDeviceNotifications(
      DeviceNotificationRequestDto(
        deviceId: id,
        tenantId: device.tenantId,
        subscribe: subscribe,
      ),
    );

    final updatedDomain = updated.toDomain();
    final newList = previous
        .map((d) => d.id == id ? updatedDomain : d)
        .toList();
    state = AsyncValue.data(newList);

    return updatedDomain;
  }

  Future<void> updateNotificationsForAllDevices(bool notifications) async {
    throw UnimplementedError();
  }

  Future<void> removeDevice(String id) async {
    throw UnimplementedError();
  }
}
