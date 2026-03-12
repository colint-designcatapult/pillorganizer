import 'dart:typed_data';
import 'dart:convert';
import 'package:app/apiv2/control_plane.dart';
import 'package:app/provider/control_plane_providers.dart';
import 'package:flutter_esp_ble_prov/flutter_esp_ble_prov.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'dart:developer' as developer;
import 'package:app/service/amplify_service.dart';
import 'package:flutter/foundation.dart';

import '../apiv2/models/dto.dart';

part 'provision_provider.mapper.dart';
part 'provision_provider.g.dart';

@MappableClass()
class ProvisioningClaim with ProvisioningClaimMappable {
  final String claimId;
  final String tenantId;
  final String tenantApiBase;
  final String deviceId;
  final String claimToken;

  ProvisioningClaim({
    required this.claimId,
    required this.tenantId,
    required this.tenantApiBase,
    required this.deviceId,
    required this.claimToken
  });
}

extension ProvisioningClaimDtoMapper on ProvisioningClaimDto {
  ProvisioningClaim toDomain() {
    return ProvisioningClaim(
        claimId: claimId,
        tenantId: tenantId,
        tenantApiBase: tenantApiBase,
        deviceId: deviceId,
        claimToken: claimToken
    );
  }
}

class ProvisioningRepository {
  final FlutterEspBleProv bleProv;
  final ControlPlaneApiClient apiClient;

  ProvisioningRepository({required this.bleProv, required this.apiClient});

  Future<List<String>> scanBleDevices() {
    String prefix = 'PILL-';
    return bleProv.scanBleDevices(prefix);
  }

  Future<List<String>> scanWifiNetworks(String deviceName) {
    return bleProv.scanWifiNetworks(deviceName, '');
  }

  Future<String> fetchHardwareSerial(String deviceName) async {
    developer.log('Fetching hardware serial...');
    final serialData = await bleProv
        .sendCustomData(deviceName, '', 'device_serial', Uint8List(0))
        .timeout(const Duration(seconds: 10));

    if (serialData == null || serialData.isEmpty) {
      throw Exception('Hardware returned null or empty serial data');
    }

    final rawString = String.fromCharCodes(serialData);

    // Safely parse JSON without blind catch block
    try {
      final parsed = jsonDecode(rawString);
      if (parsed is Map<String, dynamic> && parsed['serialNumber'] != null) {
        return parsed['serialNumber'] as String;
      }
      throw FormatException('JSON missing "serialNumber" key');
    } catch (e) {
      if (e is FormatException) rethrow;

      // Fallback: only treat as plain string if it's clearly not a JSON object
      final fallback = rawString.trim();
      if (fallback.startsWith('{')) {
        throw FormatException('Invalid JSON payload returned from hardware');
      }
      return fallback;
    }
  }

  Future<ProvisioningClaim> claimDevice(String serial) async {
    developer.log('Claiming device $serial via Backend API...');
    final result = await apiClient.getProvisioningClaim(
        ProvisioningClaimRequestDto(serialNumber: serial, deviceId: null));
    if (result == null) {
      throw Exception('Backend refused claim for device $serial');
    }
    return result.toDomain();
  }

  Future<void> sendClaimTokenToHardware(String deviceName, ProvisioningClaim claim) async {
    developer.log('Sending Claim Token back to hardware...');
    final payload = jsonEncode({
      "claimId": claim.claimId,
      "claimToken": claim.claimToken,
    });

    await bleProv.sendCustomData(
      deviceName,
      '',
      'device_claim_token_set',
      Uint8List.fromList(utf8.encode(payload)),
    ).timeout(const Duration(seconds: 10));
  }

  Future<bool?> provisionWifi(String deviceName, String ssid, String password) {
    return bleProv.provisionWifi(deviceName, '', ssid, password);
  }

  Future<void> disconnectDevice(String deviceName) {
    return bleProv.disconnectDevice(deviceName);
  }

