import 'package:app/apiv2/control_plane.dart';
import 'package:app/apiv2/models/device_access_dto.dart';
import 'package:app/apiv2/models/provisioning_claim_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'control_plane_providers.g.dart';

@riverpod
ControlPlaneApiClient controlPlaneClient(Ref ref) {
  final dio = ref.watch(controlPlaneDioProvider);
  return ControlPlaneApiClient(dio);
}

@riverpod
Future<List<DeviceAccessDto>> userDevices(Ref ref) async {
  final client = ref.watch(controlPlaneClientProvider);
  return client.getDevices();
}

@riverpod
Future<ProvisioningClaimDto> provisioningClaim(Ref ref, String serialNo) async {
  final client = ref.watch(controlPlaneClientProvider);
  return client.getProvisioningClaim(serialNo);
}
