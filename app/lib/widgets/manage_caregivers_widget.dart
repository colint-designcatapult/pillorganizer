import 'package:app/apiv2/models/dto.dart';
import 'package:app/provider/caregiver_provider.dart';
import 'package:app/provider/device_provider.dart';
import 'package:app/widgets/generic_yes_no_modal.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManageCaregiversWidget extends ConsumerStatefulWidget {
  final String deviceId;

  const ManageCaregiversWidget({super.key, required this.deviceId});

  @override
  ConsumerState<ManageCaregiversWidget> createState() =>
      _ManageCaregiversWidgetState();
}

class _ManageCaregiversWidgetState
    extends ConsumerState<ManageCaregiversWidget> {

  void _confirmRevoke(CaregiverListItemDto caregiver) {
    showDialog(
      context: context,
      builder: (_) => GenericYesNoModal(
        icon: PhosphorIconsFill.userMinus,
        title: AppLocalizations.of(context)!.revokeAccess,
        subtitle: AppLocalizations.of(context)!
            .revokeAccessConfirmation(caregiver.displayName),
        saveWidgetText: AppLocalizations.of(context)!.revoke,
        saveWidgetAction: () async {
          Navigator.of(context).pop();
          await ref
              .read(caregiverListProvider(widget.deviceId).notifier)
              .revokeCaregiver(caregiver.id);
        },
      ),
    );
  }

  void _showTransferSheet(List<CaregiverListItemDto> caregivers) {
    final nonPrimary = caregivers.where((c) => !c.primaryUser).toList();
    if (nonPrimary.isEmpty) return;

    String? selectedId;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.transferPrimaryUser,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: 8.h),
              Text(
                AppLocalizations.of(context)!.transferPrimaryUserDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 16.h),
              ...nonPrimary.map(
                (c) => RadioListTile<String>(
                  title: Text(c.displayName),
                  subtitle: c.nickname != null && c.userName != null ? Text(c.userName!) : null,
                  value: c.id,
                  groupValue: selectedId,
                  onChanged: (val) => setSheetState(() => selectedId = val),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedId == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          _confirmTransfer(selectedId!, nonPrimary
                              .firstWhere((c) => c.id == selectedId)
                              .displayName);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7A2C2C),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.transferPrimaryUser,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmTransfer(String caregiverId, String displayName) {
    showDialog(
      context: context,
      builder: (_) => GenericYesNoModal(
        icon: PhosphorIconsFill.arrowsLeftRight,
        title: AppLocalizations.of(context)!.transferPrimaryUser,
        subtitle: AppLocalizations.of(context)!
            .transferPrimaryUserConfirmation(displayName),
        saveWidgetText: AppLocalizations.of(context)!.transfer,
        saveWidgetAction: () async {
          Navigator.of(context).pop();
          await ref
              .read(caregiverListProvider(widget.deviceId).notifier)
              .transferPrimaryUser(caregiverId);
          // Refresh the device list since primary user status changed
          ref.read(deviceListProvider.notifier).refresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caregiversAsync = ref.watch(caregiverListProvider(widget.deviceId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24.h),
        Text(
          AppLocalizations.of(context)!.peopleWithAccess,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 8.h),
        caregiversAsync.when(
          loading: () => Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: const CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text(
              AppLocalizations.of(context)!.errorLoadingCaregivers,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          data: (caregivers) => Column(
            children: [
              ...caregivers.map(
                (caregiver) => _CaregiverTile(
                  caregiver: caregiver,
                  onRevoke: caregiver.primaryUser
                      ? null
                      : () => _confirmRevoke(caregiver),
                ),
              ),
              if (caregivers.where((c) => !c.primaryUser).isNotEmpty) ...[
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showTransferSheet(caregivers),
                    icon: Icon(PhosphorIconsRegular.arrowsLeftRight, size: 20.h),
                    label: Text(
                        AppLocalizations.of(context)!.transferPrimaryUser),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7A2C2C),
                      side: const BorderSide(color: Color(0xFF7A2C2C)),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CaregiverTile extends StatelessWidget {
  final CaregiverListItemDto caregiver;
  final VoidCallback? onRevoke;

  const _CaregiverTile({
    required this.caregiver,
    this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Icon(
            caregiver.primaryUser
                ? PhosphorIconsFill.crown
                : PhosphorIconsRegular.user,
            size: 24.h,
            color: caregiver.primaryUser
                ? const Color(0xFFD4A017)
                : const Color(0xFF206B8B),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caregiver.displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (caregiver.nickname != null && caregiver.userName != null)
                  Text(
                    caregiver.userName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                if (caregiver.primaryUser)
                  Text(
                    AppLocalizations.of(context)!.primaryUser,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFD4A017),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
              ],
            ),
          ),
          if (onRevoke != null)
            IconButton(
              icon: Icon(PhosphorIconsRegular.userMinus, size: 20.h),
              onPressed: onRevoke,
              tooltip: AppLocalizations.of(context)!.revokeAccess,
              color: const Color(0xFF7A2C2C),
            ),
        ],
      ),
    );
  }
}
