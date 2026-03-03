import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ProvisionStage {
  scanning_ble,
  select_ble,
  scanning_wifi,
  select_wifi,
  provisioning_wifi,
  finalizing,
  complete,
  failed,
  missingPermissions
}

class WifiEntry {
  final String name;
  final int? rssi;
  WifiEntry(this.name, {this.rssi});
}

class ProvisionState {
  final ProvisionStage stage;
  final Object? error;
  final double? progress;
  final String? deviceName;
  final List<String>? bluetoothList;
  final List<WifiEntry>? wifiNetworks;
  final String? ssid;
  final String? deviceID;
  final Duration? completionETA;

  ProvisionState({
    this.stage = ProvisionStage.scanning_ble,
    this.error,
    this.progress,
    this.deviceName,
    this.bluetoothList,
    this.wifiNetworks,
    this.ssid,
    this.deviceID,
    this.completionETA,
  });

  ProvisionState copyWith({
    ProvisionStage? stage,
    Object? error,
    double? progress,
    String? deviceName,
    List<String>? bluetoothList,
    List<WifiEntry>? wifiNetworks,
    String? ssid,
    String? deviceID,
    Duration? completionETA,
  }) {
    return ProvisionState(
      stage: stage ?? this.stage,
      error: error,
      progress: progress ?? this.progress,
      deviceName: deviceName ?? this.deviceName,
      bluetoothList: bluetoothList ?? this.bluetoothList,
      wifiNetworks: wifiNetworks ?? this.wifiNetworks,
      ssid: ssid ?? this.ssid,
      deviceID: deviceID ?? this.deviceID,
      completionETA: completionETA ?? this.completionETA,
    );
  }
}

final provisionStateProvider = NotifierProvider<ProvisionNotifier, ProvisionState>(ProvisionNotifier.new);

class ProvisionNotifier extends Notifier<ProvisionState> {
  @override
  ProvisionState build() {
    return ProvisionState();
  }

  Future<void> scanBluetooth() async {
    state = state.copyWith(stage: ProvisionStage.scanning_ble, progress: 0.1);
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(
      stage: ProvisionStage.select_ble,
      bluetoothList: ['Mock Device 1', 'Mock Device 2'],
      progress: 1.0,
    );
  }

  Future<void> rescanBluetooth() => scanBluetooth();

  Future<ProvisionState> selectBluetooth(String name) async {
    state = state.copyWith(deviceName: name, stage: ProvisionStage.scanning_wifi);
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(
      stage: ProvisionStage.select_wifi,
      wifiNetworks: [WifiEntry('Mock WiFi 1', rssi: -50), WifiEntry('Mock WiFi 2', rssi: -80)],
    );
    return state;
  }

  Future<void> rescanNetworks() async {
    state = state.copyWith(wifiNetworks: null);
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(
      wifiNetworks: [WifiEntry('Mock WiFi 1', rssi: -50), WifiEntry('Mock WiFi 2', rssi: -80)],
    );
  }

  Future<ProvisionState> setWifiPassword(BuildContext context, String ssid, String password) async {
    state = state.copyWith(ssid: ssid, stage: ProvisionStage.finalizing, progress: 0.0);
    return state;
  }

  Future<ProvisionState> finalize(BuildContext context) async {
    for (int i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(progress: i / 5, completionETA: Duration(minutes: 5 - i));
    }
    state = state.copyWith(stage: ProvisionStage.complete, deviceID: 'mock-device-id');
    return state;
  }
}