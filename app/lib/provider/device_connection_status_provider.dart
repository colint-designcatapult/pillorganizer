import 'dart:async';
import 'package:app/api/device.dart';
import 'package:app/provider/device_state_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_connection_status_provider.g.dart';

@riverpod
class DeviceConnectionStatusNotifier extends _$DeviceConnectionStatusNotifier {
  Timer? _offlineTimer;

  @override
  DeviceConnectionStatus build() {
    final deviceStateAsync = ref.watch(deviceStateProvider);

    ref.onDispose(() => _offlineTimer?.cancel());

    return deviceStateAsync.when(
      data: (state) {
        if (state == null) return DeviceConnectionStatus.loading;
        
        if (isOnlineFromLastSeen(state.lastSync)) {
          _offlineTimer?.cancel();
          return DeviceConnectionStatus.online;
        } else {
          _scheduleOfflineTimer();
          return DeviceConnectionStatus.loading;
        }
      },
      loading: () => DeviceConnectionStatus.loading,
      error: (_, __) => DeviceConnectionStatus.offline,
    );
  }

  void _scheduleOfflineTimer() {
    _offlineTimer?.cancel();
    _offlineTimer = Timer(const Duration(seconds: 15), () {
      state = DeviceConnectionStatus.offline;
    });
  }
}
