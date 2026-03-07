import 'package:dart_mappable/dart_mappable.dart';

part 'dto.mapper.dart';

@MappableClass()
class DeviceAccessDto with DeviceAccessDtoMappable {
  final String deviceId;
  final String? claimId;
  final String? nickname;
  final String? serialNo;
  final String? modelId;
  final String tenantId;
  final String apiBase;
  final bool primaryUser;
  final String? thingName;
  final bool? showTenant;

  DeviceAccessDto({
    required this.deviceId,
    this.claimId,
    this.nickname,
    this.serialNo,
    this.modelId,
    required this.apiBase,
    required this.tenantId,
    required this.primaryUser,
    this.thingName,
    this.showTenant
  });
}

@MappableClass()
class UserAndDeviceAccessDto with UserAndDeviceAccessDtoMappable {
  final List<DeviceAccessDto> devices;

  UserAndDeviceAccessDto({
    required this.devices
  });
}

@MappableClass()
class ProvisioningClaimDto with ProvisioningClaimDtoMappable {
  final String claimId;
  final String tenantId;
  final String tenantApiBase;
  final String deviceId;
  final String claimToken;

  ProvisioningClaimDto({
    required this.claimId,
    required this.tenantId,
    required this.tenantApiBase,
    required this.deviceId,
    required this.claimToken
  });

  static final fromJson = ProvisioningClaimDtoMapper.fromMap;
}

@MappableClass()
class ProvisioningClaimRequestDto with ProvisioningClaimRequestDtoMappable {
  final String serialNumber;
  final String deviceId;

  ProvisioningClaimRequestDto({
    required this.serialNumber,
    required this.deviceId
  });
}
