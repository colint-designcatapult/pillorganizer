package jct.pillorganizer.tenant.dto;

import io.micronaut.core.annotation.Nullable;
import io.micronaut.serde.annotation.Serdeable;
import jakarta.validation.constraints.NotNull;

@Serdeable.Deserializable
public record AssignDeviceDTO(
        @NotNull String deviceId,
        @Nullable String logicalId
) {
}
