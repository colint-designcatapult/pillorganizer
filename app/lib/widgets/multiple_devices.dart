import 'package:app/api/device.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/widgets/add_device.dart';
import 'package:app/widgets/single_device_modal.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MultipleDevices extends ConsumerWidget {
  final List<DeviceUser> devices;

  const MultipleDevices({
    super.key,
    required this.devices,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDevice = ref.watch(activeDeviceProvider);
    final activeDeviceNotifier = ref.read(activeDeviceProvider.notifier);

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 0.h),
      margin: EdgeInsets.only(bottom: 60.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0).r,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24.h),
            Text(
              AppLocalizations.of(context)!.manageDevices,
              style: TextStyle(
                fontSize: 16.h,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              AppLocalizations.of(context)!.modifyExistingPillOrganiser,
              style: TextStyle(
                fontSize: 16.h,
              ),
            ),
            SizedBox(height: 16.h),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                final isCurrentDevice =
                    activeDevice?.deviceID == device.deviceID;
                final isDeviceReadOnly = !device.owner;

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4.h),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFE8EFF4),
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0).r,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16.h,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  if (isCurrentDevice) ...[
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 2.h,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xffBED4D8),
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8.w,
                                            height: 8.w,
                                            margin:
                                                EdgeInsets.only(right: 6.w),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF7CAC7B),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Text(
                                            AppLocalizations.of(context)!
                                                .current,
                                            style: TextStyle(
                                              fontSize: 12.h,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  const Color(0xff31454D),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                  ],
                                  if (isDeviceReadOnly) ...[
                                    Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xffF8F9FC),
                                          borderRadius:
                                              BorderRadius.circular(50).r,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.w, vertical: 2.h),
                                        child: Text(
                                          AppLocalizations.of(context)!
                                              .viewOnly,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xff363F72),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ))
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isCurrentDevice) ...[
                              IconButton(
                                padding: const EdgeInsets.all(12),
                                icon: Icon(
                                  PhosphorIconsRegular.arrowsLeftRight,
                                  size: 24.h,
                                ),
                                color: const Color(0xFF206B8B),
                                onPressed: () {
                                  activeDeviceNotifier.selectDevice(device);
                                  Navigator.of(context)
                                      .pushNamedAndRemoveUntil(
                                          '/index', (route) => false);
                                },
                                style: ButtonStyle(
                                  shape: WidgetStateProperty.all<
                                      OutlinedBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8.r),
                                    ),
                                  ),
                                  side: WidgetStateProperty.resolveWith<
                                      BorderSide>(
                                    (Set<WidgetState> states) {
                                      return const BorderSide(
                                        color: Color(0xFF8BCAE5),
                                        width: 2.0,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                            ],
                            IconButton(
                              padding: const EdgeInsets.all(12),
                              icon: isDeviceReadOnly
                                  ? Icon(
                                      PhosphorIconsRegular.eye,
                                      size: 24.h,
                                    )
                                  : SvgPicture.asset(
                                      'lib/assets/SVG/pencilLight.svg',
                                      width: 24.w,
                                      height: 24.h,
                                    ),
                              onPressed: () {
                                showMaterialModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => SingleDeviceModal(
                                    deviceId: device.deviceID,
                                  ),
                                );
                              },
                              color: const Color(0xFF206B8B),
                              style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.all<Color>(
                                        Colors.transparent),
                                shape: WidgetStateProperty.all<
                                    OutlinedBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8.r),
                                  ),
                                ),
                                side: WidgetStateProperty.resolveWith<
                                    BorderSide>(
                                  (Set<WidgetState> states) {
                                    return const BorderSide(
                                      color: Color(0xFF8BCAE5),
                                      width: 2.0,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 28.h),
            const AddDevice(),
            SizedBox(height: 28.h),
          ],
        ),
      ),
    );
  }
}
