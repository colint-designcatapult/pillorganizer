import 'dart:async';

import 'package:app/api/device.dart';
import 'package:app/provider/caregiver_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

class ShareDevice extends StatefulWidget {
  final DeviceUser? device;

  const ShareDevice({super.key, this.device});

  @override
  State<ShareDevice> createState() => _ShareDeviceState();
}

class _ShareDeviceState extends State<ShareDevice> {
  Timer? _countdownTimer;
  final ValueNotifier<int> _countdownNotifier = ValueNotifier<int>(0);
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchShareCodes();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _countdownNotifier.dispose();
    super.dispose();
  }

  void _fetchShareCodes() {
    if (widget.device != null) {
      final caregiverProvider =
          Provider.of<CaregiverProvider>(context, listen: false);
      caregiverProvider.fetchShareCodesForDevices([widget.device!.deviceID]);
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final caregiverProvider =
            Provider.of<CaregiverProvider>(context, listen: false);
        final selectedDeviceProvider =
            Provider.of<SelectedDeviceProvider>(context, listen: false);
        final targetDevice = widget.device ?? selectedDeviceProvider.device;

        if (targetDevice != null) {
          final shareCode =
              caregiverProvider.getShareCodeForDevice(targetDevice.deviceID);
          if (shareCode == null || !shareCode.isValid) {
            timer.cancel();
            _countdownNotifier.value = 0;
            caregiverProvider.clearExpiredCodes();
            return;
          }

          _countdownNotifier.value = shareCode.remainingSeconds;
        } else {
          timer.cancel();
          _countdownNotifier.value = 0;
        }
      }
    });
  }

  void _generateCode() async {
    final caregiverProvider =
        Provider.of<CaregiverProvider>(context, listen: false);
    final selectedDeviceProvider =
        Provider.of<SelectedDeviceProvider>(context, listen: false);
    final targetDevice = widget.device ?? selectedDeviceProvider.device;

    if (targetDevice != null) {
      setState(() {
        _errorMessage = null;
      });

      try {
        await caregiverProvider
            .generateCaregiverCodeForDevice(targetDevice.deviceID);

        final shareCode =
            caregiverProvider.getShareCodeForDevice(targetDevice.deviceID);
        if (shareCode != null && shareCode.isValid) {
          _countdownNotifier.value = shareCode.remainingSeconds;
          _startCountdownTimer();
        }
      } catch (error) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.errorGenerateCode;
        });
      }
    }
  }

  void _copyCode() {
    final caregiverProvider =
        Provider.of<CaregiverProvider>(context, listen: false);
    final selectedDeviceProvider =
        Provider.of<SelectedDeviceProvider>(context, listen: false);

    DeviceUser? targetDevice;
    if (widget.device != null) {
      targetDevice = widget.device;
    } else {
      targetDevice = selectedDeviceProvider.device;
    }

    if (targetDevice != null) {
      final shareCode =
          caregiverProvider.getShareCodeForDevice(targetDevice.deviceID);
      if (shareCode != null) {
        Clipboard.setData(ClipboardData(text: shareCode.code));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SelectedDeviceProvider, CaregiverProvider>(
      builder: (context, selectedDeviceProvider, caregiverProvider, _) {
        DeviceUser? targetDevice;
        if (widget.device != null) {
          targetDevice = widget.device;
        } else {
          targetDevice = selectedDeviceProvider.device;
        }

        if (targetDevice == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final shareCode =
            caregiverProvider.getShareCodeForDevice(targetDevice.deviceID);
        final code = shareCode?.code;
        final isCodeValid = shareCode != null && shareCode.isValid;

        if (shareCode != null && shareCode.isValid && _countdownTimer == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _countdownNotifier.value = shareCode.remainingSeconds;
            _startCountdownTimer();
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.inviteCollaborators,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 8.h),
            if (!isCodeValid) ...[
              if (caregiverProvider.isFetchingShareCodes) ...[
                SizedBox(height: 40.h),
                Center(
                  child: SizedBox(
                    height: 40.h,
                    width: 40.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 3.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF206B8B),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40.h),
              ] else ...[
                Text(
                  AppLocalizations.of(context)!.inviteCollaboratorsDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: caregiverProvider.isGeneratingCode
                        ? null
                        : _generateCode,
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all<OutlinedBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      side: WidgetStateProperty.resolveWith<BorderSide>(
                        (Set<WidgetState> states) {
                          if (caregiverProvider.isGeneratingCode) {
                            return const BorderSide(
                              color: Color(0xFFCCCCCC),
                              width: 1.0,
                            );
                          } else if (_errorMessage != null) {
                            return BorderSide(
                              color: Theme.of(context).colorScheme.error,
                              width: 1.0,
                            );
                          } else {
                            return const BorderSide(
                              color: Color(0xFF8BCAE5),
                              width: 1.0,
                            );
                          }
                        },
                      ),
                      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                        EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
                      ),
                    ),
                    child: caregiverProvider.isGeneratingCode
                        ? SizedBox(
                            height: 24.h,
                            width: 24.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF206B8B),
                              ),
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context)!.generateCode,
                            style: TextStyle(
                              fontSize: 16.h,
                              fontWeight: FontWeight.w600,
                              color: _errorMessage != null
                                  ? Theme.of(context).colorScheme.error
                                  : const Color(0xFF206B8B),
                            ),
                          ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 14.h,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ] else ...[
              ValueListenableBuilder<int>(
                valueListenable: _countdownNotifier,
                builder: (context, remainingSeconds, child) {
                  return RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text:
                              "${AppLocalizations.of(context)!.codeExpiresIn} ",
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(
                          text:
                              "${remainingSeconds ~/ 60} ${AppLocalizations.of(context)!.minutes} ${remainingSeconds % 60} ${AppLocalizations.of(context)!.seconds}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: code!.split('').map((digit) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      height: 50.h,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFBED4D8),
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: SelectableText(
                          digit,
                          style: TextStyle(
                            fontSize: 24.h,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF31454D),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: caregiverProvider.isGeneratingCode
                        ? null
                        : _generateCode,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                    ),
                    icon: caregiverProvider.isGeneratingCode
                        ? SizedBox(
                            height: 16.h,
                            width: 16.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _errorMessage != null
                                    ? Theme.of(context).colorScheme.error
                                    : const Color(0xFF206B8B),
                              ),
                            ),
                          )
                        : Icon(
                            PhosphorIconsRegular.arrowClockwise,
                            size: 20.h,
                            color: _errorMessage != null
                                ? Theme.of(context).colorScheme.error
                                : const Color(0xFF206B8B),
                          ),
                    label: Text(
                      AppLocalizations.of(context)!.generateCode,
                      style: TextStyle(
                        fontSize: 14.h,
                        fontWeight: FontWeight.w600,
                        color: caregiverProvider.isGeneratingCode
                            ? const Color(0xFFCCCCCC)
                            : _errorMessage != null
                                ? Theme.of(context).colorScheme.error
                                : const Color(0xFF206B8B),
                        decoration: caregiverProvider.isGeneratingCode
                            ? TextDecoration.none
                            : TextDecoration.underline,
                        decorationColor: _errorMessage != null
                            ? Theme.of(context).colorScheme.error
                            : const Color(0xFF206B8B),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _copyCode,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                    ),
                    icon: Icon(
                      PhosphorIconsRegular.copy,
                      size: 20.h,
                      color: const Color(0xFF206B8B),
                    ),
                    label: Text(
                      AppLocalizations.of(context)!.copyCode,
                      style: TextStyle(
                        fontSize: 14.h,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF206B8B),
                        decoration: TextDecoration.underline,
                        decorationColor: const Color(0xFF206B8B),
                      ),
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: 8.h),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 14.h,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}
