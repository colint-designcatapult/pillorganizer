import 'package:app/api/device.dart';
import 'package:app/provider/ble_provider.dart';
import 'package:app/provider/device_notice_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

String wirelessText(BuildContext context, BLEConnectionStatus bleStatus) {
  if (Provider.of<DeviceNoticeProvider>(context, listen: false).value ==
          DeviceNotice.disconnected ||
      bleStatus == BLEConnectionStatus.connected) {
    return AppLocalizations.of(context)!.wirelessDisconnected;
  } else {
    return AppLocalizations.of(context)!.wirelessConnected;
  }
}

String bluetoothText(BuildContext context, BLEConnectionStatus bleStatus) {
  switch (bleStatus) {
    case BLEConnectionStatus.connected:
      return AppLocalizations.of(context)!.bluetoothConnected;
    case BLEConnectionStatus.connecting:
      return AppLocalizations.of(context)!.bluetoothConnecting;
    case BLEConnectionStatus.missingPermission:
      return AppLocalizations.of(context)!.bluetoothMissingPermissions;
    case BLEConnectionStatus.disconnected:
    case BLEConnectionStatus.suppressed:
      return AppLocalizations.of(context)!.bluetoothDisconnected;
  }
}

IconData batteryIcon(int level, bool? charging) {
  if (charging == true) {
    return PhosphorIconsRegular.batteryCharging;
  } else if (level == 0) {
    return PhosphorIconsRegular.batteryEmpty;
  } else if (level <= 20) {
    return PhosphorIconsRegular.batteryLow;
  } else if (level <= 50) {
    return PhosphorIconsRegular.batteryMedium;
  } else if (level <= 80) {
    return PhosphorIconsRegular.batteryHigh;
  }

  return PhosphorIconsRegular.batteryFull;
}

bool wifiIsConnected(BuildContext context, BLEConnectionStatus bleStatus) {
  return Provider.of<DeviceNoticeProvider>(context, listen: false).value !=
          DeviceNotice.disconnected &&
      bleStatus != BLEConnectionStatus.connected;
}
