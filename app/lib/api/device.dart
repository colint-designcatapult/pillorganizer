import 'dart:async';

import 'package:app/service/time_service.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/standalone.dart' as tz;

import '../service/notification_service.dart';
import 'api.dart';

part 'device.freezed.dart';

enum BinStatus {
  DISABLED,
  TAKEN,
  MISSED,
  PENDING,
  TAKE_NOW
}

enum EventType {
  OPENED,
  CLOSED,
  MISSED
}


@freezed
class BinEvent with _$BinEvent {
  const BinEvent._();

  const factory BinEvent({
    required int id,
    required int bin,
    DateTime? time,
    DateTime? timeLocal,
    EventType? eventType
  }) = _BinEvent;

  factory BinEvent.fromDTO({required BinEventDTO dto}) {
    DateTime dt = timeService.serverTime(dto.ts);
    return BinEvent(
      id: dto.id,
      bin: dto.bin,
      time: dt,
      timeLocal: timeService.serverTimeToLocal(dto.ts),
      eventType: EventType.values.byName(dto.eventType)
    );
  }

  static TimeService timeService = TimeService();

}

@freezed
class BinSchedule with _$BinSchedule {
  const BinSchedule._();

  const factory BinSchedule({
    required int id,
    TimeOfDayOfWeek? tdow,
    TimeOfDayOfWeek? tdowLocal
  }) = _BinSchedule;

  factory BinSchedule.fromDTO({required ScheduleDTO dto}) {
    var tdow = TimeOfDayOfWeek.fromString(
        dowString: dto.dayOfWeek,
        offsetFrom00: dto.secondsFrom00,
        isUTC: true
    );
    return BinSchedule(
      id: dto.binID,
      tdow: tdow,
      tdowLocal: tdow.toLocal()
    );
  }

}

@freezed
class BinState with _$BinState {
  const BinState._();

  const factory BinState({
    required DeviceBinID id,
    BinStatus? binStatus,
    DateTime? scheduledTime,
    DateTime? scheduledTimeLocal,
    BinSchedule? schedule,
    BinEvent? event
  }) = _BinState;

  factory BinState.fromDTO({required BinStateDTO dto}) {
    DateTime scheduledTimeUTC = timeService.serverTime(dto.scheduledTime * 1000);
    return BinState(
      id: dto.id,
      binStatus: BinStatus.values.byName(dto.binStatus),
      scheduledTime: scheduledTimeUTC,
      scheduledTimeLocal: timeService.serverTimeToLocal(dto.scheduledTime * 1000),
      schedule: dto.schedule != null ? BinSchedule.fromDTO(dto: dto.schedule!) : null,
      event: dto.event != null ? BinEvent.fromDTO(dto: dto.event!) : null
    );
  }

  static TimeService timeService = TimeService();
}

@freezed
class DosePeriod with _$DosePeriod {
  const DosePeriod._();

  const factory DosePeriod({
    required int binID,
    DateTime? scheduledTime,
    required BinStatus status,
    required List<int> medicationIDs,
  }) = _DosePeriod;

  factory DosePeriod.fromDTO(DosePeriodDTO dto) {
    return DosePeriod(
      binID: dto.binID,
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(
          (dto.timestamp ?? 0) * 1000,
          isUtc: true
      ).toLocal(),
      status: BinStatus.values[dto.status],
      medicationIDs: dto.medications ?? List.empty()
    );
  }
  static TimeService timeService = TimeService();

}


List<BinStatus> decodePackedStatus(int? bins) {
  if(bins == null) {
    return List.empty(growable: false);
  }

  List<BinStatus> out = List.empty(growable: true);

  for(int i = 0; i < 14; i++) {
    int statusInt = (bins >> (i * 4)) & 0xf;
    out.add(BinStatus.values[statusInt]);
  }

  return out;
}

@freezed
class DeviceState extends Equatable with _$DeviceState {
  const DeviceState._();

  const factory DeviceState({
    required int id,
    DateTime? lastSync,
    required List<BinStatus> bins,
    required List<DosePeriod> dosePeriods
  }) = _DeviceState;



