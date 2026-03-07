import 'package:app/service/amplify_service.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mqtt.g.dart';


@riverpod
Stream<String> mqttTopicStream(Ref ref) async* {
  print("test BEGIN");
  // 2. Initialize the client
  final client = MqttServerClient.withPort("wss://ws-mqtt.app.healthesolutions.ca/mqtt",
      "public-ESP32-SIMULATION-001-3AY6OeEsBttG7oNynxeqr1FStJF/user/3AOqWrce8DsiQeE6dwTKBGqGxni",
      443);

  AmplifyService amplifyService = AmplifyService();
  client.websocketHeader = {
    "x-jwt": await amplifyService.getIdToken(),
    "x-device-id": "3AY6OeEsBttG7oNynxeqr1FStJF",
    "x-tenant-id": "public"
  };

  // Enable WebSockets
  client.useWebSocket = true;
  client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
  client.setProtocolV311(); // AWS IoT Core prefers MQTT v3.1.1

  // Optional but recommended settings
  client.logging(on: true);
  client.keepAlivePeriod = 20;
  client.connectTimeoutPeriod = 30;
  client.autoReconnect = true;


  // 3. Connect to the broker
  try {
    await client.connect();
  } catch (e) {
    client.disconnect();
    throw Exception('MQTT Connection failed: $e');
  }

  // Verify connection status
  if (client.connectionStatus!.state != MqttConnectionState.connected) {
    client.disconnect();
    throw Exception('MQTT Connection failed. Status: ${client.connectionStatus!.state}');
  }

  String topic = "healthe/things/public-ESP32-SIMULATION-001-3AY6OeEsBttG7oNynxeqr1FStJF/test";

  // 4. Subscribe to the topic
  client.subscribe(topic, MqttQos.atLeastOnce);

  // 5. Clean up when the provider is disposed (e.g., user leaves the screen)
  ref.onDispose(() {
    client.unsubscribe(topic);
    client.disconnect();
  });

  // 6. Map the raw MQTT updates to a Stream of Strings
  if (client.updates != null) {
    await for (final messages in client.updates!) {
      final recMess = messages[0].payload as MqttPublishMessage;
      final payloadString = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      // Yield the message to the Riverpod stream
      yield payloadString;
    }
  }
}