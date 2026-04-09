import 'package:app/apiv2/models/device.dart';
import 'package:app/provider/device_connection_status_provider.dart';
import 'package:app/provider/device_state_provider.dart';
import 'package:app/provider/mqtt_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_error_provider.g.dart';

@riverpod
DeviceError deviceError(Ref ref) {
  final mqttAsync = ref.watch(mqttClientProvider);

  // If MQTT client is null and not loading, we have a phone-to-MQTT connection issue.
  if (mqttAsync.hasValue && mqttAsync.value == null && !mqttAsync.isLoading) {
    return DeviceError.phoneDisconnected;
  }

  // If MQTT client has an error, we also have a phone-to-MQTT connection issue.
  if (mqttAsync.hasError) {
    return DeviceError.phoneDisconnected;
  }

  final status = ref.watch(deviceConnectionStatusProvider);
  if (status == DeviceConnectionStatus.offline) {
    return DeviceError.disconnected;
  }

  final stateAsync = ref.watch(deviceStateProvider);
  return stateAsync.maybeWhen(
    data: (state) {
      if (state == null) return DeviceError.none;
      
      if (state.errors.isNotEmpty) {
        final DeviceErrorFlag firstError = state.errors.first;
        return switch (firstError) {
          DeviceErrorFlag.noSchedule => DeviceError.noSchedule,
          DeviceErrorFlag.stateCorrupted => DeviceError.stateCorrupted,
          DeviceErrorFlag.noRtcTime => DeviceError.noRtcTime,
          DeviceErrorFlag.unknown => DeviceError.unknown,
        };
      }
      
      if (state.reloadState?.needed == true) {
        return DeviceError.needsReload;
      }
      
      return DeviceError.none;
    },
    orElse: () => DeviceError.none,
  );
}
