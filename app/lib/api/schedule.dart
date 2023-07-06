import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../service/time_service.dart';
import 'api.dart';
import 'device.dart';

part 'schedule.freezed.dart';

@freezed
class MedicationDispenseTime extends Equatable with _$MedicationDispenseTime {
  const MedicationDispenseTime._();
  const factory MedicationDispenseTime({
    required int dispenseTimeID,
    required int quantity,
    required DayPeriod period,
    required TimeOfDay timeOfDay
  }) = _MedicationDispenseTime;
  @override
  List<Object?> get props => [dispenseTimeID, quantity, period, timeOfDay];

  factory MedicationDispenseTime.fromDTO(MedicationDispenseTimeDTO dto) {
    return MedicationDispenseTime(
      dispenseTimeID: dto.dispenseID!,
      quantity: dto.quantity!,
      period: dto.dispense?.period == "A" ? DayPeriod.am : DayPeriod.pm,
      timeOfDay: timeOfDayFromSecondsFrom00(dto.dispense!.time!, isUTC: false)
    );
  }

}

@freezed
class DispenseTime extends Equatable with _$DispenseTime {
  const DispenseTime._();
  const factory DispenseTime({
    int? id,
    required TimeOfDay time,
    required DayPeriod period
  }) = _DispenseTime;
  @override
  List<Object?> get props => [id, time];
}

@freezed
class SimpleSchedule extends Equatable with _$SimpleSchedule {
  const SimpleSchedule._();
  const factory SimpleSchedule({
    DispenseTime? am,
    DispenseTime? pm
  }) = _SimpleSchedule;

  factory SimpleSchedule.fromDTO(SimpleScheduleDTO dto) {
    return SimpleSchedule(
      am: dto.amSecondsFrom00 != null
          ? DispenseTime(
            id: dto.amID,
            time: timeOfDayFromSecondsFrom00(dto.amSecondsFrom00!, isUTC: false),
            period: DayPeriod.am
          ) : null,
      pm: dto.pmSecondsFrom00 != null
          ? DispenseTime(
            id: dto.pmID,
            time: timeOfDayFromSecondsFrom00(dto.pmSecondsFrom00!, isUTC: false),
            period: DayPeriod.pm
          ) : null
    );
  }

  SimpleScheduleDTO toDTO() {
    return SimpleScheduleDTO(
      amID: am?.id,
      pmID: pm?.id,
      amSecondsFrom00: am?.time.toSecondsFrom00(),
      pmSecondsFrom00: pm?.time.toSecondsFrom00()
    );
  }

  @override
  List<Object?> get props => [am, pm];
}

class ScheduleRepository {
  const ScheduleRepository({
    required this.client
  });

  final RestClient client;

  Future<SimpleSchedule> getDispenseTimes(int deviceID) {
    return client.getDispenseTimes(deviceID)
      .then((value) => SimpleSchedule.fromDTO(value));
  }

  Future<SimpleSchedule> updateDispenseTimes(int deviceID, SimpleSchedule schedule) {
    return client.updateDispenseTimes(deviceID, schedule.toDTO())
        .then((value) => SimpleSchedule.fromDTO(value));
  }

}

class ScheduleProvider with ChangeNotifier {
  SimpleSchedule? get schedule  => _schedule;
  SimpleSchedule? _schedule;
  Future<SimpleSchedule?>? get future => _future;
  Future<SimpleSchedule?>? _future;
  int? deviceID;

  @override
  void dispose() {
    super.dispose();
  }

  final ScheduleRepository repo = ScheduleRepository(client: client);

  ScheduleProvider update(DeviceUser? selected) {
    if(selected != null) {
      load(selected.deviceID);
    }
    return this;
  }

  ScheduleProvider({SimpleSchedule? schedule, DeviceUser? selectedDevice, int? deviceID}) {
    _schedule = schedule;
    if(selectedDevice != null) {
      load(selectedDevice.deviceID);
    } else if(deviceID != null) {
      load(deviceID!);
    }
  }

  Future<SimpleSchedule?> load(int deviceID) {
    this.deviceID = deviceID;
    var resp = repo.getDispenseTimes(deviceID)
      .then((value) {
        _schedule = value;
        notifyListeners();
        return _schedule;
      });
    _future = resp;
    notifyListeners();
    return resp;
  }

  Future<SimpleSchedule?> updateTime(DayPeriod period, TimeOfDay tod) {
    _schedule ??= const SimpleSchedule();
    if(period == DayPeriod.am) {
      _schedule = _schedule?.copyWith(am: _schedule?.am?.copyWith(time: tod)
          ?? DispenseTime(time: tod, period: DayPeriod.am));
    } else if(period == DayPeriod.pm) {
      _schedule = _schedule?.copyWith(pm: _schedule?.pm?.copyWith(time: tod)
          ?? DispenseTime(time: tod, period: DayPeriod.pm));
    }
    return repo.updateDispenseTimes(deviceID!, _schedule!)
      .then((value) {
        _schedule = value;
        notifyListeners();
        return value;
      });
  }



}