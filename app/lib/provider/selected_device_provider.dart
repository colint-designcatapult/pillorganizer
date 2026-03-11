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
    state = metadata;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastSelectedKeyName, metadata.id);
    ref.read(_savedDeviceIdProvider.notifier).updateId(metadata.id);
  }

  Future<void> selectDeviceByID(String id) async {
    final devices = ref.read(deviceListProvider).value ?? [];
    final device = devices.firstWhereOrNull((d) => d.id == id);
    if (device != null) {
      await selectDevice(device);
    }
  }
}

@riverpod
class ActiveDeviceConfig extends _$ActiveDeviceConfig {
  @override
  DeviceConfig? build() {
    final activeDevice = ref.watch(activeDeviceProvider);
    if (activeDevice == null) return null;

    // Mocking timezone for now
    return const DeviceConfig(timezone: null);
  }

  Future<void> updateTimezone(String timezone) async {
    // Logic to update timezone via API
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
