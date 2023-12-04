import 'package:app/api/schedule.dart';
import 'package:app/provider/new_medication_provider.dart';
import 'package:app/provider/schedule_provider.dart';
import 'package:app/widgets/medication_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MedicationCardEntry extends StatefulWidget {
  const MedicationCardEntry({
    super.key,
  });

  @override
  _MedicationCardEntryState createState() => _MedicationCardEntryState();
}

class _MedicationCardEntryState extends State<MedicationCardEntry> {
  Widget _buildDose(context, DispenseTime time, Set<int>? checked,
      NewMedicationProvider provider, String imageUrl) {
    bool selected = checked?.contains(time.id) ?? false;
    return RawChip(
      selectedColor: const Color(0xFFF1F2F6),
      backgroundColor: const Color(0xFFF1F2F6),
      showCheckmark: false,
      label: SizedBox(
          height: 56.h,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SvgPicture.asset(imageUrl, width: 30.w, height: 30.h),
            SizedBox(width: 12.w),
            Text(time.time.format(context),
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
        provider.toggleDispenseTime(time.id!);
      },
    );
  }

  List<Widget> _buildForSchedule(context, SimpleSchedule sched,
      Set<int>? checked, NewMedicationProvider provider) {
    return [
      if (sched.am != null)
        Expanded(
            child: _buildDose(context, sched.am!, checked, provider,
                'lib/assets/SVG/sun.svg')),
      if (sched.pm != null && sched.pm != null)
        SizedBox(
          width: 26.w,
        ),
      if (sched.pm != null)
        Expanded(
            child: _buildDose(context, sched.pm!, checked, provider,
                'lib/assets/SVG/moon.svg')),
      if (sched.am == null && sched.pm == null)
        Text(AppLocalizations.of(context)!.setMedicationTime),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NewMedicationProvider>(builder: (context, provider, child) {
      final isEditing = provider.state.existing != null;
      return SingleChildScrollView(
          child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 32.w),
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
                initialValue: provider.state.name,
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
                  provider.updateName(val);
                },
                onFieldSubmitted: (val) {
                  provider.updateName(val);
                }),
            SizedBox(height: 36.h),
            Column(
              children: [
                MedicationColorSelector(
                    selected: provider.state.color,
                    onChange: (color) {
                      provider.updateColor(color);
                    }),
                SizedBox(height: 36.h),
                PillShapeSelector(
                  key: ValueKey(provider.state.shape),
                  color: provider.state.color,
                  selected: provider.state.shape,
                  onChange: (shape) {
                    provider.updateShape(shape);
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
            Provider(
              create: (BuildContext context) {
                return ScheduleProvider(deviceID: provider.state.deviceID);
              },
              child: FutureBuilder<SimpleSchedule?>(
                  future: Provider.of<ScheduleProvider>(context).future,
                  builder: (context, snapshot) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!snapshot.hasData) ...[
                          const CircularProgressIndicator()
                        ] else ...[
                          ..._buildForSchedule(context, snapshot.requireData!,
                              provider.state.assignedDispenseTimes, provider)
                        ]
                      ],
                    );
                  }),
            ),
            SizedBox(height: 96.h),
          ],
        ),
      ));
    });
  }
}
