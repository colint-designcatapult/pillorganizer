import 'package:app/apiv2/models/dto.dart';
import 'package:timezone/standalone.dart' as tz;
import 'package:app/service/time_service.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:app/api/api.dart'; // For DTOs if they are still there

part 'device.mapper.dart';

@MappableEnum(caseStyle: CaseStyle.upperCase)
enum BinStatus {
  disabled,
  taken,
  missed,
  pending,
  @MappableValue('TAKE_NOW')
  take_now,
  noRecord,
}

@MappableEnum(caseStyle: CaseStyle.upperCase)
enum EventType { opened, closed, missed }

enum DeviceConnectionStatus { undefined, offline, online, loading }

enum DeviceError { none, disconnected, phoneDisconnected, needsReload, noSchedule, stateCorrupted, noRtcTime, noTimezone, unknown }

enum DeviceErrorFlag {
  noSchedule(1 << 0),
  stateCorrupted(1 << 1),
  noRtcTime(1 << 2),
  noTimezone(1 << 3),
  unknown(0);

  const DeviceErrorFlag(this.bit);
  final int bit;

  /// Parses a raw bitfield integer into a set of [DeviceErrorFlag] values.
  /// Any bit position that does not correspond to a known flag causes
  /// [DeviceErrorFlag.unknown] to be included in the result.
  static final Map<int, DeviceErrorFlag> _bitToFlag = {
    for (final f in values)
      if (f != unknown) f.bit: f,
  };

  static Set<DeviceErrorFlag> fromBitfield(int flags) {
    final Set<DeviceErrorFlag> result = {};
    bool hasUnknownBits = false;

    // Walk every bit position that is set in flags.
    for (int i = 0; i < flags.bitLength; i++) {
      if ((((flags >> i) & 1) == 0)) continue;
      final int bit = 1 << i;
      final DeviceErrorFlag? flag = _bitToFlag[bit];
      if (flag != null) {
        result.add(flag);
      } else {
        hasUnknownBits = true;
      }
    }

    if (hasUnknownBits) result.add(unknown);

    return result;
  }
}


@MappableClass()
class BinEvent with BinEventMappable {
  final int id;
  final int bin;
  final DateTime? time;
  final DateTime? timeLocal;
  final EventType? eventType;

  const BinEvent({
    required this.id,
    required this.bin,
    this.time,
    this.timeLocal,
    this.eventType,
  });

  factory BinEvent.fromDTO({required BinEventDTO dto}) {
    DateTime dt = timeService.serverTime(dto.ts);
    return BinEvent(
      id: dto.id,
      bin: dto.bin,
      time: dt,
      timeLocal: timeService.serverTimeToLocal(dto.ts),
      eventType: EventType.values.byName(dto.eventType.toLowerCase()),
    );
  }

  static TimeService timeService = TimeService();
}

@MappableClass()
class BinSchedule with BinScheduleMappable {
  final int id;
  final TimeOfDayOfWeek? tdow;
  final TimeOfDayOfWeek? tdowLocal;

  const BinSchedule({
    required this.id,
    this.tdow,
    this.tdowLocal,
  });

  factory BinSchedule.fromDTO({required ScheduleDTO dto}) {
    var tdow = TimeOfDayOfWeek.fromString(
        dowString: dto.dayOfWeek, offsetFrom00: dto.secondsFrom00, isUTC: true);
    return BinSchedule(id: dto.binID, tdow: tdow, tdowLocal: tdow.toLocal());
  }
}

@MappableClass()
class BatteryState with BatteryStateMappable {
  final bool batteryConnected;
  final bool charging;
  final bool chargerConnected;
  final int percent;

  const BatteryState({
    required this.batteryConnected,
    required this.charging,
    required this.chargerConnected,
    required this.percent,
  });

  factory BatteryState.fromDTO(DeviceBatteryStateDto dto) {
    return BatteryState(
        batteryConnected: (dto.con ?? 0) == 1,
        charging: (dto.chg ?? 0) == 1,
        chargerConnected: (dto.usb ?? 0) == 1 || (dto.pg ?? 0) == 1,
        percent: dto.pct ?? 0
    );
  }
}

@MappableClass()
class BinState with BinStateMappable {
  final int id;
  final BinStatus status;
  final DateTime? scheduledTime;
  final String? scheduleId;

  const BinState({
    required this.id,
    required this.status,
    this.scheduledTime,
    this.scheduleId
  });

  factory BinState.fromDTO(DeviceBinStatusDto dto) {
    return BinState(
      id: dto.id,
      status: dto.status != null ? BinStatusMapper.fromValue(dto.status) : BinStatus.noRecord,
      scheduledTime: dto.scheduledTime != null ? DateTime.fromMillisecondsSinceEpoch(
          dto.scheduledTime! * 1000,
          isUtc: true
      ) : null,
      scheduleId: dto.scheduleId
    );
  }
}

@MappableClass()
class DosePeriod with DosePeriodMappable {
  final int binID;
  final DateTime? scheduledTime;
  final BinStatus status;
  final List<int> medicationIDs;
  final String? takenAtTime;

  const DosePeriod({
    required this.binID,
    this.scheduledTime,
    required this.status,
    required this.medicationIDs,
    this.takenAtTime,
  });

