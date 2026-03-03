import 'package:app/provider/device_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/device.dart';
import '../../provider/device_notice_provider.dart';
import '../../provider/device_state_provider.dart';
import '../../provider/selected_device_provider.dart';
import 'home_body.dart';
import 'home_disconnected_body.dart';
import 'home_empty_device_body.dart';
import 'home_loading_body.dart';
import 'home_no_device_body.dart';

class HomeBodySelector extends ConsumerWidget {
  const HomeBodySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceNotice = ref.watch(deviceNoticeProvider);
    final activeDevice = ref.watch(activeDeviceProvider);
    final deviceStateAsync = ref.watch(deviceStateProvider);
    final deviceListAsync = ref.watch(deviceListProvider);

    final isLoadingDevices = deviceListAsync.isLoading;
    final bool noDevice = activeDevice == null;

    // In my migrated DeviceStateNotifier, I use AsyncValue. 
    // We can infer loading state from AsyncValue.
    final bool isLoadingInitialDeviceState = deviceStateAsync.isLoading && !deviceStateAsync.hasValue;
    final bool hasInitiallyLoadedDeviceState = deviceStateAsync.hasValue;

    final bool isDisconnected = deviceNotice == DeviceNotice.disconnected;
    final dosePeriods = deviceStateAsync.value?.dosePeriods ?? [];
    final bool isEmpty =
        !dosePeriods.any((element) => element.medicationIDs.isNotEmpty);
    final bool isOwner = activeDevice?.owner ?? false;

    if (isLoadingDevices) {
      return const HomeLoadingBody();
    }

    if (noDevice) {
      return const HomeNoDeviceBody();
    }

    if (isLoadingInitialDeviceState) {
      return const HomeLoadingBody();
    }

    if (isDisconnected) {
      return const HomeDisconnectedBody();
    }

    if (isEmpty && hasInitiallyLoadedDeviceState) {
      return HomeEmptyDeviceBody(isOwner: isOwner);
    }

    if (!isEmpty && !isDisconnected) {
      return HomeBody();
    }

    return const HomeLoadingBody();
  }
}
