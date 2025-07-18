import 'package:app/provider/new_medication_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/screens/modals/add_new_pills_modal.dart';
import 'package:app/widgets/addNewPill/medication_card_entry.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

Widget emptyDeviceScreen(
    BuildContext context, SelectedDeviceProvider selectedDevice) {
  final isOwner = selectedDevice.device?.owner == true;
  final subtext = isOwner
      ? AppLocalizations.of(context)!.homeEmptySubtextOwner
      : AppLocalizations.of(context)!.homeEmptySubtextCaregiver;
  final newMedicationProvider = NewMedicationProvider(
    selectedDevice.device?.deviceID ?? 0,
    () => {},
  );

  return ClipRRect(
      borderRadius: BorderRadius.only(topRight: const Radius.circular(40.0).r),
      child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: const Radius.circular(40.0).r,
            ),
          ),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.homeEmpyTite,
                        style: Theme.of(context).textTheme.labelLarge),
                    Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: Text(subtext,
                            style: Theme.of(context).textTheme.bodyMedium)),
                    if (!isOwner)
                      Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: Text(
                              AppLocalizations.of(context)!
                                  .homeEmptySubtextCaregiverContact,
                              style: Theme.of(context).textTheme.bodyMedium)),
                    if (isOwner)
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: const Color(0xFFFBFCFF),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: const Radius.circular(16).r,
                                ),
                              ),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width,
                              ),
                              builder: (context) {
                                return StatefulBuilder(builder:
                                    (BuildContext context,
                                        StateSetter setState) {
                                  return ChangeNotifierProvider<
                                          NewMedicationProvider>(
                                      create: (context) =>
                                          newMedicationProvider,
                                      builder: (context, _) => MedicationModal(
                                            onBack: () =>
                                                {Navigator.of(context).pop()},
                                            onNext: true,
                                            child: const MedicationCardEntry(),
                                          ));
                                });
                              });
                        },
                        child: DottedBorder(
                          color: const Color(0xff206B8B),
                          strokeWidth: 2.w,
                          dashPattern: [10.w, 5.w],
                          radius: Radius.circular(8.r),
                          borderType: BorderType.RRect,
                          child: Container(
                            padding: EdgeInsets.all(24.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F8FF),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  color: const Color(0xff043C4D),
                                  size: 24.w,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  AppLocalizations.of(context)!.addPills,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: const Color(0xff043C4D),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ]))));
}