  factory DeviceState.fromDTO(DeviceStateDTO dto) {
    DateTime? lastSeen = dto.lastSync != null
        ? DateTime.fromMillisecondsSinceEpoch(dto.lastSync!, isUtc: true)
        : null;

    return DeviceState(
      id: dto.id,
      lastSync: lastSeen,
      bins: decodePackedStatus(dto.bins),
      dosePeriods: dto.dosePeriods?.map((e) => DosePeriod.fromDTO(e)).toList()
          ?? List<DosePeriod>.empty()
    );
  }

  @override
  List<Object?> get props => [id, lastSync, bins, dosePeriods];

}

typedef DeviceListProvider = RefreshableValueNotifier<List<DeviceUser>>;

class DeviceRepository {
  DeviceRepository({
    required this.client
  }) {
    deviceListProvider = DeviceListProvider(null, myDevices);
  }

  final RestClient client;
  late final DeviceListProvider deviceListProvider;

  Future<List<DeviceUser>> myDevices() {
    return client.listMyDevices()
        .then((res) => res.map((e) => DeviceUser.fromDTO(dto: e))
        .sortedBy<num>((element) => element.id)
        .toList(growable: false));
  }

  Future<DeviceState> deviceState(int deviceID, DateTime date) {
    NumberFormat formatter = NumberFormat("00");
    String iso = '${date.year}-${formatter.format(date.month)}'
        '-${formatter.format(date.day)}';
    return client.stateDate(deviceID, iso)
          .then((value) => DeviceState.fromDTO(value));
  }

  Future<DeviceUser> update(int deviceID, {String? name, bool? notifications, TimeZoneLocation? timezone}) async {
    String? notificationToken;
    if(notifications ?? false) {
      notificationToken = await enablePushNotifications();
    }

    return client.setDeviceSettings(deviceID, UpdateDeviceUserSettings(
        deviceName: name,
        notificationToken: notificationToken,
        notifications: notifications,
        timezone: timezone?.name
    )).then((value) => DeviceUser.fromDTO(dto: value));
  }

}

final DeviceRepository deviceRepo = DeviceRepository(client: client);

bool isOnlineFromLastSeen(DateTime? lastSeen) {
  if(lastSeen == null) {
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
  List<Object?> get props => [id, deviceID, deviceClass, name, serialNo, isOnline, primaryUser, owner, notifications, timezone];
}



class SelectedDeviceProvider with ChangeNotifier {
  List<DeviceUser>? _devices;
  DeviceUser? get device => _selectedDevice;
  DeviceUser? _selectedDevice;
  int? _prevID;
  int? _selectedID;
  static const String lastSelectedKeyName = "selectedDeviceID";

  SelectedDeviceProvider() {
    _loadSaved();
  }

  SelectedDeviceProvider update(List<DeviceUser>? deviceList) {
    _devices = deviceList;
    if(_selectedID != null) {
      _selectDeviceByID(_selectedID!);
    } else if(deviceList != null && deviceList.isNotEmpty) {
      _selectDeviceByID(deviceList.first.deviceID);
    }
    return this;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if(prefs.containsKey(lastSelectedKeyName)) {
      int? selected = prefs.getInt(lastSelectedKeyName);
      if(selected != null) {
        _selectDeviceByID(selected);
      }
    }
  }

  Future<void> _persistSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if(_selectedID != null) {
      prefs.setInt(lastSelectedKeyName, _selectedID!);
    }
  }

  void selectDeviceByID(int deviceID) {
    if(_prevID != deviceID) {
      _selectDeviceByID(deviceID);
    }
  }

  void selectDevice(DeviceUser du) {
    _selectDeviceByID(du.deviceID);
  }

  void _selectDeviceByID(int deviceID) {
    _prevID = _selectedID;
    _selectedID = deviceID;
    _selectedDevice = _devices?.firstWhereOrNull(
            (element) => element.deviceID == deviceID);
    _persistSaved();
    notifyListeners();
  }


  Future<void> updateName(String newName) async {
    var newDevice = await deviceRepo.update(
        _selectedDevice!.deviceID,
        name: newName
    );
    _selectedDevice = newDevice;
    notifyListeners();
  }

  Future<void> updateTimeZone(TimeZoneLocation newTZ) async {
    var newDevice = await deviceRepo.update(
        _selectedDevice!.deviceID,
        timezone: newTZ
    );
    _selectedDevice = newDevice;
    notifyListeners();
  }

  Future<void> updateNotifications(bool notifications) async {
    var newDevice = await deviceRepo.update(
        _selectedDevice!.deviceID,
        notifications: notifications
    );
    notifyListeners();
    _selectedDevice = newDevice;
  }

}

