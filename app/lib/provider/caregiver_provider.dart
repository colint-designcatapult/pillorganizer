import 'package:app/apiv2/models/dto.dart';
import 'package:app/apiv2/tenant.dart';
import 'package:app/provider/tenant_providers.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'caregiver_provider.g.dart';

@riverpod
class Caregiver extends _$Caregiver {
  @override
  FutureOr<List<DeviceCaregiverCodeDto>> build() async {
    return [];
  }

  TenantApiClient _clientForDevice(String deviceId) {
    final devices = ref.read(activeDeviceProvider);
    if (devices != null) {
      return tenantClientForUrl(devices.apiBase);
    }
    throw Exception('No active device to determine API base URL');
  }

  Future<void> fetchShareCodesForDevices(List<String> deviceIDs) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final client = _clientForDevice(deviceIDs.first);
      return await client.getShareCodes(deviceIDs);
    });
  }

  DeviceCaregiverCodeDto? getShareCodeForDevice(String deviceID) {
    final list = state.asData?.value;
    if (list == null) return null;
    for (var c in list) {
      if (c.deviceID == deviceID) return c;
    }
    return null;
  }

  void clearExpiredCodes() {
    if (state.hasValue) {
      state = AsyncValue.data(
        state.value!.where((c) => c.isValid).toList()
      );
    }
  }

  Future<void> generateCaregiverCodeForDevice(String deviceID, String nickname) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final client = _clientForDevice(deviceID);
      final newCode = await client.generateCaregiverCode(
          deviceID, GenerateCaregiverCodeDto(nickname: nickname));
      final currentList = state.asData?.value ?? [];
      return [
        for (final c in currentList) if (c.deviceID != deviceID) c,
        newCode,
      ];
    });
  }

  Future<CaregiverCodeValidationDto> validateCaregiverCode({required String code}) async {
    final client = _clientForDevice('');
    final res = await client.validateCaregiverCode(code);
    ref.invalidateSelf();
    return res;
  }
}

@riverpod
class CaregiverList extends _$CaregiverList {
  @override
  FutureOr<List<CaregiverListItemDto>> build(String deviceId) async {
    return _fetch(deviceId);
  }

  TenantApiClient _clientForDevice() {
    final device = ref.read(activeDeviceProvider);
    if (device != null) {
      return tenantClientForUrl(device.apiBase);
    }
    throw Exception('No active device to determine API base URL');
  }

  Future<List<CaregiverListItemDto>> _fetch(String deviceId) async {
    final client = _clientForDevice();
    return await client.listCaregivers(deviceId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(deviceId));
  }

  Future<void> revokeCaregiver(String caregiverId) async {
    final client = _clientForDevice();
    await client.revokeCaregiverAccess(caregiverId);
    await refresh();
  }

  Future<void> transferPrimaryUser(String targetCaregiverId) async {
    final client = _clientForDevice();
    await client.transferPrimaryUser(
        deviceId, TransferPrimaryUserDto(targetCaregiverId: targetCaregiverId));
    ref.invalidateSelf();
  }
}
