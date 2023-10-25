import 'package:app/api/api.dart';
import 'package:app/api/medication.dart';
import 'package:app/models/medication_entry_wizard.dart';
import 'package:flutter/material.dart';

enum NewMedicationStage { name, appearance, schedule }

class NewMedicationProvider with ChangeNotifier {
  VoidCallback? _onComplete;
  late NewMedicationState _state;
  NewMedicationState get state => _state;
  NewMedicationProvider(int deviceID, VoidCallback? onComplete) {
    _state = NewMedicationState(deviceID: deviceID);
    _onComplete = onComplete;
  }

  NewMedicationProvider.fromExisting(
      int deviceID, ScheduledMedication med, VoidCallback? onComplete) {
    _onComplete = onComplete;
    _state = NewMedicationState(
        existing: med,
        deviceID: deviceID,
        name: med.name,
        shape: med.shape,
        color: med.color,
        assignedDispenseTimes:
            med.dispenseTimes.map((e) => e.dispenseTimeID).toSet());
  }

  void updateName(String? newName) {
    _state = state.copyWith(name: newName);
    notifyListeners();
  }

  void updateColor(Color? newColor) {
    _state = state.copyWith(color: newColor);
    notifyListeners();
  }

  void updateShape(MedicationShape? newShape) {
    _state = state.copyWith(shape: newShape);
    notifyListeners();
  }

  void complete(context) {
    client
        .saveMedication(
            _state.deviceID,
            SaveMedicationDTO(
                id: _state.existing?.id,
                name: _state.name,
                shape: _state.shape?.internalName,
                color: _state.color?.value,
                dispenseTimes: _state.assignedDispenseTimes))
        .then((value) {
      if (context.mounted) {
        if (_onComplete != null) {
          _onComplete!();
        }
        Navigator.of(context).pop();
      }
      notifyListeners();
    });
  }

  void delete(context) {
    client
        .deleteMedication(_state.deviceID, _state.existing!.id!)
        .then((value) {
      if (context.mounted) {
        if (_onComplete != null) {
          _onComplete!();
        }
        Navigator.of(context).pop();
      }
    });
  }

  bool canComplete() {
    return _state.assignedDispenseTimes?.isEmpty == false &&
        _state.color != null &&
        _state.name != null &&
        _state.name!.isNotEmpty &&
        _state.shape != null;
  }

  void toggleDispenseTime(int dispenseID) {
    Set<int> newSet = {...?state.assignedDispenseTimes};
    if (newSet.contains(dispenseID)) {
      newSet.remove(dispenseID);
    } else {
      newSet.add(dispenseID);
    }
    _state = state.copyWith(assignedDispenseTimes: newSet);
    notifyListeners();
  }

  final Key nameKey = UniqueKey();
  final Key appearanceKey = UniqueKey();
  final Key scheduleKey = UniqueKey();
}
