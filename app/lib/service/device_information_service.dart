import 'package:app/api/device.dart';
import 'package:app/provider/ble_provider.dart';
import 'package:app/provider/device_notice_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:provider/provider.dart';

String wirelessText(BuildContext context, DeviceBluetoothProvider bleProv) {
  if (Provider.of<DeviceNoticeProvider>(context, listen: false).value ==
          DeviceNotice.disconnected ||
      bleProv.status == BLEConnectionStatus.connected) {
    return AppLocalizations.of(context)!.wirelessDisconnected;
  } else {
    return AppLocalizations.of(context)!.wirelessConnected;
  }
}

String bluetoothText(BuildContext context, DeviceBluetoothProvider bleProv) {
  switch (bleProv.status) {
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
    return PhosphorIcons.battery_charging;
  } else if (level == 0) {
    return PhosphorIcons.battery_empty;
  } else if (level <= 20) {
    return PhosphorIcons.battery_low;
  } else if (level <= 50) {
    return PhosphorIcons.battery_medium;
  } else if (level <= 80) {
    return PhosphorIcons.battery_high;
  }

  return PhosphorIcons.battery_full;
}

bool wifiIsConnected(BuildContext context, DeviceBluetoothProvider bleProv) {
  return Provider.of<DeviceNoticeProvider>(context, listen: false).value !=
          DeviceNotice.disconnected &&
      bleProv.status != BLEConnectionStatus.connected;
}
