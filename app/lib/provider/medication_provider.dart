import 'package:app/api/api.dart';
import 'package:app/api/device.dart';
import 'package:app/api/medication.dart';

class MedicationsProvider
    extends RefreshableValueNotifier<List<ScheduledMedication>?> {
  DeviceUser? _device;
  Map<int, ScheduledMedication>? _idToMed;
  bool isUpdateMedication = false;

  MedicationsProvider(this._device)
      : super(null, () {
          return Future.value(null);
        }) {
    super.loadFunction = _load;
    refresh();
  }

  MedicationsProvider update(DeviceUser? newDevice) {
    if (newDevice?.id != _device?.id) {
      _device = newDevice;
      super.loadFunction = _load;
    }
    refresh();
    return this;
  }

  Future<List<ScheduledMedication>?> _load() {
    if (_device != null) {
      isUpdateMedication = true;
      return medicationRepo.medications(_device!.deviceID).then((value) {
        _idToMed = {for (var v in value) v.id ?? 0: v};
        return value;
      });
    } else {
      return Future.value(null);
    }
  }

  ScheduledMedication? byID(int id) {
    return _idToMed?[id];
  }
}
