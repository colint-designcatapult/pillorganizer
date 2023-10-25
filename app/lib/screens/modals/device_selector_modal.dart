import 'package:app/provider/selected_device_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

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

class DeviceListEntry extends StatelessWidget {
  final DeviceUser device;

  const DeviceListEntry({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(device.name),
        leading: DeviceStatusIcon(
            size: 48.0,
            status: device.isOnline
                ? DeviceConnectionStatus.online
                : DeviceConnectionStatus.offline),
        onTap: () {
          Provider.of<SelectedDeviceProvider>(context, listen: false)
              .selectDevice(device);
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        },
      ),
    );
  }
}

class DeviceSelectorModal extends StatelessWidget {
  const DeviceSelectorModal({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: const Text('Switch Pill Organizers'),
        automaticallyImplyLeading: false,
      ),
      material: (_, __) => MaterialScaffoldData(),
      cupertino: (_, __) => CupertinoPageScaffoldData(),
      body: SafeArea(
        bottom: false,
        child: Consumer<DeviceListProvider>(
          builder: (_, prov, __) {
            Iterable<Widget> yourDevices = prov.value!
                .where((element) => element.owner)
                .map((e) => DeviceListEntry(device: e));
            Iterable<Widget> otherDevices = prov.value!
                .where((element) => !element.owner)
                .map((e) => DeviceListEntry(device: e));

            return ListView(
              shrinkWrap: true,
              controller: ModalScrollController.of(context),
              children: [
                if (yourDevices.isNotEmpty) ...[
                  const DeviceListHeader(child: Text('My Devices')),
                  ...yourDevices
                ],
                if (otherDevices.isNotEmpty) ...[
                  const DeviceListHeader(child: Text('Other Devices')),
                  ...otherDevices
                ],
              ],
            );
          },
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
        deviceRepo.deviceListProvider.refresh();
        return const DeviceSelectorModal();
      });
}
