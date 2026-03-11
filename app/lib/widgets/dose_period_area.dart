import 'package:app/api/medication.dart';
import 'package:app/provider/new_medication_provider.dart';
import 'package:app/screens/modals/add_new_pills_modal.dart';
import 'package:app/widgets/circular_bin_status_indicator.dart';
import 'package:app/widgets/shimmer_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/service/time_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:timezone/standalone.dart' as tz;

import '../apiv2/models/device.dart';
import '../../provider/device_notice_provider.dart';
import '../../provider/device_state_provider.dart';
import '../../provider/medication_provider.dart';
import '../../provider/selected_device_provider.dart';
import '../../widgets/addNewPill/medication_card_entry.dart';
import '../../widgets/device_icon.dart';
import '../../widgets/medication_icon.dart';

const int DELAY_TIME = 10;

class DosePeriodArea extends ConsumerWidget {
  const DosePeriodArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dosePeriodsRaw = ref.watch(deviceStateProvider.select((s) => s.value?.dosePeriods));
    final activeDevice = ref.watch(activeDeviceProvider);
    final isOwner = activeDevice?.primaryUser ?? false;
    final deviceNotice = ref.watch(deviceNoticeProvider);

    final now = DateTime.now();

    List<DosePeriod>? dosePeriods = dosePeriodsRaw
        ?.where((element) {
          if (isOwner) {
            if (element.status == BinStatus.disabled ||
                element.scheduledTime == null) {
              return false;
            }
            return element.scheduledTime
                    ?.add(const Duration(minutes: DELAY_TIME))
                    .isAfter(now) ==
                true;
          } else {
            return element.scheduledTime != null &&
                element.medicationIDs.isNotEmpty;
          }
        })
        .toList()
        .reversed
        .toList();

