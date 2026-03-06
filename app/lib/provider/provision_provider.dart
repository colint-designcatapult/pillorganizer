import 'package:flutter_esp_ble_prov/flutter_esp_ble_prov.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:developer' as developer;

part 'provision_provider.freezed.dart';
part 'provision_provider.g.dart';

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

@freezed
abstract class WifiEntry with _$WifiEntry {
  const factory WifiEntry({
    required String name,
    int? rssi,
  }) = _WifiEntry;
}

@freezed
abstract class ProvisionState with _$ProvisionState {
  const factory ProvisionState({
    @Default(ProvisionStage.scanning_ble) ProvisionStage stage,
    Object? error,
    @Default(0.0) double progress,
    String? deviceName,
    @Default([]) List<String> bluetoothList,
    @Default([]) List<WifiEntry> wifiNetworks,
    String? ssid,
    String? deviceID,
    Duration? completionETA,
    String? wifiPassword,
  }) = _ProvisionState;
}

@riverpod
class Provision extends _$Provision {
  final _bleProv = FlutterEspBleProv();

  @override
  ProvisionState build() {
    return const ProvisionState();
  }

  Future<void> scanBluetooth({String prefix = 'PILL-'}) async {
    state = state.copyWith(
      stage: ProvisionStage.scanning_ble,
      progress: 0.1,
      error: null,
    );
    developer.log('Starting BLE scan with prefix: $prefix', name: 'ProvisionNotifier');
    print('DEBUG: Starting BLE scan with prefix: $prefix');
    try {
      final devices = await _bleProv.scanBleDevices(prefix);
      developer.log('BLE scan completed. Found ${devices.length} devices: $devices', name: 'ProvisionNotifier');
      print('DEBUG: BLE scan completed. Found ${devices.length} devices: $devices');
      state = state.copyWith(
        stage: ProvisionStage.select_ble,
        bluetoothList: devices,
        progress: 1.0,
      );
    } catch (e, stack) {
      developer.log('BLE scan failed: $e', name: 'ProvisionNotifier', error: e, stackTrace: stack);
      print('DEBUG: BLE scan failed: $e');
      state = state.copyWith(stage: ProvisionStage.failed, error: 'BLE Scan Error: ${e.toString()}');
    }
  }

  Future<void> rescanBluetooth() => scanBluetooth();

  Future<void> selectBluetooth(String name) async {
    state = state.copyWith(
      deviceName: name,
      stage: ProvisionStage.scanning_wifi,
      progress: 0.0,
      error: null,
    );
    developer.log('Connecting to device $name to scan WiFi networks...', name: 'ProvisionNotifier');
    print('DEBUG: Connecting to device $name for WiFi scan...');
    try {
      final networks = await _bleProv.scanWifiNetworks(name, '');
      developer.log('WiFi scan completed. Found ${networks.length} networks: $networks', name: 'ProvisionNotifier');
      print('DEBUG: WiFi scan completed. Found ${networks.length} networks: $networks');
      state = state.copyWith(
        stage: ProvisionStage.select_wifi,
        wifiNetworks: networks.map((n) => WifiEntry(name: n)).toList(),
        progress: 1.0,
      );
    } catch (e, stack) {
      developer.log('WiFi scan failed: $e', name: 'ProvisionNotifier', error: e, stackTrace: stack);
      print('DEBUG: WiFi scan failed: $e');
      state = state.copyWith(stage: ProvisionStage.failed, error: 'WiFi Scan Error: ${e.toString()}');
    }
  }


  void setWifiCredentials(String ssid, String password) {
    state = state.copyWith(ssid: ssid, wifiPassword: password);
  }

  Future<void> rescanNetworks() async {
    if (state.deviceName == null) return;
    state = state.copyWith(wifiNetworks: [], progress: 0.0);
    await selectBluetooth(state.deviceName!);
  }

  Future<void> provisionWifi({
    required String ssid,
    required String password,
  }) async {
    if (state.deviceName == null) return;

    state = state.copyWith(
      ssid: ssid,
      stage: ProvisionStage.provisioning_wifi,
      progress: 0.0,
      error: null,
    );

    developer.log('Initiating Wi-Fi provisioning for ${state.deviceName} with SSID: $ssid', name: 'ProvisionNotifier');
    print('DEBUG: Initiating Wi-Fi provisioning for ${state.deviceName} with SSID: $ssid');
    try {
      final success = await _bleProv.provisionWifi(
        state.deviceName!,
        '',
        ssid,
        password,
      );
      developer.log('Provisioning result: $success', name: 'ProvisionNotifier');
      print('DEBUG: Provisioning result: $success');

      if (success == true) {
        state = state.copyWith(
          stage: ProvisionStage.complete,
          progress: 1.0,
          deviceID: 'ESP-${state.deviceName}', // Example ID format
        );
      } else {
        state = state.copyWith(
          stage: ProvisionStage.failed,
          error: 'Provisioning returned false',
        );
      }
    } catch (e, stack) {
      developer.log('Provisioning error: $e', name: 'ProvisionNotifier', error: e, stackTrace: stack);
      print('DEBUG: Provisioning error: $e');
      state = state.copyWith(stage: ProvisionStage.failed, error: 'Provisioning Error: ${e.toString()}');
    }
  }
}