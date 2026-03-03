import 'package:app/api/api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'caregiver_provider.g.dart';

@riverpod
class Caregiver extends _$Caregiver {
  @override
  FutureOr<List<DeviceCaregiverCodeDTO>> build() async {
    return [];
  }

  Future<void> fetchShareCodesForDevices(List<int> deviceIDs) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final List<DeviceCaregiverCodeDTO> codes = [];
      for (var id in deviceIDs) {
        // Mocking getCaregiverCode as requested
        final code = id == 30 
            ? DeviceCaregiverCodeDTO(id: 1, deviceID: 30, code: 123456, expiresAt: DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch, deleted: false)
            : null;
        if (code != null) codes.add(code);
      }
      return codes;
    });
  }

  DeviceCaregiverCodeDTO? getShareCodeForDevice(int deviceID) {
    final list = state.asData?.value;
    if (list == null) return null;
    for (var c in list) {
      if (c.deviceID == deviceID) return c;
    }
    return null;
  }

  void clearExpiredCodes() {
    if (state.hasValue) {
      state = AsyncValue.data(
        state.value!.where((c) => c.isValid).toList()
      );
    }
  }

  Future<void> generateCaregiverCodeForDevice(int deviceID) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await client.generateCaregiverCode(deviceID);
       // Mocking the follow-up fetch
      final newCode = DeviceCaregiverCodeDTO(id: 1, deviceID: deviceID, code: 123456, expiresAt: DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch, deleted: false);
      final currentList = state.asData?.value ?? [];
      return [
        for (final c in currentList) if (c.deviceID != deviceID) c,
        newCode,
      ];
    });
  }

  Future<CaregiverCodeValidationDTO> validateCaregiverCode({required String code}) async {
    final res = await client.validateCaregiverCode(code);
    ref.invalidateSelf();
    return res;
  }
}