enum DeviceConnectionStatus {
  undefined,
  offline,
  online,
  loading
}

class DeviceStateProvider extends RefreshableValueNotifier<DeviceState?> {
  DateTime? _baseDate;
  DeviceUser? _device;

  DeviceStateProvider() : super(null, () => Future.value(null));

  DeviceStateProvider update(DateTime? date, DeviceUser? selected) {
    if(date != null) {
      _baseDate = date;
    }
    if(selected != null && selected.id != _device?.id) {
      _device = selected;
      loadFunction = _load;
      value = null;
      //refresh();
      notifyListeners();
    }
    return this;
  }

  Future<DeviceState?> _load() {
    if(_device == null || _baseDate == null) {
      return Future.value(null);
    } else {
      return deviceRepo.deviceState(_device!.deviceID, _baseDate!);
    }
  }
}

class DeviceConnectionStatusProvider extends ChangeNotifier {
  DeviceConnectionStatus _value = DeviceConnectionStatus.undefined;
  DeviceConnectionStatus get value => _value;
  Timer? _stateTimer;
  int _prevStateHash = 0;
  int? _prevID;

  DeviceConnectionStatusProvider() {
    value = DeviceConnectionStatus.loading;
  }

  set value(DeviceConnectionStatus newVal) {
    if(newVal == _value) {
      return;
    }

    _value = newVal;
    if(newVal == DeviceConnectionStatus.loading && _stateTimer == null) {
      _stateTimer = Timer(const Duration(seconds: 15), () {
        if(_value == DeviceConnectionStatus.loading) {
          value = DeviceConnectionStatus.offline;
        }
      });
    } else if(newVal == DeviceConnectionStatus.online) {
      _stateTimer?.cancel();
      _stateTimer = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    _stateTimer?.cancel();
  }

  DeviceConnectionStatusProvider update(DeviceState? state) {
    if(state != null) {
      if(_prevStateHash == state.hashCode) {
        return this;
      }
      _prevStateHash = state.hashCode;

      if(_prevID != state.id) {
        _stateTimer = null;
        _prevID = state.id;
      }

      if(isOnlineFromLastSeen(state.lastSync)) {
        value = DeviceConnectionStatus.online;
      } else {
        value = DeviceConnectionStatus.loading;
      }
    } else {
      value = DeviceConnectionStatus.loading;
    }
    return this;
  }
}

enum DeviceNotice {
  none,
  disconnected,
  empty
}

class DeviceNoticeProvider extends ChangeNotifier {
  DeviceNotice _value = DeviceNotice.none;
  DeviceNotice get value => _value;
  int? _deviceID;
  Future<void>? _reloadFuture;
  Future<void>? get reloadFuture => _reloadFuture;

  set value(DeviceNotice v) {
    if(v != _value) {
      _value = v;
      notifyListeners();
    }
  }

  DeviceNoticeProvider update(DeviceState? state,
      DeviceConnectionStatus status) {
    if(state != null) {
      if(_deviceID != state.id && _reloadFuture != null) {
        _reloadFuture = null;
        notifyListeners();
      }
      _deviceID = state.id;
    }

    if(status == DeviceConnectionStatus.offline) {
      value = DeviceNotice.disconnected;
    } else if(status == DeviceConnectionStatus.online &&
        (state?.dosePeriods.isEmpty ?? true)) {
      value = DeviceNotice.empty;
    } else {
      value = DeviceNotice.none;
    }
    return this;
  }

  void reload() {
    if(_deviceID != null) {
      _reloadFuture = client.reload(_deviceID!);
      notifyListeners();
    }
  }

}