  factory DosePeriod.fromDTO(DosePeriodDTO dto) {
    return DosePeriod(
      binID: dto.binID,
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(
              (dto.timestamp ?? 0) * 1000,
              isUtc: true)
          .toLocal(),
      status: BinStatus.values[dto.status],
      medicationIDs: dto.medications ?? List.empty(),
      takenAtTime: dto.takenAtTime,
    );
  }
  static TimeService timeService = TimeService();
}

List<BinStatus> decodePackedStatus(int? bins) {
  if (bins == null) {
    return List.empty(growable: false);
  }

  List<BinStatus> out = []; // '[]' is the idiomatic way to create a growable list in Dart

  for (int i = 0; i < 14; i++) {
    // Shift right by i, then bitwise AND with 1 to isolate the target bit
    bool isTaken = ((bins >> i) & 1) == 1;

    out.add(isTaken ? BinStatus.taken : BinStatus.disabled);
  }

  return out;
}

List<bool> _bitmaskToBoolList(int mask) {
  // 14 bits correspond to the 14 physical pill bins on the device
  return List.generate(14, (i) => ((mask >> i) & 1) == 1);
}

@MappableClass()
class ReloadState with ReloadStateMappable {
  final bool needed;
  final List<bool>? progress;
  final List<bool>? completeMask;

  const ReloadState({
    required this.needed,
    this.progress,
    this.completeMask,
  });

  factory ReloadState.fromDTO(ReloadStateDto dto) {
    return ReloadState(
      needed: dto.needed,
      progress: dto.progress != null ? _bitmaskToBoolList(dto.progress!) : null,
      completeMask: dto.completeMask != null ? _bitmaskToBoolList(dto.completeMask!) : null,
    );
  }
}

@MappableClass()
class DeviceState with DeviceStateMappable {
  final String id;
  final DateTime? lastSync;
  final List<BinState> bins;
  final BatteryState? battery;
  final int? doors;
  final DateTime? epochWeek;
  final Set<DeviceErrorFlag> errors;
  final String? scheduleId;
  final ReloadState? reloadState;
  final TimeZoneLocation? timezone;

  const DeviceState({
    required this.id,
    this.lastSync,
    required this.bins,
    this.battery,
    this.doors,
    this.epochWeek,
    required this.errors,
    this.scheduleId,
    this.reloadState,
    this.timezone,
  });

  factory DeviceState.fromDTO(DeviceStateDto dto, {String? deviceId}) {
    return DeviceState(
      id: deviceId!,
      lastSync: DateTime.fromMillisecondsSinceEpoch(dto.timestamp, isUtc: true),
      bins: dto.bins?.map((e) => BinState.fromDTO(e)).toList() ?? List.empty(),
      battery: dto.battery != null ? BatteryState.fromDTO(dto.battery!) : null,
      doors: dto.doors,
        epochWeek: dto.epochWeek != null
            ? DateTime.fromMillisecondsSinceEpoch(dto.epochWeek! * 1000, isUtc: true)
            : null,
        errors: dto.errorFlags != null
            ? DeviceErrorFlag.fromBitfield(dto.errorFlags!)
            : const {},
        scheduleId: dto.scheduleId,
        reloadState: dto.reload != null ? ReloadState.fromDTO(dto.reload!) : null,
        timezone: lookupTimeZoneLocation(dto.timezoneIana),
    );
  }

  /// Check if a specific bin is physically open based on the doors bitfield
  bool isBinOpen(int binIndex) {
    if (doors == null) return false;
    return (doors! & (1 << binIndex)) != 0;
  }
}

enum DeviceModel {
  unknown,
  v1;

  static DeviceModel fromString(String? modelId) {
    if (modelId == "v1_7x2") {
      return DeviceModel.v1;
    } else {
      return DeviceModel.unknown;
    }
  }
}

@MappableClass()
class DeviceMetadata with DeviceMetadataMappable {
  final String id;
  final String? nickname;
  final String? serialNo;
  final DeviceModel model;
  final String? tenantName;
  final String tenantId;
  final String apiBase;
  final bool primaryUser;
  final String? thingName;
  final bool showTenant;
  final bool notifications;
  final bool notifyTakeNow;
  final bool notifyTaken;
  final bool notifyMissed;

  const DeviceMetadata({
    required this.id,
    required this.nickname,
    required this.serialNo,
    required this.model,
    required this.tenantName,
    required this.tenantId,
    required this.apiBase,
    required this.primaryUser,
    required this.thingName,
    required this.showTenant,
    this.notifications = false,
    this.notifyTakeNow = true,
    this.notifyTaken = true,
    this.notifyMissed = true,
  });

  String get name => nickname ?? 'Device #$id';
}

@MappableClass()
class DeviceConfig with DeviceConfigMappable {
  final String? timezone;

  const DeviceConfig({this.timezone});
}

extension DeviceDtoMapper on DeviceAccessDto {
  DeviceMetadata toDomain() {
    return DeviceMetadata(
      id: deviceId,
      nickname: nickname,
      serialNo: serialNo,
      model: DeviceModel.fromString(modelId),
      tenantId: tenantId,
      tenantName: tenantName,
      apiBase: apiBase,
      primaryUser: primaryUser,
      thingName: thingName,
      showTenant: tenantName != null,
      notifications: notifications ?? false,
      notifyTakeNow: notifyTakeNow ?? true,
      notifyTaken: notifyTaken ?? true,
      notifyMissed: notifyMissed ?? true,
    );
  }
}