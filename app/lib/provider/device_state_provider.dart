import 'dart:convert';

import 'package:app/api/api.dart';
import 'package:app/apiv2/models/device.dart';
import 'package:app/provider/time_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'mqtt_provider.dart';

part 'device_state_provider.g.dart';


@riverpod
Stream<DeviceState?> deviceState(Ref ref) async* {
  // 1. Wait for the MQTT client to be connected and ready
  final client = await ref.watch(mqttClientProvider.future);
  final device = ref.watch(activeDeviceProvider)!;

  // 2. Define the shadow topic
  final topic = 'healthe/things/${device.thingName!}/state';
  

  // 3. Subscribe
  client.subscribe(topic, MqttQos.atLeastOnce);

  // 4. CLEANUP: Unsubscribe when this provider is no longer watched,
  // or when the device changes.
  ref.onDispose(() {
    print('Unsubscribing from $topic');
    client.unsubscribe(topic);
  });

  // 5. Yield updates from the MQTT stream
  // (Assuming you have a helper to parse the MQTT payload into a Map/Model)
  await for (final messages in client.updates!) {
    for (final message in messages) {
      if (message.topic == topic) {
        final payload = message.payload as MqttPublishMessage;
        final String jsonString = utf8.decode(payload.payload.message);
        final dynamic decodedJson = jsonDecode(jsonString);
        print(decodedJson);
        DeviceStateDTO dto = DeviceStateDTO.fromJson(decodedJson);
        yield DeviceState.fromDTO(dto);
      }
    }
  }
}

