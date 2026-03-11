import 'package:app/provider/device_provider.dart';
import 'package:app/widgets/single_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../apiv2/models/device.dart';

class SingleDeviceModal extends ConsumerWidget {
  final String deviceId;

  const SingleDeviceModal({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceListAsync = ref.watch(deviceListProvider);
    final devices = deviceListAsync.value ?? [];

    if (devices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final device = devices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => devices.first,
    );

    return SingleDevice(
      showAddDeviceSection: false,
      device: device,
      isModal: true,
    );
  }
}
