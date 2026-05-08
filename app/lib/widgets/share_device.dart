import 'dart:async';

import 'package:app/apiv2/models/device.dart';
import 'package:app/provider/caregiver_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/widgets/manage_caregivers_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShareDevice extends ConsumerStatefulWidget {
  final DeviceMetadata? device;

  const ShareDevice({super.key, this.device});

  @override
  ConsumerState<ShareDevice> createState() => _ShareDeviceState();
}

class _ShareDeviceState extends ConsumerState<ShareDevice> {
  Timer? _countdownTimer;
  final ValueNotifier<int> _countdownNotifier = ValueNotifier<int>(0);

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
      ref.read(caregiverProvider.notifier).fetchShareCodesForDevices([widget.device!.id]);
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final caregiver = ref.read(caregiverProvider.notifier);
        final targetDevice = widget.device ?? ref.read(activeDeviceProvider);

        if (targetDevice != null) {
          final shareCode =
              caregiver.getShareCodeForDevice(targetDevice.id);
          if (shareCode == null || !shareCode.isValid) {
            timer.cancel();
            _countdownNotifier.value = 0;
            caregiver.clearExpiredCodes();
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

  void _showGenerateCodeSheet() {
    final targetDevice = widget.device ?? ref.read(activeDeviceProvider);
    if (targetDevice == null) return;

    final nameController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      builder: (sheetContext) {
        bool isLoading = false;
        String? sheetError;
        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: 24.w,
              right: 24.w,
              top: 24.h,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.caregiverName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  maxLength: 100,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.enterCaregiverName,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (sheetError != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    sheetError!,
                    style: TextStyle(
                      fontSize: 14.h,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) return;
                            setSheetState(() {
                              isLoading = true;
                              sheetError = null;
                            });
                            try {
                              await ref
                                  .read(caregiverProvider.notifier)
                                  .generateCaregiverCodeForDevice(
                                      targetDevice.id, name);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                final shareCode = ref
                                    .read(caregiverProvider.notifier)
                                    .getShareCodeForDevice(targetDevice.id);
                                if (shareCode != null && shareCode.isValid) {
                                  setState(() {});
                                  _countdownNotifier.value =
                                      shareCode.remainingSeconds;
                                  _startCountdownTimer();
                                }
                              }
                            } catch (_) {
                              setSheetState(() {
                                isLoading = false;
                                sheetError = AppLocalizations.of(context)!
                                    .errorGenerateCode;
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF206B8B),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            height: 24.h,
                            width: 24.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context)!.generateCode,
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _copyCode() {
    final caregiver = ref.read(caregiverProvider.notifier);
    final targetDevice = widget.device ?? ref.read(activeDeviceProvider);

    if (targetDevice != null) {
      final shareCode =
          caregiver.getShareCodeForDevice(targetDevice.id);
      if (shareCode != null) {
        Clipboard.setData(ClipboardData(text: shareCode.codeString));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetDevice = widget.device ?? ref.watch(activeDeviceProvider);
    final caregiver = ref.watch(caregiverProvider);

    if (targetDevice == null) {
      return const Center(child: CircularProgressIndicator());
    }

        final shareCode =
            ref.read(caregiverProvider.notifier).getShareCodeForDevice(targetDevice.id);
        final code = shareCode?.codeString;
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
            if (caregiver.isLoading) ...[
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
                    onPressed: caregiver.isLoading
                        ? null
                        : _showGenerateCodeSheet,
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all<OutlinedBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      side: WidgetStateProperty.all<BorderSide>(
                        const BorderSide(
                          color: Color(0xFF8BCAE5),
                          width: 1.0,
                        ),
                      ),
                      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                        EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
                      ),
                    ),
                    child: caregiver.isLoading
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
                              color: const Color(0xFF206B8B),
                            ),
                          ),
                  ),
                ),
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
                    onPressed: caregiver.isLoading
                        ? null
                        : _showGenerateCodeSheet,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                    ),
                    icon: caregiver.isLoading
                        ? SizedBox(
                            height: 16.h,
                            width: 16.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF206B8B),
                              ),
                            ),
                          )
                        : Icon(
                            PhosphorIconsRegular.arrowClockwise,
                            size: 20.h,
                            color: const Color(0xFF206B8B),
                          ),
                    label: Text(
                      AppLocalizations.of(context)!.generateCode,
                      style: TextStyle(
                        fontSize: 14.h,
                        fontWeight: FontWeight.w600,
                        color: caregiver.isLoading
                            ? const Color(0xFFCCCCCC)
                            : const Color(0xFF206B8B),
                        decoration: caregiver.isLoading
                            ? TextDecoration.none
                            : TextDecoration.underline,
                        decorationColor: const Color(0xFF206B8B),
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
            ],
            ManageCaregiversWidget(deviceId: targetDevice.id),
          ],
        );
  }
}
