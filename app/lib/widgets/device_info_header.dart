import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/selected_device_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DeviceInfoHeader extends StatelessWidget {
  const DeviceInfoHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectedDeviceProvider>(builder: (_, selectedDevice, __) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Text(
                  selectedDevice.device?.name ??
                      AppLocalizations.of(context)!.loadingState,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              const Icon(Icons.info, color: Colors.white, size: 16),
            ],
          ),
          const SizedBox(height: 30),
          // const Row(
          //   children: [
          //     Text("Battery Level",
          //         style: TextStyle(color: Colors.white, fontSize: 14)),
          //     SizedBox(width: 4),
          //     Icon(
          //       PhosphorIcons.battery_medium,
          //       size: 20,
          //       color: Colors.white,
          //     ),
          //     SizedBox(width: 4),
          //     Text("70%", style: TextStyle(color: Colors.white, fontSize: 14)),
          //   ],
          // ),
        ],
      );
    });
  }
}
