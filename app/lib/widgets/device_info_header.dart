import 'package:app/api/device.dart';
import 'package:app/provider/ble_provider.dart';
import 'package:app/provider/device_notice_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:provider/provider.dart';
import '../provider/selected_device_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DeviceInfoHeader extends StatelessWidget {
  const DeviceInfoHeader({Key? key}) : super(key: key);

  String wirelessText(BuildContext context, DeviceBluetoothProvider bleProv) {
    if (Provider.of<DeviceNoticeProvider>(context, listen: false).value ==
            DeviceNotice.disconnected ||
        bleProv.status == BLEConnectionStatus.connected ||
        bleProv.status == BLEConnectionStatus.connecting) {
      return AppLocalizations.of(context)!.wirelessDisconnected;
    } else {
      return AppLocalizations.of(context)!.wirelessConnected;
    }
  }

  String bluetoothText(BuildContext context, DeviceBluetoothProvider bleProv) {
    if (bleProv.status == BLEConnectionStatus.connected) {
      return AppLocalizations.of(context)!.bluetoothConnected;
    } else if (bleProv.status == BLEConnectionStatus.connecting) {
      return AppLocalizations.of(context)!.bluetoothConnecting;
    }
    return AppLocalizations.of(context)!.bluetoothDisconnected;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectedDeviceProvider>(builder: (_, selectedDevice, __) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
              onTap: () => _showConnectionStatus(context),
              child: Row(
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
              )),
          const SizedBox(height: 30),
        ],
      );
    });
  }

  void _showConnectionStatus(BuildContext context) {
    showDialog(
        context: context,
        builder: (_) =>
            Consumer<DeviceBluetoothProvider>(builder: (_, bleProv, __) {
              return Dialog(
                  insetPadding: const EdgeInsets.all(16),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: const Icon(
                                PhosphorIcons.x_bold,
                                size: 24,
                                color: Color(0XFF101828),
                              )),
                        ),
                        const Column(
                          children: [
                            Icon(
                              PhosphorIcons.hard_drives_fill,
                              size: 48,
                              color: Color(0xFF206B8B),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.deviceInfo,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: const Color(0XFF101828)),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            AppLocalizations.of(context)!.deviceInfoSubtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFBFD2DB), width: 2),
                              color: const Color(0xFFF1F3F6),
                            ),
                            height: 56,
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 16, 20, 16),
                                child: Row(
                                  children: [
                                    const Icon(
                                      PhosphorIcons.wifi_high,
                                      size: 24,
                                      color: Color(0xFF191B1D),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      wirelessText(context, bleProv),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    )
                                  ],
                                ))),
                        const SizedBox(height: 12),
                        Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFBFD2DB), width: 2),
                              color: const Color(0xFFF1F3F6),
                            ),
                            height: 56,
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 16, 20, 16),
                                child: Row(
                                  children: [
                                    const Icon(
                                      PhosphorIcons.bluetooth_fill,
                                      size: 24,
                                      color: Color(0xFF191B1D),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      bluetoothText(context, bleProv),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    )
                                  ],
                                )))
                      ],
                    ),
                  ));
            }));
  }
}
