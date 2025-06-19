import 'dart:async';

import 'package:app/service/time_service.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:timezone/standalone.dart' as tz;

import '../service/notification_service.dart';
import 'api.dart';

part 'device.freezed.dart';

enum BinStatus { DISABLED, TAKEN, MISSED, PENDING, TAKE_NOW }

enum EventType { OPENED, CLOSED, MISSED }

@freezed
class BinEvent with _$BinEvent {
  const BinEvent._();

  const factory BinEvent(
      {required int id,
      required int bin,
      DateTime? time,
      DateTime? timeLocal,
      EventType? eventType}) = _BinEvent;

  factory BinEvent.fromDTO({required BinEventDTO dto}) {
    DateTime dt = timeService.serverTime(dto.ts);
    return BinEvent(
        id: dto.id,
        bin: dto.bin,
        time: dt,
        timeLocal: timeService.serverTimeToLocal(dto.ts),
        eventType: EventType.values.byName(dto.eventType));
  }

  static TimeService timeService = TimeService();
}

@freezed
class BinSchedule with _$BinSchedule {
  const BinSchedule._();

  const factory BinSchedule(
      {required int id,
      TimeOfDayOfWeek? tdow,
      TimeOfDayOfWeek? tdowLocal}) = _BinSchedule;

  factory BinSchedule.fromDTO({required ScheduleDTO dto}) {
    var tdow = TimeOfDayOfWeek.fromString(
        dowString: dto.dayOfWeek, offsetFrom00: dto.secondsFrom00, isUTC: true);
    return BinSchedule(id: dto.binID, tdow: tdow, tdowLocal: tdow.toLocal());
  }
}

@freezed
class BinState with _$BinState {
  const BinState._();

  const factory BinState(
      {required DeviceBinID id,
      BinStatus? binStatus,
      DateTime? scheduledTime,
      DateTime? scheduledTimeLocal,
      BinSchedule? schedule,
      BinEvent? event}) = _BinState;

  factory BinState.fromDTO({required BinStateDTO dto}) {
    DateTime scheduledTimeUTC =
        timeService.serverTime(dto.scheduledTime * 1000);
    return BinState(
        id: dto.id,
        binStatus: BinStatus.values.byName(dto.binStatus),
        scheduledTime: scheduledTimeUTC,
        scheduledTimeLocal:
            timeService.serverTimeToLocal(dto.scheduledTime * 1000),
        schedule: dto.schedule != null
            ? BinSchedule.fromDTO(dto: dto.schedule!)
            : null,
        event: dto.event != null ? BinEvent.fromDTO(dto: dto.event!) : null);
  }

  static TimeService timeService = TimeService();
}

@freezed
class DosePeriod with _$DosePeriod {
  const DosePeriod._();

  const factory DosePeriod(
      {required int binID,
      DateTime? scheduledTime,
      required BinStatus status,
      required List<int> medicationIDs,
      String? takenAtTime}) = _DosePeriod;

  factory DosePeriod.fromDTO(DosePeriodDTO dto) {
    return DosePeriod(
        binID: dto.binID,
        scheduledTime: DateTime.fromMillisecondsSinceEpoch(
                (dto.timestamp ?? 0) * 1000,
                isUtc: true)
            .toLocal(),
        status: BinStatus.values[dto.status],
        medicationIDs: dto.medications ?? List.empty(),
        takenAtTime: dto.takenAtTime);
  }
  static TimeService timeService = TimeService();
}

List<BinStatus> decodePackedStatus(int? bins) {
  if (bins == null) {
    return List.empty(growable: false);
  }

  List<BinStatus> out = List.empty(growable: true);

  for (int i = 0; i < 14; i++) {
    int statusInt = (bins >> (i * 4)) & 0xf;
    out.add(BinStatus.values[statusInt]);
  }

  return out;
}

@freezed
class DeviceState extends Equatable with _$DeviceState {
  const DeviceState._();

  const factory DeviceState(
      {required int id,
      DateTime? lastSync,
      required List<BinStatus> bins,
      required List<DosePeriod> dosePeriods,
      int? battery,
      bool? charging}) = _DeviceState;

