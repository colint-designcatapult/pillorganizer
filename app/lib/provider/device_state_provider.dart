import 'package:app/api/api.dart';
import 'package:app/apiv2/models/device.dart';
import 'package:app/provider/time_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_state_provider.g.dart';

@riverpod
class DeviceStateNotifier extends _$DeviceStateNotifier {
  @override
  FutureOr<DeviceState?> build() async {
    // Watch time and active device
    final _ = ref.watch(minuteBasedTimeProvider);
    final activeDevice = ref.watch(activeDeviceProvider);

    if (activeDevice == null) {
      return null;
    }

    return _load(activeDevice.id);
  }

  Future<DeviceState?> _load(String deviceId) async {
    // Mocking the original _load logic
    return DeviceState(
        id: deviceId,
        battery: 100,
        charging: false,
        lastSync: DateTime.now(),
        bins: List.generate(14, (index) => index == 1 ? BinStatus.taken : BinStatus.disabled),
        dosePeriods: List.generate(2, (index) => DosePeriod(binID: index, scheduledTime: DateTime.now(), status: BinStatus.taken, medicationIDs: const [1]))
    );
  }
}
