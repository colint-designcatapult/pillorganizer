import 'package:app/api/api.dart';
import 'package:app/api/medication.dart';
import 'package:app/models/medication_entry_wizard.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'new_medication_provider.g.dart';

@riverpod
class NewMedicationNotifier extends _$NewMedicationNotifier {
  @override
  NewMedicationState build() {
    // Initial dummy state, should be initialized via [initialize]
    return NewMedicationState(deviceID: 0);
  }

  void initialize(int deviceID, {ScheduledMedication? existing, VoidCallback? onComplete}) {
    if (existing != null) {
      state = NewMedicationState(
          existing: existing,
          deviceID: deviceID,
          name: existing.name,
          shape: existing.shape,
          color: existing.color,
          assignedDispenseTimes:
              existing.dispenseTimes.map((e) => e.dispenseTimeID).toSet());
    } else {
      state = NewMedicationState(deviceID: deviceID);
    }
  }

  void updateName(String? newName) {
    state = state.copyWith(name: newName);
  }

  void updateColor(Color? newColor) {
    state = state.copyWith(color: newColor);
  }

  void updateShape(MedicationShape? newShape) {
    state = state.copyWith(shape: newShape);
  }

  Future<void> complete(BuildContext context, {VoidCallback? onComplete}) async {
    try {
      await client.saveMedication(
              state.deviceID,
              SaveMedicationDTO(
                  id: state.existing?.id,
                  name: state.name,
                  shape: state.shape?.internalName,
                  color: state.color?.value,
                  dispenseTimes: state.assignedDispenseTimes));
      
      if (context.mounted) {
        if (onComplete != null) {
          onComplete();
        }
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> delete(BuildContext context, {VoidCallback? onComplete}) async {
    if (state.existing?.id == null) return;
    
    try {
      await client.deleteMedication(state.deviceID, state.existing!.id!);
      if (context.mounted) {
        if (onComplete != null) {
          onComplete();
        }
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Handle error
    }
  }

  bool canComplete() {
    return state.assignedDispenseTimes?.isEmpty == false &&
        state.color != null &&
        state.name != null &&
        state.name!.isNotEmpty &&
        state.shape != null;
  }

  void toggleDispenseTime(int dispenseID) {
    Set<int> newSet = {...?state.assignedDispenseTimes};
    if (newSet.contains(dispenseID)) {
      newSet.remove(dispenseID);
    } else {
      newSet.add(dispenseID);
    }
    state = state.copyWith(assignedDispenseTimes: newSet);
  }
}
