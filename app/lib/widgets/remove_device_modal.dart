import 'package:app/api/device.dart';
import 'package:app/provider/device_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/service/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RemoveDeviceDialog extends ConsumerStatefulWidget {
  final DeviceUser? device;

  const RemoveDeviceDialog({super.key, this.device});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RemoveDeviceDialog();
}

class _RemoveDeviceDialog extends ConsumerState<RemoveDeviceDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12).r,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      PhosphorIconsBold.x,
                      size: 24.h,
                    ),
                    color: const Color(0XFF101828),
                  ),
                ],
              ),
              Icon(
                PhosphorIconsRegular.warning,
                color: const Color(0XFF7A2C2C),
                size: 48.h,
              ),
              SizedBox(height: 4.h),
              Text(
                AppLocalizations.of(context)!.removingDevice,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(
                      0XFF7A2C2C,
                    ),
                    fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0).w,
                child: Text(
                  AppLocalizations.of(context)!.removingDeviceConfirmation,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: const Color(0XFF667085)),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 32.h),
              Row(
                children: <Widget>[
                  Expanded(
                      child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF206B8B),
                            width: 1.w,
                          ),
                        ),
                        child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              AppLocalizations.of(context)!.back,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF206B8B)),
                            ))),
                  )),
                  SizedBox(width: 12.w),
                  Expanded(
                      child: GestureDetector(
                    onTap: () {
                      _onDelete();
                    },
                    child: Container(
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7A2C2C),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF7A2C2C),
                            width: 1.w,
                          ),
                        ),
                        child: Align(
                            alignment: Alignment.center,
                            child: Text(AppLocalizations.of(context)!.remove,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      color: Colors.white,
                                    )))),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onDelete() async {
    try {
      final selectedDeviceNotifier = ref.read(activeDeviceProvider.notifier);
      final deviceListNotifier = ref.read(deviceListProvider.notifier);

      final currentSelectedDevice = ref.read(activeDeviceProvider);
      final deviceToRemove = widget.device ?? currentSelectedDevice;

      if (deviceToRemove == null) return;

      final isRemovingSelectedDevice =
          currentSelectedDevice?.deviceID == deviceToRemove.deviceID;

      await deviceListNotifier.removeDevice(deviceToRemove.deviceID);

      if (isRemovingSelectedDevice) {
        final devices = ref.read(deviceListProvider).asData?.value ?? [];
        if (devices.isNotEmpty) {
          selectedDeviceNotifier.selectDevice(devices.first);
        }
      }

      if (context.mounted) {
        Navigator.of(context).pop();
        if (isRemovingSelectedDevice) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/index', (route) => false);
        }
      }
    } catch (error) {
      if (context.mounted) {
        showErrorDialog(context, error.toString());
      }
    }
  }
}
