
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../../api/device.dart';
import '../../platform/bottom_modal.dart';
import '../../widgets/schedule_entry.dart';


class DeviceSelectorModal extends StatelessWidget {
  const DeviceSelectorModal({super.key});

  @override
  Widget build(BuildContext context) {

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: const Text('Edit Schedule'),
        automaticallyImplyLeading: false,
      ),
      material: (_, __) => MaterialScaffoldData(
        extendBody: false
      ),
      cupertino: (_, __) => CupertinoPageScaffoldData(

      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: ScheduleEntry(),
      ),
    );
  }

}

Future<DeviceUser?> showEditScheduleModal(BuildContext context) {
  return showPlatformModalBottomSheet(
      context: context,
      expand: false,
      builder: (context) {
        return const DeviceSelectorModal();
      }
  );
}