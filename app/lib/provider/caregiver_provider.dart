import 'package:app/apiv2/control_plane.dart';
import 'package:app/apiv2/models/dto.dart';
import 'package:app/apiv2/tenant.dart';
import 'package:app/provider/control_plane_providers.dart';
import 'package:app/provider/tenant_providers.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'caregiver_provider.g.dart';

@riverpod
class CaregiverInvite extends _$CaregiverInvite {
  @override
  FutureOr<void> build() async {}

  /// Invites a caregiver by email via the control plane.
  Future<void> inviteCaregiver({
    required String email,
    required String nickname,
    required String deviceId,
    required String tenantId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(controlPlaneClientProvider);
      await client.inviteCaregiver(InviteCaregiverRequestDto(
        email: email,
        nickname: nickname,
        deviceId: deviceId,
        tenantId: tenantId,
      ));
    });
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
