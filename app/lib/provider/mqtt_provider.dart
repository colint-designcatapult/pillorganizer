import 'dart:convert';

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

  final client = MqttServerClient.withPort(mqttEndpoint, clientName, 443);

  AmplifyService amplifyService = AmplifyService();
  client.websocketHeader = {
    "x-jwt": await amplifyService.getIdToken(),
    "x-device-id": device.id,
    "x-tenant-id": device.tenantId
  };

  // Enable WebSockets
  client.useWebSocket = true;
  client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
  client.setProtocolV311(); // AWS IoT Core prefers MQTT v3.1.1

  client.logging(on: true);
  client.keepAlivePeriod = 20;
  client.connectTimeoutPeriod = 30;
  client.autoReconnect = true;


  try {
    await client.connect();
  } catch (e) {
    client.disconnect();
    throw Exception('MQTT Connection failed: $e');
  }


  // Clean up when the provider is disposed (e.g., user leaves the screen)
  ref.onDispose(() {
    client.disconnect();
  });

  return client;
}