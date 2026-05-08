import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:app/apiv2/control_plane.dart';
import 'package:app/provider/control_plane_providers.dart';
import 'package:app/provider/device_provider.dart';
import 'package:flutter_esp_ble_prov/flutter_esp_ble_prov.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:app/service/provisioning_service.dart';

import '../apiv2/models/dto.dart';

part 'provision_provider.mapper.dart';
part 'provision_provider.g.dart';

enum ProvisionMode {
  newDevice,
  wifiReconfigure,
  transferDevice,
}

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

  Future<ProvisioningClaim> claimDevice(String serial, {String? deviceId}) async {
    developer.log('Claiming device $serial via Backend API...');
    final result = await apiClient.getProvisioningClaim(
        ProvisioningClaimRequestDto(serialNumber: serial, deviceId: deviceId));
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
  final ProvisionMode mode;
  final String? existingDeviceId;
  final String? targetDeviceName;

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
    this.mode = ProvisionMode.newDevice,
    this.existingDeviceId,
    this.targetDeviceName,
  });

  // Helper to check for error without needing to cast specifically in all places
  Object? get error => errorMessage;
}

@MappableClass()
class ProvisionStateScanningBle extends ProvisionState with ProvisionStateScanningBleMappable {
  const ProvisionStateScanningBle({super.progress, super.deviceName, super.bluetoothList, super.wifiNetworks, super.ssid, super.completionETA, super.wifiPassword, super.serialNumber, super.claim, super.errorMessage, super.mode, super.existingDeviceId, super.targetDeviceName});
}

@MappableClass()
class ProvisionStateSelectBle extends ProvisionState with ProvisionStateSelectBleMappable {
  const ProvisionStateSelectBle({super.progress, super.deviceName, super.bluetoothList, super.wifiNetworks, super.ssid, super.completionETA, super.wifiPassword, super.serialNumber, super.claim, super.errorMessage, super.mode, super.existingDeviceId, super.targetDeviceName});
}

@MappableClass()
class ProvisionStateFetchingSerial extends ProvisionState with ProvisionStateFetchingSerialMappable {
  const ProvisionStateFetchingSerial({super.progress, super.deviceName, super.bluetoothList, super.wifiNetworks, super.ssid, super.completionETA, super.wifiPassword, super.serialNumber, super.claim, super.errorMessage, super.mode, super.existingDeviceId, super.targetDeviceName});
}

@MappableClass()
class ProvisionStateScanningWifi extends ProvisionState with ProvisionStateScanningWifiMappable {
  const ProvisionStateScanningWifi({super.progress, super.deviceName, super.bluetoothList, super.wifiNetworks, super.ssid, super.completionETA, super.wifiPassword, super.serialNumber, super.claim, super.errorMessage, super.mode, super.existingDeviceId, super.targetDeviceName});
}

@MappableClass()
class ProvisionStateSelectWifi extends ProvisionState with ProvisionStateSelectWifiMappable {
  const ProvisionStateSelectWifi({super.progress, super.deviceName, super.bluetoothList, super.wifiNetworks, super.ssid, super.completionETA, super.wifiPassword, super.serialNumber, super.claim, super.errorMessage, super.mode, super.existingDeviceId, super.targetDeviceName});
}

@MappableClass()
class ProvisionStateProvisioningWifi extends ProvisionState with ProvisionStateProvisioningWifiMappable {
  const ProvisionStateProvisioningWifi({super.progress, super.deviceName, super.bluetoothList, super.wifiNetworks, super.ssid, super.completionETA, super.wifiPassword, super.serialNumber, super.claim, super.errorMessage, super.mode, super.existingDeviceId, super.targetDeviceName});
}

@MappableClass()
class ProvisionStateComplete extends ProvisionState with ProvisionStateCompleteMappable {
  const ProvisionStateComplete({super.progress, super.deviceName, super.bluetoothList, super.wifiNetworks, super.ssid, super.completionETA, super.wifiPassword, super.serialNumber, super.claim, super.errorMessage, super.mode, super.existingDeviceId, super.targetDeviceName});
}

@MappableClass()
class ProvisionStateFailed extends ProvisionState with ProvisionStateFailedMappable {
  const ProvisionStateFailed({required super.errorMessage, super.progress, super.deviceName, super.bluetoothList, super.wifiNetworks, super.ssid, super.completionETA, super.wifiPassword, super.serialNumber, super.claim, super.mode, super.existingDeviceId, super.targetDeviceName});
}

