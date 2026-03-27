import 'package:app/apiv2/models/schedule.dart';
import 'package:app/main.dart';
import 'package:app/provider/new_medication_provider.dart';
import 'package:app/provider/schedule_provider.dart';
import 'package:app/widgets/medication_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MedicationCardEntry extends ConsumerStatefulWidget {
  const MedicationCardEntry({
    super.key,
  });

  @override
  ConsumerState<MedicationCardEntry> createState() => _MedicationCardEntryState();
}

class _MedicationCardEntryState extends ConsumerState<MedicationCardEntry> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(newMedicationProvider);
      ref.read(scheduleProvider.notifier).load(state.deviceID);
    });
  }

  Widget _buildDose(BuildContext context, WidgetRef ref, DayPeriod dayPeriod,
      DosePeriodV2 entry, Set<int>? checked, String imageUrl) {
    // Use DayPeriod.index (0=am, 1=pm) as synthetic toggle ID
    final syntheticId = dayPeriod.index;
    final selected = checked?.contains(syntheticId) ?? false;
    final notifier = ref.read(newMedicationProvider.notifier);

    return RawChip(
      selectedColor: const Color(0xFFF1F2F6),
      backgroundColor: const Color(0xFFF1F2F6),
      showCheckmark: false,
      label: SizedBox(
          height: 56.h,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SvgPicture.asset(imageUrl, width: 30.w, height: 30.h),
            SizedBox(width: 12.w),
            Text(entry.time.format(context),
                style: Theme.of(context).textTheme.titleSmall)
          ])),
      selected: selected,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8).r,
      ),
      side: selected
          ? BorderSide(color: Theme.of(context).primaryColor, width: 2.w)
          : BorderSide(color: const Color(0xFFF1F2F6), width: 2.w),
      onPressed: () {
        notifier.toggleDispenseTime(syntheticId);
      },
    );
  }

  Widget _buildForSchedule(BuildContext context, WidgetRef ref,
      SimpleSchedule? sched, Set<int>? checked) {
    final am = sched?.amPeriod;
    final pm = sched?.pmPeriod;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (am != null)
              Expanded(
                  child: _buildDose(context, ref, DayPeriod.am, am, checked,
                      'lib/assets/SVG/sun.svg')),
            if (am != null && pm != null)
              SizedBox(
                width: 26.w,
              ),
            if (pm != null)
              Expanded(
                  child: _buildDose(context, ref, DayPeriod.pm, pm, checked,
                      'lib/assets/SVG/moon.svg')),
          ],
        ),
        if (am == null && pm == null) ...[
          SizedBox(height: 12.h),
          Text(
            AppLocalizations.of(context)!.setMedicationTime,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF03012C),
                ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicationState = ref.watch(newMedicationProvider);
    final medicationNotifier = ref.read(newMedicationProvider.notifier);
    final scheduleState = ref.watch(scheduleProvider);

    final isEditing = medicationState.existing != null;

    return SingleChildScrollView(
        child: Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 32.w),
      child: KeyboardDismissWrapper(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Text(
              isEditing
                  ? AppLocalizations.of(context)!.editMedication
                  : AppLocalizations.of(context)!.newMedication,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: const Color(0xFF03012C)),
            ),
          ),
          SizedBox(height: 8.h),
          if (!isEditing)
            Text(
              AppLocalizations.of(context)!.newMedicationSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: const Color(0xFF03012C)),
            ),
          SizedBox(height: 36.h),
          Text(
            AppLocalizations.of(context)!.name,
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(fontSize: 28.h, color: const Color(0xFF03012C)),
          ),
          SizedBox(height: 8.h),
          TextFormField(
              initialValue: medicationState.name,
              inputFormatters: [
                LengthLimitingTextInputFormatter(32),
              ],
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF1F3F6),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: const Color(0xFFBFD2DB), width: 2.w),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
              onChanged: (val) {
                medicationNotifier.updateName(val);
              },
              onFieldSubmitted: (val) {
                medicationNotifier.updateName(val);
              }),
          SizedBox(height: 36.h),
          Column(
            children: [
              MedicationColorSelector(
                  selected: medicationState.color,
                  onChange: (color) {
                    medicationNotifier.updateColor(color);
                  }),
              SizedBox(height: 36.h),
              PillShapeSelector(
                key: ValueKey(medicationState.shape),
                color: medicationState.color,
                selected: medicationState.shape,
                onChange: (shape) {
                  medicationNotifier.updateShape(shape);
                },
              )
            ],
          ),
          SizedBox(height: 36.h),
          Text(
            AppLocalizations.of(context)!.time,
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(fontSize: 28.h, color: const Color(0xFF03012C)),
          ),
          SizedBox(height: 12.h),
          Builder(
            builder: (context) {
              return scheduleState.when(
                data: (state) {
                  final effective = state.effectiveSchedule;
                  final simpleSchedule =
                      effective is SimpleSchedule ? effective : null;
                  return _buildForSchedule(context, ref, simpleSchedule,
                      medicationState.assignedDispenseTimes);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text(err.toString())),
              );
            },
          ),
          SizedBox(height: 96.h),
        ],
      )),
    ));
  }
}
