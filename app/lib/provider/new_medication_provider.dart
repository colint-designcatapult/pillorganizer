import 'package:app/api/api.dart';
import 'package:app/api/medication.dart';
import 'package:app/screens/device_settings/medication/medication_entry_wizard.dart';
import 'package:flutter/material.dart';

class NewMedicationProvider with ChangeNotifier {
  VoidCallback? _onComplete;
  late NewMedicationState _state;
  NewMedicationState get state => _state;
  NewMedicationProvider(int deviceID) {
    _state = NewMedicationState(deviceID: deviceID);
  }

  NewMedicationProvider.fromExisting(int deviceID, ScheduledMedication med) {
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

  void nextStage() {
    _state =
        state.copyWith(stage: NewMedicationStage.values[state.stage.index + 1]);
    notifyListeners();
  }

  void previousStage() {
    _state =
        state.copyWith(stage: NewMedicationStage.values[state.stage.index - 1]);
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

  Widget buildWidgetForState({VoidCallback? onComplete}) {
    _onComplete = onComplete;
    if (state.name == null || state.stage == NewMedicationStage.name) {
      return NewMedicationWizardNameStage(key: nameKey);
    } else if (state.shape == null ||
        state.color == null ||
        state.stage == NewMedicationStage.appearance) {
      return NewMedicationWizardAppearanceStage(key: appearanceKey);
    } else if (state.stage == NewMedicationStage.schedule ||
        (state.assignedDispenseTimes?.isEmpty ?? true)) {
      return NewMedicationWizardScheduleStage(key: scheduleKey);
    } else {
      return const Text('over');
    }
  }
}
