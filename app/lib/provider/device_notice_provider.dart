import 'package:app/api/api.dart';
import 'package:app/apiv2/models/device.dart';
import 'package:app/provider/device_connection_status_provider.dart';
import 'package:app/provider/device_state_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_notice_provider.g.dart';

@riverpod
class DeviceNoticeNotifier extends _$DeviceNoticeNotifier {
  @override
  DeviceNotice build() {
    final status = ref.watch(deviceConnectionStatusProvider);
    final stateAsync = ref.watch(deviceStateProvider);

    return stateAsync.when(
      data: (deviceState) {
        if (status == DeviceConnectionStatus.offline) {
          return DeviceNotice.disconnected;
        } else if (status == DeviceConnectionStatus.online &&
            (deviceState?.dosePeriods.isEmpty ?? true)) {
          return DeviceNotice.empty;
        } else {
          return DeviceNotice.none;
        }
      },
      loading: () => DeviceNotice.none,
      error: (_, __) => DeviceNotice.disconnected,
    );
  }

  Future<void> reload() async {
    final stateAsync = ref.read(deviceStateProvider);
    final deviceId = stateAsync.value?.id;
    if (deviceId != null) {
      await client.reload(deviceId);
      ref.invalidate(deviceStateProvider);
    }
  }
}
