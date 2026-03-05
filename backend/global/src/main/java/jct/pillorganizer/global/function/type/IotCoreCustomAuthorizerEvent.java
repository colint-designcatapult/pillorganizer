package jct.pillorganizer.global.function.type;

import io.micronaut.serde.annotation.Serdeable;

import java.util.Set;

@Serdeable.Deserializable
public record IotCoreCustomAuthorizerEvent(String token, boolean signatureVerified, Set<String> protocols,
                                           IotCoreProtocolData protocolData,
                                           IotCoreConnectionMetadata connectionMetadata) {
}
