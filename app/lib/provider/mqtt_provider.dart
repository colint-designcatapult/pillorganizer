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
  // Never retry
  return null;
}

@riverpod
Future<String?> mqttClientName(Ref ref) async {
  final device = ref.watch(activeDeviceProvider);
  if (device == null || device.thingName == null) {
    return null;
  }

  final idToken = await AmplifyService().getIdToken();
  if (idToken == null) {
    return null;
  }

  final String? userid;
  try {
    final idpart = idToken.split(".")[1];
    final base64s = base64.decode(base64Url.normalize(idpart));
    final Map<String, dynamic> jwtClaims = jsonDecode(utf8.decode(base64s));
    userid = jwtClaims["userId"] as String?;
  } catch (e) {
    return null;
  }

  if (userid == null) {
    return null;
  }

  return '${device.thingName}/user/$userid';
}

@Riverpod(retry: _mqttRetry)
class MqttClient extends _$MqttClient {
  @override
  Future<MqttServerClient?> build() async {
    // Only rebuild if the resolved client Name changes.
    // This stops background list refreshes from resetting the connection,
    // because Riverpod won't notify listeners if the final string is identical.
    final clientName = await ref.watch(mqttClientNameProvider.future);

    if (clientName == null) {
      print('[MQTT] clientName is null — skipping connection');
      return null;
    }

    // Get the dependencies using ref.read so they don't trigger direct rebuilds.
    final device = ref.read(activeDeviceProvider);
    final idToken = await AmplifyService().getIdToken();

    if (device == null || idToken == null) {
      return null;
    }

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
    
    // Disable inner auto-reconnect so the MQTT client doesn't enter an endless
    // reconnect loop with stale tokens. Failure bridging is now governed upstream.
    client.autoReconnect = false;

    // Track if we intentionally disconnected to avoid false positive error states
    bool isIntentionalDisconnect = false;

    // Riverpod 3.0 handles disposal semantics.
    // When the provider is invalidated or destroyed, this will run.
    ref.onDispose(() {
      isIntentionalDisconnect = true;
      client.disconnect();
    });

    // Gracefully handle forceful server disconnects (or network drops)
    client.onDisconnected = () {
      if (!isIntentionalDisconnect) {
        print('[MQTT] Disconnected unexpectedly.');
        // Update the provider state to error so the UI actively reflects the Drop
        // and doesn't sit frozen with a dead `AsyncData` client.
        state = AsyncValue.error(
          Exception('MQTT server forcefully disconnected.'),
          StackTrace.current,
        );
      }
    };

    try {
      await client.connect();
      print('[MQTT] Connected successfully');
      return client;
    } catch (e) {
      print('[MQTT] Initial connection failed: $e');
      client.disconnect();
      rethrow;
    }
  }

  /// Manually trigger a reconnect.
  void reconnect() {
    ref.invalidateSelf();
  }
}
