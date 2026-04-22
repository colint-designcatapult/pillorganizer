import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_esp_ble_prov_platform_interface.dart';

/// An implementation of [FlutterEspBleProvPlatform] that uses method channels.
class MethodChannelFlutterEspBleProv extends FlutterEspBleProvPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_esp_ble_prov');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<List<String>> scanBleDevices(String prefix) async {
    final args = {'prefix': prefix};
    final raw =
        await methodChannel.invokeMethod<List<Object?>>('scanBleDevices', args);
    final List<String> devices = [];
    if (raw != null) {
      devices.addAll(raw.cast<String>());
    }
    return devices;
  }

  @override
  Future<List<String>> scanWifiNetworks(
      String deviceName, String proofOfPossession) async {
    final args = {
      'deviceName': deviceName,
      'proofOfPossession': proofOfPossession,
    };
    final raw = await methodChannel.invokeMethod<List<Object?>>(
        'scanWifiNetworks', args);
    final List<String> networks = [];
    if (raw != null) {
      networks.addAll(raw.cast<String>());
    }
    return networks;
  }

  @override
  Future<bool?> provisionWifi(String deviceName, String proofOfPossession,
      String ssid, String passphrase) async {
    final args = {
      'deviceName': deviceName,
      'proofOfPossession': proofOfPossession,
      'ssid': ssid,
      'passphrase': passphrase
    };
    return await methodChannel.invokeMethod<bool?>('provisionWifi', args);
  }

  @override
  Future<Uint8List?> sendCustomData(String deviceName, String proofOfPossession,
      String path, Uint8List data) async {
    final args = {
      'deviceName': deviceName,
      'proofOfPossession': proofOfPossession,
      'path': path,
      'data': data
    };
    final result =
        await methodChannel.invokeMethod<dynamic>('sendCustomData', args);
    if (result == null) return null;
    if (result is Uint8List) return result;
    if (result is String) return Uint8List.fromList(result.codeUnits);
    if (result is List) return Uint8List.fromList(result.cast<int>());
    throw PlatformException(
      code: 'TYPE_ERROR',
      message: 'sendCustomData returned unexpected type: ${result.runtimeType}',
    );
  }

  @override
  Future<void> disconnectDevice(String deviceName) async {
    await methodChannel.invokeMethod<void>('disconnectDevice', {
      'deviceName': deviceName,
    });
  }
}
