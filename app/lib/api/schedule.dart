import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../service/time_service.dart';
import 'api.dart';
part 'schedule.freezed.dart';

@freezed
abstract class MedicationDispenseTime extends Equatable with _$MedicationDispenseTime {
  const MedicationDispenseTime._();
  const factory MedicationDispenseTime(
      {required int dispenseTimeID,
      required int quantity,
      required DayPeriod period,
      required TimeOfDay timeOfDay}) = _MedicationDispenseTime;
  @override
  List<Object?> get props => [dispenseTimeID, quantity, period, timeOfDay];

  factory MedicationDispenseTime.fromDTO(MedicationDispenseTimeDTO dto) {
    return MedicationDispenseTime(
        dispenseTimeID: dto.dispenseID!,
        quantity: dto.quantity!,
        period: dto.dispense?.period == "A" ? DayPeriod.am : DayPeriod.pm,
        timeOfDay:
            timeOfDayFromSecondsFrom00(dto.dispense!.time!, isUTC: false));
  }
}

@freezed
abstract class DispenseTime extends Equatable with _$DispenseTime {
  const DispenseTime._();
  const factory DispenseTime(
      {int? id,
      required TimeOfDay time,
      required DayPeriod period}) = _DispenseTime;
  @override
  List<Object?> get props => [id, time];
}

@freezed
abstract class SimpleSchedule extends Equatable with _$SimpleSchedule {
  const SimpleSchedule._();
  const factory SimpleSchedule({DispenseTime? am, DispenseTime? pm}) =
      _SimpleSchedule;

  factory SimpleSchedule.fromDTO(SimpleScheduleDTO dto) {
    return SimpleSchedule(
        am: dto.amSecondsFrom00 != null
            ? DispenseTime(
                id: dto.amID,
                time: timeOfDayFromSecondsFrom00(dto.amSecondsFrom00!,
                    isUTC: false),
                period: DayPeriod.am)
            : null,
        pm: dto.pmSecondsFrom00 != null
            ? DispenseTime(
                id: dto.pmID,
                time: timeOfDayFromSecondsFrom00(dto.pmSecondsFrom00!,
                    isUTC: false),
                period: DayPeriod.pm)
            : null);
  }

  SimpleScheduleDTO toDTO() {
    return SimpleScheduleDTO(
        amID: am?.id,
        pmID: pm?.id,
        amSecondsFrom00: am?.time.toSecondsFrom00(),
        pmSecondsFrom00: pm?.time.toSecondsFrom00());
  }

  @override
  List<Object?> get props => [am, pm];
}

class ScheduleRepository {
  const ScheduleRepository({required this.client});

  final RestClient client;

  Future<SimpleSchedule> getDispenseTimes(String deviceID) {
    return client
        .getDispenseTimes(deviceID)
        .then((value) => SimpleSchedule.fromDTO(value));
  }

  Future<SimpleSchedule> updateDispenseTimes(
      String deviceID, SimpleSchedule schedule) {
    return client
        .updateDispenseTimes(deviceID, schedule.toDTO())
        .then((value) => SimpleSchedule.fromDTO(value));
  }
}
