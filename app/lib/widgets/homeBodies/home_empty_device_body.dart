import 'package:app/provider/medication_provider.dart';
import 'package:app/provider/new_medication_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/screens/modals/add_new_pills_modal.dart';
import 'package:app/widgets/addNewPill/medication_card_entry.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeEmptyDeviceBody extends ConsumerWidget {
  final bool isOwner;

  const HomeEmptyDeviceBody({super.key, required this.isOwner});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtext = isOwner
        ? AppLocalizations.of(context)!.homeEmptySubtextOwner
        : AppLocalizations.of(context)!.homeEmptySubtextCaregiver;

    return ClipRRect(
        borderRadius:
            BorderRadius.only(topRight: const Radius.circular(40.0).r),
        child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topRight: const Radius.circular(40.0).r,
              ),
            ),
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
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
                            final device = ref.read(activeDeviceProvider);

                            if (device == null) {
                              return;
                            }

                            ref.read(newMedicationProvider.notifier).initialize(
                              device.id,
                              onComplete: () {
                                ref.invalidate(medicationsProvider);
                              },
                            );

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
                                  return MedicationModal(
                                    onBack: () =>
                                        {Navigator.of(context).pop()},
                                    onNext: true,
                                    child:
                                        const MedicationCardEntry(),
                                  );
                                });
                          },
                          child: DottedBorder(
                            options: RoundedRectDottedBorderOptions(
                              color: const Color(0xff206B8B),
                              strokeWidth: 2.w,
                              dashPattern: [10.w, 5.w],
                              radius: Radius.circular(8.r)
                            ),
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
}
