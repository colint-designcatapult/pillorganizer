import 'package:app/provider/device_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/device.dart';
import '../../platform/bottom_modal.dart';
import '../../widgets/device_icon.dart';

class DeviceListHeader extends StatelessWidget {
  final Widget child;
  const DeviceListHeader({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: child,
    );
  }
}

class DeviceListEntry extends ConsumerWidget {
  final DeviceUser device;

  const DeviceListEntry({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0).h,
      child: ListTile(
        title: Text(device.name),
        leading: DeviceStatusIcon(
            size: 48,
            status: device.isOnline
                ? DeviceConnectionStatus.online
                : DeviceConnectionStatus.offline),
        onTap: () {
          ref.read(activeDeviceProvider.notifier).selectDevice(device);
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/index', (route) => false);
        },
      ),
    );
  }
}

class DeviceSelectorModal extends ConsumerWidget {
  const DeviceSelectorModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.switchPillOrganizers,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        bottom: false,
        child: ref.watch(deviceListProvider).when(
          data: (devices) {
            Iterable<Widget> yourDevices = devices
                .where((element) => element.owner)
                .map((e) => DeviceListEntry(device: e));
            Iterable<Widget> otherDevices = devices
                .where((element) => !element.owner)
                .map((e) => DeviceListEntry(device: e));

            return ListView(
              shrinkWrap: true,
              controller: ModalScrollController.of(context),
              children: [
                if (yourDevices.isNotEmpty) ...[
                  DeviceListHeader(
                      child: Text(AppLocalizations.of(context)!.myDevices)),
                  ...yourDevices
                ],
                if (otherDevices.isNotEmpty) ...[
                  DeviceListHeader(
                      child: Text(AppLocalizations.of(context)!.otherDevices)),
                  ...otherDevices
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text(e.toString())),
        ),
      ),
    );
  }
}

Future<DeviceUser?> showDeviceSelectorModal(BuildContext context) {
  return showPlatformModalBottomSheet(
      context: context,
      expand: false,
      builder: (context) {
        return Consumer(builder: (context, ref, child) {
          ref.read(deviceListProvider.notifier).refresh();
          return const DeviceSelectorModal();
        });
      });
}
