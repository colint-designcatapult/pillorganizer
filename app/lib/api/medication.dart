import 'package:app/api/schedule.dart';
import 'package:app/service/time_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'api.dart';

part 'medication.freezed.dart';

enum MedicationShape {
  capsule,
  // diamond,
  doubleCircle,
  // heptagon,
  hexagon,
  // octagon,
  // oval,
  pentagon,
  //rectangle,
  round,
  // semicircle,
  square,
  tear,
  // trapezoid,
  triangle;

  final bool isEmpty = false;
}

extension MedicationShapeExtension on MedicationShape {
  String get internalName {
    switch (this) {
      case MedicationShape.capsule:
        return 'CAPSULE';
      // case MedicationShape.diamond:
      //   return 'DIAMOND';
      case MedicationShape.doubleCircle:
        return 'DOUBLE_CIRCLE';
      // case MedicationShape.heptagon:
      //   return 'HEPTAGON';
      case MedicationShape.hexagon:
        return 'HEXAGON';
      // case MedicationShape.octagon:
      //   return 'OCTAGON';
      // case MedicationShape.oval:
      //   return 'OVAL';
      case MedicationShape.pentagon:
        return 'PENTAGON';
      // case MedicationShape.rectangle:
      //   return 'RECTANGLE';
      case MedicationShape.round:
        return 'ROUND';
      // case MedicationShape.semicircle:
      //   return 'SEMICIRCLE';
      case MedicationShape.square:
        return 'SQUARE';
      case MedicationShape.tear:
        return 'TEAR';
      // case MedicationShape.trapezoid:
      //   return 'TRAPEZOID';
      case MedicationShape.triangle:
        return 'TRIANGLE';
    }
  }

  String get displayName {
    switch (this) {
      case MedicationShape.capsule:
        return 'Capsule';
      // case MedicationShape.diamond:
      //   return 'Diamond';
      case MedicationShape.doubleCircle:
        return 'Double circle';
      // case MedicationShape.heptagon:
      //   return 'Heptagon';
      case MedicationShape.hexagon:
        return 'Hexagon';
      // case MedicationShape.octagon:
      //   return 'Octagon';
      // case MedicationShape.oval:
      //   return 'Oval';
      case MedicationShape.pentagon:
        return 'Pentagon';
      // case MedicationShape.rectangle:
      //   return 'Rectangle';
      case MedicationShape.round:
        return 'Round';
      // case MedicationShape.semicircle:
      //   return 'Semicircle';
      case MedicationShape.square:
        return 'Square';
      case MedicationShape.tear:
        return 'Tear';
      // case MedicationShape.trapezoid:
      //   return 'Trapezoid';
      case MedicationShape.triangle:
        return 'Triangle';
    }
  }

  static MedicationShape byInternalName(String name) {
    switch (name) {
      case 'CAPSULE':
        return MedicationShape.capsule;
      // case 'DIAMOND':
      //   return MedicationShape.diamond;
      case 'DOUBLE_CIRCLE':
        return MedicationShape.doubleCircle;
      // case 'HEPTAGON':
      //   return MedicationShape.heptagon;
      case 'HEXAGON':
        return MedicationShape.hexagon;
      // case 'OCTAGON':
      //   return MedicationShape.octagon;
      // case 'OVAL':
      //   return MedicationShape.oval;
      case 'PENTAGON':
        return MedicationShape.pentagon;
      // case 'RECTANGLE':
      //   return MedicationShape.rectangle;
      case 'ROUND':
        return MedicationShape.round;
      // case 'SEMICIRCLE':
      //   return MedicationShape.semicircle;
      case 'SQUARE':
        return MedicationShape.square;
      case 'TEAR':
        return MedicationShape.tear;
      // case 'TRAPEZOID':
      //   return MedicationShape.trapezoid;
      case 'TRIANGLE':
        return MedicationShape.triangle;
      default:
        return MedicationShape.round;
    }
  }
}

Set<DayOfWeek> parseDaysOfWeekFlags(int bitmask) {
  var result = <DayOfWeek>{};

  if (bitmask & (1 << 0) != 0) {
    result.add(DayOfWeek.monday);
  }
  if (bitmask & (1 << 1) != 0) {
    result.add(DayOfWeek.tuesday);
  }
  if (bitmask & (1 << 2) != 0) {
    result.add(DayOfWeek.wednesday);
  }
  if (bitmask & (1 << 3) != 0) {
    result.add(DayOfWeek.thursday);
  }
  if (bitmask & (1 << 4) != 0) {
    result.add(DayOfWeek.friday);
  }
  if (bitmask & (1 << 5) != 0) {
    result.add(DayOfWeek.saturday);
  }
  if (bitmask & (1 << 6) != 0) {
    result.add(DayOfWeek.sunday);
  }
  return result;
}

int createDaysOfWeekFlag(Set<DayOfWeek> set) {
  int result = 0;
  for (DayOfWeek dow in set) {
    result |= (1 << dow.index);
  }
  return result;
}

@freezed
class ScheduledMedication extends Equatable with _$ScheduledMedication {
  const ScheduledMedication._();
  const factory ScheduledMedication(
          {int? id,
          required String name,
          MedicationShape? shape,
          Color? color,
          required List<MedicationDispenseTime> dispenseTimes}) =
      _ScheduledMedication;

  factory ScheduledMedication.fromDTO(ScheduledMedicationDTO dto) {
    return ScheduledMedication(
        id: dto.id,
        name: dto.med_name,
        shape: dto.shape != null
            ? MedicationShapeExtension.byInternalName(dto.shape!)
            : null,
        color: dto.color != null ? Color(dto.color!) : null,
        dispenseTimes: dto.dispenseTimes
                ?.map((e) => MedicationDispenseTime.fromDTO(e))
                .toList(growable: false) ??
            []);
  }

  ScheduledMedicationDTO toDTO() {
    return ScheduledMedicationDTO(
      id: id,
      med_name: name,
      shape: shape?.internalName,
      color: color?.value,
    );
  }

  @override
  List<Object?> get props => [id, name, shape, color];
}

class MedicationRepository {
  MedicationRepository({required this.client});

  final RestClient client;

  Future<ScheduledMedication> medication(int deviceID, int medicationID) {
    return client
        .medication(deviceID, medicationID)
        .then((value) => ScheduledMedication.fromDTO(value));
  }

  Future<List<ScheduledMedication>> medications(int deviceID) async {
    return (await client.medications(deviceID))
        .map((e) => ScheduledMedication.fromDTO(e))
        .toList(growable: false);
  }

  Future<ScheduledMedication> save(
      int deviceID, ScheduledMedication model) async {
    return ScheduledMedication.fromDTO(
        await client.addMedication(deviceID, model.toDTO()));
  }

  Future<void> delete(int deviceID, int medID) {
    return client.deleteMedication(deviceID, medID);
  }
}

final MedicationRepository medicationRepo =
    MedicationRepository(client: client);
