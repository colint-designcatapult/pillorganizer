import 'package:app/apiv2/models/dto.dart';
import 'package:app/service/time_service.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:app/api/api.dart'; // For DTOs if they are still there

part 'device.mapper.dart';

@MappableEnum(caseStyle: CaseStyle.upperCase)
enum BinStatus { disabled, taken, missed, pending, takeNow }

@MappableEnum(caseStyle: CaseStyle.upperCase)
enum EventType { opened, closed, missed }

enum DeviceConnectionStatus { undefined, offline, online, loading }

enum DeviceNotice { none, disconnected, empty }

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
class BinState with BinStateMappable {
  final DeviceBinID id;
  final BinStatus? binStatus;
  final DateTime? scheduledTime;
  final DateTime? scheduledTimeLocal;
  final BinSchedule? schedule;
  final BinEvent? event;

  const BinState({
    required this.id,
    this.binStatus,
    this.scheduledTime,
    this.scheduledTimeLocal,
    this.schedule,
    this.event,
  });

  factory BinState.fromDTO({required BinStateDTO dto}) {
    DateTime scheduledTimeUTC = timeService.serverTime(dto.scheduledTime * 1000);
    return BinState(
      id: dto.id,
      binStatus: BinStatus.values.byName(dto.binStatus.toLowerCase()),
      scheduledTime: scheduledTimeUTC,
      scheduledTimeLocal: timeService.serverTimeToLocal(dto.scheduledTime * 1000),
      schedule: dto.schedule != null ? BinSchedule.fromDTO(dto: dto.schedule!) : null,
      event: dto.event != null ? BinEvent.fromDTO(dto: dto.event!) : null,
    );
  }

  static TimeService timeService = TimeService();
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

@MappableClass()
class DeviceState extends Equatable with DeviceStateMappable {
  final String id;
  final DateTime? lastSync;
  final List<BinStatus> bins;
  final List<DosePeriod> dosePeriods;
  final int? battery;
  final bool? charging;

  const DeviceState({
    required this.id,
    this.lastSync,
    required this.bins,
    required this.dosePeriods,
    this.battery,
    this.charging,
  });

  factory DeviceState.fromDTO(DeviceStateDTO dto) {
    DateTime? lastSeen = dto.lastSync != null
        ? DateTime.fromMillisecondsSinceEpoch(dto.lastSync!, isUtc: true)
        : null;

    return DeviceState(
      id: dto.id.toString(),
      lastSync: lastSeen,
      bins: decodePackedStatus(dto.bins),
      dosePeriods: dto.dosePeriods?.map((e) => DosePeriod.fromDTO(e)).toList() ??
          List<DosePeriod>.empty(),
      battery: dto.battery,
      charging: dto.charging,
    );
  }

  @override
  List<Object?> get props => [id, lastSync, bins, dosePeriods];
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
    required this.showTenant
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
      showTenant: tenantName != null
    );
  }
}