@MappableClass()
class ProvisionStateMissingPermissions extends ProvisionState with ProvisionStateMissingPermissionsMappable {
  const ProvisionStateMissingPermissions({super.progress, super.deviceName, super.bluetoothList, super.wifiNetworks, super.ssid, super.completionETA, super.wifiPassword, super.serialNumber, super.claim, super.errorMessage, super.mode, super.existingDeviceId, super.targetDeviceName});
}

@MappableClass()
class ProvisionStateTimeout extends ProvisionState with ProvisionStateTimeoutMappable {
  const ProvisionStateTimeout({required super.errorMessage, super.progress, super.deviceName, super.bluetoothList, super.wifiNetworks, super.ssid, super.completionETA, super.wifiPassword, super.serialNumber, super.claim, super.mode, super.existingDeviceId, super.targetDeviceName});
}

@riverpod
class Provision extends _$Provision {
  @override
  ProvisionState build() {
    return const ProvisionStateScanningBle();
  }

  void initWithMode({
    required ProvisionMode mode,
    String? existingDeviceId,
    String? targetDeviceName,
  }) {
    state = ProvisionStateScanningBle(
      mode: mode,
      existingDeviceId: existingDeviceId,
      targetDeviceName: targetDeviceName,
    );
  }

  Future<void> scanBluetooth() async {
    final repo = ref.read(provisioningRepositoryProvider);
    final mode = state.mode;
    final existingDeviceId = state.existingDeviceId;
    final targetDeviceName = state.targetDeviceName;

    // Set initial state
    state = ProvisionStateScanningBle(
      progress: 0.1,
      mode: mode,
      existingDeviceId: existingDeviceId,
      targetDeviceName: targetDeviceName,
    );
    try {
      final devices = await repo.scanBleDevices()
          .timeout(const Duration(seconds: 25));
      developer.log('BLE scan completed. Found ${devices.length} devices.', name: 'ProvisionNotifier');

      // In wifiReconfigure mode, auto-select the known device
      if (mode == ProvisionMode.wifiReconfigure && targetDeviceName != null) {
        final match = devices.where((d) => d == targetDeviceName).firstOrNull;
        if (match != null) {
          developer.log('Auto-selecting known device: $targetDeviceName', name: 'ProvisionNotifier');
          await selectBluetooth(match);
          return;
        }
        // Device not found in scan, show list so user can retry
        developer.log('Target device $targetDeviceName not found in scan', name: 'ProvisionNotifier');
      }

      state = ProvisionStateSelectBle(
        bluetoothList: devices,
        progress: 1.0,
        mode: mode,
        existingDeviceId: existingDeviceId,
        targetDeviceName: targetDeviceName,
      );
    } on TimeoutException catch (e, stack) {
      developer.log('BLE scan timed out', name: 'ProvisionNotifier', error: e, stackTrace: stack);
      state = ProvisionStateTimeout(
        errorMessage: 'BLE Scan Timeout: Device not found.',
        mode: mode,
        existingDeviceId: existingDeviceId,
        targetDeviceName: targetDeviceName,
      );
    } catch (e, stack) {
      developer.log('BLE scan failed: $e', name: 'ProvisionNotifier', error: e, stackTrace: stack);
      state = ProvisionStateFailed(
        errorMessage: 'BLE Scan Error: ${e.toString()}',
        mode: mode,
        existingDeviceId: existingDeviceId,
        targetDeviceName: targetDeviceName,
      );
    }
  }

  Future<void> rescanBluetooth() => scanBluetooth();

