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

      // Step 2: Claim device from backend (only thing the app does)
      // NOTE: Using dummy serial for now — will use real hardware serial later
      const dummySerial = "ESP32-SIMULATION-001";
      
      state = state.copyWith(
        stage: ProvisionStage.fetchingSerial,
        progress: 0.5,
      );
      developer.log('Claiming device from backend for $dummySerial...', name: 'ProvisionNotifier');
      print('DEBUG: Claiming device from backend for $dummySerial...');

      final claimResult = await _backendService.claimDevice(dummySerial);
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
      );

      // Step 3: Send Claim ID and Token to device
      developer.log('Sending claim ID and token to device...', name: 'ProvisionNotifier');
      print('DEBUG: Sending claim ID and token to device...');

      final claimPayload = jsonEncode({
        "claimId": claimResult.claimId,
        "claimToken": claimResult.claimToken,
      });

      await _bleProv
          .sendCustomData(
            name,
            '',
            'device_claim_token_set',
            Uint8List.fromList(utf8.encode(claimPayload)),
          )
          .timeout(const Duration(seconds: 10));

      developer.log('Claim token set successfully', name: 'ProvisionNotifier');
      
      print('\n' + '🛰️ ' * 20);
      print('SUCCESS: CLAIM ID & TOKEN SET ON HARDWARE');
      print('🛰️ ' * 20 + '\n');

      /* 
      // Step 4: Fetch serial number from device (still doing this to maintain parity with firmware)
      developer.log('Fetching official serial number from hardware...', name: 'ProvisionNotifier');

      final serialData = await _bleProv
          .sendCustomData(
            name,
            '',
            'device_serial',
            Uint8List(0),
          )
          .timeout(const Duration(seconds: 10));

      String? serial;
      if (serialData != null && serialData.isNotEmpty) {
        // Log raw bytes for debugging
        print('DEBUG: Raw serial bytes: ${serialData.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(", ")}');

        // Check if it's a JSON/String or raw bytes
        if (serialData.length == 6) {
          serial = serialData.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
        } else {
          serial = String.fromCharCodes(serialData);
        }

        print('\n' + '*' * 50);
        print('SERIAL NUMBER RETRIEVED: $serial');
        print('*' * 50 + '\n');

        developer.log('Serial number retrieved: $serial', name: 'ProvisionNotifier');

        // Step 5: Send acknowledgement - tells device we got the serial
        developer.log('Sending acknowledgement to device...', name: 'ProvisionNotifier');
        print('DEBUG: Sending acknowledgement to device...');

        await _bleProv
            .sendCustomData(
              name,
              '',
              'device_serial_ack',
              Uint8List(0),
            )
            .timeout(const Duration(seconds: 10));

        developer.log('Acknowledgement sent successfully', name: 'ProvisionNotifier');
        print('DEBUG: Acknowledgement sent - device knows we have serial\n');
      } else {
        print('\n' + '!' * 50);
        print('SERIAL NUMBER RETRIEVAL FAILED (NULL OR EMPTY)');
        print('!' * 50 + '\n');

        developer.log('Serial retrieval failed', name: 'ProvisionNotifier');
        throw Exception('Failed to retrieve serial number');
      }
      */

      // Update UI with complete data (using dummy serial for now)
      state = state.copyWith(
        serialNumber: dummySerial,
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