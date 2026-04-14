import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:app/apiv2/control_plane.dart';
import 'package:app/provider/control_plane_providers.dart';
import 'package:flutter_esp_ble_prov/flutter_esp_ble_prov.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:app/service/provisioning_service.dart';

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
    String prefix = 'cabiNET-';
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

}


@riverpod
ProvisioningRepository provisioningRepository(Ref ref) {
  return ProvisioningRepository(
    bleProv: FlutterEspBleProv(),
    apiClient: ref.watch(controlPlaneClientProvider),
  );
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
sealed class ProvisionState with ProvisionStateMappable {
  final double progress;
  final String? deviceName;
  final List<String> bluetoothList;
  final List<WifiEntry> wifiNetworks;
  final String? ssid;
  final Duration? completionETA;
  final String? wifiPassword;
  final String? serialNumber;
  final ProvisioningClaim? claim;
  final Object? errorMessage;

  const ProvisionState({
    this.progress = 0.0,
    this.deviceName,
    this.bluetoothList = const [],
    this.wifiNetworks = const [],
    this.ssid,
    this.completionETA,
    this.wifiPassword,
    this.serialNumber,
    this.claim,
    this.errorMessage,
  });

  // Helper to check for error without needing to cast specifically in all places
  Object? get error => errorMessage;
}

@MappableClass()
class ProvisionStateScanningBle extends ProvisionState with ProvisionStateScanningBleMappable {
  const ProvisionStateScanningBle({super.progress, super.deviceName, super.bluetoothList, super.wifiNetworks, super.ssid, super.completionETA, super.wifiPassword, super.serialNumber, super.claim, super.errorMessage});
}

@MappableClass()
class ProvisionStateSelectBle extends ProvisionState with ProvisionStateSelectBleMappable {
  const ProvisionStateSelectBle({super.progress, super.deviceName, super.bluetoothList, super.wifiNetworks, super.ssid, super.completionETA, super.wifiPassword, super.serialNumber, super.claim, super.errorMessage});
}

@MappableClass()
class ProvisionStateFetchingSerial extends ProvisionState with ProvisionStateFetchingSerialMappable {
  const ProvisionStateFetchingSerial({super.progress, super.deviceName, super.bluetoothList, super.wifiNetworks, super.ssid, super.completionETA, super.wifiPassword, super.serialNumber, super.claim, super.errorMessage});
}

@MappableClass()
class ProvisionStateScanningWifi extends ProvisionState with ProvisionStateScanningWifiMappable {
  const ProvisionStateScanningWifi({super.progress, super.deviceName, super.bluetoothList, super.wifiNetworks, super.ssid, super.completionETA, super.wifiPassword, super.serialNumber, super.claim, super.errorMessage});
}

@MappableClass()
class ProvisionStateSelectWifi extends ProvisionState with ProvisionStateSelectWifiMappable {
  const ProvisionStateSelectWifi({super.progress, super.deviceName, super.bluetoothList, super.wifiNetworks, super.ssid, super.completionETA, super.wifiPassword, super.serialNumber, super.claim, super.errorMessage});
}

@MappableClass()
class ProvisionStateProvisioningWifi extends ProvisionState with ProvisionStateProvisioningWifiMappable {
  const ProvisionStateProvisioningWifi({super.progress, super.deviceName, super.bluetoothList, super.wifiNetworks, super.ssid, super.completionETA, super.wifiPassword, super.serialNumber, super.claim, super.errorMessage});
}

@MappableClass()
class ProvisionStateComplete extends ProvisionState with ProvisionStateCompleteMappable {
  const ProvisionStateComplete({super.progress, super.deviceName, super.bluetoothList, super.wifiNetworks, super.ssid, super.completionETA, super.wifiPassword, super.serialNumber, super.claim, super.errorMessage});
}

@MappableClass()
class ProvisionStateFailed extends ProvisionState with ProvisionStateFailedMappable {
  const ProvisionStateFailed({required super.errorMessage, super.progress, super.deviceName, super.bluetoothList, super.wifiNetworks, super.ssid, super.completionETA, super.wifiPassword, super.serialNumber, super.claim});
}

@MappableClass()
class ProvisionStateMissingPermissions extends ProvisionState with ProvisionStateMissingPermissionsMappable {
  const ProvisionStateMissingPermissions({super.progress, super.deviceName, super.bluetoothList, super.wifiNetworks, super.ssid, super.completionETA, super.wifiPassword, super.serialNumber, super.claim, super.errorMessage});
}

@MappableClass()
class ProvisionStateTimeout extends ProvisionState with ProvisionStateTimeoutMappable {
  const ProvisionStateTimeout({required super.errorMessage, super.progress, super.deviceName, super.bluetoothList, super.wifiNetworks, super.ssid, super.completionETA, super.wifiPassword, super.serialNumber, super.claim});
}

@riverpod
class Provision extends _$Provision {
  @override
  ProvisionState build() {
    return const ProvisionStateScanningBle();
  }

  Future<void> scanBluetooth() async {
    final repo = ref.read(provisioningRepositoryProvider);

    // Set initial state
    state = ProvisionStateScanningBle(
      progress: 0.1,
    );
    try {
      final devices = await repo.scanBleDevices()
          .timeout(const Duration(seconds: 25));
      developer.log('BLE scan completed. Found ${devices.length} devices.', name: 'ProvisionNotifier');
      state = ProvisionStateSelectBle(
        bluetoothList: devices,
        progress: 1.0,
      );
    } on TimeoutException catch (e, stack) {
      developer.log('BLE scan timed out', name: 'ProvisionNotifier', error: e, stackTrace: stack);
      state = ProvisionStateTimeout(errorMessage: 'BLE Scan Timeout: Device not found.');
    } catch (e, stack) {
      developer.log('BLE scan failed: $e', name: 'ProvisionNotifier', error: e, stackTrace: stack);
      state = ProvisionStateFailed(errorMessage: 'BLE Scan Error: ${e.toString()}');
    }
  }

  Future<void> rescanBluetooth() => scanBluetooth();

  Future<void> selectBluetooth(String name) async {
    final repo = ref.read(provisioningRepositoryProvider);

    state = ProvisionStateScanningWifi(
      deviceName: name,
      progress: 0.1,
    );

    try {
      // Step 1: Establish SECURITY_1 session by scanning WiFi networks first
      developer.log('Connecting to device $name to establish session...', name: 'ProvisionNotifier');

      final networks = await repo.scanWifiNetworks(name)
          .timeout(const Duration(seconds: 25));
I      var wifiEntries = networks.map((n) => WifiEntry(name: n)).toList();
      developer.log('Session established. Found ${networks.length} networks', name: 'ProvisionNotifier');

      // Step 2: Fetch hardware serial number from device
      state = ProvisionStateFetchingSerial(
        deviceName: name,
        wifiNetworks: wifiEntries,
        progress: 0.4,
      );
      developer.log('Fetching serial number from hardware...', name: 'ProvisionNotifier');

      // Retry serial fetch up to 3 attempts, reconnecting on each failure.
      // BLE status 133 (GATT_ERROR) can occur when the WiFi scan left the
      // session in a stale/cached state; a fresh disconnect + rescan fixes it.
      String serial = '';
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          serial = await repo.fetchHardwareSerial(name);
          break;
        } catch (e) {
          if (attempt == 3) rethrow;
          developer.log(
            'Serial fetch attempt $attempt failed ($e). Reconnecting...',
            name: 'ProvisionNotifier',
          );
          try { await repo.disconnectDevice(name); } catch (_) {}
          await Future.delayed(const Duration(seconds: 2));
          // Re-establish BLE session before next attempt
          final retryNetworks = await repo.scanWifiNetworks(name)
              .timeout(const Duration(seconds: 25));
          wifiEntries = retryNetworks.map((n) => WifiEntry(name: n)).toList();
        }
      }

      developer.log('Serial number retrieved: $serial', name: 'ProvisionNotifier');

      state = ProvisionStateFetchingSerial(
        deviceName: name,
        serialNumber: serial,
        wifiNetworks: wifiEntries,
        progress: 0.55,
      );

      // Step 3: Claim device from backend using real hardware serial
      developer.log('Claiming device from backend for $serial...', name: 'ProvisionNotifier');

      final claimResult = await repo.claimDevice(serial);

      developer.log('Claim successful. DeviceID: ${claimResult.deviceId}', name: 'ProvisionNotifier');

      state = ProvisionStateFetchingSerial(
        deviceName: name,
        serialNumber: serial,
        claim: claimResult,
        wifiNetworks: wifiEntries,
        progress: 0.75,
      );

      // Step 4: Send Claim ID and Token to device
      developer.log('Sending claim ID and token to device...', name: 'ProvisionNotifier');

      await repo.sendClaimTokenToHardware(name, claimResult);

      developer.log('Claim token set on device successfully', name: 'ProvisionNotifier');

      // Step 5: Move to WiFi selection
      state = ProvisionStateSelectWifi(
        deviceName: name,
        serialNumber: serial,
        claim: claimResult,
        wifiNetworks: wifiEntries,
        progress: 1.0,
      );
    } on TimeoutException catch (e, stack) {
      try { await repo.disconnectDevice(name); } catch (_) {}
      developer.log('Provisioning session timed out: $e', name: 'ProvisionNotifier', error: e, stackTrace: stack);
      state = ProvisionStateTimeout(
        errorMessage: 'Connection Timed Out: The device took too long to respond.',
        deviceName: name,
        serialNumber: state.serialNumber,
        claim: state.claim,
      );
    } catch (e, stack) {
      try { await repo.disconnectDevice(name); } catch (_) {}
      developer.log('Provisioning sequence failed: $e', name: 'ProvisionNotifier', error: e, stackTrace: stack);
      state = ProvisionStateFailed(
        errorMessage: 'Provisioning Error: ${e.toString()}',
        deviceName: name,
        serialNumber: state.serialNumber,
        claim: state.claim,
      );
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
    final currentDeviceName = state.deviceName;
    if (currentDeviceName == null) return;
    final repo = ref.read(provisioningRepositoryProvider);

    state = ProvisionStateProvisioningWifi(
      deviceName: currentDeviceName,
      serialNumber: state.serialNumber,
      claim: state.claim,
      wifiNetworks: state.wifiNetworks,
      ssid: ssid,
      wifiPassword: password,
      progress: 0.0,
    );

    developer.log('Initiating Wi-Fi provisioning for $currentDeviceName with SSID: $ssid', name: 'ProvisionNotifier');
    try {
      final success = await repo.provisionWifi(
        currentDeviceName,
        ssid,
        password,
      );
      developer.log('Provisioning result: $success', name: 'ProvisionNotifier');

      if (success == true) {
        developer.log('WiFi credentials sent and provisioned successfully.', name: 'ProvisionNotifier');
        await repo.disconnectDevice(currentDeviceName);
        state = ProvisionStateComplete(
          deviceName: currentDeviceName,
          serialNumber: state.serialNumber,
          claim: state.claim,
          wifiNetworks: state.wifiNetworks,
          ssid: ssid,
          progress: 1.0,
        );
      } else if (success == false) {
        // Espressif SDK returned false (e.g. AUTH_FAILED — wrong password).
        // Gracefully handle it: return to SelectWifi with an errorMessage
        developer.log('WiFi authentication failed — incorrect password.', name: 'ProvisionNotifier');
        state = ProvisionStateSelectWifi(
          errorMessage: ProvisionError.errorPasswordIncorrect,
          deviceName: currentDeviceName,
          serialNumber: state.serialNumber,
          claim: state.claim,
          wifiNetworks: state.wifiNetworks,
          ssid: ssid,
          progress: 1.0,
        );
      } else {
        // success is null — device likely wiped credentials and restarted.
        await _reconnectGracefully(currentDeviceName, ssid, reason: 'unpredictable disconnect');
      }
    } catch (e, stack) {
      developer.log('Provisioning error: $e', name: 'ProvisionNotifier', error: e, stackTrace: stack);
      await _reconnectGracefully(currentDeviceName, ssid, reason: e.toString());
    }
  }

  Future<void> _reconnectGracefully(String deviceName, String ssid, {required String reason}) async {
    final repo = ref.read(provisioningRepositoryProvider);
    developer.log('Device unreachable ($reason). Attempting gentle reconnect...', name: 'ProvisionNotifier');
    
    try { await repo.disconnectDevice(deviceName); } catch (_) {}

    state = ProvisionStateScanningWifi(
      deviceName: deviceName,
      serialNumber: state.serialNumber,
      claim: state.claim,
      wifiNetworks: state.wifiNetworks,
      ssid: ssid,
      progress: 0.1,
      errorMessage: 'Connection lost. Reconnecting to device...',
    );

    // Give ESP32 some time to reboot and advertise BLE
    await Future.delayed(const Duration(seconds: 3));

    try {
      await selectBluetooth(deviceName);
      
      if (state is ProvisionStateSelectWifi) {
        // Successfully reconnected, mark the previous Wi-Fi connection as failed
        state = (state as ProvisionStateSelectWifi).copyWith(
          errorMessage: 'Wi-Fi connection failed. Please check credentials and try again.',
          ssid: ssid,
        );
      }
    } catch (e, stack) {
      try { await repo.disconnectDevice(deviceName); } catch (_) {}
      developer.log('Graceful reconnect failed: $e', name: 'ProvisionNotifier', error: e, stackTrace: stack);
      state = ProvisionStateFailed(
        errorMessage: 'Device disconnected and could not be reached. Please start over.',
        deviceName: deviceName,
        serialNumber: state.serialNumber,
        claim: state.claim,
        wifiNetworks: state.wifiNetworks,
        ssid: ssid,
      );
    }
  }

  Future<void> cancelProvisioning() async {
    final name = state.deviceName;
    if (name != null) {
      try {
        final repo = ref.read(provisioningRepositoryProvider);
        await repo.disconnectDevice(name);
      } catch (_) {}
    }
  }
}