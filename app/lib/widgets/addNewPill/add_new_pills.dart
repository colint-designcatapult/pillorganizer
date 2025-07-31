import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddNewPills extends StatelessWidget {
  final Function() onAddMedicationClick;
  const AddNewPills({super.key, required this.onAddMedicationClick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppLocalizations.of(context)!.addMedications,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: const Color(0xFF03012C)),
          ),
          SizedBox(height: 16.h),
          Text(
            AppLocalizations.of(context)!.addMedicationsSubtitle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: const Color(0xFF03012C)),
          ),
          SizedBox(height: 44.h),
          GestureDetector(
              onTap: onAddMedicationClick,
              child: Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAddMedicationClick,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF206B8B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8).r,
                    ),
                    padding:
                        EdgeInsets.symmetric(vertical: 20.h, horizontal: 18.w),
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
