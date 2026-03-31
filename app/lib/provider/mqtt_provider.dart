import 'dart:convert';
import 'dart:math';

import 'package:app/provider/selected_device_provider.dart';
import 'package:app/service/amplify_service.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mqtt_provider.g.dart';

final String mqttEndpoint = "wss://ws-mqtt.app.healthesolutions.ca/mqtt";

@riverpod
Future<MqttServerClient?> mqttClient(Ref ref) async {
  final device = ref.watch(activeDeviceProvider);

  if(device == null) {
    return null;
  }

  if(device.thingName == null) {
    return null;
  }

    String? idToken = await AmplifyService().getIdToken();
    if (idToken == null) {
      return null;
    }
    String idpart = idToken.split(".")[1];
    final base64s = base64.decode(base64Url.normalize(idpart));
    final jsonstr = utf8.decode(base64s);
    final String userid = jsonDecode(jsonstr)["userId"];


    final clientName = '${device.thingName}/user/$userid';

  AmplifyService amplifyService = AmplifyService();
  final websocketHeader = {
    "x-jwt": await amplifyService.getIdToken(),
    "x-device-id": device.id,
    "x-tenant-id": device.tenantId
  };

  const maxRetries = 5;
  const baseDelay = Duration(seconds: 5);
  const maxDelay = Duration(minutes: 5);

  MqttServerClient? connected;
  Object? lastError;

  for (int attempt = 0; attempt <= maxRetries; attempt++) {
    // Recreate the client each attempt — disconnect() leaves it unusable.
    final attempt_client = MqttServerClient.withPort(mqttEndpoint, clientName, 443);
    attempt_client.websocketHeader = websocketHeader;
    attempt_client.useWebSocket = true;
    attempt_client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
    attempt_client.setProtocolV311();
    attempt_client.logging(on: true);
    attempt_client.keepAlivePeriod = 20;
    attempt_client.connectTimeoutPeriod = 30;
    attempt_client.autoReconnect = true;

    try {
      await attempt_client.connect();
      connected = attempt_client;
      break;
    } catch (e) {
      attempt_client.disconnect();
      lastError = e;
      if (attempt >= maxRetries) break;
      final delayMs = min(
        baseDelay.inMilliseconds * pow(2, attempt).toInt(),
        maxDelay.inMilliseconds,
      );
      await Future.delayed(Duration(milliseconds: delayMs));
    }
  }

  if (connected == null) {
    throw Exception('MQTT Connection failed after $maxRetries attempts: $lastError');
  }

  // Clean up when the provider is disposed (e.g., user leaves the screen)
  ref.onDispose(() {
    connected!.disconnect();
  });

  return connected;
}