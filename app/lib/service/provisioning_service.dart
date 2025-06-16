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
        return AppLocalizations.of(context)!.nameDevice;
      case 3:
        return AppLocalizations.of(context)!.preferences;
      case 4:
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
    } else if (step == 2) {
      return ['lib/assets/SVG/pencilLight.svg'];
    } else {
      return [
        'lib/assets/SVG/Timer.svg',
        'lib/assets/SVG/BellSimpleRinging.svg',
        'lib/assets/SVG/Pill.svg'
      ];
    }
  }
}

class ProvisionError {
  static const String errorServerUrl = "errorServerUrl";
  static const String errorOobKey = "errorOobKey";
  static const String errorSerialNumber = "errorSerialNumber";
  static const String errorDeviceOffline = "errorDeviceOffline";
  static const String errorContextGone = "errorContextGone";
  static const String errorPasswordIncorrect = "errorPasswordIncorrect";
  static const String errorNoDevicesFound = "errorNoDevicesFound";
}

String provErrorMessage(BuildContext context, String provError) {
  switch (provError) {
    case ProvisionError.errorServerUrl:
      return AppLocalizations.of(context)!.provErrorServerUrl;
    case ProvisionError.errorOobKey:
      return AppLocalizations.of(context)!.provErrorOobKey;
    case ProvisionError.errorSerialNumber:
      return AppLocalizations.of(context)!.provErrorSerialNumber;
    case ProvisionError.errorDeviceOffline:
      return AppLocalizations.of(context)!.provErrorDeviceOffline;
    case ProvisionError.errorContextGone:
      return AppLocalizations.of(context)!.provErrorContextGone;
    case ProvisionError.errorPasswordIncorrect:
      return AppLocalizations.of(context)!.provErrorPasswordIncorrect;
    case ProvisionError.errorNoDevicesFound:
      return AppLocalizations.of(context)!.provErrorNoDevicesFound;
    default:
      return AppLocalizations.of(context)!.genericError;
  }
}
