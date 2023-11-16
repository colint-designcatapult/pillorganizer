import 'package:app/api/medication.dart';
import 'package:app/provider/new_medication_provider.dart';
import 'package:app/screens/modals/add_new_pills_modal.dart';
import 'package:app/widgets/circular_bin_status_indicator.dart';
import 'package:app/widgets/shimmer_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../api/device.dart';

import '../../provider/device_notice_provider.dart';
import '../../provider/medication_provider.dart';
import '../../provider/selected_device_provider.dart';

import '../../widgets/addNewPill/medication_card_entry.dart';
import '../../widgets/device_icon.dart';
import '../../widgets/medication_icon.dart';

class DosePeriodArea extends StatelessWidget {
  const DosePeriodArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<DeviceStateProvider, List<DosePeriod>?>(
      selector: (_, prov) => prov.value?.dosePeriods,
      builder: (_, list, __) {
        List<DosePeriod>? reversedList = list
            ?.where((element) => element.status != BinStatus.DISABLED)
            .toList()
            .reversed
            .toList();
        if (Provider.of<DeviceNoticeProvider>(context, listen: false).value !=
                DeviceNotice.empty &&
            (reversedList == null || reversedList.isEmpty)) {
          return SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(child: _buildNotice(context))));
        } else {
          return SliverList.builder(
            itemBuilder: (BuildContext context, int index) {
              return _buildPanel(context, reversedList?[index]);
            },
            itemCount: reversedList?.length ?? 0,
          );
        }
      },
    );
  }

  Widget _buildPanel(context, DosePeriod? period) {
    void addNewPillUpdate() {
      Provider.of<MedicationsProvider>(context, listen: false).refresh();
    }

    Color? color = Theme.of(context).indicatorColor;
    var medProv = Provider.of<MedicationsProvider>(context);
    var deviceNoticeProv = Provider.of<DeviceNoticeProvider>(context);
    return Padding(
      padding: const EdgeInsets.only(top: 28.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 0, 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  BinIcon.forBin(bin: period!.binID, color: color),
                  Text(
                    _buildTimeString(context, period),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              )),
          if (period.medicationIDs.isNotEmpty) ...[
            ...period.medicationIDs
                .map((e) => _buildMed(
                    context, period, medProv.byID(e), deviceNoticeProv))
                .toList(growable: false),
          ] else ...[
            IndexNewPills(onAdd: () => addNewPillUpdate())
          ],
        ],
      ),
    );
  }

  Widget _buildNotice(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.homeNoMedTodayTitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.black,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.homeNoMedTodaySubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMed(context, DosePeriod period, ScheduledMedication? med,
      DeviceNoticeProvider deviceNoticeProv) {
    final deviceID = Provider.of<SelectedDeviceProvider>(context, listen: false)
        .device!
        .deviceID;

    void onComplete() {
      Provider.of<MedicationsProvider>(context, listen: false).refresh();
    }

    if (med != null) {
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
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
                height: 80,
                padding: const EdgeInsets.fromLTRB(18, 12, 12, 18),
                decoration: BoxDecoration(
                    color: const Color(0xFFF1F6F5),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: const Color(0xFF206B8B),
                      width: 2.0,
                    )),
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
                                          .labelMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  Text(
                                      _buildSubtitle(
                                          context, period, deviceNoticeProv),
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall)
                                ]))),
                    const SizedBox(
                      width: 4,
                    ),
                    CircularBinStatusIndicator(
                        status: period.status,
                        deviceStatus: deviceNoticeProv.value),
                    const SizedBox(width: 2),
                    const Icon(PhosphorIcons.dots_three_vertical)
                  ],
                ))),
      );
    } else {
      return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            height: 80,
            child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F6F5),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: const Color(0xFF206B8B),
                    width: 2.0,
                  ),
                ),
                alignment: Alignment.center,
                child: ShimmerPlaceholder(
                  loading: true,
                  builder: (BuildContext context, bool loading) {
                    return ListTile(
                      leading: Container(
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.white),
                        height: 44.0,
                        width: 44.0,
                      ),
                      title:
                          Container(width: 70, height: 40, color: Colors.white),
                      trailing: Container(
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.white),
                        height: 20,
                        width: 20,
                      ),
                    );
                  },
                )),
          ));
    }
  }

  String _buildSubtitle(
      context, DosePeriod period, DeviceNoticeProvider deviceNoticeProv) {
    final fm = DateFormat.jm();
    if (period.scheduledTime == null) {
      return "";
    }
    String format = fm.format(period.scheduledTime!);
    if (period.status == BinStatus.DISABLED ||
        deviceNoticeProv.value == DeviceNotice.empty) {
      return AppLocalizations.of(context)!.doseRefill;
    } else if (period.status == BinStatus.TAKEN) {
      return AppLocalizations.of(context)!.doseTakenAt(format);
    } else if (period.status == BinStatus.TAKE_NOW) {
      return AppLocalizations.of(context)!.doseTakeNow;
    } else if (period.status == BinStatus.PENDING) {
      return AppLocalizations.of(context)!.doseTakeAt;
    } else if (period.status == BinStatus.MISSED) {
      return AppLocalizations.of(context)!.missedAt(format);
    } else {
      return '';
    }
  }

  String _buildTimeString(context, DosePeriod period) {
    final fm = DateFormat.jm();
    if (period.scheduledTime != null) {
      return AppLocalizations.of(context)!
          .doseTodayAt(fm.format(period.scheduledTime!));
    } else {
      return AppLocalizations.of(context)!.genericToday;
    }
  }
}
