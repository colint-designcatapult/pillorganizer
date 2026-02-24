import 'package:app/api/device.dart';
import 'package:app/provider/device_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/screens/provisioning/join_device_screen.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

class SwitchDevice extends StatefulWidget {
  const SwitchDevice({Key? key}) : super(key: key);

  @override
  _SwitchDeviceState createState() => _SwitchDeviceState();
}

class _SwitchDeviceState extends State<SwitchDevice> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color(0x00101828).withOpacity(0.05), // Shadow color
              offset: const Offset(0, 1), // Shadow position
              blurRadius: 2, // Shadow blur
              spreadRadius: 0, // Spread radius
            ),
          ],
          borderRadius: BorderRadius.circular(8), // Match button corners
        ),
        child: Material(
          color: Colors.transparent, // Ensure ripple effect is visible
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showQuickSwitchDialog(),
            child: ElevatedButton(
              onPressed: null, // InkWell handles the tap
              style: ElevatedButton.styleFrom(
                elevation: 0, // Remove default elevation
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: const Color(0xff206B8B), // Button color
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context)!.quickSwitch,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xffffffff),
                          fontFamily: 'Poppins')),
                  const SizedBox(width: 8),
                  // Spacing between icon and text
                  const Icon(Icons.swap_horiz,
                      size: 20, color: Color(0xffffffff)),
                  // Icon
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleConnectNewDevice() {
  }

  void _handleJoinExistingDevice() {
    Navigator.of(context).pop();
    Navigator.of(context).push(JoinDevicePage.route(context));
  }

  void _showQuickSwitchDialog() {
    var devices = Provider.of<DeviceProvider>(context, listen: false).devices;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Icon(
                        PhosphorIconsBold.x,
                        size: 24.h,
                        color: const Color(0XFF101828),
                      )),
                ),
                const Icon(Icons.swap_horiz,
                    size: 44, color: Color(0xff206B8B)),
                const SizedBox(height: 8),
                Text(AppLocalizations.of(context)!.quickSwitch,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins')),
                const SizedBox(height: 8),
                Text(AppLocalizations.of(context)!.quickSwitchSubText,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff31454D),
                        fontFamily: 'Poppins')),
                const SizedBox(height: 24),
                ...devices.map((device) => _deviceSelectButton(device)),
                _deviceJoinButton(
                    AppLocalizations.of(context)!.quickSwitchNewDevice,
                    _handleConnectNewDevice),
                _deviceJoinButton(
                    AppLocalizations.of(context)!.quickSwitchExistingDevice,
                    _handleJoinExistingDevice),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleSelectDevice(DeviceUser device) {
    Provider.of<SelectedDeviceProvider>(context, listen: false)
        .selectDevice(device);
    Navigator.of(context).pop();
  }

  Widget _deviceSelectButton(DeviceUser device) {
    return GestureDetector(
        child: Container(
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0.h),
      margin: EdgeInsets.only(bottom: 8.h),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleSelectDevice(device),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.white,
          side: const BorderSide(
            color: Color(0xFF8BCAE5),
            width: 1.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8).r,
          ),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 18.w),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text(device.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Color(0xff206B8B),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins')),
          ),
          if (!device.owner)
            Container(
                decoration: BoxDecoration(
                  color: const Color(0xffF8F9FC),
                  borderRadius: BorderRadius.circular(50).r,
                ),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                child: Text(
                  AppLocalizations.of(context)!.viewOnly,
                  style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
                )),
          const SizedBox(width: 8), // Spacing between icon and text
          const Icon(PhosphorIconsRegular.arrowRight,
              size: 20, color: Color(0xff206B8B)), // Icon
        ]),
      ),
    ));
  }

  Widget _deviceJoinButton(String btnText, void Function() onPress) {
    return GestureDetector(
        child: Container(
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0.h),
      margin: EdgeInsets.only(bottom: 8.h),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPress,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8).r,
          ),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 18.w),
        ),
        child: Text(btnText,
            style: const TextStyle(
                color: Color(0xff445860),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins')),
      ),
    ));
  }
}
