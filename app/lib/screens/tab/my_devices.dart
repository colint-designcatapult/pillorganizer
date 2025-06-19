import 'package:app/api/device.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/widgets/multiple_devices.dart';
import 'package:app/widgets/single_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class MyDevicesScreen extends StatefulWidget {
  const MyDevicesScreen({super.key});

  @override
  _MyDevicesScreenState createState() => _MyDevicesScreenState();
}

class _MyDevicesScreenState extends State<MyDevicesScreen> {
  int selectedButtonIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer2<SelectedDeviceProvider, DeviceListProvider>(
      builder: (context, prov, deviceListProv, _) {
        final deviceCount = deviceListProv.value?.length ?? 0;

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
                        child: deviceListProv.loading
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : deviceCount > 1
                                ? MultipleDevices(
                                    devices: deviceListProv.value!,
                                    selectedButtonIndex: selectedButtonIndex,
                                    onSelectionChanged: (index) {
                                      setState(() {
                                        selectedButtonIndex = index;
                                      });
                                    },
                                  )
                                : SingleDevice(
                                    showAddDeviceSection: deviceCount == 1,
                                    device: prov.device,
                                    isModal: false,
                                  ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
