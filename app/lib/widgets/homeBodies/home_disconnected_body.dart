import 'package:app/provider/selected_device_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget disconnectedDeviceScreen(
    BuildContext context, SelectedDeviceProvider selectedDevice) {
  return ClipRRect(
      borderRadius: BorderRadius.only(topRight: const Radius.circular(40.0).r),
      child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: const Radius.circular(40.0).r,
            ),
          ),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.homeDisconnectedTitle,
                        style: Theme.of(context).textTheme.labelLarge),
                    Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: Text(
                            AppLocalizations.of(context)!
                                .homeDisconnectedSubtext,
                            style: Theme.of(context).textTheme.bodyMedium)),
                  ]))));
}
