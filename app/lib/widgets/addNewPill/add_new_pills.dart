import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddNewPills extends StatelessWidget {
  final Function() onAddMedicationClick;
  const AddNewPills({super.key, required this.onAddMedicationClick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text(
            AppLocalizations.of(context)!.addMedications,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: const Color(0xFF03012C)),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.addMedicationsSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: const Color(0xFF03012C)),
          ),
          const SizedBox(height: 44),
          GestureDetector(
              onTap: onAddMedicationClick,
              child: Container(
                padding: const EdgeInsets.all(10),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAddMedicationClick,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF206B8B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 18),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.addPillManually,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: const Color(0xFFFFFFFF)),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
