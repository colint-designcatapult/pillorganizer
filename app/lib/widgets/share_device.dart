import 'package:app/apiv2/models/device.dart';
import 'package:app/provider/caregiver_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/widgets/manage_caregivers_widget.dart';
import 'package:flutter/material.dart';
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
  void _showInviteSheet() {
    final targetDevice = widget.device ?? ref.read(activeDeviceProvider);
    if (targetDevice == null) return;

    final emailController = TextEditingController();
    final nicknameController = TextEditingController();
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
                  AppLocalizations.of(context)!.inviteByEmail,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: emailController,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.enterCaregiverEmail,
                    labelText: AppLocalizations.of(context)!.email,
                    border: const OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: nicknameController,
                  maxLength: 100,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.enterCaregiverName,
                    labelText: AppLocalizations.of(context)!.caregiverName,
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
                            final email = emailController.text.trim();
                            final nickname = nicknameController.text.trim();
                            if (email.isEmpty || nickname.isEmpty) return;
                            setSheetState(() {
                              isLoading = true;
                              sheetError = null;
                            });
                            try {
                              await ref
                                  .read(caregiverInviteProvider.notifier)
                                  .inviteCaregiver(
                                    email: email,
                                    nickname: nickname,
                                    deviceId: targetDevice.id,
                                    tenantId: targetDevice.tenantId,
                                  );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(this.context)!.caregiverInvited),
                                  ),
                                );
                              }
                            } catch (e) {
                              setSheetState(() {
                                isLoading = false;
                                sheetError = AppLocalizations.of(context)!.errorInvitingCaregiver;
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
                            AppLocalizations.of(context)!.sendInvite,
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

  @override
  Widget build(BuildContext context) {
    final targetDevice = widget.device ?? ref.watch(activeDeviceProvider);

    if (targetDevice == null) {
      return const Center(child: CircularProgressIndicator());
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
        Text(
          AppLocalizations.of(context)!.inviteCollaboratorsDescription,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: 24.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showInviteSheet,
            icon: Icon(PhosphorIconsRegular.envelopeSimple, size: 20.h),
            label: Text(
              AppLocalizations.of(context)!.inviteByEmail,
              style: TextStyle(
                fontSize: 16.h,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF206B8B),
              ),
            ),
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
          ),
        ),
        ManageCaregiversWidget(deviceId: targetDevice.id),
      ],
    );
  }
}
