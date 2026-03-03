import 'package:app/api/api.dart';
import 'package:app/api/device.dart';
import 'package:app/service/time_service.dart';
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_provider.g.dart';

@riverpod
class DeviceList extends _$DeviceList {
  @override
  FutureOr<List<DeviceUser>> build() async {
    return _fetchDevices();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchDevices());
  }

  Future<List<DeviceUser>> _fetchDevices() async {
    // Note: In the original code, this was returning a hardcoded device for now.
    // I'm maintaining that behavior but wrapping it in the AsyncNotifier pattern.
    return [
      DeviceUser(
          id: 0,
          deviceID: 0,
          deviceClass: '',
          name: '',
          serialNo: 0,
          isOnline: false,
          primaryUser: false,
          owner: false,
          notifications: false,
          timezone: null)
    ];
  }

  Future<DeviceUser> updateDeviceName(int deviceID, String newName) async {
    final currentDevices = state.asData?.value ?? [];
    DeviceUser? currentDevice =
        currentDevices.firstWhereOrNull((device) => device.deviceID == deviceID);

    if (currentDevice != null && currentDevice.name == newName) {
      return currentDevice;
    }

    // In a real app, you might want to show a loading state for the specific device,
    // but here we'll just perform the update and refresh the list.
    final updatedDevice = await deviceRepo.update(deviceID, name: newName);
    
    state = AsyncValue.data([
      for (final device in currentDevices)
        if (device.deviceID == deviceID) updatedDevice else device
    ]);
    
    return updatedDevice;
  }

  Future<DeviceUser> updateDeviceTimeZone(
      int deviceID, TimeZoneLocation newTZ) async {
    final currentDevices = state.asData?.value ?? [];
    DeviceUser? currentDevice =
        currentDevices.firstWhereOrNull((device) => device.deviceID == deviceID);

    if (currentDevice != null && currentDevice.timezone?.name == newTZ.name) {
      return currentDevice;
    }

    final updatedDevice = await deviceRepo.update(deviceID, timezone: newTZ);
    
    state = AsyncValue.data([
      for (final device in currentDevices)
        if (device.deviceID == deviceID) updatedDevice else device
    ]);
    
    return updatedDevice;
  }

  Future<DeviceUser> updateDeviceNotifications(
      int deviceID, bool notifications) async {
    final currentDevices = state.asData?.value ?? [];
    DeviceUser? currentDevice =
        currentDevices.firstWhereOrNull((device) => device.deviceID == deviceID);

    if (currentDevice != null && currentDevice.notifications == notifications) {
      return currentDevice;
    }

    final updatedDevice =
        await deviceRepo.update(deviceID, notifications: notifications);
    
    state = AsyncValue.data([
      for (final device in currentDevices)
        if (device.deviceID == deviceID) updatedDevice else device
    ]);
    
    return updatedDevice;
  }

  Future<void> updateNotificationsForAllDevices(bool notifications) async {
    final currentDevices = state.asData?.value ?? [];
    if (currentDevices.isEmpty) return;

    final updatedDevices = <DeviceUser>[];
    for (var device in currentDevices) {
      final updatedDevice = await deviceRepo.update(device.deviceID,
          notifications: notifications);
      updatedDevices.add(updatedDevice);
    }
    
    state = AsyncValue.data(updatedDevices);
  }

  Future<void> removeDevice(int deviceID) async {
    await client.removeDevice(deviceID);
    final currentDevices = state.asData?.value ?? [];
    state = AsyncValue.data(
        currentDevices.where((device) => device.deviceID != deviceID).toList());
  }
}
