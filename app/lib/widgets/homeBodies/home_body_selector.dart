import 'package:app/provider/device_provider.dart';
import 'package:app/widgets/homeBodies/home_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_body_device.dart';
import 'home_loading_body.dart';
import 'home_no_device_body.dart';

class HomeBodySelector extends ConsumerWidget {
  const HomeBodySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceListAsync = ref.watch(deviceListProvider);

    return deviceListAsync.when(
      loading: () => const HomeLoadingBody(),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Failed to load devices.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(deviceListProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (devices) {
        if (devices.isEmpty) {
          return const HomeNoDeviceBody();
        }
        return const HomeBodyDevice();
      },
    );
  }
}
