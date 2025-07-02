import 'package:app/provider/device_provider.dart';
import 'package:app/widgets/single_device.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SingleDeviceModal extends StatelessWidget {
  final int deviceId;

  const SingleDeviceModal({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, _) {
        if (deviceProvider.devices == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final device = deviceProvider.devices!.firstWhere(
          (d) => d.deviceID == deviceId,
          orElse: () => throw StateError('Device not found'),
        );

        return SingleDevice(
          showAddDeviceSection: false,
          device: device,
          isModal: true,
        );
      },
    );
  }
}
