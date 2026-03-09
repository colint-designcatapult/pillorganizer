import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_esp_ble_prov/flutter_esp_ble_prov.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:developer' as developer;
import 'package:app/service/backend_provisioning_service.dart';
import 'package:app/service/amplify_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

part 'provision_provider.freezed.dart';
part 'provision_provider.g.dart';

enum ProvisionStage {
  scanning_ble,
  select_ble,
  fetchingSerial,
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
    String? claimId,
    String? claimToken,
    Duration? completionETA,
    String? wifiPassword,
    String? serialNumber,
  }) = _ProvisionState;
}

@riverpod
class Provision extends _$Provision {
  final _bleProv = FlutterEspBleProv();
  BackendProvisioningService? __backendService;
  
  BackendProvisioningService get _backendService => __backendService ??= BackendProvisioningService(
        AmplifyService(),
        Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ))..interceptors.add(LogInterceptor(
            requestBody: true,
            requestHeader: true,
            responseBody: true,
            responseHeader: true,
            logPrint: (obj) => debugPrint('DIO: $obj'),
          )),
      );

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
      stage: ProvisionStage.scanning_wifi, // Start with WiFi scan to establish session
      progress: 0.1,
      error: null,
    );

    try {
      // Step 1: Establish SECURITY_1 session by scanning WiFi networks first
      developer.log('Connecting to device $name to establish session...', name: 'ProvisionNotifier');
      print('DEBUG: Connecting to device $name to establish session...');

      final networks = await _bleProv.scanWifiNetworks(name, '');
      developer.log('Session established. Found ${networks.length} networks', name: 'ProvisionNotifier');
      print('DEBUG: WiFi scan completed and session established. Found ${networks.length} networks');

      // Step 2: Fetch hardware serial number from device
      state = state.copyWith(
        stage: ProvisionStage.fetchingSerial,
        progress: 0.4,
      );
      developer.log('Fetching serial number from hardware...', name: 'ProvisionNotifier');
      print('DEBUG: Fetching serial number from hardware...');

      final serialData = await _bleProv
          .sendCustomData(name, '', 'device_serial', Uint8List(0))
          .timeout(const Duration(seconds: 10));

      if (serialData == null || serialData.isEmpty) {
        print('\n' + '!' * 50);
        print('SERIAL NUMBER RETRIEVAL FAILED (NULL OR EMPTY)');
        print('!' * 50 + '\n');
        throw Exception('Failed to retrieve serial number from hardware');
      }

      // Parse JSON response: {"serialNumber": "ESP32-XXXXXXXXXXXX"}
      final rawString = String.fromCharCodes(serialData);
      String serial;
      try {
        final Map<String, dynamic> parsed = jsonDecode(rawString);
        serial = parsed['serialNumber'] as String;
      } catch (_) {
        serial = rawString.trim(); // fallback: treat as plain string
      }

      print('\n' + '*' * 50);
      print('SERIAL NUMBER RETRIEVED: $serial');
      print('*' * 50 + '\n');
      developer.log('Serial number retrieved: $serial', name: 'ProvisionNotifier');

      state = state.copyWith(serialNumber: serial, progress: 0.55);

      // Step 3: Claim device from backend using real hardware serial
      developer.log('Claiming device from backend for $serial...', name: 'ProvisionNotifier');
      print('DEBUG: Claiming device from backend for $serial...');

      final claimResult = await _backendService.claimDevice(serial);
      if (claimResult == null) {
        throw Exception('Failed to claim device from backend');
      }

      developer.log('Claim successful. DeviceID: ${claimResult.deviceId}', name: 'ProvisionNotifier');

      print('\n' + '=' * 60);
      print('🚀 DEVICE CLAIMED SUCCESSFULLY:');
      print('   DEVICE ID:   ${claimResult.deviceId}');
      print('   CLAIM ID:    ${claimResult.claimId}');
      print('   CLAIM TOKEN: ${claimResult.claimToken}');
      print('=' * 60 + '\n');

      state = state.copyWith(
        deviceID: claimResult.deviceId,
        claimId: claimResult.claimId,
        claimToken: claimResult.claimToken,
        progress: 0.75,
      );

      // Step 4: Send Claim ID and Token to device
      developer.log('Sending claim ID and token to device...', name: 'ProvisionNotifier');
      print('DEBUG: Sending claim ID and token to device...');

      final claimPayload = jsonEncode({
        "claimId": claimResult.claimId,
        "claimToken": claimResult.claimToken,
      });

      await _bleProv
          .sendCustomData(
            name, '', 'device_claim_token_set',
            Uint8List.fromList(utf8.encode(claimPayload)),
          )
          .timeout(const Duration(seconds: 10));

      developer.log('Claim token set on device successfully', name: 'ProvisionNotifier');

      print('\n' + '🛰️ ' * 20);
      print('SUCCESS: CLAIM ID & TOKEN SET ON HARDWARE');
      print('🛰️ ' * 20 + '\n');

      // Step 5: Move to WiFi selection
      state = state.copyWith(
        stage: ProvisionStage.select_wifi,
        wifiNetworks: networks.map((n) => WifiEntry(name: n)).toList(),
        progress: 1.0,
      );
    } catch (e, stack) {
      developer.log('Provisioning sequence failed: $e', name: 'ProvisionNotifier', error: e, stackTrace: stack);
      print('DEBUG: Provisioning sequence failed: $e');
      state = state.copyWith(stage: ProvisionStage.failed, error: 'Provisioning Error: ${e.toString()}');
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