  Future<WifiConnectionStatus?> getWifiConnectionStatus(String deviceName) async {
    final responseData = await bleProv.sendCustomData(deviceName, '', 'wifi_connection_status', Uint8List(0))
        .timeout(const Duration(seconds: 5));
        
    if (responseData == null || responseData.isEmpty) return null;
    
    final rawString = String.fromCharCodes(responseData);
    try {
      final parsed = jsonDecode(rawString) as Map<String, dynamic>;
      final connected = parsed['connected'] as bool? ?? false;
      final failed = parsed['failed'] as bool? ?? false;
      return WifiConnectionStatus(connected: connected, failed: failed);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getFleetProvisioningStatus(String deviceName) async {
    final responseData = await bleProv.sendCustomData(deviceName, '', 'fleet_provisioning_status', Uint8List(0))
        .timeout(const Duration(seconds: 5));
        
    if (responseData == null || responseData.isEmpty) return null;
    
    final rawString = String.fromCharCodes(responseData);
    try {
      final parsed = jsonDecode(rawString) as Map<String, dynamic>;
      return parsed['status'] as String? ?? 'unknown';
    } catch (_) {
      return rawString.trim();
    }
  }
}

class WifiConnectionStatus {
  final bool connected;
  final bool failed;

  WifiConnectionStatus({required this.connected, required this.failed});
}


@riverpod
ProvisioningRepository provisioningRepository(Ref ref) {
  return ProvisioningRepository(
    bleProv: FlutterEspBleProv(),
    apiClient: ref.watch(controlPlaneClientProvider),
  );
}

enum ProvisionStage {
  scanning_ble,
  select_ble,
  fetchingSerial,
  scanning_wifi,
  select_wifi,
  provisioning_wifi,
  verifying_wifi,
  fleet_provisioning,
  complete,
  failed,
  missingPermissions
}

@MappableClass()
class WifiEntry with WifiEntryMappable {
  final String name;
  final int? rssi;

  const WifiEntry({
    required this.name,
    this.rssi,
  });
}

@MappableClass()
class ProvisionState with ProvisionStateMappable {
  final ProvisionStage stage;
  final Object? error;
  final double progress;
  final String? deviceName;
  final List<String> bluetoothList;
  final List<WifiEntry> wifiNetworks;
  final String? ssid;
  final Duration? completionETA;
  final String? wifiPassword;
  final String? serialNumber;
  final ProvisioningClaim? claim;

  const ProvisionState({
    this.stage = ProvisionStage.scanning_ble,
    this.error,
    this.progress = 0.0,
    this.deviceName,
    this.bluetoothList = const [],
    this.wifiNetworks = const [],
    this.ssid,
    this.completionETA,
    this.wifiPassword,
    this.serialNumber,
    this.claim
  });
}

@riverpod
class Provision extends _$Provision {
  @override
  ProvisionState build() {
    return const ProvisionState();
  }

  Future<void> scanBluetooth() async {
    final repo = ref.read(provisioningRepositoryProvider);

    // Set initial state
    state = state.copyWith(
      stage: ProvisionStage.scanning_ble,
      progress: 0.1,
      error: null,
    );
    try {
      final devices = await repo.scanBleDevices();
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
    final repo = ref.read(provisioningRepositoryProvider);

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

      final networks = await repo.scanWifiNetworks(name);
      developer.log('Session established. Found ${networks.length} networks', name: 'ProvisionNotifier');
      print('DEBUG: WiFi scan completed and session established. Found ${networks.length} networks');

      // Step 2: Fetch hardware serial number from device
      state = state.copyWith(
        stage: ProvisionStage.fetchingSerial,
        progress: 0.4,
      );
      developer.log('Fetching serial number from hardware...', name: 'ProvisionNotifier');
      print('DEBUG: Fetching serial number from hardware...');

      final serial = await repo.fetchHardwareSerial(name);

      print('\n' + '*' * 50);
      print('SERIAL NUMBER RETRIEVED: $serial');
      print('*' * 50 + '\n');
      developer.log('Serial number retrieved: $serial', name: 'ProvisionNotifier');

      state = state.copyWith(serialNumber: serial, progress: 0.55);

      // Step 3: Claim device from backend using real hardware serial
      developer.log('Claiming device from backend for $serial...', name: 'ProvisionNotifier');
      print('DEBUG: Claiming device from backend for $serial...');

      final claimResult = await repo.claimDevice(serial);

      developer.log('Claim successful. DeviceID: ${claimResult.deviceId}', name: 'ProvisionNotifier');

      print('\n' + '=' * 60);
      print('🚀 DEVICE CLAIMED SUCCESSFULLY:');
      print('   DEVICE ID:   ${claimResult.deviceId}');
      print('   CLAIM ID:    ${claimResult.claimId}');
      print('   CLAIM TOKEN: ${claimResult.claimToken}');
      print('=' * 60 + '\n');

      state = state.copyWith(
        claim: claimResult,
        progress: 0.75,
      );

      // Step 4: Send Claim ID and Token to device
      developer.log('Sending claim ID and token to device...', name: 'ProvisionNotifier');
      print('DEBUG: Sending claim ID and token to device...');

      await repo.sendClaimTokenToHardware(name, claimResult);

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
    final repo = ref.read(provisioningRepositoryProvider);

    state = state.copyWith(
      ssid: ssid,
      stage: ProvisionStage.provisioning_wifi,
      progress: 0.0,
      error: null,
    );

    developer.log('Initiating Wi-Fi provisioning for ${state.deviceName} with SSID: $ssid', name: 'ProvisionNotifier');
    print('DEBUG: Initiating Wi-Fi provisioning for ${state.deviceName} with SSID: $ssid');
    try {
      final success = await repo.provisionWifi(
        state.deviceName!,
        ssid,
        password,
      );
      developer.log('Provisioning result: $success', name: 'ProvisionNotifier');
      print('DEBUG: Provisioning result: $success');

      if (success == true) {
        // WiFi creds handed off — verify the device actually connected before fleet provisioning
        state = state.copyWith(
          stage: ProvisionStage.verifying_wifi,
          progress: 0.3,
        );
        print('DEBUG: WiFi credentials sent. Verifying WiFi connection...');
        final wifiConnected = await _pollWifiConnectionStatus(state.deviceName!);
        if (!wifiConnected) return; // error state already set inside the method

        // WiFi confirmed — now poll fleet provisioning
        state = state.copyWith(
          stage: ProvisionStage.fleet_provisioning,
          progress: 0.5,
        );
        print('DEBUG: WiFi connected. Polling for fleet provisioning status...');
        await _pollFleetProvisioningStatus(state.deviceName!);
      } else {
        // Espressif SDK returned false (e.g. AUTH_FAILED — wrong password).
        // Device wipes all credentials and restarts, so user must start over.
        // Disconnect to clear the stale BLE session so the next attempt reconnects fresh.
        try { await repo.disconnectDevice(state.deviceName!); } catch (_) {}
        state = state.copyWith(
          stage: ProvisionStage.scanning_ble,
          progress: 0.0,
          error: 'WiFi authentication failed — incorrect password. Your device is restarting, please start provisioning again.',
        );
      }
    } catch (e, stack) {
      developer.log('Provisioning error: $e', name: 'ProvisionNotifier', error: e, stackTrace: stack);
      print('DEBUG: Provisioning error: $e');
      state = state.copyWith(stage: ProvisionStage.failed, error: 'Provisioning Error: ${e.toString()}');
    }
  }

  /// Polls wifi_connection_status after handing off credentials.
  /// Returns true when the device is connected to WiFi.
  /// Returns false (and sets select_wifi error state) on failure or timeout.
  Future<bool> _pollWifiConnectionStatus(String deviceName) async {
    final repo = ref.read(provisioningRepositoryProvider);
    const pollInterval = Duration(seconds: 3);
    const maxDuration = Duration(seconds: 45);
    final deadline = DateTime.now().add(maxDuration);

    print('DEBUG: [WIFI] Starting wifi_connection_status poll (max 45s)...');

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(pollInterval);

      try {
        final status = await repo.getWifiConnectionStatus(deviceName);

        if (status == null) {
          print('DEBUG: [WIFI] Empty response or parse error, retrying...');
          continue;
        }

        bool connected = status.connected;
        bool failed = status.failed;

        developer.log('WiFi status: connected=$connected, failed=$failed', name: 'ProvisionNotifier');

        if (failed) {
          print('\n' + '⚠️  ' * 15);
          print('WIFI CONNECTION FAILED — DEVICE RESTARTING, START OVER');
          print('⚠️  ' * 15 + '\n');
          // Device wipes credentials and restarts — user must start provisioning over.
          // Disconnect to clear the stale BLE session.
          try { await repo.disconnectDevice(deviceName); } catch (_) {}
          state = state.copyWith(
            stage: ProvisionStage.scanning_ble,
            progress: 0.0,
            error: 'WiFi connection failed. Your device is restarting — please start provisioning again.',
          );
          return false;
        }

        if (connected) {
          print('\n' + '📶 ' * 15);
          print('WIFI CONNECTED SUCCESSFULLY!');
          print('📶 ' * 15 + '\n');
          return true;
        }

        // Still connecting — update progress and keep polling
        final remaining = deadline.difference(DateTime.now()).inSeconds;
        print('DEBUG: [WIFI] Not yet connected, ${remaining}s remaining...');
        state = state.copyWith(
          progress: 0.3 + (0.2 * (1 - remaining / maxDuration.inSeconds)),
        );
      } catch (e) {
        print('DEBUG: [WIFI] Poll error (retrying): $e');
      }
    }

    // 45s elapsed without connecting
    print('\n' + '⏰ ' * 15);
    print('WIFI CONNECTION TIMED OUT — DEVICE RESTARTING, START OVER');
    print('⏰ ' * 15 + '\n');
    // Device wipes credentials and restarts — user must start provisioning over.
    // Disconnect to clear the stale BLE session.
    try { await repo.disconnectDevice(deviceName); } catch (_) {}
    state = state.copyWith(
      stage: ProvisionStage.scanning_ble,
      progress: 0.0,
      error: 'WiFi connection timed out. Your device is restarting — please start provisioning again.',
    );
    return false;
  }

  /// Polls the fleet_provisioning_status BLE endpoint every 3s for up to 60s.
  /// - "success" → stage = complete ✅
  /// - "failed" or timeout → stage = scanning_ble (device restarts, user re-pairs) ❌
  Future<void> _pollFleetProvisioningStatus(String deviceName) async {
    final repo = ref.read(provisioningRepositoryProvider);
    const pollInterval = Duration(seconds: 3);
    const maxDuration = Duration(seconds: 60);
    final deadline = DateTime.now().add(maxDuration);

    print('DEBUG: [FLEET] Starting fleet provisioning status poll (max 60s)...');

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(pollInterval);

      try {
        final status = await repo.getFleetProvisioningStatus(deviceName);

        if (status == null) {
          print('DEBUG: [FLEET] Empty response or parse error, continuing poll...');
          continue;
        }

        developer.log('Fleet provisioning status: $status', name: 'ProvisionNotifier');

        switch (status) {
          case 'success':
            print('\n' + '✅ ' * 20);
            print('FLEET PROVISIONING COMPLETE — DEVICE IS REGISTERED!');
            print('✅ ' * 20 + '\n');
            await repo.disconnectDevice(deviceName);
            state = state.copyWith(
              stage: ProvisionStage.complete,
              progress: 1.0,
            );
            return;

          case 'failed':
            print('\n' + '❌ ' * 20);
            print('FLEET PROVISIONING FAILED — DEVICE RESTARTING, RESCAN BLE');
            print('❌ ' * 20 + '\n');
            await repo.disconnectDevice(deviceName);
            state = state.copyWith(
              stage: ProvisionStage.scanning_ble,
              progress: 0.0,
              error: 'Fleet provisioning failed. Device is restarting — please re-scan.',
            );
            return;

          default: // 'idle', 'pending', or unknown
            final remainingSeconds = deadline.difference(DateTime.now()).inSeconds;
            print('DEBUG: [FLEET] Status "$status", ${remainingSeconds}s remaining...');
            state = state.copyWith(
              progress: 0.5 + (0.4 * (1 - remainingSeconds / maxDuration.inSeconds)),
            );
            break;
        }
      } catch (e) {
        // BLE timeout/error mid-poll — keep trying until deadline
        print('DEBUG: [FLEET] Poll error (retrying): $e');
      }
    }

    // 60s elapsed with no success
    print('\n' + '⏰ ' * 20);
    print('FLEET PROVISIONING TIMED OUT — DEVICE RESTARTING, RESCAN BLE');
    print('⏰ ' * 20 + '\n');
    await repo.disconnectDevice(deviceName);
    state = state.copyWith(
      stage: ProvisionStage.scanning_ble,
      progress: 0.0,
      error: 'Fleet provisioning timed out. Device is restarting — please re-scan.',
    );
  }
}