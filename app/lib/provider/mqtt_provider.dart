import 'dart:convert';

import 'package:app/provider/selected_device_provider.dart';
import 'package:app/service/amplify_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mqtt_provider.g.dart';

final String mqttEndpoint = "wss://ws-mqtt.app.healthesolutions.ca/mqtt";

Duration? _mqttRetry(int retryCount, Object error) {
  if (retryCount >= 3) return null;
  return Duration(seconds: retryCount * 3);
}

@Riverpod(retry: _mqttRetry)
class MqttClient extends _$MqttClient {
  @override
  Future<MqttServerClient?> build() async {
    // Only rebuild if the selected device ID changes.
    // This stops background list refreshes from resetting the connection.
    ref.watch(activeDeviceProvider.select((d) => d?.id));

    // Get the full device object.
    final device = ref.read(activeDeviceProvider);

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
      print('[MQTT] Failed to parse JWT — aborting');
      return null;
    }

    if (userid == null) {
      print('[MQTT] JWT has no "userId" claim — aborting');
      return null;
    }

    final clientName = '${device.thingName}/user/$userid';
    print('[MQTT] Connecting: clientName=$clientName');

    final client = MqttServerClient.withPort(mqttEndpoint, clientName, 443,
        maxConnectionAttempts: 1);
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

    // Riverpod 3.0 handles disposal semantics.
    // When the provider is invalidated or destroyed, this will run.
    ref.onDispose(client.disconnect);

    try {
      await client.connect();
      print('[MQTT] Connected successfully');
      return client;
    } catch (e) {
      print('[MQTT] Initial connection failed: $e');
      client.disconnect();
      // Rethrow so the provider enters an error state.
      // Riverpod 3.0 will now automatically retry according to 
      // the policy defined in ProviderScope (3 retries, then stop).
      rethrow;
    }
  }

  /// Manually trigger a reconnect.
  void reconnect() {
    ref.invalidateSelf();
  }
}
