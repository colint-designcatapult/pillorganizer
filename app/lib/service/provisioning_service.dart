import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProvisionningProgress {
  final int step;
  final int stage;

  ProvisionningProgress(
    this.step,
    this.stage,
  );

  String getTitle(BuildContext context) {
    switch (step) {
      case 1:
        return AppLocalizations.of(context)!.deviceSetup;
      case 2:
        return AppLocalizations.of(context)!.preferences;
      case 3:
        return AppLocalizations.of(context)!.createAnAccount;
      default:
        return '';
    }
  }

  List<String> getIconList() {
    if (step == 1) {
      return [
        'lib/assets/SVG/Bluetooth.svg',
        'lib/assets/SVG/WifiHigh.svg',
        'lib/assets/SVG/PlugsConnected.svg'
      ];
    } else {
      return [
        'lib/assets/SVG/Timer.svg',
        'lib/assets/SVG/BellSimpleRinging.svg',
        'lib/assets/SVG/Pill.svg'
      ];
    }
  }
}
