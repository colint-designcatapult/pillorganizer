import 'package:app/provider/device_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:app/apiv2/models/device.dart';
import '../../provider/device_error_provider.dart';
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
    final deviceError = ref.watch(deviceErrorProvider);
    final activeDevice = ref.watch(activeDeviceProvider);
    final deviceStateAsync = ref.watch(deviceStateProvider);
    final deviceListAsync = ref.watch(deviceListProvider);

    final isLoadingDevices = deviceListAsync.isLoading;
    final bool noDevice = activeDevice == null;

    // In my migrated DeviceStateNotifier, I use AsyncValue. 
    // We can infer loading state from AsyncValue.
    final bool isLoadingInitialDeviceState = deviceStateAsync.isLoading && !deviceStateAsync.hasValue;
    final bool hasInitiallyLoadedDeviceState = deviceStateAsync.hasValue;

    //final bool isDisconnected = deviceNotice == DeviceNotice.disconnected;
    final bool isDisconnected = false;
    //final bool isEmpty =
    //    !dosePeriods.any((element) => element.medicationIDs.isNotEmpty);
    final bool isEmpty = false;
    final bool isOwner = activeDevice?.primaryUser ?? false;

    if (isLoadingDevices) {
      return const HomeLoadingBody();
    }

    if (deviceListAsync.hasError) {
      final error = deviceListAsync.error;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Failed to load devices.',
                textAlign: TextAlign.center,
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.refresh(deviceListProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (noDevice) {
      return const HomeNoDeviceBody();
    }

    /*if (isLoadingInitialDeviceState) {
      return const HomeLoadingBody();
    }*/

    /*if (isDisconnected) {
      return const HomeDisconnectedBody();
    }

    if (isEmpty && hasInitiallyLoadedDeviceState) {
      return HomeEmptyDeviceBody(isOwner: isOwner);
    }*/

    return HomeBody();

  }
}
