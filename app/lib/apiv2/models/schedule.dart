import 'package:app/api/api.dart';
import 'package:app/apiv2/models/dto.dart';
import 'package:app/service/time_service.dart' show timeOfDayFromSecondsFrom00;
import 'package:dart_mappable/dart_mappable.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'schedule.mapper.dart';

// V1 — used by legacy medication system
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

// V2 domain models

class DeviceScheduleState {
  final DeviceSchedule? currentSchedule;
  final DeviceSchedule? requestedSchedule;
  final ScheduleStatus? requestedStatus;

  const DeviceScheduleState({
    this.currentSchedule,
    this.requestedSchedule,
    this.requestedStatus,
  });

  BaseSchedule? get effectiveSchedule =>
      requestedSchedule?.schedule ?? currentSchedule?.schedule;

  String? get effectiveTimezoneIana =>
      requestedSchedule?.timezoneIana ?? currentSchedule?.timezoneIana;
}

class DeviceSchedule {
  final String id;
  final ScheduleTakeEffect? takeEffect;
  final BaseSchedule? schedule;
  final String? timezoneIana;

  const DeviceSchedule({
    required this.id,
    this.takeEffect,
    this.schedule,
    this.timezoneIana,
  });
}

abstract class BaseSchedule {
  const BaseSchedule();
}

class SimpleSchedule extends BaseSchedule {
  final List<DosePeriodV2> bins;

  const SimpleSchedule({required this.bins});

  DosePeriodV2? get amPeriod {
    for (final bin in bins) {
      if (bin.time.hour < 12) return bin;
    }
    return null;
  }

  DosePeriodV2? get pmPeriod {
    for (final bin in bins) {
      if (bin.time.hour >= 12) return bin;
    }
    return null;
  }
}

class DosePeriodV2 {
  final DayOfWeek dayOfWeek;
  final TimeOfDay time;

  const DosePeriodV2({required this.dayOfWeek, required this.time});
}

class SetScheduleRequest {
  final BaseSchedule schedule;
  final ScheduleTakeEffect takeEffect;
  final String timezoneIana;

  const SetScheduleRequest({required this.schedule, required this.takeEffect, required this.timezoneIana});
}

// DTO -> Domain

extension DeviceScheduleStateDtoX on DeviceScheduleStateDto {
  DeviceScheduleState toDomain() => DeviceScheduleState(
        currentSchedule: currentSchedule?.toDomain(),
        requestedSchedule: requestedSchedule?.toDomain(),
        requestedStatus: requestedStatus,
      );
}

extension DeviceScheduleDtoX on DeviceScheduleDto {
  DeviceSchedule toDomain() => DeviceSchedule(
        id: id,
        takeEffect: takeEffect,
        schedule: schedule?.toDomain(),
        timezoneIana: timezoneIana,
      );
}

extension BaseScheduleDtoX on BaseScheduleDto {
  BaseSchedule toDomain() {
    if (this is SimpleScheduleDto) {
      final s = this as SimpleScheduleDto;
      return SimpleSchedule(bins: s.bins.map((b) => b.toDomain()).toList());
    }
    throw UnsupportedError('Unknown schedule DTO type: $runtimeType');
  }
}

extension DosePeriodDtoX on DosePeriodDto {
  DosePeriodV2 toDomain() {
    final parts = time.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return DosePeriodV2(
      dayOfWeek: dayOfWeek,
      time: TimeOfDay(hour: hour, minute: minute),
    );
  }
}

// Domain -> DTO

extension DeviceScheduleStateX on DeviceScheduleState {
  DeviceScheduleStateDto toDto() => DeviceScheduleStateDto(
        currentSchedule: currentSchedule?.toDto(),
        requestedSchedule: requestedSchedule?.toDto(),
        requestedStatus: requestedStatus,
      );
}

extension DeviceScheduleX on DeviceSchedule {
  DeviceScheduleDto toDto() => DeviceScheduleDto(
        id: id,
        takeEffect: takeEffect,
        schedule: schedule?.toDto(),
        timezoneIana: timezoneIana,
      );
}

extension BaseScheduleX on BaseSchedule {
  BaseScheduleDto toDto() {
    if (this is SimpleSchedule) {
      final s = this as SimpleSchedule;
      return SimpleScheduleDto(bins: s.bins.map((b) => b.toDto()).toList());
    }
    throw UnsupportedError('Unknown schedule type: $runtimeType');
  }
}

extension DosePeriodV2X on DosePeriodV2 {
  DosePeriodDto toDto() => DosePeriodDto(
        dayOfWeek: dayOfWeek,
        time:
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      );
}
