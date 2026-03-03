import 'package:app/provider/device_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/widgets/multiple_devices.dart';
import 'package:app/widgets/single_device.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyDevicesScreen extends ConsumerWidget {
  const MyDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDevice = ref.watch(activeDeviceProvider);
    final deviceListAsync = ref.watch(deviceListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFBFD2DB),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 75.h, bottom: 20.h),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(left: 24.w, bottom: 24.h),
                  child: Text(
                    AppLocalizations.of(context)!.myDevices,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 32.h,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0).w,
                    child: deviceListAsync.when(
                      data: (devices) {
                        final deviceCount = devices.length;
                        if (deviceCount > 1) {
                          return MultipleDevices(
                            devices: devices,
                          );
                        } else {
                          return SingleDevice(
                            showAddDeviceSection: deviceCount == 1,
                            device: activeDevice,
                            isModal: false,
                          );
                        }
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (err, _) => Center(
                        child: Text('Error: $err'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
