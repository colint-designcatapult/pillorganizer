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

    DeviceMetadata? metadata;
    if (savedId != null) {
      metadata = devices.firstWhereOrNull((d) => d.id == savedId) ??
          devices.firstOrNull;
    } else {
      metadata = devices.firstOrNull;
    }

    return metadata;
  }

  Future<void> selectDevice(DeviceMetadata metadata) async {
    // Avoid setting 'state' directly since build() computes it.
    // Update the saved device ID synchronously to prevent async gap disposal issues.
    ref.read(_savedDeviceIdProvider.notifier).updateId(metadata.id);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastSelectedKeyName, metadata.id);
  }

  void selectDeviceByID(String id) {
    // No need to await deviceListProvider. If ID is provided, trust it and update synchronously.
    // This avoids async gaps which can cause the Riverpod notifier to be disposed by background refreshes.
    ref.read(_savedDeviceIdProvider.notifier).updateId(id);
    
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(lastSelectedKeyName, id);
    });
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
