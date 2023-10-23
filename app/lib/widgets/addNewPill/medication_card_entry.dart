import 'package:app/api/schedule.dart';
import 'package:app/provider/new_medication_provider.dart';
import 'package:app/provider/schedule_provider.dart';
import 'package:app/widgets/medication_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class MedicationCardEntry extends StatefulWidget {
  const MedicationCardEntry({super.key});

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
          height: 56,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SvgPicture.asset(imageUrl, width: 30, height: 30),
            const SizedBox(width: 12),
            Text(time.time.format(context),
                style: Theme.of(context).textTheme.titleSmall)
          ])),
      selected: selected,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: selected
          ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
          : const BorderSide(color: Color(0xFFF1F2F6), width: 2),
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
        const SizedBox(
          width: 26,
        ),
      if (sched.pm != null)
        Expanded(
            child: _buildDose(context, sched.pm!, checked, provider,
                'lib/assets/SVG/moon.svg')),
      if (sched.am == null && sched.pm == null)
        const Text('Please set medication times in device settings')
    ];
  }

  static const navFooterHeight = 72.0;
  @override
  Widget build(BuildContext context) {
    return Consumer<NewMedicationProvider>(builder: (context, provider, child) {
      final isEditing =
          provider.state.name != null && provider.state.name!.isNotEmpty;
      return SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Text(
                isEditing ? "Edit medication" : "New Medication",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: const Color(0xFF03012C)),
              ),
            ),
            const SizedBox(height: 8),
            if (!isEditing)
              Text(
                'Enter the new medication details for easy recognition and management.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: const Color(0xFF03012C)),
              ),
            const SizedBox(height: 36),
            Text(
              "Name",
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(fontSize: 28, color: const Color(0xFF03012C)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: provider.state.name,
              inputFormatters: [
                LengthLimitingTextInputFormatter(32),
              ],
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF1F3F6),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFBFD2DB), width: 2),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (val) {
                provider.updateName(val);
              },
            ),
            const SizedBox(height: 36),
            Column(
              children: [
                MedicationColorSelector(
                    selected: provider.state.color,
                    onChange: (color) {
                      provider.updateColor(color);
                    }),
                const SizedBox(height: 36),
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
            const SizedBox(height: 36),
            Text(
              "Time",
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(fontSize: 28, color: const Color(0xFF03012C)),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: navFooterHeight + 24),
          ],
        ),
      ));
    });
  }
}
