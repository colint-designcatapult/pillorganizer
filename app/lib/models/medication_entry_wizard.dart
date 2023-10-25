import 'package:app/api/medication.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'medication_entry_wizard.freezed.dart';

enum NewMedicationStage { name, appearance, schedule }

@freezed
class NewMedicationState with _$NewMedicationState {
  const factory NewMedicationState(
      {ScheduledMedication? existing,
      required int deviceID,
      @Default(NewMedicationStage.name) NewMedicationStage stage,
      String? name,
      MedicationShape? shape,
      Color? color,
      Set<int>? assignedDispenseTimes}) = _NewMedicationState;
}
