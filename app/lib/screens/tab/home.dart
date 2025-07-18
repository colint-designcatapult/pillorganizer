import 'package:app/api/api.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/screens/ScreenUtilWrapper.dart';
import 'package:app/widgets/device_info_header.dart';
import 'package:app/widgets/homeBodies/home_body.dart';
import 'package:app/widgets/homeBodies/home_disconnected_body.dart';
import 'package:app/widgets/homeBodies/home_empty_device_body.dart';
import 'package:app/widgets/homeBodies/home_no_device_body.dart';
import 'package:app/widgets/stateful_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../api/device.dart';
import '../../platform/ble_auto_supress.dart';
import '../../provider/device_notice_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StatefulWrapper(
        onInit: () {
          _askPermissions(context);
        },
        child: BLEAutoSuppress(
            child: AutoRefresh(
          refreshable: Provider.of<DeviceStateProvider>(context),
          child: Consumer3<DeviceNoticeProvider, SelectedDeviceProvider,
              DeviceStateProvider>(
            builder: (context, deviceNoticeProvider, selectedDevice,
                deviceStateProvider, child) {
              final bool isDisconnected =
                  (deviceNoticeProvider.value ?? DeviceNotice.none) ==
                      DeviceNotice.disconnected;
              final dosePeriods = deviceStateProvider.value?.dosePeriods ?? [];
              final bool isEmpty = !dosePeriods
                  .any((element) => element.medicationIDs.isNotEmpty);

              return ScreenUtilWrapper(
                child: Scaffold(
                  body: Stack(children: [
                    Container(
                      height: MediaQuery.of(context).size.height,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.3317],
                          colors: [
                            Color(0xFF206B8B),
                            Color(0xFF002D40),
                          ],
                        ),
                      ),
                    ),
                    NestedScrollView(
                      headerSliverBuilder:
                          (BuildContext context, bool innerBoxIsScrolled) {
                        return <Widget>[
                          SliverAppBar(
                            toolbarHeight: 160.h,
                            backgroundColor: Colors.transparent,
                            flexibleSpace: FlexibleSpaceBar(
                              expandedTitleScale: 1.0,
                              titlePadding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 0),
                              title: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 24.w, vertical: 12.h),
                                    child: const DeviceInfoHeader(),
                                  ),
                                ],
                              ),
                            ),
                            pinned: false,
                          ),
                        ];
                      },
                      body: _getHomeBody(
                          context, selectedDevice, isDisconnected, isEmpty),
                    ),
                  ]),
                ),
              );
            },
          ),
        )));
  }

  Widget _getHomeBody(
      BuildContext context,
      SelectedDeviceProvider selectedDevice,
      bool isDisconnected,
      bool isEmpty) {
    final noDevice = selectedDevice.device == null;
    if (isDisconnected) {
      return disconnectedDeviceScreen(context, selectedDevice);
    }

    if (isEmpty) {
      return emptyDeviceScreen(context, selectedDevice);
    }

    if (noDevice) {
      return noDeviceScreen(context);
    }

    return homeBody(context);
  }

  Future<void> _askPermissions(BuildContext context) async {
    //Ask Notification permission
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }
  }
}
