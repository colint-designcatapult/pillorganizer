package jct.pillorganizer.global.function.type;

import io.micronaut.serde.annotation.Serdeable;

import java.util.Map;

@Serdeable.Deserializable
public record IotCoreProtocolDataHttp(String queryString, Map<String, String> headers) {
}
