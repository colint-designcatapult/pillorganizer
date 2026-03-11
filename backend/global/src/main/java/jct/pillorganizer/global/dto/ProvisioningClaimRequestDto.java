package jct.pillorganizer.global.dto;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;

@Serdeable.Deserializable
public record ProvisioningClaimRequestDto(String serialNumber, @Nullable String deviceId) {
}
