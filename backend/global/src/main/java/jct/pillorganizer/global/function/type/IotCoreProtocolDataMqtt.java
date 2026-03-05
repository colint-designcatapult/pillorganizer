package jct.pillorganizer.global.function.type;

import io.micronaut.serde.annotation.Serdeable;

@Serdeable.Deserializable
public record IotCoreProtocolDataMqtt(String username, String password, String clientId) {
}
