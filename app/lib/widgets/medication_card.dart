import 'package:app/api/medication.dart';
import 'package:app/widgets/medication_icon.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../provider/new_medication_provider.dart';
import '../provider/medication_provider.dart';
import '../provider/selected_device_provider.dart';
import '../screens/modals/add_new_pills_modal.dart';
import 'addNewPill/medication_card_entry.dart';

// Since NewMedicationProvider is likely still a ChangeNotifier, 
// we'll need to handle it. However, I aim to migrate ALL to Riverpod.
// For now, I'll leave the logic but use ref.watch for others.

class MedicationCard extends ConsumerWidget {
  final ScheduledMedication med;
  final Color backgroundColor;

  const MedicationCard(
      {super.key, required this.med, this.backgroundColor = Colors.white});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDevice = ref.watch(activeDeviceProvider);
    final deviceID = activeDevice?.deviceID ?? 0;

    void onComplete() {
      ref.invalidate(medicationsProvider);
    }

    return GestureDetector(
      onTap: () {
        ref.read(newMedicationProvider.notifier).initialize(
          deviceID,
          existing: med,
          onComplete: onComplete,
        );
        showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: const Color(0xFFFBFCFF),
            elevation: 0,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width,
            ),
            builder: (context) {
              return MedicationModal(
                  medicationID: med.id,
                  onBack: () {
                    Navigator.of(context).pop();
                  },
                  onNext: true,
                  onComplete: onComplete,
                  child: const MedicationCardEntry());
            });
      },
      child: Padding(
          padding: EdgeInsets.only(bottom: 20.h),
          child: Container(
              height: 80.h,
              padding: EdgeInsets.fromLTRB(18.w, 0.h, 18.w, 0.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8).r,
                color: backgroundColor,
              ),
              child: Row(
                children: [
                   MedicationIcon.fromMed(med, 54.h),
                  SizedBox(
                    width: 18.w,
                  ),
                  Expanded(
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(med.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700)),
                                Text(AppLocalizations.of(context)!.everyday,
                                    style:
                                        Theme.of(context).textTheme.bodySmall)
                              ]))),
                  SizedBox(
                    width: 4.w,
                  ),
                  if (med.dispenseTimes
                      .any((time) => time.period == DayPeriod.pm))
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'lib/assets/SVG/DEV_SYM_PM.svg',
                            width: 18.w,
                            height: 18.h,
                          ),
                          SizedBox(
                            height: 4.h,
                          ),
                          Text("PM",
                              style: Theme.of(context).textTheme.bodySmall),
                        ]),
                  if (med.dispenseTimes
                          .any((time) => time.period == DayPeriod.am) &&
                      med.dispenseTimes
                          .any((time) => time.period == DayPeriod.pm))
                    SizedBox(width: 12.w),
                  if (med.dispenseTimes
                      .any((time) => time.period == DayPeriod.am))
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'lib/assets/SVG/DEV_SYM_AM.svg',
                            width: 18.w,
                            height: 18.h,
                          ),
                          SizedBox(
                            height: 4.h,
                          ),
                          Text("AM",
                              style: Theme.of(context).textTheme.bodySmall),
                        ]),
                  SizedBox(
                    width: 8.w,
                  ),
                  Icon(
                    PhosphorIconsRegular.dotsThreeVertical,
                    size: 24.h,
                  )
                ],
              ))),
    );
  }
}