    if (deviceNotice != DeviceNotice.empty &&
        (dosePeriods == null || dosePeriods.isEmpty)) {
      return SliverToBoxAdapter(
          child: Padding(
              padding: const EdgeInsets.only(top: 40).h,
              child: Center(child: _buildNotice(context))));
    } else {
      return SliverPadding(
        padding: EdgeInsets.only(bottom: 90.h),
        sliver: SliverList.builder(
          itemBuilder: (BuildContext context, int index) {
            return _buildPanel(context, ref, dosePeriods?[index]);
          },
          itemCount: dosePeriods?.length ?? 0,
        ),
      );
    }
  }

  Widget _buildPanel(BuildContext context, WidgetRef ref, DosePeriod? period) {
    void addNewPillUpdate() {
      ref.invalidate(medicationsProvider);
    }

    Color? color = Theme.of(context).indicatorColor;
    final medicationsAsync = ref.watch(medicationsProvider);
    // Helper to get medication by ID from the list
    ScheduledMedication? getMedByID(int id) {
      final list = medicationsAsync.value;
      if (list == null) return null;
      return list.firstWhereOrNull((m) => m.id == id);
    }

    final deviceNotice = ref.watch(deviceNoticeProvider);

    if (period != null && period.medicationIDs.isNotEmpty) {
      bool hasMissingMedications = false;
      for (int medID in period.medicationIDs) {
        if (getMedByID(medID) == null) {
          hasMissingMedications = true;
          break;
        }
      }

      if (hasMissingMedications && !medicationsAsync.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(medicationsProvider);
        });
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 28.0, bottom: 16.0).h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: EdgeInsets.fromLTRB(4.w, 0, 0, 20.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  BinIcon.forBin(bin: period!.binID, color: color),
                  Text(
                    _buildTimeString(context, ref, period),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              )),
          if (period.medicationIDs.isNotEmpty) ...[
            ...period.medicationIDs
                .map((e) => _buildMed(
                    context, ref, period, getMedByID(e), deviceNotice))
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
        borderRadius: BorderRadius.circular(4).r,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 6.w),
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
                    SizedBox(height: 8.h),
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

  Widget _buildMed(BuildContext context, WidgetRef ref, DosePeriod period, ScheduledMedication? med,
      DeviceNotice deviceNotice) {
    final activeDevice = ref.watch(activeDeviceProvider);
    final deviceID = activeDevice?.id ?? "";
    final bool isOwner = activeDevice?.primaryUser ?? false;

    void onComplete() {
      ref.invalidate(medicationsProvider);
    }

    if (med != null) {
      return GestureDetector(
        onTap: isOwner
            ? () {
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
              }
            : null,
        child: Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Container(
                height: 80.h,
                padding: EdgeInsets.fromLTRB(18.w, 0.h, 18.w, 0.h),
                decoration: BoxDecoration(
                    color: const Color(0xFFF1F6F5),
                    borderRadius: BorderRadius.circular(8.0).r,
                    border: Border.all(
                      color: const Color(0xFF206B8B),
                      width: 2.h,
                    )),
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
                                          .labelMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  Text(
                                      _buildSubtitle(
                                          context, ref, period, deviceNotice),
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall)
                                ]))),
                    SizedBox(
                      width: 4.w,
                    ),
                    CircularBinStatusIndicator(
                        status: period.status,
                        deviceStatus: deviceNotice),
                    if (isOwner) ...[
                      SizedBox(
                        width: 22.w,
                      ),
                      SvgPicture.asset(
                        'lib/assets/SVG/pencilLight.svg',
                        width: 24.w,
                        height: 24.h,
                      ),
                    ]
                  ],
                ))),
      );
    } else {
      return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: SizedBox(
            height: 80.h,
            child: Container(
                height: 80.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F6F5),
                  borderRadius: BorderRadius.circular(8.0).r,
                  border: Border.all(
                    color: const Color(0xFF206B8B),
                    width: 2.h,
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: ShimmerPlaceholder(
                  loading: true,
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade200,
                  builder: (BuildContext context, bool loading) {
                    return Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade400,
                          ),
                          height: 44.w,
                          width: 44.w,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 140.w,
                                height: 14.h,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Container(
                                width: 100.w,
                                height: 12.h,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade400,
                          ),
                          height: 24.w,
                          width: 24.w,
                        ),
                      ],
                    );
                  },
                )),
          ));
    }
  }

  String _buildSubtitle(
      BuildContext context, WidgetRef ref, DosePeriod period, DeviceNotice deviceNotice) {
    if (period.scheduledTime == null) {
      return "";
    }
    String format = _formatTimeInDeviceTimezone(context, ref, period.scheduledTime);

    if (period.status == BinStatus.disabled ||
        deviceNotice == DeviceNotice.empty) {
      return AppLocalizations.of(context)!.doseRefill;
    } else if (period.status == BinStatus.taken) {
      final takenTime = period.takenAtTime != null
          ? _formatTakenAtTime(context, period.takenAtTime)
          : format;
      return AppLocalizations.of(context)!.doseTakenAt(takenTime);
    } else if (period.status == BinStatus.takeNow) {
      return AppLocalizations.of(context)!.doseTakeNow;
    } else if (period.status == BinStatus.pending) {
      return AppLocalizations.of(context)!.doseTakeAt;
    } else if (period.status == BinStatus.missed) {
      return AppLocalizations.of(context)!.missedAt(format);
    } else {
      return '';
    }
  }

  String _formatTimeInDeviceTimezone(BuildContext context, WidgetRef ref, DateTime? dateTime) {
    if (dateTime == null) return "";

    final selectedDevice = ref.watch(activeDeviceProvider);
    final deviceTimezone = ref.watch(activeDeviceConfigProvider)?.timezone;
    final appLocale = AppLocalizations.of(context)!.localeName;

    if (deviceTimezone != null) {
      final loc = lookupTimeZoneLocation(deviceTimezone);
      if (loc != null) {
        final deviceTime = tz.TZDateTime.from(dateTime.toUtc(), loc);
        return DateFormat.jm(appLocale).format(deviceTime);
      }
      return DateFormat.jm(appLocale).format(dateTime);
    } else {
      return DateFormat.jm(appLocale).format(dateTime);
    }
  }

  String _formatTakenAtTime(BuildContext context, String? takenAtTimeString) {
    if (takenAtTimeString == null || takenAtTimeString.isEmpty) return "";

    try {
      final appLocale = AppLocalizations.of(context)!.localeName;
      final parts = takenAtTimeString.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final timeForFormatting = DateTime(2000, 1, 1, hour, minute);
        return DateFormat.jm(appLocale).format(timeForFormatting);
      }
    } catch (e) {
      print("Error parsing takenAtTime: $takenAtTimeString, error: $e");
    }

    return takenAtTimeString;
  }

  String _buildTimeString(BuildContext context, WidgetRef ref, DosePeriod period) {
    if (period.scheduledTime != null) {
      final formattedTime =
          _formatTimeInDeviceTimezone(context, ref, period.scheduledTime);
      return AppLocalizations.of(context)!.doseTodayAt(formattedTime);
    } else {
      return AppLocalizations.of(context)!.genericToday;
    }
  }
}
