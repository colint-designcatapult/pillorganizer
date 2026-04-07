import 'package:app/apiv2/models/device.dart';
import 'package:app/provider/device_provider.dart';
import 'package:app/provider/device_error_provider.dart';
import 'package:app/provider/device_state_provider.dart';
import 'package:app/provider/mqtt_provider.dart';
import 'package:app/widgets/device_alert_popup.dart';
import 'package:app/widgets/homeBodies/home_body.dart';
import 'package:app/widgets/shimmer_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class HomeBodyDevice extends ConsumerWidget {
  const HomeBodyDevice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceError = ref.watch(deviceErrorProvider);
    final mqttClient = ref.watch(mqttClientProvider);

    if (deviceError == DeviceError.none || mqttClient.isLoading) {
      return const HomeBody();
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.only(topRight: const Radius.circular(40.0).r),
        child: Container(
            decoration: BoxDecoration(
              color: Colors.white54,
              borderRadius: BorderRadius.only(
                topRight: const Radius.circular(40.0).r,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: 80.h),
              child: Align(
                alignment: Alignment.topCenter,
                child: DeviceAlertPopup(
                  notice: deviceError,
                  onReload: () {
                    if (deviceError == DeviceError.phoneDisconnected) {
                      ref.read(mqttClientProvider.notifier).reconnect();
                    } else {
                      ref.invalidate(deviceListProvider);
                    }
                  },
                  reloadFuture: () async {
                    if (deviceError == DeviceError.phoneDisconnected) {
                      ref.read(mqttClientProvider.notifier).reconnect();
                    } else {
                      ref.invalidate(deviceListProvider);
                    }
                  },
                ),
              ),
            )
        )
      );
    }

  }
}
