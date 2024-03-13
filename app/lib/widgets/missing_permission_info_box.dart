import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MissingPermissionInfoBox extends StatefulWidget {
  const MissingPermissionInfoBox({super.key});

  @override
  State<StatefulWidget> createState() => _MissingPermissionInfoBoxState();
}

class _MissingPermissionInfoBoxState extends State<MissingPermissionInfoBox> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 225,
        child: Column(children: [
          Expanded(
              child: MarkdownBody(
            shrinkWrap: true,
            data: Platform.isIOS
                ? AppLocalizations.of(context)!.missingPermissionInfoTextIos
                : AppLocalizations.of(context)!
                    .missingPermissionInfoTextAndroid,
          )),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                AppSettings.openAppSettings();
              },
              child: Text(AppLocalizations.of(context)!.openSettings,
                  style: Theme.of(context).textTheme.displaySmall),
            ),
          ),
        ]));
  }
}
