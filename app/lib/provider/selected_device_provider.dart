import 'package:app/apiv2/models/device.dart';
import 'package:app/provider/device_provider.dart';
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'selected_device_provider.g.dart';

@riverpod
class ActiveDevice extends _$ActiveDevice {
  static const String lastSelectedKeyName = "selectedDeviceID";

  @override
  DeviceMetadata? build() {
    final devices = ref.watch(deviceListProvider).value ?? [];
    final savedId = ref.watch(_savedDeviceIdProvider).value;

    print('[ActiveDevice] DEBUG: build() - devices=${devices.length}, savedId=$savedId');

    DeviceMetadata? metadata;
    if (savedId != null) {
      metadata = devices.firstWhereOrNull((d) => d.id == savedId) ??
          devices.firstOrNull;
    } else {
      metadata = devices.firstOrNull;
    }

    print('[ActiveDevice] DEBUG: build() result - metadata=${metadata?.name ?? 'null'}');
    return metadata;
  }

  Future<void> selectDevice(DeviceMetadata metadata) async {
    state = metadata;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastSelectedKeyName, metadata.id);
    ref.read(_savedDeviceIdProvider.notifier).updateId(metadata.id);
  }

  Future<void> selectDeviceByID(String id) async {
    print('[ActiveDevice] DEBUG: selectDeviceByID called with id=$id');

    // Wait for device list to load, then find the device
    final deviceListState = await ref.read(deviceListProvider.future);
    print('[ActiveDevice] DEBUG: Available devices: ${deviceListState.length}');

    final device = deviceListState.firstWhereOrNull((d) => d.id == id);
    print('[ActiveDevice] DEBUG: Found device: ${device?.name ?? 'NOT FOUND'}');

    if (device != null) {
      await selectDevice(device);
    } else {
      print('[ActiveDevice] DEBUG: Device not found in list, not selecting');
    }
  }
}

/// Deprecated: timezone is now sourced from [scheduleProvider].
/// This provider will be removed once all consumers are migrated.
@Deprecated('Use scheduleProvider and DeviceScheduleState.effectiveTimezoneIana instead')
@riverpod
class ActiveDeviceConfig extends _$ActiveDeviceConfig {
  @override
  DeviceConfig? build() {
    final activeDevice = ref.watch(activeDeviceProvider);
    if (activeDevice == null) return null;

    return const DeviceConfig(timezone: null);
  }

  Future<void> updateTimezone(String timezone) async {
    state = DeviceConfig(timezone: timezone);
  }
}

// Internal provider to track the saved ID from SharedPreferences
@riverpod
class _SavedDeviceId extends _$SavedDeviceId {
  @override
  FutureOr<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ActiveDevice.lastSelectedKeyName);
  }

  void updateId(String id) {
    state = AsyncData(id);
  }
}
