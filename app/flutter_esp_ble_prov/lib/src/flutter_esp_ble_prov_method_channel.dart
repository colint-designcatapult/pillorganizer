import 'dart:convert';

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
  Future<List<Map<String, String>>> scanWifiNetworks(
      String deviceName, String proofOfPossession) async {
    final args = {
      'deviceName': deviceName,
      'proofOfPossession': proofOfPossession,
    };
    final raw = await methodChannel.invokeMethod<List<Object?>>(
        'scanWifiNetworks', args);
    final Set<String> uniqNetworks = {};
    final List<Map<String, String>> networks = [];
    if (raw != null) {
      for (Object? o in raw) {
        Map<Object?, Object?> rawMap = o as Map<Object?, Object?>;
        Map<String, String> map = rawMap
            .map((key, value) => MapEntry(key as String, value as String));
        if (map.containsKey("name") && !uniqNetworks.contains(map["name"]!)) {
          uniqNetworks.add(map["name"]!);
          networks.add(map);
        }
      }
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
  Future<Uint8List?> customEndpoint(
      String deviceName, String pop, String endpoint, Uint8List data) async {
    final args = {
      'deviceName': deviceName,
      'proofOfPossession': pop,
      'endpoint': endpoint,
      'data': base64Encode(data)
    };
    return await methodChannel.invokeMethod<Uint8List>('customEndpoint', args);
  }
}
