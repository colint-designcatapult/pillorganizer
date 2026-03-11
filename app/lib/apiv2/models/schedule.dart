import 'package:app/api/api.dart';
import 'package:app/service/time_service.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'schedule.mapper.dart';

@MappableClass()
class MedicationDispenseTime extends Equatable with MedicationDispenseTimeMappable {
  final int dispenseTimeID;
  final int quantity;
  final DayPeriod period;
  final TimeOfDay timeOfDay;

  const MedicationDispenseTime({
    required this.dispenseTimeID,
    required this.quantity,
    required this.period,
    required this.timeOfDay,
  });

  @override
  List<Object?> get props => [dispenseTimeID, quantity, period, timeOfDay];

  factory MedicationDispenseTime.fromDTO(MedicationDispenseTimeDTO dto) {
    return MedicationDispenseTime(
      dispenseTimeID: dto.dispenseID!,
      quantity: dto.quantity!,
      period: dto.dispense?.period == "A" ? DayPeriod.am : DayPeriod.pm,
      timeOfDay: timeOfDayFromSecondsFrom00(dto.dispense!.time!, isUTC: false),
    );
  }
}

@MappableClass()
class DispenseTime extends Equatable with DispenseTimeMappable {
  final int? id;
  final TimeOfDay time;
  final DayPeriod period;

  const DispenseTime({
    this.id,
    required this.time,
    required this.period,
  });

  @override
  List<Object?> get props => [id, time, period];
}

@MappableClass()
class SimpleSchedule extends Equatable with SimpleScheduleMappable {
  final DispenseTime? am;
  final DispenseTime? pm;

  const SimpleSchedule({this.am, this.pm});

  factory SimpleSchedule.fromDTO(SimpleScheduleDTO dto) {
    return SimpleSchedule(
      am: dto.amSecondsFrom00 != null
          ? DispenseTime(
              id: dto.amID,
              time: timeOfDayFromSecondsFrom00(dto.amSecondsFrom00!, isUTC: false),
              period: DayPeriod.am,
            )
          : null,
      pm: dto.pmSecondsFrom00 != null
          ? DispenseTime(
              id: dto.pmID,
              time: timeOfDayFromSecondsFrom00(dto.pmSecondsFrom00!, isUTC: false),
              period: DayPeriod.pm,
            )
          : null,
    );
  }

  SimpleScheduleDTO toDTO() {
    return SimpleScheduleDTO(
      amID: am?.id,
      pmID: pm?.id,
      amSecondsFrom00: am != null ? am!.time.hour * 3600 + am!.time.minute * 60 : null,
      pmSecondsFrom00: pm != null ? pm!.time.hour * 3600 + pm!.time.minute * 60 : null,
    );
  }

  @override
  List<Object?> get props => [am, pm];
}
