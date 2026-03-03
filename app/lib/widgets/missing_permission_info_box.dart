import 'dart:io';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MissingPermissionInfoBox extends StatefulWidget {
  const MissingPermissionInfoBox({super.key});

  @override
  State<StatefulWidget> createState() => _MissingPermissionInfoBoxState();
}

class _MissingPermissionInfoBoxState extends State<MissingPermissionInfoBox> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 300.h,
        child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(children: [
              /*Expanded(
                  child: Text.rich(
                //shrinkWrap: true,
                text: Platform.isIOS
                    ? AppLocalizations.of(context)!.missingPermissionInfoTextIos
                    : AppLocalizations.of(context)!
                        .missingPermissionInfoTextAndroid,
              )),*/
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    // todo: prompt settings
                    //AppSettings.openAppSettings();
                  },
                  child: Text(AppLocalizations.of(context)!.openSettings,
                      style: Theme.of(context).textTheme.displaySmall),
                ),
              ),
            ])));
  }
}
