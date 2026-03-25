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
  final String? tenantName;

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
    this.tenantName
  });
}

@MappableClass()
class UserAndDeviceAccessDto with UserAndDeviceAccessDtoMappable {
  final List<DeviceAccessDto>? devices;

  UserAndDeviceAccessDto({
    this.devices
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
  final String? deviceId;

  ProvisioningClaimRequestDto({
    required this.serialNumber,
    this.deviceId
  });
}

@MappableClass()
class DosePeriodDto with DosePeriodDtoMappable {
  final String dayOfWeek;
  final String time;

  DosePeriodDto({required this.dayOfWeek, required this.time});
}

@MappableClass()
class SimpleScheduleDto with SimpleScheduleDtoMappable {
  final String type;
  final List<DosePeriodDto> bins;

  SimpleScheduleDto({this.type = 'SIMPLE', required this.bins});
}

@MappableEnum(caseStyle: CaseStyle.upperCase)
enum ScheduleStatus { pending, applied, rejected, superseded }

@MappableEnum()
enum ScheduleTakeEffect {
  @MappableValue('IMMEDIATE')
  immediate,
  @MappableValue('NEXT_RELOAD')
  nextReload,
}

@MappableClass()
class DeviceScheduleStateDto with DeviceScheduleStateDtoMappable {
  final String? currentScheduleId;
  final SimpleScheduleDto? currentSchedule;
  final String? requestedScheduleId;
  final SimpleScheduleDto? requestedSchedule;
  final ScheduleStatus? requestedStatus;

  DeviceScheduleStateDto({
    this.currentScheduleId,
    this.currentSchedule,
    this.requestedScheduleId,
    this.requestedSchedule,
    this.requestedStatus,
  });
}

@MappableClass()
class SetScheduleRequestDto with SetScheduleRequestDtoMappable {
  final SimpleScheduleDto schedule;
  final ScheduleTakeEffect takeEffect;

  SetScheduleRequestDto({required this.schedule, required this.takeEffect});
}
