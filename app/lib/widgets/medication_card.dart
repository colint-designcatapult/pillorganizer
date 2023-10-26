import 'package:app/api/medication.dart';
import 'package:app/widgets/medication_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../provider/medication_provider.dart';
import '../provider/new_medication_provider.dart';
import '../provider/selected_device_provider.dart';
import '../screens/modals/add_new_pills_modal.dart';
import 'addNewPill/medication_card_entry.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MedicationCard extends StatelessWidget {
  final ScheduledMedication med;
  final Color backgroundColor;

  const MedicationCard(
      {super.key, required this.med, this.backgroundColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    final deviceID = Provider.of<SelectedDeviceProvider>(context, listen: false)
        .device!
        .deviceID;

    void onComplete() {
      Provider.of<MedicationsProvider>(context, listen: false).refresh();
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: const Color(0xFFFBFCFF),
            elevation: 0,
            builder: (context) {
              return ChangeNotifierProvider<NewMedicationProvider>(
                  create: (context) => NewMedicationProvider.fromExisting(
                      deviceID, med, onComplete),
                  child: MedicationModal(
                      medicationID: med.id,
                      onBack: () {
                        Navigator.of(context).pop();
                      },
                      onNext: true,
                      child: const MedicationCardEntry()));
            });
      },
      child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Container(
              height: 80,
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: backgroundColor,
              ),
              child: Row(
                children: [
                  MedicationIcon.fromMed(med, 54),
                  const SizedBox(
                    width: 18,
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
                  const SizedBox(
                    width: 4,
                  ),
                  if (med.dispenseTimes
                      .any((time) => time.period == DayPeriod.pm))
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'lib/assets/SVG/DEV_SYM_PM.svg',
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text("PM",
                              style: Theme.of(context).textTheme.bodySmall),
                        ]),
                  if (med.dispenseTimes
                          .any((time) => time.period == DayPeriod.am) &&
                      med.dispenseTimes
                          .any((time) => time.period == DayPeriod.pm))
                    const SizedBox(width: 12),
                  if (med.dispenseTimes
                      .any((time) => time.period == DayPeriod.am))
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'lib/assets/SVG/DEV_SYM_AM.svg',
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text("AM",
                              style: Theme.of(context).textTheme.bodySmall),
                        ]),
                  const SizedBox(
                    width: 8,
                  ),
                  const Icon(PhosphorIcons.dots_three_vertical)
                ],
              ))),
    );
  }
}
