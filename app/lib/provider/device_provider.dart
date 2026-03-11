import 'package:app/apiv2/models/device.dart';
import 'package:app/apiv2/models/dto.dart';
import 'package:app/provider/control_plane_providers.dart';
import 'package:app/service/time_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/standalone.dart' as tz;

part 'device_provider.g.dart';

@riverpod
class DeviceList extends _$DeviceList {
  @override
  FutureOr<List<DeviceMetadata>> build() async {
    return _fetchDevices();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchDevices());
  }

  Future<List<DeviceMetadata>> _fetchDevices() async {
    var deviceandUser = await ref.read(controlPlaneClientProvider).getDevices();
    return deviceandUser.devices.map((dto) => dto.toDomain()).toList();
  }

  Future<DeviceMetadata> updateDeviceName(String id, String newName) async {
    throw UnimplementedError();
  }

  Future<DeviceMetadata> updateDeviceTimeZone(String id, tz.Location newTZ) async {
    throw UnimplementedError();
  }

  Future<DeviceMetadata> updateDeviceNotifications(String id, bool notifications) async {
    throw UnimplementedError();
  }

  Future<void> updateNotificationsForAllDevices(bool notifications) async {
    throw UnimplementedError();
  }

  Future<void> removeDevice(String id) async {
    throw UnimplementedError();
  }
}
