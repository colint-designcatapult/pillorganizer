package jct.pillorganizer.core.dto;

import io.micronaut.serde.annotation.Serdeable;
import jakarta.annotation.Nullable;

@Serdeable
public record DeviceAccessDto(
        String deviceId,
        @Nullable String claimId,
        String nickname,
        @Nullable String serialNo,
        @Nullable String modelId,
        String tenantId,
        String apiBase,
        boolean primaryUser,
        @Nullable String thingName,
        String tenantName,
        @Nullable Boolean notifications
) {
}