  Future<void> selectBluetooth(String name) async {
    final repo = ref.read(provisioningRepositoryProvider);
    final mode = state.mode;
    final existingDeviceId = state.existingDeviceId;
    final targetDeviceName = state.targetDeviceName;

    state = ProvisionStateScanningWifi(
      deviceName: name,
      progress: 0.1,
      mode: mode,
      existingDeviceId: existingDeviceId,
      targetDeviceName: targetDeviceName,
    );

    try {
      // Step 1: Establish SECURITY_1 session by scanning WiFi networks first
      developer.log('Connecting to device $name to establish session...', name: 'ProvisionNotifier');

      final networks = await repo.scanWifiNetworks(name)
          .timeout(const Duration(seconds: 25));
      final wifiEntries = networks.map((n) => WifiEntry(name: n)).toList();
      developer.log('Session established. Found ${networks.length} networks', name: 'ProvisionNotifier');

      if (mode == ProvisionMode.wifiReconfigure) {
        // Wi-Fi reconfigure: skip serial fetch, claim, and claim token — go straight to Wi-Fi selection
        developer.log('Wi-Fi reconfigure mode: skipping serial/claim steps', name: 'ProvisionNotifier');
        state = ProvisionStateSelectWifi(
          deviceName: name,
          wifiNetworks: wifiEntries,
          progress: 1.0,
          mode: mode,
          existingDeviceId: existingDeviceId,
          targetDeviceName: targetDeviceName,
        );
        return;
      }

      // Step 2: Fetch hardware serial number from device
      state = ProvisionStateFetchingSerial(
        deviceName: name,
        wifiNetworks: wifiEntries,
        progress: 0.4,
        mode: mode,
        existingDeviceId: existingDeviceId,
        targetDeviceName: targetDeviceName,
      );
      developer.log('Fetching serial number from hardware...', name: 'ProvisionNotifier');

      final serial = await repo.fetchHardwareSerial(name);

      developer.log('Serial number retrieved: $serial', name: 'ProvisionNotifier');

      state = ProvisionStateFetchingSerial(
        deviceName: name,
        serialNumber: serial,
        wifiNetworks: wifiEntries,
        progress: 0.55,
        mode: mode,
        existingDeviceId: existingDeviceId,
        targetDeviceName: targetDeviceName,
      );

      // Step 3: Claim device from backend using real hardware serial
      developer.log('Claiming device from backend for $serial...', name: 'ProvisionNotifier');

      final claimResult = await repo.claimDevice(
        serial,
        deviceId: mode == ProvisionMode.transferDevice ? existingDeviceId : null,
      );

      developer.log('Claim successful. DeviceID: ${claimResult.deviceId}', name: 'ProvisionNotifier');

      state = ProvisionStateFetchingSerial(
        deviceName: name,
        serialNumber: serial,
        claim: claimResult,
        wifiNetworks: wifiEntries,
        progress: 0.75,
        mode: mode,
        existingDeviceId: existingDeviceId,
        targetDeviceName: targetDeviceName,
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
        mode: mode,
        existingDeviceId: existingDeviceId,
        targetDeviceName: targetDeviceName,
      );
    } on TimeoutException catch (e, stack) {
      try { await repo.disconnectDevice(name); } catch (_) {}
      developer.log('Provisioning session timed out: $e', name: 'ProvisionNotifier', error: e, stackTrace: stack);
      state = ProvisionStateTimeout(
        errorMessage: 'Connection Timed Out: The device took too long to respond.',
        deviceName: name,
        serialNumber: state.serialNumber,
        claim: state.claim,
        mode: mode,
        existingDeviceId: existingDeviceId,
        targetDeviceName: targetDeviceName,
      );
    } catch (e, stack) {
      try { await repo.disconnectDevice(name); } catch (_) {}
      developer.log('Provisioning sequence failed: $e', name: 'ProvisionNotifier', error: e, stackTrace: stack);
      state = ProvisionStateFailed(
        errorMessage: 'Provisioning Error: ${e.toString()}',
        deviceName: name,
        serialNumber: state.serialNumber,
        claim: state.claim,
        mode: mode,
        existingDeviceId: existingDeviceId,
        targetDeviceName: targetDeviceName,
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
    final mode = state.mode;
    final existingDeviceId = state.existingDeviceId;
    final targetDeviceName = state.targetDeviceName;

    state = ProvisionStateProvisioningWifi(
      deviceName: currentDeviceName,
      serialNumber: state.serialNumber,
      claim: state.claim,
      wifiNetworks: state.wifiNetworks,
      ssid: ssid,
      wifiPassword: password,
      progress: 0.0,
      mode: mode,
      existingDeviceId: existingDeviceId,
      targetDeviceName: targetDeviceName,
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
        print('[ProvisionNotifier] WiFi credentials sent and provisioned successfully.');
        await repo.disconnectDevice(currentDeviceName);

        if (mode == ProvisionMode.wifiReconfigure) {
          // Wi-Fi reconfigure: device already exists in backend, no need to wait
          print('[ProvisionNotifier] Wi-Fi reconfigure complete — skipping backend wait.');
          state = ProvisionStateComplete(
            deviceName: currentDeviceName,
            serialNumber: state.serialNumber,
            claim: state.claim,
            wifiNetworks: state.wifiNetworks,
            ssid: ssid,
            progress: 1.0,
            mode: mode,
            existingDeviceId: existingDeviceId,
            targetDeviceName: targetDeviceName,
          );
          return;
        }
        
        // Keep showing provisioning state while waiting for device to appear in backend
        // This reuses the existing "Finishing Setup" progress screen
        final claimId = state.claim?.deviceId;
        if (claimId == null) {
          print('[ProvisionNotifier] ERROR: state.claim is null after WiFi provisioning. Cannot poll for device.');
          state = ProvisionStateTimeout(
            errorMessage: 'Device claim information lost. Cannot complete provisioning.',
            deviceName: currentDeviceName,
            serialNumber: state.serialNumber,
            claim: state.claim,
            wifiNetworks: state.wifiNetworks,
            ssid: ssid,
            mode: mode,
            existingDeviceId: existingDeviceId,
            targetDeviceName: targetDeviceName,
          );
        } else {
          print('[ProvisionNotifier] Waiting for device $claimId to complete fleet provisioning and appear in backend...');
          final deviceFoundInBackend = await _waitForDeviceInBackend(claimId);
          
          if (deviceFoundInBackend) {
            // Device successfully appeared in backend — provisioning is complete
            state = ProvisionStateComplete(
              deviceName: currentDeviceName,
              serialNumber: state.serialNumber,
              claim: state.claim,
              wifiNetworks: state.wifiNetworks,
              ssid: ssid,
              progress: 1.0,
              mode: mode,
              existingDeviceId: existingDeviceId,
              targetDeviceName: targetDeviceName,
            );
          } else {
            // Device did not appear in backend within timeout period — provisioning failed
            state = ProvisionStateTimeout(
              errorMessage: 'Device did not sync to backend within timeout. Please check your network connection and try again.',
              deviceName: currentDeviceName,
              serialNumber: state.serialNumber,
              claim: state.claim,
              wifiNetworks: state.wifiNetworks,
              ssid: ssid,
              mode: mode,
              existingDeviceId: existingDeviceId,
              targetDeviceName: targetDeviceName,
            );
          }
        }
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
          mode: mode,
          existingDeviceId: existingDeviceId,
          targetDeviceName: targetDeviceName,
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

  Future<bool> _waitForDeviceInBackend(String deviceId, {int maxRetries = 60}) async {
    print('[ProvisionNotifier] ===== Starting device backend poll =====');
    print('[ProvisionNotifier] Looking for deviceId: $deviceId (max retries: $maxRetries)');
    
    // Use the existing deviceListProvider to poll for the device
    final deviceListNotifier = ref.read(deviceListProvider.notifier);
    
    for (int i = 0; i < maxRetries; i++) {
      // Check if provisioning is still active before each poll
      // If it's been cancelled or disposed, stop polling immediately
      final currentState = state;
      if (currentState is! ProvisionStateProvisioningWifi) {
        print('[ProvisionNotifier] Provisioning state changed, stopping poll (current: ${currentState.runtimeType})');
        return false;
      }

      try {
        print('[ProvisionNotifier] Poll attempt ${i + 1}/$maxRetries...');
        await deviceListNotifier.refresh();
        final devicesAsyncValue = ref.read(deviceListProvider);
        
        final devices = devicesAsyncValue.value ?? [];
        print('[ProvisionNotifier] Found ${devices.length} devices in backend, checking for deviceId=$deviceId');
        
        // Check by ID only - this is the device ID from the current provisioning claim
        // Do NOT use serial number as fallback because the same physical device can have
        // multiple device IDs if factory reset/reprovisioned (each gets a new ID)
        final deviceExists = devices.any((d) => d.id == deviceId);
        if (deviceExists) {
          print('[ProvisionNotifier] SUCCESS: Device $deviceId found in backend after ${i + 1} attempts!');
          return true;
        }
        
        print('[ProvisionNotifier] Device $deviceId not found yet (attempt ${i + 1}/$maxRetries)');
        
        await Future.delayed(const Duration(seconds: 1));
      } catch (e, stack) {
        print('[ProvisionNotifier] ERROR polling (attempt ${i + 1}/$maxRetries): $e');
        developer.log('Poll error detail', name: 'ProvisionNotifier', error: e, stackTrace: stack);
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    
    print('[ProvisionNotifier] TIMEOUT: Device $deviceId did not appear in backend after $maxRetries attempts');
    return false;
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