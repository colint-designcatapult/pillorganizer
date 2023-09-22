import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'provision.freezed.dart';

enum ProvisionStage {
  scanning_ble,
  scanning_wifi,
  select_wifi,
  provisioning_wifi,
  finalizing,
  complete,
  failed
}

@freezed
class ProvisionState with _$ProvisionState {
  const factory ProvisionState(
      {@Default(ProvisionStage.scanning_ble) ProvisionStage stage,
      double? progress,
      Future<ProvisionState>? future,
      Object? error,
      String? deviceName,
      List<WifiEntry>? wifiNetworks,
      String? ssid,
      String? wifiPassword,
      String? serialNo,
      int? provisionID,
      int? deviceID,
      Duration? completionETA}) = _ProvisionState;
}

class WifiEntry {
  final String name;
  final int? rssi;
  final int? security;

  WifiEntry({required this.name, this.rssi, this.security});

  factory WifiEntry.fromMap(Map<String, String> map) {
    return WifiEntry(
      name: map["name"]!,
      rssi: map.containsKey("rssi") ? int.parse(map["rssi"]!) : null,
      security:
          map.containsKey("security") ? int.parse(map["security"]!) : null,
    );
  }
}
