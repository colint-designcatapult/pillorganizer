import 'package:app/api/api.dart';
import 'package:app/api/device.dart';

class DeviceStateProvider extends RefreshableValueNotifier<DeviceState?> {
  DateTime? _baseDate;
  DeviceUser? _device;
  bool _isLoadingInitialState = false;
  bool _hasInitiallyLoadedState = false;

  DeviceStateProvider() : super(null, () => Future.value(null));

  bool get isLoadingInitialState => _isLoadingInitialState;
  bool get hasInitiallyLoadedState => _hasInitiallyLoadedState;

  DeviceStateProvider update(DateTime? date, DeviceUser? selected) {
    if (date != null) {
      _baseDate = date;
    }
    if (selected != null && selected.id != _device?.id) {
      _device = selected;
      loadFunction = _load;
      value = null;
      _hasInitiallyLoadedState = false;
      notifyListeners();
    }
    return this;
  }

  @override
  void refresh() {
    if (!_hasInitiallyLoadedState) {
      _isLoadingInitialState = true;
      notifyListeners();
    }

    fromFuture(loadFunction()).then((_) {
      if (isLoadingInitialState) {
        _isLoadingInitialState = false;
        _hasInitiallyLoadedState = true;
        notifyListeners();
      }
    }).catchError((error) {
      if (isLoadingInitialState) {
        _isLoadingInitialState = false;
        notifyListeners();
      }
      throw error;
    });
  }

  Future<DeviceState?> _load() {
    if (_device == null || _baseDate == null) {
      return Future.value(null);
    } else {
      return deviceRepo.deviceState(_device!.deviceID, _baseDate!);
    }
  }
}
