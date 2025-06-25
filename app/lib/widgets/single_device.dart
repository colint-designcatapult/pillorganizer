import 'package:app/api/device.dart';
import 'package:app/widgets/device_rename_modal.dart';
import 'package:app/widgets/notifications_settings.dart';
import 'package:app/widgets/schedule_entry.dart';
import 'package:app/widgets/share_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

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

  Widget _getSelectedSection(int index) {
    switch (index) {
      case 0:
        return ScheduleEntry(
            showAddDeviceSection: widget.showAddDeviceSection,
            device: widget.device,
            isOwner: widget.device?.owner ?? false);
      case 1:
        return NotificationsSettings();
      case 2:
        return ShareDevice(device: widget.device);
      default:
        return ScheduleEntry(
            showAddDeviceSection: widget.showAddDeviceSection,
            device: widget.device,
            isOwner: widget.device?.owner ?? false);
    }
  }

  List<ButtonSegment> _getSegments() {
    return [
      ButtonSegment(
        value: 0,
        label: Text(
          AppLocalizations.of(context)!.settings,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12.h,
                color: const Color(0xFF31454D),
              ),
        ),
      ),
      ButtonSegment(
        value: 1,
        label: Text(
          AppLocalizations.of(context)!.notifications,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12.h,
                color: const Color(0xFF31454D),
              ),
        ),
      ),
      ButtonSegment(
        value: 2,
        label: Text(
          AppLocalizations.of(context)!.share,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12.h,
                color: const Color(0xFF31454D),
              ),
        ),
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    bool isOwner = widget.device?.owner ?? false;
    List<ButtonSegment> segments = _getSegments();

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
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Text(
                    widget.device?.name ??
                        AppLocalizations.of(context)!.loadingState,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 30.h,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isOwner)
                    IconButton(
                      icon: SvgPicture.asset(
                        'lib/assets/SVG/pencilLight.svg',
                        width: 24.w,
                        height: 24.h,
                      ),
                      color: Theme.of(context).primaryColor,
                      onPressed: () {
                        changeName(context, device: widget.device);
                      },
                    ),
                ]),
              ],
            ),
          ),
          if (isOwner)
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
                      segments: segments,
                      selected: {_selectedButtonIndex},
                      showSelectedIcon: false,
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
                              color: const Color(0xFFBFD2DB), width: 1.h);
                        }),
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                          if (states.contains(MaterialState.selected)) {
                            return const Color(0xFFF1F5F6);
                          }
                          return Colors.white;
                        }),
                        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                          EdgeInsets.symmetric(vertical: 16.h, horizontal: 0.w),
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
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                  child: _getSelectedSection(_selectedButtonIndex)),
            ),
          )
        ],
      ),
    );
  }
}