  factory DeviceState.fromDTO(DeviceStateDTO dto) {
    DateTime? lastSeen = dto.lastSync != null
        ? DateTime.fromMillisecondsSinceEpoch(dto.lastSync!, isUtc: true)
        : null;

    return DeviceState(
        id: dto.id,
        lastSync: lastSeen,
        bins: decodePackedStatus(dto.bins),
        dosePeriods:
            dto.dosePeriods?.map((e) => DosePeriod.fromDTO(e)).toList() ??
                List<DosePeriod>.empty(),
        battery: dto.battery,
        charging: dto.charging);
  }

  @override
  List<Object?> get props => [id, lastSync, bins, dosePeriods];
}

typedef DeviceListProvider = RefreshableValueNotifier<List<DeviceUser>>;

class DeviceRepository {
  DeviceRepository({required this.client}) {
    deviceListProvider = DeviceListProvider(null, myDevices);
  }

  final RestClient client;
  late final DeviceListProvider deviceListProvider;

  Future<List<DeviceUser>> myDevices() {
    return client.listMyDevices().then((res) => res
        .map((e) => DeviceUser.fromDTO(dto: e))
        .sortedBy<num>((element) => element.id)
        .toList(growable: false));
  }

  Future<DeviceState> deviceState(int deviceID, DateTime date) {
    NumberFormat formatter = NumberFormat("00");
    String iso = '${date.year}-${formatter.format(date.month)}'
        '-${formatter.format(date.day)}';
    return client.stateDate(deviceID, iso).then((value) {
      return DeviceState.fromDTO(value);
    });
  }

  Future<DeviceUser> update(int deviceID,
      {String? name, bool? notifications, TimeZoneLocation? timezone}) async {
    String? notificationToken;
    if (notifications ?? false) {
      notificationToken = await enablePushNotifications();
    }

    return client
        .setDeviceSettings(
            deviceID,
            UpdateDeviceUserSettings(
                deviceName: name,
                notificationToken: notificationToken,
                notifications: notifications,
                timezone: timezone?.name))
        .then((value) => DeviceUser.fromDTO(dto: value));
  }
}

final DeviceRepository deviceRepo = DeviceRepository(client: client);

bool isOnlineFromLastSeen(DateTime? lastSeen) {
  if (lastSeen == null) {
    return false;
  }
  DateTime now = DateTime.now();
  Duration diff = now.difference(lastSeen);
  return !(diff.inSeconds > 60);
}

@freezed
class DeviceUser extends Equatable with _$DeviceUser {
  const DeviceUser._();
  const factory DeviceUser({
    required int id,
    required int deviceID,
    required String deviceClass,
    required String name,
    required int serialNo,
    required bool isOnline,
    DateTime? lastSeen,
    required bool primaryUser,
    required bool owner,
    required bool notifications,
    tz.Location? timezone,
  }) = _DeviceUser;

  factory DeviceUser.fromDTO({required DeviceUserDTO dto}) {
    DateTime? lastSeen = dto.lastSync != null
        ? DateTime.fromMillisecondsSinceEpoch(dto.lastSync!, isUtc: true)
        : null;

    return DeviceUser(
      id: dto.id,
      deviceID: dto.deviceID,
      deviceClass: dto.deviceClass,
      name: dto.customName ?? 'Device #${dto.deviceID}',
      serialNo: dto.serialNo,
      isOnline: isOnlineFromLastSeen(lastSeen),
      primaryUser: dto.primaryUser,
      owner: dto.owner,
      lastSeen: lastSeen,
      notifications: dto.notifications,
      timezone: lookupTimeZoneLocation(dto.timezone),
    );
  }

  @override
  List<Object?> get props => [
        id,
        deviceID,
        deviceClass,
        name,
        serialNo,
        isOnline,
        primaryUser,
        owner,
        notifications,
        timezone,
      ];
}

enum DeviceConnectionStatus { undefined, offline, online, loading }

class DeviceStateProvider extends RefreshableValueNotifier<DeviceState?> {
  DateTime? _baseDate;
  DeviceUser? _device;

  DeviceStateProvider() : super(null, () => Future.value(null));

  DeviceStateProvider update(DateTime? date, DeviceUser? selected) {
    if (date != null) {
      _baseDate = date;
    }
    if (selected != null && selected.id != _device?.id) {
      _device = selected;
      loadFunction = _load;
      value = null;
      //refresh();
      notifyListeners();
    }
    return this;
  }

  Future<DeviceState?> _load() {
    if (_device == null || _baseDate == null) {
      return Future.value(null);
    } else {
      return deviceRepo.deviceState(_device!.deviceID, _baseDate!);
    }
  }
}

enum DeviceNotice { none, disconnected, empty }
