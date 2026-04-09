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

@MappableEnum(caseStyle: CaseStyle.upperCase)
enum ScheduleStatus { pending, applied, rejected, superseded }

@MappableEnum()
enum ScheduleTakeEffect {
  @MappableValue('IMMEDIATE')
  immediate,
  @MappableValue('NEXT_RELOAD')
  nextReload,
}

@MappableEnum()
enum DayOfWeek {
  @MappableValue('MONDAY') monday,
  @MappableValue('TUESDAY') tuesday,
  @MappableValue('WEDNESDAY') wednesday,
  @MappableValue('THURSDAY') thursday,
  @MappableValue('FRIDAY') friday,
  @MappableValue('SATURDAY') saturday,
  @MappableValue('SUNDAY') sunday,
}

@MappableClass()
class DeviceScheduleStateDto with DeviceScheduleStateDtoMappable {
  final DeviceScheduleDto? currentSchedule;
  final DeviceScheduleDto? requestedSchedule;
  final ScheduleStatus? requestedStatus;

  const DeviceScheduleStateDto({
    this.currentSchedule,
    this.requestedSchedule,
    this.requestedStatus,
  });
}

@MappableClass()
class DeviceScheduleDto with DeviceScheduleDtoMappable {
  final String id;
  final ScheduleTakeEffect? takeEffect;
  final BaseScheduleDto? schedule;
  final String? timezoneIana;
  final String? timezonePosix;

  const DeviceScheduleDto({
    required this.id,
    this.takeEffect = ScheduleTakeEffect.immediate,
    required this.schedule,
    this.timezoneIana,
    this.timezonePosix,
  });
}

@MappableClass(discriminatorKey: 'type')
abstract class BaseScheduleDto with BaseScheduleDtoMappable {
  const BaseScheduleDto();
}

@MappableClass(discriminatorValue: 'SIMPLE')
class SimpleScheduleDto extends BaseScheduleDto with SimpleScheduleDtoMappable {
  final List<DosePeriodDto> bins;

  const SimpleScheduleDto({required this.bins}) : super();
}

@MappableClass()
class DosePeriodDto with DosePeriodDtoMappable {
  final DayOfWeek dayOfWeek;
  final String time;

  const DosePeriodDto({required this.dayOfWeek, required this.time});
}

@MappableClass()
class SetScheduleRequestDto with SetScheduleRequestDtoMappable {
  final BaseScheduleDto schedule;
  final ScheduleTakeEffect takeEffect;
  final String timezoneIana;

  const SetScheduleRequestDto({required this.schedule, required this.takeEffect, required this.timezoneIana});
}

@MappableClass()
class DeviceBatteryStateDto with DeviceBatteryStateDtoMappable {
  final int? usb;
  final int? pg;
  final int? con;
  final int? chg;
  final int? pct;

  DeviceBatteryStateDto({
    this.usb,
    this.pg,
    this.con,
    this.chg,
    this.pct
  });
}

@MappableClass(caseStyle: CaseStyle.snakeCase)
class DeviceBinStatusDto with DeviceBinStatusDtoMappable {
  final int id;
  final String? status;
  final int? scheduledTime;
  final String? scheduleId;

  DeviceBinStatusDto({
    required this.id,
    this.status,
    this.scheduledTime,
    this.scheduleId
  });
}

@MappableClass(caseStyle: CaseStyle.snakeCase)
class ReloadStateDto with ReloadStateDtoMappable {
  final bool needed;
  final int? progress;
  final int? completeMask;

  ReloadStateDto({
    required this.needed,
    this.progress,
    this.completeMask,
  });
}

@MappableClass(caseStyle: CaseStyle.snakeCase)
class DeviceStateDto with DeviceStateDtoMappable {
  final int timestamp;
  final DeviceBatteryStateDto? battery;
  final ReloadStateDto? reload;
  final int? doors;
  final List<DeviceBinStatusDto>? bins;
  final String? scheduleId;
  final int? errorFlags;
  final int? epochWeek;
  @MappableField(key: 'timezoneIana')
  final String? timezoneIana;
  @MappableField(key: 'timezonePosix')
  final String? timezonePosix;

  DeviceStateDto({
    required this.timestamp,
    this.battery,
    this.reload,
    this.doors,
    this.bins,
    this.scheduleId,
    this.errorFlags,
    this.epochWeek,
    this.timezoneIana,
    this.timezonePosix,
  });
}

@MappableClass()
class UpdateDeviceSettingsDto with UpdateDeviceSettingsDtoMappable {
  final String? deviceName;

  const UpdateDeviceSettingsDto({this.deviceName});
}
