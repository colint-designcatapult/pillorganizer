import 'package:app/apiv2/models/device.dart';
import 'package:app/provider/device_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_connection_status_provider.g.dart';

bool isOnlineFromLastSeen(DateTime? lastSeen) {
  if (lastSeen == null) return false;
  return DateTime.now().difference(lastSeen).inMinutes < 5;
}

@riverpod
DeviceConnectionStatus deviceConnectionStatus(Ref ref) {
  final deviceStateAsync = ref.watch(deviceStateProvider);

  // If the provider is currently loading, we are in a 'loading' connection status.
  if (deviceStateAsync.isLoading) {
    return DeviceConnectionStatus.loading;
  }

  return deviceStateAsync.when(
    data: (state) {
      if (state == null || !isOnlineFromLastSeen(state.lastSync)) {
        return DeviceConnectionStatus.offline;
      }
      return DeviceConnectionStatus.online;
    },
    // This case is handled when data is not yet available, but isLoading check above
    // also handles refreshes/reloads.
    loading: () => DeviceConnectionStatus.loading,
    error: (_, __) => DeviceConnectionStatus.offline,
  );
}
