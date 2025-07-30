import 'package:app/provider/device_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/device.dart';
import '../../provider/device_notice_provider.dart';
import '../../provider/device_state_provider.dart';
import '../../provider/selected_device_provider.dart';
import 'home_body.dart';
import 'home_disconnected_body.dart';
import 'home_empty_device_body.dart';
import 'home_loading_body.dart';
import 'home_no_device_body.dart';

class HomeBodySelector extends StatelessWidget {
  const HomeBodySelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer4<DeviceNoticeProvider, SelectedDeviceProvider,
        DeviceStateProvider, DeviceProvider>(
      builder: (context, deviceNoticeProvider, selectedDeviceProvider,
          deviceStateProvider, deviceProvider, child) {
        final isLoadingDevices = deviceProvider.isLoading;
        final selectedDevice = selectedDeviceProvider.device;
        final bool noDevice = selectedDevice == null;

        final bool isLoadingInitialDeviceState =
            deviceStateProvider.isLoadingInitialState;
        final bool hasInitiallyLoadedDeviceState =
            deviceStateProvider.hasInitiallyLoadedState;

        final bool isDisconnected =
            deviceNoticeProvider.value == DeviceNotice.disconnected;
        final dosePeriods = deviceStateProvider.value?.dosePeriods ?? [];
        final bool isEmpty =
            !dosePeriods.any((element) => element.medicationIDs.isNotEmpty);
        final bool isOwner = selectedDevice?.owner ?? false;

        if (isLoadingDevices) {
          return const HomeLoadingBody();
        }

        if (noDevice) {
          return const HomeNoDeviceBody();
        }

        if (isLoadingInitialDeviceState) {
          return const HomeLoadingBody();
        }

        if (isEmpty && hasInitiallyLoadedDeviceState) {
          return HomeEmptyDeviceBody(isOwner: isOwner);
        }

        if (isDisconnected) {
          return const HomeDisconnectedBody();
        }

        if (!isEmpty && !isDisconnected) {
          return const HomeBody();
        }

        return const HomeLoadingBody();
      },
    );
  }
}
