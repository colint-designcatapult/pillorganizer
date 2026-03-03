import 'package:app/api/device.dart';
import 'package:app/provider/device_provider.dart';
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'selected_device_provider.g.dart';

@riverpod
class ActiveDevice extends _$ActiveDevice {
  static const String lastSelectedKeyName = "selectedDeviceID";

  @override
  DeviceUser? build() {
    // Watch the device list. Whenever it changes, we re-evaluate our selection.
    final deviceListAsync = ref.watch(deviceListProvider);
    
    return deviceListAsync.when(
      data: (devices) {
        // If we have an ID but it's not in the list, or we don't have an ID,
        // we should try to load the saved ID or pick the first one.
        // But since build() must be synchronous and return the state,
        // we might need to handle the async loading of the ID separately
        // or just return the first one if we don't have a valid ID yet.
        
        final savedId = ref.read(_savedDeviceIdProvider).asData?.value;
        final targetId = savedId;
        
        final device = devices.firstWhereOrNull((d) => d.deviceID == targetId);
        if (device != null) return device;
        
        if (devices.isNotEmpty) {
          final firstDevice = devices.first;
          _persistSaved(firstDevice.deviceID);
          return firstDevice;
        }
        
        return null;
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }

  void selectDeviceByID(int deviceID) {
    final devices = ref.read(deviceListProvider).asData?.value ?? [];
    final device = devices.firstWhereOrNull((d) => d.deviceID == deviceID);
    if (device != null) {
      _persistSaved(deviceID);
      state = device;
    }
  }

  void selectDevice(DeviceUser deviceUser) {
    selectDeviceByID(deviceUser.deviceID);
  }

  Future<void> _persistSaved(int deviceID) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(lastSelectedKeyName, deviceID);
    // Also update our internal cache of the saved ID so build() can see it
    ref.read(_savedDeviceIdProvider.notifier).updateId(deviceID);
  }
}

// Internal provider to track the saved ID from SharedPreferences
@riverpod
class _SavedDeviceId extends _$SavedDeviceId {
  @override
  FutureOr<int?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(ActiveDevice.lastSelectedKeyName);
  }
  
  void updateId(int id) {
    state = AsyncData(id);
  }
}
