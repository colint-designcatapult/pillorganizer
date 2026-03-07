import 'package:app/api/api.dart';
import 'package:app/apiv2/models/device.dart';
import 'package:app/api/medication.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'medication_provider.g.dart';

@riverpod
class Medications extends _$Medications {
  @override
  FutureOr<List<ScheduledMedication>> build() async {
    final device = ref.watch(activeDeviceProvider);
    if (device == null) return [];

    final dtos = await client.medications(device!.id);
    return dtos.map((e) => ScheduledMedication.fromDTO(e)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final device = ref.read(activeDeviceProvider);
      if (device == null) return [];
      final dtos = await client.medications(device.id);
      return dtos.map((e) => ScheduledMedication.fromDTO(e)).toList();
    });
  }

  Future<void> addMedication(ScheduledMedicationDTO medication) async {
    final device = ref.read(activeDeviceProvider);
    if (device == null) return;

    await client.addMedication(device.id, medication);
    ref.invalidateSelf();
  }

  Future<void> deleteMedication(int medId) async {
    final device = ref.read(activeDeviceProvider);
    if (device == null) return;

    await client.deleteMedication(device.id, medId);
    ref.invalidateSelf();
  }
}
