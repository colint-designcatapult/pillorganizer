import 'package:app/api/api.dart';
import 'package:app/api/share_code.dart';
import 'package:flutter/foundation.dart';

class CaregiverProvider with ChangeNotifier {
  final Map<int, ShareCode> _shareCodes = {};
  bool _isGeneratingCode = false;
  bool _isFetchingShareCodes = false;

  Map<int, ShareCode> get shareCodes => Map.unmodifiable(_shareCodes);
  bool get isGeneratingCode => _isGeneratingCode;
  bool get isFetchingShareCodes => _isFetchingShareCodes;

  ShareCode? getShareCodeForDevice(int deviceId) {
    final shareCode = _shareCodes[deviceId];
    if (shareCode != null && shareCode.isValid) {
      return shareCode;
    } else if (shareCode != null && !shareCode.isValid) {
      _shareCodes.remove(deviceId);
      notifyListeners();
    }
    return null;
  }

  Future<CaregiverCodeValidationDTO> validateCaregiverCode(
      {required String code}) async {
    return await client.validateCaregiverCode(code);
  }

  Future<ShareCode> generateCaregiverCodeForDevice(int deviceId) async {
    if (_isGeneratingCode) {
      return Future.error('Code generation already in progress');
    }

    _isGeneratingCode = true;
    notifyListeners();

    try {
      DeviceCaregiverCodeDTO caregiverCode =
          await client.generateCaregiverCode(deviceId);

      final shareCode = ShareCode.fromDTO(caregiverCode);
      _shareCodes[deviceId] = shareCode;

      return shareCode;
    } catch (error) {
      return Future.error('Error generating share code');
    } finally {
      _isGeneratingCode = false;
      notifyListeners();
    }
  }

  Future<void> fetchShareCodesForDevices(List<int> deviceIds) async {
    _isFetchingShareCodes = true;
    notifyListeners();

    if (deviceIds.isEmpty) return;

    try {
      List<DeviceCaregiverCodeDTO> codes =
          await client.getShareCodes(deviceIds);

      for (int deviceId in deviceIds) {
        _shareCodes.remove(deviceId);
      }

      for (DeviceCaregiverCodeDTO dto in codes) {
        final shareCode = ShareCode.fromDTO(dto);
        if (shareCode.isValid) {
          _shareCodes[dto.deviceID] = shareCode;
        }
      }
    } catch (error) {
      return Future.error('Error fetching share codes');
    } finally {
      _isFetchingShareCodes = false;
      notifyListeners();
    }
  }

  void clearExpiredCodes() {
    final expiredDeviceIds = _shareCodes.entries
        .where((entry) => !entry.value.isValid)
        .map((entry) => entry.key)
        .toList();

    for (int deviceId in expiredDeviceIds) {
      _shareCodes.remove(deviceId);
    }

    if (expiredDeviceIds.isNotEmpty) {
      notifyListeners();
    }
  }
}
