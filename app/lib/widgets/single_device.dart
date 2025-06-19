import 'package:app/api/device.dart';
import 'package:app/provider/caregiver_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/widgets/device_rename_modal.dart';
import 'package:app/widgets/notifications_settings.dart';
import 'package:app/widgets/schedule_entry.dart';
import 'package:app/widgets/share_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

void changeName(context, {DeviceUser? device}) {
  showDialog(
    context: context,
    builder: (_) => ChangeDeviceNameDialog(device: device),
  );
}

class SingleDevice extends StatefulWidget {
  final DeviceUser? device;
  final bool showAddDeviceSection;
  final bool isModal;

  const SingleDevice({
    super.key,
    required this.device,
    required this.showAddDeviceSection,
    this.isModal = false,
  });

  @override
  State<SingleDevice> createState() => _SingleDeviceState();
}

class _SingleDeviceState extends State<SingleDevice> {
  int _selectedButtonIndex = 0;

  Widget _getSelectedButtonIcon(int index) {
    switch (index) {
      case 0:
        return Icon(
          PhosphorIcons.gear,
          size: 18.h,
        );
      case 1:
        return Icon(
          PhosphorIcons.bell_simple_ringing,
          size: 18.h,
        );
      case 2:
        return SvgPicture.asset(
          'lib/assets/SVG/share.svg',
          width: 18.w,
          height: 18.h,
        );
      default:
        return Icon(
          PhosphorIcons.gear,
          size: 18.h,
        );
    }
  }

  Widget _getSelectedSection(int index) {
    switch (index) {
      case 0:
        return ScheduleEntry(showAddDeviceSection: widget.showAddDeviceSection);
      case 1:
        return NotificationsSettings();
      case 2:
        // Fetch share codes when share section is selected
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.device != null) {
            Provider.of<CaregiverProvider>(context, listen: false)
                .fetchShareCodesForDevices([widget.device!.deviceID]);
          } else {
            final selectedDevice =
                Provider.of<SelectedDeviceProvider>(context, listen: false)
                    .device;
            if (selectedDevice != null) {
              Provider.of<CaregiverProvider>(context, listen: false)
                  .fetchShareCodesForDevices([selectedDevice.deviceID]);
            }
          }
        });
        return ShareDevice(device: widget.device);
      default:
        return ScheduleEntry(showAddDeviceSection: widget.showAddDeviceSection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SelectedDeviceProvider, DeviceListProvider>(
      builder: (context, selectedDeviceProvider, deviceListProvider, child) {
        DeviceUser? currentDevice = widget.device;
        if (widget.device != null && deviceListProvider.value != null) {
          currentDevice = deviceListProvider.value!.firstWhere(
              (d) => d.deviceID == widget.device!.deviceID,
              orElse: () => widget.device!);
        } else if (widget.device == null) {
          currentDevice = selectedDeviceProvider.device;
        }

        return Container(
          margin: widget.isModal
              ? EdgeInsets.only(top: 60.h)
              : EdgeInsets.only(bottom: 60.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12.0).r,
              topRight: const Radius.circular(12.0).r,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.only(
                  top: 24.h,
                  bottom: 12.h,
                  left: 20.w,
                  right: 20.w,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.isModal)
                      IconButton(
                        icon: Icon(
                          PhosphorIcons.x,
                          size: 24.h,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            currentDevice?.name ??
                                AppLocalizations.of(context)!.loadingState,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 30.h,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: SvgPicture.asset(
                              'lib/assets/SVG/pencilLight.svg',
                              width: 24.w,
                              height: 24.h,
                            ),
                            color: Theme.of(context).primaryColor,
                            onPressed: () {
                              changeName(context, device: currentDevice);
                            },
                          ),
                        ]),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.only(
                  top: 12.h,
                  bottom: 12.h,
                  left: 20.w,
                  right: 20.w,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton(
                        segments: <ButtonSegment>[
                          ButtonSegment(
                              icon: Icon(
                                PhosphorIcons.gear,
                                size: 18.h,
                              ),
                              value: 0,
                              label: Text(
                                AppLocalizations.of(context)!.settings,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              )),
                          ButtonSegment(
                            icon: Icon(
                              PhosphorIcons.bell_simple_ringing,
                              size: 18.h,
                            ),
                            value: 1,
                            label: Text(
                              AppLocalizations.of(context)!.notifications,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                          ButtonSegment(
                            icon: SvgPicture.asset(
                              'lib/assets/SVG/share.svg',
                              width: 18.w,
                              height: 18.h,
                            ),
                            value: 2,
                            label: Text(
                              AppLocalizations.of(context)!.share,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                        selected: {_selectedButtonIndex},
                        selectedIcon:
                            _getSelectedButtonIcon(_selectedButtonIndex),
                        onSelectionChanged: (Set newSelection) {
                          setState(() {
                            _selectedButtonIndex = newSelection.first;
                          });
                        },
                        style: ButtonStyle(
                          shape: MaterialStateProperty.all<OutlinedBorder>(
                              RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadiusDirectional.circular(8.r))),
                          side: MaterialStateProperty.resolveWith<BorderSide>(
                              (Set<MaterialState> states) {
                            return BorderSide(
                                color: const Color(0xFFBFD2DB), width: 2.h);
                          }),
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return const Color(0xFFE8EFF4);
                            }
                            return Colors.white;
                          }),
                          padding:
                              MaterialStateProperty.all<EdgeInsetsGeometry>(
                            EdgeInsets.symmetric(
                                vertical: 16.h, horizontal: 12.w),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 20.h),
                      child: _getSelectedSection(_selectedButtonIndex)),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
