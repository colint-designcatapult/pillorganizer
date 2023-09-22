import 'package:app/api/medication.dart';
import 'package:flutter/material.dart';

class MedicationProvider with ChangeNotifier {
  ScheduledMedication get medication => _medication!;
  late ScheduledMedication? _medication;

  MedicationProvider({medication, validTimes}) {
    _medication = medication;
  }

  Future<void> load(int deviceID, ScheduledMedication model) async {
    if (model.id != null) {
      _medication = await medicationRepo.medication(deviceID, model.id!);
    } else {
      _medication = model;
    }
    notifyListeners();
  }

  void update(ScheduledMedication val) {
    _medication = val;
    notifyListeners();
  }

  Future<ScheduledMedication> save(int deviceID) async {
    return await medicationRepo.save(deviceID, _medication!);
  }

  Future<void> delete(int deviceID) async {
    if (_medication!.id != null) {
      return await medicationRepo.delete(deviceID, _medication!.id!);
    }
  }
}
