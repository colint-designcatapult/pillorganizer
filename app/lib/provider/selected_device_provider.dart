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
    print('[ActiveDevice] build() called');
    final devices = ref.watch(deviceListProvider).value ?? [];
    final savedId = ref.watch(_savedDeviceIdProvider).value;

    print('[ActiveDevice] devices count=${devices.length}, savedId=$savedId');

    DeviceMetadata? metadata;
    if (savedId != null) {
      metadata = devices.firstWhereOrNull((d) => d.id == savedId) ??
          devices.firstOrNull;
      print('[ActiveDevice] Found device by savedId: ${metadata?.name}');
    } else {
      metadata = devices.firstOrNull;
      print('[ActiveDevice] No savedId, using first device: ${metadata?.name}');
    }

    print('[ActiveDevice] build() returning: ${metadata?.name ?? 'null'}');
    return metadata;
  }

  Future<void> selectDevice(DeviceMetadata metadata) async {
    state = metadata;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastSelectedKeyName, metadata.id);
    ref.read(_savedDeviceIdProvider.notifier).updateId(metadata.id);
  }

  Future<void> selectDeviceByID(String id) async {
    print('[ActiveDevice] selectDeviceByID($id) called');
    try {
      // Refresh device list to pick up newly provisioned devices
      print('[ActiveDevice] Refreshing device list...');
      await ref.read(deviceListProvider.notifier).refresh();
      print('[ActiveDevice] Device list refreshed');

      // Now wait for the refreshed list to load
      print('[ActiveDevice] Waiting for device list to load...');
      final deviceListState = await ref.read(deviceListProvider.future);
      print('[ActiveDevice] Device list loaded: ${deviceListState.length} devices');

      final device = deviceListState.firstWhereOrNull((d) => d.id == id);
      print('[ActiveDevice] Found device: ${device?.name ?? 'NOT FOUND'}');

      if (device != null) {
        print('[ActiveDevice] Selecting device: ${device.name}');
        await selectDevice(device);
        print('[ActiveDevice] Device selected successfully');
      } else {
        print('[ActiveDevice] Device with id=$id not found in list');
      }
    } catch (e, st) {
      print('[ActiveDevice] Error in selectDeviceByID: $e');
      print('[ActiveDevice] Stack trace: $st');
      rethrow;
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
