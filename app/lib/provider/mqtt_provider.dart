import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:app/provider/selected_device_provider.dart';
import 'package:app/service/amplify_service.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mqtt_provider.g.dart';

final String mqttEndpoint = "wss://ws-mqtt.app.healthesolutions.ca/mqtt";

const _maxRetries = 5;

/// Exponential backoff: 5s → 10s → 20s → 40s → 80s, then give up.
Duration? _nextRetryDelay(int failureCount) {
  if (failureCount >= _maxRetries) return null;
  const baseSecs = 5;
  const capSecs = 300; // 5 minutes
  final secs = (baseSecs * pow(2, failureCount)).toInt();
  return Duration(seconds: secs < capSecs ? secs : capSecs);
}

@riverpod
class MqttClient extends _$MqttClient {
  MqttServerClient? _activeClient;
  int _failureCount = 0;

  @override
  Future<MqttServerClient?> build() async {
    final device = ref.watch(activeDeviceProvider);

    // Disconnect any client from a previous build before starting fresh.
    _activeClient?.disconnect();
    _activeClient = null;

    // Once the retry budget is exhausted, stop permanently.
    // Only a manual reconnect() call can reset this.
    if (_failureCount >= _maxRetries) {
      print('[MQTT] Retry budget exhausted — not attempting connection');
      return null;
    }

    if (device == null || device.thingName == null) {
      print('[MQTT] No device or thingName — skipping connection');
      return null;
    }

    final idToken = await AmplifyService().getIdToken();
    if (idToken == null) {
      print('[MQTT] getIdToken() returned null — aborting');
      return null;
    }

    final String? userid;
    try {
      final idpart = idToken.split(".")[1];
      final base64s = base64.decode(base64Url.normalize(idpart));
      final Map<String, dynamic> jwtClaims = jsonDecode(utf8.decode(base64s));
      userid = jwtClaims["userId"] as String?;
    } catch (e) {
      print('[MQTT] Failed to parse JWT: $e — aborting');
      return null;
    }

    if (userid == null) {
      print('[MQTT] JWT has no "userId" claim — aborting');
      return null;
    }

    final clientName = '${device.thingName}/user/$userid';
    print('[MQTT] Connecting: clientName=$clientName, x-device-id=${device.id}, x-tenant-id=${device.tenantId}');

    final client = MqttServerClient.withPort(mqttEndpoint, clientName, 443);
    client.websocketHeader = {
      "x-jwt": idToken,
      "x-device-id": device.id,
      "x-tenant-id": device.tenantId,
    };
    client.useWebSocket = true;
    client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
    client.setProtocolV311();
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.connectTimeoutPeriod = 30;
    client.autoReconnect = true;

    ref.onDispose(client.disconnect);

    try {
      await client.connect();
      print('[MQTT] Connected successfully');
      _failureCount = 0;
      _activeClient = client;
      return client;
    } catch (e) {
      _failureCount++;
      print('[MQTT] Connection failed (attempt $_failureCount/$_maxRetries): $e');
      final delay = _nextRetryDelay(_failureCount);
      if (delay != null) {
        print('[MQTT] Retrying in ${delay.inSeconds}s');
        final timer = Timer(delay, () => ref.invalidateSelf());
        ref.onDispose(timer.cancel);
      } else {
        print('[MQTT] Retry budget exhausted — giving up');
      }
      return null;
    }
  }

  /// Manually trigger a reconnect, resetting the retry counter.
  void reconnect() {
    _activeClient?.disconnect();
    _activeClient = null;
    _failureCount = 0;
    ref.invalidateSelf();
  }
}
